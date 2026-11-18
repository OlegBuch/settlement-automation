package com.enernoc.bdap.model;

import java.time.ZoneId;
import java.util.ArrayList;

public class SettlementCreatorSpec {

    public static class CreationScheduleEntry {
        public String creationPeriod;
        public Boolean recalcOnly;
        public ArrayList<String> dates;
        public Boolean estimated;
    }

    public String productName;
    public String productRuleId;
    public String requestedType;
    public String asofDate;
    public String scheduledSettlementCreationPeriod;
    public ArrayList<CreationScheduleEntry> scheduledSettlementCreationScheduleJson;
    public String scheduledSettlementCreationType;
    public ZoneId scheduledSettlementCreationTimezone;
    public String currency;
    public int intervalLengthMinutes;
    public String kwSourceSystem;
    public String pipelineSequence;
    public boolean createPortfolioItems;

}
