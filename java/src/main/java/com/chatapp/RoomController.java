package com.chatapp;

import org.apache.kafka.clients.admin.AdminClient;
import org.apache.kafka.clients.admin.NewTopic;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.client.RestTemplate;

import java.util.Collections;

@RestController
public class RoomController {

    @Autowired
    private AdminClient kafkaAdminClient;

    private final RestTemplate restTemplate = new RestTemplate();

    @Value("${python.service.host:python-service}")
    private String pythonServiceHost;

    @Value("${python.service.http.port:8091}")
    private String pythonServiceHttpPort;

    @PostMapping("/room")
    public String createRoom(@RequestBody RoomRequest request) {
        String topicName = "room-" + request.getRoomid();
        
        NewTopic topic = new NewTopic(topicName, 1, (short) 1);
        
        try {
            kafkaAdminClient.createTopics(Collections.singleton(topic)).all().get();
            
            String pythonServiceUrl = String.format("http://%s:%s/message", 
                pythonServiceHost, pythonServiceHttpPort);
            restTemplate.postForEntity(pythonServiceUrl, request, String.class);
            
            return "Room created and Kafka topic '" + topicName + "' created successfully";
        } catch (Exception e) {
            return "Error: " + e.getMessage();
        }
    }
}

class RoomRequest {
    private String username;
    private String roomid;

    public String getUsername() { return username; }
    public void setUsername(String username) { this.username = username; }
    public String getRoomid() { return roomid; }
    public void setRoomid(String roomid) { this.roomid = roomid; }
}
