#!/bin/bash

# Port forward script for chatapp services
# This script forwards all services to the host so they're accessible from outside the container

echo "Starting port forwarding for chatapp services..."

# Kill any existing port-forward processes
pkill -f "kubectl port-forward"

# Port forward UI service (8000)
kubectl port-forward -n chatapp svc/ui-service 8000:8000 --address 0.0.0.0 &
echo "UI Service: http://10.211.13.240:8000"

# Port forward Go service (8080)
kubectl port-forward -n chatapp svc/go-service 8080:8080 --address 0.0.0.0 &
echo "Go Service: http://10.211.13.240:8080"

# Port forward Java service (8090)
kubectl port-forward -n chatapp svc/java-service 8090:8090 --address 0.0.0.0 &
echo "Java Service: http://10.211.13.240:8090"

# Port forward Python service (8087)
kubectl port-forward -n chatapp svc/python-service 8087:8087 --address 0.0.0.0 &
echo "Python Service: http://10.211.13.240:8087"

echo ""
echo "All services are now accessible on host IP 10.211.13.240"
echo "Press Ctrl+C to stop all port forwards"

# Wait for Ctrl+C
wait
