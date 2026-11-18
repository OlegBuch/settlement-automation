package com.enernoc.bdap.model;

public class AuditLogEntry {

    public String settlement_id;
    public String settlement_item_id;
    public String interval_dttm_utc; // for intervals
    public String version; // for intervals
    public String audit_log_ts;
    public String change_comments;
    public String changed_field;
    public String changed_from;
    public String changed_to;
    public String last_updated_by;
    public String settlement_item_timebound_id;

    public AuditLogEntry withSettlementId(String id) {
        this.settlement_id = id;
        return this;
    }

    public AuditLogEntry withSettlementItemId(String id) {
        this.settlement_item_id = id;
        return this;
    }

    public AuditLogEntry withIntervalDttmUtc(String value) {
        this.interval_dttm_utc = value;
        return this;
    }

    public AuditLogEntry withAuditLogTs(String dttm) {
        this.audit_log_ts = dttm;
        return this;
    }

    public AuditLogEntry withChangeComments(String comments) {
        this.change_comments = comments;
        return this;
    }

    public AuditLogEntry withChangedField(String fieldName) {
        this.changed_field = fieldName;
        return this;
    }

    public AuditLogEntry withChangedFrom(String value) {
        this.changed_from = value;
        return this;
    }

    public AuditLogEntry withChangedTo(String value) {
        this.changed_to = value;
        return this;
    }

    public AuditLogEntry withSettlementItemTimeboundId(String id) {
        this.settlement_item_timebound_id = id;
        return this;
    }
}
