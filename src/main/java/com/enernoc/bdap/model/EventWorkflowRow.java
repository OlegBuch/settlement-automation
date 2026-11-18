package com.enernoc.bdap.model;

import com.enernoc.bdap.shared.Utility;
import org.slf4j.Logger;

import java.time.ZonedDateTime;

public class EventWorkflowRow {

    public String event_node_id;
    public String product_id;
    public String registration_id;
    public String registration_set_id;
    public String workflow_status;
    public ZonedDateTime event_node_start_time;
    public ZonedDateTime event_node_end_time;
    public ZonedDateTime curtail_complete;
    public ZonedDateTime curtail_exception_resolved;
    public ZonedDateTime cancelled;

    public void log (Logger LOG) {
        LOG.info("  event_node_start_time: {}, event_node_end_time: {}, workflow_status: {}, curtail_complete: {}, curtail_exception_resolved: {}, cancelled: {}, event_node_id: {}, product_id: {}, registration_id: {}, registration_set_id: {}",
                Utility.normalizeZonedDateTime(this.event_node_start_time), Utility.normalizeZonedDateTime(this.event_node_end_time), this.workflow_status,
                Utility.normalizeZonedDateTime(this.curtail_complete), Utility.normalizeZonedDateTime(this.curtail_exception_resolved),
                Utility.normalizeZonedDateTime(this.cancelled), this.event_node_id, this.product_id, this.registration_id, this.registration_set_id);
    }

}
