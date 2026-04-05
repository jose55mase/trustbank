# Guía de Configuración DayZ - Servidor Nitrado

Esta guía explica cada archivo de configuración de tu servidor DayZ en Nitrado, qué hace y cómo modificarlo.

---

## Estructura General del Proyecto

```
├── cfggameplay.json          → Configuración principal de gameplay
├── cfgeconomycore.xml        → Motor de economía central (clases raíz y logs)
├── cfgenvironment.xml        → Territorios de animales y zombies
├── cfgeventgroups.xml        → Grupos de objetos estáticos (trenes, accidentes)
├── cfgeventspawns.xml        → Posiciones de spawn de eventos (vehículos, helicrash, etc.)
├── cfgweather.xml            → Clima (lluvia, niebla, viento, tormentas)
├── cfgplayerspawnpoints.xml  → Puntos de spawn de jugadores nuevos
├── cfgrandompresets.xml      → Presets de loot aleatorio (comida, herramientas, munición)
├── cfgspawnabletypes.xml     → Qué items aparecen dentro de mochilas, ropa, etc.
├── cfgignorelist.xml         → Items deshabilitados del spawn
├── cfglimitsdefinition.xml   → Categorías, tags y zonas de loot
├── cfglimitsdefinitionuser.xml → Combinaciones personalizadas de zonas/tiers
├── cfgEffectArea.json        → Zonas contaminadas y efectos de área
├── cfgundergroundtriggers.json → Triggers para zonas subterráneas
├── db/
│   ├── economy.xml           → Control de qué sistemas se guardan/cargan
│   ├── types.xml             → Definición de TODOS los items (cantidad, spawn, tier)
│   ├── events.xml            → Eventos de spawn (animales, zombies, items especiales)
│   ├── globals.xml           → Variables globales del servidor
│   └── messages.xml          → Mensajes automáticos del servidor
├── custom/                   → Objetos personalizados en el mapa (árboles, edificios, etc.)
└── env/                      → Archivos de territorios de animales
```

---

## Archivos Principales

### cfggameplay.json
El archivo más importante para personalizar la experiencia de juego.

| Sección | Qué controla |
|---------|-------------|
| `GeneralData` | Daño a bases (`disableBaseDamage: true`), daño a contenedores, diálogo de respawn |
| `PlayerData.StaminaData` | Stamina del jugador. Valores en `0.0` = stamina infinita para sprint |
| `PlayerData.spawnGearPresetFiles` | Archivo JSON con el equipo inicial del jugador (`custom/pj.json`) |
| `PlayerData.MovementData` | Velocidad de rotación, tiempo para sprint |
| `PlayerData.DrowningData` | Velocidad de ahogamiento |
| `WorldsData.objectSpawnersArr` | Lista de archivos JSON que colocan objetos custom en el mapa |
| `WorldsData.environmentMinTemps/MaxTemps` | Temperaturas por mes (array de 12 valores, enero a diciembre) |
| `BaseBuildingData` | Todas las restricciones de construcción deshabilitadas (`true` = sin restricciones) |
| `MapData` | Mapa visible sin necesidad de tener el item, posición del jugador visible |

**Tu servidor tiene:** Stamina infinita para sprint, construcción sin restricciones, daño a bases deshabilitado, mapa con posición visible.

---

### db/types.xml (22,000+ líneas)
Define CADA item del juego. Es el archivo más grande y el que más vas a editar.

```xml
<type name="AK101">
    <nominal>20</nominal>        <!-- Cantidad ideal en el mapa -->
    <lifetime>14400</lifetime>   <!-- Segundos antes de desaparecer (14400 = 4 horas) -->
    <restock>3600</restock>      <!-- Segundos para re-spawnear (3600 = 1 hora) -->
    <min>12</min>                <!-- Mínimo antes de que el servidor spawnee más -->
    <quantmin>30</quantmin>      <!-- Munición mínima al spawnear (-1 = no aplica) -->
    <quantmax>80</quantmax>      <!-- Munición máxima al spawnear -->
    <cost>100</cost>             <!-- Prioridad de spawn (100 = normal) -->
    <flags count_in_cargo="0" count_in_hoarder="0" count_in_map="1" count_in_player="0" crafted="0" deloot="0"/>
    <category name="weapons"/>
    <usage name="Military"/>     <!-- Dónde aparece -->
    <value name="Tier4"/>        <!-- En qué zona del mapa -->
</type>
```

**Campos clave:**
- `nominal` = 0 → El item NO aparece en el mapa
- `crafted="1"` → Solo se obtiene crafteando, no spawneando
- `deloot="1"` → Se elimina del loot dinámico cuando hay muchos
- `count_in_hoarder="1"` → Cuenta los que están guardados en bases

**Zonas de uso (usage):** Military, Police, Medic, Firefighter, Industrial, Farm, Coast, Town, Village, Hunting, Office, School, Prison, ContaminatedArea

**Tiers (value):** Tier1 (costa/sur), Tier2, Tier3, Tier4 (norte/militar/mejor loot)

---

### db/events.xml
Define eventos de spawn para animales, zombies e items especiales.

```xml
<event name="AnimalBear">
    <nominal>10</nominal>       <!-- Grupos de osos en el mapa -->
    <min>2</min>                <!-- Mínimo de grupos activos -->
    <max>2</max>                <!-- Máximo de hijos por grupo -->
    <lifetime>180</lifetime>    <!-- Minutos de vida -->
    <saferadius>200</saferadius><!-- Radio seguro entre grupos -->
    <position>fixed</position>  <!-- fixed = posiciones predefinidas, player = cerca del jugador -->
    <active>1</active>          <!-- 1 = activo, 0 = desactivado -->
    <children>
        <child type="Animal_UrsusArctos" min="1" max="1" lootmin="0" lootmax="0"/>
    </children>
</event>
```

**Tu servidor tiene:**
- Zombies con cantidades altas (nominal 50-150), incluyendo zombies NBC, militares, y Santa
- Animales: osos, lobos, ciervos, vacas, cabras, ovejas, jabalíes, cerdos, gallinas
- Eventos especiales: `InfectedBunkerNBC`, `InfectedBunkerTow` (zombies de bunker)

---

### db/globals.xml
Variables globales que afectan todo el servidor.

| Variable | Valor | Significado |
|----------|-------|-------------|
| `AnimalMaxCount` | 200 | Máximo de animales simultáneos |
| `ZombieMaxCount` | 1000 | Máximo de zombies simultáneos |
| `CleanupLifetimeDeadPlayer` | 3600 | Cuerpo de jugador muerto dura 1 hora |
| `CleanupLifetimeRuined` | 33000 | Items arruinados duran ~9 horas |
| `FlagRefreshMaxDuration` | 3456000 | Bandera de territorio dura 40 días |
| `LootDamageMax` | 0.82 | Daño máximo con el que aparece el loot |
| `SpawnInitial` | 1200 | Items que se generan al iniciar el servidor |
| `TimeLogin` | 5 | Segundos de espera al conectar |
| `TimeLogout` | 15 | Segundos de espera al desconectar |
| `TimePenalty` | 20 | Penalización por combat log |
| `ZoneSpawnDist` | 300 | Distancia de activación de zonas de spawn |

---

### db/economy.xml
Controla qué sistemas se guardan y cargan entre reinicios.

```xml
<dynamic init="1" load="1" respawn="1" save="1"/>   <!-- Loot dinámico: se guarda -->
<animals init="1" load="0" respawn="1" save="0"/>   <!-- Animales: NO se guardan, respawnean -->
<zombies init="1" load="0" respawn="1" save="0"/>   <!-- Zombies: NO se guardan, respawnean -->
<vehicles init="1" load="1" respawn="1" save="1"/>  <!-- Vehículos: se guardan -->
<player init="1" load="1" respawn="1" save="1"/>    <!-- Jugadores: se guardan -->
```

---

### db/messages.xml
Mensajes automáticos que ven los jugadores.

Tu servidor tiene:
- Mensaje de reinicio con countdown de 120 minutos (en inglés y español)
- Link de Discord que se muestra cada 50 minutos y al conectar

---

### cfgweather.xml
Controla el clima. **Actualmente deshabilitado** (`enable="0"`).

Si lo activas (`enable="1"`), puedes controlar:
- **Overcast** (nubosidad): rango 0-1, tiempos de cambio
- **Fog** (niebla): rango 0-1
- **Rain** (lluvia): requiere overcast > 0.5 para activarse
- **Wind**: velocidad máxima 20 m/s
- **Storm**: rayos cuando overcast > 0.7

---

### cfgplayerspawnpoints.xml
Dónde aparecen los jugadores nuevos.

**Puntos de spawn actuales:**
- Kamarovo (3997, 2497)
- Zeleno (2759, 5524)
- Cherno (8686, 2567)
- Solnichy (13313, 6439)
- Krasno (10887, 12225)

---

### cfgrandompresets.xml
Define "paquetes" de loot que se reutilizan en otros archivos. Cada preset tiene un nombre y una probabilidad.

| Preset | Contenido | Usado en |
|--------|-----------|----------|
| `foodHermit` | Atún, sardinas, manzana | Cabañas aisladas |
| `foodVillage/foodCity` | Sodas, enlatados, snacks | Pueblos y ciudades |
| `foodArmy` | Bacon táctico, cantimplora | Zonas militares |
| `toolsMedic` | Vendas, antibióticos, vitaminas | Hospitales |
| `toolsPolice` | Radio, linterna, bengalas | Estaciones de policía |
| `ammoPolice` | 9x19, 556x45, 545x39 | Estaciones de policía |
| `ammoArmy` | .45ACP, 762x39, 762x54 | Zonas militares |
| `mixVillage/mixHunter/mixArmy` | Mezcla de comida + munición + herramientas | Ropa y mochilas |
| `grenades` | Humo, flash, RGD5 | Zonas militares |

También define presets de attachments (gorros, mochilas, chalecos) para zombies y ropa.

---

### cfgspawnabletypes.xml (4,400+ líneas)
Define qué items aparecen DENTRO de otros items (mochilas, ropa, cascos).

```xml
<!-- Mochilas militares traen loot militar -->
<type name="AssaultBag_Ttsko">
    <cargo preset="mixArmy" />
    <cargo preset="mixArmy" />
    <cargo preset="mixArmy" />
</type>

<!-- Contenedores de almacenamiento son "hoarders" -->
<type name="Barrel_Blue">
    <hoarder />
</type>

<!-- Items con daño controlado -->
<type name="NVGoggles">
    <damage min="0.0" max="0.32" />
</type>
```

**Tu MountainBag_Red tiene una configuración especial:** Aparece con 3 PorkCan_Opened (carne de cerdo abierta).

---

### cfgEffectArea.json
Define zonas contaminadas y efectos especiales en el mapa.

**Zonas contaminadas (requieren equipo NBC):**
- Ship-SW, Ship-NE, Ship-Central (barco naufragado)
- Pavlovo-North, Pavlovo-South (base militar)
- Bunkertox (bunker de Tisy)

**Zonas de niebla decorativa (sin daño):**
- tisy-Norte, tisy-sur, tisy-este (niebla spooky alrededor de Tisy)
- bunker-neblina

**Items fijos spawneados:**
- NVGoggles + NVGHeadstrap en posición (6785, 2508)
- 5x Hacksaw en la misma posición
- 2x SledgeHammer en la misma posición

---

### cfgignorelist.xml
Items que el servidor ignora completamente (no aparecen).

Items deshabilitados: Bandage, BandanaMasks, CattleProd, DallasMask, Defibrillator, EngineOil, HescoBox, EasterEgg, HoxtonMask, StunBaton, TransitBus, WolfMask, Spear, Mag_STANAGCoupled_30Rnd, Wreck_Mi8

---

### cfglimitsdefinition.xml
Define las categorías válidas para el sistema de loot.

**Categorías:** tools, containers, clothes, lootdispatch, food, weapons, books, explosives

**Tags de posición:** floor (suelo), shelves (estantes), ground (terreno)

**Zonas de uso:** Military, Police, Medic, Firefighter, Industrial, Farm, Coast, Town, Village, Hunting, Office, School, Prison, Lunapark, SeasonalEvent, ContaminatedArea, Historical

**Tiers:** Tier1 (costa sur), Tier2, Tier3, Tier4 (norte/militar), Unique

---

### cfglimitsdefinitionuser.xml
Combinaciones personalizadas para simplificar la asignación de loot.

| Nombre | Combina |
|--------|---------|
| `TownVillage` | Town + Village |
| `TownVillageOfficeSchool` | Town + Village + Office + School |
| `Tier12` | Tier1 + Tier2 |
| `Tier34` | Tier3 + Tier4 |
| `Tier1234` | Todos los tiers |

---

### cfgeconomycore.xml
Configuración del motor de economía central.

Define las clases raíz del juego (armas, magazines, inventario, casas, personajes, zombies/animales, vehículos) y valores por defecto para el sistema dinámico de loot.

**Logs deshabilitados** (todos en `false`): loot spawn, cleanup, respawn, zombies, vehículos. Solo `log_hivewarning` y `log_missionfilewarning` están activos.

---

### cfgeventgroups.xml
Grupos de objetos estáticos que aparecen juntos (trenes abandonados, accidentes).

Ejemplos: `Train_Abandoned_Cherno`, `Train_Accident_Electro`, `Train_Mil_Kamenka`. Cada grupo define posiciones relativas de vagones, contenedores y vehículos destruidos.

---

### cfgeventspawns.xml
Posiciones exactas donde pueden aparecer los eventos.

Incluye posiciones para: vehículos (Sedan, Hatchback, Offroad), helicópteros caídos (`StaticHeliCrash`), árboles de Navidad, fogatas, zonas contaminadas dinámicas, y el trineo de Santa.

---

### Carpeta custom/
Archivos JSON que colocan objetos 3D en el mapa (árboles, edificios, decoraciones).

Cada archivo corresponde a una zona: `Bor.json`, `Dolina.json`, `Gorka.json`, etc.

Subcarpetas `NatureOverhaul` y `NatureOverhaulConsoleDayZ` contienen versiones alternativas con más vegetación.

Formato:
```json
{
    "name": "DZ\\plants\\tree\\t_robiniapseudoacacia_3f.p3d",
    "pos": [3332.06, 184.89, 3833.67],
    "ypr": [0, 0, 0],
    "scale": 1
}
```

---

## Consejos Rápidos

- Para **aumentar loot**: sube `nominal` y `min` en `db/types.xml`
- Para **más zombies**: sube `nominal` y `min` en los eventos `Infected*` de `db/events.xml`
- Para **más vehículos**: agrega más posiciones en `cfgeventspawns.xml` y sube nominal en `db/types.xml`
- Para **desactivar un item**: pon `nominal=0` y `min=0` en `db/types.xml`, o agrégalo a `cfgignorelist.xml`
- Para **cambiar equipo inicial**: edita `custom/pj.json`
- Para **activar clima dinámico**: cambia `enable="0"` a `enable="1"` en `cfgweather.xml`
- Después de cambios, **reinicia el servidor** desde el panel de Nitrado
