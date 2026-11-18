package com.enernoc.bdap.model;

public class SettlementItemInterval {
    public String settlement_item_id;
    public String interval_dttm_utc;
    public String interval_source;
    public Boolean user_estimated;
    public Boolean vee_estimated;
    public Boolean utility_data;
    public Double metered_value;
    public String metered_uom;
    public Double baseline_value;
    public String baseline_uom;
    public Double nomination_value;
    public String nomination_uom;
    public Double payment_nomination_value;
    public String payment_nomination_uom;
    public String revenue_value;  // This is DECIMAL type in db
    public String payment_value; // This is DECIMAL type in db
    public Boolean relevant_indicator;
    public Boolean market_quality_good;
    public Double state_of_charge;
    public String change_comments;
    public String last_updated_by;
    public String last_updated_dttm_utc;
    public String created_dttm_utc;
    // ITAPPSIT-3327
    public String currency;
    public Double payment_penalty_input_value;
    public String payment_penalty_input_uom;
    public String payment_penalty_value; // This is DECIMAL type in db
    public String payment_penalty_notes;
    // ITAPPSIT-3328
    public Boolean deleted;
    // ITAPPSIT-3371
    public Double original_offer_kw;
    public Double cleared_offer_kw;
    // ITAPPSIT-3760: settlement api: add new db columns and new API fields for FCAS
    public Double realtime_availability_kw;
    public String revenue_value_estimated;  // This is DECIMAL type in db
    public String payment_value_estimated;  // This is DECIMAL type in db
    public Boolean is_armed;
    // ITAPPSIT-3859: override fields
    public Double realtime_availability_kw_override;
    public String payment_value_override;    // DECIMAL in db, keep as String like
}
