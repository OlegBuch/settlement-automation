package com.enernoc.bdap.stepdefs;

import com.enernoc.bdap.model.APIResponses.GetProductRuleFragmentsResult;
import com.enernoc.bdap.model.APIResponses.PostProductRuleFragmentsResult;
import com.enernoc.bdap.model.APIResponses.PutProductRuleFragmentsResult;
import com.enernoc.bdap.model.Endpoint;
import com.enernoc.bdap.model.HttpStatus;
import com.enernoc.bdap.model.ProductRuleFragments;
import com.enernoc.bdap.model.RequestContainer;
import com.enernoc.bdap.shared.Context;
import com.enernoc.bdap.shared.Utility;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.cucumber.datatable.DataTable;
import io.cucumber.java.en.And;
import io.cucumber.java.en.Given;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;
import io.restassured.common.mapper.TypeRef;
import io.restassured.http.ContentType;
import io.restassured.response.ValidatableResponse;
import io.restassured.specification.RequestSpecification;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.*;

import static com.enernoc.bdap.model.EntityType.PRODUCT_RULE_FRAGMENT;
import static com.enernoc.bdap.model.EntityType.PRODUCT_RULE_FRAGMENTS;
import static com.enernoc.bdap.model.HttpOp.POST;
import static com.enernoc.bdap.model.HttpOp.PUT;
import static com.enernoc.bdap.shared.Utility.toStringObjectMap;
import static io.restassured.RestAssured.given;
import static org.junit.jupiter.api.Assertions.*;

public class CrudProductRuleFragments {

    private static final Logger LOG = LoggerFactory.getLogger(CrudProductRuleFragments.class);

    private final Context context = Context.getContext();
    private final Utility utility = new Utility();

    private RequestContainer request;
    private Long lastProductRuleFragmentId;
    private final Map<String, Long> savedIdsByTag = new HashMap<>();
    private static final ObjectMapper JSON = new ObjectMapper();
    private ValidatableResponse lastPutParametersVr;
    private HttpStatus lastPutExpectedStatus;

    //
    // Helpers
    //
    private Long getRequiredCurrentId() {
        assertNotNull(lastProductRuleFragmentId, "No current product rule fragment id set!");
        return lastProductRuleFragmentId;
    }

    private RequestSpecification buildRawSpec() {
        RequestSpecification spec = given()
                .header("x-enelx-trace-id", UUID.randomUUID());
        if (context.includeApiKey) {
            spec = spec.header("x-api-key", Context.metadataApiKey);
        }
        if (context.includeEnocSession) {
            spec = spec.header("enoc_session", Context.enocSession);
        }
        return spec;
    }

    /**
     * Parses ids from error messages like:
     * "Cannot delete X associated to Product Rule Details: 131, 133, 135"
     * "Cannot delete Product Rule Fragment associated to Parameters: 10"
     * "Cannot delete Product Rule Fragment associated to Groups: 42"
     */
    private List<Long> parseIdsFromError(String message, String marker) {
        int idx = message.indexOf(marker);
        if (idx == -1) return Collections.emptyList();

        String idsPart = message.substring(idx + marker.length()).trim();
        List<Long> ids = new ArrayList<>();
        for (String token : idsPart.split("[,\\s]+")) {
            token = token.trim().replaceAll("[^0-9]", "");
            if (!token.isEmpty()) {
                try {
                    ids.add(Long.parseLong(token));
                } catch (NumberFormatException ignored) {
                }
            }
        }
        return ids;
    }

    //
    // Context id operations
    //
    @Given("I set the context product rule fragment ID to {int}")
    public void iSetContextPrfIdToInt(int id) {
        this.lastProductRuleFragmentId = (long) id;
    }

    @Given("I set the context product rule fragment id to random valid id")
    public void iSetContextPrfIdToRandomValid() {
        this.lastProductRuleFragmentId = 1L;
    }

    @Given("I set the context product rule fragment ID to non-numeric")
    public void iSetContextPrfIdToNonNumeric() {
        context.savedValues.put("productRuleFragmentId", "non-numeric");
        this.lastProductRuleFragmentId = null;
    }

    @And("I save this product rule fragment id as {word}")
    public void iSavePrfIdAsTag(String tag) {
        Long id = getRequiredCurrentId();
        savedIdsByTag.put(tag, id);
        context.savedValues.put(tag, String.valueOf(id));
    }

    @Given("I set the context product rule fragment id to {word}")
    public void iSetContextPrfIdToTag(String tag) {
        assertTrue(savedIdsByTag.containsKey(tag), "No saved id for tag " + tag);
        this.lastProductRuleFragmentId = savedIdsByTag.get(tag);
    }

    @Given("I generate a random product rule fragment name and save it as {word}")
    public void iGenerateRandomProductRuleFragmentName(String key) {
        String randomName = "ParamLinkFragment_" + UUID.randomUUID().toString().substring(0, 8);
        context.savedValues.put(key, randomName);
    }

    //
    // Cleanup helper
    //
    @Given("I delete all existing product rule fragments with name {word}")
    public void iDeleteAllFragmentsWithName(String name) {
        request = RequestContainer.build()
                .getEntities(PRODUCT_RULE_FRAGMENTS);

        var result = request.call(context.popExpectedStatus(200))
                .getResponseEntity(GetProductRuleFragmentsResult.class);

        List<Long> ids = result.data().stream()
                .filter(p -> name.equals(p.name))
                .map(p -> Long.valueOf(p.id))
                .toList();

        if (ids.isEmpty()) {
            LOG.info("No product rule fragments found with name '{}', nothing to delete", name);
            return;
        }

        for (Long id : ids) {
            deleteFragmentWithCleanup(id, name);
        }
    }

    /**
     * Deletes fragment, handling blockers in this order:
     * 1. Details (via parameters)      → deleteProductRuleDetailsByIds
     * 2. Groups                        → unlinkFragmentFromGroup
     * 3. Parameters                    → unlinkAllParametersFromFragment
     */
    private void deleteFragmentWithCleanup(Long fragmentId, String name) {
        String url = String.format("%s/%d",
                Endpoint.GET_PRODUCT_RULE_FRAGMENT.baseUrl, fragmentId);

        var response = buildRawSpec()
                .contentType(ContentType.JSON)
                .when().delete(url)
                .then().extract();

        int status = response.statusCode();

        if (status == 204) {
            LOG.info("Deleted fragment id {} named '{}'", fragmentId, name);
            return;
        }

        if (status == 400) {
            String detail = response.path("detail") != null ? response.path("detail").toString() : "";
            LOG.info("Delete fragment {} blocked, detail: [{}]", fragmentId, detail);

            // Case 1: fragment indirectly blocked via parameter→details
            List<Long> detailIds = parseIdsFromError(detail, "Product Rule Details:");
            if (!detailIds.isEmpty()) {
                LOG.info("Fragment {} blocked via parameter→details {}. Deleting details first.",
                        fragmentId, detailIds);
                deleteProductRuleDetailsByIds(detailIds);
            }

            // Case 2: fragment blocked because still linked to groups
            List<Long> groupIds = parseIdsFromError(detail, "Groups:");
            if (!groupIds.isEmpty()) {
                LOG.info("Fragment {} still linked to groups {}. Unlinking first.", fragmentId, groupIds);
                for (Long groupId : groupIds) {
                    unlinkFragmentFromGroup(groupId);
                }
            }

            // Case 3: fragment blocked because it still has parameters
            // "Cannot delete Product Rule Fragment associated to Parameters: 10"
            List<Long> parameterIds = parseIdsFromError(detail, "Parameters:");
            if (!parameterIds.isEmpty()) {
                LOG.info("Fragment {} still linked to parameters {}. Unlinking all parameters from fragment.",
                        fragmentId, parameterIds);
                unlinkAllParametersFromFragment(fragmentId);
            }

            // Retry after cleanup
            var retryResponse = buildRawSpec()
                    .contentType(ContentType.JSON)
                    .when().delete(url)
                    .then().extract();

            int retryStatus = retryResponse.statusCode();

            if (retryStatus == 204) {
                LOG.info("Deleted fragment {} named '{}' after cleanup", fragmentId, name);
                return;
            }

            // After group/parameter unlink, details might newly surface
            String retryDetail = retryResponse.path("detail") != null
                    ? retryResponse.path("detail").toString() : "";

            List<Long> remainingDetailIds = parseIdsFromError(retryDetail, "Product Rule Details:");
            if (!remainingDetailIds.isEmpty()) {
                LOG.info("Fragment {} blocked by additional details {} after unlink. Deleting...",
                        fragmentId, remainingDetailIds);
                deleteProductRuleDetailsByIds(remainingDetailIds);

                int finalStatus = buildRawSpec()
                        .contentType(ContentType.JSON)
                        .when().delete(url)
                        .then().extract().statusCode();

                if (finalStatus == 204) {
                    LOG.info("Deleted fragment {} named '{}' after full cleanup", fragmentId, name);
                } else {
                    LOG.warn("Could not delete fragment {} named '{}' after full cleanup, status: {}",
                            fragmentId, name, finalStatus);
                }
            } else {
                LOG.warn("Still could not delete fragment {} named '{}', status: {}, detail: [{}]",
                        fragmentId, name, retryStatus, retryDetail);
            }
        } else {
            LOG.warn("Unexpected status {} deleting fragment {} named '{}'", status, fragmentId, name);
        }
    }

    private void deleteProductRuleDetailsByIds(List<Long> detailIds) {
        for (Long detailId : detailIds) {
            String url = String.format("%s/%d",
                    com.enernoc.bdap.model.Endpoint.GET_PRODUCT_RULE_DETAIL.baseUrl, detailId);

            int status = buildRawSpec()
                    .contentType(ContentType.JSON)
                    .when().delete(url)
                    .then().extract().statusCode();

            if (status == 204) {
                LOG.info("Deleted product rule detail id {}", detailId);
            } else {
                LOG.warn("Failed to delete product rule detail id {}, status: {}", detailId, status);
            }
        }
    }

    private void unlinkFragmentFromGroup(Long groupId) {
        String url = String.format("%s/productrulegroups/%s/fragments",
                Context.targetMetadataUrl, groupId);

        int status = buildRawSpec()
                .contentType(ContentType.JSON)
                .body(Collections.emptyList())
                .when().put(url)
                .then().extract().statusCode();

        LOG.info("Unlinked all fragments from group {} — status: {}", groupId, status);
    }

    /**
     * PUT [] to /productrulefragments/{id}/parameters to unlink all parameters from this fragment.
     */
    private void unlinkAllParametersFromFragment(Long fragmentId) {
        String url = String.format("%s/productrulefragments/%s/parameters",
                Context.targetMetadataUrl, fragmentId);

        int status = buildRawSpec()
                .contentType(ContentType.JSON)
                .body(Collections.emptyList())
                .when().put(url)
                .then().extract().statusCode();

        LOG.info("Unlinked all parameters from fragment {} — status: {}", fragmentId, status);
    }

    //
    // POST
    //
    @When("I POST a new product rule fragment specifying the following properties")
    public void iPostNewProductRuleFragment(DataTable table) {
        HashMap<String, Object> body = new HashMap<>(table.asMap(String.class, Object.class));

        body.replaceAll((_, v) -> {
            if (v instanceof String s && context.savedValues.containsKey(s)) {
                return context.savedValues.get(s);
            }
            return v;
        });

        utility.replaceParmValues(body);

        Object v = body.get("validator");
        if (v instanceof String s && s.trim().startsWith("{")) {
            try {
                Map<String, Object> obj = JSON.readValue(s, new TypeReference<>() {});
                body.put("validator", obj);
            } catch (Exception e) {
                throw new IllegalArgumentException("Invalid JSON for validator: " + s, e);
            }
        }

        request = RequestContainer.build()
                .submitEntity(POST, PRODUCT_RULE_FRAGMENT, body);

        var expected = context.popExpectedStatus(201);
        var entity = request.call(expected)
                .getResponseEntity(PostProductRuleFragmentsResult.class);

        if (expected.getCode() == 201) {
            ProductRuleFragments prf = entity.data();
            assertNotNull(prf);
            this.lastProductRuleFragmentId = Long.valueOf(prf.id);
        }
    }

    @Then("the response should include the new product rule fragment")
    public void responseShouldIncludeNewPrf() throws JsonProcessingException {
        Map<String, Object> resp = request.getDataAsList().get(0);

        assertNotNull(lastProductRuleFragmentId, "No product rule fragment id saved");
        assertEquals(
                String.valueOf(lastProductRuleFragmentId),
                String.valueOf(resp.get("id")),
                "Unexpected id in response"
        );

        assertEquals(request.getBodyProps().get("name"), resp.get("name"));
        assertEquals(request.getBodyProps().get("description"), resp.get("description"));

        Object respValidatorObj = resp.get("validator");
        assertInstanceOf(Map.class, respValidatorObj, "validator must be an object in response");

        Object reqValidatorRaw = request.getBodyProps().get("validator");
        Map<String, Object> expectedValidator;
        if (reqValidatorRaw instanceof String s) {
            expectedValidator = JSON.readValue(s, new TypeReference<>() {});
        } else {
            expectedValidator = toStringObjectMap(reqValidatorRaw);
        }

        Map<String, Object> actualValidator = toStringObjectMap(respValidatorObj);
        assertEquals(expectedValidator, actualValidator, "validator does not match");
    }

    @Then("the product rule fragment response should contain fields")
    public void prfResponseShouldContainFields(DataTable table) {
        Set<String> required = new HashSet<>(table.asList());
        Map<String, Object> respMap = request.getDataAsList().get(0);
        for (String field : required) {
            assertTrue(respMap.containsKey(field), "Missing field: " + field);
        }
    }

    //
    // GET all
    //
    @When("I GET all product rule fragments")
    public void iGetAllPrfs() {
        request = RequestContainer.build()
                .getEntities(PRODUCT_RULE_FRAGMENTS);
        request.call(context.popExpectedStatus(200));
    }

    @Then("the product rule fragments list should be returned")
    public void prfListShouldBeReturned() {
        assertFalse(request.getDataAsList().isEmpty(), "No product rule fragments returned!");
    }

    @Then("the product rule fragments list should contain my fragment")
    public void listShouldContainMyFragment() {
        Long id = getRequiredCurrentId();
        boolean found = request.getDataAsList().stream()
                .anyMatch(m -> String.valueOf(id).equals(Objects.toString(m.get("id"), null)));
        assertTrue(found, "Current product rule fragment id not found in list");
    }

    //
    // GET by id
    //
    @When("I GET the product rule fragment by id")
    public void iGetPrfById() {
        String idStr;
        if (context.savedValues.containsKey("productRuleFragmentId")) {
            idStr = context.savedValues.get("productRuleFragmentId");
        } else {
            idStr = String.valueOf(getRequiredCurrentId());
        }
        request = RequestContainer.build()
                .getEntity(PRODUCT_RULE_FRAGMENT, idStr);
        var expected = context.popExpectedStatus(200);
        request.call(expected);
    }

    @Then("GET product rule fragment should return the current state")
    public void getPrfShouldReturnCurrentState() {
        Map<String, Object> respMap = Collections.unmodifiableMap(request.getDataAsList().get(0));
        String idStr = Objects.toString(respMap.getOrDefault("id", "No id!"));
        assertEquals(String.valueOf(getRequiredCurrentId()), idStr);
    }

    //
    // GET with include_parameters=true
    //
    @When("I GET the product rule fragment by id including parameters")
    public void iGetPrfByIdIncludingParameters() {
        String idStr;
        if (context.savedValues.containsKey("productRuleFragmentId")) {
            idStr = context.savedValues.get("productRuleFragmentId");
        } else {
            idStr = String.valueOf(getRequiredCurrentId());
        }

        request = RequestContainer.build()
                .getEntity(PRODUCT_RULE_FRAGMENT, idStr)
                .addQueryParm("include_parameters", "true");

        var expected = context.popExpectedStatus(200);
        request.call(expected);
    }

    @Then("the product rule fragment should include parameter ids")
    public void prfShouldIncludeParameterIds(DataTable table) {
        List<Integer> expectedIds = table.asList().stream()
                .map(String::trim)
                .filter(s -> !s.isEmpty())
                .map(Integer::valueOf)
                .toList();

        Map<String, Object> resp = request.getDataAsList().get(0);
        Object idsObj = resp.get("product_rule_parameter_ids");
        assertNotNull(idsObj, "product_rule_parameter_ids is missing");
        assertInstanceOf(List.class, idsObj, "product_rule_parameter_ids is not a list");

        @SuppressWarnings("unchecked")
        List<Object> actualRaw = (List<Object>) idsObj;
        List<Integer> actualIds = actualRaw.stream()
                .map(o -> Integer.valueOf(String.valueOf(o)))
                .toList();

        assertEquals(expectedIds, actualIds, "product_rule_parameter_ids does not match expected");
    }

    @When("I GET the product rule fragment by id including parameters value {string}")
    public void iGetPrfByIdIncludingParametersValue(String value) {
        String idStr;
        if (context.savedValues.containsKey("productRuleFragmentId")) {
            idStr = context.savedValues.get("productRuleFragmentId");
        } else {
            idStr = String.valueOf(getRequiredCurrentId());
        }

        request = RequestContainer.build()
                .getEntity(PRODUCT_RULE_FRAGMENT, idStr)
                .addQueryParm("include_parameters", value);

        var expected = context.popExpectedStatus(400);
        request.call(expected);
    }

    @Then("the GET response should include an empty product_rule_parameter_ids array")
    public void getResponseShouldIncludeEmptyProductRuleParameterIds() {
        Object rawData = request.responseMap.get("data");
        assertInstanceOf(Map.class, rawData, "data is not a map");
        Map<?, ?> data = (Map<?, ?>) rawData;
        Object ids = data.get("product_rule_parameter_ids");
        assertInstanceOf(List.class, ids, "product_rule_parameter_ids is not a list");
        assertTrue(((List<?>) ids).isEmpty(), "product_rule_parameter_ids is not empty");
    }

    //
    // PUT
    //
    @When("I update the product rule fragment with new values")
    public void iPutPrf(DataTable table) {
        HashMap<String, Object> body = new HashMap<>(table.asMap(String.class, Object.class));
        utility.replaceParmValues(body);
        String id;

        if (context.savedValues.containsKey("productRuleFragmentId")) {
            id = context.savedValues.get("productRuleFragmentId");
        } else {
            id = String.valueOf(getRequiredCurrentId());
        }

        Object v = body.get("validator");
        if (v instanceof String s && s.trim().startsWith("{")) {
            try {
                Map<String, Object> obj = JSON.readValue(s, new TypeReference<>() {});
                body.put("validator", obj);
            } catch (Exception e) {
                throw new IllegalArgumentException("Invalid JSON for validator: " + s, e);
            }
        }

        request = RequestContainer.build()
                .submitEntity(PUT, PRODUCT_RULE_FRAGMENT, body)
                .addIdToPath(id);

        var expected = context.popExpectedStatus(200);
        var resp = request.call(expected);
        if (expected.getCode() == 200) {
            var entity = resp.getResponseEntity(PutProductRuleFragmentsResult.class);
            ProductRuleFragments prf = entity.data();
            this.lastProductRuleFragmentId = Long.valueOf(prf.id);
        }
    }

    @Then("the response should include the updated product rule fragment")
    public void responseShouldIncludeUpdatedPrf() {
        Map<String, Object> respMap = request.getDataAsList().get(0);
        String idStr = Objects.toString(respMap.getOrDefault("id", "No id!"));
        assertEquals(String.valueOf(getRequiredCurrentId()), idStr);
    }

    @Then("the PUT parameters expected status should be returned")
    public void putParametersExpectedStatusShouldBeReturned() {
        assertNotNull(lastPutParametersVr, "No PUT parameters response captured");
        assertNotNull(lastPutExpectedStatus, "No expected status saved for PUT parameters");

        var resp = lastPutParametersVr.extract().as(new TypeRef<Map<String, Object>>() {});
        Object detailObj = resp.getOrDefault("detail", resp.get("message"));
        String actualDetail = detailObj == null ? "" : detailObj.toString();

        int actualCode = lastPutParametersVr.extract().statusCode();
        assertEquals(lastPutExpectedStatus.code, actualCode,
                "Unexpected status code for PUT parameters");

        String expectedSubstring = lastPutExpectedStatus.message;
        if (expectedSubstring != null && !expectedSubstring.isBlank()) {
            assertTrue(actualDetail.contains(expectedSubstring),
                    "Actual detail does not contain expected substring. " +
                            "Expected to contain: '" + expectedSubstring + "', actual: '" + actualDetail + "'");
        }
    }

    //
    // PUT /product-rule-fragments/{fragment_id}/parameters
    //
    @When("I PUT parameters {string} for the current product rule fragment")
    public void iPutParametersListForCurrentFragment(String paramsSpec) {
        Long fragmentId = getRequiredCurrentId();

        Object body;
        if ("EMPTY".equals(paramsSpec)) {
            body = new ArrayList<HashMap<String, Object>>();
        } else {
            List<HashMap<String, Object>> params = new ArrayList<>();
            for (String token : paramsSpec.split("\\s+")) {
                if (token.isBlank()) continue;
                String[] parts = token.split(",");
                if (parts.length != 2) {
                    throw new IllegalArgumentException("Invalid parameter token: " + token);
                }

                String idRaw = parts[0].trim();
                String resolvedId = context.savedValues.getOrDefault(idRaw, idRaw);

                HashMap<String, Object> m = new HashMap<>();
                m.put("pr_parameter_def_id", Integer.parseInt(resolvedId));
                m.put("required", Boolean.parseBoolean(parts[1].trim()));
                params.add(m);
            }
            body = params;
        }

        String url = String.format("%s/%d/parameters",
                Endpoint.GET_PRODUCT_RULE_FRAGMENT.baseUrl, fragmentId);

        lastPutExpectedStatus = context.popExpectedStatus(200);

        var spec = given();
        if (context.includeApiKey) {
            spec = spec.header("x-api-key", Context.metadataApiKey);
        }
        if (context.includeEnocSession) {
            spec = spec.header("enoc_session", Context.enocSession);
        }
        spec = spec.header("x-enelx-trace-id", UUID.randomUUID());

        lastPutParametersVr = (context.logAllAPIRequests ? spec.log().all(true) : spec.log().method().log().uri())
                .contentType(ContentType.JSON)
                .body(body)
                .when().put(url)
                .then();

        if (context.logAllAPIResponses) {
            lastPutParametersVr = lastPutParametersVr.log().all(true);
        }
    }

    @When("I PUT {int} parameters for the current product rule fragment expecting HTTP status {int}")
    public void iPutNParametersForCurrentFragmentWithStatus(int count, int expectedStatus) {
        Long fragmentId = getRequiredCurrentId();

        List<Map<String, Object>> params = new ArrayList<>();
        for (int i = 1; i <= count; i++) {
            Map<String, Object> m = new HashMap<>();
            m.put("pr_parameter_def_id", i);
            m.put("required", true);
            params.add(m);
        }

        String url = String.format("%s/%d/parameters",
                Endpoint.GET_PRODUCT_RULE_FRAGMENT.baseUrl, fragmentId);

        var spec = given();
        if (context.includeApiKey) {
            spec = spec.header("x-api-key", Context.metadataApiKey);
        }
        if (context.includeEnocSession) {
            spec = spec.header("enoc_session", Context.enocSession);
        }
        spec = spec.header("x-enelx-trace-id", UUID.randomUUID());

        lastPutExpectedStatus = context.popExpectedStatus(200);
        lastPutExpectedStatus.code = expectedStatus;

        lastPutParametersVr = (context.logAllAPIRequests ? spec.log().all(true) : spec.log().method().log().uri())
                .contentType(ContentType.JSON)
                .body(params)
                .when().put(url)
                .then();

        if (context.logAllAPIResponses) {
            lastPutParametersVr = lastPutParametersVr.log().all(true);
        }
    }

    //
    // DELETE
    //
    @When("I DELETE my product rule fragment")
    public void iDeleteMyPrf() {
        String id;
        if (context.savedValues.containsKey("productRuleFragmentId")) {
            id = context.savedValues.get("productRuleFragmentId");
        } else {
            id = String.valueOf(getRequiredCurrentId());
        }
        request = RequestContainer.build()
                .deleteEntity(PRODUCT_RULE_FRAGMENT, id);
        request.call(context.popExpectedStatus(204));
    }

    @When("I delete the current product rule fragment")
    public void iDeleteTheCurrentProductRuleFragment() {
        Long fragmentId = getRequiredCurrentId();
        String url = String.format("%s/%d", Endpoint.DELETE_PRODUCT_RULE_FRAGMENT.baseUrl, fragmentId);

        var expected = context.popExpectedStatus(200);
        var spec = given();
        if (context.includeApiKey) {
            spec = spec.header("x-api-key", Context.metadataApiKey);
        }
        if (context.includeEnocSession) {
            spec = spec.header("enoc_session", Context.enocSession);
        }
        spec = spec.header("x-enelx-trace-id", UUID.randomUUID());

        var resp = spec.when().delete(url).then();
        resp.statusCode(expected.code);
    }

    @When("I DELETE my product rule fragment with id 1 and get 403 status code")
    public void iDeleteMyPrf403() {
        String id = "1"; // ID doesn't matter — 403 is returned before resource lookup

        request = RequestContainer.build()
                .deleteEntity(PRODUCT_RULE_FRAGMENT, id);
        request.call(context.popExpectedStatus(403));
    }
}