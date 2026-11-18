package com.enernoc.bdap.model;

import static com.enernoc.bdap.model.API.*;
import static com.enernoc.bdap.model.Endpoint.ResponseType.*;
import static com.enernoc.bdap.model.HttpOp.*;
import static com.enernoc.bdap.shared.Context.*;

/**
 * Defines the endpoints for various operations within the Settlement and Metadata APIs.
 * Each endpoint is associated with a specific API, HTTP operation, response type, and base URL.
 */
public enum Endpoint {

    // Settlement API
    GET_SETTLEMENT(SETTLEMENT_API, GET, MAP, settlementUrl),
    GET_SETTLEMENTS(SETTLEMENT_API, GET, LIST, getSettlementsUrl),
    GET_SETTLEMENT_DETAILS(SETTLEMENT_API, GET, MAP, getSettlementDetailsUrl),
    POST_SETTLEMENT(SETTLEMENT_API, POST, MAP, settlementUrl),
    PUT_SETTLEMENT(SETTLEMENT_API, PUT, MAP, settlementUrl),
    PATCH_SETTLEMENT(SETTLEMENT_API, PATCH, MAP, settlementUrl),
    DELETE_SETTLEMENT(SETTLEMENT_API, DELETE, STRING, settlementUrl),

    GET_SETTLEMENT_ITEM(SETTLEMENT_API, GET, MAP, settlementItemUrl),
    GET_SETTLEMENT_ITEMS(SETTLEMENT_API, GET, LIST, getSettlementItemsUrl),
    POST_SETTLEMENT_ITEM(SETTLEMENT_API, POST, MAP, settlementItemUrl),
    PUT_SETTLEMENT_ITEM(SETTLEMENT_API, PUT, MAP, settlementItemUrl),
    PATCH_SETTLEMENT_ITEM(SETTLEMENT_API, PATCH, STRING, settlementItemUrl),
    DELETE_SETTLEMENT_ITEM(SETTLEMENT_API, DELETE, STRING, settlementItemUrl),

    GET_SETTLEMENT_ITEM_INTERVALS(SETTLEMENT_API, GET, LIST, settlementItemIntervalsUrl),
    GET_SETTLEMENT_ITEM_INTERVAL_SUMMARY(SETTLEMENT_API, GET, MAP, getSettlementItemIntervalsSummaryUrl),
    POST_SETTLEMENT_ITEM_INTERVALS(SETTLEMENT_API, POST, STRING, settlementItemIntervalsUrl),
    PUT_SETTLEMENT_ITEM_INTERVALS(SETTLEMENT_API, PUT, STRING, settlementItemIntervalsUrl),
    PATCH_SETTLEMENT_ITEM_INTERVALS(SETTLEMENT_API, PATCH, STRING, settlementItemIntervalsUrl),
    DELETE_SETTLEMENT_ITEM_INTERVALS(SETTLEMENT_API, DELETE, STRING, settlementItemIntervalsUrl),

    GET_SETTLEMENT_AUDIT_LOG(SETTLEMENT_API, GET, LIST, settlementAuditLogUrl),
    GET_SETTLEMENT_ITEM_AUDIT_LOG(SETTLEMENT_API, GET, LIST, settlementItemAuditLogUrl),
    GET_SETTLEMENT_ITEM_INTERVALS_AUDIT_LOG(SETTLEMENT_API, GET, LIST, settlementItemIntervalsAuditLogUrl),

    // Metadata API
    GET_REGISTRATION(METADATA_API, GET, MAP, registrationUrl),
    POST_REGISTRATION(METADATA_API, POST, MAP, registrationUrl),
    PUT_REGISTRATION(METADATA_API, PUT, MAP, registrationUrl),
    DELETE_REGISTRATION(METADATA_API, DELETE, STRING, registrationUrl),

    GET_REGISTRATION_HISTORY(METADATA_API, GET, LIST, registrationHistoryUrl),
    GET_REGISTRATION_FIELD_HISTORY(METADATA_API, GET, LIST, registrationFieldHistoryUrl),

    GET_FINANCIAL_POINT_MAPPING(METADATA_API, GET, LIST, getFinancialPointMappingUrl),

    GET_PIPELINE_STATE(METADATA_API, GET, LIST, pipelineStateUrl),
    POST_PIPELINE_STATE(METADATA_API, POST, MAP, pipelineStateUrl),

    //Product rule parameters API
    GET_PRODUCT_RULE_PARAMETER(METADATA_API, GET, MAP, productRuleParametersUrl),
    GET_PRODUCT_RULE_PARAMETERS(METADATA_API, GET, LIST, productRuleParametersUrl),
    POST_PRODUCT_RULE_PARAMETERS(METADATA_API, POST,MAP, productRuleParametersUrl),
    PUT_PRODUCT_RULE_PARAMETERS(METADATA_API, PUT, MAP, productRuleParametersUrl),
    DELETE_PRODUCT_RULE_PARAMETER(METADATA_API, DELETE, STRING, productRuleParametersUrl),

    //Product rule fragments API
    GET_PRODUCT_RULE_FRAGMENT(METADATA_API, GET, MAP, productRuleFragmentsUrl),
    GET_PRODUCT_RULE_FRAGMENTS(METADATA_API, GET, LIST, productRuleFragmentsUrl),
    POST_PRODUCT_RULE_FRAGMENTS(METADATA_API, POST,MAP, productRuleFragmentsUrl),
    PUT_PRODUCT_RULE_FRAGMENTS(METADATA_API, PUT, MAP, productRuleFragmentsUrl),
    PUT_PRODUCT_RULE_FRAGMENT_PARAMETERS(METADATA_API, PUT, MAP, productRuleFragmentsUrl),
    DELETE_PRODUCT_RULE_FRAGMENT(METADATA_API, DELETE, STRING, productRuleFragmentsUrl),

    //Product rules API
    GET_PRODUCT_RULE(METADATA_API, GET, MAP, productRulesUrl),
    GET_PRODUCT_RULES(METADATA_API, GET, LIST, productRulesUrl),
    POST_PRODUCT_RULES(METADATA_API, POST,MAP, productRulesUrl),
    PUT_PRODUCT_RULES(METADATA_API, PUT, MAP, productRulesUrl),
    DELETE_PRODUCT_RULE(METADATA_API, DELETE, STRING, productRulesUrl),

    //Product rule details API
    GET_PRODUCT_RULE_DETAIL(METADATA_API, GET, MAP, productRuleDetailsUrl),
    GET_PRODUCT_RULE_DETAILS(METADATA_API, GET, LIST, productRuleDetailsUrl),
    POST_PRODUCT_RULE_DETAILS(METADATA_API, POST,MAP, productRuleDetailsUrl),
    PUT_PRODUCT_RULE_DETAILS(METADATA_API, PUT, MAP, productRuleDetailsUrl),
    DELETE_PRODUCT_RULE_DETAIL(METADATA_API, DELETE, STRING, productRuleDetailsUrl),

    //Registration history overrides API
    GET_REGISTRATION_HISTORY_OVERRIDE(METADATA_API, GET, MAP, registrationHistoryOverridesUrl),
    GET_REGISTRATION_HISTORY_OVERRIDES(METADATA_API, GET, LIST, registrationHistoryOverridesUrl),
    POST_REGISTRATION_HISTORY_OVERRIDES(METADATA_API, POST,MAP, registrationHistoryOverridesUrl),
    PUT_REGISTRATION_HISTORY_OVERRIDES(METADATA_API, PUT, MAP, registrationHistoryOverridesUrl),
    DELETE_REGISTRATION_HISTORY_OVERRIDE(METADATA_API, DELETE, STRING, registrationHistoryOverridesUrl),

    //SettlementCreator API
    GET_SETTLEMENT_CREATOR_PING(SETTLEMENT_CREATOR_API, GET, MAP, settlementCreatorPingUrl),
    POST_RUN_SETTLEMENT_PIPELINE(SETTLEMENT_CREATOR_API, POST, MAP, settlementCreatorRunPipeline),

    //Product rule groups API
    GET_PRODUCT_RULE_GROUP(METADATA_API, GET, MAP, productRuleGroupsUrl),
    GET_PRODUCT_RULE_GROUPS(METADATA_API, GET, LIST, productRuleGroupsUrl),
    POST_PRODUCT_RULE_GROUPS(METADATA_API, POST,MAP, productRuleGroupsUrl),
    PUT_PRODUCT_RULE_GROUPS(METADATA_API, PUT, MAP, productRuleGroupsUrl),
    DELETE_PRODUCT_RULE_GROUP(METADATA_API, DELETE, STRING, productRuleGroupsUrl),

    //Eco Financial Api
    GET_ADHOC_FINANCIAL_API_LEVELS(ECO_API, GET, LIST,  adHocFinancialLevels),

    //FinEngine Api
    GET_FIN_ENGINE_API_PING(FIN_ENGINE_API, GET, MAP, finEnginePingUrl),

    //Eco Financial Search Api
    POST_ADHOC_FINANCIAL_API_SEARCH(ECO_API, POST, LIST, adHocFinancialSearchUrl),

    // Eco Adhoc Financial Api
    POST_ADHOC_FINANCIAL(ECO_API, POST, MAP, adHocFinancialUrl),
    GET_ADHOC_FINANCIAL(ECO_API, GET, MAP, adHocFinancialUrl),
    PUT_ADHOC_FINANCIAL(ECO_API, PUT, MAP, adHocFinancialUrl),
    DELETE_ADHOC_FINANCIAL(ECO_API, DELETE, NONE, adHocFinancialUrl),

    // Settlement item timebound API
    GET_SETTLEMENT_ITEM_TIMEBOUND(SETTLEMENT_API, GET, MAP, settlementItemTimeboundUrl),
    GET_SETTLEMENT_ITEM_TIMEBOUNDS(SETTLEMENT_API, GET, LIST, settlementItemTimeboundUrl),
    POST_SETTLEMENT_ITEM_TIMEBOUND(SETTLEMENT_API, POST, LIST, settlementItemTimeboundUrl),
    PUT_SETTLEMENT_ITEM_TIMEBOUND(SETTLEMENT_API, PUT, STRING, settlementItemTimeboundUrl),
    PATCH_SETTLEMENT_ITEM_TIMEBOUND(SETTLEMENT_API, PATCH, STRING, settlementItemTimeboundUrl),
    DELETE_SETTLEMENT_ITEM_TIMEBOUND(SETTLEMENT_API, DELETE, STRING, settlementItemTimeboundUrl),
    GET_SETTLEMENT_ITEM_TIMEBOUND_AUDIT_LOG(SETTLEMENT_API, GET, LIST, settlementItemTimeboundAuditLogUrl);


    // Note: If your DELETE returns absolutely no body (204 No Content), you might need to use ResponseType.NONE if your enum supports it.
    public final API api;
    public final HttpOp verb;
    public final ResponseType responseType;
    public final String baseUrl;

    /**
     * Constructs an endpoint with specified details.
     *
     * @param api The API associated with the endpoint.
     * @param verb The HTTP operation (verb) for the endpoint.
     * @param type The expected response type of the endpoint.
     * @param baseUrl The base URL for the endpoint.
     */
    Endpoint(API api, HttpOp verb, ResponseType type, String baseUrl) {
        this.api = api;
        this.verb = verb;
        this.responseType = type;
        this.baseUrl = baseUrl;
    }

    /**
     * Enumerates the possible response types for an endpoint.
     */
    public enum ResponseType {
        MAP, LIST, STRING, NONE
    }
}
