#!/bin/bash

# ChatApp Kubernetes Deployment Script
# This script builds Docker images and deploys to Kubernetes

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="chatapp"
REGISTRY="${REGISTRY:-}"  # Set this to your container registry if using remote cluster

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Build Docker images
build_images() {
    log_info "Building Docker images..."
    
    cd ..
    
    log_info "Building Python service..."
    docker build -t chatapp-python:latest -f python/Dockerfile .
    
    log_info "Building Java service..."
    docker build -t chatapp-java:latest -f java/Dockerfile .
    
    log_info "Building Go service..."
    docker build -t chatapp-go:latest -f go/Dockerfile .
    
    log_info "All images built successfully!"
}

# Tag and push images to registry
push_images() {
    if [ -z "$REGISTRY" ]; then
        log_warn "No registry specified. Skipping image push."
        log_warn "Set REGISTRY environment variable to push images."
        return
    fi
    
    log_info "Tagging and pushing images to $REGISTRY..."
    
    for service in python java go; do
        log_info "Pushing chatapp-${service}..."
        docker tag chatapp-${service}:latest ${REGISTRY}/chatapp-${service}:latest
        docker push ${REGISTRY}/chatapp-${service}:latest
    done
    
    log_info "All images pushed successfully!"
}

# Create UI ConfigMap from index.html
create_ui_configmap() {
    log_info "Creating UI ConfigMap..."
    
    cd ..
    
    if [ -f "index.html" ]; then
        kubectl create configmap ui-config \
            --from-file=index.html=./index.html \
            -n ${NAMESPACE} \
            --dry-run=client -o yaml | kubectl apply -f -
        log_info "UI ConfigMap created successfully!"
    else
        log_warn "index.html not found. Please update ui-config ConfigMap manually."
    fi
}

# Deploy to Kubernetes
deploy() {
    log_info "Deploying to Kubernetes..."
    
    cd k8s
    
    # Create namespace
    log_info "Creating namespace..."
    kubectl apply -f namespace.yaml
    
    # Deploy Zookeeper
    log_info "Deploying Zookeeper..."
    kubectl apply -f zookeeper-deployment.yaml
    
    log_info "Waiting for Zookeeper to be ready..."
    kubectl wait --for=condition=ready pod -l app=zookeeper -n ${NAMESPACE} --timeout=120s || true
    
    # Deploy Kafka
    log_info "Deploying Kafka..."
    kubectl apply -f kafka-deployment.yaml
    
    log_info "Waiting for Kafka to be ready..."
    kubectl wait --for=condition=ready pod -l app=kafka -n ${NAMESPACE} --timeout=120s || true
    
    # Deploy application services
    log_info "Deploying Python service..."
    kubectl apply -f python-service-deployment.yaml
    
    log_info "Deploying Java service..."
    kubectl apply -f java-service-deployment.yaml
    
    log_info "Deploying Go service..."
    kubectl apply -f go-service-deployment.yaml
    
    # Create UI ConfigMap and deploy UI
    create_ui_configmap
    
    log_info "Deploying UI..."
    kubectl apply -f ui-deployment.yaml
    
    # Deploy Ingress
    log_info "Deploying Ingress..."
    kubectl apply -f ingress.yaml || log_warn "Failed to deploy ingress (may need ingress controller)"
    
    log_info "Deployment complete!"
}

# Show deployment status
show_status() {
    log_info "Deployment Status:"
    echo ""
    
    log_info "Pods:"
    kubectl get pods -n ${NAMESPACE}
    echo ""
    
    log_info "Services:"
    kubectl get services -n ${NAMESPACE}
    echo ""
    
    log_info "Ingress:"
    kubectl get ingress -n ${NAMESPACE} || log_warn "No ingress found"
}

# Main script
main() {
    log_info "ChatApp Kubernetes Deployment"
    echo ""
    
    case "${1:-all}" in
        build)
            build_images
            ;;
        push)
            push_images
            ;;
        deploy)
            deploy
            show_status
            ;;
        all)
            build_images
            push_images
            deploy
            show_status
            ;;
        status)
            show_status
            ;;
        *)
            echo "Usage: $0 {build|push|deploy|all|status}"
            echo ""
            echo "  build   - Build Docker images"
            echo "  push    - Push images to registry (requires REGISTRY env var)"
            echo "  deploy  - Deploy to Kubernetes"
            echo "  all     - Build, push, and deploy (default)"
            echo "  status  - Show deployment status"
            echo ""
            echo "Example:"
            echo "  $0 all"
            echo "  REGISTRY=myregistry.io/myproject $0 all"
            exit 1
            ;;
    esac
}

main "$@"
