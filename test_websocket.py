import asyncio
import json

import websockets


async def test_chat():
    uri = "ws://localhost:8080/api/v1/chat/ws"
    print(f"Connecting to {uri}...")
    try:
        async with websockets.connect(uri) as websocket:
            print("✅ Connected!")

            payload = {
                "text": "Olá, teste de conexão.",
                "attachments": [],
                "model": "gemini",
            }
            print(f"Sending: {payload}")
            await websocket.send(json.dumps(payload))

            print("Waiting for response...")
            response = await websocket.recv()
            print(f"✅ Received: {response}")

    except Exception as e:
        print(f"❌ Error: {e}")


if __name__ == "__main__":
    asyncio.run(test_chat())
