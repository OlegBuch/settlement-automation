package com.enernoc.bdap.model;

import java.util.ArrayList;
import java.util.TreeSet;

public class SettlementItem implements Comparable<SettlementItem> {

    public String settlement_item_id;
    public String settlement_id;
    public String settlement_level;
    public String settlement_level_id;
    public boolean submitted_indicator;
    public Boolean deleted;
    public String settlement_item_status;
    public String asset_type;
    public String master_settlement_item_id;
    public String registration_set_id;
    public String portfolio_id;
    public String last_updated_by;
    public String last_updated_dttm_utc;
    public String atlas_settlement_level_id;
    public String ecrm_opportunity_id;
    public String ecrm_account_id;
    public String ecrm_site_id;
    public String processing_status;
    public String start_dttm_utc;
    public String end_dttm_utc;
    public String change_comments;
    public Boolean is_inactive;
    public TreeSet<SettlementItem> sub_settlement_items;
    public ArrayList<SettlementItemInterval> intervals;

    @Override
    public int compareTo(SettlementItem other) {
        return this.settlement_item_id.compareTo(other.settlement_item_id);
    }

    public String nonNullsToString() {
        String s = "";
        if (settlement_item_id != null) {
            s += String.format("settlement_item_id: '%s'  ", settlement_item_id);
        }
        if (settlement_id != null) {
            s += String.format("settlement_id: '%s'  ", settlement_id);
        }
        if (settlement_level != null) {
            s += String.format("settlement_level: '%s'  ", settlement_level);
        }
        if (settlement_level_id != null) {
            s += String.format("settlement_level_id: '%s'  ", settlement_level_id);
        }
        if (start_dttm_utc != null) {
            s += String.format("start_dttm_utc: '%s'  ", start_dttm_utc);
        }
        if (end_dttm_utc != null) {
            s += String.format("end_dttm_utc: '%s'  ", end_dttm_utc);
        }
        s += String.format("submitted_indicator: '%b'  ", submitted_indicator);
        if (deleted != null) {
            s += String.format("deleted: '%b'  ", deleted);
        }
        if (settlement_item_status != null) {
            s += String.format("settlement_item_status: '%s'  ", settlement_item_status);
        }
        if (asset_type != null) {
            s += String.format("asset_type: '%s'  ", asset_type);
        }
        if (master_settlement_item_id != null) {
            s += String.format("master_settlement_item_id: '%s'  ", master_settlement_item_id);
        }
        if (atlas_settlement_level_id != null) {
            s += String.format("atlas_settlement_level_id: '%s'  ", atlas_settlement_level_id);
        }
        if (ecrm_opportunity_id != null) {
            s += String.format("ecrm_opportunity_id: '%s'  ", ecrm_opportunity_id);
        }
        if (ecrm_account_id != null) {
            s += String.format("ecrm_account_id: '%s'  ", ecrm_account_id);
        }
        if (ecrm_site_id != null) {
            s += String.format("ecrm_site_id: '%s'  ", ecrm_site_id);
        }
        if (processing_status != null) {
            s += String.format("processing_status: '%s'  ", processing_status);
        }
        if (change_comments != null) {
            s += String.format("change_comments: '%s'  ", change_comments);
        }
        if (last_updated_by != null) {
            s += String.format("last_updated_by: '%s'  ", last_updated_by);
        }
        if (last_updated_dttm_utc != null) {
            s += String.format("last_updated_dttm_utc: '%s'  ", last_updated_dttm_utc);
        }

        return s;
    }
}
