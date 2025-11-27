import asyncio
import json
import logging

import websockets

# Configure logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

URI = "ws://localhost:8080/api/v1/chat/ws"


async def test_solicitation_flow():
    async with websockets.connect(URI) as websocket:
        logger.info("Connected to WebSocket")

        # 1. Send initial problem statement
        msg1 = {
            "text": "Estou com um problema no sistema. O botão de salvar não funciona.",
            "model": "openai",
            "sessionId": "test-session-123",
        }
        await websocket.send(json.dumps(msg1))
        logger.info(f"Sent: {msg1['text']}")

        # Receive response (Agent should offer to open solicitation or ask for details)
        response1 = await websocket.recv()
        logger.info(f"Received: {response1}")

        # 2. Confirm and provide details
        msg2 = {
            "text": "Sim, pode abrir. É urgente. Prioridade Alta. É um erro na tela de cadastro.",
            "model": "openai",
            "sessionId": "test-session-123",
        }
        await websocket.send(json.dumps(msg2))
        logger.info(f"Sent: {msg2['text']}")

        # Receive response (Agent should call tool and confirm)
        # Note: The agent might send multiple messages if it sends intermediate thoughts,
        # but our implementation sends the final response.
        # However, if the tool execution takes time, we might need to wait.
        response2 = await websocket.recv()
        logger.info(f"Received: {response2}")

        if "Solicitação criada com sucesso" in response2 or "Número: #" in response2:
            logger.info("✅ SUCCESS: Solicitation created via chat.")
        else:
            logger.error("❌ FAILURE: Solicitation creation not confirmed.")


if __name__ == "__main__":
    asyncio.run(test_solicitation_flow())
