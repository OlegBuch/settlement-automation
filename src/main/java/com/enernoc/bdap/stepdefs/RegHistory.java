package com.enernoc.bdap.stepdefs;

import com.enernoc.bdap.model.*;
import com.enernoc.bdap.shared.*;
import com.enernoc.bdap.model.APIResponses.*;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.cucumber.datatable.DataTable;
import io.cucumber.java.en.And;
import io.cucumber.java.en.Given;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.time.ZonedDateTime;
import java.util.*;
import java.util.stream.Collectors;

import static com.enernoc.bdap.model.EntityType.REGISTRATION_HISTORY;
import static com.enernoc.bdap.model.RegistrationAdjective.*;
import static com.enernoc.bdap.shared.Context.*;
import static org.junit.jupiter.api.Assertions.*;

public class RegHistory {

    private static final Logger LOG = LoggerFactory.getLogger("RegHistory");
    private static final ObjectMapper JSON = new ObjectMapper();
    private final Context context = Context.getContext();
    private final Utility utility = new Utility();
    private final PostgresClient client = new PostgresClient(metadataSecretValues);

    private RequestContainer request;
    private final List<HashMap<String, Object>> lastDbHistory = new ArrayList<>();
    private int numDbHistoryRows;

    private void assertHasOverrideForMostRecentRow(List<RegistrationHistory> dbHistory, boolean expected) {
        RegistrationHistory mostRecentDbRow = dbHistory.stream()
                .max(Comparator.comparingLong(r -> r.id))
                .orElseThrow();

        // Convert row to map for convenience if you want, or just check the field directly
        Boolean hasOverride = mostRecentDbRow.has_override; // assuming field exists in model

        assertEquals(expected, Boolean.TRUE.equals(hasOverride),
                String.format("Unexpected value for has_override in most recent history row (id=%d). Expected: %b, Actual: %s",
                        mostRecentDbRow.id, expected, hasOverride));
    }

    @Given("I retrieve and save the complete registration history for {word}")
    public void iRetrieveRegistrationHistory(String regName) throws Throwable {
        context.lastRegistrationId = RegistrationConfig.getRegistrationId(regName);
        var rows = client.getRegistrationHistoryRows(context.lastRegistrationId);
        assertFalse(rows.isEmpty(), "Something's wrong! No history returned");
        var history = new TreeMap<Long, RegistrationHistory>();
        rows.forEach(h -> history.put(h.id, h));
        context.initializeContextRegistrationHistory(context.lastRegistrationId, history);
        if (context.logAllAPIResponses) {
            history.values().forEach(h -> LOG.info("History id: {}  status: {}  {} - {}", h.id, h.status, h.effective_start_dttm_utc, h.effective_end_dttm_utc));
        }
        LOG.info(String.format("History for %s contains %d rows", regName, rows.size()));
    }


    @Then("the registration history should not be updated")
    public void registrationHistoryShouldNotBeUpdated() {

        lastDbHistory.clear();
        assertTrue(context.savedRegistrationOpt.isPresent(), "registration not found in registrationsMap!");
        Registration reg = context.savedRegistrationOpt.get();

        // Get current history from db
        var request = RequestContainer.build()
                .getEntities(REGISTRATION_HISTORY)
                .addQueryParm("id", reg.registration_id)
                .addQueryParm("id_type", "registration")
                .addQueryParm("include_deleted", "true");
        var dbHistory = new ArrayList<>(request.call(context.popExpectedStatus(200)).getResponseEntity(APIResponses.GetRegistrationHistoryResult.class).data());
        assertFalse(dbHistory.isEmpty(), "Something's wrong! No history returned");
        var contextHistory = context.getContextRegistrationHistory(reg.registration_id);
        assertEquals(contextHistory.size(), dbHistory.size(), "History has unexpected number of rows!");
        numDbHistoryRows = dbHistory.size();
        var dbMap = new HashMap<>(dbHistory.stream().collect(Collectors.toMap(h -> h.id, h -> h)));

        assertEquals(contextHistory.keySet(), dbMap.keySet(), "History has unexpected differences!");
        contextHistory.values().forEach(expected -> {
            var dbRow = dbMap.get(expected.id);
            assertNotEquals(expected, dbRow, String.format("Response contains row %d which has been unexpectedly updated!", expected.id));
        });

        var dbIdsStr = dbHistory.stream().map(r -> r.id.toString()).collect(Collectors.joining(","));
        lastDbHistory.addAll(request.getDataAsList());
        LOG.info(String.format("Registration history verified for rows [%s]", dbIdsStr));
    }


    // Alternate syntax. Manual updates are applied to context history as well as db history, so they should still match
    @Then("the registration history should reflect the manual updates")
    public void regHistoryShouldReflectManualUpdates() {
        registrationHistoryShouldNotBeUpdated();
    }


    @Then("the registration history should reflect the {registrationAdjective} operation")
    public void getRegistrationHistoryShouldBeCorrect(RegistrationAdjective adjective) {

        lastDbHistory.clear();
        assertTrue(context.savedRegistrationOpt.isPresent(), "registration not found in registrationsMap!");
        Registration reg = context.savedRegistrationOpt.get();

        // Get current history from db
        var request = RequestContainer.build()
                .getEntities(REGISTRATION_HISTORY)
                .addQueryParm("id", reg.registration_id)
                .addQueryParm("id_type", "registration")
                .addQueryParm("include_deleted", "true");
        var dbHistory = new ArrayList<>(request.call(context.popExpectedStatus(200)).getResponseEntity(APIResponses.GetRegistrationHistoryResult.class).data());
        assertFalse(dbHistory.isEmpty(), "Something's wrong! No history returned");
        numDbHistoryRows = dbHistory.size();
        RegistrationHistory mostRecentDbRow = dbHistory.stream().max(Comparator.comparingLong(r -> r.id)).orElseThrow();
        var dbIds = new TreeSet<>(dbHistory.stream().map(h -> h.id).toList());

        if (DELETE.equals(adjective)) {
            // Because DELETE /registration doesn't return last_updated_dttm_utc, we need to do a hack to set the expected effective_end_dttm_utc
            //assertTrue(mostRecentDbRow.effective_start_dttm_utc > reg.last_updated_dttm_utc);
            var mostRecentStartDttm = ZonedDateTime.parse(mostRecentDbRow.effective_start_dttm_utc);
            var lastUpdatedDttm = ZonedDateTime.parse(reg.last_updated_dttm_utc);
            assertTrue(mostRecentStartDttm.isAfter(lastUpdatedDttm), "mostRecentStartDttm is not greater than lastUpdatedDttm!");
            reg.last_updated_dttm_utc = mostRecentDbRow.effective_start_dttm_utc;
        }

        switch (adjective) {
            case NEW -> {
                // Create expected history row
                assertEquals(1, dbHistory.size(), "More than one history record returned!");
                var regHistory = JSON.convertValue(reg, new TypeReference<RegistrationHistory>() {});
                regHistory.effective_start_dttm_utc = reg.last_updated_dttm_utc;
                regHistory.effective_end_dttm_utc = EFFECTIVE_END_INFINITY;
                regHistory.id = mostRecentDbRow.id;
                var contextHistory = new TreeMap<Long, RegistrationHistory>();
                contextHistory.put(mostRecentDbRow.id, regHistory);
                context.initializeContextRegistrationHistory(reg.registration_id, contextHistory);
                var actual = JSON.convertValue(dbHistory.get(0), new TypeReference<HashMap<String, Object>>() {});
                var expected = JSON.convertValue(regHistory, new TypeReference<HashMap<String, Object>>() {});

                // Validate history
                assertFalse(actual.isEmpty()); // sanity check
                assertEquals(expected, actual);
            }
            case UPDATE, DELETE, RECREATE -> {
                // Find the most recent history row and update it
                var contextHistory = context.getContextRegistrationHistory(reg.registration_id);
                RegistrationHistory prevHist = contextHistory.get(contextHistory.lastKey());
                prevHist.effective_end_dttm_utc = reg.last_updated_dttm_utc;

                // Create the new history row
                assertFalse(contextHistory.containsKey(mostRecentDbRow.id), "History was not updated");
                var regHistory = JSON.convertValue(reg, new TypeReference<RegistrationHistory>() {});
                regHistory.effective_start_dttm_utc = reg.last_updated_dttm_utc;
                regHistory.effective_end_dttm_utc = EFFECTIVE_END_INFINITY;
                regHistory.id = mostRecentDbRow.id;
                contextHistory.put(mostRecentDbRow.id, regHistory);

                // Validate the db history

                // First, validate that the expected number of rows were returned (we do this because we use set objects in the next step)
                assertEquals(contextHistory.size(), dbHistory.size(), "Unexpected number of rows returned from API call");

                // Next, validate that the same set of ids were returned
                assertEquals(contextHistory.keySet(), dbIds, "Set of row ids returned from API call does not match expected set");

                // Now do row-by-row comparison
                for (var row : dbHistory) {
                    var actual = JSON.convertValue(row, new TypeReference<HashMap<String, Object>>() {});
                    var expected = JSON.convertValue(contextHistory.get(row.id), new TypeReference<HashMap<String, Object>>() {});
                    assertEquals(expected, actual, "History row returned from API call does not match expected row");
                }
            }
            default -> fail("Invalid adjective!");
        }

        lastDbHistory.addAll(request.getDataAsList());
        var dbIdsStr = dbIds.stream().map(Object::toString).collect(Collectors.joining(","));
        LOG.info(String.format("Registration history verified for rows [%s]", dbIdsStr));
    }


    @Given("I call GET registration_history as follows:")
    public void iCallGetHistoryWithMultipleParams(DataTable paramTable) {

        lastDbHistory.clear();
        var parms = new HashMap<String, Object>(paramTable.asMap());
        utility.replaceParmValues(parms);
        var parmStrings = new HashMap<String, Object>() {{
            parms.forEach((k, v) -> this.put(k, v.toString()));
        }};
        var expectedStatus = context.popExpectedStatus(200);
        request = RequestContainer.build().getEntities(REGISTRATION_HISTORY).addQueryParms(parmStrings);
        var result = request.call(expectedStatus).getResponseEntity(GetRegistrationHistoryResult.class);
        if (expectedStatus.getCode() == 200) {
            if ("registration".equals(parmStrings.get("id_type"))) {
                context.lastRegistrationId = parmStrings.get("id").toString();
                LOG.info("{} {} returned", numDbHistoryRows, REGISTRATION_HISTORY.name());
            }
            lastDbHistory.addAll(request.getDataAsList());
            int expectedPageNum = Integer.parseInt(parms.getOrDefault("page", "1").toString());
            int expectedPerPage = Integer.parseInt(parms.getOrDefault("per_page", "100").toString());
            assertEquals(expectedPerPage, result.meta().per_page, "Meta 'per_page' is incorrect!");
            assertEquals(expectedPageNum, result.meta().page, "Meta 'page' is incorrect!");
            int metaTotal = result.meta().total;
            if (parms.containsKey("page")) { // we actually only want a single page
                numDbHistoryRows = lastDbHistory.size();
                LOG.info("{} {} returned", numDbHistoryRows, REGISTRATION_HISTORY.name());
                return;
            }
            while (result.meta().next != null) {
                // Page forward
                expectedPageNum++;
                var pageRequest = RequestContainer.build().getWithMetadataUrl(REGISTRATION_HISTORY, result.meta().next);
                result = pageRequest.call(expectedStatus).getResponseEntity(GetRegistrationHistoryResult.class);
                assertEquals(expectedPerPage, result.meta().per_page, "Meta 'per_page' is incorrect!");
                assertEquals(expectedPageNum, result.meta().page, "Meta 'page' is incorrect!");
                assertEquals(metaTotal, result.meta().total, "Meta 'total' is incorrect!");
                lastDbHistory.addAll(pageRequest.getDataAsList());
            }
            if (result.meta().page > 1) {
                // Page backward
                var dbBackward = new ArrayList<>(result.data());
                while (result.meta().prev != null) {
                    expectedPageNum--;
                    var pageRequest = RequestContainer.build().getWithMetadataUrl(REGISTRATION_HISTORY, result.meta().prev);
                    result = pageRequest.call(expectedStatus).getResponseEntity(GetRegistrationHistoryResult.class);
                    assertEquals(expectedPerPage, result.meta().per_page, "Meta 'per_page' is incorrect!");
                    assertEquals(expectedPageNum, result.meta().page, "Meta 'page' is incorrect!");
                    assertEquals(metaTotal, result.meta().total, "Meta 'total' is incorrect!");
                    dbBackward.addAll(result.data());
                }
                var dbIdsForward = lastDbHistory.stream().map(h -> Long.parseLong(h.get("id").toString())).collect(Collectors.toCollection(TreeSet::new));
                var dbIdsBackward = dbBackward.stream().map(h -> h.id).collect(Collectors.toCollection(TreeSet::new));
                assertEquals(metaTotal, dbIdsForward.size(), "Total row ids returned from paging forward does not meta.total");
                assertEquals(dbIdsForward, dbIdsBackward, "Set of row ids returned from paging backward does not match paging forward");
            }
            numDbHistoryRows = lastDbHistory.size();
            assertEquals(numDbHistoryRows, metaTotal, "meta.total does not match number of rows returned");
            LOG.info("{} REGISTRATION_HISTORY rows returned", numDbHistoryRows);
        } else {
            numDbHistoryRows = 0;
        }
    }


    @When("I manually update the registration history rows effective_start_dttm_utc with the following values:")
    public void iManuallyUpdateRowHistoryForMostRecent(DataTable paramTable) throws Throwable {

        var startDttms = new LinkedList<>(paramTable.asList());
        var endDttms = new LinkedList<>(paramTable.asList()) {{
            this.removeFirst();
            this.add(EFFECTIVE_END_INFINITY);
        }};

        var contextHistory = context.getContextRegistrationHistory(context.lastRegistrationId);
        for (var entry : contextHistory.entrySet()) {
            var id = entry.getKey();
            var row = entry.getValue();
            row.effective_start_dttm_utc = startDttms.removeFirst();
            row.effective_end_dttm_utc = endDttms.removeFirst();
            String query = "update settlement_metadata.\"REGISTRATION_HISTORY\" "
                    + String.format("set effective_start_dttm_utc=(TIMESTAMP WITH TIME ZONE '%s'), ", row.effective_start_dttm_utc)
                    + String.format("effective_end_dttm_utc=(TIMESTAMP WITH TIME ZONE '%s') ", row.effective_end_dttm_utc)
                    + String.format("where id = %d", id);
            int count = client.runUpdateQuery(query);
            assertTrue(count > 0, "No rows updated!");
            LOG.info(String.format("Number of rows updated: %d", count));
        }

    }


    @Then("the registration history response should contain {int} row(s)")
    public void verifyNumRowsReturned(int numExpected) {
        assertEquals(numExpected, numDbHistoryRows, "Unexpected number of rows were returned!!");
        LOG.info("Response verified");
    }

    @Then("the registration history response should contain at least {int} row(s)")
    public void verifyNumRowsAtLeast(int minExpected) {
        assertTrue(numDbHistoryRows >= minExpected,
                String.format("Expected at least %d rows but got %d", minExpected, numDbHistoryRows));
        LOG.info("Response verified: {} rows (>= {})", numDbHistoryRows, minExpected);
    }

    @And("these rows should be returned for each registration:")
    public void verifyRowIdsReturnedPerReg(DataTable dataTable) {
        assertFalse(lastDbHistory.isEmpty(), "No history returned!!");
        dataTable.asMap(String.class, String.class).forEach((k, v) -> {
            String regId = RegistrationConfig.getRegistrationId(k);
            var contextHistory = context.getContextRegistrationHistory(regId);
            var correctIds = Arrays.stream(v.split(","))
                    .map(str -> contextHistory.keySet().toArray()[Integer.parseInt(str) - 1])
                    .toList();
            var dbIds = lastDbHistory.stream().filter(r -> regId.equals(r.get("registration_id"))).map(r -> Long.parseLong(r.get("id").toString())).toList();
            assertEquals(correctIds, dbIds, "Invalid set of history rows returned!");
            var dbIdsStr = dbIds.stream().map(Object::toString).collect(Collectors.joining(","));
            LOG.info(String.format("Registration history for %s verified for rows [%s]", regId, dbIdsStr));
        });
    }


    @Then("the correct set of registration history rows should be returned: {string}")
    public void verifyCorrectRegHistoryRowsReturned(String correctRowsStr) {
        verifyHistoryInternal(context.lastRegistrationId, correctRowsStr);
    }


    @Then("the correct set of registration history rows should be returned for each registration:")
    public void verifyCorrectRegHistoryRowsReturnedPerReg(DataTable dataTable) {
        dataTable.asMap(String.class, String.class).forEach((k, v) -> verifyHistoryInternal(RegistrationConfig.getRegistrationId(k), v));
    }


    private void verifyHistoryInternal(String regId, String correctRowsStr) {

        var contextHistory = context.getContextRegistrationHistory(regId);
        var correctIds = Arrays.stream(correctRowsStr.split(","))
                .map(str -> contextHistory.keySet().toArray()[Integer.parseInt(str) - 1])
                .toList();

        assertFalse(lastDbHistory.isEmpty(), "No history returned!!");
        var queryParms = request.getQueryParms();
        assertFalse(queryParms.isEmpty(), "No query params specified!");

        var startDttm = ZonedDateTime.parse(queryParms.getOrDefault("start_dttm_utc", "1970-01-01T00:00:00Z").toString());
        var endDttm = ZonedDateTime.parse(queryParms.getOrDefault("end_dttm_utc", "9000-01-01T00:00:00Z").toString());
        var expectedRows = new ArrayList<>(contextHistory.values());

        if (!"true".equals(queryParms.getOrDefault("include_deleted", "false").toString())) {
            // Remove expected rows that are deleted
            expectedRows.removeIf(r -> Objects.equals(true, r.deleted));
        }

        if (queryParms.containsKey("statuses")) {
            // Remove expected rows that don't have a matching status
            var statuses = Arrays.asList(queryParms.get("statuses").toString().split(","));
            expectedRows.removeIf(r -> r.status == null || !statuses.contains(r.status));
        }

        // Remove expected rows outside the requested date range
        expectedRows.removeIf(r -> {
            var effectiveStart = ZonedDateTime.parse(r.effective_start_dttm_utc);
            var effectiveEnd = ZonedDateTime.parse(r.effective_end_dttm_utc);
            if (startDttm.isEqual(endDttm)) {  // special case
                return !(startDttm.isEqual(effectiveStart) || (startDttm.isAfter(effectiveStart) && startDttm.isBefore(effectiveEnd)));
            } else {
                boolean startIsIncluded = startDttm.isBefore(effectiveEnd);
                boolean endIsIncluded = endDttm.isAfter(effectiveStart);
                return !(startIsIncluded && endIsIncluded);
            }
        });

        var expectedIds = expectedRows.stream().map(r -> r.id).toList();
        assertEquals(correctIds, expectedIds, "Something's wrong! My code did not calculate the correct set of rows!");
        var dbIds = lastDbHistory.stream().filter(r -> regId.equals(r.get("registration_id"))).map(r -> Long.parseLong(r.get("id").toString())).toList();
        assertEquals(expectedIds, dbIds, "Invalid set of history rows returned!");

        var dbIdsStr = dbIds.stream().map(Object::toString).collect(Collectors.joining(","));
        LOG.info(String.format("Registration history for %s verified for rows [%s]", regId, dbIdsStr));
    }

    @Then("the most recent registration history row should have has_override {word}")
    public void mostRecentHistoryHasOverride(String expectedStr) {
        boolean expected = Boolean.parseBoolean(expectedStr);
        assertFalse(lastDbHistory.isEmpty(), "No history returned!!");
        var dbHistory = lastDbHistory.stream()
                .map(m -> JSON.convertValue(m, RegistrationHistory.class))
                .toList();
        assertHasOverrideForMostRecentRow(dbHistory, expected);
    }


}
