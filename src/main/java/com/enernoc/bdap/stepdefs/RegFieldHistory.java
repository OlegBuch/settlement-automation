package com.enernoc.bdap.stepdefs;

import com.enernoc.bdap.model.*;
import com.enernoc.bdap.shared.*;
import com.enernoc.bdap.model.APIResponses.*;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.cucumber.datatable.DataTable;
import io.cucumber.java.en.Given;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.time.ZonedDateTime;
import java.util.*;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.stream.Collectors;

import static com.enernoc.bdap.model.EntityType.REGISTRATION_FIELD_HISTORY;
import static com.enernoc.bdap.model.RegistrationAdjective.*;
import static com.enernoc.bdap.shared.Context.metadataSecretValues;
import static org.junit.jupiter.api.Assertions.*;

public class RegFieldHistory {

    private static final Logger LOG = LoggerFactory.getLogger("RegFieldHistory");
    private static final ObjectMapper JSON = new ObjectMapper();
    private final Context context = Context.getContext();

    private RequestContainer request;
    private final Utility utility = new Utility();
    private final PostgresClient client = new PostgresClient(metadataSecretValues);
    private final List<RegistrationFieldHistory> previousHistory = new ArrayList<>();
    private final HashMap<String, Object> manualUpdates = new HashMap<>();
    private long firstHistoryId = 0;


    @Given("I retrieve and save the complete registration field history for {word}")
    public void iRetrieveRegistrationHistory(String regName) {
        fail("Re-implement using database query");
        context.lastRegistrationId = RegistrationConfig.getRegistrationId(regName);
//        var request = RequestContainer.build()
//                .getEntities(REGISTRATION_FIELD_HISTORY)
//                .addQueryParm("id", context.lastRegistrationId)
//                .addQueryParm("id_type", "registration")
//                .addQueryParm("include_deleted", "true");
//        var currentHistory = new ArrayList<>(request.call(context.popExpectedStatus(200)).getResponseEntity(APIResponses.GetRegistrationFieldHistoryResult.class).data());
//        assertFalse(currentHistory.isEmpty(), "Something's wrong! No history returned");
//        previousHistory.clear();
//        previousHistory.addAll(currentHistory);
    }


//    @When("I manually update the most recent registration field history rows effective_start_dttm_utc with the following values:")
//    public void iManuallyUpdateHistoryForMostRecent(DataTable paramTable) throws Throwable {
//        var params = new HashMap<>(paramTable.asMap(String.class, Object.class));
//        assertTrue(params.containsKey("effective_start_dttm_utc"), "effective_start_dttm_utc is required!");
//        assertTrue(params.containsKey("override_reason"), "override_reason is required!");
//        assertFalse(context.lastLastUpdatedBy.isBlank(), "lastLastUpdatedBy is not set!");
//        String dttm = params.get("effective_start_dttm_utc").toString();
//        String reason =  params.get("override_reason").toString();
//
//        { // Update effective_start_dttm_utc on the most recent rows (tagged by most recent last_updated_by value)
//            String query = "update settlement_metadata.\"REGISTRATION_FIELD_HISTORY\" "
//                    + "set effective_start_dttm_orig_utc=effective_start_dttm_utc, "
//                    + String.format("effective_start_dttm_utc=(TIMESTAMP WITH TIME ZONE '%s'), ", dttm)
//                    + String.format("override_reason='%s' ", reason)
//                    + String.format("where registration_id = '%s' and last_updated_by = '%s'", context.lastRegistrationId, context.lastLastUpdatedBy);
//            int count = client.runUpdateQuery(query);
//            assertTrue(count > 0, "No rows updated!");
//            LOG.info(String.format("Number of rows updated: %d", count));
//
//            // Update saved history
//            previousHistory.stream()
//                    .filter(h -> h.last_updated_by.equals(context.lastLastUpdatedBy))
//                    .forEach(h -> {
//                        h.effective_start_dttm_utc = dttm;
//                        h.override_reason = reason;
//                    });
//        }
//
//        // Update effective_end_dttm_utc for the previous row of each updated field
//        String endDttm = ZonedDateTime.parse(dttm).toString();
//        if (!endDttm.contains(".")) {
//            endDttm = endDttm.replace("00Z", "00:00.000Z");
//        }
//        for (String name : context.lastUpdatedFields) {
//            // Find the most recent row for the field whose effective_end_dttm_utc is the default value
//            var prevOpt = previousHistory.stream()
//                    .filter(h -> h.field_name.equals(name) && !h.effective_end_dttm_utc.equals("9999-02-01T00:00:00.000Z"))
//                    .max(Comparator.comparingLong(h -> h.registration_history_id));
//            assertTrue(prevOpt.isPresent(), "No previous row found!");
//
//            // Update the effective_end_dttm_utc on that row
//            String query = String.format("update settlement_metadata.\"REGISTRATION_FIELD_HISTORY\" set effective_end_dttm_utc = (TIMESTAMP WITH TIME ZONE '%s') ", endDttm)
//                    + String.format("where id = %d;", prevOpt.get().registration_history_id);
//            int count = client.runUpdateQuery(query);
//            assertEquals(1, count, String.format("Unexpected number of rows updated: %d", count));
//            prevOpt.get().effective_end_dttm_utc = endDttm;  // Update saved history
//            LOG.info(String.format("Number of rows updated: %d", count));
//        }
//
//    }


    @Then("the registration field history should not be updated")
    public void registrationHistoryShouldNotBeUpdated() {
        var request = RequestContainer.build()
                .getEntities(REGISTRATION_FIELD_HISTORY)
                .addQueryParm("id", context.lastRegistrationId)
                .addQueryParm("id_type", "registration")
                .addQueryParm("include_deleted", "true");
        var currentHistory = new ArrayList<>(request.call(context.popExpectedStatus(200)).getResponseEntity(APIResponses.GetRegistrationFieldHistoryResult.class).data());
        assertFalse(currentHistory.isEmpty(), "Something's wrong! No history returned");
        var currentHistoryMap = new HashMap<Long, RegistrationFieldHistory>(currentHistory.stream().collect(Collectors.toMap(h -> h.registration_history_id, h -> h)));
        var previousHistoryMap = new HashMap<Long, RegistrationFieldHistory>(previousHistory.stream().collect(Collectors.toMap(h -> h.registration_history_id, h -> h)));
        assertEquals(previousHistoryMap.size(), currentHistoryMap.size(), "History has unexpected new rows!");
        assertEquals(previousHistoryMap.keySet(), currentHistoryMap.keySet(), "History has unexpected differences!");
        previousHistoryMap.keySet().forEach(id -> {
            var currentRow = currentHistoryMap.get(id);
            var prevRow = previousHistoryMap.get(id);
            assertNotEquals(currentRow, prevRow); // sanity check
            HashMap<String, String> previousAsMap = JSON.convertValue(currentRow, new TypeReference<>() {});
            HashMap<String, String> currentAsMap = JSON.convertValue(prevRow, new TypeReference<>() {});
            assertEquals(previousAsMap, currentAsMap, String.format("Response contains row %d which has been unexpectedly updated!", id));
        });
    }


    // Alternate syntax
    @Then("the manual updates should be reflected in the registration field history")
    public void manulaUpdatesShouldBeReflected() {
        registrationHistoryShouldNotBeUpdated();
    }


    @Then("the registration field history should reflect the {registrationAdjective} operation")
    public void getRegistrationHistoryShouldBeCorrect(RegistrationAdjective adjective) {

        var expected = new HashMap<String, Object>();
        String expectedRegId = context.lastRegistrationId;
        switch (adjective) {
            case NEW, RECREATE -> {
                assertTrue(context.savedRegistrationOpt.isPresent(), "Something's wrong! No saved registration");
                var registration = context.savedRegistrationOpt.get();
                expected.putAll(JSON.convertValue(registration, new TypeReference<>(){}));
                if (adjective == NEW) {
                    expected.put("service_delivery_point_id", null); // SDP is not supported for MVP
                    if (!expected.containsKey("ecrm_site_id")) {
                        expected.put("ecrm_site_id", null);
                    }
                    if (!expected.containsKey("ecrm_account_id")) {
                        expected.put("ecrm_account_id", null);
                    }
                }
                if (adjective == RECREATE) {
                    expected.put("deleted", "false");
                }
                Arrays.asList("registration_id", "last_updated_dttm_utc", "last_updated_by").forEach(expected::remove); // these are not saved to history
            }
            case UPDATE -> {
                expected.putAll(request.getBodyProps());
                Arrays.asList("last_updated_dttm_utc", "last_updated_by").forEach(expected::remove); // these are not saved to history
            }
            case MANUAL_UPDATE, HISTORY_MANUAL_UPDATE -> expected.putAll(manualUpdates);
            case DELETE -> expected.put("deleted", "true");
            default -> fail("Invalid adjective!");
        }
        int numExpectedUpdates = expected.size();
        AtomicInteger numUpdatesVerified = new AtomicInteger();
        assertTrue(numExpectedUpdates > 0, "Something's wrong! No expected updates");

        List<String> errors = new ArrayList<>();

        // Get current history returned from last call
        var request = RequestContainer.build()
                .getEntities(REGISTRATION_FIELD_HISTORY)
                .addQueryParm("id", context.lastRegistrationId)
                .addQueryParm("id_type", "registration");
        if (adjective == DELETE) {
            request.addQueryParm("include_deleted", "true");
        }
        var currentHistory = new ArrayList<>(request.call(context.popExpectedStatus(200)).getResponseEntity(APIResponses.GetRegistrationFieldHistoryResult.class).data());
        assertFalse(currentHistory.isEmpty(), "Something's wrong! No history returned");
        var currentIds = currentHistory.stream().map(h -> h.registration_history_id).toList();
        assertEquals(currentIds.size(), new HashSet<>(currentIds).size(), "Response contains duplicate history rows!");

        // Validate the updates that were made for the last POST/PUT call

        var previousIds = previousHistory.stream().map(h -> h.registration_history_id).toList(); // will be empty set (no previous history) for new registration
        List<RegistrationFieldHistory> mostRecentUpdates = new ArrayList<>();

        switch (adjective) {

            case NEW, UPDATE, MANUAL_UPDATE, DELETE, RECREATE -> {

                if (adjective == NEW) {
                    mostRecentUpdates.addAll(currentHistory);  // Validate entire history
                } else { // Only validate latest updates
                    mostRecentUpdates = currentHistory.stream()
                            .filter(h -> !previousIds.contains(h.registration_history_id))
                            .toList();
                    assertFalse(mostRecentUpdates.isEmpty());  // sanity check
                }

                mostRecentUpdates.forEach(actual -> {

                    // Vaildate registration_id
                    if (!actual.registration_id.equals(expectedRegId)) {
                        errors.add(String.format("Mismatched values for registration_id. Expected: '%s'  Actual: '%s'", expectedRegId, actual.registration_id));
                    }

                    // Validate effective_start_dttm_utc
                    if (actual.effective_start_dttm_utc == null) {
                        errors.add("effective_start_dttm_utc is null!");
                    } else {
                        ZonedDateTime startDttm = ZonedDateTime.parse(actual.effective_start_dttm_utc);
                        if (startDttm.toEpochSecond() < Context.testStartEpoch) {
                            errors.add(String.format("effective_start_dttm_utc '%s' is BEFORE the test initialization time '%s'!", startDttm, Utility.epochToString(Context.testStartEpoch)));
                        } else if ((startDttm.toEpochSecond() - Context.testStartEpoch) > 600) {  // we are assuming that no feature-file will take longer than 10 minutes to run
                            errors.add(String.format("effective_start_dttm_utc '%s' is greater than 10 minutes after the test initialization time '%s'!", startDttm, Utility.epochToString(Context.testStartEpoch)));
                        }
                    }

                    // Validate effective_end_dttm_utc
                    if (actual.effective_end_dttm_utc == null) {
                        errors.add("effective_end_dttm_utc is null!");
                    } else {
                        // For new history rows, this should default to a date far in the future.
                        ZonedDateTime endDttm = ZonedDateTime.parse(actual.effective_end_dttm_utc);
                        if (endDttm.isBefore(Context.EFFECTIVE_END_DTTM)) {
                            errors.add(String.format("effective_end_dttm_utc '%s' did not default to a far-future date!", endDttm));
                        }
                    }

                    // Validate last_updated_dttm_utc
                    if (actual.last_updated_dttm_utc == null) {
                        errors.add("last_updated_dttm_utc is null!");
                    } else {
                        ZonedDateTime updatedDttm = ZonedDateTime.parse(actual.last_updated_dttm_utc);
                        if (Math.abs(updatedDttm.toEpochSecond() - Context.testStartEpoch) > 600) { // we are assuming that no feature-file will take longer than 10 minutes to run
                            errors.add(String.format("last_updated_dttm_utc '%s' is more than 10 minutes different from the test initialization time '%s'!", updatedDttm, Utility.epochToString(Context.testStartEpoch)));
                        }
                    }

                    // Validate last_updated_by
                    if (actual.last_updated_by == null  || actual.last_updated_by.isBlank()) {
                        errors.add("last_updated_by is null!");
                    }

                    // Validate field that was updated
                    if (!expected.containsKey(actual.field_name)) {
                        errors.add(String.format("Extra field %s returned in history!", actual.field_name));
                    } else {
                        Object expval = expected.remove(actual.field_name);
                        if (expval instanceof Boolean) {
                            // TODO: remove if and when registration_history returns booleans as boolean values rather than strings
                            expval = expval.toString();
                        }
                        if (!Objects.equals(actual.field_value, expval)) {
                            errors.add(String.format("Mismatched values for %s. Expected: '%s'  Actual: '%s'", actual.field_name, expval, actual.field_value));
                        }
                        numUpdatesVerified.getAndIncrement();
                    }
                });

                // If we didn't find fields in the latest updates, verify that their values haven't changed from the most recent updates
                new HashMap<>(expected).forEach((name, expval) -> {
                    // Find the RegistrationFieldHistory entity with the expected field name which has the highest registration_history_id, if any
                    var prevOpt = previousHistory.stream()
                            .filter(h -> h.field_name.equals(name))
                            .max(Comparator.comparingLong(h -> h.registration_history_id));
                    if (prevOpt.isPresent()) {
                        var prev = prevOpt.get();
                        if (expval instanceof Boolean) {
                            // TODO: remove if and when registration_history returns booleans as boolean values rather than strings
                            expval = expval.toString();
                        }
                        if (Objects.equals(prev.field_value, expval)) {
                            expected.remove(name);
                            numUpdatesVerified.getAndIncrement();
                        }
                    }
                });

                expected.keySet().forEach(expval -> errors.add(String.format("Field %s not returned in history!", expval)));

            }

            case HISTORY_MANUAL_UPDATE -> {

                // Validate that both the current history and previous history contain the same set of row ids.
                assertEquals(currentIds.size(), previousIds.size(), "The set of rows returned by the current history and the previous history are different!");
                assertEquals(new TreeSet<>(currentIds), new TreeSet<>(previousIds), "The set of rows returned by the current history and the previous history are different!");

                // Only validate the specific history row that was updated.
                // First, get the current version of the row.
                Optional<RegistrationFieldHistory> currentRowOpt = currentHistory.stream().filter(h -> h.registration_history_id == firstHistoryId).findFirst();
                assertTrue(currentRowOpt.isPresent(), "Something's wrong, should never get here!");
                HashMap<String, Object> currentRowMap = JSON.convertValue(currentRowOpt.get(), new TypeReference<>() {});

                // Next, get the previous version of the row
                Optional<RegistrationFieldHistory> previousRowOpt = previousHistory.stream().filter(h -> h.registration_history_id == firstHistoryId).findFirst();
                assertTrue(previousRowOpt.isPresent(), "Something's wrong, should never get here!");
                HashMap<String, Object> previousRowMap = JSON.convertValue(previousRowOpt.get(), new TypeReference<>() {});

                // Now, apply the manual updates to the previous row
                previousRowMap.putAll(manualUpdates);

                if (!currentRowMap.equals(previousRowMap)) {
                    errors.add("Mismatched values for manual history update! Examine log to see difference.");
                }
                numUpdatesVerified.getAndAdd(manualUpdates.size());
            }

            default -> fail("Unsupported adjective: " + adjective);
        }
        if (numExpectedUpdates != numUpdatesVerified.get()) {
            errors.add(String.format("Something's wrong! Different number of updates verified %d than expected %d", numUpdatesVerified.get(), numExpectedUpdates));
        }

        // Validate changes to earlier history rows, if any.
        if (List.of(UPDATE, MANUAL_UPDATE, DELETE, RECREATE).contains(adjective)) {

            // First, validate that all previous history rows were also returned in current history
            previousIds.stream()
                    .filter(id -> !currentIds.contains(id))
                    .forEach(id -> errors.add(String.format("Row id %d was not returned in response!", id)));

            // Now validate previous rows that shouid have been updated in current history
            var currentHistoryMap = new HashMap<Long, RegistrationFieldHistory>(currentHistory.stream().collect(Collectors.toMap(h -> h.registration_history_id, h -> h)));
            var previousHistoryMap = new HashMap<Long, RegistrationFieldHistory>(previousHistory.stream().collect(Collectors.toMap(h -> h.registration_history_id, h -> h)));
            mostRecentUpdates.forEach(actual -> {
                previousHistory.stream()
                        .filter(h -> h.field_name.equals(actual.field_name))
                        .map(h -> h.registration_history_id)
                        .max(Comparator.comparingLong(id -> id)).ifPresent(priorId -> {
                            // If we get here, there is at least one prior history row for the field.
                            // First, validate that the effective_end_dttm_utc of the prior update was updated to the effective_start_dttm_utc of the latest update
                            var priorUpdate = currentHistoryMap.get(priorId);
                            if (!priorUpdate.effective_end_dttm_utc.equals(actual.effective_start_dttm_utc)) {
                                errors.add(String.format("History id %d has incorrect effective_end_dttm_utc. Expected: %s  Actual: %s", priorId, actual.effective_start_dttm_utc, priorUpdate.effective_end_dttm_utc));
                            }
                            // Second, validate that the prior update was not otherwise updated
                            {
                                HashMap<String, String> priorAsMap = JSON.convertValue(priorUpdate, new TypeReference<>() {});
                                priorAsMap.remove("effective_end_dttm_utc"); // we just validated this
                                HashMap<String, String> previousAsMap = JSON.convertValue(previousHistoryMap.get(priorId), new TypeReference<>() {});
                                previousAsMap.remove("effective_end_dttm_utc");
                                if (!priorAsMap.equals(previousAsMap)) {
                                    errors.add(String.format("Response contains row %d which has been unexpectedly updated!", priorUpdate.registration_history_id));
                                }
                            }
                            // Third, validate that earlier rows for the field were NOT updated in any way
                            {
                                List<RegistrationFieldHistory> allPreviousRowsForField = new ArrayList<>(previousHistory.stream()
                                        .filter(h -> h.field_name.equals(actual.field_name))
                                        .filter(h -> !h.registration_history_id.equals(priorId))  // we already validated the prior update
                                        .toList());
                                allPreviousRowsForField.forEach(h -> {
                                    if (!currentHistoryMap.containsKey(h.registration_history_id)) {
                                        errors.add(String.format("Response does not contain the expected row with id %d!", h.registration_history_id));
                                    } else {
                                        var currentRow = currentHistoryMap.get(h.registration_history_id);
                                        assertNotEquals(currentRow, h); // sanity check
                                        HashMap<String, String> currentAsMap = JSON.convertValue(currentRow, new TypeReference<>() {});
                                        HashMap<String, String> previousAsMap = JSON.convertValue(h, new TypeReference<>() {});
                                        if (!previousAsMap.equals(currentAsMap)) {
                                            errors.add(String.format("Response contains row %d which has been unexpectedly updated!", h.registration_history_id));
                                        }
                                    }
                                });
                            }
                        });
            });

        }

        assertTrue(errors.isEmpty(), "\n" + String.join("\n", errors));

        // Save the current history as the prevous history for later use
        previousHistory.clear();
        previousHistory.addAll(currentHistory);

        LOG.info("Registration history verified");
    }


    @Given("I call GET registration_field_history as follows:")
    public void iCallGetHistoryWithMultipleParams(DataTable paramTable) {

        var parms = new HashMap<String, Object>(paramTable.asMap());
        utility.replaceParmValues(parms);
        var parmStrings = new HashMap<String, Object>() {{
            parms.forEach((k, v) -> this.put(k, v.toString()));
        }};
        var expectedStatus = context.popExpectedStatus(200);
        request = RequestContainer.build().getEntities(REGISTRATION_FIELD_HISTORY).addQueryParms(parmStrings);
        request.call(expectedStatus).getResponseEntity(GetRegistrationHistoryResult.class);
        if (expectedStatus.getCode() == 200) {
            LOG.info("{} {} returned", request.getDataAsList().size(), REGISTRATION_FIELD_HISTORY.name());
        }
    }


    @Then("the correct set of registration field history rows should be returned")
    public void verifyCorrectRowsReturned() {

        assertFalse(previousHistory.isEmpty(), "You need the stepdef 'I retrieve and save the complete registration field history'");
        var data = (List<HashMap<String, Object>>) request.getDataAsList();
        assertFalse(data.isEmpty(), "No history returned!!");
        var queryParms = request.getQueryParms();
        assertFalse(queryParms.isEmpty(), "No query params specified!");

        var startDttm = ZonedDateTime.parse(queryParms.getOrDefault("start_dttm_utc", "1970-01-01T00:00:00Z").toString());
        var endDttm = ZonedDateTime.parse(queryParms.getOrDefault("end_dttm_utc", "9000-01-01T00:00:00Z").toString());

        var expectedRows = new ArrayList<>(previousHistory);
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

        var expectedIds = expectedRows.stream().map(r -> r.registration_history_id).toList();
        var actualIds = data.stream().map(r -> Long.parseLong(r.get("registration_history_id").toString())).toList();
        assertEquals(expectedIds, actualIds, "Invalid set of history rows returned!");

        // Sanity check: data should contain at least one row for every registration field enabled for history tracking, and no untracked fields
        var actualFields = new TreeSet<>(data.stream().map(r -> r.get("field_name").toString()).toList());
        assertEquals(Registration.fieldsTrackedInHistory, actualFields, "Not all tracked fields returned, or untracked fields returned!");

        LOG.info(String.format("%d history rows verified", expectedIds.size()));

        var summary = new TreeMap<String, List<String>> ();
        data.forEach(r -> summary.computeIfAbsent(r.get("override_reason").toString(), k -> new ArrayList<>()).add(r.get("field_name").toString()));
        summary.forEach((k, v) -> LOG.info(String.format("Row set returned: '%s' for fields '%s'", k, String.join(",",v))));
    }


    @Then("the registration field history response should contain {int} row(s)")
    public void verifyNumRowsReturned(int numExpected) {
        assertEquals(numExpected, request.getDataAsList().size(), "Unexpected number of rows were returned!!");
        LOG.info("Response verified");
    }


}
