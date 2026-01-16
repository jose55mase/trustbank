# Endpoints para Módulo Home - Filtrado de Préstamos

## 🎯 **Nuevos Endpoints Agregados**

### 1. **Préstamos Activos** (Para el Home principal)
```bash
GET /api/loans/active
```
**Uso:**
```bash
curl -X GET http://localhost:8082/api/loans/active
```
**Respuesta:** Lista solo préstamos con status `ACTIVE`

### 2. **Préstamos Vencidos** (Consulta separada si es necesario)
```bash
GET /api/loans/overdue
```
**Uso:**
```bash
curl -X GET http://localhost:8082/api/loans/overdue
```
**Respuesta:** Lista solo préstamos con status `OVERDUE`
**Nota:** Este endpoint está en `OverdueLoanController`

### 3. **Estadísticas del Home** (Recomendado para el módulo home)
```bash
GET /api/loans/home-stats
```
**Uso:**
```bash
curl -X GET http://localhost:8082/api/loans/home-stats
```
**Respuesta:**
```json
{
  "activeLoansCount": 2,
  "overdueLoansCount": 1,
  "activeLoans": [
    {
      "id": 1,
      "user": {...},
      "amount": 5000000,
      "status": "ACTIVE",
      ...
    }
  ],
  "overdueLoans": [
    {
      "id": 3,
      "user": {...},
      "amount": 2000000,
      "status": "OVERDUE",
      ...
    }
  ]
}
```

## 🏠 **Implementación Recomendada para el Home**

### Opción 1: Un solo endpoint (Recomendado)
```dart
// En Flutter - Obtener todo en una sola llamada
final response = await http.get('$baseUrl/api/loans/home-stats');
final data = json.decode(response.body);

List<Loan> activeLoans = data['activeLoans'];
List<Loan> overdueLoans = data['overdueLoans'] ?? [];
int activeCount = data['activeLoansCount'];
int overdueCount = data['overdueLoansCount'];
```

### Opción 2: Llamadas separadas
```dart
// Solo préstamos activos para el home principal
final activeLoans = await http.get('$baseUrl/api/loans/active');

// Préstamos vencidos solo si se necesitan
if (showOverdueSection) {
  final overdueLoans = await http.get('$baseUrl/api/loans/overdue');
}
```

## 📊 **Ventajas del Filtrado**

1. **Performance**: Solo se consultan los préstamos necesarios
2. **UI Limpia**: El home solo muestra préstamos activos
3. **Separación**: Los vencidos se pueden mostrar en sección aparte
4. **Flexibilidad**: Puedes elegir cuándo mostrar cada tipo

## 🔄 **Estados de Préstamos**

- `ACTIVE`: Préstamos en curso (mostrar en home)
- `OVERDUE`: Préstamos vencidos (mostrar aparte si es necesario)
- `COMPLETED`: Préstamos completados (no mostrar en home)
- `CANCELLED`: Préstamos cancelados (no mostrar en home)

## 🚀 **Para Probar**

1. Ejecutar el backend: `mvn spring-boot:run`
2. Usar los endpoints con curl o desde Flutter
3. El endpoint `/home-stats` es el más completo para el módulo home