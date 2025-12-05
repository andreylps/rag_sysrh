import asyncio
import json
import logging

from fastapi import APIRouter, Body, Depends, WebSocket, WebSocketDisconnect
from sqlalchemy.orm import Session

# Import Database & Services
from src.core.database import get_db

# Import Agents
from src.rag_sysrh.agente_bi import AgenteBI
from src.rag_sysrh.agente_documentacao import AgenteDocumentacao
from src.services.chat_service import ChatService

router = APIRouter()

logger = logging.getLogger(__name__)


class ConnectionManager:
    def __init__(self):
        self.active_connections: list[WebSocket] = []

    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.append(websocket)

    def disconnect(self, websocket: WebSocket):
        self.active_connections.remove(websocket)

    async def send_personal_message(self, message: str, websocket: WebSocket):
        await websocket.send_text(message)

    async def broadcast(self, message: str):
        for connection in self.active_connections:
            await connection.send_text(message)


manager = ConnectionManager()

# Instantiate agents globally
agente_bi = None
agente_docs = None


def get_agents():
    global agente_bi, agente_docs
    print("DEBUG: get_agents called")
    if agente_bi is None:
        try:
            print("DEBUG: Initializing AgenteBI...")
            agente_bi = AgenteBI()
            print("DEBUG: AgenteBI initialized.")
        except Exception as e:
            print(f"DEBUG: Failed to initialize AgenteBI: {e}")
            logger.error(f"Failed to initialize AgenteBI: {e}", exc_info=True)
    if agente_docs is None:
        try:
            print("DEBUG: Initializing AgenteDocumentacao...")
            agente_docs = AgenteDocumentacao()
            print("DEBUG: AgenteDocumentacao initialized.")
        except Exception as e:
            print(f"DEBUG: Failed to initialize AgenteDocumentacao: {e}")
            logger.error(f"Failed to initialize AgenteDocumentacao: {e}", exc_info=True)
    return agente_bi, agente_docs


# --- HTTP Endpoints for Chat History ---


@router.get("/sessions")
def get_sessions(db: Session = Depends(get_db)):
    service = ChatService(db)
    return service.get_sessions()


@router.post("/sessions")
def create_session(
    title: str = Body(embed=True, default="New Chat"), db: Session = Depends(get_db)
):
    service = ChatService(db)
    return service.create_session(title)


@router.delete("/sessions/{session_id}")
def delete_session(session_id: str, db: Session = Depends(get_db)):
    service = ChatService(db)
    service.delete_session(session_id)
    return {"status": "deleted"}


@router.get("/sessions/{session_id}/messages")
def get_session_messages(session_id: str, db: Session = Depends(get_db)):
    service = ChatService(db)
    return service.get_messages(session_id)


# --- WebSocket Endpoint ---


@router.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket, db: Session = Depends(get_db)):
    await manager.connect(websocket)

    # Initialize ChatService
    chat_service = ChatService(db)

    # Ensure agents are initialized in a non-blocking way
    with open("debug_chat.log", "a") as f:
        f.write("DEBUG: Initializing agents...\n")
    logger.info("Initializing agents...")
    try:
        bi_agent, docs_agent = await asyncio.to_thread(get_agents)
        with open("debug_chat.log", "a") as f:
            f.write("DEBUG: Agents initialized successfully.\n")
        logger.info("Agents initialized successfully.")
    except Exception as e:
        with open("debug_chat.log", "a") as f:
            f.write(f"DEBUG: Failed to initialize agents: {e}\n")
        logger.error(f"Failed to initialize agents: {e}")
        await manager.disconnect(websocket)
        return

    # --- SETUP TOOL CALLING ---
    try:
        with open("debug_chat.log", "a") as f:
            f.write("DEBUG: Setting up tools...\n")
        from langchain_core.messages import (
            AIMessage,
            HumanMessage,
            SystemMessage,
            ToolMessage,
        )

        from src.rag_sysrh.tools.solicitation_tools import CreateSolicitationTool

        solicitation_tool = CreateSolicitationTool()
        # Bind tools to the LLM (if supported by the provider, assuming OpenAI/GPT-4)
        if docs_agent and hasattr(docs_agent.llm, "bind_tools"):
            with open("debug_chat.log", "a") as f:
                f.write("DEBUG: Binding tools to LLM...\n")
            llm_with_tools = docs_agent.llm.bind_tools([solicitation_tool])
        else:
            llm_with_tools = docs_agent.llm if docs_agent else None
            with open("debug_chat.log", "a") as f:
                f.write(
                    "DEBUG: LLM does not support bind_tools or agent not initialized.\n"
                )
            logger.warning("LLM does not support bind_tools or agent not initialized.")
    except Exception as e:
        with open("debug_chat.log", "a") as f:
            f.write(f"DEBUG: Failed to setup tools: {e}\n")
        logger.error(f"Failed to setup tools: {e}", exc_info=True)
        llm_with_tools = None

    try:
        while True:
            raw_data = await websocket.receive_text()
            logger.info("Received message payload")

            text_input = ""
            attachments = []
            model_provider = "openai"
            session_id = None

            try:
                payload = json.loads(raw_data)
                text_input = payload.get("text", "")
                attachments = payload.get("attachments", [])
                model_provider = payload.get("model", "openai")
                session_id = payload.get("sessionId")
            except json.JSONDecodeError:
                text_input = raw_data
                model_provider = "openai"

            logger.info(
                f"Text: {text_input}, Attachments: {len(attachments)}, Model: {model_provider}, Session: {session_id}"
            )

            # Save User Message
            if session_id:
                chat_service.save_message(session_id, "user", text_input, attachments)

            # Switch LLM if needed
            if docs_agent:
                docs_agent.set_llm(model_provider)
                # Re-bind tools after switching LLM if necessary
                if hasattr(docs_agent.llm, "bind_tools"):
                    llm_with_tools = docs_agent.llm.bind_tools([solicitation_tool])

            if bi_agent:
                bi_agent.set_llm(model_provider)

            response = ""

            try:
                # --- CONVERSATION HISTORY & CONTEXT ---
                history_messages = []
                if session_id:
                    # Fetch last 10 messages for context
                    raw_history = chat_service.get_messages(session_id)
                    # Assuming raw_history is ordered by time asc
                    for msg in raw_history[-10:]:
                        # Handle both dict and object (just in case)
                        role = (
                            msg.sender if hasattr(msg, "sender") else msg.get("sender")
                        )
                        content = (
                            msg.content
                            if hasattr(msg, "content")
                            else msg.get("content")
                        )

                        if role == "user":
                            history_messages.append(HumanMessage(content=content))
                        elif role == "ai":
                            history_messages.append(AIMessage(content=content))

                # 1. RAG Retrieval (Context)
                relevant_docs = []
                if text_input.strip() and docs_agent:
                    vectorstore = docs_agent.retriever.vectorstore
                    results = vectorstore.similarity_search_with_score(text_input, k=3)
                    relevant_docs = [doc for doc, score in results if score >= 0.80]

                context_text = "\n\n".join([d.page_content for d in relevant_docs])

                # 2. System Prompt Construction
                logger.info("Constructing system prompt...")
                system_prompt = f"""
Você é o Assistente Virtual Inteligente do sistema RAG SYS-RH.

**SUAS CAPACIDADES:**
1. **Responder Dúvidas:** Use o contexto abaixo para responder perguntas sobre o sistema.
2. **Analisar Imagens:** Você é capaz de ver e interpretar imagens enviadas pelo usuário. Se uma imagem for enviada, descreva-a ou responda à pergunta do usuário sobre ela.
3. **Abrir Solicitações (CRÍTICO):** Se o usuário relatar um problema, bug ou pedir uma melhoria, você **DEVE** seguir este protocolo:

**PROTOCOLO DE CRIAÇÃO DE SOLICITAÇÃO:**
1.  **Identificar Intenção:** O usuário quer registrar algo?
2.  **Coletar Dados:** Verifique se você tem TODOS os seguintes dados:
    *   **Título:** Um resumo curto do problema.
    *   **Descrição:** Detalhes do que está acontecendo.
    *   **Prioridade:** Baixa, Média ou Alta.
    *   **Tipo:** Evolutiva, Corretiva, Dúvida ou Operação.
3.  **Solicitar Faltantes:** Se faltar algum dado, PERGUNTE ao usuário. Não invente.
4.  **CHAMAR A FERRAMENTA:** Assim que tiver os 4 dados, **NÃO PERGUNTE MAIS NADA**. CHAME IMEDIATAMENTE a ferramenta `create_solicitation`.
    *   NÃO diga "Vou criar o chamado". APENAS CHAME A FERRAMENTA.

**CONTEXTO RECUPERADO (Use para responder dúvidas):**
{context_text}
"""
                messages = [SystemMessage(content=system_prompt)] + history_messages

                # Construct Human Message (Text or Multimodal)
                if attachments:
                    logger.info(
                        f"Processing {len(attachments)} attachments for multimodal message."
                    )
                    content_parts = [{"type": "text", "text": text_input}]
                    for att in attachments:
                        # Assuming att['content'] is the base64 string (data:image/png;base64,...)
                        # OpenAI expects "image_url": {"url": "data:image/jpeg;base64,..."}
                        if "image" in att.get("type", "") or att.get(
                            "content", ""
                        ).startswith("data:image"):
                            content_parts.append(
                                {
                                    "type": "image_url",
                                    "image_url": {"url": att["content"]},
                                }
                            )

                    messages.append(HumanMessage(content=content_parts))
                else:
                    messages.append(HumanMessage(content=text_input))

                # 3. LLM Execution with Tools
                logger.info("Invoking LLM...")
                if llm_with_tools:
                    logger.info("Using LLM with tools.")
                    ai_msg = await llm_with_tools.ainvoke(messages)
                    logger.info(
                        f"LLM response received. Tool calls: {ai_msg.tool_calls}"
                    )

                    # Check for Tool Calls
                    if ai_msg.tool_calls:
                        logger.info(f"Tool Call Detected: {ai_msg.tool_calls}")
                        for tool_call in ai_msg.tool_calls:
                            if tool_call["name"] == "create_solicitation":
                                # Execute Tool
                                logger.info("Executing create_solicitation tool...")
                                tool_output = await solicitation_tool.ainvoke(
                                    tool_call["args"]
                                )
                                logger.info(f"Tool output: {tool_output}")
                                # Append Tool Message to history (simulated for this turn)
                                messages.append(ai_msg)
                                messages.append(
                                    ToolMessage(
                                        content=tool_output,
                                        tool_call_id=tool_call["id"],
                                    )
                                )

                                # Get final response from LLM incorporating tool output
                                logger.info("Invoking LLM again with tool output...")
                                final_response = await llm_with_tools.ainvoke(messages)
                                response = final_response.content
                    else:
                        response = ai_msg.content
                else:
                    # Fallback without tools
                    logger.info("Using LLM without tools (Fallback).")
                    ai_msg = await docs_agent.llm.ainvoke(messages)
                    response = ai_msg.content

            except Exception as e:
                logger.error(f"Error processing request: {e}", exc_info=True)
                response = f"Ocorreu um erro ao processar sua solicitação: {e!s}"

            # Save AI Response
            if session_id:
                chat_service.save_message(session_id, "ai", response)

            await manager.send_personal_message(response, websocket)

    except WebSocketDisconnect:
        manager.disconnect(websocket)
        logger.info("Client disconnected")
