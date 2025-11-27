import asyncio
import json
import logging
from typing import List

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
        self.active_connections: List[WebSocket] = []

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
2. **Abrir Solicitações:** Se o usuário relatar um problema, bug ou pedir uma melhoria, **OFEREÇA** abrir uma solicitação.
   - Se o usuário aceitar, colete: Título (resumido), Descrição detalhada, Prioridade e Tipo.
   - **VOCÊ DEVE CHAMAR A FERRAMENTA `create_solicitation` PARA REGISTRAR.**
   - **NÃO RESPONDA COM TEXTO DIZENDO QUE VAI FAZER. FAÇA!**
   - **CHAME A FERRAMENTA.**

**DIRETRIZES:**
- Seja prestativo e profissional.
- Se o usuário disser "meu sistema travou", pergunte detalhes e ofereça abrir um chamado.
- Se o usuário perguntar "como faço X", explique usando o contexto.
- NÃO invente informações se não estiverem no contexto.

**CONTEXTO RECUPERADO:**
{context_text}
"""
                # system_prompt = system_prompt.replace(
                #     "{contexto_extra_placeholder}", context_text
                # )

                messages = (
                    [SystemMessage(content=system_prompt)]
                    + history_messages
                    + [HumanMessage(content=text_input)]
                )

                # Inject reminder if user mentions priority (hack to force tool)
                if "prioridade" in text_input.lower():
                    messages.append(
                        SystemMessage(
                            content="O usuário forneceu os dados. CHAME A FERRAMENTA create_solicitation AGORA."
                        )
                    )

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
                response = f"Ocorreu um erro ao processar sua solicitação: {str(e)}"

            # Save AI Response
            if session_id:
                chat_service.save_message(session_id, "ai", response)

            await manager.send_personal_message(response, websocket)

    except WebSocketDisconnect:
        manager.disconnect(websocket)
        logger.info("Client disconnected")
