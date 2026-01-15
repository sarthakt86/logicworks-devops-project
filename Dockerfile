# Step 1: Base image
FROM openjdk:17-jdk-slim

# Step 2: Working directory
WORKDIR /app

# Step 3: Copy built jar file into container
COPY target/demo-app-1.0-SNAPSHOT.jar app.jar

# Step 4: Expose a different port (8081 instead of 8080)
EXPOSE 8081

# Step 5: Command to run the app
ENTRYPOINT ["java","-jar","app.jar"]
