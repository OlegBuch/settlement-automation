package com.enernoc.bdap.model;

public class SettlementItemTimebound {
    public String settlement_item_id;
    public String start_dttm_utc;
    public String end_dttm_utc;
    public String interval_source;
    public Double nomination_value;
    public String nomination_uom;
    public Double payment_nomination_value;
    public String payment_nomination_uom;
    public Double payment_nomination_value_estimated;
    public String payment_nomination_uom_estimated;
    public String revenue_value;          // DECIMAL in db
    public String payment_value;          // DECIMAL in db
    public Double payment_penalty_input_value;
    public String payment_penalty_input_uom;
    public String payment_penalty_value;  // DECIMAL in db
    public String payment_penalty_notes;
    public String currency;

    // Returned by API, not in POST payload
    public String settlement_item_timebound_id;
    public String change_comments;        // used only in PUT/PATCH payload
    public Boolean deleted;
    public String last_updated_by;
    public String last_updated_dttm_utc;
    public String created_dttm_utc;
}
