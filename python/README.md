# Python Message Service

## Setup
```bash
pip install -r requirements.txt
```

## Run
```bash
python app.py
```

## Test
```bash
curl -X POST http://localhost:8091/message \
  -H "Content-Type: application/json" \
  -d '{"username":"john","roomid":"room123","message":"Hello"}'
```

## Flow
1. Receives messages via `/message` endpoint
2. Publishes to Kafka topic `room-{roomid}`
3. Consumes from Kafka and stores to SQLite `messages.db`
