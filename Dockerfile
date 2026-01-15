FROM eclipse-temurin:17-jdk

WORKDIR /app

COPY target/demo-app-1.0-SNAPSHOT.jar app.jar

EXPOSE 8081

CMD ["java", "-jar", "app.jar"]

