package com.enernoc.bdap.stepdefs;

import com.enernoc.bdap.model.Endpoint;
import com.enernoc.bdap.model.RequestContainer;
import com.enernoc.bdap.shared.Context;
import io.cucumber.java.en.Given;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

public class EcoAdhocFinancialSearch {

    private static final Logger LOG = LoggerFactory.getLogger(EcoAdhocFinancialSearch.class);
    private final Context context = Context.getContext();
    private RequestContainer request;

    // ──────────────────────────────────────────────
    // Header Setup Steps (Authorization + enoc_session)
    // ──────────────────────────────────────────────

    @Given("I include valid Authorization and enoc_session headers")
    public void iIncludeValidAuthAndSessionHeaders() {
        context.includeAuthorization = true;
        // Adjust "Bearer valid-token" to match how your framework generates/fetches valid tokens
        context.authorizationToken = null;
        context.includeEnocSession = true;
        LOG.info("Valid Authorization and enoc_session headers will be sent");
    }

    @Given("I include valid Authorization header")
    public void iIncludeValidAuthorizationHeader() {
        context.includeAuthorization = true;
        context.authorizationToken = "Bearer valid-token";
        LOG.info("Valid Authorization header will be sent");
    }

    @Given("I include valid enoc_session header")
    public void iIncludeValidEnocSessionHeader() {
        context.includeEnocSession = true;
        LOG.info("Valid enoc_session header will be sent");
    }

    @Given("I omit the Authorization header")
    public void iOmitAuthorizationHeader() {
        context.includeAuthorization = false;
        LOG.info("Authorization header will be omitted");
    }

    @Given("I provide an empty Authorization header value")
    public void iProvideEmptyAuthorizationHeaderValue() {
        context.includeAuthorization = true;
        context.authorizationToken = "";
        LOG.info("Authorization header will be sent with an empty value");
    }

    @Given("I omit the enoc_session header")
    public void iOmitEnocSessionHeader() {
        context.includeEnocSession = false;
        LOG.info("enoc_session header will be omitted");
    }

    @Given("I provide an empty enoc_session header value")
    public void iProvideEmptyEnocSessionHeaderValue() {
        context.includeEnocSession = true;
        context.enocSession = "";
        LOG.info("enoc_session header will be sent with an empty value");
    }


    // ──────────────────────────────────────────────
    // Query Parameter Setup Steps
    // ──────────────────────────────────────────────

    @Given("I set the search query parameter id to {string} and id_type to {string}")
    public void iSetSearchQueryParams(String id, String idType) {
        String actualId = resolveEnvSpecificId(id);
        context.searchId = actualId;
        context.searchIdType = idType;
        context.extraQueryParams = new HashMap<>();
        LOG.info("Search query params set: id={}, id_type={}", actualId, idType);
    }

    @Given("I set the search query parameter id to {string}")
    public void iSetSearchQueryParamId(String id) {
        String actualId = resolveEnvSpecificId(id);
        context.searchId = actualId;
        LOG.info("Search query param id set to: {}", actualId);
    }

    @Given("I set duplicate search query parameters with id {string}, id_type {string} and {string}")
    public void iSetDuplicateIdTypeParams(String id, String idType1, String idType2) {
        String actualId = resolveEnvSpecificId(id);
        context.searchId = actualId;
        context.searchIdType = idType1;
        context.searchIdTypeDuplicate = idType2;
        context.isDuplicateIdType = true;
        LOG.info("Duplicate id_type query parameters set: {} and {} (id={})", idType1, idType2, actualId);
    }

    @Given("I set the search query parameter id_type to {string}")
    public void iSetSearchQueryParamIdType(String idType) {
        context.searchIdType = idType;
        LOG.info("Search query param id_type set to: {}", idType);
    }

    @Given("I omit the id query parameter")
    public void iOmitIdQueryParam() {
        context.searchId = null;
        LOG.info("id query parameter will be omitted");
    }

    @Given("I provide an empty id query parameter value")
    public void iProvideEmptyIdQueryParamValue() {
        context.searchId = "";
        LOG.info("id query parameter will be sent with an empty value");
    }

    @Given("I omit the id_type query parameter")
    public void iOmitIdTypeQueryParam() {
        context.searchIdType = null;
        LOG.info("id_type query parameter will be omitted");
    }

    @Given("I add an extra query parameter {string} with value {string}")
    public void iAddExtraQueryParam(String key, String value) {
        if (context.extraQueryParams == null) {
            context.extraQueryParams = new HashMap<>();
        }
        context.extraQueryParams.put(key, value);
        LOG.info("Extra query parameter added: {}={}", key, value);
    }

    // ──────────────────────────────────────────────
    // Action Steps
    // ──────────────────────────────────────────────

    @When("I POST to the adhoc financial search endpoint")
    public void iPostToAdhocFinancialSearchEndpoint() {
        StringBuilder queryParams = new StringBuilder();
        boolean first = true;

        if (context.searchId != null) {
            queryParams.append(first ? "" : "&").append("id=").append(context.searchId);
            first = false;
        }
        if (context.searchIdType != null) {
            queryParams.append(first ? "" : "&").append("id_type=").append(context.searchIdType);
            first = false;
        }
        if (context.isDuplicateIdType != null && context.isDuplicateIdType) {
            queryParams.append(first ? "" : "&").append("id_type=").append(context.searchIdTypeDuplicate);
            first = false;
        }
        if (context.extraQueryParams != null && !context.extraQueryParams.isEmpty()) {
            for (Map.Entry<String, String> entry : context.extraQueryParams.entrySet()) {
                queryParams.append(first ? "" : "&").append(entry.getKey()).append("=").append(entry.getValue());
                first = false;
            }
        }

        String qs = queryParams.toString();
        String endpoint = "/api/v1/adhoc-financial/search";

        // Build the request with the dynamically constructed query string
        request = RequestContainer.build()
                .postWithEcoUrl(endpoint, qs.isEmpty() ? "" : "?" + qs);

        // Execute the call. Adjust the expected status parameter based on your RequestContainer implementation.
        // If your framework asserts inside .call(), you may need to pass context.popExpectedStatus(200) here.
        request.call(context.popExpectedStatus(200));
    }

    @Then("the response data array should not be empty")
    public void theResponseDataArrayShouldNotBeEmpty() {
        assertNotNull(request, "Request was not executed!");
        assertNotNull(request.response, "Response object is null!");

        List<Object> dataList = request.response.jsonPath().getList("data");
        assertNotNull(dataList, "The 'data' field is missing or null in the response!");
        assertFalse(dataList.isEmpty(), "The 'data' array is empty, but expected at least one record!");

        LOG.info("Successfully verified data array is not empty. Found {} records.", dataList.size());
    }

    @Then("the response data array should be empty")
    public void theResponseDataArrayShouldBeEmpty() {
        assertNotNull(request, "Request was not executed!");
        assertNotNull(request.response, "Response object is null!");

        List<Object> dataList = request.response.jsonPath().getList("data");
        // Treat null or [] as empty
        assertTrue(dataList == null || dataList.isEmpty(),
                "The 'data' array should be empty, but found " + (dataList != null ? dataList.size() : 0) + " records!");

        LOG.info("Successfully verified data array is empty.");
    }

    @When("I POST to the external adhoc financial search endpoint")
    public void iPostToExternalAdhocFinancialSearchEndpoint() {
        StringBuilder queryParams = new StringBuilder();
        boolean first = true;

        if (context.searchId != null) {
            queryParams.append(first ? "" : "&").append("id=").append(context.searchId);
            first = false;
        }
        if (context.searchIdType != null) {
            queryParams.append(first ? "" : "&").append("id_type=").append(context.searchIdType);
            first = false;
        }
        if (context.isDuplicateIdType != null && context.isDuplicateIdType) {
            queryParams.append(first ? "" : "&").append("id_type=").append(context.searchIdTypeDuplicate);
            first = false;
        }
        if (context.extraQueryParams != null && !context.extraQueryParams.isEmpty()) {
            for (Map.Entry<String, String> entry : context.extraQueryParams.entrySet()) {
                queryParams.append(first ? "" : "&").append(entry.getKey()).append("=").append(entry.getValue());
                first = false;
            }
        }

        String qs = queryParams.toString();

        // Build the request container
        request = RequestContainer.build();

        // 👇 OVERRIDE URL: Use the external URL from Context instead of the internal ecoUrl 👇
        assertNotNull(Context.ecoExternalUrlFinancialSearch, "External ECO Financial Search URL is not configured in configuration.json!");
        request.url = Context.ecoExternalUrlFinancialSearch + (qs.isEmpty() ? "" : "?" + qs);
        request.endpoint = Endpoint.POST_ADHOC_FINANCIAL_API_SEARCH;

        LOG.info("🎯 Targeting EXTERNAL ECO Search URL: {}", request.url);

        // Execute the call
        request.call(context.popExpectedStatus(200));
    }

    private String resolveEnvSpecificId(String idAlias) {
        if ("VALID_ORG_ID".equals(idAlias)) {
            // Assuming Context.deployment holds "dev", "pre-prd", "prod", etc.
            String env = Context.targetEnv != null ? Context.targetEnv.toLowerCase() : "dev";

            if (env.contains("pre")) {
                return "cad9f99e-0dd3-4934-98b1-40f812e9dbb5"; // Pre-Prd
            } else {
                return "a85920a4-f1d4-41aa-8cdf-95f58382a8dc"; // Dev ID (Default)
            }
        }
            return idAlias;
    }
}