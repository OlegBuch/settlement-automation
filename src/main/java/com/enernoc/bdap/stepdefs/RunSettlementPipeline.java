package com.enernoc.bdap.stepdefs;

import com.enernoc.bdap.model.Endpoint;
import com.enernoc.bdap.model.RequestContainer;
import com.enernoc.bdap.shared.Context;
import io.cucumber.datatable.DataTable;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.time.ZonedDateTime;
import java.util.*;

import static org.junit.jupiter.api.Assertions.*;

public class RunSettlementPipeline {

    private final Context context = Context.getContext();
    private RequestContainer request;

    private HashMap<String, Object> buildBodyFromTable(DataTable table) {
    Map<String, String> raw = table.asMap(String.class, String.class);

    HashMap<String, Object> body = new LinkedHashMap<>();

    String productIdsCsv = raw.get("product_ids");
    if (productIdsCsv != null && !productIdsCsv.isBlank()) {
        List<String> ids = new ArrayList<>();
        for (String token : productIdsCsv.split(",")) {
            String t = token.trim();
            if (!t.isEmpty()) ids.add(t);
        }
        body.put("product_ids", ids);
    }

    String mode = raw.get("mode");
    if (mode != null && !mode.isBlank()) body.put("mode", mode);

    String startDate = raw.get("start_date");
    if (startDate != null && !startDate.isBlank()) body.put("start_date", startDate);

    String endDate = raw.get("end_date");
    if (endDate != null && !endDate.isBlank()) body.put("end_date", endDate);

    return body;
}

    private void executePost(HashMap<String, Object> body, int defaultExpectedStatus) {
        request = RequestContainer.build();
        request.endpoint = Endpoint.POST_RUN_SETTLEMENT_PIPELINE;
        request.url = request.endpoint.baseUrl;

        var invokeDttm = ZonedDateTime.now().minusSeconds(1);
        long lambdaInvokeEpoch = invokeDttm.toEpochSecond();

        context.pipelineInvokeEpoch = invokeDttm.toEpochSecond();

        if (body != null) {
            request.getBodyProps().putAll(body);
        }

        var expectedStatus = context.popExpectedStatus(defaultExpectedStatus);
        request.call(expectedStatus);

        // Save response data to context for other stepdefs to access
        var dataList = request.getDataAsList();
        if (!dataList.isEmpty() && dataList.get(0) != null) {
            context.lastApiResponseData.clear();
            context.lastApiResponseData.putAll(dataList.get(0));
        }
    }

    @When("I POST a run-settlement-pipeline request with body")
    public void iPostRunSettlementPipelineRequestWithBody(DataTable table) {
        executePost(buildBodyFromTable(table), 200);
    }

    @When("I POST a run-settlement-pipeline request with raw JSON body")
    public void iPostRunSettlementPipelineRequestWithRawJsonBody(String json) {
        try {
            HashMap<String, Object> body = new com.fasterxml.jackson.databind.ObjectMapper()
                    .readValue(json, new com.fasterxml.jackson.core.type.TypeReference<>() {});
            executePost(body, 400);
        } catch (Exception e) {
            throw new IllegalArgumentException("Invalid JSON body: " + e.getMessage(), e);
        }
    }

    @Then("the run-settlement-pipeline response status should be {int}")
    public void runSettlementPipelineResponseStatusShouldBe(int expectedStatus) {
        assertNotNull(request, "No run-settlement-pipeline request made");
        assertEquals(expectedStatus, request.response.statusCode(),
                "Unexpected status code for run-settlement-pipeline");
    }

    @Then("the run-settlement-pipeline expected status should be returned")
    public void runSettlementPipelineExpectedStatusShouldBeReturned() {
        assertNotNull(request, "No run-settlement-pipeline request made");
        assertTrue(request.statusVerified,
                "Status was not verified for run-settlement-pipeline");
    }


}