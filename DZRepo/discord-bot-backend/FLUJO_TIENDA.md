# 🏪 Flujo de la Tienda — TNT Market

## Diagrama del flujo completo

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         FLUJO DE COMPRA (Discord)                            │
└─────────────────────────────────────────────────────────────────────────────┘

  JUGADOR                          BOT                           NITRADO
  ───────                          ───                           ───────

  1. Click "🛒 Abrir Tienda"
       │
       ▼
  ┌──────────────┐
  │ Ver Catálogo │ ◄─── Bot muestra embed con productos disponibles
  │ + Botón      │      ID, nombre, precio, categoría
  │ "🛍️ Comprar" │
  └──────┬───────┘
         │
  2. Click "🛍️ Comprar"
         │
         ▼
                              ┌─────────────────────────┐
                              │ Validar:                 │
                              │ • ¿Jugador vinculado?    │
                              │   NO → "Usa /vincular"   │
                              │   SÍ → continuar        │
                              └───────────┬─────────────┘
                                          │
                                          ▼
                              ┌─────────────────────────┐         ┌──────────────┐
                              │ Consultar últimas        │────────►│ GET logs ADM │
                              │ 3 posiciones del jugador │◄────────│ del servidor │
                              └───────────┬─────────────┘         └──────────────┘
                                          │
                                          │ Parsea: pos=<X, Z, Y>
                                          │ Deduplica (< 5m = misma ubicación)
                                          ▼
  ┌──────────────────────────────────────────────────────┐
  │  📍 Confirma tu ubicación de entrega                  │
  │                                                      │
  │  Jugador: xXTORRESXx 9224                           │
  │                                                      │
  │  ┌────────────────────────────────────────────────┐  │
  │  │ ▼ Selecciona dónde entregar tus pedidos        │  │
  │  ├────────────────────────────────────────────────┤  │
  │  │ Posición 1 — 16:25:49                          │  │
  │  │   X: 4970.1 | Z: 6789.6 | Altura: 266.0       │  │
  │  │ Posición 2 — 15:10:22                          │  │
  │  │   X: 3200.5 | Z: 8450.2 | Altura: 180.3       │  │
  │  │ Posición 3 — 14:45:01                          │  │
  │  │   X: 6100.0 | Z: 9200.1 | Altura: 310.5       │  │
  │  └────────────────────────────────────────────────┘  │
  └──────────────────────────┬───────────────────────────┘
                             │
  3. Selecciona "Posición 1"
                             │
                             ▼
  ┌──────────────────────────────────────────────────────┐
  │  🛒 Sesión de Compra Activa                          │
  │                                                      │
  │  📍 Ubicación de entrega:                            │
  │     X: 4970.1 | Z: 6789.6 | Altura: 266.0          │
  │                                                      │
  │  ✅ Ubicación confirmada.                            │
  │  Haz click en ➕ Agregar Producto para comprar.      │
  │                                                      │
  │  ┌───────────────────┐  ┌──────────────────┐        │
  │  │ ➕ Agregar Producto│  │ 📋 Ver Catálogo  │        │
  │  └───────────────────┘  └──────────────────┘        │
  └──────────────────────────┬───────────────────────────┘
                             │
  4. Click "➕ Agregar Producto"
                             │
                             ▼
  ┌──────────────────────────┐
  │  Modal: Agregar Producto │
  │  ┌─────────────────────┐ │
  │  │ ID Producto: 1      │ │
  │  │ Cantidad: 2         │ │
  │  └─────────────────────┘ │
  └──────────────┬───────────┘
                 │
  5. Envía modal
                 │
                 ▼
                              ┌─────────────────────────┐
                              │ Procesar compra:         │
                              │ • Verificar balance      │
                              │ • Debitar TNT Coins      │
                              │ • Crear orden PENDING    │
                              │ • Subir archivo custom   │
                              │ • Registrar en gameplay  │
                              └───────────┬─────────────┘
                                          │
                                          ▼
  ┌──────────────────────────────────────────────────────┐
  │  🛒 Sesión de Compra Activa                          │
  │                                                      │
  │  📍 Ubicación de entrega:                            │
  │     X: 4970.1 | Z: 6789.6 | Altura: 266.0          │
  │                                                      │
  │  📦 Pedidos en esta sesión (1):                      │
  │  • #1 — 2x AKM (1000 TNT Coins)                    │
  │                                                      │
  │  💰 Total gastado: 1000 TNT Coins                   │
  │                                                      │
  │  ┌───────────────────┐  ┌──────────────────┐        │
  │  │ ➕ Agregar Producto│  │ 📋 Ver Catálogo  │        │
  │  └───────────────────┘  └──────────────────┘        │
  └──────────────────────────┬───────────────────────────┘
                             │
  6. Click "➕ Agregar Producto" (puede repetir sin límite)
                             │
                             ▼
  ┌──────────────────────────┐
  │  Modal: Agregar Producto │
  │  ┌─────────────────────┐ │
  │  │ ID Producto: 3      │ │
  │  │ Cantidad: 1         │ │
  │  └─────────────────────┘ │
  └──────────────┬───────────┘
                 │
                 ▼
  ┌──────────────────────────────────────────────────────┐
  │  🛒 Sesión de Compra Activa                          │
  │                                                      │
  │  📍 Ubicación de entrega:                            │
  │     X: 4970.1 | Z: 6789.6 | Altura: 266.0          │
  │                                                      │
  │  📦 Pedidos en esta sesión (2):                      │
  │  • #1 — 2x AKM (1000 TNT Coins)                    │
  │  • #2 — 1x Casco Balístico (500 TNT Coins)         │
  │                                                      │
  │  💰 Total gastado: 1500 TNT Coins                   │
  │                                                      │
  │  ┌───────────────────┐  ┌──────────────────┐        │
  │  │ ➕ Agregar Producto│  │ 📋 Ver Catálogo  │        │
  │  └───────────────────┘  └──────────────────┘        │
  └──────────────────────────────────────────────────────┘

         + Cada compra se publica en #pedidos-mercado


┌─────────────────────────────────────────────────────────────────────────────┐
│                    SUBIDA DE ARCHIVOS A NITRADO (por cada compra)            │
└─────────────────────────────────────────────────────────────────────────────┘

  Por cada "➕ Agregar Producto" exitoso:

  1. Se crea un archivo JSON:

     /custom/shop_xXTORRESXx9224_1.json
     {
       "Objects": [
         {
           "name": "AKM",
           "pos": [4970.1, 266.0, 6789.6],
           "ypr": [0.0, 0.0, 0.0],
           "scale": 1.0,
           "enableCEPersistency": 0
         },
         {
           "name": "AKM",
           "pos": [4970.6, 266.0, 6790.1],   ← offset 0.5m para no stackear
           "ypr": [0.0, 0.0, 0.0],
           "scale": 1.0,
           "enableCEPersistency": 0
         }
       ]
     }

  2. Se agrega al objectSpawnersArr de cfggameplay.json:

     "objectSpawnersArr": [
       "custom/testcontainers.json",
       "custom/spawncamp.json",
       ...
       "custom/shop_xXTORRESXx9224_1.json"   ← NUEVO
     ]


┌─────────────────────────────────────────────────────────────────────────────┐
│                     ENTREGA (Automática post-restart)                        │
└─────────────────────────────────────────────────────────────────────────────┘

  ShopDeliveryScheduler (cada 60s)
  ─────────────────────────────────

  ┌───────────────────────┐
  │ Consulta estado server │──────► Nitrado API: getServerStatus()
  └───────────┬───────────┘
              │
              │  ¿Server pasó de OFFLINE → ONLINE?
              │
              ├── NO → esperar siguiente ciclo
              │
              └── SÍ → ¡Restart detectado! Items ya spawnearon
                        │
                        ▼
              ┌─────────────────────────┐
              │ confirmDelivery()        │
              │                         │
              │ Para cada orden PENDING: │
              │                         │
              │ 1. Marcar → DELIVERED    │
              │                         │
              │ 2. Descargar             │
              │    cfggameplay.json      │
              │                         │
              │ 3. Remover ruta del      │
              │    objectSpawnersArr:    │
              │    "custom/shop_...json" │
              │                         │
              │ 4. Re-subir              │
              │    cfggameplay.json      │
              │                         │
              │ 5. Borrar archivo        │
              │    custom/shop_...json   │
              └─────────────────────────┘
                        │
                        ▼
              ┌─────────────────────────┐
              │ ✅ Servidor limpio       │
              │ Items entregados         │
              │ Archivos removidos       │
              │ Listo para próximo ciclo │
              └─────────────────────────┘


┌─────────────────────────────────────────────────────────────────────────────┐
│                     MAPEO DE COORDENADAS                                     │
└─────────────────────────────────────────────────────────────────────────────┘

  Log del servidor (ADM):
  16:25:49 | Player "xXTORRESXx 9224" (id=A49... pos=<4970.1, 6789.6, 266.0>)
                                                     ▲       ▲       ▲
                                                     X       Z       Y
                                                   (este)  (norte) (alto)

                                    │ Conversión
                                    ▼

  JSON Object Spawner (custom/*.json):
  "pos": [4970.1, 266.0, 6789.6]
           ▲       ▲       ▲
           X       Y       Z
         (este)  (alto)  (norte)

  Fórmula: log <X, Z, Y> → json [X, Y, Z]
            log[0] → json[0]  (X = X)
            log[1] → json[2]  (Z del log = Z del json)
            log[2] → json[1]  (Y del log = Y del json / altura)


┌─────────────────────────────────────────────────────────────────────────────┐
│                     RESUMEN DE PASOS                                         │
└─────────────────────────────────────────────────────────────────────────────┘

  COMPRA (primera vez):
  ┌───┐   ┌───┐   ┌───┐   ┌───┐   ┌───┐
  │ 1 │──►│ 2 │──►│ 3 │──►│ 4 │──►│ 5 │
  └───┘   └───┘   └───┘   └───┘   └───┘
   Abrir   Comprar  Select  Modal   Compra
   tienda  (valid.) posición prod.  exitosa

  AGREGAR MÁS PRODUCTOS (sin re-confirmar posición):
  ┌───┐   ┌───┐
  │ 1 │──►│ 2 │  ← Se repite cuantas veces quiera
  └───┘   └───┘
   ➕ Add  Compra
   product exitosa

  ENTREGA (automática):
  ┌───┐   ┌───┐   ┌───┐
  │ 1 │──►│ 2 │──►│ 3 │
  └───┘   └───┘   └───┘
   Server  Marcar  Limpiar
   online  DELIVER archivos
```
