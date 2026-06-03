package com.bolsadeideas.springboot.backend.apirest.models.services;

import java.io.IOException;
import java.io.OutputStream;
import java.text.SimpleDateFormat;
import java.util.List;

import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.CellStyle;
import org.apache.poi.ss.usermodel.Font;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.xssf.streaming.SXSSFWorkbook;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.bolsadeideas.springboot.backend.apirest.models.dao.ILeadDao;
import com.bolsadeideas.springboot.backend.apirest.models.entity.LeadEntity;

@Service
public class LeadExportService {

    private static final String[] HEADERS = {
        "Nombre", "Apellido", "Last Call Status", "Últ. Llamada", "Asesor", "País",
        "Teléfono", "Email", "Campaña", "Fecha de Registro", "Comentarios"
    };

    private static final String DATE_FORMAT = "dd/MM/yyyy";
    private static final String DATETIME_FORMAT = "dd/MM/yyyy HH:mm";

    @Autowired
    private ILeadDao leadDao;

    /**
     * Genera un archivo Excel (.xlsx) con todos los leads ordenados por fecha de registro DESC.
     * Usa SXSSFWorkbook para streaming eficiente de memoria.
     *
     * @param outputStream OutputStream donde se escribe el archivo
     * @throws IOException si ocurre un error de escritura
     */
    public void generateExcelExport(OutputStream outputStream) throws IOException {
        SXSSFWorkbook workbook = new SXSSFWorkbook(100);
        try {
            Sheet sheet = workbook.createSheet("Leads");

            // Crear estilo para encabezados (negrita)
            CellStyle headerStyle = workbook.createCellStyle();
            Font headerFont = workbook.createFont();
            headerFont.setBold(true);
            headerStyle.setFont(headerFont);

            // Escribir fila de encabezados
            Row headerRow = sheet.createRow(0);
            for (int i = 0; i < HEADERS.length; i++) {
                Cell cell = headerRow.createCell(i);
                cell.setCellValue(HEADERS[i]);
                cell.setCellStyle(headerStyle);
            }

            // Consultar todos los leads con advisor precargado
            List<LeadEntity> leads = leadDao.findAllWithAdvisorForExport();

            // Escribir filas de datos
            SimpleDateFormat dateFormat = new SimpleDateFormat(DATE_FORMAT);
            SimpleDateFormat dateTimeFormat = new SimpleDateFormat(DATETIME_FORMAT);
            int rowIndex = 1;

            for (LeadEntity lead : leads) {
                Row row = sheet.createRow(rowIndex++);

                row.createCell(0).setCellValue(lead.getNombre() != null ? lead.getNombre() : "");
                row.createCell(1).setCellValue(lead.getApellido() != null ? lead.getApellido() : "");
                row.createCell(2).setCellValue(lead.getLastCallStatus() != null ? lead.getLastCallStatus() : "");
                row.createCell(3).setCellValue(
                    lead.getLastCallDate() != null ? dateTimeFormat.format(lead.getLastCallDate()) : ""
                );
                // Asesor
                String advisorName = "";
                if (lead.getAdvisor() != null) {
                    String firstName = lead.getAdvisor().getFirstName() != null ? lead.getAdvisor().getFirstName() : "";
                    String lastName = lead.getAdvisor().getLastName() != null ? lead.getAdvisor().getLastName() : "";
                    advisorName = (firstName + " " + lastName).trim();
                }
                row.createCell(4).setCellValue(advisorName);
                row.createCell(5).setCellValue(lead.getPais() != null ? lead.getPais() : "");
                row.createCell(6).setCellValue(lead.getTelefono() != null ? lead.getTelefono() : "");
                row.createCell(7).setCellValue(lead.getEmail() != null ? lead.getEmail() : "");
                row.createCell(8).setCellValue(lead.getCampana() != null ? lead.getCampana() : "");
                row.createCell(9).setCellValue(
                    lead.getFechaRegistro() != null ? dateFormat.format(lead.getFechaRegistro()) : ""
                );
                row.createCell(10).setCellValue(lead.getComentarios() != null ? lead.getComentarios() : "");
            }

            // Escribir al OutputStream
            workbook.write(outputStream);
        } finally {
            workbook.close();
            workbook.dispose();
        }
    }
}
