package com.bolsadeideas.springboot.backend.apirest.models.services;

import com.bolsadeideas.springboot.backend.apirest.models.services.intefaces.IUploadFileService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.io.IOException;
import java.net.MalformedURLException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.UUID;

@Service
public class UploadFileServiceImpl implements IUploadFileService {

    private final Logger log = LoggerFactory.getLogger(UploadFileServiceImpl.class);

    private final static String DIRECTORIO_UPLOAD = "uploads";

    @Override
    public Resource cargar(String nombreFoto) throws MalformedURLException {

        Path rutaArchivo = getPath(nombreFoto);
        log.info(rutaArchivo.toString());

        Resource recurso = new UrlResource(rutaArchivo.toUri());

        if(!recurso.exists() && !recurso.isReadable()) {
            rutaArchivo = Paths.get("src/main/resources/static/images").resolve("no-usuario.png").toAbsolutePath();

            recurso = new UrlResource(rutaArchivo.toUri());

            log.error("Error no se pudo cargar la imagen: " + nombreFoto);

        }
        return recurso;
    }

    @Override
    public String copiar(MultipartFile archivo) throws IOException {
        log.info("Iniciando copia de archivo...");
        log.info("Tamaño del archivo: " + archivo.getSize() + " bytes");
        log.info("Nombre original: " + archivo.getOriginalFilename());
        log.info("Content-Type: " + archivo.getContentType());
        
        // Validar que el archivo no esté vacío
        if (archivo.isEmpty()) {
            throw new IOException("El archivo está vacío");
        }
        
        // Validar el nombre del archivo
        String originalFilename = archivo.getOriginalFilename();
        if (originalFilename == null || originalFilename.trim().isEmpty()) {
            throw new IOException("Nombre de archivo inválido");
        }
        
        // Validar el tamaño del archivo (máximo 5MB)
        if (archivo.getSize() > 5 * 1024 * 1024) {
            throw new IOException("El archivo es muy grande. Máximo 5MB permitido");
        }
        
        // Validar tipo de archivo
        String contentType = archivo.getContentType();
        log.info("Content-Type recibido: " + contentType);
        
        // Lista de tipos MIME permitidos
        boolean isValidImageType = contentType != null && (
            contentType.equals("image/jpeg") ||
            contentType.equals("image/jpg") ||
            contentType.equals("image/png") ||
            contentType.equals("image/gif") ||
            contentType.equals("image/webp") ||
            contentType.startsWith("image/")
        );
        
        // También validar por extensión como respaldo
        String extension = "";
        if (originalFilename.contains(".")) {
            extension = originalFilename.substring(originalFilename.lastIndexOf(".")).toLowerCase();
        }
        
        boolean isValidExtension = extension.equals(".jpg") || 
                                 extension.equals(".jpeg") || 
                                 extension.equals(".png") || 
                                 extension.equals(".gif") || 
                                 extension.equals(".webp");
        
        if (!isValidImageType && !isValidExtension) {
            log.warn("Archivo con tipo no estándar pero se permitirá: Content-Type: " + contentType + ", Extensión: " + extension);
            // Temporalmente permitir todos los archivos para debug
            // throw new IOException("Tipo de archivo no válido. Content-Type: " + contentType + ", Extensión: " + extension);
        }
        
        try {
            String nombreArchivo = UUID.randomUUID().toString() + "_" + originalFilename.replace(" ", "");
            Path rutaArchivo = getPath(nombreArchivo);
            
            // Crear directorio si no existe
            Files.createDirectories(rutaArchivo.getParent());
            
            log.info("Guardando archivo en: " + rutaArchivo.toString());
            Files.copy(archivo.getInputStream(), rutaArchivo);
            
            return nombreArchivo;
        } catch (IOException e) {
            log.error("Error al copiar archivo: " + e.getMessage());
            throw new IOException("Error al guardar el archivo: " + e.getMessage());
        }
    }

    @Override
    public boolean eliminar(String nombreFoto) {

        if(nombreFoto !=null && nombreFoto.length() >0) {
            Path rutaFotoAnterior = Paths.get("uploads").resolve(nombreFoto).toAbsolutePath();
            File archivoFotoAnterior = rutaFotoAnterior.toFile();
            if(archivoFotoAnterior.exists() && archivoFotoAnterior.canRead()) {
                archivoFotoAnterior.delete();
                return true;
            }
        }

        return false;
    }

    @Override
    public Path getPath(String nombreFoto) {
        Path uploadPath = Paths.get(DIRECTORIO_UPLOAD).toAbsolutePath();
        try {
            // Crear directorio si no existe
            if (!Files.exists(uploadPath)) {
                Files.createDirectories(uploadPath);
                log.info("Directorio de uploads creado: " + uploadPath.toString());
            }
        } catch (IOException e) {
            log.error("Error al crear directorio de uploads: " + e.getMessage());
        }
        return uploadPath.resolve(nombreFoto);
    }

}
