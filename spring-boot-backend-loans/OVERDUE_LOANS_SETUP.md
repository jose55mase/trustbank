# Configuración de Préstamos Vencidos - Datos Dummy

## 📋 Resumen
Se han creado datos dummy para probar la funcionalidad de préstamos vencidos en la campaña del home.

## 🎯 Datos Incluidos

### Usuarios Adicionales (4 nuevos):
1. **Ana López** (USR004) - +1234567893
2. **Pedro Martínez** (USR005) - +1234567894
3. **Sofia Hernández** (USR006) - +1234567895
4. **Luis González** (USR007) - +1234567896

### Préstamos Vencidos (6 préstamos):

| Usuario | Monto | Tasa | Cuotas | Pagadas | Estado Vencido | Tipo |
|---------|-------|------|--------|---------|----------------|------|
| Ana López | $3,000,000 | 18% | 12 | 2 | 2 meses | Tradicional |
| Pedro Martínez | $8,000,000 | 16% | 24 | 4 | 1 mes | Tradicional |
| Sofia Hernández | $4,500,000 | 20% | 18 | 3 | 3 semanas | Fijo |
| Luis González | $6,000,000 | 15% | 15 | 1 | 1 semana | Tradicional |
| Ana López | $2,500,000 | 22% | 10 | 1 | 6 meses (crítico) | Fijo |
| Pedro Martínez | $5,500,000 | 17% | 20 | 6 | 5 días | Tradicional |

### Transacciones:
- Cada préstamo tiene historial de pagos realizados
- Incluye cálculos de interés y capital
- Diferentes métodos de pago (TRANSFER, CASH, CHECK)

### Notificaciones:
- 6 notificaciones de préstamos vencidos
- Incluyen información del usuario y días de atraso
- Tipos: OVERDUE_LOAN y CRITICAL_OVERDUE

## 🚀 Cómo Cargar los Datos

### Opción 1: Ejecutar el Script SQL Manualmente
1. Iniciar la aplicación Spring Boot
2. Acceder a H2 Console: `http://localhost:8082/h2-console`
3. Conectar con:
   - URL: `jdbc:h2:mem:loansdb`
   - Usuario: `sa`
   - Contraseña: (vacía)
4. Copiar y ejecutar el contenido de `overdue_loans_data.sql`

### Opción 2: Agregar al schema.sql (Automático)
1. Abrir `src/main/resources/schema.sql`
2. Agregar al final del archivo el contenido de `overdue_loans_data.sql`
3. Reiniciar la aplicación

## 📡 Nuevos Endpoints API

### Obtener Préstamos Vencidos
```
GET http://localhost:8082/api/loans/overdue
```
**Respuesta**: Lista de todos los préstamos con status OVERDUE

### Contar Préstamos Vencidos
```
GET http://localhost:8082/api/loans/overdue/count
```
**Respuesta**: Número total de préstamos vencidos
```json
6
```

## 💡 Uso en Flutter

### Ejemplo de Integración:

```dart
// Obtener préstamos vencidos
Future<List<Loan>> getOverdueLoans() async {
  final response = await http.get(
    Uri.parse('http://localhost:8082/api/loans/overdue'),
  );
  
  if (response.statusCode == 200) {
    List<dynamic> data = json.decode(response.body);
    return data.map((json) => Loan.fromJson(json)).toList();
  }
  throw Exception('Error al cargar préstamos vencidos');
}

// Obtener cantidad de préstamos vencidos
Future<int> getOverdueLoansCount() async {
  final response = await http.get(
    Uri.parse('http://localhost:8082/api/loans/overdue/count'),
  );
  
  if (response.statusCode == 200) {
    return int.parse(response.body);
  }
  throw Exception('Error al contar préstamos vencidos');
}
```

### Widget de Campaña en Home:

```dart
FutureBuilder<int>(
  future: getOverdueLoansCount(),
  builder: (context, snapshot) {
    if (snapshot.hasData && snapshot.data! > 0) {
      return Card(
        color: Colors.red[50],
        child: ListTile(
          leading: Icon(Icons.warning, color: Colors.red),
          title: Text('Préstamos Vencidos'),
          subtitle: Text('${snapshot.data} préstamos requieren atención'),
          trailing: Icon(Icons.arrow_forward_ios),
          onTap: () {
            // Navegar a lista de préstamos vencidos
          },
        ),
      );
    }
    return SizedBox.shrink();
  },
)
```

## 🎨 Sugerencias de UI

### Indicadores Visuales:
- 🔴 **Crítico** (>90 días): Rojo intenso
- 🟠 **Alto** (30-90 días): Naranja
- 🟡 **Medio** (15-30 días): Amarillo
- 🟢 **Bajo** (<15 días): Amarillo claro

### Información a Mostrar:
- Nombre del cliente
- Monto del préstamo
- Días de atraso
- Monto de la cuota vencida
- Botón de contacto rápido

## 🔧 Verificación

Para verificar que los datos se cargaron correctamente:

```bash
# Contar préstamos vencidos
curl http://localhost:8082/api/loans/overdue/count

# Ver todos los préstamos vencidos
curl http://localhost:8082/api/loans/overdue

# Ver todos los préstamos
curl http://localhost:8082/api/loans
```

## 📝 Notas Importantes

1. Los datos se cargan en memoria H2, se pierden al reiniciar
2. Las fechas están configuradas para simular diferentes niveles de atraso
3. El status OVERDUE debe existir en el enum LoanStatus
4. Los endpoints están protegidos por CORS para permitir acceso desde Flutter

## 🎯 Próximos Pasos

1. Implementar lógica automática para cambiar status a OVERDUE
2. Crear sistema de alertas automáticas
3. Agregar cálculo de penalidades por mora
4. Implementar recordatorios automáticos
5. Dashboard de gestión de cobranza
