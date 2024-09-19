package com.bolsadeideas.springboot.backend.apirest.utils;



public class RestResponse {

    private Integer responseCode;
    private String message;


    private Object data;


    public RestResponse(Integer responseCode) {
        super();
        this.responseCode = responseCode;
    }

    public RestResponse(Integer responseCode, String message) {
        super();
        this.responseCode = responseCode;
        this.message = message;
    }

    public RestResponse(Integer responseCode, String message, Object objet) {
        /// Esto es un comentario
        super();
        this.responseCode = responseCode;
        this.message = message;
        this.data = objet;
    }

    public Integer getResponseCode() {
        return responseCode;
    }

    public void setResponseCode(Integer responseCode) {
        this.responseCode = responseCode;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    public Object getData() {
        return data;
    }

    public void setData(Object data) {
        this.data = data;
    }
}