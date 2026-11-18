package com.enernoc.bdap.stepdefs;

import com.enernoc.bdap.model.APIResponses;
import com.enernoc.bdap.model.APIResponses.PostProductRules;
import com.enernoc.bdap.model.APIResponses.PutProductRules;
import com.enernoc.bdap.model.ProductRules;
import com.enernoc.bdap.model.RequestContainer;
import com.enernoc.bdap.shared.Context;
import com.enernoc.bdap.shared.Utility;
import io.cucumber.datatable.DataTable;
import io.cucumber.java.en.And;
import io.cucumber.java.en.Given;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.*;

import static com.enernoc.bdap.model.EntityType.*;
import static com.enernoc.bdap.model.HttpOp.POST;
import static com.enernoc.bdap.model.HttpOp.PUT;
import static org.junit.jupiter.api.Assertions.*;

public class CrudProductRules {

    private static final Logger LOG = LoggerFactory.getLogger(CrudProductRules.class);

    private final Context context = Context.getContext();
    private final Utility utility = new Utility();

    private RequestContainer request;
    // product_id is a UUID string, so we track it as String
    private String lastProductId;
    private final Map<String, String> savedProductIdsByTag = new HashMap<>();
    private Long lastProductRuleIntId;

    //
    // Helpers
    //
    private String getRequiredCurrentProductId() {
        assertNotNull(lastProductId, "No current product rule product_id set!");
        return lastProductId;
    }

    private io.restassured.specification.RequestSpecification buildRawSpec() {
        var spec = io.restassured.RestAssured.given();
        if (context.includeApiKey) {
            spec = spec.header("x-api-key", Context.metadataApiKey);
        }
        if (context.includeEnocSession) {
            spec = spec.header("enoc_session", Context.enocSession);
        }
        return spec.header("x-enelx-trace-id", java.util.UUID.randomUUID());
    }

    //
    // Context product_id operations
    //
    @Given("I set the context product rule product id to {word}")
    public void iSetContextProductRuleProductIdToTagOrValue(String tagOrLiteral) {
        // If tag stored earlier, resolve it; otherwise treat as literal product_id
        this.lastProductId = savedProductIdsByTag.getOrDefault(tagOrLiteral, tagOrLiteral);
    }

    @Given("I set the context product rule product ID to non-uuid")
    public void iSetContextProductRuleProductIdToNonUuid() {
        // Stored as a special saved value, RequestContainer will use it directly in path
        context.savedValues.put("productRuleProductId", "non-uuid");
        this.lastProductId = null;
    }

    @And("I save this product rule product id as {word}")
    public void iSaveProductRuleProductIdAsTag(String tag) {
        String productId = getRequiredCurrentProductId();
        savedProductIdsByTag.put(tag, productId);
        context.savedValues.put(tag, productId);
    }

    //
    // Cleanup helper
    //
    @Given("I delete all existing product rules with product id {word}")
    public void iDeleteAllProductRulesWithProductId(String productId) {
        request = RequestContainer.build()
                .getEntities(PRODUCT_RULES);

        var result = request.call(context.popExpectedStatus(200))
                .getResponseEntity(APIResponses.GetProductRule.class);

        List<ProductRules> matchingRules = result.data().stream()
                .filter(r -> productId.equals(r.product_id))
                .toList();

        if (matchingRules.isEmpty()) {
            LOG.info("No product rules found with product_id '{}', nothing to delete", productId);
            return;
        }

        for (ProductRules rule : matchingRules) {
            String pid = rule.product_id;
            deleteProductRuleWithGroupCleanup(pid);
        }
    }

    private void deleteProductRuleWithGroupCleanup(String productId) {
        String url = String.format("%s/%s",
                com.enernoc.bdap.model.Endpoint.GET_PRODUCT_RULE.baseUrl, productId);

        var extractedResponse = buildRawSpec()
                .contentType(io.restassured.http.ContentType.JSON)
                .when().delete(url)
                .then().extract();

        int statusCode = extractedResponse.statusCode();

        if (statusCode == 204) {
            LOG.info("Deleted product rule with product_id '{}'", productId);
            return;
        }

        if (statusCode == 400) {
            String detail = extractedResponse.path("detail") != null
                    ? extractedResponse.path("detail").toString()
                    : "";

            LOG.info("Delete product rule '{}' blocked, detail: [{}]", productId, detail);

            List<Long> groupIds = parseGroupIdsFromDeleteError(detail);

            if (groupIds.isEmpty()) {
                LOG.warn("Cannot delete product rule '{}', unrecognised 400 detail: {}", productId, detail);
                return;
            }

            LOG.info("Product rule '{}' blocked by groups {}. Deleting groups first.", productId, groupIds);
            deleteGroupsByIds(groupIds);

            // Retry after group cleanup
            int retryStatus = buildRawSpec()
                    .contentType(io.restassured.http.ContentType.JSON)
                    .when().delete(url)
                    .then().extract().statusCode();

            if (retryStatus == 204) {
                LOG.info("Deleted product rule '{}' after removing groups", productId);
            } else {
                LOG.warn("Failed to delete product rule '{}' even after removing groups, status: {}",
                        productId, retryStatus);
            }
        } else {
            LOG.warn("Unexpected status {} deleting product rule '{}'", statusCode, productId);
        }
    }

    /**
     * Parses group ids from an error message like:
     * "Cannot delete Product Rule associated to Groups: 18"
     * "Cannot delete Product Rule associated to Groups: 18, 22, 45"
     */
    private List<Long> parseGroupIdsFromDeleteError(String message) {
        // Find everything after "Groups:" and parse comma-separated numbers
        int idx = message.indexOf("Groups:");
        if (idx == -1) {
            return Collections.emptyList();
        }
        String idsPart = message.substring(idx + "Groups:".length()).trim();
        List<Long> ids = new ArrayList<>();
        for (String token : idsPart.split("[,\\s]+")) {
            token = token.trim();
            if (token.matches("\\d+")) {
                ids.add(Long.parseLong(token));
            }
        }
        return ids;
    }

    /**
     * Deletes product rule groups directly by their id,
     * without filtering by name — used during cascade cleanup.
     */

    private void deleteGroupsByIds(List<Long> groupIds) {
        for (Long groupId : groupIds) {
            String url = String.format("%s/%s",
                    com.enernoc.bdap.model.Endpoint.GET_PRODUCT_RULE_GROUP.baseUrl, groupId);

            int status = buildRawSpec()
                    .contentType(io.restassured.http.ContentType.JSON)
                    .when().delete(url)
                    .then().extract().statusCode();

            if (status == 204) {
                LOG.info("Deleted product rule group id {}", groupId);
            } else {
                LOG.warn("Failed to delete product rule group id {}, status: {}", groupId, status);
            }
        }
    }

    //
    // POST
    //
    @When("I POST a new product rule specifying the following properties")
    public void iPostNewProductRule(DataTable table) {
        HashMap<String, Object> body = new HashMap<>(table.asMap(String.class, Object.class));
        utility.replaceParmValues(body);

        request = RequestContainer.build()
                .submitEntity(POST, PRODUCT_RULE, body);

        var expected = context.popExpectedStatus(201);
        var entity = request.call(expected)
                .getResponseEntity(PostProductRules.class);

        if (expected.getCode() == 201) {
            ProductRules rule = entity.data();
            assertNotNull(rule);
            this.lastProductId = rule.product_id;
            this.lastProductRuleIntId = Long.valueOf(rule.id);
        }
    }

    @Then("the response should include the new product rule")
    public void responseShouldIncludeNewProductRule() {
        Map<String, Object> resp = request.getDataAsList().get(0);

        assertNotNull(lastProductId, "No product rule product_id saved");
        assertEquals(
                lastProductId,
                String.valueOf(resp.get("product_id")),
                "Unexpected product_id in response"
        );

        // name matches the request
        assertEquals(request.getBodyProps().get("name"), resp.get("name"));
    }

    @Then("the product rule response should contain fields")
    public void productRuleResponseShouldContainFields(DataTable table) {
        Set<String> required = new HashSet<>(table.asList());
        Map<String, Object> respMap = request.getDataAsList().get(0);
        for (String field : required) {
            assertTrue(respMap.containsKey(field), "Missing field: " + field);
        }
    }

    //
    // GET all
    //
    @When("I GET all product rules")
    public void iGetAllProductRules() {
        request = RequestContainer.build()
                .getEntities(PRODUCT_RULES);
        request.call(context.popExpectedStatus(200));
    }

    @Then("the product rules list should be returned")
    public void productRulesListShouldBeReturned() {
        List<HashMap<String, Object>> list = request.getDataAsList();

        // list is not empty
        assertFalse(list.isEmpty(), "No product rules returned!");

        for (Map<String, Object> item : list) {
            // top-level fields present and non-empty
            assertTrue(item.containsKey("id"), "Missing id");
            assertNotNull(item.get("id"), "id is null");

            assertTrue(item.containsKey("product_id"), "Missing product_id");
            assertNotNull(item.get("product_id"), "product_id is null");
            assertFalse(String.valueOf(item.get("product_id")).isBlank(), "product_id is blank");

            assertTrue(item.containsKey("name"), "Missing name");
            assertNotNull(item.get("name"), "name is null");
            assertFalse(String.valueOf(item.get("name")).isBlank(), "name is blank");

            assertTrue(item.containsKey("last_updated_dttm_utc"), "Missing last_updated_dttm_utc");
            assertNotNull(item.get("last_updated_dttm_utc"), "last_updated_dttm_utc is null");
            assertFalse(String.valueOf(item.get("last_updated_dttm_utc")).isBlank(), "last_updated_dttm_utc is blank");

            assertTrue(item.containsKey("last_updated_by"), "Missing last_updated_by");
            assertNotNull(item.get("last_updated_by"), "last_updated_by is null");
            assertFalse(String.valueOf(item.get("last_updated_by")).isBlank(), "last_updated_by is blank");

        }
    }

    @Then("the product rules list should contain my rule")
    public void productRulesListShouldContainMyRule() {
        String productId = getRequiredCurrentProductId();
        boolean found = request.getDataAsList().stream()
                .anyMatch(m -> productId.equals(Objects.toString(m.get("product_id"), null)));
        assertTrue(found, "Current product rule product_id not found in list");
    }

    //
    // GET by product_id
    //
    @When("I GET the product rule by product id")
    public void iGetProductRuleByProductId() {
        String idStr;
        if (context.savedValues.containsKey("productRuleProductId")) {
            idStr = context.savedValues.get("productRuleProductId");
        } else {
            idStr = getRequiredCurrentProductId();
        }

        request = RequestContainer.build()
                .getEntity(PRODUCT_RULE, idStr);
        var expected = context.popExpectedStatus(200);
        request.call(expected);
    }

    @Then("GET product rule should return the current state")
    public void getProductRuleShouldReturnCurrentState() {
        Map<String, Object> respMap = Collections.unmodifiableMap(request.getDataAsList().get(0));
        String productId = Objects.toString(respMap.getOrDefault("product_id", "No product_id!"));
        assertEquals(getRequiredCurrentProductId(), productId);
    }


    //
    // PUT
    //
    @When("I update the product rule with new values")
    public void iPutProductRule(DataTable table) {
        HashMap<String, Object> body = new HashMap<>(table.asMap(String.class, Object.class));
        utility.replaceParmValues(body);

        String pathProductId;
        if (context.savedValues.containsKey("productRuleProductId")) {
            pathProductId = context.savedValues.get("productRuleProductId");
        } else {
            pathProductId = getRequiredCurrentProductId();
        }

        request = RequestContainer.build()
                .submitEntity(PUT, PRODUCT_RULE, body)
                .addIdToPath(pathProductId);

        var expected = context.popExpectedStatus(200);
        var entity = request.call(expected)
                .getResponseEntity(PutProductRules.class);

        if (expected.getCode() == 200) {
            ProductRules rule = entity.data();
            assertNotNull(rule, "PUT product rule returned null data");
            this.lastProductId = rule.product_id;
        }
    }


    //
    // DELETE
    //
    @When("I DELETE my product rule")
    public void iDeleteMyProductRule() {
        String id;
        if (context.savedValues.containsKey("productRuleProductId")) {
            id = context.savedValues.get("productRuleProductId");
        } else {
            id = getRequiredCurrentProductId();
        }
        request = RequestContainer.build()
                .deleteEntity(PRODUCT_RULE, id);
        request.call(context.popExpectedStatus(204));
    }

    @Then("the response should include the updated product rule")
    public void responseShouldIncludeUpdatedProductRule() {
        Map<String, Object> resp = request.getDataAsList().get(0);

        // product_id matches the current context
        assertNotNull(lastProductId, "No product rule product_id saved");
        assertEquals(
                lastProductId,
                String.valueOf(resp.get("product_id")),
                "Unexpected product_id in response"
        );

        // name still matches the request
        assertEquals(request.getBodyProps().get("name"), resp.get("name"));

        // last_updated_dttm_utc must be present and non-empty
        assertTrue(resp.containsKey("last_updated_dttm_utc"), "Missing last_updated_dttm_utc");
        Object lastUpdated = resp.get("last_updated_dttm_utc");
        assertNotNull(lastUpdated, "last_updated_dttm_utc is null");
        assertFalse(String.valueOf(lastUpdated).isBlank(), "last_updated_dttm_utc is blank");

        // last_updated_by must be present and non-empty
        assertTrue(resp.containsKey("last_updated_by"), "Missing last_updated_by");
        Object lastUpdatedBy = resp.get("last_updated_by");
        assertNotNull(lastUpdatedBy, "last_updated_by is null");
        assertFalse(String.valueOf(lastUpdatedBy).isBlank(), "last_updated_by is blank");
    }

    @Given("I GET a real product rule id and save it as {word}")
    public void iGetARealProductRuleIdAndSaveItAs(String key) {
        RequestContainer getRulesRequest = RequestContainer.build()
                .getEntities(PRODUCT_RULES);

        APIResponses.GetProductRule result = getRulesRequest.call(context.popExpectedStatus(200))
                .getResponseEntity(APIResponses.GetProductRule.class);

        assertNotNull(result, "GET product rules returned null response");
        assertNotNull(result.data(), "GET product rules returned null data");
        assertFalse(result.data().isEmpty(), "No product rules exist to use for product rule group tests");

        ProductRules firstRule = result.data().get(0);
        assertNotNull(firstRule, "First product rule is null");
        assertNotNull(firstRule.id, "Resolved product rule id is null");

        this.lastProductId = String.valueOf(Integer.valueOf(firstRule.id.intern()));
        context.savedValues.put(key, String.valueOf(this.lastProductId));
    }

    @When("I GET the product rule by product id with include_details true")
    public void iGetProductRuleByProductIdWithIncludeDetailsTrue() {
        String productId = getRequiredCurrentProductId();
        request = RequestContainer.build()
                .getEntity(PRODUCT_RULE, productId + "?include_details=true");
        request.call(context.popExpectedStatus(200));
    }

    @Then("the product rule should contain groups with fragments and parameters")
    public void productRuleShouldContainGroupsWithFragmentsAndParameters() {
        Map<String, Object> resp = request.getDataAsList().get(0);

        Object groupsObj = resp.get("groups");
        assertNotNull(groupsObj, "groups is missing from product rule response");
        assertInstanceOf(List.class, groupsObj, "groups is not a list");

        @SuppressWarnings("unchecked")
        List<Map<String, Object>> groups = (List<Map<String, Object>>) groupsObj;
        assertFalse(groups.isEmpty(), "groups list is empty");

        for (Map<String, Object> group : groups) {
            Object fragmentsObj = group.get("fragments");
            assertNotNull(fragmentsObj, "fragments missing from group id " + group.get("id"));
            assertInstanceOf(List.class, fragmentsObj, "fragments not a list in group id " + group.get("id"));

            @SuppressWarnings("unchecked")
            List<Map<String, Object>> fragments = (List<Map<String, Object>>) fragmentsObj;
            assertFalse(fragments.isEmpty(), "fragments empty in group id " + group.get("id"));

            for (Map<String, Object> fragment : fragments) {
                Object paramsObj = fragment.get("parameters");
                assertNotNull(paramsObj, "parameters missing from fragment id " + fragment.get("id"));
                assertInstanceOf(List.class, paramsObj, "parameters not a list in fragment id " + fragment.get("id"));
            }
        }
    }

    @Then("the product rule group {word} should include no fragments")
    public void productRuleGroupShouldIncludeNoFragments(String groupIdTag) {
        Map<String, Object> resp = request.getDataAsList().get(0);

        @SuppressWarnings("unchecked")
        List<Map<String, Object>> groups = (List<Map<String, Object>>) resp.get("groups");
        assertNotNull(groups, "groups is missing from product rule response");

        String targetId = context.savedValues.getOrDefault(groupIdTag, groupIdTag);

        Map<String, Object> group = groups.stream()
                .filter(g -> targetId.equals(String.valueOf(g.get("id"))))
                .findFirst()
                .orElseThrow(() -> new AssertionError("Group " + targetId + " not found in product rule response"));

        Object fragmentsObj = group.get("fragments");
        if (fragmentsObj == null) return; // absent = no fragments, acceptable

        assertInstanceOf(List.class, fragmentsObj, "fragments not a list");
        assertTrue(((List<?>) fragmentsObj).isEmpty(),
                "Expected group " + targetId + " to have no fragments, but found: " + fragmentsObj);
    }

    @Then("the product rule should have no groups")
    public void productRuleShouldHaveNoGroups() {
        Map<String, Object> resp = request.getDataAsList().get(0);
        Object groupsObj = resp.get("groups");

        if (groupsObj == null) return; // absent = no groups

        assertInstanceOf(List.class, groupsObj, "groups is not a list");
        assertTrue(((List<?>) groupsObj).isEmpty(),
                "Expected product rule to have no groups, but found: " + groupsObj);
    }

    @And("I save this product rule id as {word}")
    public void iSaveProductRuleIdAsTag(String tag) {
        // lastProductRuleIntId is the integer id field (r.id) saved during POST
        assertNotNull(lastProductRuleIntId, "No product rule integer id available to save");
        context.savedValues.put(tag, String.valueOf(lastProductRuleIntId));
    }

}
