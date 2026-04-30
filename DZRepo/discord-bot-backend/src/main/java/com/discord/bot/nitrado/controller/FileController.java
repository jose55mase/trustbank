package com.discord.bot.nitrado.controller;

import com.discord.bot.nitrado.dto.ActionResponse;
import com.discord.bot.nitrado.dto.FileContentResponse;
import com.discord.bot.nitrado.dto.FileEntryDto;
import com.discord.bot.nitrado.service.NitradoApiClient;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * REST controller for file operations on a game server.
 * Exposes endpoints for listing, downloading, and uploading files.
 */
@RestController
@RequestMapping("/api/servers/{serviceId}/files")
public class FileController {

    private final NitradoApiClient nitradoClient;

    public FileController(NitradoApiClient nitradoClient) {
        this.nitradoClient = nitradoClient;
    }

    /**
     * Lists files and directories at the specified path on a game server.
     * Defaults to the root directory "/" if no path is provided (Req 10.4).
     *
     * @param serviceId the Nitrado service ID
     * @param path      the directory path to list (defaults to "/")
     * @return list of file and directory entries
     */
    @GetMapping
    public List<FileEntryDto> listFiles(
            @PathVariable int serviceId,
            @RequestParam(defaultValue = "/") String path) {
        return nitradoClient.listFiles(serviceId, path);
    }

    /**
     * Downloads a file from a game server and returns its content.
     *
     * @param serviceId the Nitrado service ID
     * @param path      the path of the file to download
     * @return the file content wrapped in a FileContentResponse
     */
    @GetMapping("/download")
    public FileContentResponse downloadFile(
            @PathVariable int serviceId,
            @RequestParam String path) {
        String content = nitradoClient.downloadFile(serviceId, path);
        return new FileContentResponse(content);
    }

    /**
     * Uploads a file to a game server.
     *
     * @param serviceId the Nitrado service ID
     * @param path      the destination path on the server
     * @param content   the file content to upload
     * @return confirmation response
     */
    @PostMapping("/upload")
    public ActionResponse uploadFile(
            @PathVariable int serviceId,
            @RequestParam String path,
            @RequestBody String content) {
        nitradoClient.uploadFile(serviceId, path, content);
        return new ActionResponse("success", "Archivo subido correctamente");
    }
}
