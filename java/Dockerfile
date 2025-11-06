FROM maven:3.9-eclipse-temurin-17 AS build

WORKDIR /app

COPY java/pom.xml ./
COPY java/src ./src

# Build the project (this will generate sources and package)
RUN mvn clean package -DskipTests

FROM eclipse-temurin:17-jre

WORKDIR /app

COPY --from=build /app/target/*.jar app.jar

EXPOSE 8090 9090

# CMD removed - will be specified in Kubernetes deployment
