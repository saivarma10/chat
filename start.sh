#!/bin/bash

echo "🚀 Starting Chat App with Docker Compose..."
echo ""
echo "This will start:"
echo "  - Zookeeper"
echo "  - Kafka"
echo "  - Python Service (8091)"
echo "  - Java Service (8090)"
echo "  - Go Service (8080)"
echo "  - UI (http://localhost)"
echo ""

docker-compose up --build

echo ""
echo "To stop: docker-compose down"
