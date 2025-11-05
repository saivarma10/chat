package com.chatapp;

import com.chatapp.grpc.*;
import io.grpc.ManagedChannel;
import io.grpc.ManagedChannelBuilder;
import io.grpc.stub.StreamObserver;
import org.apache.kafka.clients.admin.AdminClient;
import org.apache.kafka.clients.admin.NewTopic;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.util.Collections;

@Service
public class RoomGrpcService extends RoomServiceGrpc.RoomServiceImplBase {

    @Autowired
    private AdminClient kafkaAdminClient;

    @Value("${python.service.host:python-service}")
    private String pythonServiceHost;

    @Value("${python.service.grpc.port:50052}")
    private int pythonServiceGrpcPort;

    @Override
    public void createRoom(com.chatapp.grpc.RoomRequest request, 
                          io.grpc.stub.StreamObserver<com.chatapp.grpc.RoomResponse> responseObserver) {
        String topicName = "room-" + request.getRoomid();
        
        try {
            NewTopic topic = new NewTopic(topicName, 1, (short) 1);
            kafkaAdminClient.createTopics(Collections.singleton(topic)).all().get();
            
            // gRPC call to Python service using configurable host and port
            ManagedChannel channel = ManagedChannelBuilder
                    .forAddress(pythonServiceHost, pythonServiceGrpcPort)
                    .usePlaintext()
                    .build();
            
            MessageServiceGrpc.MessageServiceBlockingStub stub = 
                    MessageServiceGrpc.newBlockingStub(channel);
            
            MessageRequest msgRequest = MessageRequest.newBuilder()
                    .setUsername(request.getUsername())
                    .setRoomid(request.getRoomid())
                    .setMessage("User joined")
                    .build();
            
            stub.sendMessage(msgRequest);
            channel.shutdown();
            
            RoomResponse response = RoomResponse.newBuilder()
                    .setStatus("success")
                    .setMessage("Room created via gRPC: " + topicName)
                    .build();
            
            responseObserver.onNext(response);
            responseObserver.onCompleted();
            
        } catch (Exception e) {
            RoomResponse response = RoomResponse.newBuilder()
                    .setStatus("error")
                    .setMessage("Error: " + e.getMessage())
                    .build();
            
            responseObserver.onNext(response);
            responseObserver.onCompleted();
        }
    }
}
