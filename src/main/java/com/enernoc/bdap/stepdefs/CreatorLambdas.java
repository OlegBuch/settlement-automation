package com.enernoc.bdap.stepdefs;

import com.enernoc.bdap.shared.MomClient;
import com.enernoc.bdap.shared.MomClient.*;
import com.enernoc.bdap.shared.AwsSqs.*;
import com.enernoc.bdap.model.*;
import com.enernoc.bdap.model.Settlement.*;
import com.enernoc.bdap.shared.*;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.PropertyNamingStrategy;
import io.cucumber.datatable.DataTable;
import io.cucumber.java.en.And;
import io.cucumber.java.en.Given;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.time.*;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.stream.Collectors;

import static com.enernoc.bdap.model.EntityType.*;
import static com.enernoc.bdap.shared.Context.*;
import static java.time.ZoneOffset.UTC;
import static org.junit.jupiter.api.Assertions.*;


public class CreatorLambdas {

    private static final Logger LOG = LoggerFactory.getLogger("CreatorLambdas");
    private static final ObjectMapper JSON = new ObjectMapper().setPropertyNamingStrategy(PropertyNamingStrategy.SNAKE_CASE);
    private static final ObjectMapper JSONNoPNS = new ObjectMapper();
    private final Context context = Context.getContext();
    private final PostgresClient client = new PostgresClient(settlementSecretValues);
    private final PostgresClient metadataClient = new PostgresClient(metadataSecretValues);
    private final Utility utility = new Utility();
    private final ArrayList<RegistrationHistory> applicableHistories = new ArrayList<>();
    private Optional<SettlementCreatorSpec> creatorSpecOpt = Optional.empty();
    private final RuntimeException noSpecException = new RuntimeException("No scheduled settlement specification!");
    private final ArrayList<SettlementItem> expectedSettlementItems = new ArrayList<>();
    private List<HashMap<String, String>> actualRegistrationHistoryGaps = new ArrayList<>();
    private List<HashMap<String, Object>> inactiveSettlementItemIds = new ArrayList<>();
    private List<HashMap<String, Object>> activeSettlementItemIds = new ArrayList<>();


    private String toUtcString(String rawTimestamp) {
        if (rawTimestamp == null) return "<NULL>";
        try {
            return ZonedDateTime.parse(
                            rawTimestamp.replace(" ", "T"),
                            DateTimeFormatter.ISO_OFFSET_DATE_TIME)
                    .withZoneSameInstant(ZoneOffset.UTC)
                    .format(DateTimeFormatter.ISO_OFFSET_DATE_TIME);
        } catch (Exception e) {
            return rawTimestamp + " (unparseable)";
        }
    }

    @Given("I want to do a scheduled settlement for product: {word} type: {word} as of: {string}")
    public void iWantToCreateSettlement(String productName, String sType, String asof) {
        var spec = new SettlementCreatorSpec();
        {
            spec.productName = productName;
            spec.productRuleId = Utility.getProductRuleFromConfig(productName);
            spec.requestedType = sType;
            spec.asofDate = asof;
        }
        creatorSpecOpt = Optional.of(spec);
    }


    @When("I save the id for the product rule {word} for later use with the tag {word}")
    public void iSaveProductId(String ruleName, String tag) {
        context.savedValues.put(tag, Utility.getProductRuleFromConfig(ruleName));
    }


    @Given("I delete any pre-existing expected settlements from the database")
    public void iDeleteExistingTargetSettlements() throws Exception {
        record Parm(String entityId, Class<?> clazz) {
        }
        int numDeleted = 0;
        assertFalse(context.expectedSettlements.isEmpty(), "No expected settlements set up!!");
        for (Settlement s : context.expectedSettlements) {
            List<Settlement> settlements = client.getSettlementRows(s.product_id, s.settlement_type, s.start_dttm_utc, false);
            if (!settlements.isEmpty()) {
                assertEquals(1, settlements.size(), String.format("Expected 1 settlement in db but found %d!!", settlements.size()));
                var settlement = settlements.get(0);
                Parm parm = new Parm(settlement.settlement_id, APIResponses.DeleteSettlementResult.class);
                var request = RequestContainer.build().deleteEntity(EntityType.SETTLEMENT, parm.entityId);
                var entity = request.call(200).getResponseEntity(parm.clazz);
                assertTrue(request.responseMap.containsKey("detail"), "No detail field in response!");
                String actual = request.responseMap.get("detail").toString();
                LOG.info(String.format("Deleted existing settlement for product_id='%s' settlement_type='%s' start_dttm_utc='%s'",
                        settlement.product_id, settlement.settlement_type, settlement.start_dttm_utc));
                LOG.info(actual);
                numDeleted++;
            }
        }

        LOG.info(String.format("%d existing settlements deleted", numDeleted));
    }


    @Given("I delete all pre-existing expected settlements from the database")
    public void iDeleteAllExistingTargetSettlements() throws Exception {
        assertFalse(context.expectedSettlements.isEmpty(), "No expected settlements set up!!");

        int numDeleted = 0;
        List<String> errors = new ArrayList<>();

        for (Settlement s : context.expectedSettlements) {
            List<Settlement> settlements =
                    client.getSettlementRows(s.product_id, s.settlement_type, s.start_dttm_utc, false);

            if (settlements.size() > 1) {
                LOG.warn(String.format("Found %d settlements for product_id='%s' settlement_type='%s' start_dttm_utc='%s'; deleting all of them",
                        settlements.size(), s.product_id, s.settlement_type, s.start_dttm_utc));
            }

            for (Settlement existing : settlements) {
                try {
                    var request = RequestContainer.build()
                            .deleteEntity(EntityType.SETTLEMENT, existing.settlement_id);
                    request.call(200).getResponseEntity(APIResponses.DeleteSettlementResult.class);
                    assertTrue(request.responseMap.containsKey("detail"), "No detail field in response!");

                    LOG.info(String.format("Deleted settlement_id='%s' product_id='%s' settlement_type='%s' start_dttm_utc='%s'",
                            existing.settlement_id, existing.product_id, existing.settlement_type, existing.start_dttm_utc));
                    LOG.info(request.responseMap.get("detail").toString());
                    numDeleted++;
                } catch (AssertionError | RuntimeException e) {
                    errors.add(String.format("Failed to delete settlement_id='%s': %s",
                            existing.settlement_id, e.getMessage()));
                }
            }
        }

        LOG.info(String.format("%d existing settlements deleted", numDeleted));
        assertTrue(errors.isEmpty(), String.join("\n", errors));

        // Confirm nothing is left; allow for replica lag
        if (numDeleted > 0) {
            List<String> remaining = new ArrayList<>();
            for (int attempt = 1; attempt <= 5; attempt++) {
                remaining.clear();
                for (Settlement s : context.expectedSettlements) {
                    client.getSettlementRows(s.product_id, s.settlement_type, s.start_dttm_utc, false)
                            .forEach(r -> remaining.add(r.settlement_id));
                }
                if (remaining.isEmpty()) break;
                Thread.sleep(2000);
            }
            assertTrue(remaining.isEmpty(),
                    "Settlements still present after delete: " + remaining);
        }
    }

    @Given("I retrieve the existing matching settlement from the database")
    public void iRetrieveExistingMatchingSettlement() throws Exception {
        context.savedSettlementItems.clear();
        assertEquals(1, context.expectedSettlements.size(), "This stepdef only supports 1 settlement!!");
        var s = context.expectedSettlements.getFirst();
        List<Settlement> settlements = client.getSettlementRows(s.product_id, s.settlement_type, s.start_dttm_utc, false);
        assertEquals(1, settlements.size(), String.format("Expected 1 settlement in db but found %d!!", settlements.size()));
        var settlement = settlements.getFirst();
        HashMap<String, Object> settMap = JSON.convertValue(settlement, new TypeReference<>() {});
        context.savedSettlements.put(settlement.settlement_id, settMap);
        context.lastSettlementId = settlement.settlement_id;
        context.existingSettlement = settlement;
        LOG.info("Found existing settlement for {}.  Id: {}", s.start_dttm_utc, settlement.settlement_id);
    }


    @Given("I retrieve the existing matching settlements from the database")
    public void iRetrieveExistingMatchingSettlements() throws Exception {
        context.savedSettlementItems.clear();
        assertFalse(context.expectedSettlements.isEmpty(), "No expected settlements!!");
        for (var s : context.expectedSettlements) {
            List<Settlement> settlements = client.getSettlementRows(s.product_id, s.settlement_type, s.start_dttm_utc, false);
            assertEquals(1, settlements.size(), String.format("Expected 1 settlement in db but found %d!!", settlements.size()));
            var settlement = settlements.getFirst();
            HashMap<String, Object> settMap = JSON.convertValue(settlement, new TypeReference<>() {});
            context.savedSettlements.put(settlement.settlement_id, settMap);
            LOG.info("Found existing settlement for {}.  Id: {}", s.start_dttm_utc, settlement.settlement_id);
        }
    }


    @Given("I delete any pre-existing QAA settlements")
    public void iDeleteExistingSettlements() throws Exception {
        record Parm(String entityId, Class<?> clazz) {
        }
        int numDeleted = 0;
        var spec = creatorSpecOpt.orElseThrow(() ->noSpecException);
        List<Settlement> settlements = client.getQAASettlementRows(spec.productRuleId, spec.requestedType);
        for (Settlement s : settlements) {
            Parm parm = new Parm(s.settlement_id, APIResponses.DeleteSettlementResult.class);
            var request = RequestContainer.build().deleteEntity(EntityType.SETTLEMENT, parm.entityId);
            request.call(200).getResponseEntity(parm.clazz);
            assertTrue(request.responseMap.containsKey("detail"), "No detail field in response!");
            String actual = request.responseMap.get("detail").toString();
            LOG.info(String.format("Deleted existing settlement for product_id='%s' settlement_type='%s' start_dttm_utc='%s'",
                    s.product_id, s.settlement_type, s.start_dttm_utc));
            LOG.info(actual);
            numDeleted++;
        }
        if (numDeleted > 0) {
            Thread.sleep(3000);  // allow time to propagate to replica
        }

        LOG.info(String.format("%d existing settlements deleted", numDeleted));
    }


    private long lambdaInvokeEpoch = 0L;

    @Given("I generate the expected scheduled settlement(s)")
    public void iGenerateExpectedSchedSettlementForProductRule() throws Throwable {
        var spec = creatorSpecOpt.orElseThrow(() ->noSpecException);
        var expectedStatus = context.popExpectedStatus(200);
        var request = RequestContainer.build().getEntity(PRODUCT_RULE, spec.productRuleId);
        var rule = request.call(expectedStatus).getResponseEntity(APIResponses.GetProductRuleResult.class).data();
        var asofStartOfDay = ZonedDateTime.parse(spec.asofDate).withHour(0).withMinute(0).withSecond(0).withNano(0);
        var asofEndOfDay = asofStartOfDay.plusDays(1);

        // Fill out the settlement creator spec details
        HashMap<String, List<ProductRuleFragments.Detail>> details = new HashMap<>();
        for (var group : rule.getGroups()) {
            for (var fragment : group.getFragments()) {
                details.putAll(fragment.getDetailsForDateRange(asofStartOfDay, asofEndOfDay));
            }
        }
        {
            var sscs = details.getOrDefault("SCHEDULED_SETTLEMENT_CREATION_SCHEDULE_JSON", Collections.emptyList());
            assertEquals(1, sscs.size(), "Unexpected number of SCHEDULED_SETTLEMENT_CREATION_SCHEDULE_JSON");
            spec.scheduledSettlementCreationScheduleJson = JSONNoPNS.readValue(sscs.get(0).value, new TypeReference<>() {});
            sscs = details.getOrDefault("SCHEDULED_SETTLEMENT_CREATION_TYPE", Collections.emptyList());
            assertEquals(1, sscs.size(), "Unexpected number of SCHEDULED_SETTLEMENT_CREATION_TYPE");
            assertEquals(spec.requestedType, sscs.get(0).value, "Creation types don't match!");
            spec.scheduledSettlementCreationType = sscs.get(0).value;
            sscs = details.getOrDefault("SCHEDULED_SETTLEMENT_CREATION_TIMEZONE", Collections.emptyList());
            assertEquals(1, sscs.size(), "Unexpected number of SCHEDULED_SETTLEMENT_CREATION_TIMEZONE");
            spec.scheduledSettlementCreationTimezone = ZoneId.of(sscs.get(0).value);
            sscs = details.getOrDefault("CURRENCY", Collections.emptyList());
            assertEquals(1, sscs.size(), "Unexpected number of CURRENCY");
            spec.currency = sscs.get(0).value;
            sscs = details.getOrDefault("INTERVAL_LENGTH_MINUTES", Collections.emptyList());
            assertEquals(1, sscs.size(), "Unexpected number of INTERVAL_LENGTH_MINUTES");
            spec.intervalLengthMinutes = Integer.parseInt(sscs.get(0).value);
            sscs = details.getOrDefault("KW_SOURCE_SYSTEM", Collections.emptyList());
            assertEquals(1, sscs.size(), "Unexpected number of KW_SOURCE_SYSTEM");
            spec.kwSourceSystem = sscs.get(0).value;
            sscs = details.getOrDefault("PIPELINE_SEQUENCE", Collections.emptyList());
            assertEquals(1, sscs.size(), "Unexpected number of PIPELINE_SEQUENCE");
            spec.pipelineSequence = sscs.get(0).value;

            var calcStartList = details.getOrDefault("CALCS_EFFECTIVE_START_DTTM_UTC", Collections.emptyList());
            var calcEndList = details.getOrDefault("CALCS_EFFECTIVE_END_DTTM_UTC", Collections.emptyList());
            LOG.info("Product rule: {}  CALCS_EFFECTIVE_START_DTTM_UTC: {}  CALCS_EFFECTIVE_END_DTTM_UTC: {}",
                    spec.productRuleId, calcStartList.isEmpty() ? "<missing>" : calcStartList.getFirst().value, calcEndList.isEmpty() ? "<missing>" : calcEndList.getFirst().value);

            var createPortfolioItemsList = details.getOrDefault("CREATE_PORTFOLIO_ITEMS", Collections.emptyList());
            if (!createPortfolioItemsList.isEmpty()) {
                spec.createPortfolioItems = Boolean.parseBoolean(createPortfolioItemsList.get(0).value);
            } else {
                spec.createPortfolioItems = false; // Default to false if not present.
            }
        }

        // Determine if the asof date matches the schedule. Both are in UTC for MVP.
        {
            String asofMonthDayStr = asofStartOfDay.format(DateTimeFormatter.ofPattern("MMdd"));
            boolean matchesSchedule = spec.scheduledSettlementCreationScheduleJson.stream()
                    .anyMatch(sched -> {
                        if (sched.dates.contains(asofMonthDayStr)) {
                            spec.scheduledSettlementCreationPeriod = sched.creationPeriod;
                            return true;
                        }
                        return false;
                    });
            assertTrue(matchesSchedule, "asof date not found in SCHEDULED_SETTLEMENT_CREATION_SCHEDULE!");
            LOG.info("asof date matches rule schedule, settlement should be created");
        }

        // Build the expected scheduled settlement(s)
        context.expectedSettlements.clear();
        var endLocal = asofStartOfDay.withDayOfMonth(1).withZoneSameLocal(spec.scheduledSettlementCreationTimezone);
        switch (spec.scheduledSettlementCreationPeriod) {
            case "PREVIOUS_3_FULL_MONTHS" -> {
                for (int i = 0; i < 3; i++) {
                    var settlement = new ScheduledSettlement(rule, spec, endLocal);
                    context.expectedSettlements.add(settlement);
                    long diffInMinutes = Duration.between(ZonedDateTime.parse(settlement.start_dttm_utc), ZonedDateTime.parse(settlement.end_dttm_utc)).toMinutes();
                    LOG.info(String.format("Expected settlement for %s: Time range %s - %s spans %d intervals.", spec.scheduledSettlementCreationPeriod, settlement.start_dttm_utc, settlement.end_dttm_utc, diffInMinutes / spec.intervalLengthMinutes));
                    endLocal = endLocal.minusMonths(1);
                }
            }
            case "PREVIOUS_1_FULL_MONTH" -> {
                var settlement = new ScheduledSettlement(rule, spec, endLocal);
                context.expectedSettlements.add(settlement);
                long diffInMinutes = Duration.between(ZonedDateTime.parse(settlement.start_dttm_utc), ZonedDateTime.parse(settlement.end_dttm_utc)).toMinutes();
                LOG.info(String.format("Expected settlement for %s: Time range %s - %s spans %d intervals.", spec.scheduledSettlementCreationPeriod, settlement.start_dttm_utc, settlement.end_dttm_utc, diffInMinutes / spec.intervalLengthMinutes));
            }
            case "PREVIOUS_FULL_QUARTER" -> {
                var startLocal = endLocal.minusMonths(3);

                var startUtc = startLocal.withZoneSameInstant(UTC);
                var endUtc   = endLocal.withZoneSameInstant(UTC);

                var settlement = new ScheduledSettlement(rule, spec, endLocal);
                settlement.start_dttm_utc = startUtc.toString();
                settlement.end_dttm_utc   = endUtc.toString();

                context.expectedSettlements.add(settlement);

                long diffInMinutes = Duration.between(
                                ZonedDateTime.parse(settlement.start_dttm_utc),
                                ZonedDateTime.parse(settlement.end_dttm_utc))
                        .toMinutes();
                LOG.info(String.format(
                        "Expected settlement for %s: Time range %s - %s spans %d intervals.",
                        spec.scheduledSettlementCreationPeriod,
                        settlement.start_dttm_utc,
                        settlement.end_dttm_utc,
                        diffInMinutes / spec.intervalLengthMinutes));
                            }

            default -> fail("Unsupported scheduledSettlementCreationPeriod: " + spec.scheduledSettlementCreationPeriod);
        }
    }

    @Given("I verify that the expected settlement covers the {word}")
    public void iVerifyExpectedSettlementsCover(String period) {
        assertFalse(context.expectedSettlements.isEmpty(), "No expected settlements!");

        // Get the timezone from the spec (it was loaded from the product rule)
        var spec = creatorSpecOpt.orElseThrow(() -> noSpecException);
        ZoneId settlementZone = spec.scheduledSettlementCreationTimezone; // e.g., Australia/Brisbane

        context.expectedSettlements.forEach(s -> {
            // Parse in the configured timezone, not UTC
            var start = ZonedDateTime.parse(s.start_dttm_utc).withZoneSameInstant(settlementZone);
            var end = ZonedDateTime.parse(s.end_dttm_utc).withZoneSameInstant(settlementZone);

            var months = Period.between(start.toLocalDate(), end.toLocalDate()).getMonths();

            switch (period) {
                case "PREVIOUS_3_FULL_MONTHS" -> {
                    assertEquals(1, start.getDayOfMonth(), "Settlement start_dttm_utc is not the first day of the month!");
                    assertEquals(1, end.getDayOfMonth(), "Settlement end_dttm_utc is not the first day of the month!");
                    assertEquals(3, months, "Expected end month to be 3 months after start month!");
                }
                case "PREVIOUS_1_FULL_MONTH" -> {
                    assertEquals(1, start.getDayOfMonth(), "Settlement start_dttm_utc is not the first day of the month!");
                    assertEquals(1, end.getDayOfMonth(), "Settlement end_dttm_utc is not the first day of the month!");
                    assertEquals(1, months, "Expected end month to be 1 month after start month!");
                }
                case "PREVIOUS_FULL_QUARTER" -> {
                    assertEquals(1, start.getDayOfMonth(), "Settlement start_dttm_utc is not the first day of the month!");
                    assertEquals(1, end.getDayOfMonth(),   "Settlement end_dttm_utc is not the first day of the month!");

                    int totalMonths = (end.getYear() - start.getYear()) * 12
                            + (end.getMonthValue() - start.getMonthValue());
                    assertEquals(3, totalMonths, "Expected end month to be 3 months after start month for PREVIOUS_FULL_QUARTER!");
                }
                default -> fail(period + " not implemented!");
            }
        });

        LOG.info(String.format("Verified that expected settlement(s) cover %s", period));
    }



    @When("I invoke the settlement creator lambda")
    public void iInvokeSettlementCreator() throws Exception {

        var spec = creatorSpecOpt.orElseThrow(() ->noSpecException);
        AwsLambda lambda = new AwsLambda(Context.createSettlementArn);

        var parms = new HashMap<String, Object>();
        parms.put("product_ids", Collections.singletonList(spec.productRuleId));
        parms.put("as_of_date_utc", spec.asofDate);
        var payloadMap = new HashMap<String, HashMap<String, Object>>();
        payloadMap.put("detail", parms);
        String payload = JSON.writeValueAsString(payloadMap);
        var invokeDttm = ZonedDateTime.now().minusSeconds(1); // subtract a second in case our clock isn't synced to server
        lambdaInvokeEpoch = invokeDttm.toEpochSecond();
        LOG.info("Lambda payload: {}", payload);
        lambda.invoke(payload);
        LOG.info(String.format("Settlement creator lambda invoked at %s for product rule '%s'", Utility.normalizeZonedDateTime(invokeDttm), spec.productRuleId));
        Thread.sleep(10000);
    }


    @And("no settlements should have been created")
    public void noSettlementsShouldBeCreated() throws Exception {
        List<Settlement> settlements = client.getSettlementRowsCreatedAfter(Utility.epochToString(lambdaInvokeEpoch));
        List<String> errors = settlements.stream()
                .map(s -> {
                    var msgSuffix = String.format("product_id='%s' settlement_type='%s' start_dttm_utc='%s'", s.product_id, s.settlement_type, s.start_dttm_utc);
                    return String.format("The lambda execution created this settlement: %s", msgSuffix);
                }).toList();
        assertTrue(errors.isEmpty(), String.join("\n", errors));
        LOG.info("No settlements created");
    }


    @Then("the expected settlement(s) should be created and no others should be created")
    public void expectedSettlementShouldBeCreated() throws Exception {
        assertFalse(context.expectedSettlements.isEmpty(), "No expected settlements!");
        List<Settlement> newSettlements = client.getSettlementRowsCreatedAfter(Utility.epochToString(lambdaInvokeEpoch));
        HashMap<String, Settlement> newMap = newSettlements.stream().collect(Collectors.toMap(s -> s.settlement_id, s -> s, (a, b) -> b, HashMap::new));

        // Verify the expected settlements
        CrudSettlements crud = new CrudSettlements();
        for (ScheduledSettlement s : context.expectedSettlements) {
            List<Settlement> newList = newSettlements.stream()
                    .filter(dbs -> (dbs.product_id.equals(s.product_id) && dbs.settlement_type.equals(s.settlement_type) && dbs.start_dttm_utc.equals(s.start_dttm_utc)))
                    .toList();
            assertEquals(1, newList.size(), String.format("Expected 1 settlement in db but found %d!! product_id='%s' settlement_type='%s' start_dttm_utc='%s'",
                    newList.size(), s.product_id, s.settlement_type, s.start_dttm_utc));
            var newTarget = newList.get(0);
            var msgSuffix = String.format("settlement_id='%s' product_id='%s' settlement_type='%s' start_dttm_utc='%s' end_dttm_utc='%s'",
                    newTarget.settlement_id, newTarget.product_id, newTarget.settlement_type, newTarget.start_dttm_utc, newTarget.end_dttm_utc);

            // Add fields set by db to our expected settlement, then verify that GET settlement returns the expected settlement.
            s.settlement_id = newTarget.settlement_id;
            s.last_updated_by = newTarget.last_updated_by;
            s.last_updated_dttm_utc = newTarget.last_updated_dttm_utc;

            HashMap<String, Object> map = JSON.convertValue(s.convertToSimple(), new TypeReference<>() {});
            map.remove("settlement_items");
            map.remove("create_portfolio_items");

            String rawInputsAvailable = newTarget.inputs_available_until_dttm_utc;
            if (rawInputsAvailable != null) {
                // 1. Replace space with 'T' to make it closer to ISO-8601
                String normalized = rawInputsAvailable.replace(" ", "T");

                // 2. If the offset is missing the minutes (e.g., ends with "+02" or "-05"), append ":00"
                if (normalized.matches(".*[+-]\\d{2}$")) {
                    normalized = normalized + ":00";
                }

                // 3. Parse, convert to UTC, and format to match the API's 'Z' suffix
                java.time.ZonedDateTime zdt = java.time.ZonedDateTime.parse(normalized);
                String utcFormatted = zdt.withZoneSameInstant(java.time.ZoneOffset.UTC).toString();

                map.put("inputs_available_until_dttm_utc", utcFormatted);
            } else {
                map.put("inputs_available_until_dttm_utc", null);
            }

            context.savedSettlements.put(s.settlement_id, map);
            context.lastSettlementId = s.settlement_id;
            if (context.pipelineSettlementsProcessed.stream().map(ps -> ps.settlement_id).noneMatch(id -> id.equals(s.settlement_id))) {
                context.pipelineSettlementsProcessed.add(s);
            }
            crud.getSettlementShouldReturnNewEntity("new");
            LOG.info(String.format("Found new settlement for: %s", msgSuffix));
            newMap.remove(newTarget.settlement_id); // we're done with this settlement
        }

        // Verify no other settlements were created
        List<String> errors = newMap.keySet().stream().map(s -> String.format("The lambda execution unexpectedly created this settlement: %s", s)).toList();
        assertTrue(errors.isEmpty(), String.join("\n", errors));
    }


    @Given("I mark all of the expected settlements as QAA")
    public void iMarkExpectedSettlementsQAA() {
        assertFalse(context.expectedSettlements.isEmpty(), "No expected settlements!");
        var request = RequestContainer.build();
        for (var s : context.expectedSettlements) {
            s.settlement_subtype = "QAA";
            HashMap<String, Object> payload = JSON.convertValue(s.convertToSimple(), new TypeReference<>() {});
            Arrays.asList("deleted", "last_updated_by", "last_updated_dttm_utc", "change_comments", "settlement_items").forEach(payload::remove);
            var resp = request.submitEntity(HttpOp.PUT, SETTLEMENT, payload).call(200).getResponseEntity(APIResponses.PutSettlementItemResult.class);
            LOG.info(String.format("Settlement %s marked as QAA", s.settlement_id));
        }
    }


    List<PipelineStateItem> lastPipelineStateRows = new ArrayList<>();
    Set<String> prevPipelineRunIds = new HashSet<>();


    @Then("I retrieve all of the pipeline history rows for our saved settlement(s) up to pipeline_step: {word} status: {word}")
    public void iRetrievePSHSavedSettlement(String step, String status) throws Throwable {
        lastPipelineStateRows.clear();
        context.savedSettlements.values().stream().map(m -> m.get("settlement_id")).forEach(id -> {
            var rows = new ArrayList<PipelineStateItem>();
            boolean foundLastRow = false;
            var parms = new HashMap<String, Object>(Map.of("settlement_id", id));
            for (int i = 1; i < 36; i++) {
                var request = RequestContainer.build().getPipelineStateHistoryItem(parms);
                rows = request.call(200).getResponseEntity(APIResponses.GetPipelineStateResult.class).data();
                if (rows.stream().anyMatch(r -> step.equals(r.pipeline_step) && status.equals(r.status))) {
                    foundLastRow = true;
                    break;
                }
                try {
                    Thread.sleep(5000);
                } catch (Exception e) {
                    fail(e.toString());
                }
            }
            assertTrue(foundLastRow, String.format("Timeout waiting for pipeline history row. Settlement: %s  Step: %s  Status: %s", id, step, status));
            lastPipelineStateRows.addAll(rows);
        });
        LOG.info(String.format("%d pipeline history rows retrieved", lastPipelineStateRows.size()));
    }


    @Then("I timeout waiting for a pipeline history row for our saved settlement with pipeline_step: {word} status: {word}")
    public void iTimeoutPSHSavedSettlement(String step, String status) throws Throwable {
        assertEquals(1, context.savedSettlements.size(), "This stepdef only supports exactly one saved settlement!");
        String id = context.savedSettlements.values().stream().map(m -> m.get("settlement_id")).findFirst().orElseThrow().toString();
        lastPipelineStateRows.clear();
        var rows = new ArrayList<PipelineStateItem>();
        var parms = new HashMap<String, Object>(Map.of("settlement_id", id));
        for (int i = 1; i < 5; i++) {
            var request = RequestContainer.build().getPipelineStateHistoryItem(parms);
            rows = request.call(200).getResponseEntity(APIResponses.GetPipelineStateResult.class).data();
            if (rows.stream().anyMatch(r -> step.equals(r.pipeline_step) && status.equals(r.status))) {
                fail(String.format("Found unexpected pipeline history row. Settlement: %s  Step: %s  Status: %s", id, step, status));
            }
            try {
                Thread.sleep(5000);
            } catch (Exception e) {
                fail(e.toString());
            }
        }
        lastPipelineStateRows.addAll(rows);
        LOG.info(String.format("Timeout-out as expected waiting for specified row. %d pipeline history rows retrieved.", lastPipelineStateRows.size()));
    }


    @Then("I retrieve any new pipeline history rows for our saved settlement(s)")
    public void iLogNewPSHSavedSettlement() {
        prevPipelineRunIds.addAll(lastPipelineStateRows.stream().map(row -> row.pipeline_run_id).collect(Collectors.toSet()));
        lastPipelineStateRows.clear();
        context.savedSettlements.values().stream().map(m -> m.get("settlement_id")).forEach(id -> {
            var request = RequestContainer.build().getPipelineStateHistoryItem(new HashMap<>(Map.of("settlement_id", id)));
            var newRows = request.call(200).getResponseEntity(APIResponses.GetPipelineStateResult.class).data();
            lastPipelineStateRows.addAll(newRows.stream().filter(item -> !prevPipelineRunIds.contains(item.pipeline_run_id)).toList());
        });
        LOG.info(String.format("%d new pipeline history rows retrieved", lastPipelineStateRows.size()));
    }


    @Then("no pipeline history rows should have been retrieved")
    public void noPSHRetrieved() {
        if (!lastPipelineStateRows.isEmpty()) {
            LOG.info("Pipeline history rows returned!");
            iLogLastSetPSH();
            fail();
        }
        LOG.info("Verified that no pipeline history was retrieved");
    }


    @Given("I log the last set of pipeline history rows")
    public void iLogLastSetPSH() {
        // Build a sorted map of lastPipelineStateRows sorted by settlement_id:settlement_item_id:created_dttm_utc
        var sortedMap = lastPipelineStateRows.stream()
                .sorted(Comparator.comparing(row -> ZonedDateTime.parse(row.created_dttm_utc)))
                .collect(Collectors.toMap(row -> String.format("%s:%s:%s", row.settlement_id, row.settlement_item_id, row.created_dttm_utc), h -> h, (a, b) -> b, TreeMap::new));
        var logs = new ArrayList<String>();
        sortedMap.forEach((key, value) -> logs.add(String.format("%s %s", key, value.toLogString())));
        LOG.info("Last set of pipeline history rows (settlement_id:settlement_item_id:created_dttm_utc):\n" + String.join("\n", logs));
    }


    @Given("I verify that the latest {word} pipeline history rows all have a non-failure status")
    public void iVerifyPSHRowsHaveStatus(String step) {
        assertFalse(lastPipelineStateRows.isEmpty(), "No pipeline history rows retrieved!");
        var nonFailures = Arrays.asList("STARTED", "REQUESTED", "SUCCESS");
        var errors = lastPipelineStateRows.stream()
                .filter(row -> row.pipeline_step.startsWith(step) && !nonFailures.contains(row.status))
                .map(PipelineStateItem::toFormattedString)
                .collect(Collectors.toList());
        assertTrue(errors.isEmpty(), String.format("\nThe following rows have a failure status:\n%s", String.join("\n", errors)));
        LOG.info("Verified that latest pipeline history rows all have non-failure status");
    }


    @Given("I generate the expected settlement items for the saved scheduled settlement(s)")
    public void iGenerateExpectedSettlementItemsSavedSettlement() throws Throwable {
        assertFalse(context.expectedSettlements.isEmpty(), "Something's wrong! No expected saved settlements!");
        context.expectedSettlementItems.clear();
        for (var s : context.expectedSettlements) {
            context.expectedSettlementItems.addAll(generateExpectedItemsInternal(s.product_id, s.scspec.intervalLengthMinutes, s.start_dttm_utc, s.end_dttm_utc, s.scspec.createPortfolioItems));
        }
    }


    @Given("I generate the expected settlement items for product: {string} length: {int} start: {string} end: {string}")
    public void iGenerateExpectedSettlementItems(String productId, int intervalLengthMinutes, String stmStartStr, String stmEndStr) throws Throwable {
        // Pass true for backward compatibility with older tests using this step.
        context.expectedSettlementItems.clear();
        context.expectedSettlementItems.addAll(generateExpectedItemsInternal(productId, intervalLengthMinutes, stmStartStr, stmEndStr, true));
    }

    @Then("there should be {int} expected settlement item(s)")
    public void shouldBeNumExpectedItems(int numExpected) {
        assertEquals(numExpected, context.expectedSettlementItems.size(), "Unexpected number of expected settlement items generated!");
    }


    @Given("I log all the registration history rows for that product")
    public void iLogAllRegHistoryProduct() throws Throwable {
        var spec = creatorSpecOpt.orElseThrow(() ->noSpecException);
        var historyList = metadataClient.getActiveRegHistoryRowsForProductId(spec.productRuleId);
        assertFalse(historyList.isEmpty(), "No registration history rows returned!!");
        var rows = historyList.values().stream()
                .flatMap(history -> history.values().stream())
                .toList();
        LOG.info(String.format("Registration histories for %s product (%s):\n", spec.productName, spec.productRuleId)
                + rows.stream().map(r -> String.format("   History reg: %s  %s - %s  set: %s  port: %s  status: %s  deleted: %b",
                r.registration_id, r.effective_start_dttm_utc, r.effective_end_dttm_utc, r.registration_set_id, r.portfolio_id, r.status, r.deleted)).collect(Collectors.joining("\n")));
    }


    private ArrayList<SettlementItem> generateExpectedItemsInternal( String productId, int intervalLengthMinutes, String stmStartStr, String stmEndStr, boolean createPortfolioItems) throws Throwable {

        LOG.info("\n\nGenerating expected items from {} - {}", stmStartStr, stmEndStr);

        var expectedItems = new ArrayList<SettlementItem>();

        // Get all history rows for product
        var historyList = metadataClient.getActiveRegHistoryRowsForProductId(productId);
        assertFalse(historyList.isEmpty(), "No registration history rows returned!!");

        // Dejitter the rows
        for (var regHistory : historyList.entrySet()) {
            for (var entry : new HashSet<>(regHistory.getValue().entrySet())) {
                var row = entry.getValue();
                row.effective_start_dttm_utc = Utility.roundTimeUpToInterval(row.effective_start_dttm_utc, intervalLengthMinutes);
                row.effective_end_dttm_utc = Utility.roundTimeUpToInterval(row.effective_end_dttm_utc, intervalLengthMinutes);
                var startEpoch = ZonedDateTime.parse(row.effective_start_dttm_utc).toEpochSecond();
                var endEpoch = ZonedDateTime.parse(row.effective_end_dttm_utc).toEpochSecond();
                if (endEpoch <= startEpoch) {  // row no longer spans any time
                    regHistory.getValue().remove(entry.getKey());
                }
            }
        }

        // Select the rows for which we need to create items
        var stmStart = ZonedDateTime.parse(stmStartStr);
        var stmEnd = ZonedDateTime.parse(stmEndStr);

        applicableHistories.clear();
        {
            for (var regHistory : historyList.values()) {
                for (var row : regHistory.values()) {
                    var historyStart = ZonedDateTime.parse(row.effective_start_dttm_utc);
                    var historyEnd = ZonedDateTime.parse(row.effective_end_dttm_utc);
                    if (Utility.datesOverlap(historyStart, historyEnd, stmStart, stmEnd)) {
                        applicableHistories.add(row);
                        LOG.info(String.format("Applicable history:  id: %s  reg: %s   reg set: %s  portfolio: %s  effective: %s - %s",
                                row.id, row.registration_id, row.registration_set_id, row.portfolio_id, row.effective_start_dttm_utc, row.effective_end_dttm_utc));
                    }
                }
            }
        }

        // if product rule has CREATE_PORTFOLIO_ITEMS = true, then:
        // 1. Scan the applicableHistories list and create a list of unique portfolio ids found in the histories.
        // 2. For each unique portfolio id, create a portfolio item.

        final Map<String, SettlementItem> portfolioIdToItemMap = new HashMap<>();

        LOG.info(String.format("createPortfolioItems flag is set to: %b", createPortfolioItems));

        if (createPortfolioItems) {
            // 1. Find unique portfolio_ids from the filtered registration histories
            Set<String> uniquePortfolioIds = applicableHistories.stream()
                    .map(history -> history.portfolio_id)
                    .filter(Objects::nonNull)
                    .collect(Collectors.toSet());
            // Log for portfolio id
            LOG.info(String.format("Found %d unique portfolio IDs", uniquePortfolioIds.size()));
            uniquePortfolioIds.forEach(portfolioId ->
                    LOG.info(String.format("  Portfolio ID: %s", portfolioId))
            );

            // 2. Create a parent item for each unique portfolio_id
            uniquePortfolioIds.forEach(portfolioId -> {
                var portfolioItem = new SettlementItem();
                portfolioItem.settlement_level = "PORTFOLIO";
                portfolioItem.atlas_settlement_level_id = portfolioId;
                portfolioItem.settlement_level_id = portfolioId;
                // Set other common fields...
                portfolioItem.submitted_indicator = false;
                portfolioItem.asset_type = "LOAD";
                portfolioItem.settlement_item_status = "PRELIMINARY";
                portfolioItem.processing_status = null;
                // According to Nate, portfolio item covers the entire settlement period, even if child registrations change.
                portfolioItem.start_dttm_utc = stmStartStr;
                portfolioItem.end_dttm_utc = stmEndStr;
                portfolioItem.deleted = false;

                expectedItems.add(portfolioItem);
                portfolioIdToItemMap.put(portfolioId, portfolioItem);
            });
        }


        // Create the expected registration-level items.
        applicableHistories.forEach(row -> {
            var item = new SettlementItem();
            {
                item.settlement_level = "REGISTRATION";
                item.submitted_indicator = false;
                item.asset_type = "LOAD";
                item.settlement_item_status = "PRELIMINARY";
                item.start_dttm_utc = Utility.getMaximumDate(stmStartStr, row.effective_start_dttm_utc);
                item.end_dttm_utc = Utility.getMinimumDate(stmEndStr, row.effective_end_dttm_utc);
                item.atlas_settlement_level_id = row.registration_id;
                item.settlement_level_id = row.registration_id;
                item.ecrm_account_id = row.ecrm_account_id;
                item.ecrm_site_id = row.ecrm_site_id;
                item.ecrm_opportunity_id = row.ecrm_opportunity_id;
                item.processing_status = row.needs_manual_fix ? "MISSING_META" : null;
                item.deleted = false;
                item.registration_set_id = row.registration_set_id;

                // if product rule has CREATE_PORTFOLIO_ITEMS = true, then set item.master_settlement_item_id = portfolio id for that registration
                if (createPortfolioItems && row.portfolio_id != null) {
                    SettlementItem parentPortfolioItem = portfolioIdToItemMap.get(row.portfolio_id);
                    if (parentPortfolioItem != null) {
                        item.master_settlement_item_id = parentPortfolioItem.atlas_settlement_level_id;
                        item.portfolio_id = row.portfolio_id;
                    }
                }
            }
            expectedItems.add(item);
        });

        //new log for portfolio ids
        LOG.info(String.format("Settlement start/end: %s - %s", stmStart, stmEnd));
        if (applicableHistories.isEmpty() && expectedItems.isEmpty()) {
            LOG.info(String.format("No matching registration histories for product (%s), no items expected", productId));
        } else {
            expectedItems.forEach(item -> {
                if ("PORTFOLIO".equals(item.settlement_level)) {
                    LOG.info(String.format("   Item Portfolio: %s  %s - %s",
                            item.settlement_level_id, item.start_dttm_utc, item.end_dttm_utc));
                } else {
                    LOG.info(String.format("   Item Reg: %s  Reg set: %s  Master: %s %s - %s",
                            item.atlas_settlement_level_id, item.registration_set_id, item.master_settlement_item_id, item.start_dttm_utc, item.end_dttm_utc));
                }
            });
            LOG.info(String.format("Total expected settlement items: %d", expectedItems.size()));
        }
        return expectedItems;
    }


    @Then("{int} applicable registration history row(s) should be returned")
    public void applicableHistoriesReturned(int numExpected) {
        assertEquals(numExpected, applicableHistories.size(), "Unexpected number of applicable histories returned!");
    }


    @Then("no settlement items should have been created")
    public void noItemsShouldBeCreated() {
        assertFalse(lastPipelineStateRows.isEmpty(), "Empty pipeline history returned!");
        var newItemIds = lastPipelineStateRows.stream()
                .filter(row -> row.settlement_item_id != null)
                .map(row -> row.settlement_item_id)
                .collect(Collectors.toSet());
        var errors = new ArrayList<String>();
        newItemIds.forEach(id -> errors.add(String.format("Unexpected item in pipeline history. settlement_item_id: %s ", id)));
        assertTrue(errors.isEmpty(), String.join("\n", errors));
        LOG.info("As expected, no new items created");
    }


    @Then("no new settlement items should have been created")
    public void noNewItemsShouldBeCreated() {
        assertFalse(lastPipelineStateRows.isEmpty(), "Empty pipeline history returned!");
        assertFalse(context.expectedSettlementItems.isEmpty(), "No expected items!");
        var expectedIds = context.expectedSettlementItems.stream().map(item -> item.settlement_item_id).toList();
        var newItems = new ArrayList<>(lastPipelineStateRows.stream()
                .filter(row -> row.settlement_item_id != null && !expectedIds.contains(row.settlement_item_id))
                .filter(row -> "STARTED".equals(row.status))
                .toList());
        var errors = new ArrayList<String>();
        newItems.forEach(newItem -> errors.add(String.format("Unexpected item in pipeline history. settlement_item_id: %s ", newItem.settlement_item_id)));
        assertTrue(errors.isEmpty(), String.join("\n", errors));
        LOG.info("As expected, no new items created");
    }


    @Then("only the {int} expected settlement item(s) should have been created")
    public void verifyExpectedItemsCreated(int numExpected) {
        verifyExpectedItemsCreatedInternal(Optional.of(numExpected), context.expectedSettlementItems);
    }


    @Then("only the {int} saved settlement items should have been created")
    public void verifySavedItemsCreated(int numExpected) {
        verifyExpectedItemsCreatedInternal(Optional.of(numExpected), context.expectedSettlementItemsSaved);
    }


    @Then("the expected settlement item(s) should have been created")
    public void verifyExpectedItemsCreated2() {
        verifyExpectedItemsCreatedInternal(Optional.empty(), context.expectedSettlementItems);
    }


    private void verifyExpectedItemsCreatedInternal(Optional<Integer> numExpectedOpt, ArrayList<SettlementItem> expectedItems) {

        int saveExpectedSize = expectedItems.size();
        numExpectedOpt.ifPresent(numExpected -> {
            assertTrue(numExpected > 0, "Use the stepdef 'no settlement items should have been created'");
            assertEquals(numExpected, expectedItems.size(), "Unexpected number of expected items!");
        });
        assertFalse(lastPipelineStateRows.isEmpty(), "Empty pipeline history returned!");

        // Update the expected items with the actual settlement id
        assertEquals(1, context.savedSettlements.size(), "This stepdef only supports one settlement!");
        String settlementId = context.savedSettlements.values().iterator().next().get("settlement_id").toString();
        expectedItems.forEach(item -> item.settlement_id = settlementId);

        var expecteds = new ArrayList<>(expectedItems);  // We will remove items from this list as they are verified
        var actuals = new ArrayList<SettlementItem>();
        {
            // Get the unique settlement_item_ids and retrieve each item.
            var settlementItemIds = lastPipelineStateRows.stream()
                    .filter(row -> row.settlement_item_id != null)
                    .map(row -> row.settlement_item_id)
                    .collect(Collectors.toSet());
            settlementItemIds.forEach(id -> {
                var props = RequestContainer.build().getEntity(SETTLEMENT_ITEM, id).call().getDataAsList();
                assertEquals(1, props.size(), String.format("Unexpected number of items returned for pipeline state settlement_item_id %s", id));
                SettlementItem item = JSON.convertValue(props.getFirst(), new TypeReference<>() {});
                actuals.add(item);
                context.savedSettlementItems.put(props.getFirst().get("settlement_item_id").toString(), props.getFirst());
            });
        }

        // Build a map from portfolio atlas_settlement_level_id to real settlement_item_id
        Map<String, String> actualPortfolioIdToRealItemId = actuals.stream()
                .filter(item -> "PORTFOLIO".equals(item.settlement_level))
                .collect(Collectors.toMap(
                        item -> item.atlas_settlement_level_id,  // portfolio_id
                        item -> item.settlement_item_id
                ));

        // Patch expected portfolio items to have the real generated settlement_item_id
        for (SettlementItem expected : expectedItems) {
            if ("PORTFOLIO".equals(expected.settlement_level)) {
                String actualId = actualPortfolioIdToRealItemId.get(expected.atlas_settlement_level_id);
                expected.settlement_item_id = Objects.requireNonNullElseGet(actualId, () -> String.format("No PORTFOLIO item found for portfolio_id %s", expected.atlas_settlement_level_id));
            }
        }

        // Patch expected registration items' master_settlement_item_id to reference the real portfolio item UUID
        for (SettlementItem expected : expectedItems) {
            if ("REGISTRATION".equals(expected.settlement_level) && expected.master_settlement_item_id != null) {
                String actualId = actualPortfolioIdToRealItemId.get(expected.master_settlement_item_id);
                // The error will be included when we compare actual vs. expected below
                expected.master_settlement_item_id = Objects.requireNonNullElseGet(actualId, () -> String.format("No PORTFOLIO item found for portfolio_id %s", expected.master_settlement_item_id));
            }
        }

        var errors = new ArrayList<String>();
        for (SettlementItem expected : expectedItems) {
            Optional<SettlementItem> actualOpt = actuals.stream()
                    .filter(actual -> expected.atlas_settlement_level_id.equals(actual.atlas_settlement_level_id))
                    .filter(actual -> ZonedDateTime.parse(expected.start_dttm_utc).equals(ZonedDateTime.parse(actual.start_dttm_utc)))
                    .findFirst();
            if (actualOpt.isEmpty()) {
                errors.add(String.format("Expected item not in pipeline history. Reg: %s  start_dttm_utc: %s", expected.atlas_settlement_level_id, expected.start_dttm_utc));
                continue;
            }
            var actual = actualOpt.get();
            expected.settlement_item_id = actual.settlement_item_id;
            expected.last_updated_by = actual.last_updated_by;
            expected.last_updated_dttm_utc = actual.last_updated_dttm_utc;
            HashMap<String, Object> expMap = JSON.convertValue(expected, new TypeReference<>() {});
            HashMap<String, Object> actMap = JSON.convertValue(actual, new TypeReference<>() {});
            String itemType = "PORTFOLIO".equals(expected.settlement_level) ? "Portfolio" :
                    "REGISTRATION".equals(expected.settlement_level) ? "Reg" : expected.settlement_level;

            var diffErrors = new ArrayList<String>();
            var allKeys = new HashSet<String>();
            allKeys.addAll(expMap.keySet());
            allKeys.addAll(actMap.keySet());

            for (String key : allKeys) {
                Object expValue = expMap.get(key);
                Object actValue = actMap.get(key);

                if (!Objects.equals(expValue, actValue)) {
                    diffErrors.add(String.format("Item %s:  Mismatched field '%s': expected='%s', actual='%s'",
                            expected.settlement_item_id, key, expValue, actValue));
                }
            }

            if (diffErrors.isEmpty()) {
                LOG.info(String.format("Expected %s item verified. Item id: %s   Master id: %s  Atlas id: %s  %s - %s",
                        itemType,
                        expected.settlement_item_id,
                        expected.master_settlement_item_id,
                        expected.atlas_settlement_level_id,
                        expected.start_dttm_utc,
                        expected.end_dttm_utc
                ));
            } else {
                errors.addAll(diffErrors);
            }

            expecteds.remove(expected);
            actuals.remove(actual);
        }
        if (!expecteds.isEmpty()) {
            errors.add("Something's wrong! Expecteds not empty!");
        }
        actuals.forEach(actual -> errors.add(String.format("Unexpected item in pipeline history. settlement_item_id: %s ", actual.settlement_item_id)));
        assertTrue(errors.isEmpty(), String.join("\n", errors));
        LOG.info(String.format("%d expected items verified", saveExpectedSize));
    }


    @Given("I save the expected settlement items for later verification")
    public void iSaveExpItemsForLater() {
        context.expectedSettlementItemsSaved.addAll(context.expectedSettlementItems);
        LOG.info(String.format("%d items saved for later, for a total of %d saved", context.expectedSettlementItems.size(), context.expectedSettlementItemsSaved.size()));
    }


    private String lastPipelineRunId;
    private CreateIntervalsSqsInputMessage lastIntervalsInputMsg;
    private SortedMap<ZonedDateTime, CreateIntervalsSqsOutputMessage> lastIntervalsOutputMsgs = new TreeMap<>();


    @When("I send a message to the SQS DLQ for {word} with the status {string}")
    public void iSendSQSDLQMessage(String queue, String status) throws Exception {

        var msg = new AwsSqs.SqsMessageCommon();
        msg.action = "RUN_PIPELINE";
        msg.settlementId = "123";
        msg.productId = "456";
        msg.status = status;
        msg.step = "CREATOR_FIRST";
        msg.caller = "CREATOR";
        msg.pipelineRunId = "12345";

        String url = switch (queue) {
            case "settlement_output" -> Context.createSettlementSQSOutputDLQUrl;
            case "items_input" -> Context.createItemsSQSInputDLQUrl;
            case "intervals_output" -> Context.createIntervalsSQSOutputDLQUrl;
            default -> fail("Unknown queue");
        };
        AwsSqs client = AwsSqs.build().withUrl(url);
        String msgString = JSON.writeValueAsString(msg);
        if (url.endsWith(".fifo")) {
            client.sendSqsMessageToFifoQueue(msgString);
        } else {
            client.sendSqsMessage(msgString);
        }

    }


    @When("I run a stress test for the SQS DLQs sending {int} messages to each DLQ")
    public void iRunDLQStressTest(int numMsgs) throws Exception {

        var msg = new AwsSqs.SqsMessageCommon();
        msg.action = "RUN_PIPELINE";
        msg.settlementId = "123";
        msg.productId = "456";
        msg.status = "DLQStressTest";
        msg.step = "CREATOR_FIRST";
        msg.caller = "CREATOR";

        var stlOutputClient = AwsSqs.build().withUrl(Context.createSettlementSQSOutputDLQUrl);
        var itemsInputClient = AwsSqs.build().withUrl(Context.createItemsSQSInputDLQUrl);
        var intervalsOutputClient = AwsSqs.build().withUrl(Context.createIntervalsSQSOutputDLQUrl);
        for (int counter = 1; counter <= numMsgs; counter++) {
            msg.pipelineRunId = String.format("SettlementOutputDLQ: %d", counter);
            stlOutputClient.sendSqsMessageToFifoQueue(JSON.writeValueAsString(msg));

            msg.pipelineRunId = String.format("ItemsInputDLQ: %d", counter);
            itemsInputClient.sendSqsMessageToFifoQueue(JSON.writeValueAsString(msg));

            msg.pipelineRunId = String.format("IntervalsOutputDLQ: %d", counter);
            intervalsOutputClient.sendSqsMessage(JSON.writeValueAsString(msg));
        }

        LOG.info(String.format("%d sent to each DLQ", numMsgs));

    }


    @When("I send a message to the SQS Intervals Input Queue using the saved item$")
    public void iSendSqsMsgIntervalsInput() throws Exception {
        iSendSqsMsgIntervalsInputInternal(new HashMap<>());
    }


    @When("I send a message to the SQS Intervals Input Queue using the saved item and these properties:")
    public void iSendSqsMsgIntervalsInputWithOverrides(DataTable data) throws Exception {
        iSendSqsMsgIntervalsInputInternal(new HashMap<>(data.asMap(String.class, Object.class)));
    }


    private void iSendSqsMsgIntervalsInputInternal(HashMap<String, Object> overrides) throws Exception {
        AwsSqs client = AwsSqs.build().withUrl(Context.createIntervalsSQSInputUrl);

        lastIntervalsInputMsg = new CreateIntervalsSqsInputMessage();

        var map = context.savedSettlementItems.entrySet().stream().findFirst().orElseThrow();
        SettlementItem item = JSON.convertValue(map.getValue(), new TypeReference<>() {});

        // Need to ensure that start and end dttms are in exact format needed for MOM
        item.start_dttm_utc = ZonedDateTime.parse(item.start_dttm_utc).format(fullDttmFormat);
        item.end_dttm_utc = ZonedDateTime.parse(item.end_dttm_utc).format(fullDttmFormat);

        // Set default properties
        lastIntervalsInputMsg.action = "RUN_TASK";
        lastIntervalsInputMsg.status = "REQUESTED";
        lastIntervalsInputMsg.step = "CREATOR_REST";
        lastIntervalsInputMsg.settlementId = item.settlement_id;
        lastIntervalsInputMsg.settlementItemId = item.settlement_item_id;
        lastIntervalsInputMsg.productId = UUID.randomUUID().toString();
        lastPipelineRunId = UUID.randomUUID().toString();
        lastIntervalsInputMsg.pipelineRunId = lastPipelineRunId;
        lastIntervalsInputMsg.caller = "CREATOR";
        lastIntervalsInputMsg.extras = new Extras();
        lastIntervalsInputMsg.extras.settlementItem = item;
        lastIntervalsInputMsg.extras.currency = "USD";
        lastIntervalsInputMsg.extras.intervalLengthMinutes = 15;
        lastIntervalsInputMsg.extras.productRuleIntervalsKwSourceSystem = "MOM";

        // Apply property overrides, if any
        if (!overrides.isEmpty()) {
            utility.replaceParmValues(overrides);
            overrides.forEach((key, value) -> {
                String valStr = value.toString();
                switch (key) {
                    case "atlas_settlement_level_id" -> item.atlas_settlement_level_id = valStr;
                    case "product_id" -> lastIntervalsInputMsg.productId = valStr;
                    case "currency" -> lastIntervalsInputMsg.extras.currency = valStr;
                    case "interval_length_minutes" -> lastIntervalsInputMsg.extras.intervalLengthMinutes = Integer.parseInt(valStr);
                    case "product_rule_intervals_kw_source_system" -> lastIntervalsInputMsg.extras.productRuleIntervalsKwSourceSystem = valStr;
                    case "end_dttm_utc" -> {
                        lastIntervalsInputMsg.extras.settlementItem.end_dttm_utc = ZonedDateTime.parse(valStr).format(fullDttmFormat);
                        map.getValue().put("end_dttm_utc", valStr);
                    }
                    default -> fail("Unknown property: " + key);
                }
            });
        }
        String msgString = JSON.writeValueAsString(lastIntervalsInputMsg);

        client.sendSqsMessage(msgString);
        LOG.info(String.format("createIntervalsSQSInput message sent with pipeline_run_id: %s  settlement_item_id: %s", lastPipelineRunId, item.settlement_item_id));
    }


    @Given("I change the settlementId on the saved item to a random uuid")
    public void iChangeSettlementIdToRandomUuid() {
        var map = context.savedSettlementItems.entrySet().stream().findFirst().get();
        map.getValue().put("settlement_id", UUID.randomUUID().toString());
    }


    @Given("I change the settlementItemId on the saved item to a random uuid")
    public void iChangeSettlementItemIdToRandomUuid() {
        var map = context.savedSettlementItems.entrySet().stream().findFirst().get();
        map.getValue().put("settlement_item_id", UUID.randomUUID().toString());
    }


    @When("I receive a message from the SQS Intervals Output Queue")
    public void iReceiveSqsMsgIntervalsOutput() throws Exception {
        lastIntervalsOutputMsgs.clear();
        AwsSqs client = AwsSqs.build().withUrl(Context.createIntervalsSQSOutputUrl);
        var msgs = client.getSqsMessagesForPipelineRunId(lastPipelineRunId, 60, AwsSqs.CreateIntervalsSqsOutputMessage.class);
        LOG.info(String.format("%d createIntervalsSQSOutput messages received for pipeline run id: %s", msgs.size(), lastPipelineRunId));
        assertEquals(1, msgs.size(), "Exactly one output message expected!");
        lastIntervalsOutputMsgs.putAll(msgs);
    }


    @Then("the SQS Intervals Output message should match:")
    public void sqsIntervalsOutputMessageShouldMatch(DataTable data) throws Throwable {
        assertEquals(1, lastIntervalsOutputMsgs.size(), "Exactly one output message expected!");
        var msg = lastIntervalsOutputMsgs.get(lastIntervalsOutputMsgs.firstKey());
        LOG.info(JSON.writeValueAsString(msg));
        // First, validate the expected input properties
        assertEquals(lastIntervalsInputMsg.pipelineRunId, msg.pipelineRunId, "Message pipelineRunId does not match!");
        assertEquals(lastIntervalsInputMsg.settlementId, msg.settlementId, "Message settlementId does not match!");
        if (!"<any>".equals(lastIntervalsInputMsg.settlementItemId)) {
            assertEquals(lastIntervalsInputMsg.settlementItemId, msg.settlementItemId, "Message settlementItemId does not match!");
        }
        assertEquals(lastIntervalsInputMsg.productId, msg.productId, "Message productId does not match!");
        assertEquals(lastIntervalsInputMsg.caller, msg.caller, "Message caller property does not match!");
        assertEquals(lastIntervalsInputMsg.step, msg.step, "Message caller property does not match!");
        data.asMap().forEach((key, value) -> {
            switch (key) {
                case "action" -> assertEquals(value, msg.action, "Message action does not match!");
                case "status" -> assertEquals(value, msg.status, "Message status does not match!");
                case "error.description" -> assertTrue(msg.error.description.startsWith(value), String.format("Message error.description has unexpected value! Expected: '%s' Actual: '%s'", value, msg.error.description));
                case "error.code" -> assertEquals(value, msg.error.code, "Message error.code does not match!");
                case "error.stack_trace" -> {
                    assertFalse(msg.error.stack_trace.isEmpty(), "Message error.stack_trace is empty!");
                    String expectedTrace = value.replace("<atlas_settlement_level_id>", lastIntervalsInputMsg.extras.settlementItem.atlas_settlement_level_id);
                    String actual = msg.error.stack_trace.get(0);
                    assertTrue(actual.startsWith(expectedTrace), String.format("Message error.stack_trace has unexpected value! Expected: '%s' Actual: '%s'", expectedTrace, actual));
                }
                default -> fail("Unknown property: " + key);
            }
        });
        LOG.info("createIntervalsSQSOutput message verified");
    }



    private final TreeMap<Long, HashMap<String, Object>> expectedIntervals = new TreeMap<>();
    private final TreeMap<Long, HashMap<String, Object>> dbIntervals = new TreeMap<>();

    @When("I generate expected intervals from MOM offers$")
    public void iGenerateIntervalsFromMom() {

        var map = context.savedSettlementItems.entrySet().stream().findFirst().orElseThrow();
        SettlementItem item = JSON.convertValue(map.getValue(), new TypeReference<>() {});

        // First, get the ACTUAL offers from MOM
        GetClearedOffersRequest request = new GetClearedOffersRequest();
        request.startDttm = item.start_dttm_utc;
        request.endDttm = item.end_dttm_utc;
        request.clearedOfferType = "ACTUAL";
        request.recordType = "REGISTRATION";
        request.by = "registration";
        request.id = item.atlas_settlement_level_id;
        var actualOffers = new MomClient().getMomClearedOffers(request);

        // Next, get the FORECAST offers from MOM
        request = new GetClearedOffersRequest();
        request.startDttm = item.start_dttm_utc;
        request.endDttm = item.end_dttm_utc;
        request.clearedOfferType = "FORECAST";
        request.recordType = "REGISTRATION";
        request.by = "registration";
        request.id = item.atlas_settlement_level_id;
        var forecastOffers = new MomClient().getMomClearedOffers(request);

        // Now create the expected settlement item intervals.
        // For MVP, product interval length must equal MOM offer granularity, so we just need to create intervals one-for-one for offers over the settlement range, no agg or disagg.
        // Settlement intervals are keyed by end dttm.
        var intervals = new ArrayList<HashMap<String, Object>>();
        var intervalDttm = ZonedDateTime.parse(item.start_dttm_utc).plusMinutes(lastIntervalsInputMsg.extras.intervalLengthMinutes);
        var rangeEndDttm = ZonedDateTime.parse(item.end_dttm_utc);
        while (!intervalDttm.isAfter(rangeEndDttm)) {
            Optional<ClearedOffer> actualOpt = actualOffers.containsKey(intervalDttm) ? Optional.of(actualOffers.get(intervalDttm)) : Optional.empty();
            Optional<ClearedOffer> forecastOpt = forecastOffers.containsKey(intervalDttm) ? Optional.of(forecastOffers.get(intervalDttm)) : Optional.empty();
            var interval = new HashMap<String, Object>(); {
                interval.put("settlement_item_id", item.settlement_item_id);
                interval.put("interval_dttm_utc", intervalDttm.format(DateTimeFormatter.ISO_INSTANT));
                interval.put("user_estimated", false);
                interval.put("utility_data", false);
                interval.put("relevant_indicator", false);
                interval.put("deleted", false);
                interval.put("currency", lastIntervalsInputMsg.extras.currency);
                if (actualOpt.isEmpty() && forecastOpt.isEmpty()) {
                    interval.put("interval_source", "MISSING");
                } else {
                    interval.put("interval_source", "OFFER");
                    actualOpt.ifPresent(offer -> interval.put("cleared_offer_kw", offer.cleared.quantities.capacity));
                    forecastOpt.ifPresent(offer -> interval.put("original_offer_kw", offer.cleared.quantities.capacity));
                }

            }
            intervals.add(interval);
            intervalDttm = intervalDttm.plusMinutes(lastIntervalsInputMsg.extras.intervalLengthMinutes);
        }

        // Save intervals for later verification
        expectedIntervals.clear();
        intervals.forEach(iMap -> expectedIntervals.put(ZonedDateTime.parse(iMap.get("interval_dttm_utc").toString()).toEpochSecond(), iMap));
        LOG.info(String.format("Number of expected intervals: %d from %s to %s", intervals.size(),
                intervals.get(0).get("interval_dttm_utc"), intervals.get(intervals.size() - 1).get("interval_dttm_utc")));

    }


    @Then("the database intervals should match the expected intervals")
    public void databaseIntervalsShouldMatchExpected() {

        // First, get the db intervals using the API
        dbIntervals.clear();
        HashMap<String, Object> parms = new HashMap<>(Collections.singletonMap("settlement_item_id", lastIntervalsInputMsg.settlementItemId));
        var request = RequestContainer.build().getEntities(SETTLEMENT_ITEM_INTERVALS).addQueryParms(parms);
        var result = request.call(200).getResponseEntity(APIResponses.GetSettlementItemIntervalsResult.class);
        request.getDataAsList().forEach(item -> {
            long epoch = ZonedDateTime.parse(item.get("interval_dttm_utc").toString()).toEpochSecond();
            assertFalse(dbIntervals.containsKey(epoch));
            dbIntervals.put(epoch, item);
        });
        while (result.meta().next != null) {
            request = RequestContainer.build().getWithUrl(SETTLEMENT_ITEM_INTERVALS, result.meta().next);
            result = request.call(200).getResponseEntity(APIResponses.GetSettlementItemIntervalsResult.class);
            request.getDataAsList().forEach(item -> {
                long epoch = ZonedDateTime.parse(item.get("interval_dttm_utc").toString()).toEpochSecond();
                assertFalse(dbIntervals.containsKey(epoch));
                dbIntervals.put(epoch, item);
            });
        }

        // Now compare the db intervals against the expecteds
        List<String> errors = new ArrayList<>();
        TreeMap<Long, HashMap<String, Object>> dbIntervalsLocal = new TreeMap<>(dbIntervals); // Use a new map so we can manipulate it locally
        AtomicInteger numVerified = new AtomicInteger(0);
        expectedIntervals.forEach((key, expected) -> {
            String dttm = expected.get("interval_dttm_utc").toString();
            if (!dbIntervalsLocal.containsKey(key)) {
                errors.add(String.format("No actual interval created for: %s", dttm));
            } else {
                var actual = dbIntervalsLocal.remove(key);
                numVerified.incrementAndGet();
                expected.keySet().forEach(prop -> {
                    if (!Utility.testObjsEqual(prop, expected.get(prop), actual.get(prop))) {
                        var expectedProp = expected.get(prop);
                        var actProp = actual.get(prop);
                        errors.add(String.format("%s: mismatched property %s. Expected: %s Found: %s", dttm, prop,
                                expectedProp == null ? "null" : expectedProp.toString(), actProp == null ? "null" : actProp.toString()));
                    }
                });
            }
        });
        dbIntervalsLocal.forEach((key, actual) -> errors.add(String.format("Extra database interval created for : %s", actual.get("interval_dttm_utc").toString())));
        assertTrue(errors.isEmpty(), "\n" + String.join("\n", errors) + "\n");
        LOG.info("{} database intervals verified", numVerified.get());
    }


    @And("the database intervals should include {int} OFFER and {int} MISSING for a total of {int}")
    public void numDatabaseIntervalsCreated(int numOfferExpected, int numMissingExpected, int numExpected) {
        assertEquals(numExpected, numMissingExpected + numOfferExpected);
        assertEquals(numExpected, dbIntervals.size(), "Unexpected number of intervals created!");
        assertEquals(numOfferExpected, dbIntervals.values().stream().filter(v -> "OFFER".equals(v.get("interval_source").toString())).count(), "Unexpected number of offers created!");
        assertEquals(numMissingExpected, dbIntervals.values().stream().filter(v -> "MISSING".equals(v.get("interval_source").toString())).count(), "Unexpected number of missing created!");
        LOG.info(String.format("settlement_item_id %s: %d intervals created as expected with %d offers and %d missing",
                lastIntervalsInputMsg.settlementItemId, numExpected, numOfferExpected, numMissingExpected));
    }


    private CreateItemsSqsInputMessage lastItemsInputMsg;
    private final SortedMap<ZonedDateTime, CreateIntervalsSqsInputMessage> lastIntervalsInputMsgs = new TreeMap<>();

    @When("I send a message to the SQS Items Input Queue using the saved settlement")
    public void iSendSqsMsgItemsInput() throws Exception {
        iSendSqsMsgItemsInputInternal();
    }

    private void iSendSqsMsgItemsInputInternal() throws Exception {
        AwsSqs client = AwsSqs.build().withUrl(Context.createItemsSQSInputUrl);

        var map = context.savedSettlements.entrySet().stream().findFirst().orElseThrow();
        Settlement settlement = JSON.convertValue(map.getValue(), new TypeReference<>() {});

        lastItemsInputMsg = new CreateItemsSqsInputMessage();
        {
            lastItemsInputMsg.action = "RUN_TASK";
            lastItemsInputMsg.status = "REQUESTED";
            lastItemsInputMsg.caller = "ORCHESTRATOR";
            lastItemsInputMsg.step = "CREATOR_REST";
            lastItemsInputMsg.settlementId = settlement.settlement_id;
            lastItemsInputMsg.productId = settlement.product_id;
            lastPipelineRunId = UUID.randomUUID().toString();
            lastItemsInputMsg.pipelineRunId = lastPipelineRunId;
        }

        String msgString = JSON.writeValueAsString(lastItemsInputMsg);
        client.sendSqsMessageToFifoQueue(msgString);

        // Construct expected SQS Intervals Input message for later use
        lastIntervalsInputMsg = new CreateIntervalsSqsInputMessage();
        {
            lastIntervalsInputMsg.pipelineRunId = lastItemsInputMsg.pipelineRunId;
            lastIntervalsInputMsg.productId = lastItemsInputMsg.productId;
            lastIntervalsInputMsg.settlementId = lastItemsInputMsg.settlementId;
            lastIntervalsInputMsg.settlementItemId = "<any>";
            lastIntervalsInputMsg.caller = "CREATOR";
            lastIntervalsInputMsg.step = lastItemsInputMsg.step;
        }

        LOG.info(String.format("CreateItemsSqsInputMessage message sent with pipeline_run_id: %s  settlement_id: %s", lastPipelineRunId, lastItemsInputMsg.settlementId));
    }

    @And("the expected armed status by registration set:")
    public void setExpectedArmedStatusByRegistrationSet(DataTable table) {
        Map<String, Boolean> expected = new HashMap<>();

        // table.asMaps -> each row is a Map<header, value>
        for (Map<String, String> row : table.asMaps(String.class, String.class)) {
            String regSetId = row.get("registration_set_id");
            String expectedStr = row.get("expected_armed");
            expected.put(regSetId, Boolean.parseBoolean(expectedStr));
        }

        context.setExpectedArmedByRegistrationSetId(expected);
    }

    @Then("the registration-level settlement item intervals should match the expected armed status")
    public void verifyArmedStatusForRegistrationItems() throws Exception {
        Map<String, Boolean> expectedMap = context.getExpectedArmedByRegistrationSetId();

        assertFalse(context.savedSettlementItems.isEmpty(), "No saved settlement items!");

        List<HashMap<String, Object>> regItems = context.savedSettlementItems.values().stream()
                .filter(m -> "REGISTRATION".equals(m.get("settlement_level")))
                .collect(Collectors.toList());

        var errors = new ArrayList<String>();

        for (var item : regItems) {
            String settlementItemId = item.get("settlement_item_id").toString();
            String registrationSetId = Objects.toString(item.get("registration_set_id"), "NULL");

            Boolean expectedArmed = expectedMap.get(registrationSetId);
            if (expectedArmed == null) {
                continue;
            }

            List<SettlementItemInterval> intervals =
                    client.getIntervalsForSettlementItem(settlementItemId);

            boolean anyTrue = intervals.stream()
                    .anyMatch(i -> Boolean.TRUE.equals(i.is_armed));

            if (expectedArmed && !anyTrue) {
                errors.add("Expected ARMED intervals for settlement_item_id=" + settlementItemId);
            } else if (!expectedArmed && anyTrue) {
                errors.add("Did NOT expect ARMED intervals for settlement_item_id=" + settlementItemId);
            }
        }

        assertTrue(errors.isEmpty(), String.join("\n", errors));
    }



    @Given("I run Nates overlaps test")
    public void iRunNatesOverlapsTest() {

        // both ranges are instants
        assertFalse(Utility.nateOverlaps(1L, 1L, 2L, 2L));
        assertTrue(Utility.nateOverlaps(2L, 2L, 2L, 2L));
        assertFalse(Utility.nateOverlaps(3L, 3L, 2L, 2L));

        // first instant, 2nd range
        assertFalse(Utility.nateOverlaps(5L, 5L, 1L, 4L));
        assertFalse(Utility.nateOverlaps(5L, 5L, 1L, 5L));
        assertTrue(Utility.nateOverlaps(5L, 5L, 1L, 6L));
        assertTrue(Utility.nateOverlaps(5L, 5L, 5L, 7L));
        assertFalse(Utility.nateOverlaps(5L, 5L, 6L, 7L));

        // first range, 2nd instant
        assertFalse(Utility.nateOverlaps(1L, 4L, 5L, 5L));
        assertFalse(Utility.nateOverlaps(1L, 5L, 5L, 5L));
        assertTrue(Utility.nateOverlaps(1L, 6L, 5L, 5L));
        assertTrue(Utility.nateOverlaps(5L, 6L, 5L, 5L));
        assertFalse(Utility.nateOverlaps(6L, 7L, 5L, 5L));

        // both ranges, 1st moving, 2nd constant
        assertFalse(Utility.nateOverlaps(1L, 4L, 5L, 8L));
        assertFalse(Utility.nateOverlaps(1L, 5L, 5L, 8L));
        assertTrue(Utility.nateOverlaps(1L, 7L, 5L, 8L));
        assertTrue(Utility.nateOverlaps(1L, 8L, 5L, 8L));
        assertTrue(Utility.nateOverlaps(1L, 9L, 5L, 8L));

        assertTrue(Utility.nateOverlaps(5L, 7L, 5L, 8L));
        assertTrue(Utility.nateOverlaps(5L, 8L, 5L, 8L));
        assertTrue(Utility.nateOverlaps(5L, 9L, 5L, 8L));

        assertTrue(Utility.nateOverlaps(6L, 7L, 5L, 8L));
        assertTrue(Utility.nateOverlaps(6L, 8L, 5L, 8L));
        assertTrue(Utility.nateOverlaps(6L, 9L, 5L, 8L));

        assertFalse(Utility.nateOverlaps(8L, 9L, 5L, 8L));

        assertFalse(Utility.nateOverlaps(9L, 10L, 5L, 8L));

        // both ranges, 1st constant, 2nd moving
        assertFalse(Utility.nateOverlaps(5L, 8L,1L, 4L));
        assertFalse(Utility.nateOverlaps(5L, 8L,1L, 5L));
        assertTrue(Utility.nateOverlaps(5L, 8L,1L, 7L));
        assertTrue(Utility.nateOverlaps(5L, 8L,1L, 8L));
        assertTrue(Utility.nateOverlaps(5L, 8L,1L, 9L));

        assertTrue(Utility.nateOverlaps(5L, 8L,5L, 7L));
        assertTrue(Utility.nateOverlaps(5L, 8L,5L, 8L));
        assertTrue(Utility.nateOverlaps(5L, 8L,5L, 9L));

        assertTrue(Utility.nateOverlaps(5L, 8L,6L, 7L));
        assertTrue(Utility.nateOverlaps(5L, 8L,6L, 8L));
        assertTrue(Utility.nateOverlaps(5L, 8L,6L, 9L));

        assertFalse(Utility.nateOverlaps(5L, 8L,8L, 9L));

        assertFalse(Utility.nateOverlaps(5L, 8L,9L, 10L));
    }


    @Given("I run my overlaps test")
    public void iRunMyOverlapsTest() {

        // both ranges are instants
        assertFalse(Utility.datesOverlap(1L, 1L, 2L, 2L));
        assertTrue(Utility.datesOverlap(2L, 2L, 2L, 2L));
        assertFalse(Utility.datesOverlap(3L, 3L, 2L, 2L));

        // first instant, 2nd range
        assertFalse(Utility.datesOverlap(5L, 5L, 1L, 4L));
        assertFalse(Utility.datesOverlap(5L, 5L, 1L, 5L));
        assertTrue(Utility.datesOverlap(5L, 5L, 1L, 6L));
        assertTrue(Utility.datesOverlap(5L, 5L, 5L, 7L));
        assertFalse(Utility.datesOverlap(5L, 5L, 6L, 7L));

        // first range, 2nd instant
        assertFalse(Utility.datesOverlap(1L, 4L, 5L, 5L));
        assertFalse(Utility.datesOverlap(1L, 5L, 5L, 5L));
        assertTrue(Utility.datesOverlap(1L, 6L, 5L, 5L));
        assertTrue(Utility.datesOverlap(5L, 6L, 5L, 5L));
        assertFalse(Utility.datesOverlap(6L, 7L, 5L, 5L));

        // both ranges, 1st moving, 2nd constant
        assertFalse(Utility.datesOverlap(1L, 4L, 5L, 8L));
        assertFalse(Utility.datesOverlap(1L, 5L, 5L, 8L));
        assertTrue(Utility.datesOverlap(1L, 7L, 5L, 8L));
        assertTrue(Utility.datesOverlap(1L, 8L, 5L, 8L));
        assertTrue(Utility.datesOverlap(1L, 9L, 5L, 8L));

        assertTrue(Utility.datesOverlap(5L, 7L, 5L, 8L));
        assertTrue(Utility.datesOverlap(5L, 8L, 5L, 8L));
        assertTrue(Utility.datesOverlap(5L, 9L, 5L, 8L));

        assertTrue(Utility.datesOverlap(6L, 7L, 5L, 8L));
        assertTrue(Utility.datesOverlap(6L, 8L, 5L, 8L));
        assertTrue(Utility.datesOverlap(6L, 9L, 5L, 8L));

        assertFalse(Utility.datesOverlap(8L, 9L, 5L, 8L));

        assertFalse(Utility.datesOverlap(9L, 10L, 5L, 8L));

        // both ranges, 1st constant, 2nd moving
        assertFalse(Utility.datesOverlap(5L, 8L,1L, 4L));
        assertFalse(Utility.datesOverlap(5L, 8L,1L, 5L));
        assertTrue(Utility.datesOverlap(5L, 8L,1L, 7L));
        assertTrue(Utility.datesOverlap(5L, 8L,1L, 8L));
        assertTrue(Utility.datesOverlap(5L, 8L,1L, 9L));

        assertTrue(Utility.datesOverlap(5L, 8L,5L, 7L));
        assertTrue(Utility.datesOverlap(5L, 8L,5L, 8L));
        assertTrue(Utility.datesOverlap(5L, 8L,5L, 9L));

        assertTrue(Utility.datesOverlap(5L, 8L,6L, 7L));
        assertTrue(Utility.datesOverlap(5L, 8L,6L, 8L));
        assertTrue(Utility.datesOverlap(5L, 8L,6L, 9L));

        assertFalse(Utility.datesOverlap(5L, 8L,8L, 9L));

        assertFalse(Utility.datesOverlap(5L, 8L,9L, 10L));

        // Error conditions
        boolean errorFound = false;
        try {
            Utility.datesOverlap(9L, 8L, 5L, 7L);
        } catch (Throwable e) {
            errorFound = true;
            LOG.info(e.getMessage());
        }
        assertTrue(errorFound);

        errorFound = false;
        try {
            Utility.datesOverlap(5L, 8L, 8L, 7L);
        } catch (Throwable e) {
            errorFound = true;
            LOG.info(e.getMessage());
        }
        assertTrue(errorFound);
    }


    @Given("I run Nates rounding test")
    public void iRunNatesRoundingTest() {
        assertEquals("2025-04-14T00:00:00Z", Utility.roundTimeUpToInterval("2025-04-14T00:00:00Z", 60));
        assertEquals("2025-04-14T01:00:00Z", Utility.roundTimeUpToInterval("2025-04-14T00:00:00.001Z", 60));
        assertEquals("2025-04-14T01:00:00Z", Utility.roundTimeUpToInterval("2025-04-14T00:00:59.999Z", 60));

        var endRoundedPrev = ZonedDateTime.parse(Utility.roundTimeUpToInterval("2025-04-14T00:00:00.000Z", 60));
        var startRounded = ZonedDateTime.parse(Utility.roundTimeUpToInterval("2025-04-14T00:00:00.000Z", 60));
        var endRounded = ZonedDateTime.parse(Utility.roundTimeUpToInterval("2025-04-14T00:00:01.000Z", 60));
        var startRoundedNext = ZonedDateTime.parse(Utility.roundTimeUpToInterval("2025-04-14T00:00:01.000Z", 60));
        LOG.info(String.format("endRoundedPrev = '%s'   startRounded = '%s'   endRounded = '%s  startRoundedNext = '%s'", endRoundedPrev, startRounded, endRounded, startRoundedNext));
        if (endRounded.isAfter(startRounded)) {
            LOG.info(String.format("Rounded times are different, history retained: '%s' '%s'", startRounded, endRounded));
        } else {
            LOG.info(String.format("Rounded times are identical, history discarded: '%s' '%s'", startRounded, endRounded));
        }

        endRoundedPrev = ZonedDateTime.parse(Utility.roundTimeUpToInterval("2025-04-14T00:00:01.000Z", 60));
        startRounded = ZonedDateTime.parse(Utility.roundTimeUpToInterval("2025-04-14T00:00:01.000Z", 60));
        endRounded = ZonedDateTime.parse(Utility.roundTimeUpToInterval("2025-04-14T00:00:02.000Z", 60));
        startRoundedNext = ZonedDateTime.parse(Utility.roundTimeUpToInterval("2025-04-14T00:00:02.000Z", 60));
        LOG.info(String.format("endRoundedPrev = '%s'   startRounded = '%s'   endRounded = '%s  startRoundedNext = '%s'", endRoundedPrev, startRounded, endRounded, startRoundedNext));
        if (endRounded.isAfter(startRounded)) {
            LOG.info(String.format("Rounded times are different, history retained: '%s' '%s'", startRounded, endRounded));
        } else {
            LOG.info(String.format("Rounded times are identical, history discarded: '%s' '%s'", startRounded, endRounded));
        }

    }

    @Then("the expected settlement items for all saved settlements should have been created")
    public void verifyExpectedItemsCreatedForAllSavedSettlements() {
        assertFalse(context.savedSettlements.isEmpty(), "No saved settlements!");
        assertFalse(context.expectedSettlementItems.isEmpty(), "No expected items!");

        // Use lastSettlementId — explicitly set when each settlement is saved
        String currentSettlementId = context.lastSettlementId;
        assertNotNull(currentSettlementId, "lastSettlementId is null!");

        var actuals = new ArrayList<SettlementItem>();

        var settlementItemIds = lastPipelineStateRows.stream()
                .filter(row -> row.settlement_item_id != null)
                .map(row -> row.settlement_item_id)
                .collect(Collectors.toSet());

        settlementItemIds.forEach(id -> {
            var props = RequestContainer.build().getEntity(SETTLEMENT_ITEM, id).call().getDataAsList();
            assertEquals(1, props.size(), String.format("Unexpected number of items returned for pipeline state settlement_item_id %s", id));
            SettlementItem item = JSON.convertValue(props.getFirst(), new TypeReference<>() {});
            if (currentSettlementId.equals(item.settlement_id)) {
                actuals.add(item);
                context.savedSettlementItems.put(props.getFirst().get("settlement_item_id").toString(), props.getFirst());
            }
        });

        Map<String, SettlementItem> expectedByKey = new LinkedHashMap<>();
        for (SettlementItem item : context.expectedSettlementItems) {
            String key = item.atlas_settlement_level_id + ":" + item.start_dttm_utc + ":" + item.end_dttm_utc;
            expectedByKey.put(key, item);
        }

        var actualByKey = actuals.stream()
                .collect(Collectors.toMap(
                        item -> item.atlas_settlement_level_id + ":" + item.start_dttm_utc + ":" + item.end_dttm_utc,
                        item -> item,
                        (a, b) -> a,
                        LinkedHashMap::new));

        var errors = new ArrayList<String>();

        for (var expectedEntry : expectedByKey.entrySet()) {
            var key = expectedEntry.getKey();
            var expected = expectedEntry.getValue();
            var actual = actualByKey.remove(key);

            if (actual == null) {
                errors.add("Expected item not in pipeline history: " + key);
                continue;
            }

            expected.settlement_item_id = actual.settlement_item_id;
            expected.settlement_id = actual.settlement_id;
            expected.last_updated_by = actual.last_updated_by;
            expected.last_updated_dttm_utc = actual.last_updated_dttm_utc;

            HashMap<String, Object> expMap = JSON.convertValue(expected, new TypeReference<>() {});
            HashMap<String, Object> actMap = JSON.convertValue(actual, new TypeReference<>() {});

            if (!expMap.equals(actMap)) {
                errors.add("Mismatch for item " + key);
            }
        }

        actualByKey.values().forEach(actual ->
                errors.add("Unexpected item in pipeline history. settlement_item_id: " + actual.settlement_item_id));

        assertTrue(errors.isEmpty(), String.join("\n", errors));
        LOG.info("{} expected items verified for settlement {}", context.expectedSettlementItems.size(), currentSettlementId);
    }

    @Then("only the {int} expected settlement items should have been created for the last settlement")
    public void verifyExpectedItemCount(int expectedCount) {
        assertEquals(expectedCount, context.savedSettlementItems.size());
    }

    @Then("only the {int} saved settlements should have been created earlier")
    public void verifySavedSettlementsCreated(int numExpected) {
        // The quarterly pipeline re-run should only have processed one item per settlement
        // (i.e. numExpected = 3 settlements), not all 22 saved items.
        // We check that the pipeline history contains exactly numExpected distinct settlement ids,
        // and that each one is among the savedSettlements keys.
        assertFalse(lastPipelineStateRows.isEmpty(), "Empty pipeline history returned!");

        var processedSettlementIds = lastPipelineStateRows.stream()
                .filter(row -> row.settlement_id != null)
                .map(row -> row.settlement_id)
                .distinct()
                .collect(Collectors.toList());

        var errors = new ArrayList<String>();

        // Verify the count matches what we expect
        if (processedSettlementIds.size() != numExpected) {
            errors.add(String.format("Expected %d settlement(s) in pipeline history, but found %d: %s",
                    numExpected, processedSettlementIds.size(), String.join((CharSequence) ", ", (CharSequence) processedSettlementIds)));
        }

        // Verify each processed settlement is one we already know about
        processedSettlementIds.forEach(id -> {
            if (!context.savedSettlements.containsKey(id)) {
                errors.add(String.format("Unexpected settlement in pipeline history: %s", id));
            }
        });

        // Verify no new settlement items were created (only existing ones re-processed)
        var newItemIds = lastPipelineStateRows.stream()
                .filter(row -> row.settlement_item_id != null)
                .map(row -> row.settlement_item_id)
                .collect(Collectors.toSet());

        var savedItemIds = context.expectedSettlementItemsSaved.stream()
                .map(item -> item.settlement_item_id)
                .filter(Objects::nonNull)
                .collect(Collectors.toSet());

        newItemIds.forEach(id -> {
            if (!savedItemIds.contains(id)) {
                errors.add(String.format("Unexpected new item in pipeline history, settlementitemid: %s", id));
            }
        });

        assertTrue(errors.isEmpty(), String.join("\n", errors));
        LOG.info(String.format("%d settlements re-processed by quarterly pipeline as expected", numExpected));
    }

    @Then("^all created settlements for product \"([^\"]*)\" should have inputs_available_until_dttm_utc (populated|as null)$")
    public void verifyInputsAvailableUntilForProduct(String productId, String expectedState) throws Exception {
        boolean shouldBePopulated = expectedState.equals("populated");

        List<Settlement> productSettlements = context.pipelineSettlementsProcessed.stream()
                .filter(s -> s.product_id.equals(productId))
                .collect(Collectors.toList());

        if (productSettlements.isEmpty()) {
            LOG.warn("pipelineSettlementsProcessed empty for product_id='{}', falling back to expectedSettlements", productId);
            productSettlements = context.expectedSettlements.stream()
                    .filter(s -> s.product_id.equals(productId))
                    .collect(Collectors.toList());
        }

        assertFalse(productSettlements.isEmpty(),
                "No settlements found in context for product_id='" + productId + "'");

        List<String> errors = new ArrayList<>();

        for (Settlement s : productSettlements) {
            List<Settlement> rows = client.getSettlementRows(
                    s.product_id, s.settlement_type, s.start_dttm_utc, false);

            if (rows.isEmpty()) {
                errors.add(String.format("Settlement not found in DB — product_id='%s' start_dttm_utc='%s'",
                        s.product_id, s.start_dttm_utc));
                continue;
            }

            Settlement dbSettlement = rows.get(0);
            var msgSuffix = String.format("settlement_id='%s' product_id='%s' start_dttm_utc='%s'",
                    dbSettlement.settlement_id, dbSettlement.product_id, dbSettlement.start_dttm_utc);

            if (shouldBePopulated && dbSettlement.inputs_available_until_dttm_utc == null) {
                errors.add("inputs_available_until_dttm_utc is NULL but should be populated for: " + msgSuffix);
            } else if (!shouldBePopulated && dbSettlement.inputs_available_until_dttm_utc != null) {
                errors.add("inputs_available_until_dttm_utc should be NULL but was '"
                        + dbSettlement.inputs_available_until_dttm_utc + "' for: " + msgSuffix);
            } else {
                LOG.info("inputs_available_until_dttm_utc '{}' OK for: {}", expectedState, msgSuffix);
            }
        }

        assertTrue(errors.isEmpty(),
                "inputs_available_until_dttm_utc verification failed:\n" + String.join("\n", errors));
    }

    @Then("^(\\d+) settlement_item(?:s)? for product_id \"([^\"]*)\" between \"([^\"]*)\" and \"([^\"]*)\" should have is_inactive (true|false)$")
    public void verifyExactCountSettlementItemsIsInactive(int expectedCount, String productId, String startStr, String endStr, String expectedFlag) throws Exception {
        boolean expectedIsInactive = Boolean.parseBoolean(expectedFlag);

        ZonedDateTime rangeStart = ZonedDateTime.parse(startStr);
        ZonedDateTime rangeEnd = ZonedDateTime.parse(endStr);

        var msgSuffix = String.format("product_id='%s' between '%s' and '%s'", productId, startStr, endStr);

        long timeoutMillis = 30_000;
        long pollIntervalMillis = 2_000;
        long deadline = System.currentTimeMillis() + timeoutMillis;

        List<HashMap<String, Object>> matching = new ArrayList<>();

        while (System.currentTimeMillis() < deadline) {
            List<Settlement> productSettlements = client.selectRecordsTable(
                            "settlements", String.format("product_id='%s' AND deleted=false", productId), null)
                    .stream()
                    .map(row -> JSON.convertValue(row, Settlement.class))
                    .toList();

            matching = new ArrayList<>();
            for (Settlement s : productSettlements) {
                List<HashMap<String, Object>> items = client.getSettlementItemsForSettlementRows(s.settlement_id);
                for (HashMap<String, Object> item : items) {
                    String rawStart = (String) item.get("start_dttm_utc");
                    String rawEnd = (String) item.get("end_dttm_utc");

                    if (rawStart == null || "null".equalsIgnoreCase(rawStart)
                            || rawEnd == null || "null".equalsIgnoreCase(rawEnd)) {
                        LOG.warn("Skipping settlement_item_id='{}' due to null start_dttm_utc/end_dttm_utc (start='{}', end='{}')",
                                item.get("settlement_item_id"), rawStart, rawEnd);
                        continue;
                    }

                    ZonedDateTime itemStart = ZonedDateTime.parse(Utility.normalizeDateTime(rawStart));
                    ZonedDateTime itemEnd = ZonedDateTime.parse(Utility.normalizeDateTime(rawEnd));
                    boolean overlaps = itemStart.isBefore(rangeEnd) && itemEnd.isAfter(rangeStart);

                    Object rawIsInactive = item.get("is_inactive");
                    boolean actualIsInactive = rawIsInactive != null && Boolean.parseBoolean(rawIsInactive.toString());

                    if (overlaps && actualIsInactive == expectedIsInactive) {
                        matching.add(item);
                    }
                }
            }

            if (matching.size() >= expectedCount) {
                break;
            }

            LOG.info("Found {} matching settlement_item(s) so far for {}, expected {}. Retrying...",
                    matching.size(), msgSuffix, expectedCount);
            Thread.sleep(pollIntervalMillis);
        }

        final List<HashMap<String, Object>> finalMatching = matching;

        assertEquals(expectedCount, finalMatching.size(),
                String.format("Expected %d settlement_item(s) with is_inactive=%s for %s, but found %d",
                        expectedCount, expectedIsInactive, msgSuffix, finalMatching.size()));

        finalMatching.forEach(item -> LOG.info(String.format(
                "Verified settlement_item_id='%s' is_inactive=%s start_dttm_utc='%s' end_dttm_utc='%s'",
                item.get("settlement_item_id"), expectedIsInactive, item.get("start_dttm_utc"), item.get("end_dttm_utc"))));

        LOG.info(String.format("%d settlement_item(s) with is_inactive=%s verified for %s", finalMatching.size(), expectedIsInactive, msgSuffix));
    }

    @Then("I query and log settlements for product {string}")
    public void iQueryAndLogSettlementsForProduct(String productId) throws Exception {
        LOG.info("=== Querying settlements for product_id: {} ===", productId);

        List<Settlement> productSettlements = context.pipelineSettlementsProcessed.stream()
                .filter(s -> s.product_id.equals(productId))
                .collect(Collectors.toList());

        if (productSettlements.isEmpty()) {
            LOG.warn("No processed settlements found in context for product_id: {}", productId);
            LOG.info("Falling back to expected settlements...");
            productSettlements = context.expectedSettlements.stream()
                    .filter(s -> s.product_id.equals(productId))
                    .collect(Collectors.toList());
        }

        assertFalse(productSettlements.isEmpty(),
                "No settlements found in context for product_id: " + productId);

        List<String> errors = new ArrayList<>();

        for (Settlement s : productSettlements) {
            List<Settlement> rows = client.getSettlementRows(
                    s.product_id, s.settlement_type, s.start_dttm_utc, false);

            if (rows.isEmpty()) {
                errors.add(String.format(
                        "Settlement not found in DB: settlement_id='%s' product_id='%s' start_dttm_utc='%s'",
                        s.settlement_id, s.product_id, s.start_dttm_utc));
                continue;
            }

            Settlement dbSettlement = rows.get(0);
            LOG.info("--------------------------------------------------");
            LOG.info("  settlement_id                   : {}", dbSettlement.settlement_id);
            LOG.info("  product_id                      : {}", dbSettlement.product_id);
            LOG.info("  settlement_type                 : {}", dbSettlement.settlement_type);
            LOG.info("  start_dttm_utc                  : {}", dbSettlement.start_dttm_utc);
            LOG.info("  end_dttm_utc                    : {}", dbSettlement.end_dttm_utc);
            LOG.info("  inputs_available_until_dttm_utc : {}",
                    dbSettlement.inputs_available_until_dttm_utc != null
                            ? toUtcString(dbSettlement.inputs_available_until_dttm_utc) : "<NULL>");
            LOG.info("--------------------------------------------------");
        }

        assertTrue(errors.isEmpty(), "DB query errors:\n" + String.join("\n", errors));
        LOG.info("=== Query complete for product_id: {} ({} settlement(s)) ===",
                productId, productSettlements.size());
    }


    @Then("^all created settlements for product_id \"([^\"]*)\" and product (AESO|FCAS) should have inputs_available_until_dttm_utc (populated|as null)$")
    public void verifyInputsAvailableUntilForProductWithCalculation(String productId, String productType, String expectedState) throws Exception {
        boolean shouldBePopulated = expectedState.equals("populated");

        int daysOffset = switch (productType) {
            case "AESO" -> 365;
            case "FCAS" -> 90;
            default -> throw new IllegalArgumentException("Unknown product type: " + productType);
        };

        List<Settlement> productSettlements = context.pipelineSettlementsProcessed.stream()
                .filter(s -> s.product_id.equals(productId))
                .collect(Collectors.toList());

        if (productSettlements.isEmpty()) {
            LOG.warn("pipelineSettlementsProcessed empty for product_id='{}', falling back to expectedSettlements", productId);
            productSettlements = context.expectedSettlements.stream()
                    .filter(s -> s.product_id.equals(productId))
                    .collect(Collectors.toList());
        }

        assertFalse(productSettlements.isEmpty(),
                "No settlements found in context for product_id='" + productId + "'");

        List<String> errors = new ArrayList<>();

        for (Settlement s : productSettlements) {
            List<Settlement> rows = client.getSettlementRows(
                    s.product_id, s.settlement_type, s.start_dttm_utc, false);

            if (rows.isEmpty()) {
                errors.add(String.format("Settlement not found in DB — product_id='%s' start_dttm_utc='%s'",
                        s.product_id, s.start_dttm_utc));
                continue;
            }

            Settlement dbSettlement = rows.get(0);
            var msgSuffix = String.format("settlement_id='%s' product_id='%s' start_dttm_utc='%s'",
                    dbSettlement.settlement_id, dbSettlement.product_id, dbSettlement.start_dttm_utc);

            String rawValue = dbSettlement.inputs_available_until_dttm_utc;
            boolean isPopulated = rawValue != null;

            LOG.info("inputs_available_until_dttm_utc='{}' for: {}",
                    isPopulated ? toUtcString(rawValue) : "<NULL>", msgSuffix);

            if (!shouldBePopulated) {
                if (isPopulated) {
                    errors.add("inputs_available_until_dttm_utc should be NULL but was '" + rawValue + "' for: " + msgSuffix);
                } else {
                    LOG.info("✓ inputs_available_until_dttm_utc is NULL as expected for: {}", msgSuffix);
                }
            } else {
                if (!isPopulated) {
                    errors.add("inputs_available_until_dttm_utc is NULL but should be populated for: " + msgSuffix);
                } else {
                    try {
                        ZonedDateTime expectedDate = ZonedDateTime.parse(s.start_dttm_utc)
                                .plusDays(daysOffset)
                                .withZoneSameInstant(UTC);
                        ZonedDateTime actualDate = ZonedDateTime.parse(rawValue.replace(" ", "T"),
                                        DateTimeFormatter.ISO_OFFSET_DATE_TIME)
                                .withZoneSameInstant(UTC);

                        if (actualDate.equals(expectedDate)) {
                            LOG.info("✓ inputs_available_until_dttm_utc OK ({} + {} days = {}) for: {}",
                                    s.start_dttm_utc, daysOffset, actualDate, msgSuffix);
                        } else {
                            errors.add(String.format(
                                    "Date mismatch for %s (+%d days)  Expected: %s  Actual: %s  For: %s",
                                    productType, daysOffset, expectedDate, actualDate, msgSuffix));
                        }
                    } catch (Exception e) {
                        errors.add("Failed to parse inputs_available_until_dttm_utc='" + rawValue + "': "
                                + e.getMessage() + " for: " + msgSuffix);
                    }
                }
            }
        }

        assertTrue(errors.isEmpty(),
                "inputs_available_until_dttm_utc verification failed:\n" + String.join("\n", errors));
    }

    @Then("^all settlements for product_id \"([^\"]*)\" between \"([^\"]*)\" and \"([^\"]*)\" should still have inputs_available_until_dttm_utc populated$")
    public void verifyInputsAvailableUntilNotNulledByQuarterlyRun(String productId, String startDate, String endDate) throws Exception {

        // Normalize dates to UTC timestamps for DB query
        String startDttm = startDate + "T00:00:00Z";
        String endDttm   = endDate   + "T23:59:59Z";

        List<Settlement> rows = client.getSettlementRowsForProductInRange(productId, startDttm, endDttm);

        assertFalse(rows.isEmpty(),
                String.format("No settlements found in DB for product_id='%s' between '%s' and '%s'",
                        productId, startDate, endDate));

        List<String> errors = new ArrayList<>();

        for (Settlement dbSettlement : rows) {
            var msgSuffix = String.format("settlement_id='%s' start_dttm_utc='%s'",
                    dbSettlement.settlement_id, dbSettlement.start_dttm_utc);

            if (dbSettlement.inputs_available_until_dttm_utc == null) {
                errors.add("inputs_available_until_dttm_utc was nulled out by quarterly run for: " + msgSuffix);
            } else {
                LOG.info("✓ inputs_available_until_dttm_utc='{}' still populated after quarterly run for: {}",
                        dbSettlement.inputs_available_until_dttm_utc, msgSuffix);
            }
        }

        assertTrue(errors.isEmpty(),
                "Quarterly run nulled out inputs_available_until_dttm_utc:\n" + String.join("\n", errors));
    }


    @When("^I calculate registration_history gaps for product_id \"([^\"]*)\" registration_id \"([^\"]*)\" between \"([^\"]*)\" and \"([^\"]*)\"$")
    public void iCalculateRegistrationHistoryGaps(String productId, String registrationId, String startStr, String endStr) throws Exception {
        actualRegistrationHistoryGaps.clear();

        List<HashMap<String, Object>> rows = metadataClient.getReconciledRegistrationHistoryRows(productId, startStr, endStr);

        List<HashMap<String, Object>> intervals = new ArrayList<>();
        for (HashMap<String, Object> row : rows) {
            if (!registrationId.equals(row.get("registration_id"))) {
                LOG.info("Skipping unrelated registration_id='{}' (expected '{}')", row.get("registration_id"), registrationId);
                continue;
            }
            String rawStart = String.valueOf(row.get("effective_start_dttm_utc"));
            String rawEnd = String.valueOf(row.get("effective_end_dttm_utc"));
            if (rawStart == null || "null".equalsIgnoreCase(rawStart)
                    || rawEnd == null || "null".equalsIgnoreCase(rawEnd)) {
                LOG.warn("Skipping history_id='{}' due to null effective_start_dttm_utc/effective_end_dttm_utc",
                        row.get("history_id"));
                continue;
            }
            intervals.add(row);
        }

        intervals.sort(Comparator.comparing(r -> ZonedDateTime.parse(String.valueOf(r.get("effective_start_dttm_utc")))));

        List<ZonedDateTime[]> merged = new ArrayList<>();
        for (HashMap<String, Object> row : intervals) {
            ZonedDateTime start = ZonedDateTime.parse(String.valueOf(row.get("effective_start_dttm_utc")));
            ZonedDateTime end = ZonedDateTime.parse(String.valueOf(row.get("effective_end_dttm_utc")));

            if (!merged.isEmpty() && !start.isAfter(merged.getLast()[1])) {
                if (end.isAfter(merged.getLast()[1])) {
                    merged.getLast()[1] = end;
                }
            } else {
                merged.add(new ZonedDateTime[]{start, end});
            }
        }

        for (int i = 0; i < merged.size() - 1; i++) {
            ZonedDateTime currentEnd = merged.get(i)[1];
            ZonedDateTime nextStart = merged.get(i + 1)[0];
            if (nextStart.isAfter(currentEnd)) {
                var gap = new HashMap<String, String>();
                gap.put("start_dttm_utc", currentEnd.toString());
                gap.put("end_dttm_utc", nextStart.toString());
                actualRegistrationHistoryGaps.add(gap);
            }
        }

        LOG.info("Found {} gap(s) for product_id='{}' registration_id='{}' between '{}' and '{}'",
                actualRegistrationHistoryGaps.size(), productId, registrationId, startStr, endStr);
        actualRegistrationHistoryGaps.forEach(g -> LOG.info("Gap: start_dttm_utc='{}' end_dttm_utc='{}'", g.get("start_dttm_utc"), g.get("end_dttm_utc")));
    }

    @Then("^the registration_history gaps should be:$")
    public void verifyRegistrationHistoryGaps(DataTable expectedTable) {
        List<Map<String, String>> expectedRows = expectedTable.asMaps(String.class, String.class);

        List<ZonedDateTime[]> expectedGaps = expectedRows.stream()
                .map(row -> new ZonedDateTime[]{
                        ZonedDateTime.parse(Utility.normalizeDateTime(row.get("start_dttm_utc"))),
                        ZonedDateTime.parse(Utility.normalizeDateTime(row.get("end_dttm_utc")))
                })
                .toList();

        List<ZonedDateTime[]> actualGaps = actualRegistrationHistoryGaps.stream()
                .map(g -> new ZonedDateTime[]{
                        ZonedDateTime.parse(Utility.normalizeDateTime(g.get("start_dttm_utc"))),
                        ZonedDateTime.parse(Utility.normalizeDateTime(g.get("end_dttm_utc")))
                })
                .toList();

        assertEquals(expectedGaps.size(), actualGaps.size(),
                String.format("Expected %d gap(s) but found %d.\nExpected: %s\nActual: %s",
                        expectedGaps.size(), actualGaps.size(), expectedRows, actualRegistrationHistoryGaps));

        List<String> errors = new ArrayList<>();
        for (int i = 0; i < expectedGaps.size(); i++) {
            ZonedDateTime expStart = expectedGaps.get(i)[0];
            ZonedDateTime expEnd = expectedGaps.get(i)[1];
            ZonedDateTime actStart = actualGaps.get(i)[0];
            ZonedDateTime actEnd = actualGaps.get(i)[1];

            if (!expStart.isEqual(actStart) || !expEnd.isEqual(actEnd)) {
                errors.add(String.format("Gap #%d mismatch: expected [%s, %s] but found [%s, %s]",
                        i + 1, expStart, expEnd, actStart, actEnd));
            }
        }

        assertTrue(errors.isEmpty(), "Registration history gap verification failed:\n" + String.join("\n", errors));

        LOG.info("Verified {} registration_history gap(s) match expected values", expectedGaps.size());
    }

    @Then("^I verify that non-deleted settlements exist for product_id \"([^\"]*)\"$")
    public void iVerifyNonDeletedSettlementsExistForProduct(String productId) throws Exception {
        // Selects all matching rows to verify they exist and log the count
        List<HashMap<String, Object>> rows = client.selectRecordsTable(
                "settlements",
                String.format("product_id='%s' AND deleted=false", productId),
                null
        );

        assertFalse(rows.isEmpty(), String.format("Expected at least one non-deleted settlement for product_id '%s', but found 0", productId));
        LOG.info("Verified {} non-deleted settlements exist for product_id '{}'", rows.size(), productId);
    }

    @When("^I set inputs_available_until_dttm_utc to null for all non-deleted settlements with product_id \"([^\"]*)\"$")
    public void iSetInputsAvailableUntilToNullForAllNonDeletedSettlements(String productId) throws Throwable {
        // Updates ALL matching rows in a single query without needing to know the count beforehand
        String query = String.format(
                "UPDATE settlements SET inputs_available_until_dttm_utc = NULL WHERE product_id = '%s' AND deleted = false",
                productId
        );

        // runUpdateQuery executes the UPDATE and returns the number of affected rows
        int updatedRows = client.runUpdateQuery(query);

        assertTrue(updatedRows > 0, String.format("Expected to update at least one row for product_id '%s', but updated 0", productId));
        LOG.info("Successfully set inputs_available_until_dttm_utc to NULL for {} settlements with product_id '{}'", updatedRows, productId);
    }

    @Given("I query settlement_items for the saved settlement and identify inactive items")
    public void iQueryInactiveSettlementItemsForSavedSettlement() throws Exception {
        assertNotNull(context.lastSettlementId, "No settlement_id saved in context!");
        inactiveSettlementItemIds.clear();
        String condition = String.format("settlement_id = '%s' AND is_inactive = true", context.lastSettlementId);
        List<HashMap<String, Object>> rows = client.selectRecordsTable("settlement_items", condition, "settlement_item_id");
        inactiveSettlementItemIds.addAll(rows);
        LOG.info(String.format("Found %d inactive settlement_items for settlement_id=%s", rows.size(), context.lastSettlementId));
    }

    @Given("I query settlement_items for the saved settlement and identify active items")
    public void iQueryActiveSettlementItemsForSavedSettlement() throws Exception {
        assertNotNull(context.lastSettlementId, "No settlement_id saved in context!");
        activeSettlementItemIds.clear();
        String condition = String.format("settlement_id = '%s' AND (is_inactive IS NULL OR is_inactive = false)", context.lastSettlementId);
        List<HashMap<String, Object>> rows = client.selectRecordsTable("settlement_items", condition, "settlement_item_id");
        activeSettlementItemIds.addAll(rows);
        LOG.info(String.format("Found %d active settlement_items for settlement_id=%s", rows.size(), context.lastSettlementId));
    }

    @Then("all estimated intervals for inactive settlement items should have zero payment_value_estimated and revenue_value_estimated values")
    public void iVerifyInactiveIntervalsAreZero() throws Exception {
        assertFalse(inactiveSettlementItemIds.isEmpty(), "No inactive settlement_items found to verify!");

        List<String> itemIds = inactiveSettlementItemIds.stream()
                .map(row -> row.get("settlement_item_id").toString())
                .collect(Collectors.toList());

        String idList = itemIds.stream().map(id -> "'" + id + "'").collect(Collectors.joining(", "));
        String condition = String.format("settlement_item_id IN (%s)", idList);
        List<HashMap<String, Object>> intervals = client.selectRecordsTable(
                "settlement_item_intervals", condition, "settlement_item_id, interval_dttm_utc");

        assertFalse(intervals.isEmpty(), "No settlement_item_intervals found for inactive items!");

        int violations = 0;
        for (HashMap<String, Object> row : intervals) {
            Object payment = row.get("payment_value_estimated");
            Object revenue = row.get("revenue_value_estimated");

            double paymentVal = payment == null ? 0.0 : ((Number) payment).doubleValue();
            double revenueVal = revenue == null ? 0.0 : ((Number) revenue).doubleValue();

            if (paymentVal != 0.0 || revenueVal != 0.0) {
                violations++;
                LOG.info(String.format(
                        "VIOLATION: settlement_item_id=%s interval_dttm_utc=%s payment_value_estimated=%s revenue_value_estimated=%s",
                        row.get("settlement_item_id"), row.get("interval_dttm_utc"), payment, revenue));
            }
        }

        assertEquals(0, violations, String.format(
                "%d interval(s) for inactive settlement items had non-zero payment_value_estimated or revenue_value_estimated!",
                violations));
    }

    @Then("all estimated intervals for active settlement items should have non-zero payment_value_estimated and revenue_value_estimated values")
    public void iVerifyActiveIntervalsAreNonZero() throws Exception {
        assertFalse(activeSettlementItemIds.isEmpty(), "No active settlement_items found to verify!");

        List<String> itemIds = activeSettlementItemIds.stream()
                .map(row -> row.get("settlement_item_id").toString())
                .collect(Collectors.toList());

        String idList = itemIds.stream().map(id -> "'" + id + "'").collect(Collectors.joining(", "));
        String condition = String.format("settlement_item_id IN (%s)", idList);
        List<HashMap<String, Object>> intervals = client.selectRecordsTable(
                "settlement_item_intervals", condition, "settlement_item_id, interval_dttm_utc");

        assertFalse(intervals.isEmpty(), "No settlement_item_intervals found for active items!");

        int violations = 0;
        for (HashMap<String, Object> row : intervals) {
            violations += checkColumnNotZero(row, "payment_value_estimated");
            violations += checkColumnNotZero(row, "revenue_value_estimated");
        }

        assertEquals(0, violations, String.format(
                "%d column check(s) for active settlement items had a value of exactly 0 (nulls are allowed)!",
                violations));
    }

    private int checkColumnNotZero(HashMap<String, Object> row, String columnName) {
        Object value = row.get(columnName);
        if (value != null && ((Number) value).doubleValue() == 0.0) {
            LOG.info(String.format(
                    "VIOLATION: settlement_item_id=%s interval_dttm_utc=%s %s=%s (non-null but zero)",
                    row.get("settlement_item_id"), row.get("interval_dttm_utc"), columnName, value));
            return 1;
        }
        return 0;
    }

    @Then("all intervals for inactive settlement items should have zero payment, revenue, and estimated values")
    public void iVerifyInactiveFinalIntervalsAreZero() throws Exception {
        assertFalse(inactiveSettlementItemIds.isEmpty(), "No inactive settlement_items found to verify!");

        List<String> itemIds = inactiveSettlementItemIds.stream()
                .map(row -> row.get("settlement_item_id").toString())
                .collect(Collectors.toList());

        String idList = itemIds.stream().map(id -> "'" + id + "'").collect(Collectors.joining(", "));
        String condition = String.format("settlement_item_id IN (%s)", idList);
        List<HashMap<String, Object>> intervals = client.selectRecordsTable(
                "settlement_item_intervals", condition, "settlement_item_id, interval_dttm_utc");

        assertFalse(intervals.isEmpty(), "No settlement_item_intervals found for inactive items!");

        List<String> columnsToCheck = List.of(
                "payment_value_estimated",
                "revenue_value_estimated",
                "payment_value",
                "revenue_value"
        );

        int violations = 0;
        for (HashMap<String, Object> row : intervals) {
            for (String col : columnsToCheck) {
                Object value = row.get(col);
                double val = value == null ? 0.0 : ((Number) value).doubleValue();
                if (val != 0.0) {
                    violations++;
                    LOG.info(String.format(
                            "VIOLATION: settlement_item_id=%s interval_dttm_utc=%s %s=%s (expected 0)",
                            row.get("settlement_item_id"), row.get("interval_dttm_utc"), col, value));
                }
            }
        }

        assertEquals(0, violations, String.format(
                "%d column check(s) for inactive settlement items had a non-zero value!",
                violations));
    }

    @Then("all intervals for active settlement items should have non-zero payment and revenue values")
    public void iVerifyActiveIntervalsFinalValuesAreNonZero() throws Exception {
        assertFalse(activeSettlementItemIds.isEmpty(), "No active settlement_items found to verify!");

        List<String> itemIds = activeSettlementItemIds.stream()
                .map(row -> row.get("settlement_item_id").toString())
                .collect(Collectors.toList());

        String idList = itemIds.stream().map(id -> "'" + id + "'").collect(Collectors.joining(", "));
        String condition = String.format("settlement_item_id IN (%s)", idList);
        List<HashMap<String, Object>> intervals = client.selectRecordsTable(
                "settlement_item_intervals", condition, "settlement_item_id, interval_dttm_utc");

        assertFalse(intervals.isEmpty(), "No settlement_item_intervals found for active items!");

        int violations = 0;
        for (HashMap<String, Object> row : intervals) {
            violations += checkColumnNotZero(row, "payment_value");
            violations += checkColumnNotZero(row, "revenue_value");
            violations += checkColumnNotZero(row, "payment_value_estimated");
            violations += checkColumnNotZero(row, "revenue_value_estimated");
        }

        assertEquals(0, violations, String.format(
                "%d column check(s) for active settlement items had a value of exactly 0 (nulls are allowed)!",
                violations));
    }
}