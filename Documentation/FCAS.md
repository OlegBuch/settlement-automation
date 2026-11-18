# FCAS

Note: the phrase "as of today" used in this document refers to 25 November 2025, the date of the settlement automation knowledge-transfer session.

FCAS is an Australian fast-response frequency-control program managed by the Enel ANZ (Australia-New Zealand) Energy Markets team.
The program includes a number of products which correspond to different response speeds for both under-frequency and over-frequency system conditions.

## References
- General information about the [FCAS program](<CONFLUENCE_URL>/spaces/AUC/pages/717312691/FCAS+Operations+Guide)
- Nate's [Happy Path document](<CONFLUENCE_URL>/spaces/XP/pages/805514841/FCAS+Ancillary+Settlement+happy+path)
- Background info on [EPS armed status](<CONFLUENCE_URL>/spaces/XP/pages/844210121/FCAS+Armed+Status)

## Scenarios

Scenarios specific to FCAS are collected in the following feature-files:

- Pipeline/StmAndItemCreators/PortfolioLevelItemCreators.feature
- Pipeline/FCAS/FCAS_support.feature

In addition, various other files have been updated to include the new database table columns and API fields added for FCAS.

FCAS differs from AESO in that the payment calculations require aggregating registrations up to portfolios. For this reason, settlement creator creates settlements for
both registrations and portfolios. The portfolio settlement item intervals are the sum of the registration intervals.

FCAS requires quite a lot of data setup, so as of today most FCAS scenarios can only run in **preprd**.

### Atlas Program Hierarchy

In preprd, the ANZ Energy Markets team created a FCAS program hierarchy which is a subset of the expected prod hierarchy.
The program includes eight products based on different response times and actions, for example 'FCAS Raise 1 sec'.
The customer hierarchy consists of portfolios, registrations, and registration sets.
The top-level FCAS program node in preprd has the uuid 7b841207-22bd-46ae-853a-23c3e47f9148.

### Financial Points and Pricing Data

Our QAA created the FCAS financial points in preprd Atlas, using the feature-file **atlasSetup/Create_FCAS_FinancialHierarchy.feature** in the Xplatform automation.
This feature-file also contains a scenario to load pricing interval data.

All of the FCAS financial points have the same financial_point_type, **MARKET_PRICE**. Use this query to see the current financial points mappings in the settlement metadata:

    select * from settlement_metadata."financial_point_mapping" where financial_point_type = 'MARKET_PRICE';

As of today, there are still some open questions about how the financial information should be structured, so the current financial-point setup may be subject to change.

### Product Rules

Use this SQL query to see all of the FCAS products defined in the settlement metadata:

    select * from "settlement_metadata"."PRODUCT_RULE" where name LIKE 'FCAS%';

To see the full details for a specific rule, use this query with the appropriate product_id:

    select r.name as "Product", def.name as "Parameter", detail.value, detail.start_dttm_utc, detail.end_dttm_utc, * from settlement_metadata."PRODUCT_RULE_DETAIL" detail
    JOIN settlement_metadata."PR_PARAMETER_DEF" as def ON def.id = detail.pr_parameter_def_id
    JOIN "settlement_metadata"."PRODUCT_RULE" as r ON r.id = detail.product_rule_id
    where detail.product_rule_id = (select id from "settlement_metadata"."PRODUCT_RULE" where product_id = '1ef635c7-65b2-4945-bdcb-aa2606956cfd');

### Registrations

As of today, there is only one FCAS registration defined in the metadata:

    select * from settlement_metadata."REGISTRATION_HISTORY" where registration_id IN ('61eacbe0-d853-4fd1-a50c-e32375475a70');

### EPS Armed Status

For the FCAS program, we only receive revenue for registrations which are "armed" for at least part of the settlement period.
"Armed" means that the asset associated with the registration is available to participate in an FCAS event. Information on
the arming status of registrations in maintained in the event_node_workflow table in the EPS database (Event Performance Service).
The settlement interval creator queries the table to determine if and when the registrations in the settlement were armed.
However, the creator queries by the registration set, not by the registration itself. Because all the registrations under a registration set actually represent the
same physical device, EPS only maintains rows for one of the registrations and those rows apply to all registrations in the set.

EPS connection and authentication information is stored in the AWS secret **tf-stmcreate-{env}**. Here is a query to get the workflow rows for a registration set:

    select event_node_id, registration_id,workflow_status, event_node_start_time, event_node_end_time, curtail_complete, curtail_exception_resolved, cancelled, *
    from event_node_workflow where registration_set_id = '04693f3d-33c3-4156-b81b-0eefe4ce2ae7';

We have been granted access to create workflow rows in EPS. Here is an example curl. You can obtain the API key from Nate.

```
curl --location --request POST '<EPS_URL>/v1/event' \
--header 'accept: application/json' \
--header 'x-api-key: {api-key}' \
--header 'x-enelx-trace-id: 7dd3a99b-3175-4bbe-a080-c31131bfc1bf' \
--header 'Content-Type: application/json' \
--data-raw '{
"event_id": "<unique uuid>",
"event_type": "INTERNAL_TEST",
"product_id": "1ef635c7-65b2-4945-bdcb-aa2606956cfd",
"start_time": "2025-01-30T00:00:00.000Z",
"end_time": "2025-03-02T00:00:00.000Z",
"workflow_id": "351",
"event_nodes": [
{
"event_node_id": "<unique uuid>",
"registration_id": "61eacbe0-d853-4fd1-a50c-e32375475a70",
"registration_display_labels": {
"en_US": "FCAS Raise R5"
},
"registration_set_id": "04693f3d-33c3-4156-b81b-0eefe4ce2ae7",
"flexible_asset_id": "f334d38c-539a-4a14-877e-2c66e04ff8c5",
"expected_capacity": 1000,
"expected_capacity_uom": "kW",
"workflow_status": "READY",
"preauthorized": true,
"control_type": "MANUAL",
"control_timeout": 1,
"registration_type": "LOAD",
"confirmed": "2025-10-20T00:00:00.000Z"
}
]
}'
```
I believe that you should always create the workflow row with an initial status of READY. After you have created it, you can then update the row in the db as you need:

    update event_node_workflow set workflow_status = 'CURTAIL_COMPLETE' where event_node_id = 'befefb43-a747-48ef-b95f-c2ae988e44e3';
 
The automation support for EPS uses the class shared/EPSClient.java.

### MOM Data

As of today, FCAS settlements use MOM realtime-availability data, rather than cleared offers as is used for AESO.
However, we are still trying to get confirmation that this is the correct implementation.

The automation support for EPS uses the class shared/MomClient.java.
We only access MOM through the [MOM API](<INTERNAL_DOCS_URL>/stg/fdr_market_offer_management_mom). The API urls
are in configuration.json under the "mom" section. Note: the **/realtime-availability** endpoint used by FCAS is an undocumented feature.
We do not have access to create realtime-availability data in MOM.

See [ITAPPSIT-3763](<JIRA_URL>/browse/ITAPPSIT-3763) for a description of the current pipeline implementation and an example API query.

### ECO Results

The end result of a FCAS settlement pipeline run is the creation of REV/COGS pairs of payment row in the ECO database.
A pair of rows is created for each registration. No rows are created for portfolios.

EPS connection and authentication information is stored in the AWS secret **tf-stm-{env}-settlement-api**. Use the following query to retrieve the rows for a settlement:

    select * from transaction_source where settlement_item_id = '4c43bb4d-6924-4d5e-a58e-4a81e9cbf973'