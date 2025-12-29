# Solución al Error de Base de Datos

## Problema
Error 500: "constraint violation" al crear usuarios porque el backend aún usa el campo `email` pero el schema fue cambiado a `direccion`.

## Solución
**REINICIAR EL BACKEND** para que tome los cambios del schema:

### Opción 1: Desde IDE
1. Detener la aplicación en tu IDE
2. Ejecutar nuevamente `LoansBackendApplication.java`

### Opción 2: Desde Terminal
```bash
cd /Users/ojc04152/Desktop/dev/trustbank/spring-boot-backend-loans
./mvnw spring-boot:run
```

### Opción 3: Maven
```bash
mvn clean spring-boot:run
```

## Verificación
- La base de datos H2 se recrea automáticamente con el nuevo schema
- El campo `email` ahora es `direccion`
- La aplicación Flutter funcionará correctamente

## Nota
Como usas `spring.jpa.hibernate.ddl-auto=create-drop`, la base de datos se recrea en cada reinicio, por lo que los cambios del schema se aplicarán automáticamente.