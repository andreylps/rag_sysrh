import asyncio
import base64
import json
import logging
from typing import List

from fastapi import APIRouter, Body, Depends, WebSocket, WebSocketDisconnect
from langchain_core.messages import HumanMessage
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
    logger.info("Initializing agents...")
    try:
        bi_agent, docs_agent = await asyncio.to_thread(get_agents)
        logger.info("Agents initialized successfully.")
    except Exception as e:
        logger.error(f"Failed to initialize agents: {e}")
        await manager.disconnect(websocket)
        return

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
                session_id = payload.get("sessionId")  # Get session ID from payload
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
            if bi_agent:
                bi_agent.set_llm(model_provider)

            # Simple routing logic
            response = ""
            lower_data = text_input.lower()

            # Heuristic routing
            is_bi_query = any(
                keyword in lower_data
                for keyword in [
                    "quantos",
                    "total",
                    "valor",
                    "status",
                    "dashboard",
                    "faturamento",
                    "custo",
                ]
            )

            # Check for greetings
            greetings = [
                "bom dia",
                "boa tarde",
                "boa noite",
                "oi",
                "olá",
                "ola",
                "obrigado",
                "obrigada",
                "tchau",
                "até mais",
                "valeu",
            ]
            is_greeting = (
                any(greet in lower_data for greet in greetings)
                and len(lower_data.split()) < 25
            )

            try:
                if is_greeting and not attachments and docs_agent:
                    # Resposta conversacional dinâmica usando LLM (Sentiment Analysis)
                    logger.info("Generating dynamic greeting/farewell with LLM")

                    prompt_conversational = f"""
                    Você é o Assistente Virtual do sistema RAG SYS-RH.
                    O usuário enviou uma mensagem curta de interação social: "{text_input}"
                    
                    Sua tarefa é responder de forma breve, natural e humana, espelhando o sentimento do usuário (Rapport).
                    
                    IMPORTANTE: Retorne APENAS a mensagem de resposta para o usuário. NÃO inclua explicações, análises de sentimento ou rótulos como "Resposta:".
                    """

                    try:
                        llm_response = await docs_agent.llm.ainvoke(
                            [HumanMessage(content=prompt_conversational)]
                        )
                        response = llm_response.content
                    except Exception as e:
                        logger.error(f"Failed to generate dynamic greeting: {e}")
                        response = "Olá! Como posso ajudar você hoje?"

                elif is_bi_query and bi_agent and not attachments:
                    # Use BI Agent (Text only for now)
                    logger.info("Routing to AgenteBI")
                    result = bi_agent.responder_pergunta(text_input)
                    response = result.get(
                        "resposta", "Não consegui obter uma resposta do BI."
                    )

                elif docs_agent:
                    # Use Docs Agent (RAG + Vision)
                    logger.info("Routing to AgenteDocumentacao (RAG/Vision)")

                    # Process Attachments
                    image_content = []
                    file_context = ""

                    for att in attachments:
                        if att["type"].startswith("image/"):
                            # Prepare for Vision Model
                            image_content.append(
                                {
                                    "type": "image_url",
                                    "image_url": {"url": att["content"]},
                                }
                            )
                        elif att["type"] in [
                            "text/plain",
                            "text/csv",
                            "application/json",
                        ]:
                            # Decode text files
                            try:
                                content_bytes = base64.b64decode(
                                    att["content"].split(",")[1]
                                )
                                decoded_text = content_bytes.decode("utf-8")
                                file_context += f"\n\n--- Conteúdo do Arquivo {att['name']} ---\n{decoded_text}\n"
                            except Exception as e:
                                logger.error(
                                    f"Failed to decode file {att['name']}: {e}"
                                )

                    # 1. Retrieve context with score (only if there is text input)
                    relevant_docs = []
                    if text_input.strip():
                        vectorstore = docs_agent.retriever.vectorstore
                        results = vectorstore.similarity_search_with_score(
                            text_input, k=4
                        )
                        logger.info(f"RAG Retrieval: Found {len(results)} raw results.")
                        for doc, score in results:
                            logger.info(
                                f" - Doc: {doc.metadata.get('source', 'unknown')} | Score: {score}"
                            )

                        relevant_docs = [
                            doc for doc, score in results if score >= 0.85
                        ]  # Lowered threshold slightly for testing
                        logger.info(
                            f"RAG Retrieval: {len(relevant_docs)} docs passed threshold (>= 0.85)."
                        )

                    # Heurística para detectar intenção de suporte/correção
                    support_keywords = [
                        "corrigir",
                        "erro",
                        "bug",
                        "defeito",
                        "falha",
                        "solicita",
                        "cadastrar",
                        "criar",
                        "abrir",
                        "evolu",
                        "melhoria",
                        "chamado",
                        "ticket",
                    ]
                    is_support_query = any(k in lower_data for k in support_keywords)

                    # Heurística para mensagens curtas (evitar busca na web para chitchat/comandos)
                    is_short_message = len(text_input.split()) < 10

                    # Decide flow: RAG, Web Search, or Vision/File Analysis
                    if (
                        not relevant_docs
                        and not attachments
                        and not is_support_query
                        and not is_short_message
                    ):
                        logger.info(
                            "Low relevance scores, not support, not short. Falling back to Web Search."
                        )
                        try:
                            from duckduckgo_search import DDGS

                            web_results = ""
                            with DDGS() as ddgs:
                                results = list(ddgs.text(text_input, max_results=3))
                                if results:
                                    web_results = "\n\n".join(
                                        [
                                            f"- **{r['title']}**: {r['body']} ({r['href']})"
                                            for r in results
                                        ]
                                    )
                                else:
                                    web_results = "Nenhum resultado encontrado na web."

                            prompt_web = f"""
                            Você é um assistente útil. O usuário fez uma pergunta que não consta na base de conhecimento interna.
                            Responda com base nos resultados da pesquisa na web abaixo.
                            Resultados da Web:
                            {web_results}
                            Pergunta:
                            {text_input}
                            Instrução:
                            Responda de forma amigável e direta.
                            """
                            llm_response = await docs_agent.llm.ainvoke(
                                [HumanMessage(content=prompt_web)]
                            )
                            response = (
                                "⚠️ **Aviso:** Esta pergunta está fora do contexto do sistema RAG SYS-RH. "
                                "A resposta abaixo foi obtida via pesquisa na web e não reflete necessariamente os dados internos.\n\n"
                                f"{llm_response.content}"
                            )
                        except Exception as e:
                            logger.error(f"Web search failed: {e}")
                            response = "Não encontrei informações relevantes na base interna e não consegui pesquisar na web no momento."

                    else:
                        # 2. Generate answer using RAG + Attachments
                        context_text = "\n\n".join(
                            [d.page_content for d in relevant_docs]
                        )

                        # Append file context if any
                        if file_context:
                            context_text += file_context

                        prompt_text = f"""
                        Você é o Assistente Virtual do sistema RAG SYS-RH.
                        
                        **DIRETRIZES IMPORTANTES:**
                        1. **PRIORIDADE MÁXIMA:** Se o usuário perguntar **como o sistema funciona**, **como realizar uma tarefa** ou buscar informações técnicas (ex: "Como cadastro um usuário?", "O que é o módulo X?"), **RESPONDA** com base no Contexto abaixo. **NÃO** o mande para a Governança nestes casos.
                        
                        2. Apenas se o usuário manifestar **CLARAMENTE** a intenção de **abrir um chamado técnico AGORA**, **relatar um bug** ou **pedir uma nova funcionalidade**:
                           - Oriente-o a acessar a opção **"Governança & IA"** no menu lateral.
                           - Explique que lá ele encontrará o formulário para cadastrar sua demanda.

                        2. Para outras perguntas, use o contexto abaixo recuperado da base de conhecimento (e arquivos anexados, se houver).
                        
                        Contexto:
                        {context_text}
                        
                        Pergunta:
                        {text_input}
                        """

                        # Construct Message
                        if image_content:
                            # Multimodal Message
                            message_content = [
                                {"type": "text", "text": prompt_text}
                            ] + image_content
                            message = HumanMessage(content=message_content)
                        else:
                            # Text Message
                            message = HumanMessage(content=prompt_text)

                        llm_response = await docs_agent.llm.ainvoke([message])
                        response = llm_response.content

                else:
                    response = "Desculpe, os agentes do sistema não estão disponíveis no momento."

            except Exception as e:
                logger.error(f"Error processing request: {e}")
                response = f"Ocorreu um erro ao processar sua solicitação: {str(e)}"

            # Save AI Response
            if session_id:
                chat_service.save_message(session_id, "ai", response)

            await manager.send_personal_message(response, websocket)

    except WebSocketDisconnect:
        manager.disconnect(websocket)
        logger.info("Client disconnected")
