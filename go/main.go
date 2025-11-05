package main

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"time"

	pb "chatapp/proto"

	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
)

type JoinRoomRequest struct {
	Username string `json:"username"`
	RoomID   string `json:"roomid"`
}

var (
	javaServiceHost     string
	javaServiceHttpPort string
	javaServiceGrpcPort string
)

func init() {
	// Read service endpoints from environment variables
	javaServiceHost = os.Getenv("JAVA_SERVICE_HOST")
	if javaServiceHost == "" {
		javaServiceHost = "localhost" // Default for local development
	}

	javaServiceHttpPort = os.Getenv("JAVA_SERVICE_HTTP_PORT")
	if javaServiceHttpPort == "" {
		javaServiceHttpPort = "8090" // Default port
	}

	javaServiceGrpcPort = os.Getenv("JAVA_SERVICE_GRPC_PORT")
	if javaServiceGrpcPort == "" {
		javaServiceGrpcPort = "9090" // Default port
	}

	log.Printf("Configured to connect to Java service at %s (HTTP:%s, gRPC:%s)",
		javaServiceHost, javaServiceHttpPort, javaServiceGrpcPort)
}

func main() {
	http.HandleFunc("/joinroom", joinRoomHandler)
	http.HandleFunc("/joingrpcroom", joinGrpcRoomHandler)
	fmt.Println("Server running on :8080")
	log.Fatal(http.ListenAndServe(":8080", nil))
}

func joinRoomHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
	w.Header().Set("Access-Control-Allow-Headers", "Content-Type")

	username := r.URL.Query().Get("username")
	roomid := r.URL.Query().Get("roomid")

	if username == "" || roomid == "" {
		http.Error(w, "username and roomid required", http.StatusBadRequest)
		return
	}

	payload := JoinRoomRequest{Username: username, RoomID: roomid}
	jsonData, _ := json.Marshal(payload)

	javaServiceURL := fmt.Sprintf("http://%s:%s/room", javaServiceHost, javaServiceHttpPort)
	resp, err := http.Post(javaServiceURL, "application/json", bytes.NewBuffer(jsonData))
	if err != nil {
		http.Error(w, "Failed to call room service: "+err.Error(), http.StatusInternalServerError)
		return
	}
	defer resp.Body.Close()

	w.WriteHeader(http.StatusOK)
	fmt.Fprintf(w, "Joined room successfully (HTTP)")
}

func joinGrpcRoomHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
	w.Header().Set("Access-Control-Allow-Headers", "Content-Type")

	username := r.URL.Query().Get("username")
	roomid := r.URL.Query().Get("roomid")

	if username == "" || roomid == "" {
		http.Error(w, "username and roomid required", http.StatusBadRequest)
		return
	}

	// gRPC call to Java service
	javaGrpcAddr := fmt.Sprintf("%s:%s", javaServiceHost, javaServiceGrpcPort)
	conn, err := grpc.Dial(javaGrpcAddr, grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		http.Error(w, "Failed to connect to Java gRPC: "+err.Error(), http.StatusInternalServerError)
		return
	}
	defer conn.Close()

	client := pb.NewRoomServiceClient(conn)
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	response, err := client.CreateRoom(ctx, &pb.RoomRequest{
		Username: username,
		Roomid:   roomid,
	})

	if err != nil {
		http.Error(w, "Failed to call Java gRPC service: "+err.Error(), http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusOK)
	fmt.Fprintf(w, "Joined room successfully via gRPC: %s", response.Message)
}
