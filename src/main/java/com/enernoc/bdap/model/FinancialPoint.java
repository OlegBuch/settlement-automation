package com.enernoc.bdap.model;

// <CONFLUENCE_URL>/display/XP/Settlement+Data+Service+-+Data+Model

public class FinancialPoint {
    public Long id;
    public String level_id; // Atlas UUID
    public String level_type;
    public String financial_point_id; // Atlas UUID
    public Integer channel_id;
    public String financial_point_type;
    public String start_dttm_utc;
    public String end_dttm_utc;
    public String zone_id; // Atlas UUID
    public String last_updated_dttm_utc;
    public String last_updated_by;
}
