package com.enernoc.bdap.stepdefs;

import com.enernoc.bdap.model.APIResponses;
import com.enernoc.bdap.model.PipelineStateItem;
import com.enernoc.bdap.model.RequestContainer;
import com.enernoc.bdap.shared.Context;
import com.enernoc.bdap.shared.Utility;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.cucumber.datatable.DataTable;
import io.cucumber.java.en.And;
import io.cucumber.java.en.Given;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.concurrent.atomic.AtomicBoolean;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

public class PipelineStateHistory {

    private static final Logger LOG = LoggerFactory.getLogger("PipelineStateHistory");
    private static final ObjectMapper JSON = new ObjectMapper();
    private final Context context = Context.getContext();
    private RequestContainer request;
    private final Utility utility = new Utility();
    private HashMap<String, Object> savedParams;
    private ZonedDateTime timeReference;

    private enum ItemLevel {SETTLEMENT, SETTLEMENT_ITEM}

    private void getPipelineStateHistoryItems(HashMap<String, Object> props) throws JsonProcessingException {
        request = RequestContainer.build().getPipelineStateHistoryItem(props);
        context.lastPipelineStateItems = request.call(context.popExpectedStatus(200)).getResponseEntity(APIResponses.GetPipelineStateResult.class).data();
        LOG.info("Retrieved pipeline state history items from GET request: {}", JSON.writerWithDefaultPrettyPrinter().writeValueAsString(context.lastPipelineStateItems));
    }

    private void switchSavedParams(HashMap<String, Object> queryMap) {
        queryMap.entrySet().stream().forEach(entry -> {
            if (!Objects.equals("<uuid>", entry.getValue()) && savedParams.containsKey(entry.getKey())) {
                if (entry.getValue().toString().startsWith("<") && entry.getValue().toString().endsWith(">")) {
                    queryMap.replace(entry.getKey(), savedParams.get(entry.getKey()));
                }
            } else if (Objects.equals("created_dttm_before_utc", entry.getKey()) && Objects.equals("<saved_time_reference>", entry.getValue())) {
                queryMap.replace(entry.getKey(), timeReference.withZoneSameInstant(ZoneId.of("UTC")).format(DateTimeFormatter.ISO_OFFSET_DATE_TIME));
            }
        });
    }

    private void checkStepsAndStatusForId(String settlement_id, String settlement_item_id, String step, String status, String mode) {
        List<PipelineStateItem> filteredItems = context.lastPipelineStateItems.stream().filter(item -> Objects.equals(item.settlement_id, settlement_id) && Objects.equals(item.settlement_item_id, settlement_item_id) && Objects.equals(item.pipeline_step, step) && Objects.equals(item.status, status) && (mode == null || Objects.equals(item.mode, mode))).toList();
        assertEquals(1, filteredItems.size(), "Expected pipeline state history item not found - settlement_id: " + settlement_id + " - settlement_item_id: " + settlement_item_id + " - step: " + step + " - status: " + status + " - mode: " + mode);
    }

    @When("I GET the pipeline state history items with:")
    public void iGETThePipelineStateHistoryItemsWith(DataTable dataTable) throws JsonProcessingException {
        var queryMap = new HashMap<>(dataTable.asMap(String.class, Object.class));
        if (savedParams != null)
            switchSavedParams(queryMap);
        utility.replaceParmValues(queryMap); // perform general utility replacements (e.g. <last-settlement-id>)
        getPipelineStateHistoryItems(queryMap);
    }

    @When("I read \\(GET) the same pipeline state history item")
    public void iReadGETTheSamePipelineStateHistoryItem() throws JsonProcessingException {
        Object settlementId = savedParams.get("settlement_id");
        HashMap<String, Object> queryMap = new HashMap<>(Map.of("settlement_id", settlementId));
        getPipelineStateHistoryItems(queryMap);
    }

    @Given("I consider as expected a pipeline state history item with the following properties:")
    public void iConsiderAsExpectedAPipelineStateHistoryItemWithTheFollowingProperties(DataTable dataTable) {
        var params = new HashMap<>(dataTable.asMap(String.class, Object.class));
        if (savedParams != null)
            switchSavedParams(params);
        utility.replaceParmValues(params);
        savedParams = params;
        if (params.containsKey("pipeline_run_id")) {
            context.lastPipelineRunId = params.get("pipeline_run_id").toString();
        }
    }

    @Given("I consider as expected for the new entity a pipeline state history item with the following properties:")
    public void iConsiderAsExpectedForTheNewEntityAPipelineStateHistoryItemWithTheFollowingProperties(DataTable dataTable) {
        savedParams = null;
        iConsiderAsExpectedAPipelineStateHistoryItemWithTheFollowingProperties(dataTable);
    }

    @When("I create \\(POST) that item")
    public void iCreatePOSTExpectedItem() throws JsonProcessingException {
        request = RequestContainer.build().postPipelineStateHistoryItem(savedParams);
        context.lastPipelineStateItems = Collections.singletonList(request.call(context.popExpectedStatus(201)).getResponseEntity(APIResponses.PostPipelineStateResult.class).data());
        LOG.info("Created pipeline state history items from POST request: {}", JSON.writerWithDefaultPrettyPrinter().writeValueAsString(context.lastPipelineStateItems));
    }

    @When("I create \\(POST) a faulty item with those properties")
    public void iPostFaultyItem() {
        RequestContainer.build().postPipelineStateHistoryItem(savedParams).call(context.popExpectedStatus());
    }

    @When("I create \\(POST) a faulty item with no properties")
    public void iCreatePOSTAFaultyItemWithNoProperties() {
        RequestContainer.build().postPipelineStateHistoryItem(null).call(context.popExpectedStatus());
    }

    @Then("the expected pipeline item should be returned in the response")
    public void theExpectedPipelineItemShouldBeReturnedInTheResponse() {
        //var actual = JSON.convertValue(lastReturnedItems.get(0), HashMap.class);
        boolean itemIsInResponse = false;
        for (PipelineStateItem item : context.lastPipelineStateItems) {
            itemIsInResponse = checkActualsAgainstSavedStateParams(JSON.convertValue(item, HashMap.class));
            if (itemIsInResponse) {
                break;
            }
        }
        assertTrue(itemIsInResponse, "Expected pipeline state history item not found in response");
    }

    private <T> boolean checkActualsAgainstSavedStateParams(T actual) {
        AtomicBoolean itemsDoMatch = new AtomicBoolean(false);
        if (actual instanceof HashMap) {
            savedParams.keySet().forEach(key -> {
                assertTrue(((HashMap<?, ?>) actual).containsKey(key), "Expected field not found: " + key);

                // Use String.valueOf() to handle nulls gracefully
                String expectedVal = String.valueOf(savedParams.get(key));
                Object actualObj = ((HashMap<?, ?>) actual).get(key);
                String actualVal = (actualObj == null) ? "null" : actualObj.toString();

                itemsDoMatch.set(Utility.testObjsEqual(key, expectedVal, actualVal));
            });
        }
        return itemsDoMatch.get();
    }

    @Then("the number of returned items should be {int}")
    public void theNumberOfReturnedItemsShouldBe(int numberOfReturnedItems) {
        assertEquals(numberOfReturnedItems, context.lastPipelineStateItems.size(), "Number of returned items does not match expected");
    }

    @Given("I save a time reference")
    public void iSaveATimeReference() {
        timeReference = ZonedDateTime.now();
    }


    @And("the pipeline state for that settlement should have just been initialized")
    public void thePipelineStateForThatSettlementShouldHaveJustBeenInitialized() throws JsonProcessingException {
        getPipelineStateHistoryItems(new HashMap<>(Map.of("settlement_id", context.lastSettlementId)));
        assertTrue(context.lastPipelineStateItems.isEmpty(), "Found pipeline state history items for newly created settlement with ID: " + context.lastSettlementId);
    }

    @And("I GET all the pipeline states for that pipeline run")
    public void iGETAllThePipelineStatesForThatPipelineRun() throws JsonProcessingException {
        getPipelineStateHistoryItems(new HashMap<>(Map.of("pipeline_run_id", context.lastPipelineRunId)));
    }

    @Then("for each of the following settlements I should find the corresponding states:")
    public void forEachOfTheFollowingSettlementsIShouldFindTheCorrespondingStates(DataTable dataTable) {
        var settlements = dataTable.asMaps();
        for (Map<String, String> row : settlements) {
            HashMap<String, Object> settlement = new HashMap<>(row);
            utility.replaceParmValues(settlement);
            String mode = settlement.get("mode") != null ? settlement.get("mode").toString() : null;
            checkStepsAndStatusForId(settlement.get("settlement-id").toString(), settlement.get("settlement-item-id") == null ? null : settlement.get("settlement-item-id").toString(), settlement.get("step").toString(), settlement.get("status").toString(), mode);
        }
    }

    @Then("for each of the following settlements I should find a single pipeline state history item:")
    public void forEachOfTheFollowingSettlementsIShouldFindASinglePipelineStateHistoryItem(DataTable dataTable) {
        // The following methods already checks that for each row we get a single item. Here we are just using a more descriptive name
        forEachOfTheFollowingSettlementsIShouldFindTheCorrespondingStates(dataTable);
    }

    @And("I save the settlement item id as dlq-settlement-item-id")
    public void iSaveTheSettlementItemIdAsDlqSettlementItemId() {
        context.lastDlqSettlementItemId = context.lastPipelineStateItems.get(0).settlement_item_id;
    }

    @And("I save the settlement item id as settlement-item-id-{int}")
    public void iSaveTheSettlementItemIdAsSettlementItemId(int savedItemIndex) {
        assertTrue(savedItemIndex ==1 || savedItemIndex == 2, "Invalid saved item index");
        if (savedItemIndex == 1)
            context.savedSettlementItemId1 = context.lastPipelineStateItems.get(0).settlement_item_id;
        else
            context.savedSettlementItemId2 = context.lastPipelineStateItems.get(0).settlement_item_id;
    }
}
