package com.enernoc.bdap.stepdefs;

import com.enernoc.bdap.model.*;
import com.enernoc.bdap.model.APIResponses.*;
import com.enernoc.bdap.shared.Context;
import com.enernoc.bdap.shared.PostgresClient;
import com.enernoc.bdap.shared.Utility;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.cucumber.datatable.DataTable;
import io.cucumber.java.en.*;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.time.ZonedDateTime;
import java.util.*;

import static com.enernoc.bdap.model.EntityType.*;
import static com.enernoc.bdap.shared.Context.metadataSecretValues;
import static org.junit.jupiter.api.Assertions.*;


public class GetEntities {

    private static final Logger LOG = LoggerFactory.getLogger("GetEntities");
    private final Context context = Context.getContext();
    private final Utility utility = new Utility();
    private static final ObjectMapper JSON = new ObjectMapper();

    private final PostgresClient client = new PostgresClient(metadataSecretValues);
    Optional<ProductRules> ruleWithDetailsOpt = Optional.empty();


// -------- QUERY STEPDEFS

    private RequestContainer request;


    @Given("I call GET {entityType} with {word} {string}")
    public void iCallGetEntitiesWithOneParam(EntityType entityType, String name, String value) {

        var parms = new HashMap<String, Object>() {{
            this.put(name, value);
        }};
        utility.replaceParmValues(parms);
        var expectedStatus = context.popExpectedStatus(200);
        request = RequestContainer.build().getEntities(entityType).addQueryParm(name, parms.get(name).toString());
        context.includeDeletedOpt.ifPresent(flag -> request.addQueryParm("include_deleted", flag));
        switch (entityType) {
            case SETTLEMENTS -> request.call(expectedStatus).getResponseEntity(GetSettlementsResult.class);
            case SETTLEMENT_ITEMS -> request.call(expectedStatus).getResponseEntity(GetSettlementItemsResult.class);
            default -> fail("Unsupported entity type!");
        }
        if (expectedStatus.getCode() == 200) {
            LOG.info("{} {} returned", request.getDataAsList().size(), entityType.name());
        }
    }


    @Given("I call GET {entityType} with the following parameters:")
    public void iCallGetEntitiesWithMultipleParams(EntityType entityType, DataTable paramTable) {

        var parms = new HashMap<String, Object>(paramTable.asMap());
        utility.replaceParmValues(parms);
        var parmStrings = new HashMap<String, Object>() {{
            parms.forEach((k, v) -> this.put(k, v.toString()));
        }};
        var expectedStatus = context.popExpectedStatus(200);
        request = RequestContainer.build().getEntities(entityType).addQueryParms(parmStrings);
        switch (entityType) {
            case SETTLEMENTS -> {
                context.includeDeletedOpt.ifPresent(flag -> request.addQueryParm("include_deleted",  flag));
                request.call(expectedStatus).getResponseEntity(GetSettlementsResult.class);
            }
            case SETTLEMENT_ITEMS -> request.call(expectedStatus).getResponseEntity(GetSettlementItemsResult.class);
            case FINANCIAL_POINT -> request.call(expectedStatus).getResponseEntity(GetFinancialPointResult.class);
            default -> fail("Unsupported entity type!");
        }
        if (expectedStatus.getCode() == 200) {
            LOG.info("{} {} returned", request.getDataAsList().size(), entityType.name());
        }
    }


    @Given("I call GET productrules$")
    public void iCallGetProductRules() {

        var expectedStatus = context.popExpectedStatus(200);
        request = RequestContainer.build().getEntities(PRODUCT_RULES);
        context.includeDetailsOpt.ifPresent(flag -> request.addQueryParm("include_details",  flag));
        request.call(expectedStatus).getResponseEntity(GetProductRulesResult.class);
        if (expectedStatus.getCode() == 200) {
            LOG.info("{} product rules returned", request.getDataAsList().size());
        }
    }


    @Given("I call GET productrules for the product {string}")
    public void iCallGetProductRulesForProduct(String product) {

        var expectedStatus = context.popExpectedStatus(200);
        request = RequestContainer.build().getEntity(PRODUCT_RULE, product);
        context.includeDetailsOpt.ifPresent(flag -> request.addQueryParm("include_details",  flag));
        request.call(expectedStatus).getResponseEntity(GetProductRuleResult.class);
        if (expectedStatus.getCode() == 200) {
            LOG.info("Product rule returned");
        }
    }


    @Given("I call GET {entityType} with no query parameters")
    public void iCallGetEntitiesWithNoQueryParms(EntityType entityType) {
        RequestContainer.build().getEntities(entityType).call(context.popExpectedStatus());
    }


    @Given("I call GET {entityType} with an invalid query parameter {word} = {word}")
    public void iCallGetSettlementsWithInvalidQueryParm(EntityType entityType, String param, String value) {
        RequestContainer.build().getEntities(entityType).addQueryParm(param, value).call(context.popExpectedStatus());
    }

    @Given("I call POST {entityType} with an invalid query parameter {word} = {word}")
    public void iCallPostEntitiesWithInvalidQueryParm(EntityType entityType, String param, String value) {
        RequestContainer.build().getEntities(entityType).addQueryParm(param, value).call(context.popExpectedStatus());
    }


    @Given("I save the returned settlement items")
    public void iSaveReturnedSettlementItems() {
        var itemList =  request.getDataAsList();
        if (itemList.isEmpty()) {
            fail("No settlement items returned!");
        }
        itemList.forEach(map -> context.savedSettlementItems.put(map.get("settlement_item_id").toString(), map));
        LOG.info(String.format("%d settlement items saved", itemList.size()));
    }



// -------- VALIDATION STEPDEFS

    @Then("I verify that no settlement exists with the event {string}")
    public void iVerifyNoSettlementWithEvent(String eventId) {

        var parmStrings = new HashMap<String, Object>() {{
            this.put("event_id", eventId);
        }};
        request = RequestContainer.build().getEntities(SETTLEMENTS).addQueryParms(parmStrings).call(200);
        if (!request.getDataAsList().isEmpty()) {
            fail(String.format("A settlement with that event id exists with statement_id '%s'", request.getDataAsList().get(0).get("settlement_id")));
        }
        LOG.info("Verified that no settlement with the event_id exists");
    }


    @Then("a settlement exists for the event {string}")
    public void settlementExistsForEvent(String eventId) {

        var parmStrings = new HashMap<String, Object>() {{
            this.put("event_id", eventId);
        }};
        request = RequestContainer.build().getEntities(SETTLEMENTS).addQueryParms(parmStrings).call(200);
        if (request.getDataAsList().isEmpty()) {
            fail("No settlement with that event id exists!");
        }
        context.lastSettlementId = request.getDataAsList().get(0).get("settlement_id").toString();
        LOG.info(String.format("Found settlement: %s", context.lastSettlementId));
    }


    @Then("only non-deleted {word} should be returned")
    public void onlyNonDeletedEntitiesReturned(String noun) {
        var settlements = (List<HashMap<String, Object>>) request.getDataAsList();
        assertFalse(settlements.isEmpty(), "No entities returned!!");
        var nonDeletedCount = settlements.stream().filter(s -> !((boolean) s.getOrDefault("deleted", false))).count();
        var deletedCount = settlements.stream().filter(s -> (boolean) s.getOrDefault("deleted", false)).count();
        LOG.info(String.format("Non-deleted %s: %d  Deleted %s: %d", noun, nonDeletedCount, noun, deletedCount));
        assertEquals(0, deletedCount, String.format("%d deleted entities returned!!", deletedCount));
    }


    @Then("both deleted and non-deleted {word} should be returned")
    public void bothDeletedNonDeletedEntitiessReturned(String noun) {
        var settlements = (List<HashMap<String, Object>>) request.getDataAsList();
        assertFalse(settlements.isEmpty(), "No settlements returned!!");
        var nonDeletedCount = settlements.stream().filter(s -> !((boolean) s.getOrDefault("deleted", false))).count();
        var deletedCount = settlements.stream().filter(s -> (boolean) s.getOrDefault("deleted", false)).count();
        LOG.info(String.format("Non-deleted %s: %d  Deleted %s: %d", noun, nonDeletedCount, noun, deletedCount));
        assertTrue(deletedCount > 0, "No deleted entities returned!!");
        assertTrue(nonDeletedCount > 0, "No non-deleted entities returned!!");
    }


    @And("at least one item should have a non-null {word}")
    public void GetItemsReturnsNonNullProp(String property) {
        // Find the first settlement item in the request response whose specified property is not null
        var items = request.getDataAsList();
        var itemOpt = items.stream().filter(i -> i.get(property) != null).findFirst();
        assertTrue(itemOpt.isPresent(), String.format("No items with non-null %s returned!!", property));
        LOG.info(String.format("Verified: at least one item with non-null '%s'", property));
    }


    @Then("all settlement(s)/item(s) returned should match the query")
    public void GetEntitiesVerifyAllEntitiesMatchQuery() {

        var data = (List<HashMap<String, Object>>) request.getDataAsList();
        assertFalse(data.isEmpty(), "No entities found!!");
        var queryParms = request.getQueryParms();
        assertFalse(queryParms.isEmpty(), "No query params specified!");
        if (!queryParms.containsKey("include_deleted")) {
            queryParms.put("include_deleted", false);  // false is the default value
        }
        List<String> parmsVerified = new ArrayList<>();
        queryParms.forEach((name, value) ->{
            var mismatches = switch (name) {
                case "start_dttm_utc_from" -> { // start_dttm_utc_from: Datetime chronologically before or equal to Settlement Start Time (inclusive)
                    ZonedDateTime start = ZonedDateTime.parse(value.toString());
                    yield data.stream().filter(s -> { // start_dttm_utc_to: Datetime chronologically equal to or after Settlement Start Time (inclusive)
                        ZonedDateTime dttm = ZonedDateTime.parse(s.get("start_dttm_utc").toString());
                        return start.isAfter(dttm);
                    }).toList();
                }
                case "start_dttm_utc_to" -> {
                    ZonedDateTime end = ZonedDateTime.parse(value.toString());
                    yield data.stream().filter(s -> {
                        ZonedDateTime dttm = ZonedDateTime.parse(s.get("start_dttm_utc").toString());
                        return end.isBefore(dttm);
                    }).toList();
                }
                case "submitted_indicator" -> data.stream().filter(s -> !s.get(name).equals(Boolean.parseBoolean(value.toString()))).toList();
                case "include_deleted" -> {
                    if ((value instanceof Boolean && (boolean) value) || (value instanceof String && Boolean.parseBoolean(value.toString()))) {
                        // If include_deleted = true, both deleted and non-deleted settlements can be returned, so no point checking the deleted property
                        yield Collections.EMPTY_LIST;
                    } else {
                        // If include_deleted = false, verify that deleted = false on all returned properties
                        yield data.stream().filter(s -> s.get("deleted").equals(true)).toList();
                    }
                }
                default -> data.stream().filter(s -> !s.get(name).equals(value)).toList();
            };
            assertTrue(mismatches.isEmpty(), String.format("%d mismatched entities returned!!", mismatches.size()));
            parmsVerified.add(name);
        });
        LOG.info(String.format("GET verified for query parms %s", String.join(",", parmsVerified)));
    }


    @Then("the response should contain more than {int} settlement(s)/item(s)/rule(s)")
    public void GetSettlementsNumEntitiesReturnedMoreThan(int numExpected) {
        assertTrue(request.getDataAsList().size() > numExpected, "Not enough entities were returned!!");
        LOG.info("Response verified");
    }


    @Then("the response should contain {int} settlement(s)/item(s)")
    public void GetSettlementsNumEntitiesReturned(int numExpected) {
        assertEquals(numExpected, request.getDataAsList().size(), "Unexpected number of entities were returned!!");
        LOG.info("Response verified");
    }


    @Then("the response should not contain any settlements/items")
    public void GetSettlementsNoEntitiesReturned() {
        assertEquals(0, request.getDataAsList().size(), "Entities were returned!!");
        LOG.info("Response verified");
    }


    @Then("every item in the response should have the property {word} set to {string}")
    public void everyItemHasProperty(String prop, String value) {
        var items = request.getDataAsList();
        assertFalse(items.isEmpty(), "No items returned!!");
        long numMatches = items.stream().filter(item -> value.equals(item.getOrDefault(prop, "missing"))).count();
        assertEquals(items.size(), numMatches, "Not every item has the expected value!!");
        LOG.info(String.format("All %d items match", items.size()));
    }


    @Then("I save the atlas_settlement_level_id from the last item in the GET response")
    public void iSaveAtlasSettlementLevelIds() {
        var idOpt = request.getDataAsList().stream()
                .map(item -> item.getOrDefault("atlas_settlement_level_id", "").toString())
                .filter(id -> !id.isBlank())
                .findFirst();
        assertFalse(idOpt.isEmpty(), "No atlas_settlement_level_id found!!");
        context.lastAtlasSettlementLevelId = idOpt.get();
        LOG.info("Response verified");
    }


    @And("at least one rule should actually have details")
    public void AtLeastOneRuleShouldHaveDetails() {
        GetProductRulesVerifyIncludeDetailsAtLeastOne();
    }


    @And("if include_details=true at least one rule should actually have details")
    public void GetProductRulesVerifyIncludeDetailsAtLeastOne() {
        if (context.includeDetailsOpt.orElse(true)) {
            var rules = request.getResponseEntity(GetProductRulesResult.class).data();

            ruleWithDetailsOpt = rules.stream()
                    .filter(r -> r.getGroups() != null && r.getGroups().stream()
                            .anyMatch(g -> g.getFragments() != null && g.getFragments().stream()
                                    .anyMatch(f -> f.parameters != null && !f.parameters.isEmpty() &&
                                            f.parameters.stream().anyMatch(p -> p.details != null && !p.details.isEmpty()))))
                    .findFirst();

            assertTrue(ruleWithDetailsOpt.isPresent(), "No rules with details returned!!");
            LOG.info("Verified: at least one rule was returned with details");
        } else {
            LOG.info("include_details=false; skipping");
        }
    }

    @When("I call GET productrules for the rule that has details")
    public void GetProductRulesForRuleWithDetails() {
        assertTrue(ruleWithDetailsOpt.isPresent(), "No rules with details returned!!");
        var rule = ruleWithDetailsOpt.get();
        request = RequestContainer.build().getEntity(PRODUCT_RULE, rule.product_id);
        request.addQueryParm("include_details", context.includeDetailsOpt.orElse(true));
        request.call(200).getResponseEntity(GetProductRuleResult.class);
        // update the ruleWithDetailsOpt to the actual rule returned
        ruleWithDetailsOpt = Optional.of(request.getResponseEntity(GetProductRuleResult.class).data());
        Optional<ProductRules> ruleWithDetailsOpt =
                Optional.of(request.getResponseEntity(GetProductRuleResult.class).data());
        LOG.info("Verified: rule with details returned");
    }


     // -------- Financial point mappings stepdefs


    @Then("all financlal point mappings returned should match the query")
    public void GetEntitiesVerifyAllFinancialPointsRowsMatchQueryV2() throws Throwable {

        var data = (List<HashMap<String, Object>>) request.getDataAsList();
        assertFalse(data.isEmpty(), "No points found!!");
        var queryParms = request.getQueryParms();
        assertFalse(queryParms.isEmpty(), "No query params specified!");

        var startDttm = ZonedDateTime.parse(queryParms.getOrDefault("start_dttm_utc", "1970-01-01T00:00:00Z").toString());
        var endDttm = ZonedDateTime.parse(queryParms.getOrDefault("end_dttm_utc", "9000-01-01T00:00:00Z").toString());
        String levelId = queryParms.getOrDefault("level_id", "missing").toString();
        String levelType = queryParms.getOrDefault("level_type", "missing").toString();

        // Get all the financial points and then eliminate all non-matching points
        var expectedRows = client.getAllFinancialPointRows("select * from settlement_metadata.\"financial_point_mapping\" where deleted = false order by id asc");
        assertFalse(expectedRows.isEmpty(), "No points found!!");

        expectedRows.removeIf(row -> {
            if (!levelId.equals(row.level_id) || !levelType.equals(row.level_type)) {
                return true;
            }
            var effectiveStart = ZonedDateTime.parse(row.start_dttm_utc);
            var effectiveEnd = ZonedDateTime.parse(row.end_dttm_utc);
            if (startDttm.isEqual(endDttm)) {  // special case
                return !(startDttm.isEqual(effectiveStart) || (startDttm.isAfter(effectiveStart) && startDttm.isBefore(effectiveEnd)));
            } else {
                boolean startIsIncluded = startDttm.isBefore(effectiveEnd);
                boolean endIsIncluded = endDttm.isAfter(effectiveStart);
                return !(startIsIncluded && endIsIncluded);
            }
        });

        // Now compare expected and actual
        var expectedIds = expectedRows.stream().map(row -> row.id).toList();
        var actualIds = data.stream().map(row -> Long.parseLong(row.get("id").toString())).toList();
        assertEquals(expectedIds, actualIds, "Invalid set of point rows returned!");

        LOG.info(String.format("GET verified, %d rows returned", actualIds.size()));
    }


    @Then("exactly {int} financial point mapping(s) should be returned")
    public void exactlyNFinancialPointMappingsShouldBeReturned(int numExpected) {
        int actualSize = request.getDataAsList().size();
        assertEquals(numExpected, actualSize, String.format("Expected %d financial point mappings, but got %d", numExpected, actualSize));
        LOG.info("{} financial point mappings were returned as expected", numExpected);
    }


    @Then("no financial point mappings should be returned")
    public void noFinancialPointMappingsShouldBeReturned () {
        assertTrue(request.getDataAsList().isEmpty(), "Financial point mappings were returned!!");
        LOG.info("Response verified");
    }

    @Then("the following financial point should be returned:")
    public void finPointDetailedValidation(DataTable paramTable) {
        var expected = new TreeMap<>(paramTable.asMap(String.class, Object.class));
        var actuals = request.getDataAsList();
        assertEquals(1, actuals.size(), "Unexpected number of points returned!");
        var actual = new TreeMap<>(actuals.get(0));
        expected.replace("channel_id", Integer.parseInt(expected.get("channel_id").toString()));  // need to convert to integer
        expected.put("id", actual.getOrDefault("id", "<missing>")); // this is set by db
        expected.put("last_updated_dttm_utc", actual.getOrDefault("last_updated_dttm_utc", "<missing>"));
        expected.put("last_updated_by", actual.getOrDefault("last_updated_by", "<missing>"));
        assertEquals(expected, actual);
        // Validate formats of these fields
        var date = ZonedDateTime.parse(actual.get("last_updated_dttm_utc").toString());
        var earliestReasonableDate = ZonedDateTime.parse("2024-07-01T00:00:00Z");
        assertTrue(date.isAfter(earliestReasonableDate), String.format("last_updated_dttm_utc is not a reasonable date: %s", date));
        UUID uuid = UUID.fromString(actual.get("last_updated_by").toString()); // will throw an exception if not a valid uuid
    }


    // -------- UTILITY STEPDEFS

    @Given("I log the first settlement returned")
    public void iLogFirstSettlement() {
        LOG.info(request.getDataAsList().get(0).toString());
    }


}
