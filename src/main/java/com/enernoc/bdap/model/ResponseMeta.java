package com.enernoc.bdap.model;

public class ResponseMeta {
    public Integer total;
    public Integer total_pages;  // returned by GET /registration_field_history
    public Integer total_records; // returned by GET /registration_field_history
    public Integer page;
    public Integer per_page;
    public String next;
    public String prev;
}
