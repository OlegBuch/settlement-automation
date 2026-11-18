package com.enernoc.bdap.model;

import static com.enernoc.bdap.model.Endpoint.*;

/**
 * Represents the type of entities involved in both the Settlement and Metadata APIs.
 * This enumeration defines the entity types and their associated CRUD (Create, Read, Update, Delete)
 * and PATCH operations through endpoints.
 */
public enum EntityType {
    // Settlement API
    /** Settlement entity with CRUD and PATCH endpoints. */
    SETTLEMENT(GET_SETTLEMENT, POST_SETTLEMENT, PUT_SETTLEMENT, PATCH_SETTLEMENT, DELETE_SETTLEMENT),
    /** Settlements entity with only a READ endpoint. */
    SETTLEMENTS(GET_SETTLEMENTS, null, null, null, null),
    /** Settlement Details entity with only a READ endpoint. */
    SETTLEMENT_DETAILS(GET_SETTLEMENT_DETAILS, null, null, null, null),
    /** Settlement Item entity with CRUD and PATCH endpoints. */
    SETTLEMENT_ITEM(GET_SETTLEMENT_ITEM, POST_SETTLEMENT_ITEM, PUT_SETTLEMENT_ITEM, PATCH_SETTLEMENT_ITEM, DELETE_SETTLEMENT_ITEM),
    /** Settlement Items entity with only a READ endpoint. */
    SETTLEMENT_ITEMS(GET_SETTLEMENT_ITEMS, null, null, null, null),
    /** Settlement Item Intervals entity with CRUD and PATCH endpoints. */
    SETTLEMENT_ITEM_INTERVALS(GET_SETTLEMENT_ITEM_INTERVALS, POST_SETTLEMENT_ITEM_INTERVALS, PUT_SETTLEMENT_ITEM_INTERVALS, PATCH_SETTLEMENT_ITEM_INTERVALS, DELETE_SETTLEMENT_ITEM_INTERVALS),
    /** Settlement Item Interval Summary entity with only a READ endpoint. */
    SETTLEMENT_ITEM_INTERVAL_SUMMARY(GET_SETTLEMENT_ITEM_INTERVAL_SUMMARY, null, null, null, null),

    // Metadata API
    /** Product Rule entity endpoints. */
    PRODUCT_RULE(GET_PRODUCT_RULE, POST_PRODUCT_RULES, PUT_PRODUCT_RULES, null, DELETE_PRODUCT_RULE),
    /** Product Rules entity with only a READ endpoint. */
    PRODUCT_RULES(GET_PRODUCT_RULES, null, null, null, null),
    /** Registration entity with CRUD operations, excluding PATCH. */
    REGISTRATION(GET_REGISTRATION, POST_REGISTRATION, PUT_REGISTRATION, null, DELETE_REGISTRATION),
    /** Registration history with only a READ endpoint. */
    REGISTRATION_HISTORY(GET_REGISTRATION_HISTORY, null, null, null, null),
    /** Registration field history with only a READ endpoint. */
    REGISTRATION_FIELD_HISTORY(GET_REGISTRATION_FIELD_HISTORY, null, null, null, null),
    /** Financial point entity with only a READ endpoint. */
    FINANCIAL_POINT(GET_FINANCIAL_POINT_MAPPING, null, null, null, null),
    /** Pipeline state entity with READ and CREATE endpoints. */
    PIPELINE_STATE(GET_PIPELINE_STATE, POST_PIPELINE_STATE, null, null, null),

    //Product rule parameters API
    PRODUCT_RULE_PARAMETERS(GET_PRODUCT_RULE_PARAMETERS, null, null, null, null),
    PRODUCT_RULE_PARAMETER(GET_PRODUCT_RULE_PARAMETER, POST_PRODUCT_RULE_PARAMETERS, PUT_PRODUCT_RULE_PARAMETERS, null, DELETE_PRODUCT_RULE_PARAMETER),

    //Product rule fragments API
    PRODUCT_RULE_FRAGMENTS(GET_PRODUCT_RULE_FRAGMENTS, null, null, null, null),
    PRODUCT_RULE_FRAGMENT(GET_PRODUCT_RULE_FRAGMENT, POST_PRODUCT_RULE_FRAGMENTS, PUT_PRODUCT_RULE_FRAGMENTS, null, DELETE_PRODUCT_RULE_FRAGMENT),
    PRODUCT_RULE_FRAGMENT_PARAMETERS(null, null, PUT_PRODUCT_RULE_FRAGMENT_PARAMETERS, null, null),

    //Product rule details API
    PRODUCT_RULE_DETAILS(GET_PRODUCT_RULE_DETAILS, null, null, null, null),
    PRODUCT_RULE_DETAIL(GET_PRODUCT_RULE_DETAIL, POST_PRODUCT_RULE_DETAILS, PUT_PRODUCT_RULE_DETAILS, null, DELETE_PRODUCT_RULE_DETAIL),

    //Registration history overrides API
    REGISTRATION_HISTORY_OVERRIDES(GET_REGISTRATION_HISTORY_OVERRIDES, null, null, null, null),
    REGISTRATION_HISTORY_OVERRIDE(GET_REGISTRATION_HISTORY_OVERRIDE, POST_REGISTRATION_HISTORY_OVERRIDES, PUT_REGISTRATION_HISTORY_OVERRIDES, null, DELETE_REGISTRATION_HISTORY_OVERRIDE),

    //Product rule groups API
    PRODUCT_RULE_GROUPS(GET_PRODUCT_RULE_GROUPS, null, null, null, null),
    PRODUCT_RULE_GROUP(GET_PRODUCT_RULE_GROUP, POST_PRODUCT_RULE_GROUPS, PUT_PRODUCT_RULE_GROUPS, null, DELETE_PRODUCT_RULE_GROUP),

    //Eco AdHoc Fin Level API
    ECO_ADHOC_FINANCIAL_LEVELS_API(GET_ADHOC_FINANCIAL_API_LEVELS, null, null, null, null),

    //Fin Engine API
    FIN_ENGINE_PING(GET_FIN_ENGINE_API_PING, null, null, null, null),

    //Settlement item timebound API
    SETTLEMENT_ITEM_TIMEBOUND(
            GET_SETTLEMENT_ITEM_TIMEBOUND,
            POST_SETTLEMENT_ITEM_TIMEBOUND,
            PUT_SETTLEMENT_ITEM_TIMEBOUND,
            PATCH_SETTLEMENT_ITEM_TIMEBOUND,
            DELETE_SETTLEMENT_ITEM_TIMEBOUND
            ),
    SETTLEMENT_ITEM_TIMEBOUNDS(GET_SETTLEMENT_ITEM_TIMEBOUNDS, null, null, null, null);

    /**
     * Retrieves an EntityType based on its name, in a case-insensitive manner.
     *
     * @param typeName The name of the EntityType to retrieve.
     * @return The corresponding EntityType.
     */
    public static EntityType get(String typeName) {
        return EntityType.valueOf(typeName.toUpperCase());
    }

    /**
    * Fields representing the endpoints for each CRUD operation plus PATCH.
    */
    public final Endpoint get, post, put, patch, delete;

    /**
     * Constructs an EntityType with specified endpoints for CRUD and PATCH operations.
     *
     * @param get The endpoint for the READ operation.
     * @param post The endpoint for the CREATE operation.
     * @param put The endpoint for the UPDATE operation.
     * @param patch The endpoint for the PATCH operation.
     * @param delete The endpoint for the DELETE operation.
     */
    EntityType(Endpoint get, Endpoint post, Endpoint put, Endpoint patch, Endpoint delete) {
        this.get = get;
        this.post = post;
        this.put = put;
        this.patch = patch;
        this.delete = delete;
    }
}