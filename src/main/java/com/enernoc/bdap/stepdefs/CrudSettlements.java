package com.enernoc.bdap.stepdefs;

import com.enernoc.bdap.model.*;
import com.enernoc.bdap.model.APIResponses.*;
import com.enernoc.bdap.shared.Context;
import com.enernoc.bdap.shared.EntityValidator;
import com.enernoc.bdap.shared.Utility;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.cucumber.datatable.DataTable;
import io.cucumber.java.ParameterType;
import io.cucumber.java.en.Given;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.time.*;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.LongAdder;
import java.util.stream.Stream;

import static com.enernoc.bdap.model.EntityType.*;
import static com.enernoc.bdap.model.HttpOp.*;
import static org.junit.jupiter.api.Assertions.*;
import java.time.OffsetDateTime;
import java.time.format.DateTimeParseException;

public class CrudSettlements {

    private static final Logger LOG = LoggerFactory.getLogger("CrudSettlements");
    private static final ObjectMapper JSON = new ObjectMapper();
    private final Context context = Context.getContext();

    private RequestContainer request;
    private final Utility utility = new Utility();

    private final HashMap<String, SettlementItem> siHierarchies = new HashMap<>();  // indexed by master settlement id
    private final HashMap<String, ArrayList<AuditLogEntry>> settlementAuditLogEntries = new HashMap<>();  // indexed by settlement id
    private final HashMap<String, ArrayList<AuditLogEntry>> settlementItemAuditLogEntries = new HashMap<>();  // indexed by settlement item id
    private final HashMap<String, ArrayList<AuditLogEntry>> settlementItemIntervalsAuditLogEntries = new HashMap<>();  // indexed by settlement id

    private HashMap<String, ArrayList<AuditLogEntry>> getExpectedAuditLog(EntityType entityType) {
        return switch (entityType) {
            case SETTLEMENT -> settlementAuditLogEntries;
            case SETTLEMENT_ITEM -> settlementItemAuditLogEntries;
            case SETTLEMENT_ITEM_INTERVALS -> settlementItemIntervalsAuditLogEntries;
            default -> {
                fail("Invalid entity");
                yield new HashMap<>(); // makes compiler happy
            }
        };
    }


    @ParameterType(".*")
    public EntityType entityType(String str) {
        if ("SETTLEMENT_ITEM_INTERVAL".equalsIgnoreCase(str)) {
            return SETTLEMENT_ITEM_INTERVALS;
        }
        return EntityType.get(str);
    }


    @ParameterType(".*")
    public HttpOp httpOp(String str) {
        return HttpOp.get(str);
    }


    @Given("I save the event_id")
    public void iSaveEventId() {
        context.savedEventId = request.getBodyProps().get("event_id").toString();
    }


    @When("I save the {entityType} id for later use with the tag {word}")
    public void iSaveEntityId(EntityType entityType, String tag) {
        switch (entityType) {
            case SETTLEMENT -> context.savedValues.put(tag, context.lastSettlementId);
            case SETTLEMENT_ITEM -> context.savedValues.put(tag, context.lastSettlementItemId);
            default -> fail();
        }
    }

    @When("I set the last {entityType} id from the tag {word}")
    public void iSetEntityId(EntityType entityType, String tag) {
        switch (entityType) {
            case SETTLEMENT -> context.lastSettlementId = context.savedValues.get(tag);
            case SETTLEMENT_ITEM -> context.lastSettlementItemId = context.savedValues.get(tag);
            default -> fail();
        }
    }


    @When("I set the last {entityType} id to {word}")
    public void iSetEntityIdTo(EntityType entityType, String id) {
        switch (entityType) {
            case SETTLEMENT -> context.lastSettlementId = id;
            case SETTLEMENT_ITEM -> context.lastSettlementItemId = id;
            default -> fail();
        }
    }


    @When("I set the tag {word} to a random uuid")
    public void iSetTagRandomUuid(String tag) {
        context.savedValues.put(tag, UUID.randomUUID().toString());
    }


    @When("I POST a {entityType} with the following properties:")
    public void iCreateEntity(EntityType entityType, DataTable paramTable) {

        var params = new HashMap<>(paramTable.asMap(String.class, Object.class));
        utility.replaceParmValues(params);

        Utility.stringToBoolean(params);

        switch (entityType) {
            case SETTLEMENT -> {
                request = RequestContainer.build().submitEntity(HttpOp.POST, entityType, params);
                var expectedStatus = context.popExpectedStatus(201);
                var entity = request.call(expectedStatus).getResponseEntity(PostSettlementResult.class);
                if (expectedStatus.getCode() == 201) {
                    assertNotNull(entity);
                    context.lastSettlementId = entity.data().settlement_id;
                    LOG.info(String.format("Settlement created: %s", entity.data().settlement_id));
                }
            }
            case SETTLEMENT_ITEM -> {
                request = RequestContainer.build().submitEntity(HttpOp.POST, entityType, params);
                var expectedStatus = context.popExpectedStatus(201);
                if (expectedStatus.getCode() == 201) {
                    var entity = request.call(expectedStatus).getResponseEntity(PostSettlementItemResult.class);
                    assertNotNull(entity);
                    var item = entity.data();
                    if (item.deleted == null) {
                        item.deleted = false;  // this will be set on the saved item by the API
                    }
                    context.lastSettlementItemId =item.settlement_item_id;
                    context.lastSettlementLevelId = Utility.objectToStringOrNull(params.getOrDefault("settlement_level_id", item.settlement_level_id));
                    context.lastAtlasSettlementLevelId = Utility.objectToStringOrNull(params.getOrDefault("atlas_settlement_level_id", item.settlement_level_id));
                    context.lastRegistrationSetId = Utility.objectToStringOrNull(params.getOrDefault("registration_set_id", null));
                    context.lastPortfolioId = Utility.objectToStringOrNull(params.getOrDefault("portfolio_id", null));
                    if (params.containsKey("master_settlement_item_id")) {
                        // This item is a child
                        var masterId = params.get("master_settlement_item_id").toString();
                        assertTrue(siHierarchies.containsKey(masterId), "Invalid master item specified!");
                        var masterItem =  siHierarchies.get(masterId);
                        masterItem.sub_settlement_items.add(item);
                    } else {
                        // This item could potentially be a master
                        item.sub_settlement_items = new TreeSet<>();
                        siHierarchies.put(item.settlement_item_id, item);
                    }
                    LOG.info(String.format("%s created with settlement_item_id %s", entityType, item.settlement_item_id));
                } else {  // error is expected
                    request.call(expectedStatus).getResponseEntity(BasicResult.class);
                }
            }
            case SETTLEMENT_ITEM_INTERVALS -> {
                // numeric overrides
                Utility.stringToNumber(
                        params,
                        "realtime_availability_kw_override"
                );

                //treat null as null for realtime_availability_kw_override", "payment_value_override"
                    Stream.of("realtime_availability_kw_override", "payment_value_override")
                            .forEach(f -> {
                                Object v = params.get(f);
                                if (v != null && "null".equalsIgnoreCase(v.toString())) {
                                    params.put(f, null);   // real null -> JSON null
                                }
                            });

                request = RequestContainer.build().submitIntervals(HttpOp.POST, List.of(params));
                var expectedStatus = context.popExpectedStatus(200);
                var entity = request.call(expectedStatus).getResponseEntity(PostSettlementItemIntervalsResult.class);
                if (expectedStatus.getCode() == 200) {
                    assertNotNull(entity);
                    // Save the interval. Since the POST payload may be missing optional fields, we need to convert the payload to an object and back to a map to get all fields.
                    SettlementItemInterval interval = JSON.convertValue(params, SettlementItemInterval.class);
                    HashMap<String, Object> intervalMap = JSON.convertValue(interval, new TypeReference<>() {});
                    if (!intervalsByItem.containsKey(interval.settlement_item_id)) {
                        intervalsByItem.put(interval.settlement_item_id, new TreeMap<>());
                    }
                    intervalsByItem.get(interval.settlement_item_id).put(ZonedDateTime.parse(interval.interval_dttm_utc).toEpochSecond(), intervalMap);

                    LOG.info(entityType + " created");
                }
            }
        }

    }


    @When("I PUT the {entityType} with new values:")
    public void iPutEntity(EntityType entityType, DataTable paramTable) {
        iUpdateEntity(PUT, entityType, paramTable);
    }


    @When("I PATCH the {entityType} with new values:")
    public void iPatchEntity(EntityType entityType, DataTable paramTable) {
        iUpdateEntity(HttpOp.PATCH, entityType, paramTable);
    }


    private void iUpdateEntity(HttpOp op, EntityType entityType, DataTable paramTable) {
        var params = new HashMap<>(paramTable.asMap(String.class, Object.class));
        utility.replaceParmValues(params);

        Utility.stringToBoolean(params);

        // Update saved ids to point to current entity (if different), then get current properties of entity
        HashMap<String, Object> savedProps = switch (entityType) {
            case SETTLEMENT -> {
                if (params.containsKey("settlement_id")) {
                    String id = params.get("settlement_id").toString();
                    if (context.savedSettlements.containsKey(id)) {
                        // settlement_id is present and specifies an existing item
                        context.lastSettlementId = id;
                        yield context.savedSettlements.get(id);
                    } else {
                        // settlement_id is present but does not specify an existing item
                        // Get the last settlement if it exists, otherwise assume this is an error scenario
                        if (context.savedSettlements.containsKey(context.lastSettlementId)) {
                            yield context.savedSettlements.get(context.lastSettlementId);
                        } else {
                            yield new HashMap<>();
                        }
                    }
                } else {
                    // settlement_id is not present
                    yield context.savedSettlements.get(context.lastSettlementId);
                }
            }
            case SETTLEMENT_ITEM -> {
                if (params.containsKey("settlement_item_id")) {
                    String id = params.get("settlement_item_id").toString();
                    if (context.savedSettlementItems.containsKey(id)) {
                        // settlement_item_id is present and specifies an existing item
                        context.lastSettlementItemId = id;
                        yield context.savedSettlementItems.get(id);
                    } else {
                        // settlement_item_id is present but does not specify an existing item
                        yield context.savedSettlementItems.get(context.lastSettlementItemId);
                    }
                } else {
                    // settlement_item_id is not present
                    yield context.savedSettlementItems.get(context.lastSettlementItemId);
                }
            }
            case SETTLEMENT_ITEM_INTERVALS -> {
                // numeric overrides
                Utility.stringToNumber(
                        params,
                        "realtime_availability_kw_override"
                );

                //treat null as null not string
            Stream.of("realtime_availability_kw_override", "payment_value_override")
                    .forEach(f -> {
                        Object v = params.get(f);
                        if (v != null && "null".equalsIgnoreCase(v.toString())) {
                            params.put(f, null);   // real null -> JSON null
                        }
                    });


                if (params.containsKey("settlement_item_id")) {
                    String itemId = params.get("settlement_item_id").toString();
                    if (intervalsByItem.containsKey(itemId)) {
                        var intervals = intervalsByItem.get(itemId);
                        if (params.containsKey("interval_dttm_utc")) {
                            long epoch = ZonedDateTime.parse(params.get("interval_dttm_utc").toString()).toEpochSecond();
                            if (intervals.containsKey(epoch)) {
                                yield intervals.get(epoch);
                            }
                        }
                    }
                }
                yield new HashMap<>();
            }
            default -> fail(String.format("Invalid entity type requested: %s", entityType.name()));
        };

        // Generate expected audit log entries if request is expected to succeed
        ArrayList<AuditLogEntry> newLogEntries = new ArrayList<>();
        HttpStatus expectedStatus = context.popExpectedStatus(200);
        List<String> unauditedProps = Arrays.asList("change_comments", "last_updated_dttm_utc", "last_updated_by", "created_dttm_utc", "deleted", "force");
        if (expectedStatus.getCode() == 200) {
            String comments = params.get("change_comments").toString();
            newLogEntries.addAll(new ArrayList<>() {{
                params.entrySet().stream().filter(e -> !unauditedProps.contains(e.getKey())).forEach(e -> {
                    String fromValue = savedProps.get(e.getKey()) == null ? "" : savedProps.get(e.getKey()).toString();
                    String toValue = e.getValue() == null ? "" : e.getValue().toString();
                    if (!Objects.equals(fromValue, toValue)) {
                        var entry = new AuditLogEntry()
                                .withChangeComments(comments)
                                .withChangedField(e.getKey())
                                .withChangedFrom(fromValue)
                                .withChangedTo(toValue);
                        switch (entityType) {
                            case SETTLEMENT -> entry.withSettlementId(context.lastSettlementId);
                            case SETTLEMENT_ITEM -> entry.withSettlementItemId(context.lastSettlementItemId);
                            case SETTLEMENT_ITEM_INTERVALS -> entry.withSettlementItemId(context.lastSettlementItemId)
                                    .withIntervalDttmUtc(params.get("interval_dttm_utc").toString());
                        }
                        this.add(entry);
                    }
                });
            }});
            // For PUT, properties that are not in the payload should be set to null, which will appear as empty strings in the audit log
            if (op.equals(PUT)) {
                newLogEntries.addAll(new ArrayList<>() {{
                    savedProps.keySet().stream()
                            .filter(key -> !List.of("last_updated_by", "last_updated_dttm_utc","deleted").contains(key))  // these are set by API
                            .filter(key -> !params.containsKey(key))
                            .filter(key -> savedProps.get(key) != null) // property is already null, so no log entry will be created
                            .forEach(key -> {
                                String fromValue = savedProps.get(key).toString();
                                var entry = new AuditLogEntry()
                                        .withChangeComments(comments)
                                        .withChangedField(key)
                                        .withChangedFrom(fromValue)
                                        .withChangedTo("");
                                switch (entityType) {
                                    case SETTLEMENT -> entry.withSettlementId(context.lastSettlementId);
                                    case SETTLEMENT_ITEM, SETTLEMENT_ITEM_INTERVALS -> entry.withSettlementItemId(context.lastSettlementItemId);
                                }
                                this.add(entry);
                            });
                }});
            }
        }

        // Now make the PUT or PATCH request
        request = RequestContainer.build();  // need a new request to save updated properties
        switch (op) {
            case PUT -> {
                var payload = new HashMap<>(params);
                params.entrySet().stream()
                        .filter(e -> e.getValue() != null)
                        .filter(e -> "<missing>".equals(e.getValue().toString())).map(Map.Entry::getKey)
                        .toList()
                        .forEach(payload::remove);
                switch (entityType) {
                    case SETTLEMENT -> {
                        Class<?> clazz = PutSettlementResult.class;
                        request.submitEntity(HttpOp.PUT, entityType, payload).call(expectedStatus).getResponseEntity(clazz);
                    }
                    case SETTLEMENT_ITEM -> {
                        request.submitEntity(HttpOp.PUT, entityType, payload).call(expectedStatus).getResponseEntity(PutSettlementItemResult.class);
                    }
                    case SETTLEMENT_ITEM_INTERVALS -> {
                        request.submitIntervals(HttpOp.PUT, List.of(payload)).call(expectedStatus).getResponseEntity(PutPatchSettlementItemIntervalsResult.class);
                    }
                }
            }
            case PATCH -> {
                var payload = new HashMap<String, Object>() {{
                    this.putAll(params);
                }};
                params.entrySet().stream()
                        .filter(e -> e.getValue() != null)
                        .filter(e -> "<missing>".equals(e.getValue().toString()))
                        .map(Map.Entry::getKey)
                        .toList().forEach(payload::remove);
                switch (entityType) {
                    case SETTLEMENT -> {
                        Class<?> clazz = PutSettlementResult.class;
                        request.submitEntity(op, entityType, payload).call(expectedStatus).getResponseEntity(clazz);
                    }
                    case SETTLEMENT_ITEM -> {
                        Class<?> clazz = PatchResult.class;
                        request.submitEntity(op, entityType, payload).call(expectedStatus).getResponseEntity(clazz);
                    }
                    case SETTLEMENT_ITEM_INTERVALS -> {
                        Class<?> clazz = PatchResult.class;
                        request.submitIntervals(op, List.of(payload)).call(expectedStatus).getResponseEntity(clazz);
                    }
                   default -> fail();
                };
            }
            default -> fail("Invalid operation specified");
        }

        if (expectedStatus.getCode() == 200) { // only update audit log and stored entity if request is expected to succeed
            // Update the log entries with the predicted range of the entry timestamp
            String predictedUpdatedTs = String.format("%d,%d", Context.crudEpoch, ZonedDateTime.now().toEpochSecond() + 15); // allow 15 sec slack
            newLogEntries.forEach(entry -> entry.withAuditLogTs(predictedUpdatedTs));
            // Save the log entries
            var logEntries = getExpectedAuditLog(entityType);
            var id = switch (entityType) {
                case SETTLEMENT -> context.lastSettlementId;
                case SETTLEMENT_ITEM, SETTLEMENT_ITEM_INTERVALS -> context.lastSettlementItemId;
                default -> "missing";
            };
            if (logEntries.containsKey(id)) {
                logEntries.get(id).addAll(newLogEntries);
            } else {
                logEntries.put(id, newLogEntries);
            }
            Utility.stringToBoolean(params);
            // Update the stored entity. Note: for PUT, API should set all properties not in the payload to null.
            params.remove("change_comments"); // this is only saved in the audit log
            if (SETTLEMENT_ITEM_INTERVALS.equals(entityType)) {
                // These are stripped out by PUT and PATCH /interval
                Arrays.asList("last_updated_by", "last_updated_dttm_utc", "created_dttm_utc", "deleted").forEach(params::remove);
            }
            savedProps.putAll(params);
            if (op.equals(PUT)) {
                savedProps.keySet().stream()
                        .filter(key -> !List.of("last_updated_by", "last_updated_dttm_utc", "deleted").contains(key))
                        .filter(key -> !params.containsKey(key))
                        .forEach(key -> savedProps.put(key, null));
            }
            if (op.equals(HttpOp.PATCH) && SETTLEMENT_ITEM.equals(entityType)) {  // Response does not include last_updated_dttm_utc
                savedProps.remove("last_updated_dttm_utc");
            }
            if (op.equals(HttpOp.PUT) && SETTLEMENT_ITEM.equals(entityType)) {
                context.lastSettlementLevelId = Utility.objectToStringOrNull(params.getOrDefault("settlement_level_id", null));
                context.lastAtlasSettlementLevelId = Utility.objectToStringOrNull(params.getOrDefault("atlas_settlement_level_id", null));
                context.lastRegistrationSetId = Utility.objectToStringOrNull(params.getOrDefault("registration_set_id", null));
                context.lastPortfolioId = Utility.objectToStringOrNull(params.getOrDefault("portfolio_id", null));
            }
            if (op.equals(HttpOp.PATCH) && SETTLEMENT_ITEM.equals(entityType) && Objects.nonNull(savedProps.get("master_settlement_item_id"))) {
                savedProps.remove("force");
                SettlementItem thisItem = JSON.convertValue(savedProps, SettlementItem.class);
                // Remove this item from any existing hierarchies
                siHierarchies.values().forEach(master ->
                    master.sub_settlement_items.stream()
                            .filter(item -> item.settlement_item_id.equals(id)).findAny()
                            .ifPresent(item -> master.sub_settlement_items.remove(item)));
                // Now add it to its new master, if it exists
                var masterId = thisItem.master_settlement_item_id;
                assertTrue(siHierarchies.containsKey(masterId), "Invalid master item specified!");
                var masterItem =  siHierarchies.get(masterId);
                masterItem.sub_settlement_items.add(thisItem);
            }
            LOG.info(entityType.name() + " updated");
        }

    }


    @Given("I DELETE all settlements created in this scenario")
    public void iDeleteAllScenarioSettlements() {
        context.savedSettlements.values().stream()
                .filter(item -> !((boolean) item.getOrDefault("deleted", false))).forEach(item -> {
            context.lastSettlementId = item.get("settlement_id").toString();
            iDeleteEntity(SETTLEMENT);
        });
    }


    @Given("I DELETE settlement with the settlement_id {word}")
    public void iDeleteSettlementWithId(String id) {
        context.lastSettlementId = id;
        iDeleteEntity(SETTLEMENT);
    }


    @Given("I DELETE settlement with the id tag {word}")
    public void iDeleteSettlementTagged(String tag) {
        assertTrue(context.savedValues.containsKey(tag), "Saved values does not contain '" + tag + "'");
        context.lastSettlementId = context.savedValues.get(tag);
        iDeleteEntity(SETTLEMENT);
    }


    @Given("I DELETE settlement_item with the id {word}")
    public void iDeleteSettlementItemWithId(String id) {
        context.lastSettlementItemId = id;
        iDeleteEntity(SETTLEMENT_ITEM);
    }


    @Given("I DELETE settlement item with the id tag {word}")
    public void iDeleteSettlementItemTagged(String tag) {
        assertTrue(context.savedValues.containsKey(tag), "Saved values does not contain '" + tag + "'");
        context.lastSettlementItemId = context.savedValues.get(tag);
        iDeleteEntity(SETTLEMENT_ITEM);
    }


    private int lastNumberOfIntervalsDeleted = 0;

    @When("I DELETE the {entityType}")
    public void iDeleteEntity(EntityType entityType) {

        record Parm(String entityId, Class<?> clazz) {
        }
        Parm parm = switch (entityType) {
            case SETTLEMENT -> {
                if (context.savedSettlements.containsKey(context.lastSettlementId)) {
                    context.savedSettlements.get(context.lastSettlementId).put("deleted", true);
                }
                yield new Parm(context.lastSettlementId, DeleteSettlementResult.class);
            }
            case SETTLEMENT_ITEM -> new Parm(context.lastSettlementItemId, DeleteSettlementItemResult.class);
            case SETTLEMENT_ITEM_INTERVALS -> new Parm(context.lastSettlementItemId, DeleteSettlementItemIntervalsResult.class);
            default -> fail(String.format("Invalid entity type requested: %s", entityType.name()));
        };

        // Make API call
        HttpStatus expectedStatus = context.popExpectedStatus(200);
        request = RequestContainer.build().deleteEntity(entityType, parm.entityId);
        var entity = request.call(expectedStatus).getResponseEntity(parm.clazz);

        if (expectedStatus.getCode() == 200) {
            assertNotNull(entity);
            switch (entityType) {
                case SETTLEMENT -> {
                    addDeletionAuditLogEntry(SETTLEMENT, parm.entityId);
                    context.savedSettlementItems.values().stream().filter(item -> parm.entityId.equals(item.get("settlement_id"))).forEach(item -> {
                        String itemId = item.get("settlement_item_id").toString();
                        addDeletionAuditLogEntry(SETTLEMENT_ITEM, itemId);
                        if (intervalsByItem.containsKey(itemId)) {
                            addDeletionAuditLogEntry(SETTLEMENT_ITEM_INTERVALS, itemId);
                        }
                    });
                }
                case SETTLEMENT_ITEM -> {
                    addDeletionAuditLogEntry(SETTLEMENT_ITEM, parm.entityId);
                    if (intervalsByItem.containsKey(parm.entityId)) {
                        addDeletionAuditLogEntry(SETTLEMENT_ITEM_INTERVALS, parm.entityId);
                    }
                    if (context.savedSettlementItems.containsKey(parm.entityId)) {
                        context.savedSettlementItems.get(parm.entityId).put("deleted", true);
                        if (siHierarchies.containsKey(parm.entityId)) {
                            siHierarchies.get(parm.entityId).deleted = true;
                        }
                    }
                }
                case SETTLEMENT_ITEM_INTERVALS -> {
                    if (intervalsByItem.containsKey(parm.entityId)) {
                        lastNumberOfIntervalsDeleted = intervalsByItem.get(parm.entityId).size();
                        if (!deletedIntervalsByItem.containsKey(parm.entityId)) {
                            deletedIntervalsByItem.put(parm.entityId, new TreeMap<>());
                        }
                        deletedIntervalsByItem.get(parm.entityId).putAll(intervalsByItem.get(parm.entityId));
                        addDeletionAuditLogEntry(SETTLEMENT_ITEM_INTERVALS, parm.entityId);
                        intervalsByItem.remove(parm.entityId);
                    }
                }
            }
            LOG.info(entityType + " deleted");
        }
    }


    private void addDeletionAuditLogEntry(EntityType entityType, String entityId) {

        var entry = new AuditLogEntry()
                .withChangedField("deleted")
                .withChangedFrom("false")
                .withChangedTo("true");
        switch (entityType) {
            case SETTLEMENT -> {
                entry.withChangeComments("Deleted Settlement").withSettlementId(entityId);
            }
            case SETTLEMENT_ITEM -> {
                entry.withChangeComments("Deleted settlement_item").withSettlementItemId(entityId);
                // Remove this item from hierarchies
                siHierarchies.values().forEach(master -> {
                    master.sub_settlement_items.stream()
                            .filter(item -> item.settlement_item_id.equals(entityId)).findAny()
                            .ifPresent(item -> item.deleted = true);
                });
            }
            case SETTLEMENT_ITEM_INTERVALS -> {
                assertTrue(intervalsByItem.containsKey(entityId));
                int numIntervals = intervalsByItem.get(entityId).size();
                entry
                        .withChangeComments(String.format("Deleted %d intervals", numIntervals))
                        .withSettlementItemId(entityId)
                        .withIntervalDttmUtc("ALL_INTERVALS");
            }
        };
        String predictedUpdatedTs = String.format("%d,%d", Context.crudEpoch, ZonedDateTime.now().toEpochSecond() + 15); // allow 15-sec slack
        entry.withAuditLogTs(predictedUpdatedTs);
        var logEntries = getExpectedAuditLog(entityType);
        if (logEntries.containsKey(entityId)) {
            logEntries.get(entityId).add(entry);
        } else {
            var entryList = new ArrayList<AuditLogEntry>();
            entryList.add(entry);
            logEntries.put(entityId, entryList);
        }
    }


    @Then("the DELETE settlement details should specify {int} settlement items and {int} settlement item intervals")
    public void deleteSettlementResultShouldContain(int numItems, int numIntervals) {
        assertTrue(request.responseMap.containsKey("detail"), "No detail field in response!");
        String actual = request.responseMap.get("detail").toString();
        String expected = String.format("Deleted %d settlement_item_interval(s), %d settlement_item(s) and 1 settlement for settlement_id=%s",
                numIntervals, numItems, context.lastSettlementId);
        assertEquals(expected, actual);
        LOG.info("DELETE settlement detail verified");
    }


    @Then("the DELETE settlement_item details should specify the expected number of settlement item intervals")
    public void deleteSettlementItemResultShouldContain() {
        int numIntervals = intervalsByItem.get(context.lastSettlementItemId).size();
        assertTrue(request.responseMap.containsKey("detail"), "No detail field in response!");
        String actual = request.responseMap.get("detail").toString();
        String expected = String.format("Deleted %d settlement_item_interval(s) and 1 settlement_item for settlement_item_id=%s", numIntervals, context.lastSettlementItemId);
        assertEquals(expected, actual);
        LOG.info(String.format("DELETE settlement_item detail verified: %s", actual));
    }


    @Then("the DELETE settlement_item details should specify {int} settlement item(s) and {int} settlement item interval(s)")
    public void deleteSettlementItemResultShouldContain(int numItems, int numIntervals) {
        assertTrue(request.responseMap.containsKey("detail"), "No detail field in response!");
        String actual = request.responseMap.get("detail").toString();
        String expected = String.format("Deleted %d settlement_item_interval(s) and %d settlement_item for settlement_item_id=%s",
                numIntervals, numItems, context.lastSettlementItemId);
        assertEquals(expected, actual);
        LOG.info(String.format("DELETE settlement_item detail verified: %s", actual));
    }


    @Then("the DELETE settlement_item_intervals details should specify the expected number of settlement item intervals")
    public void deleteSettlementItemIntervalsResultShouldContain() {
        assertTrue(request.responseMap.containsKey("detail"), "No detail field in response!");
        String actual = request.responseMap.get("detail").toString();
        String expected = String.format("Deleted %d settlement_item_interval(s) for settlement_item_id=%s", lastNumberOfIntervalsDeleted, context.lastSettlementItemId);
        assertEquals(expected, actual);
        LOG.info(String.format("DELETE settlement_item_intervals detail verified: %s", actual));
    }


    @Then("the response should include the new settlement")
    public void crudResponseShouldNewSettlement() {

        var expected = new HashMap<>(request.getBodyProps());
        expected.put("settlement_id", context.lastSettlementId);
        expected.putIfAbsent("inputs_available_until_dttm_utc", null);
        Utility.stringToBoolean(expected);

        List<String> errors = EntityValidator.build()
                .withRequest(request)
                .withExpected(expected)
                .compare();
        assertTrue(errors.isEmpty(), String.join("\n", errors));

        // Save the settlement for later updates
        var respMap = request.getDataAsList().get(0);
        respMap.put("deleted", false);  // this is added by the API when the settlement is saved in the database
        assertFalse(context.savedSettlements.containsKey(context.lastSettlementId), "You want to use the stepdef 'the response should include the updated settlement'!");
        context.savedSettlements.put(context.lastSettlementId, respMap);

        // Also save added properties for later use
        context.lastEventId = respMap.get("event_id") == null ? null : respMap.get("event_id").toString();
        context.lastUpdatedBy = respMap.getOrDefault("last_updated_by", "missing").toString();
        context.lastUpdatedDttmUtc = respMap.getOrDefault("last_updated_dttm_utc", "missing").toString();

        LOG.info("Settlement verified");
    }


    @Then("the response should include the new settlement_item")
    public void crudResponseShouldNewSettlementItem() {

        var expected = new HashMap<>(request.getBodyProps());
        expected.put("settlement_item_id", context.lastSettlementItemId);
        // Add properties that are returned even if null
        Arrays.asList("master_settlement_item_id", "atlas_settlement_level_id", "ecrm_opportunity_id", "ecrm_account_id", "ecrm_site_id", "start_dttm_utc", "end_dttm_utc", "registration_set_id", "portfolio_id", "is_inactive").forEach(prop -> {
            if (!expected.containsKey(prop)) {
                expected.put(prop, null);
            }
        });
        expected.put("deleted", false);

        List<String> errors = EntityValidator.build()
                .withRequest(request)
                .withExpected(expected)
                .compare();
        assertTrue(errors.isEmpty(), String.join("\n", errors));

        // Save the settlement_item for later updates
        assertFalse(context.savedSettlementItems.containsKey(context.lastSettlementItemId), "You want to use the stepdef 'the response should include the new settlement_item'!");
        context.savedSettlementItems.put(context.lastSettlementItemId, expected);

        LOG.info("Settlement item verified");
    }


    // This map stores a list of timestamp-ordered intervals for each settlement item
    private final HashMap<String, TreeMap<Long, HashMap<String, Object>>> intervalsByItem = new HashMap<>();

    // This map stores a list of DELETED timestamp-ordered intervals for each settlement item
    private final HashMap<String, TreeMap<Long, HashMap<String, Object>>> deletedIntervalsByItem = new HashMap<>();


    @Then("the response should indicate that {int} intervals were created")
    public void responseIndicatesNumIntervalsCreated(int numExpected) {
        String actual = request.responseMap.getOrDefault("detail", "<missing>").toString();
        String expected = String.format("Successfully created %d settlement_item_intervals", numExpected);
        assertEquals(expected, actual);
    }


    @Given("I call GET settlement_details")
    public void iCallGetSettlementDetails() {

        //request = RequestContainer.build().getEntity(SETTLEMENT_DETAILS, context.lastSettlementId);
        request = RequestContainer.build().getEntity(SETTLEMENT_DETAILS, "01b3d5ed-4273-480c-a03c-4ab0527425cd");
        var expectedStatus = context.popExpectedStatus(200);
        var response = request.call(expectedStatus).getResponseEntity(GetSettlementDetailsResult.class);
        if (expectedStatus.getCode() == 200) {
            var details = response.data();
            LOG.info(String.format("GET settlement_details returned %d items", details.settlement_items.size()));
        }
    }


    @Given("I call GET settlement_item_intervals_summary")
    public void iCallGetSettlementItemIntervalsSummary() {

        request = RequestContainer.build().getEntity(SETTLEMENT_ITEM_INTERVAL_SUMMARY, context.lastSettlementItemId);
        var expectedStatus = context.popExpectedStatus(200);
        var response = request.call(expectedStatus).getResponseEntity(GetSettlementItemIntervalSummaryResult.class);
        if (expectedStatus.getCode() == 200) {
            var summary = response.data();
            LOG.info(String.format("GET summary returned %d intervals from %s to %s", summary.number_of_intervals, summary.first_interval_dttm_utc, summary.last_interval_dttm_utc));
        }
    }


    @Then("the GET settlement_item_intervals_summary result should be correct")
    public void validateGetSettlementItemIntervalsSummary() {
        assertEquals(200, request.response.getStatusCode(), "GET settlement_item_intervals_summary did not succeed");
        var summary = request.getResponseEntity(GetSettlementItemIntervalSummaryResult.class).data();
        assertTrue(intervalsByItem.containsKey(context.lastSettlementItemId), "No intervals found for last item!");
        var intervals = intervalsByItem.get(context.lastSettlementItemId);
        assertEquals(intervals.size(), summary.number_of_intervals, "Invalid number of intervals in summary");

        {
            long expected = intervals.firstKey();
            long actual = ZonedDateTime.parse(summary.first_interval_dttm_utc).toEpochSecond();
            if (actual != expected) {
                fail(String.format("Invalid first_interval_dttm_utc in summary. Expected: %s  Actual: %s",
                        ZonedDateTime.ofInstant(Instant.ofEpochSecond(expected), ZoneOffset.UTC), ZonedDateTime.ofInstant(Instant.ofEpochSecond(actual), ZoneOffset.UTC)));
            }
        }

        {
            long expected = intervals.lastKey();
            long actual = ZonedDateTime.parse(summary.last_interval_dttm_utc).toEpochSecond();
            if (expected != actual) {
                fail(String.format("Invalid last_interval_dttm_utc in summary. Expected: %s  Actual: %s",
                        ZonedDateTime.ofInstant(Instant.ofEpochSecond(expected), ZoneOffset.UTC), ZonedDateTime.ofInstant(Instant.ofEpochSecond(actual), ZoneOffset.UTC)));
            }
        }
        LOG.info("GET settlement_item_intervals_summary verified");
    }



    @Then("the response should include the updated settlement")
    public void crudResponseShouldUpdatedSettlement() {

        var respMap = Collections.unmodifiableMap(request.getDataAsList().get(0));
        String id = (String) respMap.getOrDefault("settlement_id", "No settlement id!");
        assertEquals(context.lastSettlementId, id);
        assertTrue(context.savedSettlements.containsKey(context.lastSettlementId),
                "No existing settlement saved in this scenario!");
        var settlement = context.savedSettlements.get(context.lastSettlementId);

        HashMap<String, Object> expected;
        if (request.endpoint.verb.equals(PUT)) {
            expected = new HashMap<>(request.getBodyProps());
            expected.putIfAbsent("inputs_available_until_dttm_utc", null);
        } else {
            // PATCH: start from what the API actually returned, then assert payload fields are correct
            expected = new HashMap<>(request.getDataAsList().get(0));
            // Override with payload values — these are what we actually want to assert changed
            expected.putAll(request.getBodyProps());
        }

        Utility.stringToBoolean(expected);
        expected.remove("last_updated_dttm_utc");
        expected.remove("deleted");
        expected.remove("change_comments");

        List<String> errors = EntityValidator.build()
                .withRequest(request)
                .withExpected(expected)
                .compare();
        assertTrue(errors.isEmpty(), String.join("\n", errors));

        settlement.put("last_updated_dttm_utc",
                respMap.getOrDefault("last_updated_dttm_utc", "No last_updated_dttm_utc!"));

        LOG.info("Response verified");
    }

    @Then("the response should include the updated settlement_item")
    public void crudResponseShouldUpdatedSettlementItem() {

        var respMap = Collections.unmodifiableMap(request.getDataAsList().get(0));
        String id = (String) respMap.getOrDefault("settlement_item_id", "No settlement item id!");
        assertEquals(context.lastSettlementItemId, id);
        assertTrue(context.savedSettlementItems.containsKey(context.lastSettlementItemId), "No existing settlement item saved in this scenario!");
        var item = context.savedSettlementItems.get(context.lastSettlementItemId);

        // Now verify that the PUT/PATCH response is identical to the updated settlement.
        // Note: PATCH response only includes the updated fields
        var expected = new HashMap<String, Object>() {{
            if (request.endpoint.verb.equals(PUT)) {
                this.putAll(item);
                // Following is needed to propagate the special comment "No update expected"
                this.put("change_comments", request.getBodyProps().getOrDefault("change_comments", "na"));
            } else {
                this.putAll(request.getBodyProps());
            }
        }};
        expected.remove("last_updated_dttm_utc"); // allow validator to verify that timestamp is after scenario timestamp
        List<String> errors = EntityValidator.build()
                .withRequest(request)
                .withExpected(expected)
                .compare();
        assertTrue(errors.isEmpty(), String.join("\n", errors));

        // update the timestamp in the saved settlement
        item.put("last_updated_dttm_utc", respMap.getOrDefault("last_updated_dttm_utc", "No last_updated_dttm_utc!"));

        LOG.info("Response verified");
    }


    @Then("the response should include the updated settlement_item_interval")
    public void crudResponseShouldUpdatedSettlementItemInterval() {

        var respMap = Collections.unmodifiableMap(request.getDataAsList().get(0));
        String id = (String) respMap.getOrDefault("settlement_item_id", "No settlement item id!");
        String dttm = (String) respMap.getOrDefault("interval_dttm_utc", "No settlement item id!");
        Long epoch = ZonedDateTime.parse(dttm).toEpochSecond();
        assertTrue(intervalsByItem.containsKey(id), "No intervals saved for this settlement id!");
        var interval = intervalsByItem.get(id).get(epoch);

        // Now verify that the PUT/PATCH response is identical to the updated settlement.
        // Note: PATCH response only includes the updated fields
        List<String> errors = EntityValidator.build()
                .withRequest(request)
                .withExpected(request.getBodyPropsList().get(0))
                .compare();
        assertTrue(errors.isEmpty(), String.join("\n", errors));

        // finally, update the timestamp in the saved settlement
        interval.put("last_updated_dttm_utc", respMap.getOrDefault("last_updated_dttm_utc", "No last_updated_dttm_utc!"));

        LOG.info("Response verified");
    }


    @Then("GET settlement should return the {word} entity")
    public void getSettlementShouldReturnNewEntity(String adjective) {

        assertTrue(Arrays.asList("updated","new","deleted").contains(adjective));
        boolean isDeleted = "deleted".equals(adjective);
        var props = context.savedSettlements.get(context.lastSettlementId);
        props.put("deleted", isDeleted);
        if (isDeleted) {
            props.remove("last_updated_dttm_utc"); // DELETE /settlement doesn't return the entity, so allow validator to check that last_updated_dttm_utc > scenario timestamp
        }

        var request = RequestContainer.build().getLastEntity(SETTLEMENT);
        context.includeDeletedOpt.ifPresent(flag -> request.addQueryParm("include_deleted", flag));
        var getRequest = request.call();

        List<String> errors = EntityValidator.build()
                .withRequest(getRequest)
                .withExpected(props)
                .compare();
        assertTrue(errors.isEmpty(), String.join("\n", errors));

        LOG.info("SETTLEMENT verified");
    }


    private SettlementItem lastSettlementItemRetrieved;


    @Then("GET settlement_item should return the new/updated entity")
    public void getSettlementItemShouldReturnNewEntity() {

        var getRequest = RequestContainer.build().getLastEntity(SETTLEMENT_ITEM).call();

        List<String> errors = EntityValidator.build()
                .withRequest(getRequest)
                .withExpected(context.savedSettlementItems.get(context.lastSettlementItemId))
                .compare();
        assertTrue(errors.isEmpty(), String.join("\n", errors));

        LOG.info("SETTLEMENT_ITEM verified");
    }


    @Then("GET settlement_item_intervals should return the new/updated entity")
    public void getSettlementItemIntervalsShouldReturnNewEntity() {

        var getRequest = RequestContainer.build().getLastEntity(SETTLEMENT_ITEM).call();

        List<String> errors = EntityValidator.build()
                .withRequest(getRequest)
                .withExpected(context.savedSettlementItems.get(context.lastSettlementItemId))
                .compare();
        assertTrue(errors.isEmpty(), String.join("\n", errors));

        LOG.info("SETTLEMENT_ITEM_INTERVALS verified");
    }


    @When("I call GET settlement_item for saved id {word} and {word} = {word}")
    public void iCallGetSettlementItemForSavedId(String tag, String parm, String value) {

        assertTrue(context.savedValues.containsKey(tag), "Saved values does not contain '" + tag + "'");
        var id = context.savedValues.get(tag);

        request = RequestContainer.build().getEntity(SETTLEMENT_ITEM, id).addQueryParm(parm, value);
        context.includeDeletedOpt.ifPresent(flag -> request.addQueryParm("include_deleted", flag));
        HttpStatus expectedStatus = context.popExpectedStatus(200);
        if (expectedStatus.getCode() == 200) {
            lastSettlementItemRetrieved = request.call(expectedStatus).getResponseEntity(GetSettlementItemResult.class).data();
            LOG.info("Request succeeded");
        } else {
            request.call(expectedStatus).getResponseEntity(BasicResult.class);
        }

    }

    @Then("the returned settlement item should contain the complete item hierarchy")
    public void siMatchesHierarchy() {
        assertNotNull(lastSettlementItemRetrieved, "You need to retrieve a settlement item!");
        assertTrue(siHierarchies.containsKey(lastSettlementItemRetrieved.settlement_item_id), "You need to create a settlement item hierarchy!");
        SettlementItem master = siHierarchies.get(lastSettlementItemRetrieved.settlement_item_id);
        HashMap<String, Object> hierarchyMap = JSON.convertValue(siHierarchies.get(lastSettlementItemRetrieved.settlement_item_id), new TypeReference<>() {});
        HashMap<String, Object> retrievedMap = JSON.convertValue(lastSettlementItemRetrieved, new TypeReference<>() {});
        List<HashMap<String, Object>> subItems = (List<HashMap<String, Object>>) hierarchyMap.get("sub_settlement_items");
        List<HashMap<String, Object>> subItemsRetrieved = (List<HashMap<String, Object>>) retrievedMap.get("sub_settlement_items");
        assertNotNull(subItems, "No sub_settlement items saved!");
        assertNotNull(subItemsRetrieved, "No sub_settlement items retrieved!");

        List<HashMap<String, Object>> subItemsExpected = new ArrayList<>() {{
            // GET should only return non-deleted items unless it was called with include_deleted = true
            subItems.forEach(item -> {
                if (context.includeDeletedOpt.orElse(false)) {
                    this.add(item);
                } else {
                    Object deletedProp = item.getOrDefault("deleted", null);
                    if (deletedProp == null || !((Boolean) deletedProp)) {
                        this.add(item);
                    }
                }
            });
        }};

        // GET settlement_item always returns deleted property as true or false
        subItemsExpected.forEach(item ->{
            if (item.containsKey("deleted") && item.get("deleted") == null) {
                item.replace("deleted", false);
            }
        });

        // API updates timestamp when subitem is moved to a new parent
        subItemsExpected.forEach(item -> item.replace("last_updated_dttm_utc", "<value replaced by automation>"));
        subItemsRetrieved.forEach(item -> item.replace("last_updated_dttm_utc", "<value replaced by automation>"));

        // Add expected last_updated_by if it's missing in the saved item
        subItemsExpected.stream()
                .filter(item -> !item.containsKey("last_updated_by") || item.get("last_updated_by") == null)
                .forEach(item -> {
                    item.put("last_updated_by", context.lastUpdatedBy);
                });

        if (Boolean.TRUE.equals(master.deleted)) {
            // The DELETE call doesn't return the time of deletion, so we can't verify it
            hierarchyMap.put("last_updated_dttm_utc", "<value replaced by automation>");
            retrievedMap.put("last_updated_dttm_utc", "<value replaced by automation>");
        }

        // temporarily substitute the item hierarchy
        hierarchyMap.put("sub_settlement_items", subItemsExpected);
        assertEquals(hierarchyMap, retrievedMap);
        hierarchyMap.put("sub_settlement_items", subItems);
    }


    @Then("the returned settlement item should only return the master item")
    public void siMatchesMasterItem() {
        assertNotNull(lastSettlementItemRetrieved, "You need to retrieve a settlement item!");
        assertTrue(siHierarchies.containsKey(lastSettlementItemRetrieved.settlement_item_id), "You need to create a settlement item hierarchy!");
        HashMap<String, Object> hierarchyMap = JSON.convertValue(siHierarchies.get(lastSettlementItemRetrieved.settlement_item_id), new TypeReference<>() {});
        hierarchyMap.put("sub_settlement_items", null);
        HashMap<String, Object> retrievedMap = JSON.convertValue(lastSettlementItemRetrieved, new TypeReference<>() {});
        assertEquals(hierarchyMap, retrievedMap);
    }


    @Then("GET settlement_item should return the {word} item")
    public void getSettlementItemShouldReturnNamedItem(String tag) {
        assertTrue(context.savedValues.containsKey(tag), "Saved values does not contain '" + tag + "'");
        var id = context.savedValues.get(tag);
        assertTrue(context.savedSettlementItems.containsKey(id), "Settlement item not saved!");
        HashMap<String, Object> expected = JSON.convertValue(context.savedSettlementItems.get(id), new TypeReference<>() {});
        expected.put("sub_settlement_items", null);
        HashMap<String, Object> actual = JSON.convertValue(lastSettlementItemRetrieved, new TypeReference<>() {});
        List<String> errors = new ArrayList<>() {{
            this.addAll(EntityValidator.build()
                    .withActual(request, actual)
                    .withExpected(expected)
                    .compare());
        }};
        assertTrue(errors.isEmpty(), String.join("\n", errors));
        LOG.info("GET /settlement_item response verified");
    }


    @When("I call GET settlement_item for id {word}")
    public void iCallGetSettlementItemForId(String id) {

        request = RequestContainer.build().getEntity(SETTLEMENT_ITEM, id);
        var result = request.call(context.popExpectedStatus(200));

        LOG.info("Request returned with status " + result.response.statusCode());
    }

    // ---------- GET /settlement_item_intervals

    private final TreeMap<Long, HashMap<String, Object>> returnedIntervals = new TreeMap<>();
    private String lastGetIntervalsItemId = "";

    @Given("I call GET settlement_item_intervals with settlement_item_id: {word} per_page: {word} direction: {word}")
    public void iCallGetSettlementItemIntervalsWithEnumParam(String itemId, String perPage, String direction) {
        boolean goBackward = switch (direction) {
            case "forward" -> false;
            case "backward" -> true;
            default -> fail("Invalid direction specified");
        };
        returnedIntervals.clear();
        HashMap<String, Object> parms = new HashMap<>() {{
            this.put("settlement_item_id", itemId);
            if (!"default".equals(perPage)) {
                this.put("per_page", Integer.parseInt(perPage));
            }
        }};
        utility.replaceParmValues(parms);
        lastGetIntervalsItemId = parms.get("settlement_item_id").toString();
        if (goBackward) {
            int per_page = Integer.parseInt(perPage);
            assertTrue(intervalsByItem.containsKey(lastGetIntervalsItemId), "Settlement item does not have any intervals!");
            int expectedSize = intervalsByItem.get(lastGetIntervalsItemId).size();
            int lastPage = expectedSize / per_page;
            if ((expectedSize % per_page) > 0) {
                lastPage++;
            }
            parms.put("page", lastPage);
        }
        request = RequestContainer.build().getEntities(SETTLEMENT_ITEM_INTERVALS).addQueryParms(parms);
        context.includeDeletedOpt.ifPresent(flag -> request.addQueryParm("include_deleted", flag));
        var expectedStatus = context.popExpectedStatus(200);
        var result = request.call(expectedStatus).getResponseEntity(GetSettlementItemIntervalsResult.class);
        if (expectedStatus.getCode() == 200) {
            LOG.info("{} settlement_item_intervals returned", result.data().size());
            request.getDataAsList().forEach(item -> {
                long epoch = ZonedDateTime.parse(item.get("interval_dttm_utc").toString()).toEpochSecond();
                assertFalse(returnedIntervals.containsKey(epoch));
                returnedIntervals.put(epoch, item);
            });
            while (goBackward ? result.meta().prev != null : result.meta().next != null) {
                request = RequestContainer.build().getWithUrl(SETTLEMENT_ITEM_INTERVALS, goBackward ? result.meta().prev : result.meta().next);
                result = request.call(expectedStatus).getResponseEntity(GetSettlementItemIntervalsResult.class);
                LOG.info("{} settlement_item_intervals returned", result.data().size());
                request.getDataAsList().forEach(item -> {
                    long epoch = ZonedDateTime.parse(item.get("interval_dttm_utc").toString()).toEpochSecond();
                    assertFalse(returnedIntervals.containsKey(epoch));
                    returnedIntervals.put(epoch, item);
                });
            }
        }
    }


    @Then("all of the returned intervals should have {word}={word}")
    public void allIntervalsShouldHaveDeleted(String property, String value) {
        assertFalse(returnedIntervals.isEmpty(), "No intervals returned!");
        long numMismatches = returnedIntervals.values().stream().filter(ri -> !value.equals(ri.getOrDefault(property, "missing!").toString())).count();
        assertEquals(0, numMismatches, "Mismatches found!");
    }


    @Then("the GET settlement_item_intervals response should contain only non-deleted intervals$")
    public void validateGetSettlementItemIntervals() {
        assertTrue(intervalsByItem.containsKey(lastGetIntervalsItemId), "Settlement item does not have any intervals!");
        validateGetSettlementItemIntervalsCommon(intervalsByItem.get(lastGetIntervalsItemId));
    }


    @Then("the GET settlement_item_intervals response should contain all of the intervals including deleted")
    public void validateGetSettlementItemIntervalsAll() {

        var expecteds = new TreeMap<Long, HashMap<String, Object>> () {{
            // We need to compose the expecteds in this order because new intervals will overwrite old deleted intervals with the same timestamp
            if (deletedIntervalsByItem.containsKey(lastGetIntervalsItemId)) {
                this.putAll(deletedIntervalsByItem.get(lastGetIntervalsItemId));
            }
            if (intervalsByItem.containsKey(lastGetIntervalsItemId)) {
                this.putAll(intervalsByItem.get(lastGetIntervalsItemId));
            }
        }};
        assertFalse(expecteds.isEmpty(), "Settlement item does not have any deleted intervals!");
        validateGetSettlementItemIntervalsCommon(expecteds);
    }


    private void validateGetSettlementItemIntervalsCommon(TreeMap<Long, HashMap<String, Object>> expecteds) {
        // 'expecteds' is a map of intervals (each interval being itself a map) indexed by epoch second
        LOG.info(String.format("GET /settlement_item_intervals returned %d intervals from %s to %s", returnedIntervals.size(), returnedIntervals.firstEntry().getValue().get("interval_dttm_utc"),
                returnedIntervals.lastEntry().getValue().get("interval_dttm_utc")));
        List<String> errors = new ArrayList<>() {{
            expecteds.keySet().forEach(key ->{
                if (!returnedIntervals.containsKey(key)) {
                    this.add(String.format("Response does not include expected interval for %d", key));
                }
                var actual = returnedIntervals.remove(key);
                var expected = expecteds.get(key);
                this.addAll(EntityValidator.build()
                        .withActual(request, actual)
                        .withExpected(expected)
                        .removeExpectedNulls()  // both v0 and v1 suppress null properties in GET response
                        .compare());
            });
            returnedIntervals.keySet().forEach(key -> this.add(String.format("Extra interval returned in response: %d", key)));
        }};
        assertTrue(errors.isEmpty(), String.join("\n", errors));
        LOG.info("GET /settlement_item_intervals response verified");
    }


    Optional<Integer> numExpectedLogEntriesOpt = Optional.empty();

    @Then("I expect the audit log to return a total of {int} entries")
    public void IExpectNumAuditLogEntries(int numEntries) {
        numExpectedLogEntriesOpt = Optional.of(numEntries);
    }


    @Then("no additional changes should be recorded in the {entityType} audit log")
    public void noAdditionalChangesInLog(EntityType entityType) {
        changesAreRecordedInAuditLog(entityType, 200, "forward");
    }


    @Then("changes should be recorded in the {entityType} audit log")
    public void changesAreRecordedInAuditLog(EntityType entityType) {
        changesAreRecordedInAuditLog(entityType, 200, "forward");
    }


    @Then("changes should be recorded in the {entityType} audit log for {word} with per_page: {int} direction: {word}")
    public void changesAreRecordedInAuditLogForItem(EntityType entityTypeParm, String tag, int perPage, String direction) {
        assertTrue(context.savedValues.containsKey(tag), "Saved values does not contain '" + tag + "'");
        var id = context.savedValues.get(tag);
        changesAreRecordedInAuditLogInternal(entityTypeParm, id, perPage, direction);
    }


    @Then("changes should be recorded in the {entityType} audit log with per_page: {int} direction: {word}")
    public void changesAreRecordedInAuditLog(EntityType entityType, int perPage, String direction) {
         var id = switch (entityType) {
            case SETTLEMENT -> context.lastSettlementId;
            case SETTLEMENT_ITEM, SETTLEMENT_ITEM_INTERVALS  -> context.lastSettlementItemId;
            default -> "missing";
        };
        changesAreRecordedInAuditLogInternal(entityType, id, perPage, direction);
    }


    private void changesAreRecordedInAuditLogInternal(EntityType entityTypeParm, String id, int perPage, String direction) {

        boolean goBackward = switch (direction) {
            case "forward" -> false;
            case "backward" -> true;
            default -> fail("Invalid direction specified");
        };

        final EntityType entityType = entityTypeParm;
        var expecteds = getExpectedAuditLog(entityType).getOrDefault(id, new ArrayList<>());

        HashMap<String, Object> parms = new HashMap<>() {{
            this.put("per_page", perPage);
            if (goBackward) {
                int lastPage = expecteds.size() / perPage;
                if ((expecteds.size() % perPage) > 0) {
                    lastPage++;
                }
                this.put("page", lastPage);
            }
        }};

        var errors = new ArrayList<String>();
        var actuals = new ArrayList<AuditLogEntry>() {{
            AuditLogResult auditLog = RequestContainer.build().getAuditLog(entityType, id).addQueryParms(parms).call().getResponseEntity(AuditLogResult.class);
            LOG.info("{} log entries returned. meta.total: {}  meta.page: {}", auditLog.data().length, auditLog.meta().total, auditLog.meta().page);
            assertEquals(parms.getOrDefault("page", 1), auditLog.meta().page, "Unexpected meta.page value!");
            assertEquals(perPage, auditLog.meta().per_page, "Unexpected meta.per_page value!");
            if (!numExpectedLogEntriesOpt.orElse(expecteds.size()).equals(auditLog.meta().total)) {
                errors.add(String.format("Unexpected meta.total value! Expected: %d  actual: %d", numExpectedLogEntriesOpt.orElse(expecteds.size()), auditLog.meta().total));
            }
            this.addAll(List.of(auditLog.data()));
            while (goBackward ? auditLog.meta().prev != null : auditLog.meta().next != null) {
                request = RequestContainer.build().getAuditLogUrl(entityType, goBackward ? auditLog.meta().prev : auditLog.meta().next);
                auditLog = request.call().getResponseEntity(AuditLogResult.class);
                LOG.info("{} log entries returned. meta.total: {}  meta.page: {}", auditLog.data().length, auditLog.meta().total, auditLog.meta().page);
                if (goBackward) {
                    // add this page to the beginning of the combined list
                    var temp = new ArrayList<>(List.of(auditLog.data()));
                    temp.addAll(this);
                    this.clear();
                    this.addAll(temp);
                } else {
                    // add this page to the end of the combined list
                    this.addAll(List.of(auditLog.data()));
                }
            }
        }};
        assertFalse(actuals.isEmpty(), "No audit log entries returned!");
        if (!numExpectedLogEntriesOpt.orElse(expecteds.size()).equals(actuals.size())) {
            errors.add(String.format("Unexpected number of entries returned! Expected: %d  actual: %d", numExpectedLogEntriesOpt.orElse(expecteds.size()), actuals.size()));
        }

        // Verify that log entries are returned in ascending order
        final ZonedDateTime[] dttmPrev = {ZonedDateTime.parse(actuals.get(0).audit_log_ts)};
        actuals.forEach(actual -> {
            var dttmCurr = ZonedDateTime.parse(actual.audit_log_ts);
            assertFalse(dttmCurr.isBefore(dttmPrev[0]), String.format("Audit log entries are not in ascending timestamp order! Previous: %s  Current: %s", dttmPrev[0], dttmCurr));
            dttmPrev[0] = dttmCurr;
        });

        // Verify entries
        var numVerified = new LongAdder();
        expecteds.forEach(expected -> {
            Optional<AuditLogEntry> actualOpt =
                    switch (entityType) {
                        case SETTLEMENT_ITEM_INTERVALS -> {
                            // Interval audit log only includes change_comments for bulk delete. Otherwise, do the best we can to find matching entries.
                            Optional<AuditLogEntry> tempOpt = actuals.stream()
                                    .filter(entry -> expected.changed_field.equals(entry.changed_field) && expected.change_comments != null && expected.change_comments.equals(entry.change_comments))
                                    .findFirst();
                            if (tempOpt.isPresent()) {
                                yield tempOpt;
                            } else {
                                yield actuals.stream()
                                        .filter(actual -> {
                                            if (expected.interval_dttm_utc.equals(actual.interval_dttm_utc)) {
                                                return true;
                                            } else {
                                                long expEpoch = ZonedDateTime.parse(expected.interval_dttm_utc).toEpochSecond();
                                                long actEpoch = ZonedDateTime.parse(actual.interval_dttm_utc).toEpochSecond();
                                                return expEpoch == actEpoch;
                                            }
                                        })
                                        .filter(actual -> expected.changed_field.equals(actual.changed_field))
                                        .filter(actual -> {
                                            if (expected.changed_field.endsWith("_value") || expected.changed_field.endsWith("_value_estimated") || expected.changed_field.endsWith("_kw") || expected.changed_field.equals("state_of_charge")) {
                                                Double expFrom = Double.parseDouble(expected.changed_from);
                                                Double expTo = Double.parseDouble(expected.changed_to);
                                                Double actFrom = Double.parseDouble(actual.changed_from);
                                                Double actTo = Double.parseDouble(actual.changed_to);
                                                return expFrom.equals(actFrom) && expTo.equals(actTo);
                                            } else {
                                                return expected.changed_from.equals(actual.changed_from) && expected.changed_to.equals(actual.changed_to);
                                            }
                                        })
                                        .findFirst();
                            }
                        }
                        default -> actuals.stream()
                                .filter(entry -> expected.changed_field.equals(entry.changed_field) && expected.change_comments.equals(entry.change_comments))
                                .findFirst();
                    };
            if (actualOpt.isEmpty()) {
                errors.add(String.format(String.format("Missing entry in audit log for '%s', '%s'", expected.interval_dttm_utc, expected.changed_field)));
            } else {
                AuditLogEntry actual = actualOpt.get();
                actuals.remove(actual);
                assertEquals(expected.changed_field, actual.changed_field, "Unexpected entry in audit log for 'changed_field'!");  // failsafe for code above
                switch (entityType) {
                    case SETTLEMENT, SETTLEMENT_ITEM -> {
                        assertEquals(expected.settlement_id, actual.settlement_id, "Unexpected entry in audit log for 'settlement_id'!");
                        assertEquals(expected.settlement_item_id, actual.settlement_item_id, "Unexpected entry in audit log for 'settlement_item_id'!");
                        assertEquals(expected.change_comments, actual.change_comments, "Unexpected entry in audit log for 'change_comments'!");
                        if (actual.changed_field.contains("dttm")) {  // date formats may differ
                            if (!Objects.equals(expected.changed_from, actual.changed_from)) { // null-safe comparison. Will also handle empty strings.
                                assertEquals(ZonedDateTime.parse(expected.changed_from), ZonedDateTime.parse(actual.changed_from), "Unexpected entry in audit log for 'changed_from'!");
                            }
                            if (!Objects.equals(expected.changed_to, actual.changed_to)) {
                                assertEquals(ZonedDateTime.parse(expected.changed_to), ZonedDateTime.parse(actual.changed_to), "Unexpected entry in audit log for 'changed_to'!");
                            }
                        } else {
                            assertEquals(expected.changed_from, actual.changed_from, "Unexpected entry in audit log for 'changed_from'!");
                            assertEquals(expected.changed_to, actual.changed_to, "Unexpected entry in audit log for 'changed_to'!");
                        }
                    }
                    case SETTLEMENT_ITEM_INTERVALS -> {
                        // per agreement with Yanis, change_comments are not recorded in audit log for PUT. However, they ARE recorded for DELETE.
                        // Also, we don't have to verify equality of changed_from and changed_to since we did that above.
                        assertEquals(expected.settlement_item_id, actual.settlement_item_id, "Unexpected entry in audit log for 'settlement_item_id'!");
                        if ("deleted".equals(expected.changed_field)) {
                            assertEquals(expected.change_comments, actual.change_comments, "Unexpected entry in audit log for 'change_comments'!");
                            assertEquals(expected.interval_dttm_utc, actual.interval_dttm_utc, "Unexpected entry in audit log for 'interval_dttm_utc'!");
                        }
                    }
                    default -> fail();
                }

                if (!Context.enocSession.isBlank()) {
                    try {
                        UUID uuid = UUID.fromString(actual.last_updated_by); // validate that value matches uuid schema
                    } catch (Exception e) {
                        fail(String.format("Invalid 'last_updated_by': '%s'!", actual.last_updated_by));
                    }
                }

                // Verify that log entry timestamp is within the expected range
                long actualTs = ZonedDateTime.parse(actual.audit_log_ts).toEpochSecond();
                long[] expTs = Arrays.stream(expected.audit_log_ts.split(",")).mapToLong(Long::parseLong).toArray();
                if (actualTs < expTs[0] || actualTs > expTs[1]) {
                    fail(String.format("audit_log_ts '%s' is outside the predicted range '%s' - '%s'!", actual.audit_log_ts, Utility.epochToString(expTs[0]), Utility.epochToString(expTs[1])));
                }
                numVerified.increment();
            }
        });

        if (!actuals.isEmpty()) {
            actuals.forEach(actual -> errors.add(String.format(String.format("Extra entry in audit log for '%s', '%s'", actual.interval_dttm_utc, actual.changed_field))));
        }
        assertTrue(errors.isEmpty(), String.join("\n", errors));

        LOG.info(String.format("Audit log verified for %d %s", numVerified.sum(), numVerified.sum() == 1 ? "entry" : "entries"));
    }


    @Then("no entries should be found in the {entityType} audit log")
    public void noEntriesFoundInAuditLog(EntityType entityType) {
        record MsgAndId(String msg, String id) {}
        MsgAndId msgAndId = switch (entityType ) {
            case SETTLEMENT -> new MsgAndId(String.format("no settlement audit logs found for settlement_id=%s", context.lastSettlementId), context.lastSettlementId);
            case SETTLEMENT_ITEM -> new MsgAndId(String.format("no settlement item audit logs found for settlement_item_id=%s", context.lastSettlementItemId), context.lastSettlementItemId);
            case SETTLEMENT_ITEM_INTERVALS -> new MsgAndId(String.format("no settlement item interval audit logs found for settlement_item_id=%s", context.lastSettlementItemId), context.lastSettlementItemId);
            default -> fail("Unsupported entity type");
        };
        HttpStatus expectedStatus = HttpStatus.build().withCode(404).withDetails(msgAndId.msg);
        RequestContainer.build().getAuditLog(entityType, msgAndId.id).call(expectedStatus);

        LOG.info(String.format("Audit log verified to have no entries for %s", msgAndId.id));
    }

    private boolean includeDuplicateFromFirstBatch = false;
    private boolean includeRandomItemId = false;
    private boolean includeRandomBadEnum = false;
    private boolean includeIntervalNotFound = false;
    private boolean patchOnlyOneField = false;
    private boolean includeDifferentFields = false;
    private int insertIntervalsBatchSize = 0;

    private double randomDouble(double constant) {
        return Double.parseDouble(String.format("%.2f", constant + (Math.random() * 10)));
    }

    private boolean randomBoolean() {
        return Math.random() >= 0.5;
    }


    @Given("I reset the intervals start date and flags")
    public void iResetIntervalsStartDateFlags() {
        // actually, the intervals start date will always be set to the first interval of the parent item
        includeDuplicateFromFirstBatch = false;
        includeRandomItemId = false;
        includeRandomBadEnum = false;
        patchOnlyOneField = false;
        includeDifferentFields = false;
        LOG.info("Flags reset");
    }


    @Given("I set the SQL INSERT intervals batch size to {int}")
    public void iSetInsertBatchSize(int size) {
        insertIntervalsBatchSize = size;
        LOG.info(String.format("SQL INSERT batch size set to %d", insertIntervalsBatchSize));
    }


    @Given("I want to include a duplicate interval from the first batch")
    public void iWantDuplicateInterval() {
        includeDuplicateFromFirstBatch = true;
        LOG.info(String.format("includeDuplicateFromFirstBatch set to %b", includeDuplicateFromFirstBatch));
    }


    @Given("I want to include an interval with a random settlement item id")
    public void iWantRandomItemId() {
        includeRandomItemId = true;
        LOG.info(String.format("includeRandomItemId set to %b", includeRandomItemId));
    }


    @Given("I want to include an interval with a bad enumeration")
    public void iWantRandomBadEnum() {
        includeRandomBadEnum = true;
        LOG.info(String.format("includeRandomBadEnum set to %b", includeRandomBadEnum));
    }


    @Given("I want to include an interval with an unknown timestamp")
    public void iWantUnknownTimestamp() {
        includeIntervalNotFound = true;
        LOG.info(String.format("includeIntervalNotFound set to %b", includeIntervalNotFound));
    }


    @Given("I only want to patch one field")
    public void iWantPatchOneField() {
        patchOnlyOneField = true;
        LOG.info(String.format("patchOnlyOneField set to %b", patchOnlyOneField));
    }


    @Given("I want to patch different fields")
    public void iWantPatchDifferentFields() {
        patchOnlyOneField = true;
        includeDifferentFields = true;
        LOG.info("patchOnlyOneField and includeDifferentFields set to true");
    }


    @When("I POST a set of {word} intervals starting with interval {int} for settlement_item_id {word}")
    public void iPostIntervalSetStarting(String numIntervalsParm, int startingInterval, String itemTag) {
        iPostIntervalSetInternal(numIntervalsParm, itemTag, startingInterval);
    }


    @When("I POST a set of {word} intervals for settlement_item_id {word}")
    public void iPostIntervalSet(String numIntervalsParm, String itemTag) {
        iPostIntervalSetInternal(numIntervalsParm, itemTag, 1);
    }


    private void iPostIntervalSetInternal(String numIntervalsParm, String itemTag, int startingInterval) {

        int numIntervals = switch (numIntervalsParm) {
            case "batchSize" -> insertIntervalsBatchSize;
            case "batchSizeMinusOne" -> insertIntervalsBatchSize - 1;
            case "batchSizePlusOne" -> insertIntervalsBatchSize + 1;
            default -> Integer.parseInt(numIntervalsParm);
        };
        assertTrue(numIntervals > 0, "You need to use the stepdef 'Given I set the SQL INSERT intervals batch size to n'");

        assertTrue(context.savedValues.containsKey(itemTag), "Saved values does not contain '" + itemTag + "'");
        String itemId = context.savedValues.get(itemTag);
        SettlementItem item = JSON.convertValue(context.savedSettlementItems.get(itemId), new TypeReference<>() {});
        var dttm = ZonedDateTime.parse(item.start_dttm_utc).plusMinutes(startingInterval * 5L);  // ITAPPSIT-3453 requires first interval to be greater than item start time

        var intervals = new ArrayList<HashMap<String, Object>>();
        {
            for (int i = 0; i < numIntervals; i++) {
                var interval = new HashMap<String, Object>();
                {
                    // Required properties
                    interval.put("settlement_item_id", itemId);
                    interval.put("interval_dttm_utc", dttm.format(DateTimeFormatter.ISO_INSTANT));
                    interval.put("interval_source", Math.random() > 0.5 ? "UTILITY" : "MEASURED");
                    interval.put("user_estimated", randomBoolean());
                    interval.put("utility_data", randomBoolean());
                    interval.put("relevant_indicator", randomBoolean());
                    // Optional properties
                    interval.put("vee_estimated", randomBoolean());
                    interval.put("metered_value", randomDouble(100));
                    interval.put("metered_uom", Math.random() > 0.5 ? "KW" : "KWH");
                    interval.put("baseline_value", randomDouble(50));
                    interval.put("baseline_uom", Math.random() > 0.5 ? "MW" : "AMPS");
                    interval.put("nomination_value", randomDouble(70));
                    interval.put("nomination_uom", Math.random() > 0.5 ? "KW" : "KWH");
                    interval.put("payment_nomination_value", randomDouble(120));
                    interval.put("payment_nomination_uom", Math.random() > 0.5 ? "MW" : "AMPS");
                    interval.put("revenue_value", String.format("%.2f", randomDouble(40)));
                    interval.put("currency", Math.random() > 0.5 ? "USD" : "TWD");
                    interval.put("payment_value", String.format("%.2f", randomDouble(10)));
                    interval.put("state_of_charge", Math.random());
                    interval.put("market_quality_good", randomBoolean());
                    interval.put("payment_penalty_input_value", randomDouble(20));
                    interval.put("payment_penalty_input_uom", Math.random() > 0.5 ? "GAL" : "GIGAJOULES");
                    interval.put("payment_penalty_value", String.format("%.2f", randomDouble(80)));
                    interval.put("payment_penalty_notes", Math.random() > 0.5 ? "abc" : "def");
                    interval.put("original_offer_kw", randomDouble(20));
                    interval.put("cleared_offer_kw", randomDouble(20));
                    interval.put("payment_value_estimated", String.format("%.2f", randomDouble(10)));
                    interval.put("revenue_value_estimated", String.format("%.2f", randomDouble(10)));
                    interval.put("realtime_availability_kw", randomDouble(20));
                    interval.put("is_armed", randomBoolean());
                    interval.put("realtime_availability_kw_override", randomDouble(20));
                    interval.put("payment_value_override", String.format("%.2f", randomDouble(10)));
                    dttm = dttm.plusMinutes(5);
                }
                intervals.add(interval);
            }
        }

        if (includeDuplicateFromFirstBatch) {
            intervals.add(intervals.get(0));  // this will cause a 400 from the POST
        }

        if (includeRandomItemId) {
            intervals.get(3).put("settlement_item_id", UUID.randomUUID());  // this will cause a 400 from the POST
        }

        if (includeRandomBadEnum) {
            intervals.get(2).put("interval_source", "FOO");  // this will cause a 400 from the POST
        }

        request = RequestContainer.build().submitIntervals(HttpOp.POST, intervals);
        var expectedStatus = context.popExpectedStatus(200);
        var response = request.call(expectedStatus).getResponseEntity(PostSettlementItemIntervalsResult.class);

        if (expectedStatus.getCode() == 200) {

            String expectedDetails = String.format("Successfully created %d settlement_item_intervals", intervals.size());
            HashMap<String, Object> responseMap = JSON.convertValue(response, new TypeReference<>() {});
            String actualDetails = responseMap.get("detail").toString();
            assertTrue(actualDetails.contains(expectedDetails), String.format("Unexpected status details in response: '%s'", actualDetails));

            // Save intervals for later verification
            if (!intervalsByItem.containsKey(itemId)) {
                intervalsByItem.put(itemId, new TreeMap<>());
            }
            intervals.forEach(iMap -> intervalsByItem.get(itemId).put(ZonedDateTime.parse(iMap.get("interval_dttm_utc").toString()).toEpochSecond(), iMap));
            LOG.info(String.format("Number of intervals successfully posted: %d from %s to %s", intervals.size(),
                    intervals.get(0).get("interval_dttm_utc"), intervals.get(intervals.size() - 1).get("interval_dttm_utc")));
        }
    }


    // Following stepdef is used for PUT and PATCH
    @When("I {httpOp} an update for {word} of the intervals with settlement_item_id {word}")
    public void iUpdateIntervalSet(HttpOp op, String updateAllOrSome, String itemTag) {
        
        boolean updateAll = switch (updateAllOrSome) {
            case "all" -> true;
            case "some" -> false;
            default -> fail();
        };
        assertTrue(context.savedValues.containsKey(itemTag), "Saved values does not contain '" + itemTag + "'");
        String itemId = context.savedValues.get(itemTag);
        assertTrue(intervalsByItem.containsKey(itemId), "No saved intervals for that item!");
        var intervals = intervalsByItem.get(itemId);
        assertFalse(intervals.isEmpty(), "No saved intervals for that item!");
        var expectedStatus = context.popExpectedStatus(200);

        var auditLog = getExpectedAuditLog(SETTLEMENT_ITEM_INTERVALS);
        if (!auditLog.containsKey(itemId)) {
            auditLog.put(itemId, new ArrayList<>());
        }
        var logList = auditLog.get(itemId);
        String predictedUpdatedTs = String.format("%d,%d", Context.crudEpoch, ZonedDateTime.now().toEpochSecond() + 5); // allow 10-sec slack

        var updatesTemp = new ArrayList<HashMap<String, Object>>();

        intervals.values().stream().filter(interval -> updateAll || Math.random() > 0.7).forEach(interval -> {

            // Make a copy of the existing interval
            var original = new HashMap<String, Object>() {{
                this.putAll(interval);
            }};

            if (patchOnlyOneField) {
                interval.put("metered_value", randomDouble(100));
            } else {
                interval.put("interval_source", Math.random() > 0.5 ? "UTILITY_TRANSFORM" : "DEROS");
                interval.put("user_estimated", !(boolean) interval.get("user_estimated"));
                interval.put("utility_data", !(boolean) interval.get("utility_data"));
                interval.put("relevant_indicator", !(boolean) interval.get("relevant_indicator"));
                // PUT/PATCH require change_comments, even though the comments aren't saved in the audit log
                interval.put("change_comments", String.format("Update interval %s", interval.get("interval_dttm_utc").toString()));
                // Optional properties
                interval.put("vee_estimated", !(boolean) interval.get("vee_estimated"));
                interval.put("metered_value", randomDouble(100));
                interval.put("metered_uom", Math.random() > 0.5 ? "BTU" : "CCF");
                interval.put("baseline_value", randomDouble(50));
                interval.put("baseline_uom", Math.random() > 0.5 ? "GIGAJOULES" : "HZ");
                interval.put("nomination_value", randomDouble(70));
                interval.put("nomination_uom", Math.random() > 0.5 ? "BTU" : "CCF");
                interval.put("payment_nomination_value", randomDouble(120));
                interval.put("payment_nomination_uom", Math.random() > 0.5 ? "GIGAJOULES" : "HZ");
                interval.put("revenue_value", String.format("%.2f", randomDouble(40)));
                interval.put("currency", Math.random() > 0.5 ? "THB" : "ZAR");
                interval.put("payment_value", String.format("%.2f", randomDouble(10)));
                interval.put("state_of_charge", Math.random());
                interval.put("market_quality_good", !(boolean) interval.get("market_quality_good"));
                interval.put("payment_penalty_input_value", randomDouble(10));
                interval.put("payment_penalty_input_uom", Math.random() > 0.5 ? "THERMS" : "TONS");
                interval.put("payment_penalty_value", String.format("%.2f", randomDouble(80)));
                interval.put("payment_penalty_notes", Math.random() > 0.5 ? "ghi" : "xyz");
                interval.put("original_offer_kw", randomDouble(20));
                interval.put("cleared_offer_kw", randomDouble(20));
                interval.put("payment_value_estimated", String.format("%.2f", randomDouble(10)));
                interval.put("revenue_value_estimated", String.format("%.2f", randomDouble(10)));
                interval.put("realtime_availability_kw", randomDouble(20));
                interval.put("is_armed", randomBoolean());
            }

            updatesTemp.add(interval);

            // Create audit log entries
            if (expectedStatus.getCode() == 200) {
                interval.keySet().stream().filter(key -> !"change_comments".equals(key)).forEach(key -> {
                    Object oldValue = original.get(key);
                    Object newValue = interval.get(key);
                    if (!Objects.equals(oldValue, newValue)) {
                        var entry = new AuditLogEntry()
                                .withSettlementItemId(itemId)
                                .withIntervalDttmUtc(interval.get("interval_dttm_utc").toString())
                                .withChangedField(key)
                                .withChangedFrom(oldValue == null ? "" : oldValue.toString())
                                .withChangedTo(newValue == null ? "" : newValue.toString())
                                .withAuditLogTs(predictedUpdatedTs);
                        logList.add(entry);
                    }
                });
            }
        });

        if (includeIntervalNotFound) {
            updatesTemp.get(2).put("interval_dttm_utc", "2024-03-05T08:00:00Z");
        }

        if (includeDuplicateFromFirstBatch) {
            updatesTemp.add(updatesTemp.get(0));  // this will cause a 400
        }

        if (includeRandomItemId) {
            updatesTemp.get(2).put("settlement_item_id", UUID.randomUUID());  // this will cause a 400
        }

        if (includeRandomBadEnum) {
            // this will cause a 400
            switch (op) {
                case PUT -> updatesTemp.get(3).put("interval_source", "FOO");
                case PATCH -> updatesTemp.get(3).put("metered_uom", "FOO");
                default -> fail();
            }
        }

        var updates = new ArrayList<HashMap<String, Object>>() {{
            AtomicBoolean switchFields = new AtomicBoolean(includeDifferentFields);
            updatesTemp.forEach(up -> {
                var update = new HashMap<String, Object>() {{
                    if (patchOnlyOneField) {
                        this.put("settlement_item_id", up.get("settlement_item_id"));
                        this.put("interval_dttm_utc", up.get("interval_dttm_utc"));
                        this.put("change_comments", up.get("change_comments"));
                        if (switchFields.get()) {
                            // Note: this will cause a 400 error
                            this.put("baseline_value", up.get("baseline_value"));
                            switchFields.set(false);
                        } else {
                            this.put("metered_value", up.get("metered_value"));
                        }
                    } else {
                        this.putAll(up);
                    }
                }};
                this.add(update);
            });
        }};

        if (expectedStatus.getCode() == 200) {
            // Verify that all updates have unique interval_dttm_utc values
            var uniqueIntervals = new HashSet<>();
            updates.forEach(update -> {
                String intervalDttm = update.get("interval_dttm_utc").toString();
                assertFalse(uniqueIntervals.contains(intervalDttm), String.format("Duplicate interval_dttm_utc value: %s. This error sometimes happens for unknown reason in automation code; re-run scenario.", intervalDttm));
                uniqueIntervals.add(intervalDttm);
            });
        }

        request = RequestContainer.build().submitIntervals(op, updates);

        var response = request.call(expectedStatus).getResponseEntity(PutPatchSettlementItemIntervalsResult.class);
        HashMap<String, Object> responseMap =  JSON.convertValue(response, new TypeReference<>() {});
        if (expectedStatus.getCode() == 200) {
            String expectedDetails = String.format("Successfully updated %d settlement_item_intervals", updates.size());
            String actualDetails = responseMap.get("detail").toString();
            assertTrue(actualDetails.contains(expectedDetails), String.format("Unexpected status details in response: '%s'", actualDetails));
            LOG.info(String.format("Number of intervals successfully updated: %d from %s to %s", updates.size(),
                    updates.get(0).get("interval_dttm_utc"), updates.get(updates.size() - 1).get("interval_dttm_utc")));
        }
    }

    @Then("the last settlement_item_interval should have the following properties:")
    public void lastIntervalShouldHaveProperties(io.cucumber.datatable.DataTable table) {
        // Make sure we have intervals for the last item
        assertTrue(intervalsByItem.containsKey(lastGetIntervalsItemId),
                "Settlement item does not have any intervals!");

        // intervalsByItem maps itemId -> TreeMap<epoch, Map<String,Object>>
        var intervalsForItem = intervalsByItem.get(lastGetIntervalsItemId);
        assertFalse(intervalsForItem.isEmpty(), "No intervals found for last settlement item!");

        // Last interval by time
        HashMap<String, Object> actual = intervalsForItem.lastEntry().getValue();

        Map<String, String> expected = table.asMap(String.class, String.class);

        expected.forEach((field, expectedStr) -> {
            Object actualVal = actual.get(field);
            assertNotNull(actualVal, "Field '" + field + "' is missing on last interval");
            assertEquals(
                    expectedStr,
                    actualVal.toString(),
                    String.format("Unexpected value for '%s'", field)
            );
        });
    }


    @Then("the last settlement_item_interval should not include override fields")
    public void lastIntervalShouldNotIncludeOverrideFields() {
        assertTrue(intervalsByItem.containsKey(lastGetIntervalsItemId),
                "Settlement item does not have any intervals!");

        var intervalsForItem = intervalsByItem.get(lastGetIntervalsItemId);
        assertFalse(intervalsForItem.isEmpty(), "No intervals found for last settlement item!");

        HashMap<String, Object> actual = intervalsForItem.lastEntry().getValue();

        Object raOverride = actual.get("realtime_availability_kw_override");
        assertNull(raOverride,
                "realtime_availability_kw_override should not be present on the last interval");

        Object pvOverride = actual.get("payment_value_override");
        assertNull(pvOverride,
                "payment_value_override should not be present on the last interval");
    }


    @Then("the last updated settlement_item_interval should have the following properties:")
    public void lastPatchedIntervalShouldHaveTheFollowingProperties(DataTable table) {
        // 1. Build expected from the DataTable only
        HashMap<String, Object> expected =
                new HashMap<>(table.asMap(String.class, Object.class));

        // 2. Take the last interval returned by the previous GET settlement_item_intervals
        assertFalse(returnedIntervals.isEmpty(), "No intervals returned!");
        HashMap<String, Object> actual = returnedIntervals.lastEntry().getValue();

        // Treat literal "null" in the feature file as Java null for these fields
        Stream.of("realtime_availability_kw_override", "payment_value_override")
                .forEach(f -> {
                    Object v = expected.get(f);
                    if (v != null && "null".equalsIgnoreCase(v.toString())) {
                        expected.put(f, null);
                    }
                });

        // 3. Compare only the keys present in 'expected'
        List<String> errors = new ArrayList<>();
        expected.forEach((field, expVal) -> {
            Object actVal = actual.get(field);
            String expStr = expVal == null ? null : expVal.toString();
            String actStr = actVal == null ? null : actVal.toString();
            if (!Objects.equals(expStr, actStr)) {
                errors.add(String.format(
                        "Unexpected value for '%s'. Expected: '%s' Actual: '%s'",
                        field, expStr, actStr
                ));
            }
        });

        errors.forEach(LOG::error);
        assertTrue(errors.isEmpty(), String.join("\n", errors));
    }

    @Then("the settlement_item_intervals audit log should contain override entries for the last interval")
    public void auditLogShouldContainOverrideEntriesForLastInterval() {
        // 1. Get the last interval we just verified
        assertFalse(returnedIntervals.isEmpty(), "No intervals returned!");
        var lastInterval = returnedIntervals.lastEntry().getValue();
        String itemId = String.valueOf(lastInterval.get("settlement_item_id"));
        String intervalTs = String.valueOf(lastInterval.get("interval_dttm_utc")); // e.g. 2023-09-05T14:05:00Z or .000Z

        // Normalize timestamp to instant (strip .000Z)
        String normTs = intervalTs.replace(".000Z", "Z");

        // 2. Call the audit API directly for that item
        var params = new HashMap<String, Object>();
        params.put("per_page", 200);

        var auditLog = RequestContainer.build()
                .getAuditLog(EntityType.SETTLEMENT_ITEM_INTERVALS, itemId)
                .addQueryParms(params)
                .call()
                .getResponseEntity(APIResponses.AuditLogResult.class);

        assertTrue(auditLog.data().length > 0, "No audit log entries returned for item " + itemId);

        // 3. Look for the two override entries by field + timestamp only
        boolean hasRealtimeOverride = Arrays.stream(auditLog.data())
                .anyMatch(e ->
                        "realtime_availability_kw_override".equals(e.changed_field)
                                && normTs.equals(e.interval_dttm_utc.replace(".000Z", "Z")));

        boolean hasPaymentOverride = Arrays.stream(auditLog.data())
                .anyMatch(e ->
                        "payment_value_override".equals(e.changed_field)
                                && normTs.equals(e.interval_dttm_utc.replace(".000Z", "Z")));

        List<String> errors = new ArrayList<>();
        if (!hasRealtimeOverride) {
            errors.add("Missing audit entry for realtime_availability_kw_override at " + normTs);
        }
        if (!hasPaymentOverride) {
            errors.add("Missing audit entry for payment_value_override at " + normTs);
        }

        errors.forEach(LOG::error);
        assertTrue(errors.isEmpty(), String.join("\n", errors));
    }

    @Given("I call GET settlement creator ping")
    public void iCallGetSettlementCreatorPing() {
        request = RequestContainer.build();
        request.endpoint = com.enernoc.bdap.model.Endpoint.GET_SETTLEMENT_CREATOR_PING;
        request.url = request.endpoint.baseUrl;

        var expectedStatus = context.popExpectedStatus(200);
        request.call(expectedStatus);

        if (expectedStatus.getCode() == 200) {
            LOG.info("GET settlement creator ping returned 200");
        }
    }


    @Then("the settlement inputs_available_until_dttm_utc field should be {word}")
    public void settlementInputsAvailableUntilFieldShouldBe(String expectedState) {
        assertTrue(context.savedSettlements.containsKey(context.lastSettlementId),
                "No saved settlement found for id " + context.lastSettlementId);

        HashMap<String, Object> settlement = context.savedSettlements.get(context.lastSettlementId);
        Object actualValue = settlement.get("inputs_available_until_dttm_utc");

        switch (expectedState.toLowerCase()) {
            case "null" -> {
                assertNull(actualValue,
                        "Expected inputs_available_until_dttm_utc to be null but was [" + actualValue + "]");
            }

            case "set" -> {
                assertNotNull(actualValue,
                        "Expected inputs_available_until_dttm_utc to be set but was null");

                String ts = actualValue.toString();
                assertFalse(ts.isBlank(),
                        "Expected inputs_available_until_dttm_utc to be set but it was blank");

                try {
                    // Validates ISO-8601 timestamp like 2026-06-17T14:27:02.620Z
                    OffsetDateTime.parse(ts);
                } catch (DateTimeParseException e) {
                    fail("inputs_available_until_dttm_utc has invalid timestamp format: [" + ts + "]", e);
                }
            }

            default -> fail("Expected state must be 'null' or 'set', but was: " + expectedState);
        }

        LOG.info("Verified inputs_available_until_dttm_utc is {}", expectedState);
    }

    @Then("the settlement_item is_inactive field should be {word}")
    public void settlementItemIsInactiveFieldShouldBe(String expectedState) {
        assertTrue(context.savedSettlementItems.containsKey(context.lastSettlementItemId),
                "No saved settlement_item found for id " + context.lastSettlementItemId);

        HashMap<String, Object> item = context.savedSettlementItems.get(context.lastSettlementItemId);
        Object actualValue = item.get("is_inactive");

        switch (expectedState.toLowerCase()) {
            case "null" -> assertNull(actualValue,
                    "Expected is_inactive to be null but was [" + actualValue + "]");

            case "true" -> {
                assertNotNull(actualValue,
                        "Expected is_inactive to be true but was null");
                assertEquals(Boolean.TRUE, actualValue,
                        "Expected is_inactive to be true but was [" + actualValue + "]");
            }

            case "false" -> {
                assertNotNull(actualValue,
                        "Expected is_inactive to be false but was null");
                assertEquals(Boolean.FALSE, actualValue,
                        "Expected is_inactive to be false but was [" + actualValue + "]");
            }

            default -> fail("Expected state must be 'null', 'true', or 'false', but was: " + expectedState);
        }

        LOG.info("Verified is_inactive is {}", expectedState);
    }
}
