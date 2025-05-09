# Usa una imagen base compatible con Java 10
FROM openjdk:10-jdk-slim

LABEL authors="jose.castaneda"

# Crea un directorio para la app
WORKDIR /app

# Copia el JAR generado por Spring Boot
COPY target/spring-boot-backend-apirest-0.0.1-SNAPSHOT.jar app.jar

# Expón el puerto que uses (por defecto 8080)
EXPOSE 8081

# Comando para ejecutar la app
ENTRYPOINT ["java", "-jar", "app.jar"]

# docker build -t springboot-app-security .
# docker run -d -p 8082:8082 --name springboot-app-security springboot-app-security
