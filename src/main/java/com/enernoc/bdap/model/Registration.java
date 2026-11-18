package com.enernoc.bdap.model;

import java.util.List;
import java.util.TreeSet;

public class Registration {
    public String registration_id;
    public String status;
    public String product_id;
    public String flexible_asset_id;
    public String service_delivery_point_id;
    public String org_id;
    public String site_id;
    public String ecrm_account_id;
    public String ecrm_site_id;
    public String ecrm_opportunity_id;
    public boolean deleted;
    public boolean needs_manual_fix;
    public String last_updated_dttm_utc;
    public String last_updated_by;
    public String portfolio_id;
    public String registration_set_id;

    public static TreeSet<String> fieldsTrackedInHistory = new TreeSet<>(List.of("status", "product_id", "flexible_asset_id", "service_delivery_point_id", "org_id", "site_id", "ecrm_account_id",
            "ecrm_site_id", "ecrm_opportunity_id", "deleted", "needs_manual_fix", "portfolio_id", "registration_set_id"));
}
