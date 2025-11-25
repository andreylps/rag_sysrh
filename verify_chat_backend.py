import asyncio
import sys

import websockets


async def test_websocket():
    uri = "ws://localhost:8081/api/v1/chat/ws"
    try:
        async with websockets.connect(uri) as websocket:
            print(f"Connected to {uri}")

            messages = ["ola", "ajuda", "qual seu nome"]
            for msg in messages:
                print(f"Sending: {msg}")
                await websocket.send(msg)
                response = await websocket.recv()
                print(f"Received: {response}")

    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    asyncio.run(test_websocket())
