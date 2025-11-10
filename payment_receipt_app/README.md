# TrustBank Payment Receipt App

Aplicación Flutter con sistema de diseño inspirado en Nequi, usando arquitectura atómica y patrón BLoC.

## 🏠 Página Principal Estilo Nequi

### Características
- **Tarjeta de saldo**: Con toggle de visibilidad y gradiente
- **Grid de acciones**: Enviar, recargar, comprobantes, QR
- **Transacciones recientes**: Lista con iconos y estados
- **AppBar personalizada**: Saludo y notificaciones

### Componentes
- `BalanceCard`: Tarjeta de saldo con gradiente
- `ActionGrid`: Grid de acciones principales
- `RecentTransactions`: Lista de movimientos recientes

## 🔐 Sistema de Autenticación

### Login → Home
- Login exitoso navega a página principal
- Diseño estilo Nequi con gradientes
- Validación y estados de carga

## 🎨 Sistema de Diseño

### Arquitectura Atómica
- **Átomos**: TBButton, TBInput
- **Moléculas**: BalanceCard, ActionGrid, RecentTransactions
- **Organismos**: LoginCard
- **Páginas**: HomeScreen, LoginScreen

### Paleta de Colores
- **Primary**: #6C63FF (Violeta)
- **Secondary**: #00D4AA (Verde menta)
- **Success**: #4CAF50 (Verde)
- **Background**: #F8F9FA (Gris claro)

## 📱 Navegación

```
LoginScreen → HomeScreen → ReceiptListScreen
```

## 🚀 Funcionalidades

- ✅ Login con validación
- ✅ Página principal estilo Nequi
- ✅ Tarjeta de saldo con toggle
- ✅ Grid de acciones
- ✅ Transacciones recientes
- ✅ Navegación a comprobantes
- ✅ Generación de PDF

## 📁 Estructura

```
lib/
├── design_system/
│   └── components/
│       ├── atoms/
│       ├── molecules/
│       └── organisms/
├── features/
│   ├── auth/
│   └── home/
└── screens/
```

## 🛠️ Instalación

```bash
flutter pub get
flutter run
```