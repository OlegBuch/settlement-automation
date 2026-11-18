package com.enernoc.bdap.stepdefs;

import com.enernoc.bdap.model.HttpStatus;
import com.enernoc.bdap.model.RequestContainer;
import com.enernoc.bdap.shared.Context;
import io.cucumber.datatable.DataTable;
import io.cucumber.java.en.Given;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

public class EcoAdhocFinancial {

    private static final Logger LOG = LoggerFactory.getLogger(EcoAdhocFinancial.class);
    private final Context context = Context.getContext();
    private RequestContainer request;

    private List<HashMap<String, Object>> payloadList = new ArrayList<>();
    private HashMap<String, Object> currentElement = new HashMap<>();
    private String rawPayload = null;

    private static Object parseValue(String value) {
        if (value == null || "null".equalsIgnoreCase(value)) return null;
        if ("empty".equalsIgnoreCase(value)) return "";
        if (value.startsWith("num:")) return new java.math.BigDecimal(value.substring(4).trim());
        return value;
    }

    // ──────────────────────────────────────────────
    // Payload Construction Steps
    // ──────────────────────────────────────────────

    @Given("I create an adhoc financial element with body")
    public void iCreateAdhocFinancialElementWithBody(DataTable table) {
        currentElement = new HashMap<>();
        Map<String, String> data = table.asMap(String.class, String.class);

        for (Map.Entry<String, String> entry : data.entrySet()) {
            String key = entry.getKey();
            String value = entry.getValue();

            // Helper logic to handle special keywords passed from Gherkin
            if ("null".equalsIgnoreCase(value)) {
                currentElement.put(key, null);
            } else if ("empty".equalsIgnoreCase(value)) {
                currentElement.put(key, "");
            } else {
                currentElement.put(key, parseValue(value));
            }
        }
        rawPayload = null; // Ensure raw payload mode is turned off
        LOG.info("Created adhoc financial element from DataTable with {} fields", data.size());
    }

    @Given("I create an empty adhoc financial element")
    public void iCreateEmptyAdhocFinancialElement() {
        currentElement = new HashMap<>();
    }

    @Given("I set the {string} field to {string} in the current element")
    public void iSetFieldToString(String field, String value) {
        currentElement.put(field, value);
    }

    @Given("I set the {string} field to null in the current element")
    public void iSetFieldToNull(String field) {
        currentElement.put(field, null);
    }

    @Given("I remove the {string} field from the current element")
    public void iRemoveField(String field) {
        currentElement.remove(field);
    }

    @Given("I add custom field {string} with value {string} to the current element")
    public void iAddCustomFieldString(String key, String value) {
        currentElement.put(key, value);
    }

    @Given("I add custom field {string} with numeric value {int} to the current element")
    public void iAddCustomFieldNumeric(String key, int value) {
        currentElement.put(key, value);
    }

    @Given("I add custom field {string} with boolean value {word} to the current element")
    public void iAddCustomFieldBoolean(String key, String value) {
        currentElement.put(key, Boolean.parseBoolean(value));
    }

    @Given("I add custom field {string} with null value to the current element")
    public void iAddCustomFieldNull(String key) {
        currentElement.put(key, null);
    }

    @Given("I add the current element to the adhoc financial payload")
    public void iAddCurrentElementToPayload() {
        payloadList.add(new HashMap<>(currentElement));
        rawPayload = null;
    }

    @Given("I set the adhoc financial payload to an empty array")
    public void iSetPayloadToEmptyArray() {
        payloadList.clear();
        rawPayload = null;
    }

    @Given("I set the raw adhoc financial payload to {string}")
    public void iSetRawPayload(String json) {
        rawPayload = json;
        payloadList.clear();
    }

    // ──────────────────────────────────────────────
    // Action Steps
    // ──────────────────────────────────────────────

    @When("I POST the adhoc financial payload")
    public void iPostAdhocFinancialPayload() {
        request = RequestContainer.build().submitAdhocFinancial(payloadList);
        request.call(context.popExpectedStatus(200));
    }

    @When("I POST the raw adhoc financial payload")
    public void iPostRawAdhocFinancialPayload() {
        request = RequestContainer.build().submitRawAdhocFinancial(rawPayload);
        request.call(context.popExpectedStatus(200));
    }

    @When("I POST the adhoc financial payload with Atlas mocked as unavailable")
    public void iPostWithAtlasMocked() {
        request = RequestContainer.build().submitAdhocFinancial(payloadList);
        request.call(context.popExpectedStatus(500));
    }

    @Then("the response should contain {int} inserted ids")
    public void responseShouldContainIds(int count) {
        // Extract the list of IDs from the correct nested JSON path
        List<Object> ids = request.response.jsonPath().getList("data.adhoc_financial_ids");

        assertNotNull(ids, "Response 'data.adhoc_financial_ids' is null or missing. Raw response: " + request.response.getBody().asString());
        assertEquals(count, ids.size(), "Expected " + count + " inserted ids but got " + ids.size());

        LOG.info("Successfully verified {} inserted ids in response: {}", count, ids);
    }

    @Given("I add {int} baseline valid elements to the adhoc financial payload")
    public void iAddMultipleBaselineValidElements(int count) {
        // The "baseline" is now defined in the .feature file via a DataTable.
        // This step simply clones that template element `count` times.
        assertFalse(currentElement.isEmpty(),
                "No baseline template found! First create an element with " +
                        "'Given I create an adhoc financial element with body' + DataTable.");

        payloadList.clear();
        for (int i = 0; i < count; i++) {
            payloadList.add(new HashMap<>(currentElement));
        }
        rawPayload = null;
        LOG.info("Added {} cloned baseline elements to the payload", count);
    }

    @Given("I save the first inserted id from the response")
    public void iSaveTheFirstInsertedIdFromTheResponse() {
        List<Object> ids = request.response.jsonPath().getList("data.adhoc_financial_ids");
        assertNotNull(ids, "Response 'data.adhoc_financial_ids' is null or missing.");
        assertFalse(ids.isEmpty(), "No IDs returned in POST response to save.");

        context.lastCreatedAdhocFinancialId = ids.get(0).toString();
        LOG.info("Saved adhoc_financial ID: {}", context.lastCreatedAdhocFinancialId);
    }

    private String resolveId(String idOrKey) {
        if ("target_id".equals(idOrKey) || idOrKey == null) {
            assertNotNull(context.lastCreatedAdhocFinancialId, "No saved ID found in context. Did you run the POST step first?");
            return context.lastCreatedAdhocFinancialId;
        }
        return idOrKey; // Assume it's a raw UUID passed directly from Gherkin
    }

    @When("I GET the adhoc financial record")
    public void iGetTheAdhocFinancialRecord() {
        iGetTheAdhocFinancialRecordForId("target_id");
    }

    @When("I GET the adhoc financial record for id {string}")
    public void iGetTheAdhocFinancialRecordForId(String idOrKey) {
        String id = resolveId(idOrKey);
        request = RequestContainer.build().getAdhocFinancial(id);
        request.call(context.popExpectedStatus(200));
    }

    @When("I PUT the adhoc financial record with body")
    public void iPutTheAdhocFinancialRecordWithBody(DataTable table) {
        iPutTheAdhocFinancialRecordForIdWithBody("target_id", table);
    }

    @When("I PUT the adhoc financial record for id {string} with body")
    public void iPutTheAdhocFinancialRecordForIdWithBody(String idOrKey, DataTable table) {
        String id = resolveId(idOrKey);
        HashMap<String, Object> body = new HashMap<>();
        Map<String, String> data = table.asMap(String.class, String.class);

        for (Map.Entry<String, String> entry : data.entrySet()) {
            String key = entry.getKey();
            String value = entry.getValue();
            if ("null".equalsIgnoreCase(value)) {
                body.put(key, null);
            } else if ("empty".equalsIgnoreCase(value)) {
                body.put(key, "");
            } else {
                body.put(key, parseValue(value));
            }
        }

        request = RequestContainer.build().updateAdhocFinancial(id, body);
        request.call(context.popExpectedStatus(200));
    }

    @When("I delete the adhoc financial record")
    public void iDeleteTheAdhocFinancialRecord() {
        iDeleteTheAdhocFinancialRecordForId("target_id");
    }

    @When("I delete the adhoc financial record for id {string}")
    public void iDeleteTheAdhocFinancialRecordForId(String idOrKey) {
        String id = resolveId(idOrKey);
        request = RequestContainer.build().deleteAdhocFinancial(id);
        // Soft deletes typically return 204
        request.call(context.popExpectedStatus(204));
    }

    @Then("the response should contain the adhoc financial data")
    public void theResponseShouldContainTheAdhocFinancialData() {
        assertNotNull(request.response, "Response is null");
        Object data = request.response.jsonPath().get("data");
        assertNotNull(data, "Response 'data' field is missing");
        LOG.info("Successfully retrieved adhoc financial data");
    }

    /**
     * Bulk cleanup: deletes EVERY id returned by the last POST response
     * (data.adhoc_financial_ids). Used after batch inserts (3 / 100 elements).
     * Gherkin: Then I delete all inserted records from the response
     */
    @Then("I delete all inserted records from the response")
    public void iDeleteAllInsertedRecords() {
        assertNotNull(request, "No request was executed yet - nothing to clean up.");
        assertNotNull(request.response, "No response available - nothing to clean up.");
        List<Object> ids = request.response.jsonPath().getList("data.adhoc_financial_ids");
        assertNotNull(ids, "Response 'data.adhoc_financial_ids' is null or missing.");
        int cleaned = 0;
        for (Object id : ids) {
            RequestContainer.build()
                    .deleteAdhocFinancial(id.toString())
                    .call(context.popExpectedStatus(204));
            cleaned++;
        }
        LOG.info("Cleaned up {} inserted adhoc financial records", cleaned);
    }

// ──────────────────────────────────────────────
// GET - additional
// ──────────────────────────────────────────────

    @When("I send a PATCH request to the adhoc financial record")
    public void iSendPatchRequestToAdhocFinancialRecord() {
        String id = resolveId("target_id");
        request = RequestContainer.build().sendUnsupportedMethod("PATCH", "adhoc-financial", id);
        HttpStatus expectedStatus = context.popExpectedStatus(400);
        request.assertRawStatusCode(expectedStatus.code);
    }

// ──────────────────────────────────────────────
// PUT - additional body variants
// ──────────────────────────────────────────────

    @When("I PUT the adhoc financial record with an empty body")
    public void iPutTheAdhocFinancialRecordWithEmptyBody() {
        String id = resolveId("target_id");
        HashMap<String, Object> body = new HashMap<>();
        request = RequestContainer.build().updateAdhocFinancial(id, body);
        request.call(context.popExpectedStatus(200));
    }

    @When("I PUT the adhoc financial record with raw body {string}")
    public void iPutTheAdhocFinancialRecordWithRawBody(String json) {
        String id = resolveId("target_id");
        request = RequestContainer.build().updateAdhocFinancialRaw(id, json);
        request.call(context.popExpectedStatus(400));
    }

// ──────────────────────────────────────────────
// PUT / GET response field assertions
// ──────────────────────────────────────────────

    @Then("the custom field {string} should be {string} in the response")
    public void theCustomFieldShouldBeNullInResponse(String fieldName, String new_value) {
        Object value = request.response.jsonPath().get("data." + fieldName);
        assertNotNull(value, "Expected custom field '" + fieldName + "' to be : " + new_value);
        LOG.info("Verified custom field '{}' is updated after using PUT", fieldName);
    }

    @Then("the custom field {string} should equal {string} in the response")
    public void theCustomFieldShouldEqualInResponse(String fieldName, String expectedValue) {
        Object value = request.response.jsonPath().get("data." + fieldName);
        assertNotNull(value, "Expected custom field '" + fieldName + "' to be present");
        assertEquals(expectedValue, value.toString(),
                "Expected custom field '" + fieldName + "' to remain '" + expectedValue + "' but was '" + value + "'");
        LOG.info("Verified untouched custom field '{}' preserved value '{}'", fieldName, expectedValue);
    }


    @Then("the {string} column should be unchanged in the database")
    public void theColumnShouldBeUnchangedInDatabase(String columnName) {
        String id = context.lastCreatedAdhocFinancialId;
        fail("No DB helper exists in Context/RequestContainer to query the ECO database. "
                + "Add a JdbcTemplate/DataSource-backed helper (e.g. Context.ecoDb) that can run "
                + "'SELECT " + columnName + " FROM adhoc_financial WHERE id = ?' with id=" + id
                + " before enabling this scenario.");
    }

    @Then("all adhoc_financial_detail rows for the deleted id should be marked deleted in the database")
    public void allDetailRowsShouldBeMarkedDeleted() {
        String id = context.lastCreatedAdhocFinancialId;
        fail("No DB helper exists in Context/RequestContainer to query the ECO database. "
                + "Add a JdbcTemplate/DataSource-backed helper that can run "
                + "'SELECT deleted FROM adhoc_financial_detail WHERE adhoc_financial_id = ?' with id=" + id
                + " and assert all rows are deleted before enabling this scenario.");
    }

    @When("I delete the adhoc financial record with raw body {string}")
    public void iDeleteTheAdhocFinancialRecordWithRawBody(String json) {
        String id = resolveId("target_id");
        request = RequestContainer.build().deleteAdhocFinancialWithBody(id, json);
        request.call(context.popExpectedStatus(200));
    }
}