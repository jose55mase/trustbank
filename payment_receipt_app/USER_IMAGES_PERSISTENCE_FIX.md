# Fix: Persistencia de Imágenes de Usuario

## 🔍 Problema Identificado

Las imágenes se subían pero no se guardaban en el backend porque:

1. **Frontend** usaba endpoints incorrectos en `DocumentApiService`
2. **ApiService** no tenía métodos para subir imágenes de usuario
3. **Backend** ya tenía los endpoints correctos pero no se usaban

## ✅ Solución Implementada

### 1. **Agregados métodos al ApiService**

```dart
// Subir foto de perfil
static Future<Map<String, dynamic>> uploadProfileImage(File file, int userId)

// Subir documento frontal  
static Future<Map<String, dynamic>> uploadDocumentFront(File file, int userId)

// Subir documento trasero
static Future<Map<String, dynamic>> uploadDocumentBack(File file, int userId)

// Obtener URL de imagen
static String getUserImageUrl(String? imageName)
```

### 2. **Corregido DocumentApiService**

#### Antes (❌ Endpoints incorrectos):
```dart
// Usaba endpoints que no existían
Uri.parse('$baseUrl/documents/users/$userId/images')
```

#### Después (✅ Endpoints correctos):
```dart
// Usa los endpoints reales del backend
await ApiService.uploadProfileImage(photoFile, userId);      // /api/user/upload
await ApiService.uploadDocumentFront(frontFile, userId);     // /api/user/upload/documentFrom  
await ApiService.uploadDocumentBack(backFile, userId);      // /api/user/upload/documentBack
```

### 3. **Flujo Corregido**

```
Usuario selecciona imagen → DocumentApiService → ApiService → Backend → Base de datos
```

## 🔄 Endpoints del Backend Utilizados

### **Ya existían en UserConstructor.java:**

1. **Foto de perfil**: `POST /api/user/upload`
   - Parámetros: `archivo` (MultipartFile), `id` (Long)
   - Guarda en: `UserEntity.foto`

2. **Documento frontal**: `POST /api/user/upload/documentFrom`
   - Parámetros: `archivo` (MultipartFile), `id` (Long)  
   - Guarda en: `UserEntity.documentFrom`

3. **Documento trasero**: `POST /api/user/upload/documentBack`
   - Parámetros: `archivo` (MultipartFile), `id` (Long)
   - Guarda en: `UserEntity.documentBack`

4. **Ver imagen**: `GET /api/user/uploads/img/{nombreFoto}`
   - Retorna: Archivo de imagen

## 🗃️ Campos en Base de Datos

### **UserEntity ya tiene los campos:**
- `foto` - Nombre del archivo de foto de perfil
- `documentFrom` - Nombre del archivo documento frontal
- `documentBack` - Nombre del archivo documento trasero
- `fotoStatus` - Estado de aprobación de foto
- `documentFromStatus` - Estado de aprobación documento frontal  
- `documentBackStatus` - Estado de aprobación documento trasero

## 🧪 Flujo de Subida

### **Proceso completo:**

1. **Usuario selecciona imagen** en `UploadDocumentImagesDialog`
2. **Se convierte a File temporal** desde Uint8List
3. **ApiService llama endpoint correcto** del backend
4. **Backend guarda archivo** en servidor
5. **Backend actualiza UserEntity** con nombre del archivo
6. **Frontend guarda copia local** para vista previa
7. **Se actualiza estado** a "PENDING"

### **Ejemplo de llamada:**
```dart
// Crear archivo temporal
final photoFile = await _createTempFile(clientPhoto, 'client_photo.jpg');

// Subir al backend  
final result = await ApiService.uploadProfileImage(photoFile, userId);

// Limpiar archivo temporal
await photoFile.delete();
```

## 🎯 Resultado

Ahora cuando el usuario sube imágenes:

1. **Se guardan en el servidor** (carpeta uploads)
2. **Se persisten en base de datos** (campos foto, documentFrom, documentBack)
3. **Se pueden recuperar** con getUserById()
4. **Se muestran en la app** con estado de aprobación
5. **Los admins pueden aprobar/rechazar** desde panel

## 🔧 Archivos Modificados

### **Frontend:**
- `lib/services/api_service.dart` - Agregados métodos de subida
- `lib/services/document_api_service.dart` - Corregidos endpoints

### **Backend:**
- ✅ Ya existían todos los endpoints necesarios
- ✅ UserEntity ya tenía todos los campos
- ✅ UploadFileService ya manejaba archivos

## 🚨 Importante

- **Archivos temporales** se limpian automáticamente
- **Autenticación** incluida en headers
- **Manejo de errores** completo
- **Estados de aprobación** sincronizados
- **Vista previa local** mantenida para UX

Las imágenes ahora se guardan correctamente en el backend y persisten en la base de datos.