# Room Service

## Prerequisites
- Java 17+
- Maven
- Kafka running on localhost:9092

## Setup SSL (Optional - for HTTPS)
For testing without SSL, remove SSL config from application.properties

To generate keystore:
```bash
keytool -genkeypair -alias tomcat -keyalg RSA -keysize 2048 -storetype PKCS12 -keystore src/main/resources/keystore.p12 -validity 3650 -storepass changeit
```

## Run Kafka (if not running)
```bash
# Start Zookeeper
bin/zookeeper-server-start.sh config/zookeeper.properties

# Start Kafka
bin/kafka-server-start.sh config/server.properties
```

## Build and Run
```bash
mvn clean install
mvn spring-boot:run
```

## Test
```bash
curl -k -X POST https://localhost:8090/room \
  -H "Content-Type: application/json" \
  -d '{"username":"john","roomid":"room123"}'
```
