package com.enernoc.bdap.stepdefs;

import com.enernoc.bdap.model.EntityType;
import com.enernoc.bdap.model.HttpOp;
import com.enernoc.bdap.model.HttpStatus;
import com.enernoc.bdap.model.RequestContainer;
import com.enernoc.bdap.shared.Context;
import com.enernoc.bdap.shared.Utility;
import io.cucumber.datatable.DataTable;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;
import java.math.BigDecimal;

import java.time.ZonedDateTime;
import java.util.*;
import java.util.stream.Collectors;

import static org.junit.jupiter.api.Assertions.*;

public class SettlementItemTimebound {

    private final Context context = Context.getContext();
    private final Utility utility = new Utility();

    private RequestContainer request;
    private final Map<String, HashMap<String, Object>> expectedRowsById = new HashMap<>();
    private final TreeMap<Long, HashMap<String, Object>> returnedRows = new TreeMap<>();
    private HashMap<String, Object> lastRetrievedById;

    private String lastTimeboundId = "";
    private String lastListSettlementItemId = "";
    private Optional<ZonedDateTime> lastListStartOpt = Optional.empty();
    private Optional<ZonedDateTime> lastListEndOpt = Optional.empty();
    private HashMap<String, Object> lastListMeta = new HashMap<>();
    private ArrayList<HashMap<String, Object>> lastAuditRows = new ArrayList<>();
    private List<HashMap<String, Object>> lastPostReturned = new ArrayList<>();
    private final Map<String, String> lastChangeCommentById = new HashMap<>();
    private final List<String> createdIds = new ArrayList<>();
    private static final List<String> AUDIT_OP_FIELDS =
            List.of("operation", "operation_type", "action", "audit_action", "change_type");

    private Map<String, String> lastResponseHeaders = new HashMap<>();
    private byte[] lastRawBody = new byte[0];

    private void captureResponseDetails() {
        lastResponseHeaders = new HashMap<>();
        request.response.getHeaders().forEach(h -> lastResponseHeaders.put(h.getName().toLowerCase(), h.getValue()));
        lastRawBody = request.response.asByteArray();
    }


    private HashMap<String, Object> fetchRow(String id, Boolean includeDeleted) {
        RequestContainer r = RequestContainer.build().getEntity(EntityType.SETTLEMENT_ITEM_TIMEBOUND, id);
        if (includeDeleted != null) {
            r.addQueryParm("include_deleted", includeDeleted);   // use String.valueOf(...) if your method takes a String
        }
        r.call(HttpStatus.build().withCode(200));
        return r.getDataAsList().get(0);
    }

    private boolean valuesEqual(String expected, Object actual) {
        String a = Objects.toString(actual, null);
        try {
            return new BigDecimal(expected).compareTo(new BigDecimal(a)) == 0;
        } catch (NumberFormatException | NullPointerException e) {
            return expected.equals(a);
        }
    }

    private String resolveIfToken(String raw) {
        return raw.matches("^<[^<>]+>$") ? resolveToken(raw) : raw;
    }


    // ---------------- helpers ----------------

    private boolean rowOverlapsLastWindow(HashMap<String, Object> row) {
        ZonedDateTime rowStart = ZonedDateTime.parse(Objects.toString(row.get("start_dttm_utc")));
        ZonedDateTime rowEnd = ZonedDateTime.parse(Objects.toString(row.get("end_dttm_utc")));

        if (lastListStartOpt.isPresent() && !rowEnd.isAfter(lastListStartOpt.get())) {
            return false;
        }
        if (lastListEndOpt.isPresent() && !rowStart.isBefore(lastListEndOpt.get())) {
            return false;
        }
        return true;
    }

    private void captureCurrentPageRows() {
        ArrayList<HashMap<String, Object>> rows = new ArrayList<>(request.getDataAsList());
        for (HashMap<String, Object> row : rows) {
            ZonedDateTime start = ZonedDateTime.parse(Objects.toString(row.get("start_dttm_utc")));
            long key = start.toEpochSecond();
            while (returnedRows.containsKey(key)) {
                key++;
            }
            returnedRows.put(key, row);
        }
        readMeta();
    }

    @SuppressWarnings("unchecked")
    private void readMeta() {
        Object metaObj = request.responseMap.get("meta");
        if (metaObj instanceof HashMap<?, ?> map) {
            lastListMeta = (HashMap<String, Object>) map;
        } else {
            lastListMeta = new HashMap<>();
        }
    }

    private String getPageLink(String key) {
        Object value = lastListMeta.get(key);
        if (value == null) {
            return null;
        }
        String s = value.toString();
        return s.isBlank() ? null : s;
    }

    private Optional<ZonedDateTime> parseOptionalUtc(String token) {
        if ("missing".equalsIgnoreCase(token)) {
            return Optional.empty();
        }
        return Optional.of(ZonedDateTime.parse(resolveToken(token)));
    }

    private String resolveTag(String tag) {
        assertTrue(context.savedValues.containsKey(tag), "Saved values does not contain '" + tag + "'");
        return context.savedValues.get(tag);
    }

    private String resolveToken(String token) {
        HashMap<String, Object> map = new HashMap<>();
        map.put("value", token);
        utility.replaceParmValues(map);
        Object resolved = map.get("value");
        assertNotNull(resolved, "Resolved token is null for token: " + token);
        return resolved.toString();
    }



    // ---------------- POST (array body) ----------------

    @When("I POST a settlement_item_timebound row with the following data:")
    public void iPostOneSettlementItemTimebound(DataTable table) {
        HashMap<String, Object> row = new HashMap<>(table.asMap(String.class, Object.class));
        iPostSettlementItemTimeboundRows(List.of(row));
    }

    @When("I POST the following settlement_item_timebound rows:")
    public void iPostMultipleSettlementItemTimeboundRows(DataTable table) {
        List<Map<String, String>> maps = table.asMaps(String.class, String.class);
        List<HashMap<String, Object>> rows = maps.stream()
                .map(m -> new HashMap<String, Object>(m))
                .collect(Collectors.toList());
        iPostSettlementItemTimeboundRows(rows);
    }

//
//    private void iPostSettlementItemTimeboundRows(List<HashMap<String, Object>> rows) {
//        rows.forEach(row -> {
//            utility.replaceParmValues(row);
//            Utility.stringToBoolean(row);
//            Utility.stringToNumber(row,
//                    "nomination_value", "payment_nomination_value",
//                    "payment_nomination_value_estimated", "payment_penalty_input_value");
//            // treat literal "null" strings as real JSON null
//            List.of("nomination_value", "nomination_uom", "payment_nomination_value", "payment_nomination_uom",
//                    "payment_nomination_value_estimated", "payment_nomination_uom_estimated",
//                    "revenue_value", "payment_value", "payment_penalty_input_value", "payment_penalty_input_uom",
//                    "payment_penalty_value", "payment_penalty_notes", "currency"
//            ).forEach(f -> {
//                Object v = row.get(f);
//                if (v != null && "null".equalsIgnoreCase(v.toString())) {
//                    row.put(f, null);
//                }
//            });
//        });
//
//        request = RequestContainer.build().submitTimebounds(HttpOp.POST, rows);
//        HttpStatus expectedStatus = context.popExpectedStatus(200);
//        request.call(expectedStatus);
//
//        if (expectedStatus.getCode() == 200) {
//            List<HashMap<String, Object>> returned = request.getDataAsList();
//            lastPostReturned = new ArrayList<>(returned);
//            assertEquals(rows.size(), returned.size(), "Unexpected number of created rows returned");
//            for (HashMap<String, Object> data : returned) {
//                String id = Objects.toString(data.get("settlement_item_timebound_id"), "");
//                assertFalse(id.isBlank(), "POST did not return settlement_item_timebound_id");
//                lastTimeboundId = id;
//                context.lastSettlementItemTimeboundId = id;
//
//                HashMap<String, Object> saved = new HashMap<>(data);
//                saved.putIfAbsent("deleted", false);
//                expectedRowsById.put(id, saved);
//            }
//        }
//    }

    private void iPostSettlementItemTimeboundRows(List<HashMap<String, Object>> rows) {
        rows.forEach(row -> {
            utility.replaceParmValues(row);
            Utility.stringToBoolean(row);
            Utility.stringToNumber(row,
                    "nomination_value", "payment_nomination_value",
                    "payment_nomination_value_estimated", "payment_penalty_input_value");
            // treat literal "null" strings as real JSON null
            List.of("nomination_value", "nomination_uom", "payment_nomination_value", "payment_nomination_uom",
                    "payment_nomination_value_estimated", "payment_nomination_uom_estimated",
                    "revenue_value", "payment_value", "payment_penalty_input_value", "payment_penalty_input_uom",
                    "payment_penalty_value", "payment_penalty_notes", "currency"
            ).forEach(f -> {
                Object v = row.get(f);
                if (v != null && "null".equalsIgnoreCase(v.toString())) {
                    row.put(f, null);
                }
            });
        });

        request = RequestContainer.build().submitTimebounds(HttpOp.POST, rows);
        HttpStatus expectedStatus = context.popExpectedStatus(200);
        request.call(expectedStatus);

        if (expectedStatus.getCode() == 200) {
            List<HashMap<String, Object>> returned = request.getDataAsList();
            assertEquals(rows.size(), returned.size(), "Unexpected number of created rows returned");
            lastPostReturned = new ArrayList<>(returned);

            for (int i = 0; i < returned.size(); i++) {
                HashMap<String, Object> data = returned.get(i);
                String id = Objects.toString(data.get("settlement_item_timebound_id"), "");
                assertFalse(id.isBlank(), "POST did not return settlement_item_timebound_id");
                lastTimeboundId = id;
                context.lastSettlementItemTimeboundId = id;
                createdIds.add(id);

                Object cc = rows.get(i).get("change_comments");
                if (cc != null) {
                    lastChangeCommentById.put(id, cc.toString());
                }

                HashMap<String, Object> saved = new HashMap<>(data);
                saved.putIfAbsent("deleted", false);
                expectedRowsById.put(id, saved);
            }
        }
    }

    // ---------------- PUT / PATCH (array body) ----------------

    private void iUpsertSettlementItemTimebound(HttpOp op, String id, DataTable table) {
        HashMap<String, Object> payload = new HashMap<>(table.asMap(String.class, Object.class));
        payload.put("settlement_item_timebound_id", id);
        utility.replaceParmValues(payload);
        Utility.stringToBoolean(payload);

        request = RequestContainer.build().submitTimebounds(op, List.of(payload));
        HttpStatus expectedStatus = context.popExpectedStatus(200);
        request.call(expectedStatus);

        if (expectedStatus.getCode() == 200 && expectedRowsById.containsKey(id)) {
            HashMap<String, Object> current = expectedRowsById.get(id);
            current.putAll(payload);
            current.remove("change_comments");
        }
        lastTimeboundId = id;
        context.lastSettlementItemTimeboundId = id;
    }

    private void iUpsertSettlementItemTimeboundMissingId(HttpOp op, DataTable table) {
        HashMap<String, Object> payload = new HashMap<>(table.asMap(String.class, Object.class));
        // Intentionally do NOT set settlement_item_timebound_id, to trigger validation error
        utility.replaceParmValues(payload);
        Utility.stringToBoolean(payload);

        request = RequestContainer.build().submitTimebounds(op, List.of(payload));
        HttpStatus expectedStatus = context.popExpectedStatus(200);
        request.call(expectedStatus);
    }


    @When("I PUT settlement_item_timebound with id tag {word} and values:")
    public void iPutSettlementItemTimeboundByTag(String tag, DataTable table) {
        iUpsertSettlementItemTimebound(HttpOp.PUT, resolveTag(tag), table);
    }

    @When("I PUT settlement_item_timebound with id {word} and values:")
    public void iPutSettlementItemTimeboundByIdToken(String idToken, DataTable table) {
        iUpsertSettlementItemTimebound(HttpOp.PUT, resolveToken(idToken), table);
    }

    @When("I PATCH settlement_item_timebound with id tag {word} and values:")
    public void iPatchSettlementItemTimeboundByTag(String tag, DataTable table) {
        iUpsertSettlementItemTimebound(HttpOp.PATCH, resolveTag(tag), table);
    }

    @When("I PATCH settlement_item_timebound with id {word} and values:")
    public void iPatchSettlementItemTimeboundByIdToken(String idToken, DataTable table) {
        iUpsertSettlementItemTimebound(HttpOp.PATCH, resolveToken(idToken), table);
    }

    @When("I PUT settlement_item_timebound with missing id and values:")
    public void iPutSettlementItemTimeboundMissingId(DataTable table) {
        iUpsertSettlementItemTimeboundMissingId(HttpOp.PUT, table);
    }

    @When("I PATCH settlement_item_timebound with missing id and values:")
    public void iPatchSettlementItemTimeboundMissingId(DataTable table) {
        iUpsertSettlementItemTimeboundMissingId(HttpOp.PATCH, table);
    }


    // ---------------- DELETE ----------------

    @When("I DELETE settlement_item_timebound with id tag {word}")
    public void iDeleteSettlementItemTimeboundWithTag(String tag) {
        iDeleteSettlementItemTimebound(resolveTag(tag));
    }

    @When("I DELETE settlement_item_timebound with id {word}")
    public void iDeleteSettlementItemTimeboundWithId(String idToken) {
        iDeleteSettlementItemTimebound(resolveToken(idToken));
    }

    private void iDeleteSettlementItemTimebound(String id) {
        request = RequestContainer.build().deleteEntity(EntityType.SETTLEMENT_ITEM_TIMEBOUND, id);
        HttpStatus expectedStatus = context.popExpectedStatus(200);
        request.call(expectedStatus);

        if (expectedStatus.getCode() == 200 && expectedRowsById.containsKey(id)) {
            expectedRowsById.get(id).put("deleted", true);
        }
        lastTimeboundId = id;
        context.lastSettlementItemTimeboundId = id;
    }

    @When("I save the last settlement_item_timebound id with the tag {word}")
    public void iSaveLastSettlementItemTimeboundId(String tag) {
        assertFalse(lastTimeboundId.isBlank(), "No settlement_item_timebound id captured yet");
        context.savedValues.put(tag, lastTimeboundId);
    }

    // ---------------- GET by id ----------------

    @When("I call GET settlement_item_timebound for id tag {word}")
    public void iCallGetSettlementItemTimeboundByTag(String tag) {
        iCallGetSettlementItemTimeboundById(resolveTag(tag));
    }

    @When("I call GET settlement_item_timebound for id {word}")
    public void iCallGetSettlementItemTimeboundByIdToken(String token) {
        iCallGetSettlementItemTimeboundById(resolveToken(token));
    }

    private void iCallGetSettlementItemTimeboundById(String id) {
        request = RequestContainer.build().getEntity(EntityType.SETTLEMENT_ITEM_TIMEBOUND, id);
        context.includeDeletedOpt.ifPresent(flag -> request.addQueryParm("include_deleted", flag));

        HttpStatus expectedStatus = context.popExpectedStatus(200);
        request.call(expectedStatus);

        if (expectedStatus.getCode() == 200) {
            lastRetrievedById = request.getDataAsList().get(0);
            lastTimeboundId = id;
            context.lastSettlementItemTimeboundId = id;
        }
    }

    // ---------------- GET list ----------------

    @When("I call GET settlement_item_timebound with settlement_item_id: {word} start_dttm_utc: {word} end_dttm_utc: {word} per_page: {int} direction: {word}")
    public void iCallGetSettlementItemTimeboundList(
            String settlementItemIdToken,
            String startToken,
            String endToken,
            int perPage,
            String direction
    ) {
        returnedRows.clear();

        String settlementItemId = resolveToken(settlementItemIdToken);
        lastListSettlementItemId = settlementItemId;

        String startRaw = "missing".equalsIgnoreCase(startToken) ? null : resolveToken(startToken);
        String endRaw = "missing".equalsIgnoreCase(endToken) ? null : resolveToken(endToken);
        lastListStartOpt = parseUtcLeniently(startRaw);
        lastListEndOpt = parseUtcLeniently(endRaw);

        HashMap<String, Object> parms = new HashMap<>();
        parms.put("settlement_item_id", settlementItemId);
        if (perPage != 0) {
            parms.put("per_page", perPage);
        }
        if (startRaw != null) {
            parms.put("start_dttm_utc", startRaw);   // send exactly what the scenario says
        }
        if (endRaw != null) {
            parms.put("end_dttm_utc", endRaw);
        }

        boolean goBackward = "backward".equalsIgnoreCase(direction);
        request = RequestContainer.build().getEntities(EntityType.SETTLEMENT_ITEM_TIMEBOUNDS).addQueryParms(parms);
        context.includeDeletedOpt.ifPresent(flag -> request.addQueryParm("include_deleted", flag));

        HttpStatus expectedStatus = context.popExpectedStatus(200);
        request.call(expectedStatus);
        if (expectedStatus.getCode() != 200) {
            return;
        }

        captureCurrentPageRows();

        while (getPageLink(goBackward ? "prev" : "next") != null) {
            String link = getPageLink(goBackward ? "prev" : "next");
            request = RequestContainer.build().getWithUrl(EntityType.SETTLEMENT_ITEM_TIMEBOUNDS, link);
            request.call(expectedStatus);
            captureCurrentPageRows();
        }
    }

    private Optional<ZonedDateTime> parseUtcLeniently(String raw) {
        if (raw == null) {
            return Optional.empty();
        }
        try {
            return Optional.of(ZonedDateTime.parse(raw));
        } catch (java.time.format.DateTimeParseException e) {
            return Optional.empty();   // invalid values are meant for negative tests; the API must answer 400
        }
    }

    @When("I call GET settlement_item_timebound with missing settlement_item_id")
    public void iCallGetSettlementItemTimeboundMissingItemId() {
        request = RequestContainer.build().getEntities(EntityType.SETTLEMENT_ITEM_TIMEBOUNDS);
        HttpStatus expectedStatus = context.popExpectedStatus(400);
        request.call(expectedStatus);
    }

    // ---------------- GET audit ----------------

    @When("I call GET settlement_item_timebound_audit for id tag {word} per_page {int} direction {word}")
    public void iCallGetSettlementItemTimeboundAudit(String tag, int perPage, String direction) {
        String id = resolveTag(tag);
        boolean backward = "backward".equalsIgnoreCase(direction);

        HashMap<String, Object> parms = new HashMap<>();
        parms.put("per_page", perPage);

        request = RequestContainer.build().getAuditLog(EntityType.SETTLEMENT_ITEM_TIMEBOUND, id).addQueryParms(parms);
        HttpStatus expectedStatus = context.popExpectedStatus(200);
        request.call(expectedStatus);

        lastAuditRows = new ArrayList<>();
        if (expectedStatus.getCode() != 200) {
            // e.g. 404 = no audit history yet for this id (a row that was only ever POSTed, never updated/deleted)
            return;
        }

        lastAuditRows.addAll(request.getDataAsList());
        readMeta();

        while (getPageLink(backward ? "prev" : "next") != null) {
            String link = getPageLink(backward ? "prev" : "next");
            request = RequestContainer.build().getAuditLogUrl(EntityType.SETTLEMENT_ITEM_TIMEBOUND, link);
            request.call(expectedStatus);
            lastAuditRows.addAll(request.getDataAsList());
            readMeta();
        }
    }

    // ---------------- THEN assertions ----------------

    @Then("GET settlement_item_timebound by id should match saved row {word}")
    public void getByIdShouldMatchSaved(String tag) {
        String id = resolveTag(tag);
        assertNotNull(lastRetrievedById, "No GET by id response captured");
        assertEquals(id, Objects.toString(lastRetrievedById.get("settlement_item_timebound_id"), null));
    }

    @Then("GET settlement_item_timebound should return only expected active rows")
    public void getListShouldReturnExpectedActiveRows() {
        List<HashMap<String, Object>> expected = expectedRowsById.values().stream()
                .filter(row -> lastListSettlementItemId.equals(Objects.toString(row.get("settlement_item_id"), "")))
                .filter(row -> !Boolean.TRUE.equals(row.get("deleted")))
                .filter(this::rowOverlapsLastWindow)
                .collect(Collectors.toList());

        Set<String> expectedIds = expected.stream()
                .map(row -> Objects.toString(row.get("settlement_item_timebound_id"), ""))
                .collect(Collectors.toSet());

        Set<String> actualIds = returnedRows.values().stream()
                .map(row -> Objects.toString(row.get("settlement_item_timebound_id"), ""))
                .collect(Collectors.toSet());

        assertEquals(expectedIds, actualIds, "Mismatch in returned timebound IDs");
    }

    @Then("the settlement_item_timebound response should be paged")
    public void responseShouldBePaged() {
        assertFalse(lastListMeta.isEmpty(), "No meta returned");
        assertTrue(lastListMeta.containsKey("page"), "meta.page missing");
        assertTrue(lastListMeta.containsKey("per_page"), "meta.per_page missing");
        assertTrue(lastListMeta.containsKey("total"), "meta.total missing");
    }

    @Then("settlement_item_timebound audit should contain at least {int} entries")
    public void auditShouldContainAtLeastEntries(int min) {
        assertTrue(lastAuditRows.size() >= min,
                "Expected at least " + min + " audit rows, got " + lastAuditRows.size());
    }

    @Then("settlement_item_timebound audit response should be paged")
    public void auditShouldBePaged() {
        assertFalse(lastListMeta.isEmpty(), "No audit meta found");
        assertTrue(lastListMeta.containsKey("page"), "meta.page missing");
        assertTrue(lastListMeta.containsKey("per_page"), "meta.per_page missing");
        assertTrue(lastListMeta.containsKey("total"), "meta.total missing");
    }

    @Then("settlement_item_timebound audit entries should not contain settlement_item_id or timestamp columns")
    public void auditShouldNotContainItemOrTimestampColumns() {
        assertFalse(lastAuditRows.isEmpty(), "No audit rows captured");
        lastAuditRows.forEach(row -> {
            assertFalse(row.containsKey("settlement_item_id"), "Audit row unexpectedly contains settlement_item_id");
            assertFalse(row.containsKey("start_dttm_utc"), "Audit row unexpectedly contains start_dttm_utc");
            assertFalse(row.containsKey("end_dttm_utc"), "Audit row unexpectedly contains end_dttm_utc");
        });
    }

    @Then("settlement_item_timebound audit should contain exactly {int} entries")
    public void auditShouldContainExactlyEntries(int expected) {
        assertEquals(expected, lastAuditRows.size(), "Unexpected number of audit rows");
    }

    @Then("settlement_item_timebound audit changed fields should be {string}")
    public void auditChangedFieldsShouldBe(String csv) {
        assertFalse(lastAuditRows.isEmpty(), "No audit rows captured");
        assertTrue(lastAuditRows.get(0).containsKey("changed_field"),
                "No changed_field column found, keys: " + lastAuditRows.get(0).keySet());
        List<String> actual = lastAuditRows.stream()
                .map(r -> Objects.toString(r.get("changed_field"), "").toLowerCase())
                .collect(Collectors.toList());
        List<String> expected = Arrays.stream(csv.split(","))
                .map(s -> s.trim().toLowerCase())
                .collect(Collectors.toList());
        assertEquals(expected, actual, "Audit changed_field values differ");
    }

    @Then("settlement_item_timebound audit entry {int} should change {word} from {string} to {string}")
    public void auditEntryShouldChangeFieldFromTo(int index, String field, String from, String to) {
        assertTrue(index >= 1 && index <= lastAuditRows.size(),
                "Audit entry index " + index + " out of range (" + lastAuditRows.size() + " rows)");
        HashMap<String, Object> row = lastAuditRows.get(index - 1);
        assertEquals(field, Objects.toString(row.get("changed_field"), ""), "changed_field");
        assertEquals(from, Objects.toString(row.get("changed_from"), ""), "changed_from");
        assertEquals(to, Objects.toString(row.get("changed_to"), ""), "changed_to");
    }

    @Then("the saved ids {word} and {word} should differ")
    public void savedIdsShouldDiffer(String tagA, String tagB) {
        assertNotEquals(resolveTag(tagA), resolveTag(tagB), "Ids should differ");
    }

    @Then("settlement_item_timebound {word} should still belong to {word}")
    public void rowShouldStillBelongTo(String tag, String itemToken) {
        HashMap<String, Object> row = fetchRow(resolveTag(tag), null);
        assertEquals(resolveToken(itemToken), Objects.toString(row.get("settlement_item_id"), null),
                "settlement_item_id changed");
    }

    @Then("the row {word} should not be deleted")
    public void rowShouldNotBeDeleted(String tag) {
        HashMap<String, Object> row = fetchRow(resolveTag(tag), true);
        assertFalse(Boolean.parseBoolean(Objects.toString(row.get("deleted"), "false")),
                "Row unexpectedly deleted");
    }

    @Then("the last POST response should have a generated id different from {word} and deleted false")
    public void lastPostShouldHaveGeneratedId(String suppliedId) {
        assertFalse(lastPostReturned.isEmpty(), "No POST response captured");
        for (HashMap<String, Object> data : lastPostReturned) {
            String id = Objects.toString(data.get("settlement_item_timebound_id"), "");
            assertNotEquals(suppliedId, id, "Server used the client supplied id");
            Object deleted = data.get("deleted");
            if (deleted != null) {
                assertFalse(Boolean.parseBoolean(deleted.toString()), "POST returned deleted=true");
            }
            assertFalse(Boolean.parseBoolean(
                    Objects.toString(fetchRow(id, true).get("deleted"), "false")), "Stored row is deleted");
        }
        RequestContainer.build().getEntity(EntityType.SETTLEMENT_ITEM_TIMEBOUND, suppliedId)
                .call(HttpStatus.build().withCode(404));
    }

    @Then("GET settlement_item_timebound by id should have field {word} equal to {}")
    public void byIdFieldEquals(String field, String expectedRaw) {
        assertNotNull(lastRetrievedById, "No GET by id response captured");
        Object actual = lastRetrievedById.get(field);
        if ("null".equals(expectedRaw)) {
            assertNull(actual, "Expected " + field + " to be null but was " + actual);
            return;
        }
        assertNotNull(actual, "Field '" + field + "' is null or missing");
        String expected = resolveIfToken(expectedRaw);
        assertTrue(valuesEqual(expected, actual),
                field + ": expected '" + expected + "' but was '" + actual + "'");
    }

    @Then("GET settlement_item_timebound by id should have a numeric field {word} equal to {}")
    public void byIdNumericFieldEquals(String field, String expected) {
        assertNotNull(lastRetrievedById, "No GET by id response captured");
        Object actual = lastRetrievedById.get(field);
        assertTrue(actual instanceof Number, field + " is not a JSON number: " + actual);
        assertEquals(0, new BigDecimal(expected).compareTo(new BigDecimal(actual.toString())),
                field + ": expected " + expected + " but was " + actual);
    }

    @Then("GET settlement_item_timebound by id should have a string field {word}")
    public void byIdStringField(String field) {
        assertNotNull(lastRetrievedById, "No GET by id response captured");
        assertTrue(lastRetrievedById.get(field) instanceof String,
                field + " is not a JSON string: " + lastRetrievedById.get(field));
    }

    @Then("GET settlement_item_timebound by id should have timestamps in UTC Z format")
    public void byIdTimestampsUtcZ() {
        assertNotNull(lastRetrievedById, "No GET by id response captured");
        for (String f : List.of("start_dttm_utc", "end_dttm_utc")) {
            String v = Objects.toString(lastRetrievedById.get(f), "");
            assertTrue(v.endsWith("Z"), f + " is not in UTC Z format: " + v);
            ZonedDateTime.parse(v);
        }
    }

    @Then("GET settlement_item_timebound should return {int} rows")
    public void listShouldReturnRows(int expected) {
        assertEquals(expected, returnedRows.size(), "Unexpected number of rows returned");
    }

    @Then("GET settlement_item_timebound current page should contain {int} rows")
    public void currentPageShouldContainRows(int expected) {
        assertEquals(expected, request.getDataAsList().size(), "Unexpected number of rows on this page");
    }

    @When("I POST an empty settlement_item_timebound array")
    public void iPostEmptyArray() {
        request = RequestContainer.build().submitTimebounds(HttpOp.POST, new ArrayList<HashMap<String, Object>>());
        request.call(context.popExpectedStatus(400));
    }

    @When("I call GET settlement_item_timebound with settlement_item_id {word} and raw query {string}")
    public void iCallGetListWithItemAndRawQuery(String itemToken, String rawQuery) {
        HashMap<String, Object> parms = new HashMap<>();
        parms.put("settlement_item_id", resolveToken(itemToken));
        callListWithRawQuery(parms, rawQuery);
    }

    @When("I call GET settlement_item_timebound with raw query {string}")
    public void iCallGetListWithRawQueryOnly(String rawQuery) {
        callListWithRawQuery(new HashMap<>(), rawQuery);
    }

    private void callListWithRawQuery(HashMap<String, Object> parms, String rawQuery) {
        returnedRows.clear();
        for (String pair : rawQuery.split("&")) {
            if (pair.isBlank()) continue;
            String[] kv = pair.split("=", 2);
            String value = kv.length > 1 ? java.net.URLDecoder.decode(kv[1], java.nio.charset.StandardCharsets.UTF_8) : "";
            parms.put(kv[0], value);
        }
        request = RequestContainer.build().getEntities(EntityType.SETTLEMENT_ITEM_TIMEBOUNDS).addQueryParms(parms);
        HttpStatus expectedStatus = context.popExpectedStatus(200);
        request.call(expectedStatus);
        if (expectedStatus.getCode() == 200) {
            captureCurrentPageRows();
        }
    }

    @Then("GET settlement_item_timebound by id should have field change_comments absent or not changed by delete")
    public void byIdChangeCommentsUnchanged() {
        assertNotNull(lastRetrievedById, "No GET by id response captured");
        String id = Objects.toString(lastRetrievedById.get("settlement_item_timebound_id"), "");
        Object actual = lastRetrievedById.get("change_comments");
        if (actual != null && lastChangeCommentById.containsKey(id)) {
            assertEquals(lastChangeCommentById.get(id), actual.toString(),
                    "change_comments changed after DELETE");
        }
    }

    @When("I POST a settlement_item_timebound row for {word} from {word} to {word}")
    public void iPostRowForItemFromTo(String itemToken, String start, String end) {
        HashMap<String, Object> row = new HashMap<>();
        row.put("settlement_item_id", itemToken);          // replaceParmValues resolves <G1> in the shared POST helper
        row.put("start_dttm_utc", start);
        row.put("end_dttm_utc", end);
        row.put("interval_source", "MEASURED");
        row.put("change_comments", "auto " + start + " to " + end);
        iPostSettlementItemTimeboundRows(List.of(row));
    }

//    @When("I call GET settlement_item_timebound with settlement_item_id {word} and header {string} = {string}")
//    public void iCallGetListWithHeader(String itemToken, String headerName, String headerValue) {
//        returnedRows.clear();
//        HashMap<String, Object> parms = new HashMap<>();
//        parms.put("settlement_item_id", resolveToken(itemToken));
//        request = RequestContainer.build().getEntities(EntityType.SETTLEMENT_ITEM_TIMEBOUNDS).addQueryParms(parms);
//        request.addHeader(headerName, headerValue);      // ADAPT: your header method name
//        HttpStatus expectedStatus = context.popExpectedStatus(200);
//        request.call(expectedStatus);
//        captureResponseDetails();
//        if (expectedStatus.getCode() == 200) {
//            captureCurrentPageRows();
//        }
//    }
//
//    @Then("the response header {string} should be {string}")
//    public void responseHeaderShouldBe(String name, String expected) {
//        String actual = lastResponseHeaders.get(name.toLowerCase());
//        assertNotNull(actual, "Response header '" + name + "' missing, got " + lastResponseHeaders.keySet());
//        assertEquals(expected.toLowerCase(), actual.toLowerCase(), "Header " + name);
//    }
//
//    @Then("the response should not have header {string}")
//    public void responseShouldNotHaveHeader(String name) {
//        assertFalse(lastResponseHeaders.containsKey(name.toLowerCase()),
//                "Unexpected response header '" + name + "': " + lastResponseHeaders.get(name.toLowerCase()));
//    }
//
//    @Then("the decompressed body should be valid JSON with meta.total {int}")
//    public void decompressedBodyShouldBeValidJson(int expectedTotal) throws Exception {
//        byte[] bytes = lastRawBody;
//        boolean gzipped = bytes.length > 2 && (bytes[0] & 0xff) == 0x1f && (bytes[1] & 0xff) == 0x8b;
//        if (gzipped) {
//            try (java.util.zip.GZIPInputStream in = new java.util.zip.GZIPInputStream(new java.io.ByteArrayInputStream(bytes))) {
//                bytes = in.readAllBytes();
//            }
//        }
//        com.fasterxml.jackson.databind.JsonNode json = new com.fasterxml.jackson.databind.ObjectMapper().readTree(bytes);
//        assertTrue(json.has("meta"), "Response has no meta");
//        assertEquals(expectedTotal, json.get("meta").get("total").asInt(), "meta.total");
//        assertTrue(json.has("data"), "Response has no data");
//    }

    @When("I call GET settlement_item_timebound with settlement_item_id {word} and header {string} = {string}")
    public void iCallGetListWithHeader(String itemToken, String headerName, String headerValue) {
        returnedRows.clear();
        HashMap<String, Object> parms = new HashMap<>();
        parms.put("settlement_item_id", resolveToken(itemToken));
        request = RequestContainer.build()
                .getEntities(EntityType.SETTLEMENT_ITEM_TIMEBOUNDS)
                .addQueryParms(parms)
                .addHeader(headerName, headerValue);
        HttpStatus expectedStatus = context.popExpectedStatus(200);
        request.callRaw(expectedStatus.getCode());
        captureResponseDetails();
    }

    @Then("the response header {string} should be {string}")
    public void responseHeaderShouldBe(String name, String expected) {
        String actual = lastResponseHeaders.get(name.toLowerCase());
        assertNotNull(actual, "Response header '" + name + "' missing, got " + lastResponseHeaders.keySet());
        assertEquals(expected.toLowerCase(), actual.toLowerCase(), "Header " + name);
    }

    @Then("the response should not have header {string}")
    public void responseShouldNotHaveHeader(String name) {
        assertFalse(lastResponseHeaders.containsKey(name.toLowerCase()),
                "Unexpected response header '" + name + "': " + lastResponseHeaders.get(name.toLowerCase()));
    }

    @Then("the decompressed body should be valid JSON with meta.total {int}")
    public void decompressedBodyShouldBeValidJson(int expectedTotal) throws Exception {
        byte[] bytes = lastRawBody;
        boolean gzipped = bytes.length > 2 && (bytes[0] & 0xff) == 0x1f && (bytes[1] & 0xff) == 0x8b;
        if (gzipped) {
            try (java.util.zip.GZIPInputStream in =
                         new java.util.zip.GZIPInputStream(new java.io.ByteArrayInputStream(bytes))) {
                bytes = in.readAllBytes();
            }
        }
        com.fasterxml.jackson.databind.JsonNode json = new com.fasterxml.jackson.databind.ObjectMapper().readTree(bytes);
        assertTrue(json.has("data") && json.get("data").isArray(), "Response has no data array");
        assertTrue(json.has("meta"), "Response has no meta");
        assertEquals(expectedTotal, json.get("meta").get("total").asInt(), "meta.total");
    }
}
