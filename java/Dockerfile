FROM maven:3.9-eclipse-temurin-17 AS build

WORKDIR /app

COPY java/pom.xml ./
COPY java/src ./src
COPY java/target/generated-sources ./target/generated-sources

# Use package instead of clean package to preserve generated sources
RUN mvn package -DskipTests

FROM eclipse-temurin:17-jre

WORKDIR /app

COPY --from=build /app/target/*.jar app.jar

EXPOSE 8090 9090

CMD ["java", "-jar", "app.jar"]
