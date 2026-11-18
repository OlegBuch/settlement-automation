package com.enernoc.bdap.model;

import com.enernoc.bdap.shared.Utility;

import java.time.ZonedDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

public class Settlement {

    public Boolean create_portfolio_items;

    public String settlement_id;
    public String settlement_type;
    public String settlement_subtype;
    public String start_dttm_utc;
    public String end_dttm_utc;
    public String event_id;
    public String description;
    public String settlement_status;
    public String business_process_status;
    public String source_system_type;
    public String product_id;
    public String processing_status;
    public Boolean deleted;
    public String last_updated_by;
    public String last_updated_dttm_utc;
    public String inputs_available_until_dttm_utc;
    public String change_comments;
    public ArrayList<SettlementItem> settlement_items;

    public static class ScheduledSettlement extends Settlement {
        public SettlementCreatorSpec scspec;
        public ScheduledSettlement(ProductRules rule, SettlementCreatorSpec scspec, ZonedDateTime endLocal) {
            this.scspec = scspec;
            this.deleted = false;
            this.product_id = rule.product_id;
            this.settlement_type = scspec.scheduledSettlementCreationType;
            this.settlement_subtype = "none";
            this.source_system_type = "CLASSIC_DR";
            this.description = "scheduled settlement";
            this.settlement_status = "PRELIMINARY";
            this.business_process_status = "NOT_STARTED";
            { // set settlement start and end dates
                this.end_dttm_utc = Utility.normalizeZonedDateTime(endLocal);
                this.start_dttm_utc = Utility.normalizeZonedDateTime(endLocal.minusMonths(1));
            }
            // Populate createPortfolioItems from the ProductRules details
            this.create_portfolio_items = false; // Default to false
            try {
                boolean found = false;
                for (var group : rule.getGroups()) {
                    if (group.getFragments() == null) continue;
                    for (var fragment : group.getFragments()) {
                        Map<String, List<ProductRuleFragments.Detail>> details =
                                fragment.getDetailsForDateRange(
                                        ZonedDateTime.parse(this.start_dttm_utc),
                                        ZonedDateTime.parse(this.end_dttm_utc));

                        List<ProductRuleFragments.Detail> portfolioItemsRule =
                                details.get("CREATE_PORTFOLIO_ITEMS");
                    if (portfolioItemsRule != null && !portfolioItemsRule.isEmpty()) {
                        String value = portfolioItemsRule.get(0).value;
                        this.create_portfolio_items = Boolean.parseBoolean(value);
                            found = true;
                            break;
                }
            }
                    if (found) break;
        }
            } catch (Exception e) {
                // If anything goes wrong (e.g., no fragments, parsing error), default remains false.
                System.err.println("Could not determine CREATE_PORTFOLIO_ITEMS rule: " + e.getMessage());
                this.create_portfolio_items = false;
            }
        }

        public Settlement convertToSimple() {
            var s = new Settlement();
            s.settlement_id = this.settlement_id;
            s.settlement_type = this.settlement_type;
            s.settlement_subtype = this.settlement_subtype;
            s.start_dttm_utc = this.start_dttm_utc;
            s.end_dttm_utc = this.end_dttm_utc;
            s.event_id = this.event_id;
            s.description = this.description;
            s.settlement_status = this.settlement_status;
            s.business_process_status = this.business_process_status;
            s.source_system_type = this.source_system_type;
            s.product_id = this.product_id;
            s.processing_status = this.processing_status;
            s.deleted = this.deleted;
            s.last_updated_by = this.last_updated_by;
            s.last_updated_dttm_utc = this.last_updated_dttm_utc;
            s.change_comments = this.change_comments;
            s.settlement_items = this.settlement_items;
            s.create_portfolio_items = this.create_portfolio_items;
            s.inputs_available_until_dttm_utc = this.inputs_available_until_dttm_utc;
            return s;
        }
    }

}

