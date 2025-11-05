from flask import Flask, request, jsonify
from flask_cors import CORS
from kafka import KafkaProducer, KafkaConsumer
import sqlite3
import json
import threading
import os
import grpc
from concurrent import futures
import chatapp_pb2
import chatapp_pb2_grpc

app = Flask(__name__)
CORS(app)

KAFKA_SERVERS = os.getenv('KAFKA_BOOTSTRAP_SERVERS', 'localhost:9092')
DB_PATH = 'messages.db'

producer = KafkaProducer(
    bootstrap_servers=KAFKA_SERVERS,
    value_serializer=lambda v: json.dumps(v).encode('utf-8')
)

def init_db():
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    c.execute('CREATE TABLE IF NOT EXISTS messages (username TEXT, roomid TEXT, message TEXT, timestamp DATETIME DEFAULT CURRENT_TIMESTAMP)')
    conn.commit()
    conn.close()

def consume_kafka():
    consumer = KafkaConsumer(
        bootstrap_servers=KAFKA_SERVERS,
        value_deserializer=lambda m: json.loads(m.decode('utf-8')),
        auto_offset_reset='earliest',
        group_id='chatapp-group'
    )
    consumer.subscribe(pattern='^room-.*')
    
    for msg in consumer:
        data = msg.value
        conn = sqlite3.connect(DB_PATH)
        c = conn.cursor()
        c.execute('INSERT INTO messages (username, roomid, message) VALUES (?, ?, ?)', 
                  (data['username'], data['roomid'], data.get('message', 'User joined')))
        conn.commit()
        conn.close()
        print(f"Stored message for room {data['roomid']}")

class MessageServiceServicer(chatapp_pb2_grpc.MessageServiceServicer):
    def SendMessage(self, request, context):
        data = {
            'username': request.username,
            'roomid': request.roomid,
            'message': request.message
        }
        topic = f"room-{request.roomid}"
        producer.send(topic, data)
        return chatapp_pb2.MessageResponse(status="success")

def serve_grpc():
    server = grpc.server(futures.ThreadPoolExecutor(max_workers=10))
    chatapp_pb2_grpc.add_MessageServiceServicer_to_server(MessageServiceServicer(), server)
    server.add_insecure_port('[::]:50052')
    server.start()
    print("Python gRPC server started on port 50052")
    server.wait_for_termination()

@app.route('/message', methods=['POST'])
def handle_message():
    data = request.json
    topic = f"room-{data['roomid']}"
    producer.send(topic, data)
    return jsonify({"status": "Message sent to Kafka"}), 200

@app.route('/messages', methods=['GET'])
def get_messages():
    roomid = request.args.get('roomid')
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    c.execute('SELECT username, message, timestamp FROM messages WHERE roomid = ? ORDER BY timestamp', (roomid,))
    messages = [{'username': row[0], 'message': row[1], 'timestamp': row[2]} for row in c.fetchall()]
    conn.close()
    return jsonify(messages), 200

if __name__ == '__main__':
    init_db()
    threading.Thread(target=consume_kafka, daemon=True).start()
    threading.Thread(target=serve_grpc, daemon=True).start()
    app.run(host='0.0.0.0', port=8091, debug=False)
