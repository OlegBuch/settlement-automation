package com.enernoc.bdap.stepdefs;

import com.enernoc.bdap.model.APIResponses.GetProductRuleDetail;
import com.enernoc.bdap.model.APIResponses.PostProductRuleDetails;
import com.enernoc.bdap.model.APIResponses.PutProductRuleDetails;
import com.enernoc.bdap.model.ProductRuleDetails;
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

import static com.enernoc.bdap.model.EntityType.PRODUCT_RULE_DETAIL;
import static com.enernoc.bdap.model.EntityType.PRODUCT_RULE_DETAILS;
import static com.enernoc.bdap.model.HttpOp.POST;
import static com.enernoc.bdap.model.HttpOp.PUT;
import static org.junit.jupiter.api.Assertions.*;

public class CrudProductRuleDetails {

    private static final Logger LOG = LoggerFactory.getLogger(CrudProductRuleDetails.class);

    private final Context context = Context.getContext();
    private final Utility utility = new Utility();

    private RequestContainer request;
    private Long lastDetailId;
    private final Map<String, Long> savedDetailIdsByTag = new HashMap<>();

    //
    // Helpers
    //
    private Long getRequiredCurrentDetailId() {
        assertNotNull(lastDetailId, "No current product rule detail id set!");
        return lastDetailId;
    }

    private void coerceToLong(Map<String, Object> body, String... keys) {
        for (String key : keys) {
            Object val = body.get(key);
            if (val == null) continue;
            String strVal = val.toString().trim();
            if (strVal.matches("-?\\d+")) {
                body.put(key, Long.parseLong(strVal));
            }
        }
    }

    //
    // Context id operations
    //
    @Given("I set the context product rule detail ID to {int}")
    public void iSetContextProductRuleDetailIdToInt(int id) {
        this.lastDetailId = (long) id;
    }

    @Given("I set the context product rule detail id to {word}")
    public void iSetContextProductRuleDetailIdToTag(String tagOrLiteral) {
        // If tag stored earlier, resolve it; otherwise treat as literal numeric id
        if (savedDetailIdsByTag.containsKey(tagOrLiteral)) {
            this.lastDetailId = savedDetailIdsByTag.get(tagOrLiteral);
        } else {
            this.lastDetailId = Long.valueOf(tagOrLiteral);
        }
    }

    @And("I save this product rule detail id as {word}")
    public void iSaveProductRuleDetailIdAsTag(String tag) {
        Long id = getRequiredCurrentDetailId();
        savedDetailIdsByTag.put(tag, id);
        context.savedValues.put(tag, String.valueOf(id));
    }

    //
    // Cleanup helper: remove all details for a given product_rule_id + parameter
    //
    @Given("I delete all existing product rule details for product group id {word} and parameter {int}")
    public void iDeleteAllExistingProductRuleDetailsForRuleAndParam(String prGroupId, int prParamDefId) {
        request = RequestContainer.build()
                .getEntities(PRODUCT_RULE_DETAILS);

        var result = request.call(context.popExpectedStatus(200))
                .getResponseEntity(GetProductRuleDetail.class);

        List<Long> ids = result.data().stream()
                .filter(d -> prGroupId.equals(d.pr_group_id)
                        && String.valueOf(prParamDefId).equals(d.pr_parameter_def_id))
                .map(d -> d.id)
                .toList();

        if (ids.isEmpty()) {
            LOG.info("No product rule details found for pr_group_id={} pr_parameter_def_id={}, nothing to delete",
                    prGroupId, prParamDefId);
            return;
        }

        var deleteStatus = context.popExpectedStatus(204); // pop once, reuse for all deletes

        for (Long id : ids) {
            try {
                RequestContainer.build()
                        .deleteEntity(PRODUCT_RULE_DETAIL, String.valueOf(id))
                        .call(deleteStatus);
            } catch (AssertionError ex) {
                LOG.warn("Failed to delete product rule detail with id {}", id, ex);
            }
        }
    }
    //
    // POST
    //
    @When("I POST a new product rule detail specifying the following properties")
    public void iPostNewProductRuleDetail(DataTable table) {
        HashMap<String, Object> body = new HashMap<>(table.asMap(String.class, Object.class));
        utility.replaceParmValues(body);

        body.replaceAll((_, v) -> {
            if (v instanceof String s && context.savedValues.containsKey(s)) {
                return context.savedValues.get(s);
            }
            return v;
        });

        coerceToLong(body, "pr_group_id", "pr_parameter_def_id");

        request = RequestContainer.build()
                .submitEntity(POST, PRODUCT_RULE_DETAIL, body);

        var expected = context.popExpectedStatus(201);
        var entity = request.call(expected)
                .getResponseEntity(PostProductRuleDetails.class);

        if (expected.getCode() == 201) {
            ProductRuleDetails detail = entity.data();
            assertNotNull(detail, "POST product rule detail returned null data");
            this.lastDetailId = detail.id;
        }
    }


    @Then("the response should include the new product rule detail")
    public void responseShouldIncludeNewProductRuleDetail() {
        Map<String, Object> resp = request.getDataAsList().get(0);

        assertNotNull(lastDetailId, "No product rule detail id saved");
        assertEquals(
                String.valueOf(lastDetailId),
                String.valueOf(resp.get("id")),
                "Unexpected id in response"
        );

        // Check mandatory fields are present and non-empty
        assertTrue(resp.containsKey("pr_group_id"), "Missing pr_group_id");
        assertNotNull(resp.get("pr_group_id"), "pr_group_id is null");

        assertTrue(resp.containsKey("pr_parameter_def_id"), "Missing pr_parameter_def_id");
        assertNotNull(resp.get("pr_parameter_def_id"), "pr_parameter_def_id is null");

        assertTrue(resp.containsKey("value"), "Missing value");
        assertNotNull(resp.get("value"), "value is null");

        assertTrue(resp.containsKey("start_dttm_utc"), "Missing start_dttm_utc");
        assertNotNull(resp.get("start_dttm_utc"), "start_dttm_utc is null");

        assertTrue(resp.containsKey("end_dttm_utc"), "Missing end_dttm_utc");
        assertNotNull(resp.get("end_dttm_utc"), "end_dttm_utc is null");
    }

    //
    // GET by id
    //
    @When("I GET the product rule detail by id")
    public void iGetProductRuleDetailById() {
        String idStr;
        if (context.savedValues.containsKey("productRuleDetailId")) {
            idStr = context.savedValues.get("productRuleDetailId");
        } else {
            idStr = String.valueOf(getRequiredCurrentDetailId());
        }

        request = RequestContainer.build()
                .getEntity(PRODUCT_RULE_DETAIL, idStr);
        var expected = context.popExpectedStatus(200);
        request.call(expected);
    }

    @Then("GET product rule detail should return the current state")
    public void getProductRuleDetailShouldReturnCurrentState() {
        Map<String, Object> respMap = Collections.unmodifiableMap(request.getDataAsList().get(0));
        String idStr = Objects.toString(respMap.getOrDefault("id", "No id!"));
        assertEquals(String.valueOf(getRequiredCurrentDetailId()), idStr);
    }

    //
    // GET all (optional generic check, similar to product rules)
    //
    @When("I GET all product rule details")
    public void iGetAllProductRuleDetails() {
        request = RequestContainer.build()
                .getEntities(PRODUCT_RULE_DETAILS);
        request.call(context.popExpectedStatus(200));
    }

    @Then("the product rule details list should be returned")
    public void productRuleDetailsListShouldBeReturned() {
        List<HashMap<String, Object>> list = request.getDataAsList();
        assertFalse(list.isEmpty(), "No product rule details returned!");

        for (Map<String, Object> item : list) {
            assertTrue(item.containsKey("id"), "Missing id");
            assertNotNull(item.get("id"), "id is null");

            assertTrue(item.containsKey("product_rule_id"), "Missing product_rule_id");
            assertNotNull(item.get("product_rule_id"), "product_rule_id is null");

            assertTrue(item.containsKey("pr_parameter_def_id"), "Missing pr_parameter_def_id");
            assertNotNull(item.get("pr_parameter_def_id"), "pr_parameter_def_id is null");

            assertTrue(item.containsKey("value"), "Missing value");
            assertNotNull(item.get("value"), "value is null");

            assertTrue(item.containsKey("start_dttm_utc"), "Missing start_dttm_utc");
            assertNotNull(item.get("start_dttm_utc"), "start_dttm_utc is null");

            assertTrue(item.containsKey("end_dttm_utc"), "Missing end_dttm_utc");
            assertNotNull(item.get("end_dttm_utc"), "end_dttm_utc is null");
        }
    }

    //
    // PUT
    //
    @When("I update the product rule detail with new values")
    public void iPutProductRuleDetail(DataTable table) {
        HashMap<String, Object> body = new HashMap<>(table.asMap(String.class, Object.class));
        utility.replaceParmValues(body);

        String idStr;
        if (context.savedValues.containsKey("productRuleDetailId")) {
            idStr = context.savedValues.get("productRuleDetailId");
        } else {
            idStr = String.valueOf(getRequiredCurrentDetailId());
        }

        request = RequestContainer.build()
                .submitEntity(PUT, PRODUCT_RULE_DETAIL, body)
                .addIdToPath(idStr);

        var expected = context.popExpectedStatus(200);
        var entity = request.call(expected)
                .getResponseEntity(PutProductRuleDetails.class);

        if (expected.getCode() == 200) {
            ProductRuleDetails detail = entity.data();
            assertNotNull(detail, "PUT product rule detail returned null data");
            this.lastDetailId = detail.id;
        }
    }

    @Then("the response should include the updated product rule detail")
    public void responseShouldIncludeUpdatedProductRuleDetail() {
        Map<String, Object> resp = request.getDataAsList().get(0);

        assertNotNull(lastDetailId, "No product rule detail id saved");
        assertEquals(
                String.valueOf(lastDetailId),
                String.valueOf(resp.get("id")),
                "Unexpected id in response"
        );

        // Check that timeframe fields are present and non-empty
        assertTrue(resp.containsKey("start_dttm_utc"), "Missing start_dttm_utc");
        Object start = resp.get("start_dttm_utc");
        assertNotNull(start, "start_dttm_utc is null");
        assertFalse(String.valueOf(start).isBlank(), "start_dttm_utc is blank");

        assertTrue(resp.containsKey("end_dttm_utc"), "Missing end_dttm_utc");
        Object end = resp.get("end_dttm_utc");
        assertNotNull(end, "end_dttm_utc is null");
        assertFalse(String.valueOf(end).isBlank(), "end_dttm_utc is blank");
    }

    //
    // DELETE
    //
    @When("I DELETE my product rule detail")
    public void iDeleteMyProductRuleDetail() {
        String idStr;
        if (context.savedValues.containsKey("productRuleDetailId")) {
            idStr = context.savedValues.get("productRuleDetailId");
        } else {
            idStr = String.valueOf(getRequiredCurrentDetailId());
        }

        request = RequestContainer.build()
                .deleteEntity(PRODUCT_RULE_DETAIL, idStr);
        request.call(context.popExpectedStatus(204));
    }

    @Given("I delete all existing product rule details for product rule product id {word}")
    public void iDeleteAllExistingProductRuleDetailsForProductRule(String productIdTag) {
        String productId = context.savedValues.getOrDefault(productIdTag, productIdTag);

        // GET all details
        request = RequestContainer.build().getEntities(PRODUCT_RULE_DETAILS);
        var result = request.call(context.popExpectedStatus(200))
                .getResponseEntity(GetProductRuleDetail.class);

        List<Long> ids = result.data().stream()
                .filter(d -> productId.equals(d.pr_group_id))
                .map(d -> d.id)
                .toList();

        if (ids.isEmpty()) {
            LOG.info("No product rule details found for product_id='{}', nothing to delete", productId);
            return;
        }

        for (Long id : ids) {
            try {
                RequestContainer.build()
                        .deleteEntity(PRODUCT_RULE_DETAIL, String.valueOf(id))
                        .call(context.popExpectedStatus(204));
                LOG.info("Deleted product rule detail id {}", id);
            } catch (AssertionError ex) {
                LOG.warn("Failed to delete product rule detail id {}: {}", id, ex.getMessage());
            }
        }
    }

}
