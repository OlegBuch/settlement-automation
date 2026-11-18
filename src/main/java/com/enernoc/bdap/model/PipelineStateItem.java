package com.enernoc.bdap.model;

public class PipelineStateItem {
    public String id;
    public String settlement_id;
    public String settlement_item_id;
    public String pipeline_step;
    public String status;
    public String detail;
    public String created_dttm_utc;
    public String pipeline_run_id;
    public String mode;

    public String toFormattedString() {
        return String.format("id: %s  settlement_id: '%s'  settlement_item_id: '%s'  pipeline_step: '%s'  status: '%s'  detail: '%s'  created_dttm_utc: '%s'  pipeline_run_id: '%s' mode: '%s'",
                this.id, this.settlement_id, this.settlement_item_id, this.pipeline_step, this.status, this. detail, this.created_dttm_utc, this.pipeline_run_id, this.mode);
    }

    public String toLogString() {
        return String.format("pipeline_step: '%s'  status: '%s'  detail: '%s'  pipeline_run_id: '%s' mode: '%s'",
                this.pipeline_step, this.status, this. detail, this.pipeline_run_id, this.mode);
    }

}
