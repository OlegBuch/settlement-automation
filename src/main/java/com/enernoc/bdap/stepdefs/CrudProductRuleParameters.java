package com.enernoc.bdap.stepdefs;

import com.enernoc.bdap.model.APIResponses.GetProductRuleParametersResult;
import com.enernoc.bdap.model.APIResponses.GetProductRulesResult;
import com.enernoc.bdap.model.APIResponses.PostProductRuleParameterResult;
import com.enernoc.bdap.model.APIResponses.PutProductRuleParameterResult;
import com.enernoc.bdap.model.ProductRuleParameters;
import com.enernoc.bdap.model.ProductRules;
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
import io.restassured.http.ContentType;
import io.restassured.specification.RequestSpecification;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.*;

import static com.enernoc.bdap.model.EntityType.PRODUCT_RULE_PARAMETER;
import static com.enernoc.bdap.model.EntityType.PRODUCT_RULE_PARAMETERS;
import static com.enernoc.bdap.model.HttpOp.POST;
import static com.enernoc.bdap.model.HttpOp.PUT;
import static com.enernoc.bdap.shared.Utility.toStringObjectMap;
import static io.restassured.RestAssured.given;
import static org.junit.jupiter.api.Assertions.*;

public class CrudProductRuleParameters {

    private static final Logger LOG = LoggerFactory.getLogger(CrudProductRuleParameters.class);

    private final Context context = Context.getContext();
    private final Utility utility = new Utility();

    private RequestContainer request;
    private Long lastProductRuleParameterId;
    private final Map<String, Long> savedIdsByTag = new HashMap<>();
    private static final ObjectMapper JSON = new ObjectMapper();

    //
    // Helpers
    //
    private Long getRequiredCurrentId() {
        assertNotNull(lastProductRuleParameterId, "No current product rule parameter id set!");
        return lastProductRuleParameterId;
    }

    /**
     * Shared raw RestAssured spec with headers.
     */
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

    //
    // Auth / header control
    //
    @Given("I do not include the ENOC session header")
    public void iDoNotIncludeEnocSession() {
        context.includeEnocSession = false;
    }

    @Given("I do not include the API key header")
    public void iDoNotIncludeApiKey() {
        context.includeApiKey = false;
    }

    //
    // Context id operations
    //
    @Given("I set the context product rule parameter ID to {int}")
    public void iSetContextPrpIdToInt(int id) {
        this.lastProductRuleParameterId = (long) id;
    }

    @Given("I set the context product rule parameter id to random valid id")
    public void iSetContextPrpIdToRandomValid() {
        this.lastProductRuleParameterId = 1L;
    }

    @Given("I set the context product rule parameter ID to non-numeric")
    public void iSetContextPrpIdToNonNumeric() {
        context.savedValues.put("productRuleParamId", "non-numeric");
        this.lastProductRuleParameterId = null;
    }

    @Given("I set the context product rule parameter id to the id of in-use product rule parameter {word}")
    public void iSetContextPrpIdToInUse(String name) {
        request = RequestContainer.build()
                .getEntities(PRODUCT_RULE_PARAMETER);
        var result = request.call(context.popExpectedStatus(200))
                .getResponseEntity(GetProductRulesResult.class);
        Optional<ProductRules> opt = result.data().stream()
                .filter(p -> name.equals(p.name))
                .findFirst();
        assertTrue(opt.isPresent(), "In-use parameter " + name + " not found!");
        this.lastProductRuleParameterId = Long.valueOf(opt.get().id);
    }

    @And("I save this product rule parameter id as {word}")
    public void iSavePrpIdAsTag(String tag) {
        Long id = getRequiredCurrentId();
        savedIdsByTag.put(tag, id);
        context.savedValues.put(tag, String.valueOf(id));
    }

    @Given("I set the context product rule parameter id to {word}")
    public void iSetContextPrpIdToTag(String tag) {
        assertTrue(savedIdsByTag.containsKey(tag), "No saved id for tag " + tag);
        this.lastProductRuleParameterId = savedIdsByTag.get(tag);
    }

    //
    // POST
    //
    @Given("I generate a random product rule parameter name and save it as {word}")
    public void iGenerateRandomProductRuleParameterName(String key) {
        String randomName = "ProductRuleParam_" + UUID.randomUUID().toString().substring(0, 8);
        context.savedValues.put(key, randomName);
    }

    @When("I POST a new product rule parameter specifying the following properties")
    public void iPostNewProductRuleParameter(DataTable table) {
        HashMap<String, Object> body = new HashMap<>(table.asMap(String.class, Object.class));
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
                .submitEntity(POST, PRODUCT_RULE_PARAMETER, body);

        var expected = context.popExpectedStatus(201);
        var entity = request.call(expected)
                .getResponseEntity(PostProductRuleParameterResult.class);

        if (expected.getCode() == 201) {
            ProductRuleParameters prp = entity.data();
            assertNotNull(prp);
            this.lastProductRuleParameterId = Long.valueOf(prp.id);
        }
    }

    @Then("the response should include the new product rule parameter")
    public void responseShouldIncludeNewPrp() throws JsonProcessingException {
        Map<String, Object> resp = request.getDataAsList().get(0);

        assertNotNull(lastProductRuleParameterId, "No product rule parameter id saved");
        assertEquals(
                String.valueOf(lastProductRuleParameterId),
                String.valueOf(resp.get("id")),
                "Unexpected id in response"
        );

        assertEquals(request.getBodyProps().get("name"), resp.get("name"));
        assertEquals(request.getBodyProps().get("type"), resp.get("type"));

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

    @Then("the product rule parameter response should contain fields")
    public void prpResponseShouldContainFields(DataTable table) {
        Set<String> required = new HashSet<>(table.asList());
        Map<String, Object> respMap = request.getDataAsList().get(0);
        for (String field : required) {
            assertTrue(respMap.containsKey(field), "Missing field: " + field);
        }
    }

    //
    // GET all
    //
    @When("I GET all product rule parameters")
    public void iGetAllPrps() {
        request = RequestContainer.build()
                .getEntities(PRODUCT_RULE_PARAMETERS);
        request.call(context.popExpectedStatus(200));
    }

    @Then("the product rule parameters list should be returned")
    public void prpListShouldBeReturned() {
        assertFalse(request.getDataAsList().isEmpty(), "No product rule parameters returned!");
    }

    @Then("the product rule parameters list should contain my parameter")
    public void listShouldContainMyParameter() {
        Long id = getRequiredCurrentId();
        boolean found = request.getDataAsList().stream()
                .anyMatch(m -> String.valueOf(id).equals(Objects.toString(m.get("id"), null)));
        assertTrue(found, "Current product rule parameter id not found in list");
    }

    //
    // GET by id
    //
    @When("I GET the product rule parameter by id")
    public void iGetPrpById() {
        String idStr;
        if (context.savedValues.containsKey("productRuleParamId")) {
            idStr = context.savedValues.get("productRuleParamId");
        } else {
            idStr = String.valueOf(getRequiredCurrentId());
        }
        request = RequestContainer.build()
                .getEntity(PRODUCT_RULE_PARAMETER, idStr);
        var expected = context.popExpectedStatus(200);
        request.call(expected);
    }

    @Then("GET product rule parameter should return the current state")
    public void getPrpShouldReturnCurrentState() {
        Map<String, Object> respMap = Collections.unmodifiableMap(request.getDataAsList().get(0));
        String idStr = Objects.toString(respMap.getOrDefault("id", "No id!"));
        assertEquals(String.valueOf(getRequiredCurrentId()), idStr);
    }

    @Given("I set the enel-x-trace-id header to {word}")
    public void iSetEnelXTraceId(String traceId) {
        Context.getContext().savedValues.put("enel-x-trace-id", traceId);
    }

    //
    // PUT
    //
    @When("I update the product rule parameter with new values")
    public void iPutPrp(DataTable table) {
        HashMap<String, Object> body = new HashMap<>(table.asMap(String.class, Object.class));
        utility.replaceParmValues(body);
        String id;

        if (context.savedValues.containsKey("productRuleParamId")) {
            id = context.savedValues.get("productRuleParamId");
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
                .submitEntity(PUT, PRODUCT_RULE_PARAMETER, body)
                .addIdToPath(id);

        var expected = context.popExpectedStatus(200);
        var resp = request.call(expected);
        if (expected.getCode() == 200) {
            var entity = resp.getResponseEntity(PutProductRuleParameterResult.class);
            ProductRuleParameters prp = entity.data();
            this.lastProductRuleParameterId = Long.valueOf(prp.id);
        }
    }

    @Then("the response should include the updated product rule parameter")
    public void responseShouldIncludeUpdatedPrp() {
        Map<String, Object> respMap = request.getDataAsList().get(0);
        String idStr = Objects.toString(respMap.getOrDefault("id", "No id!"));
        assertEquals(String.valueOf(getRequiredCurrentId()), idStr);
    }

    //
    // DELETE
    //
    @When("I DELETE my product rule parameter")
    public void iDeleteMyPrp() {
        String id;
        if (context.savedValues.containsKey("productRuleParamId")) {
            id = context.savedValues.get("productRuleParamId");
        } else {
            id = String.valueOf(getRequiredCurrentId());
        }
        request = RequestContainer.build()
                .deleteEntity(PRODUCT_RULE_PARAMETER, id);
        request.call(context.popExpectedStatus(204));
    }

    //
    // Cleanup with cascading delete
    //
    @Given("I delete all existing product rule parameters with name {word}")
    public void iDeleteAllWithName(String name) {
        request = RequestContainer.build()
                .getEntities(PRODUCT_RULE_PARAMETERS);

        var result = request.call(context.popExpectedStatus(200))
                .getResponseEntity(GetProductRuleParametersResult.class);

        List<Long> ids = result.data().stream()
                .filter(p -> name.equals(p.name))
                .map(p -> Long.valueOf(p.id))
                .toList();

        if (ids.isEmpty()) {
            LOG.info("No product rule parameters found with name '{}', nothing to delete", name);
            return;
        }

        for (Long id : ids) {
            deleteParameterWithCleanup(id, name);
        }
    }

    /**
     * Deletes a parameter, handling blockers:
     * - Product Rule Details (delete details first)
     * - Fragment Parameters (unlink from fragments first)
     */
    private void deleteParameterWithCleanup(Long parameterId, String name) {
        String url = String.format("%s/%d",
                com.enernoc.bdap.model.Endpoint.GET_PRODUCT_RULE_PARAMETER.baseUrl, parameterId);

        var response = buildRawSpec()
                .contentType(ContentType.JSON)
                .when().delete(url)
                .then().extract();

        int status = response.statusCode();

        if (status == 204) {
            LOG.info("Deleted parameter id {} named '{}'", parameterId, name);
            return;
        }

        if (status == 400) {
            String detail = response.path("detail") != null ? response.path("detail").toString() : "";
            LOG.info("Delete parameter {} blocked, detail: [{}]", parameterId, detail);

            // Blocker 1: associated details
            List<Long> detailIds = parseIdsFromError(detail, "Product Rule Details:");
            if (!detailIds.isEmpty()) {
                LOG.info("Parameter {} blocked by details {}. Deleting details first.", parameterId, detailIds);
                deleteProductRuleDetailsByIds(detailIds);
            }

            // Blocker 2: associated fragment parameters
            List<Long> fragmentIds = parseIdsFromError(detail, "Fragment Parameters:");
            if (!fragmentIds.isEmpty()) {
                LOG.info("Parameter {} still linked to fragments {}. Unlinking first.", parameterId, fragmentIds);
                for (Long fragmentId : fragmentIds) {
                    unlinkParametersFromFragment(fragmentId);
                }
            }

            // First retry
            var retryResponse = buildRawSpec()
                    .contentType(ContentType.JSON)
                    .when().delete(url)
                    .then().extract();

            int retryStatus = retryResponse.statusCode();

            if (retryStatus == 204) {
                LOG.info("Deleted parameter {} named '{}' after cleanup", parameterId, name);
                return;
            }

            // After unlinking from fragments, details might surface as a new blocker
            String retryDetail = retryResponse.path("detail") != null
                    ? retryResponse.path("detail").toString() : "";

            List<Long> remainingDetailIds = parseIdsFromError(retryDetail, "Product Rule Details:");
            if (!remainingDetailIds.isEmpty()) {
                LOG.info("Parameter {} blocked by additional details {} after fragment unlink. Deleting...",
                        parameterId, remainingDetailIds);
                deleteProductRuleDetailsByIds(remainingDetailIds);

                int finalStatus = buildRawSpec()
                        .contentType(ContentType.JSON)
                        .when().delete(url)
                        .then().extract().statusCode();

                if (finalStatus == 204) {
                    LOG.info("Deleted parameter {} named '{}' after full cleanup", parameterId, name);
                } else {
                    LOG.warn("Could not delete parameter {} named '{}' after full cleanup, status: {}",
                            parameterId, name, finalStatus);
                }
            } else {
                LOG.warn("Could not delete parameter {} named '{}', status: {}, detail: [{}]",
                        parameterId, name, retryStatus, retryDetail);
            }
        } else {
            LOG.warn("Unexpected status {} deleting parameter {} named '{}'", status, parameterId, name);
        }
    }

    /**
     * Delete product rule details by id list.
     */
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

    /**
     * PUT [] to /productrulefragments/{id}/parameters to unlink all parameters.
     */
    private void unlinkParametersFromFragment(Long fragmentId) {
        String url = String.format("%s/productrulefragments/%s/parameters",
                Context.targetMetadataUrl, fragmentId);

        int status = buildRawSpec()
                .contentType(ContentType.JSON)
                .body(Collections.emptyList())
                .when().put(url)
                .then().extract().statusCode();

        LOG.info("Unlinked all parameters from fragment {} — status: {}", fragmentId, status);
    }

    /**
     * Parses numeric ids from error messages after a marker, e.g.
     * "Cannot delete Product Rule Parameter associated to Product Rule Details: 135, 136"
     * "Cannot delete Product Rule Parameter associated to Fragment Parameters: 62, 45"
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
}