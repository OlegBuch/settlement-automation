package com.enernoc.bdap.model;

public enum HttpOp {

    GET, POST, PUT, PATCH, DELETE;

    public static HttpOp get(String typeName) {
        return HttpOp.valueOf(typeName.toUpperCase());
    }

}
