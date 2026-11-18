package com.enernoc.bdap.stepdefs;

import com.enernoc.bdap.model.APIResponses;
import com.enernoc.bdap.model.HttpOp;
import com.enernoc.bdap.model.HttpStatus;
import com.enernoc.bdap.model.RequestContainer;
import com.enernoc.bdap.shared.Context;
import com.enernoc.bdap.shared.Utility;
import io.cucumber.datatable.DataTable;
import io.cucumber.java.en.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.*;

import static com.enernoc.bdap.model.EntityType.REGISTRATION_HISTORY_OVERRIDE;
import static com.enernoc.bdap.model.EntityType.REGISTRATION_HISTORY_OVERRIDES;
import static org.junit.jupiter.api.Assertions.*;

public class CrudRegistrationHistoryOverrides {

    private static final Logger LOG = LoggerFactory.getLogger(CrudRegistrationHistoryOverrides.class);

    private final Context context = Context.getContext();
    private final Utility utility = new Utility();

    private RequestContainer request;

    // Saved ids
    private String lastRegistrationId;          // registration_id (UUID string)
    private String lastOverrideId;             // override row id (string)

    // Latest override snapshot used for GET-one verification
    private final Map<String, Object> savedOverrideState = new HashMap<>();

    private String getRequiredRegistrationId() {
        assertNotNull(lastRegistrationId, "No current registration_id set for overrides!");
        return lastRegistrationId;
    }

    private String getRequiredOverrideId() {
        assertNotNull(lastOverrideId, "No current registration history override id set!");
        return lastOverrideId;
    }

    // ------------------------------------------------------------------------
    // Context helpers
    // ------------------------------------------------------------------------

    @Given("I generate a random registration id and save it as {word}")
    public void iGenerateRandomRegistrationIdAndSaveAs(String key) {
        String randomId = UUID.randomUUID().toString();
        context.savedValues.put(key, randomId);
        this.lastRegistrationId = randomId;
        LOG.info("Generated random registration_id {}", randomId);
    }

    @And("I save this registration history override id as {word}")
    public void iSaveThisOverrideIdAs(String key) {
        String id = getRequiredOverrideId();
        context.savedValues.put(key, id);
    }

    @Given("I set the context registration history override id to {word}")
    public void iSetContextOverrideIdToTag(String key) {
        String id = context.savedValues.get(key);
        assertNotNull(id, "No override id saved for key " + key);
        this.lastOverrideId = id;
    }

    // ------------------------------------------------------------------------
    // POST
    // ------------------------------------------------------------------------

    @When("I POST a new registration history override specifying the following properties")
    public void iPostNewRegistrationHistoryOverride(DataTable table) {
        HashMap<String, Object> body = new HashMap<>(table.asMap(String.class, Object.class));

        // Resolve saved values from context (e.g. OverrideRegistrationId)
        body.replaceAll((ignored, v) -> {
            if (v instanceof String s && context.savedValues.containsKey(s)) {
                return context.savedValues.get(s);
            }
            return v;
        });

        utility.replaceParmValues(body);

        request = RequestContainer.build()
                .submitEntity(HttpOp.POST, REGISTRATION_HISTORY_OVERRIDE, body);

        HttpStatus expected = context.popExpectedStatus(201);
        var entity = request.call(expected)
                .getResponseEntity(APIResponses.PostRegistrationHistoryOverride.class);

        if (expected.getCode() == 201) {
            assertNotNull(entity, "POST override response entity is null");
            var data = entity.data();
            assertNotNull(data, "POST override data is null");
            this.lastOverrideId = data.id;
            this.lastRegistrationId = data.registration_id;
            LOG.info("Created registration history override id={}, registration_id={}", lastOverrideId, lastRegistrationId);
        }
    }

    @Then("the response should include the new registration history override")
    public void responseShouldIncludeNewRegistrationHistoryOverride() {
        // Response map from POST
        Map<String, Object> data = request.getDataAsList().get(0);
        assertNotNull(data, "POST override response missing data object");

        // Check mandatory fields match the request payload
        Map<String, Object> body = request.getBodyProps();

        // Strict equality for payload fields
        assertEquals(body.get("registration_id"), data.get("registration_id"), "registration_id mismatch");
        assertEquals(body.get("field_name"), data.get("field_name"), "field_name mismatch");
        assertEquals(body.get("field_value"), data.get("field_value"), "field_value mismatch");
        assertEquals(body.get("effective_start_dttm_utc"), data.get("effective_start_dttm_utc"), "effective_start_dttm_utc mismatch");
        assertEquals(body.get("effective_end_dttm_utc"), data.get("effective_end_dttm_utc"), "effective_end_dttm_utc mismatch");
        assertEquals(body.get("override_reason"), data.get("override_reason"), "override_reason mismatch");

        // Non-payload fields: not null and non-empty where applicable
        assertNotNull(data.get("id"), "id is null");
        this.lastOverrideId = String.valueOf(data.get("id"));

        assertNotNull(data.get("deleted"), "deleted is null");

        Object createdBy = data.get("created_by");
        assertNotNull(createdBy, "created_by is null");
        assertFalse(String.valueOf(createdBy).isBlank(), "created_by is blank");

        Object createdDttm = data.get("created_dttm_utc");
        assertNotNull(createdDttm, "created_dttm_utc is null");
        assertFalse(String.valueOf(createdDttm).isBlank(), "created_dttm_utc is blank");

        Object lastUpdatedBy = data.get("last_updated_by");
        assertNotNull(lastUpdatedBy, "last_updated_by is null");
        assertFalse(String.valueOf(lastUpdatedBy).isBlank(), "last_updated_by is blank");

        Object lastUpdatedDttm = data.get("last_updated_dttm_utc");
        assertNotNull(lastUpdatedDttm, "last_updated_dttm_utc is null");
        assertFalse(String.valueOf(lastUpdatedDttm).isBlank(), "last_updated_dttm_utc is blank");

        // Save the full latest state for later GET-one verification
        savedOverrideState.clear();
        savedOverrideState.putAll(data);

        LOG.info("POST registration_history_override response verified");
    }

    // ------------------------------------------------------------------------
    // PUT
    // ------------------------------------------------------------------------

    @When("I update the registration history override with new values")
    public void iPutRegistrationHistoryOverride(DataTable table) {
        HashMap<String, Object> body = new HashMap<>(table.asMap(String.class, Object.class));
        utility.replaceParmValues(body);

        String urlId = getRequiredOverrideId();

        request = RequestContainer.build()
                .submitEntity(HttpOp.PUT, REGISTRATION_HISTORY_OVERRIDE, body)
                .addIdToPath(urlId);

        HttpStatus expected = context.popExpectedStatus(200);
        var entity = request.call(expected)
                .getResponseEntity(APIResponses.PutRegistrationHistoryOverride.class);

        if (expected.getCode() == 200) {
            assertNotNull(entity, "PUT override response entity is null");
            var data = entity.data();
            assertNotNull(data, "PUT override data is null");
            this.lastOverrideId = data.id;
            this.lastRegistrationId = data.registration_id;
        }
    }

    @Then("the response should include the updated registration history override")
    public void responseShouldIncludeUpdatedRegistrationHistoryOverride() {
        Map<String, Object> data = request.getDataAsList().get(0);

        assertNotNull(data, "PUT override response missing data object");

        Map<String, Object> body = request.getBodyProps();

        // registration_id should remain the same as before
        assertEquals(getRequiredRegistrationId(), data.get("registration_id"), "registration_id changed unexpectedly");

        // Strict checks for fields present in PUT payload
        assertEquals(body.get("field_name"), data.get("field_name"), "field_name mismatch after PUT");
        assertEquals(body.get("field_value"), data.get("field_value"), "field_value mismatch after PUT");
        assertEquals(body.get("effective_start_dttm_utc"), data.get("effective_start_dttm_utc"), "effective_start_dttm_utc mismatch after PUT");
        assertEquals(body.get("effective_end_dttm_utc"), data.get("effective_end_dttm_utc"), "effective_end_dttm_utc mismatch after PUT");
        assertEquals(body.get("override_reason"), data.get("override_reason"), "override_reason mismatch after PUT");

        // Non-payload fields must be present and non-null/non-blank
        assertNotNull(data.get("id"), "id is null after PUT");
        this.lastOverrideId = String.valueOf(data.get("id"));

        assertNotNull(data.get("deleted"), "deleted is null after PUT");

        Object createdBy = data.get("created_by");
        assertNotNull(createdBy, "created_by is null after PUT");
        assertFalse(String.valueOf(createdBy).isBlank(), "created_by is blank after PUT");

        Object createdDttm = data.get("created_dttm_utc");
        assertNotNull(createdDttm, "created_dttm_utc is null after PUT");
        assertFalse(String.valueOf(createdDttm).isBlank(), "created_dttm_utc is blank after PUT");

        Object lastUpdatedBy = data.get("last_updated_by");
        assertNotNull(lastUpdatedBy, "last_updated_by is null after PUT");
        assertFalse(String.valueOf(lastUpdatedBy).isBlank(), "last_updated_by is blank after PUT");

        Object lastUpdatedDttm = data.get("last_updated_dttm_utc");
        assertNotNull(lastUpdatedDttm, "last_updated_dttm_utc is null after PUT");
        assertFalse(String.valueOf(lastUpdatedDttm).isBlank(), "last_updated_dttm_utc is blank after PUT");

        // Update saved state for later GET-one comparison
        savedOverrideState.clear();
        savedOverrideState.putAll(data);

        LOG.info("PUT registration_history_override response verified");
    }

    @When("I update the registration history override with id {string} and new values")
    public void iPutRegistrationHistoryOverrideWithId(String overrideId, DataTable table) {
        HashMap<String, Object> body = new HashMap<>(table.asMap(String.class, Object.class));
        utility.replaceParmValues(body);

        request = RequestContainer.build()
                .submitEntity(HttpOp.PUT, REGISTRATION_HISTORY_OVERRIDE, body)
                .addIdToPath(overrideId);

        HttpStatus expected = context.popExpectedStatus(200);
        request.call(expected); // for error cases we just let Then 'expected status' assert
    }

    @When("I update the current registration history override with new values")
    public void iUpdateCurrentRegistrationHistoryOverride(DataTable table) {
        String overrideId = getRequiredOverrideId();
        iPutRegistrationHistoryOverrideWithId(overrideId, table);
    }

    // Generic negative/validation case – uses status set in Given
    @When("I update the registration history override with id {string} and new values expecting failure")
    public void iPutRegistrationHistoryOverrideWithIdExpectingFailure(String overrideId, DataTable table) {
        HashMap<String, Object> body = new HashMap<>(table.asMap(String.class, Object.class));
        utility.replaceParmValues(body);

        request = RequestContainer.build()
                .submitEntity(HttpOp.PUT, REGISTRATION_HISTORY_OVERRIDE, body)
                .addIdToPath(overrideId);
        HttpStatus expected = HttpStatus.build().withCode((404));
        request.call(expected);
    }

    @Then("the updated registration history override response should reflect the new values")
    public void updatedOverrideShouldReflectNewValues() {
        Map<String, Object> data = request.getDataAsList().get(0);
        assertNotNull(data, "PUT override response data is null");

        Map<String, Object> body = request.getBodyProps();

        // Verify that updated fields match the PUT payload
        assertEquals(body.get("field_name"), data.get("field_name"), "field_name was not updated");
        assertEquals(body.get("field_value"), data.get("field_value"), "field_value was not updated");
        assertEquals(body.get("effective_start_dttm_utc"), data.get("effective_start_dttm_utc"),
                "effective_start_dttm_utc was not updated");
        assertEquals(body.get("effective_end_dttm_utc"), data.get("effective_end_dttm_utc"),
                "effective_end_dttm_utc was not updated");
        assertEquals(body.get("override_reason"), data.get("override_reason"), "override_reason was not updated");

        // Check id & registration_id unchanged
        assertEquals(getRequiredOverrideId(), String.valueOf(data.get("id")), "id should not change on update");
        assertEquals(getRequiredRegistrationId(), String.valueOf(data.get("registration_id")),
                "registration_id should not change on update");
    }

    // ------------------------------------------------------------------------
    // GET all
    // ------------------------------------------------------------------------

    @When("I GET all registration history overrides for the current registration")
    public void iGetAllRegistrationHistoryOverridesForCurrentRegistration() {
        String regId = getRequiredRegistrationId();

        request = RequestContainer.build()
                .getEntities(REGISTRATION_HISTORY_OVERRIDES);
        request.addQueryParm("registration_id", regId);

        HttpStatus expected = context.popExpectedStatus(200);
        request.call(expected);
    }

    @Then("the registration history overrides list should contain my override")
    public void registrationHistoryOverridesListShouldContainMyOverride() {
        String overrideId = getRequiredOverrideId();
        String regId = getRequiredRegistrationId();

        List<HashMap<String, Object>> list = request.getDataAsList();
        assertFalse(list.isEmpty(), "No registration history overrides returned");

        boolean found = list.stream().anyMatch(m ->
                overrideId.equals(Objects.toString(m.get("id"), null)) &&
                        regId.equals(Objects.toString(m.get("registration_id"), null)));

        assertTrue(found, "Current registration history override not found in list");
    }

    @When("I GET all registration history overrides with include_deleted flag")
    public void iGetAllRegistrationHistoryOverridesWithIncludeDeleted() {
        request = RequestContainer.build()
                .getEntities(REGISTRATION_HISTORY_OVERRIDES)  // collection-type constant
                .addQueryParm("include_deleted", "true");

        HttpStatus expected = context.popExpectedStatus(200);
        request.call(expected);
    }

    @When("I GET all registration history overrides for registration_id {string}")
    public void iGetAllRegistrationHistoryOverridesForRegistrationId(String registrationId) {
        request = RequestContainer.build()
                .getEntities(REGISTRATION_HISTORY_OVERRIDES)
                .addQueryParm("registration_id", registrationId);

        HttpStatus expected = context.popExpectedStatus(200);
        request.call(expected);
    }

    @When("I GET all registration history overrides for the current registration_id including deleted")
    public void iGetAllRegistrationHistoryOverridesForCurrentRegistrationIdIncludingDeleted() {
        String registrationId = getRequiredRegistrationId();

        request = RequestContainer.build()
                .getEntities(REGISTRATION_HISTORY_OVERRIDES)
                .addQueryParm("registration_id", registrationId)
                .addQueryParm("include_deleted", true);

        HttpStatus expected = context.popExpectedStatus(200);
        request.call(expected);
    }

    @Then("the registration history overrides list should be empty")
    public void registrationHistoryOverridesListShouldBeEmpty() {
        List<HashMap<String, Object>> list = request.getDataAsList();
        assertNotNull(list, "data list is null");
        assertTrue(list.isEmpty(), "Expected empty list of registration history overrides but got size " + list.size());
    }

    @Then("the registration history overrides list should contain valid populated items")
    public void registrationHistoryOverridesListShouldContainValidPopulatedItems() {
        List<HashMap<String, Object>> list = request.getDataAsList();
        assertNotNull(list, "GET-all response data list is null");

        // It can be empty for some scenarios (e.g. non-existent registration_id),
        // so only validate items when present.
        if (list.isEmpty()) {
            return;
        }

        List<String> requiredFields = List.of(
                "id",
                "registration_id",
                "field_name",
                "field_value",
                "effective_start_dttm_utc",
                "effective_end_dttm_utc",
                "deleted",
                "override_reason",
                "created_by",
                "created_dttm_utc",
                "last_updated_by",
                "last_updated_dttm_utc"
        );

        for (Map<String, Object> item : list) {
            assertNotNull(item, "List contains null item");

            // Required fields present and non-null
            for (String field : requiredFields) {
                assertTrue(item.containsKey(field), "Missing field: " + field);
                assertNotNull(item.get(field), "Field is null: " + field);
            }

            // Types and basic semantics
            Object deleted = item.get("deleted");
            assertInstanceOf(Boolean.class, deleted, "deleted is not a boolean");

            // Strings non-blank
            for (String field : List.of(
                    "id",
                    "registration_id",
                    "field_name",
                    "field_value",
                    "override_reason",
                    "created_by",
                    "created_dttm_utc",
                    "last_updated_by",
                    "last_updated_dttm_utc",
                    "effective_start_dttm_utc",
                    "effective_end_dttm_utc"
            )) {
                Object value = item.get(field);
                assertInstanceOf(String.class, value, "Field is not a string: " + field);
                assertFalse(((String) value).isBlank(), "Field is blank: " + field);
            }

            // id numeric string
            String id = String.valueOf(item.get("id"));
            assertTrue(id.matches("\\d+"), "id is not a numeric string: " + id);

            // registration_id, created_by, last_updated_by UUIDs
            for (String field : List.of("registration_id", "created_by", "last_updated_by")) {
                String value = String.valueOf(item.get(field));
                assertDoesNotThrow(() -> java.util.UUID.fromString(value),
                        field + " is not a valid UUID: " + value);
            }

            // Date-time fields parse as ISO instants
            for (String field : List.of(
                    "effective_start_dttm_utc",
                    "effective_end_dttm_utc",
                    "created_dttm_utc",
                    "last_updated_dttm_utc"
            )) {
                String value = String.valueOf(item.get(field));
                assertDoesNotThrow(() -> java.time.Instant.parse(value),
                        field + " is not a valid ISO-8601 UTC timestamp: " + value);
            }
        }
    }

    // ------------------------------------------------------------------------
    // GET one
    // ------------------------------------------------------------------------

    @When("I GET the registration history override by id")
    public void iGetRegistrationHistoryOverrideById() {
        String id = getRequiredOverrideId();

        request = RequestContainer.build()
                .getEntity(REGISTRATION_HISTORY_OVERRIDE, id);

        HttpStatus expected = context.popExpectedStatus(200);
        request.call(expected);
    }

    @Then("GET registration history override should return the current state")
    public void getRegistrationHistoryOverrideShouldReturnCurrentState() {
        Map<String, Object> data = request.getDataAsList().get(0);

        assertNotNull(data, "GET one override response missing data object");

        assertFalse(savedOverrideState.isEmpty(), "No saved override state to compare with");

        // Compare only non-null fields in savedOverrideState
        Map<String, Object> expected = new HashMap<>();
        savedOverrideState.forEach((k, v) -> {
            if (v != null) {
                expected.put(k, v);
            }
        });

        // Simple field-by-field comparison
        List<String> errors = new ArrayList<>();
        for (Map.Entry<String, Object> e : expected.entrySet()) {
            Object actual = data.get(e.getKey());
            if (!Objects.equals(e.getValue(), actual)) {
                errors.add(String.format("Field %s mismatch. Expected '%s', actual '%s'",
                        e.getKey(), e.getValue(), actual));
            }
        }

        assertTrue(errors.isEmpty(), String.join("\n", errors));
        LOG.info("GET registration_history_override current state verified");
    }

    @Then("the registration history override response should contain valid populated fields")
    public void registrationHistoryOverrideResponseShouldContainValidPopulatedFields() {
        Map<String, Object> data = request.getDataAsList().get(0);
        assertNotNull(data, "GET override response data is null");

        // Required fields present
        List<String> requiredFields = List.of(
                "id",
                "registration_id",
                "field_name",
                "field_value",
                "effective_start_dttm_utc",
                "effective_end_dttm_utc",
                "deleted",
                "override_reason",
                "created_by",
                "created_dttm_utc",
                "last_updated_by",
                "last_updated_dttm_utc"
        );

        for (String field : requiredFields) {
            assertTrue(data.containsKey(field), "Missing field: " + field);
            assertNotNull(data.get(field), "Field is null: " + field);
        }

        // String fields present and non-blank
        List<String> nonBlankStringFields = List.of(
                "id",
                "registration_id",
                "field_name",
                "field_value",
                "override_reason",
                "created_by",
                "created_dttm_utc",
                "last_updated_by",
                "last_updated_dttm_utc",
                "effective_start_dttm_utc",
                "effective_end_dttm_utc"
        );

        for (String field : nonBlankStringFields) {
            Object value = data.get(field);
            assertInstanceOf(String.class, value, "Field is not a string: " + field);
            assertFalse(((String) value).isBlank(), "Field is blank: " + field);
        }

        // deleted must be boolean
        assertInstanceOf(Boolean.class, data.get("deleted"), "deleted is not a boolean");

        // id should be numeric string
        String id = String.valueOf(data.get("id"));
        assertTrue(id.matches("\\d+"), "id is not a numeric string: " + id);

        // registration_id should be UUID
        String registrationId = String.valueOf(data.get("registration_id"));
        assertDoesNotThrow(() -> java.util.UUID.fromString(registrationId),
                "registration_id is not a valid UUID: " + registrationId);

        // created_by and last_updated_by should be UUIDs
        String createdBy = String.valueOf(data.get("created_by"));
        assertDoesNotThrow(() -> java.util.UUID.fromString(createdBy),
                "created_by is not a valid UUID: " + createdBy);

        String lastUpdatedBy = String.valueOf(data.get("last_updated_by"));
        assertDoesNotThrow(() -> java.util.UUID.fromString(lastUpdatedBy),
                "last_updated_by is not a valid UUID: " + lastUpdatedBy);

        // Date-time fields should parse as ISO instants
        List<String> dateFields = List.of(
                "effective_start_dttm_utc",
                "effective_end_dttm_utc",
                "created_dttm_utc",
                "last_updated_dttm_utc"
        );

        for (String field : dateFields) {
            String value = String.valueOf(data.get(field));
            assertDoesNotThrow(() -> java.time.Instant.parse(value),
                    field + " is not a valid ISO-8601 UTC timestamp: " + value);
        }
    }

    @When("I GET the registration history override by id including deleted")
    public void iGetRegistrationHistoryOverrideByIdIncludingDeleted() {
        String id = getRequiredOverrideId();
        iGetRegistrationHistoryOverrideWithIdIncludingDeleted(id);
    }

    @When("I GET the registration history override with id {string} including deleted")
    public void iGetRegistrationHistoryOverrideWithIdIncludingDeleted(String id) {
        request = RequestContainer.build()
                .getEntity(REGISTRATION_HISTORY_OVERRIDE, id)
                .addQueryParm("include_deleted", "true");


        HttpStatus expected = context.popExpectedStatus(200);
        request.call(expected);
    }

    // ------------------------------------------------------------------------
    // DELETE
    // ------------------------------------------------------------------------

    @When("I DELETE my registration history override")
    public void iDeleteMyRegistrationHistoryOverride() {
        String id = getRequiredOverrideId();

        request = RequestContainer.build()
                .deleteEntity(REGISTRATION_HISTORY_OVERRIDE, id);

        HttpStatus expected = context.popExpectedStatus(204);
        request.call(expected);

        LOG.info("Deleted registration_history_override id={}", id);
    }

    @When("I DELETE registration history override with id {string}")
    public void iDeleteRegistrationHistoryOverrideWithId(String id) {
        request = RequestContainer.build()
                .deleteEntity(REGISTRATION_HISTORY_OVERRIDE, id);

        HttpStatus expected = context.popExpectedStatus(204);
        request.call(expected);
    }

    @Then("the delete should succeed")
    public void theDeleteShouldSucceed() {
        // Status already asserted in call(); optional extra check:
        assertEquals(204, context.lastRequest.response.getStatusCode(),
                "Expected 204 from DELETE registration history override");
    }

    @Then("the registration history override response should be marked as deleted")
    public void registrationHistoryOverrideResponseShouldBeMarkedAsDeleted() {
        Map<String, Object> data = request.getDataAsList().get(0);
        assertNotNull(data, "GET override response data is null");

        Object deleted = data.get("deleted");
        assertNotNull(deleted, "deleted field is missing or null");
        assertInstanceOf(Boolean.class, deleted, "deleted field is not a boolean");
        assertTrue((Boolean) deleted, "deleted flag should be true for a soft-deleted override");
    }

//    public static class DbCleanupSteps {
//
//        private final PostgresClient postgresClient;
//
//        public DbCleanupSteps(PostgresClient postgresClient) {
//            this.postgresClient = postgresClient;
//        }
//
//        @Given("I hard delete all test registration history overrides for known effective windows")
//        public void hardDeleteAllTestOverridesForKnownWindows() throws Throwable {
//            String condition = """
//            (effective_start_dttm_utc = TIMESTAMPTZ '2026-04-01T07:33:38.213Z'
//             AND effective_end_dttm_utc   = TIMESTAMPTZ '2026-04-02T10:33:38.213Z')
//          OR
//            (effective_start_dttm_utc = TIMESTAMPTZ '2026-04-10T07:33:38.213Z'
//             AND effective_end_dttm_utc   = TIMESTAMPTZ '2026-04-10T08:33:38.213Z')
//            """;
//
//            postgresClient.deleteRecordsTable("registration_history_override", condition);
//        }
//    }


}