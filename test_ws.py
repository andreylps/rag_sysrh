import asyncio
import json

import websockets


async def test_ws():
    uri = "ws://localhost:8080/api/v1/chat/ws"
    print(f"Tentando conectar a {uri}...")
    try:
        async with websockets.connect(uri) as websocket:
            print("✅ Conexão WebSocket estabelecida com sucesso!")

            # Envia uma mensagem de teste
            msg = {"text": "Olá, teste de conexão"}
            await websocket.send(json.dumps(msg))
            print(f"Enviado: {msg}")

            response = await websocket.recv()
            print(f"Recebido: {response}")

    except Exception as e:
        print(f"❌ Falha na conexão WebSocket: {e}")


if __name__ == "__main__":
    asyncio.run(test_ws())
