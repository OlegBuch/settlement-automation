package com.enernoc.bdap.model;

import java.util.ArrayList;

public class APIResponses {

    // Settlement API

    public record BasicResult(int code, String message, String details, String detail, Object data) {}

    public record GetSettlementsResult(int code, String message, String details, Settlement[] data) {}

    public record GetSettlementDetailsResult(int code, String message, String details, Settlement data) {}

    public record PostSettlementResult(int code, String message, String details, Settlement data) {}

    public record PutSettlementResult(int code, String message, String details, Settlement data) {}

    public record DeleteSettlementResult(int code, String message, String detail) {}

    public record GetSettlementItemResult(int code, String message, String details, SettlementItem data) {}

    public record GetSettlementItemsResult(int code, String message, String details, SettlementItem[] data) {}

    public record PostSettlementItemResult(int code, String message, String details, SettlementItem data) {}

    public record PutSettlementItemResult(int code, String message, String details, Object data) {}

    public record PatchResult(int code, String message, String detail) {}

    public record DeleteSettlementItemResult(int code, String message, String detail) {}

    public record PostSettlementItemIntervalsResult(int code, String message, String detail) {}

    public record PutPatchSettlementItemIntervalsResult(int code, String message, String detail) {}

    public record GetSettlementItemIntervalsResult(int code, String message, String details, ArrayList<SettlementItemInterval> data, ResponseMeta meta) {}

    public record GetSettlementItemIntervalSummaryResult(int code, String message, String details, SettlementItemIntervalSummary data) {}

    public record DeleteSettlementItemIntervalsResult(int code, String message, String detail) {}

    public record AuditLogResult(int code, String message, String details, AuditLogEntry[] data, ResponseMeta meta) {}

    public record GetReferenceDataResult(int code, String message, ReferenceData[] data, ResponseMeta meta) { }


    // Metadata API

    public record GetProductRulesResult(int code, String message, String details, ArrayList<ProductRules> data) {}

    public record GetProductRuleResult(int code, String message, String details, ProductRules data) {}

    public record PostRegistrationResult(int code, String message, String detail, Registration data) {}

    public record PutRegistrationResult(int code, String message, String details, Registration data) {}

    public record GetRegistrationHistoryResult(int code, String message, ArrayList<RegistrationHistory> data, ResponseMeta meta) {}

    public record GetRegistrationFieldHistoryResult(int code, String message, ArrayList<RegistrationFieldHistory> data, ResponseMeta meta) {}

    public record GetFinancialPointResult(int code, String message, String details, ArrayList<FinancialPoint> data) {}

    public record GetPipelineStateResult(int code, String message, String details, ArrayList<PipelineStateItem> data, ResponseMeta meta) {}

    public record PostPipelineStateResult(int code, String message, String detail, PipelineStateItem data) {}

    //Product Rule Parameters
    public record GetProductRuleParametersResult(int code, String message, java.util.List<ProductRuleParameters> data) {}

    public record PostProductRuleParameterResult(int code, String message, String detail, ProductRuleParameters data) {}

    public record PutProductRuleParameterResult(int code, String message, String details, ProductRuleParameters data) {}

    //Product Rule Fragments
    public record GetProductRuleFragmentsResult(int code, String message, java.util.List<ProductRuleFragments> data) {}

    public record PostProductRuleFragmentsResult(int code, String message, String detail, ProductRuleFragments data) {}

    public record PutProductRuleFragmentsResult(int code, String message, String details, ProductRuleFragments data) {}

    //Product Rules
    public record GetProductRule(int code, String message, java.util.List<ProductRules> data) {}

    public record PostProductRules(int code, String message, String detail, ProductRules data) {}

    public record PutProductRules(int code, String message, String details, ProductRules data) {}

    //Product Rule Details
    public record GetProductRuleDetail(int code, String message, java.util.List<ProductRuleDetails> data) {}

    public record PostProductRuleDetails(int code, String message, String detail, ProductRuleDetails data) {}

    public record PutProductRuleDetails(int code, String message, String details, ProductRuleDetails data) {}

    //Registration History Overrides
    public record PostRegistrationHistoryOverride(int code, String message, String detail, RegistrationHistoryOverrides data) {}

    public record PutRegistrationHistoryOverride(int code, String message, String details, RegistrationHistoryOverrides data) {}

    //Product Rule Groups
    public record GetProductRuleGroups(int code, String message, java.util.List<ProductRuleGroup> data) {}

    public record PostProductRuleGroups(int code, String message, String detail, ProductRuleGroup data) {}

    public record PutProductRuleGroups(int code, String message, String details, ProductRuleGroup data) {}

    //Eco Adhoc Financial Api
    public record GetAdhocFinancialApi(int code, String message, java.util.List<EcoAdhocFinancialLevel> data) {}

}
