package com.enernoc.bdap.stepdefs;

import com.enernoc.bdap.model.APIResponses.GetProductRuleGroups;
import com.enernoc.bdap.model.APIResponses.PostProductRuleGroups;
import com.enernoc.bdap.model.APIResponses.PutProductRuleGroups;
import com.enernoc.bdap.model.HttpStatus;
import com.enernoc.bdap.model.ProductRuleGroup;
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
import io.restassured.http.ContentType;
import io.restassured.response.ValidatableResponse;
import io.restassured.specification.RequestSpecification;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.*;

import static com.enernoc.bdap.model.EntityType.*;
import static com.enernoc.bdap.model.HttpOp.POST;
import static com.enernoc.bdap.model.HttpOp.PUT;
import static com.enernoc.bdap.shared.Context.metadataApiKey;
import static com.enernoc.bdap.shared.Context.targetMetadataUrl;
import static io.restassured.RestAssured.given;
import static org.junit.jupiter.api.Assertions.*;

public class CrudProductRuleGroups {

    private static final Logger LOG = LoggerFactory.getLogger(CrudProductRuleGroups.class);
    private static final ObjectMapper JSON = new ObjectMapper();

    private final Context context = Context.getContext();
    private final Utility utility = new Utility();

    private RequestContainer request;
    private Long lastProductRuleGroupId;
    private final Map<String, Long> savedIdsByTag = new HashMap<>();

    // For /productrulegroups/{id}/fragments
    private ValidatableResponse lastPutFragmentsVr;
    private HttpStatus lastPutFragmentsExpectedStatus;

    //
    // Helpers
    //
    private Long getRequiredCurrentGroupId() {
        assertNotNull(lastProductRuleGroupId, "No current product rule group id set!");
        return lastProductRuleGroupId;
    }

    //
    // Low‑level auth + URL helpers (used by fragments PUT)
    //
    private RequestSpecification buildAuthSpec() {
        RequestSpecification spec = given();

        // Always include trace id
        UUID traceId = UUID.randomUUID();
        spec = spec.header("x-enelx-trace-id", traceId);
        if (!context.logAllAPIRequests) {
            LOG.info("x-enelx-trace-id: {}", traceId);
        }

        // API key (Metadata API)
        if (context.includeApiKey) {
            String apiKey =
                    context.includeInvalidApiKey
                            ? "INVALID_API_KEY_FOR_TESTING"
                            : metadataApiKey;
            spec = spec.header("x-api-key", apiKey);
        }

        // ENOC session
        if (context.includeEnocSession) {
            if (context.includeInvalidEnocSession) {
                spec = spec.header("enoc_session", "INVALID_SESSION");
            } else {
                assertFalse(Context.enocSession.isBlank(),
                        "No user session! Maybe you forgot 'Given I log in as a settlement API admin'");
                spec = spec.header("enoc_session", Context.enocSession);
            }
        }

        // Logging level
        spec = context.logAllAPIRequests ? spec.log().all(true) : spec.log().method().log().uri();

        return spec;
    }

    private String buildGroupFragmentsUrl(String groupId) {
        // Endpoint: /api/v1/productrulegroups/{id}/fragments on metadata API
        return String.format("%s/productrulegroups/%s/fragments", targetMetadataUrl, groupId);
    }

    //
    // Context id operations
    //
    @Given("I set the context product rule group ID to {int}")
    public void iSetContextProductRuleGroupIdToInt(int id) {
        context.savedValues.remove("productRuleGroupId");
        this.lastProductRuleGroupId = (long) id;
    }

    @Given("I set the context product rule group id to random valid id")
    public void iSetContextProductRuleGroupIdToRandomValid() {
        context.savedValues.remove("productRuleGroupId");
        this.lastProductRuleGroupId = 1L;
    }

    @Given("I set the context product rule group ID to non-numeric")
    public void iSetContextProductRuleGroupIdToNonNumeric() {
        context.savedValues.put("productRuleGroupId", "non-numeric");
        this.lastProductRuleGroupId = null;
    }

    @And("I save this product rule group id as {word}")
    public void iSaveProductRuleGroupIdAsTag(String tag) {
        Long id = getRequiredCurrentGroupId();
        savedIdsByTag.put(tag, id);
        context.savedValues.put(tag, String.valueOf(id));
    }

    @Given("I set the context product rule group id to {word}")
    public void iSetContextProductRuleGroupIdToTag(String tag) {
        assertTrue(savedIdsByTag.containsKey(tag), "No saved id for tag " + tag);
        context.savedValues.remove("productRuleGroupId");
        this.lastProductRuleGroupId = savedIdsByTag.get(tag);
    }

    @Given("I generate a random product rule group name and save it as {word}")
    public void iGenerateRandomProductRuleGroupName(String key) {
        String randomName = "ProductRuleGroup_" + UUID.randomUUID().toString().substring(0, 8);
        context.savedValues.put(key, randomName);
    }

    //
    // Cleanup helper
    //
    @Given("I delete all existing product rule groups for product rule {int} and name {word}")
    public void iDeleteAllExistingProductRuleGroupsForRuleAndName(int productRuleId, String name) {
        request = RequestContainer.build()
                .getEntities(PRODUCT_RULE_GROUPS);

        try {
            GetProductRuleGroups result = request.call(context.popExpectedStatus(200))
                    .getResponseEntity(GetProductRuleGroups.class);

            List<Long> ids = result.data().stream()
                    .filter(g -> Integer.parseInt(String.valueOf(g.product_rule_id)) == productRuleId)
                    .filter(g -> name.equals(g.name))
                    .map(g -> Long.valueOf(String.valueOf(g.id)))
                    .toList();

            for (Long id : ids) {
                try {
                    RequestContainer.build()
                            .deleteEntity(PRODUCT_RULE_GROUP, String.valueOf(id))
                            .call(context.popExpectedStatus(204));
                } catch (AssertionError ex) {
                    LOG.warn("Failed to delete product rule group {} for product rule {} and name {}", id, productRuleId, name, ex);
                }
            }
        } catch (AssertionError e) {
            LOG.info("No existing product rule groups found for product rule {} and name {}, or failed to retrieve groups: {}",
                    productRuleId, name, e.getMessage());
        }
    }

    //
    // POST
    //
    @When("I POST a new product rule group specifying the following properties")
    public void iPostNewProductRuleGroup(DataTable table) {
        HashMap<String, Object> body = new HashMap<>(table.asMap(String.class, Object.class));

        body.replaceAll((_, v) -> {
            if (v instanceof String s && context.savedValues.containsKey(s)) {
                return context.savedValues.get(s);
            }
            return v;
        });

        utility.replaceParmValues(body);

        request = RequestContainer.build()
                .submitEntity(POST, PRODUCT_RULE_GROUP, body);

        var expected = context.popExpectedStatus(201);
        PostProductRuleGroups entity = request.call(expected)
                .getResponseEntity(PostProductRuleGroups.class);

        if (expected.getCode() == 201) {
            ProductRuleGroup prg = entity.data();
            assertNotNull(prg);
            this.lastProductRuleGroupId = Long.valueOf(String.valueOf(prg.id));
            context.savedValues.remove("productRuleGroupId");
        }
    }

    @Then("the response should include the new product rule group")
    public void responseShouldIncludeNewProductRuleGroup() {
        Map<String, Object> resp = request.getDataAsList().get(0);

        assertNotNull(lastProductRuleGroupId, "No product rule group id saved");
        assertEquals(String.valueOf(lastProductRuleGroupId), String.valueOf(resp.get("id")), "Unexpected id in response");
        assertEquals(String.valueOf(request.getBodyProps().get("product_rule_id")),
                String.valueOf(resp.get("product_rule_id")));
        assertEquals(request.getBodyProps().get("name"), resp.get("name"));
    }

    @Then("the product rule group response should contain fields")
    public void productRuleGroupResponseShouldContainFields(DataTable table) {
        Set<String> required = new HashSet<>(table.asList());
        Map<String, Object> respMap = request.getDataAsList().get(0);
        for (String field : required) {
            assertTrue(respMap.containsKey(field), "Missing field: " + field);
        }
    }

    //
    // GET all
    //
    @When("I GET all product rule groups")
    public void iGetAllProductRuleGroups() {
        request = RequestContainer.build()
                .getEntities(PRODUCT_RULE_GROUPS);
        try {
            request.call(context.popExpectedStatus(200));
        } catch (AssertionError e) {
            LOG.info("No product rules found, or otherwise failed to get product rule groups: {}", e.getMessage());
        }
    }

    @Then("the product rule groups list should be returned")
    public void productRuleGroupsListShouldBeReturned() throws JsonProcessingException {
        assertFalse(request.getDataAsList().isEmpty(), "No product rule groups returned!");
        LOG.info("Received product rule groups:\n{}",
                JSON.writerWithDefaultPrettyPrinter().writeValueAsString(request.getDataAsList()));
    }

    @Then("the product rule groups list should contain my group")
    public void productRuleGroupsListShouldContainMyGroup() {
        Long id = getRequiredCurrentGroupId();
        boolean found = request.getDataAsList().stream()
                .anyMatch(m -> String.valueOf(id).equals(Objects.toString(m.get("id"), null)));
        assertTrue(found, "Current product rule group id not found in list");
    }

    //
    // GET by id
    //
    @When("I GET the product rule group by id")
    public void iGetProductRuleGroupById() {
        String idStr;
        if (context.savedValues.containsKey("productRuleGroupId")) {
            idStr = context.savedValues.get("productRuleGroupId");
        } else {
            idStr = String.valueOf(getRequiredCurrentGroupId());
        }

        request = RequestContainer.build()
                .getEntity(PRODUCT_RULE_GROUP, idStr);

        var expected = context.popExpectedStatus(200);
        request.call(expected);
    }

    @Then("GET product rule group should return the current state")
    public void getProductRuleGroupShouldReturnCurrentState() {
        Map<String, Object> respMap = Collections.unmodifiableMap(request.getDataAsList().get(0));
        String idStr = Objects.toString(respMap.getOrDefault("id", "No id!"));
        assertEquals(String.valueOf(getRequiredCurrentGroupId()), idStr);
    }

    //
    // PUT
    //
    @When("I update the product rule group with new values")
    public void iUpdateTheProductRuleGroupWithNewValues(DataTable table) {
        HashMap<String, Object> body = new HashMap<>(table.asMap(String.class, Object.class));
        body.replaceAll((_, v) -> {
            if (v instanceof String s && context.savedValues.containsKey(s)) {
                return context.savedValues.get(s);
            }
            return v;
        });

        utility.replaceParmValues(body);

        String id;
        if (context.savedValues.containsKey("productRuleGroupId")) {
            id = context.savedValues.get("productRuleGroupId");
        } else {
            id = String.valueOf(getRequiredCurrentGroupId());
        }

        request = RequestContainer.build()
                .submitEntity(PUT, PRODUCT_RULE_GROUP, body)
                .addIdToPath(id);

        var expected = context.popExpectedStatus(200);
        var resp = request.call(expected);

        if (expected.getCode() == 200) {
            PutProductRuleGroups entity = resp.getResponseEntity(PutProductRuleGroups.class);
            ProductRuleGroup prg = entity.data();
            this.lastProductRuleGroupId = Long.valueOf(String.valueOf(prg.id));
            context.savedValues.remove("productRuleGroupId");
        }
    }

    @Then("the response should include the updated product rule group")
    public void responseShouldIncludeUpdatedProductRuleGroup() {
        Map<String, Object> respMap = request.getDataAsList().get(0);
        String idStr = Objects.toString(respMap.getOrDefault("id", "No id!"));
        assertEquals(String.valueOf(getRequiredCurrentGroupId()), idStr);
    }

    //
    // DELETE
    //
    @When("I DELETE my product rule group")
    public void iDeleteMyProductRuleGroup() {
        String id;
        if (context.savedValues.containsKey("productRuleGroupId")) {
            id = context.savedValues.get("productRuleGroupId");
        } else {
            id = String.valueOf(getRequiredCurrentGroupId());
        }

        request = RequestContainer.build()
                .deleteEntity(PRODUCT_RULE_GROUP, id);

        request.call(context.popExpectedStatus(204));
    }

    @Given("I delete all existing product rule groups for saved product rule {word} and name {word}")
    public void iDeleteAllExistingProductRuleGroupsForSavedProductRuleAndName(String productRuleIdTag, String name) {
        assertTrue(context.savedValues.containsKey(productRuleIdTag),
                "No saved product rule id for tag " + productRuleIdTag);

        int productRuleId = Integer.parseInt(context.savedValues.get(productRuleIdTag));
        iDeleteAllExistingProductRuleGroupsForRuleAndName(productRuleId, name);
    }

    //
    // PUT /productrulegroups/{id}/fragments
    //
    @When("I PUT fragments {string} for the current product rule group")
    public void iPutFragmentsForCurrentProductRuleGroup(String fragmentsSpec) {
        String groupId = String.valueOf(getRequiredCurrentGroupId());

        List<Map<String, Object>> body = new ArrayList<>();
        for (String token : fragmentsSpec.split("[,\\s]+")) {
            token = token.trim();
            if (token.isBlank()) continue;

            String resolved = context.savedValues.getOrDefault(token, token);

            if (!resolved.matches("\\d+")) {
                throw new IllegalArgumentException(
                        "Cannot resolve fragment id from token '" + token + "' — got '" + resolved + "'. " +
                                "Make sure the value is saved in context.savedValues before this step.");
            }

            Map<String, Object> m = new HashMap<>();
            m.put("pr_fragment_id", Integer.parseInt(resolved));
            body.add(m);
        }

        LOG.info("PUT fragments body for group {}: {}", groupId, body);

        lastPutFragmentsExpectedStatus = context.popExpectedStatus(200);

        lastPutFragmentsVr =
                (context.logAllAPIRequests
                        ? buildAuthSpec().log().all(true)
                        : buildAuthSpec().log().method().log().uri())
                        .contentType(ContentType.JSON)
                        .body(body)
                        .when().put(buildGroupFragmentsUrl(groupId))
                        .then();

        if (context.logAllAPIResponses) {
            lastPutFragmentsVr = lastPutFragmentsVr.log().all(true);
        }
    }

    @When("I PUT {int} fragments for the current product rule group expecting HTTP status {int}")
    public void iPutNFragmentsForCurrentProductRuleGroup(int count, int expectedStatus) {
        String groupId = String.valueOf(getRequiredCurrentGroupId());

        List<Map<String, Object>> body = new ArrayList<>();
        for (int i = 1; i <= count; i++) {
            Map<String, Object> m = new HashMap<>();
            m.put("pr_fragment_id", i);
            body.add(m);
        }

        // Build expected status explicitly
        lastPutFragmentsExpectedStatus = HttpStatus.build().withCode(expectedStatus);

        lastPutFragmentsVr =
                (context.logAllAPIRequests
                        ? buildAuthSpec().log().all(true)
                        : buildAuthSpec().log().method().log().uri())
                        .contentType(ContentType.JSON)
                        .body(body)
                        .when().put(buildGroupFragmentsUrl(groupId))
                        .then();

        if (context.logAllAPIResponses) {
            lastPutFragmentsVr = lastPutFragmentsVr.log().all(true);
        }
    }

    @When("I PUT fragments body with non-numeric fragment id for the current product rule group")
    public void iPutFragmentsBodyWithNonNumericFragmentIdForCurrentProductRuleGroup() {
        String groupId = String.valueOf(getRequiredCurrentGroupId());

        String body = """
                [                  {
                    "pr_fragment_id": "string"
                  }
                ]
                """;

        // Validation error, default 400 (overrideable via context)
        lastPutFragmentsExpectedStatus = context.popExpectedStatus(400);

        lastPutFragmentsVr =
                (context.logAllAPIRequests
                        ? buildAuthSpec().log().all(true)
                        : buildAuthSpec().log().method().log().uri())
                        .contentType(ContentType.JSON)
                        .body(body)
                        .when().put(buildGroupFragmentsUrl(groupId))
                        .then();

        if (context.logAllAPIResponses) {
            lastPutFragmentsVr = lastPutFragmentsVr.log().all(true);
        }
    }

    @Then("the PUT fragments expected status should be returned")
    public void putFragmentsExpectedStatusShouldBeReturned() {
        assertNotNull(lastPutFragmentsVr, "No PUT fragments response captured");
        assertNotNull(lastPutFragmentsExpectedStatus, "No expected status saved for PUT fragments");

        Map<String, Object> resp = lastPutFragmentsVr.extract()
                .as(new io.restassured.common.mapper.TypeRef<>() {});

        int actualCode = lastPutFragmentsVr.extract().statusCode();
        assertEquals(lastPutFragmentsExpectedStatus.code, actualCode,
                "Unexpected status code for PUT fragments");

        Object messageObj = resp.get("message");
        String actualMessage = messageObj == null ? "" : messageObj.toString();

        String expectedMessage = lastPutFragmentsExpectedStatus.message;
        if (expectedMessage != null && !expectedMessage.isBlank()) {
            assertTrue(actualMessage.contains(expectedMessage),
                    "Actual message does not contain expected substring. " +
                            "Expected to contain: '" + expectedMessage + "', actual: '" + actualMessage + "'");
        }
    }

    @Then("the product rule group should include no fragments")
    public void productRuleGroupShouldIncludeNoFragments() {
        Map<String, Object> resp = request.getDataAsList().get(0);
        assertFalse(resp.containsKey("fragments"),
                "Expected 'fragments' to be absent from response, but it was present: " + resp.get("fragments"));
    }

    @Then("the product rule group should contain at least the following fragment ids")
    public void productRuleGroupShouldContainAtLeastTheFollowingFragmentIds(DataTable table) {
        // Parse expected IDs from Gherkin table:
        //   And the product rule group should contain at least the following fragment ids
        //     | 1 |
        //     | 2 |
        List<Integer> expectedIds = table.asList().stream()
                .map(String::trim)
                .filter(s -> !s.isEmpty())
                .map(Integer::valueOf)
                .toList();

        Map<String, Object> resp = request.getDataAsList().get(0);

        Object fragmentsObj = resp.get("fragments");
        assertNotNull(fragmentsObj, "fragments is missing");
        assertInstanceOf(List.class, fragmentsObj, "fragments is not a list");

        @SuppressWarnings("unchecked")
        List<Map<String, Object>> fragments = (List<Map<String, Object>>) fragmentsObj;

        // Index fragments by id for quick lookup
        Map<Integer, Map<String, Object>> fragmentsById = new HashMap<>();
        for (Map<String, Object> f : fragments) {
            Object idObj = f.get("id");
            if (idObj != null) {
                fragmentsById.put(Integer.parseInt(String.valueOf(idObj)), f);
            }
        }

        // Verify each expected id is present and well formed
        for (Integer expectedId : expectedIds) {
            Map<String, Object> fragment = fragmentsById.get(expectedId);
            assertNotNull(fragment,
                    "Expected fragment id " + expectedId + " not found in " + fragmentsById.keySet());

            Object nameObj = fragment.get("name");
            assertNotNull(nameObj, "name missing for fragment id " + expectedId);
            assertFalse(String.valueOf(nameObj).isBlank(), "name blank for fragment id " + expectedId);

            Object paramsObj = fragment.get("parameters");
            assertNotNull(paramsObj, "parameters missing for fragment id " + expectedId);
            assertInstanceOf(List.class, paramsObj, "parameters not a list for fragment id " + expectedId);

            @SuppressWarnings("unchecked")
            List<Map<String, Object>> params = (List<Map<String, Object>>) paramsObj;
            assertFalse(params.isEmpty(), "parameters empty for fragment id " + expectedId);

            for (Map<String, Object> p : params) {
                assertNotNull(p.get("id"), "parameter id missing on fragment " + expectedId);
                Object paramName = p.get("name");
                assertNotNull(paramName, "parameter name missing on fragment " + expectedId);
                assertFalse(String.valueOf(paramName).isBlank(), "parameter name blank on fragment " + expectedId);
                Object type = p.get("type");
                assertNotNull(type, "parameter type missing on fragment " + expectedId);
                assertFalse(String.valueOf(type).isBlank(), "parameter type blank on fragment " + expectedId);
            }
        }
    }

    @Given("I delete all existing product rule groups for product rule product id {word}")
    public void iDeleteAllExistingProductRuleGroupsForProductRuleProductId(String productIdOrTag) {
        String productId = context.savedValues.getOrDefault(productIdOrTag, productIdOrTag);

        // Step 1: GET all groups
        request = RequestContainer.build().getEntities(PRODUCT_RULE_GROUPS);

        GetProductRuleGroups result;
        try {
            result = request.call(context.popExpectedStatus(200))
                    .getResponseEntity(GetProductRuleGroups.class);
        } catch (AssertionError e) {
            LOG.warn("Could not fetch product rule groups for product_id='{}': {}", productId, e.getMessage());
            return;
        }

        // Step 2: Filter groups whose product rule belongs to this product_id
        // Groups have product_rule_id (integer id), so we need to cross-reference
        // via the product rules list to find which product_rule_id maps to our product_id
        request = RequestContainer.build().getEntities(PRODUCT_RULE_DETAILS); // reuse existing GET product rules
        // Actually use CrudProductRules logic — fetch product rule id from saved context
        // The product rule for this product_id was already looked up; filter groups by product_rule_id
        List<Long> groupIds = result.data().stream()
                .filter(g -> {
                    // product_rule_id on the group must match the product rule for our product_id
                    // Since we always use a fixed product_id in setup, check via saved IntProductRuleId if available
                    String savedRuleId = context.savedValues.get("IntProductRuleId");
                    if (savedRuleId != null) {
                        return savedRuleId.equals(String.valueOf(g.product_rule_id));
                    }
                    // Fallback: no filter possible without product_rule_id — delete nothing safely
                    return false;
                })
                .map(g -> Long.valueOf(String.valueOf(g.id)))
                .toList();

        if (groupIds.isEmpty()) {
            LOG.info("No product rule groups found for product_id='{}', nothing to delete", productId);
            return;
        }

        LOG.info("Deleting {} group(s) for product_id='{}'", groupIds.size(), productId);
        for (Long id : groupIds) {
            try {
                RequestContainer.build()
                        .deleteEntity(PRODUCT_RULE_GROUP, String.valueOf(id))
                        .call(context.popExpectedStatus(204));
                LOG.info("Deleted product rule group id {}", id);
            } catch (AssertionError ex) {
                LOG.warn("Failed to delete product rule group id {}: {}", id, ex.getMessage());
            }
        }
    }
}