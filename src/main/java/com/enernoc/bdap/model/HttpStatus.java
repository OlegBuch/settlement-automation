package com.enernoc.bdap.model;


import static org.junit.jupiter.api.Assertions.fail;

public class HttpStatus {

    public int code;
    public String message = "";
    public String details = "";

    public static HttpStatus build() {
        return new HttpStatus();
    }

    public HttpStatus withCode(int code) {
        this.code = code;
        this.message = switch (code) {
            case 200 -> "OK";
            case 201 -> "Created";
            case 204 -> "No Content";
            case 400 -> "Bad Request";
            case 401 -> "Unauthorized";
            case 403 -> "Forbidden";
            case 404 -> "Not Found";
            case 409 -> "Conflict";
            case 500 -> "Internal Server Error";
            case 501 -> "Not Implemented";
            default -> fail("Unsupported status code");
        };
        return this;
    }

    public HttpStatus withDetails(String details) {
        this.details = details;
        return this;
    }

    public HttpStatus withMessage(String msg) {
        this.message = msg;
        return this;
    }

    public int getCode() {
        return this.code;
    }

}
