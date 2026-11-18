package com.enernoc.bdap.stepdefs;

import com.enernoc.bdap.model.*;
import com.enernoc.bdap.shared.*;
import com.enernoc.bdap.model.APIResponses.*;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.cucumber.datatable.DataTable;
import io.cucumber.java.en.Given;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import java.util.*;
import java.util.stream.Stream;

import static com.enernoc.bdap.model.EntityType.REGISTRATION;
import static com.enernoc.bdap.shared.Context.metadataSecretValues;
import static org.junit.jupiter.api.Assertions.*;

public class CrudRegistrations {

    private static final Logger LOG = LoggerFactory.getLogger("CrudRegistrations");
    private static final ObjectMapper JSON = new ObjectMapper();
    private final Context context = Context.getContext();
    private final String itsApiKey = metadataSecretValues.getOrDefault("ITS_API_KEY", "missing");
    private String expectedOrgId = "";

    private RequestContainer request;
    private final Utility utility = new Utility();

    private final PostgresClient client = new PostgresClient(metadataSecretValues);


    @Given("I delete all existing table rows for the registration {word}")
    public void iDeleteExistingRegistration(String regName) throws Throwable {
        String regId = RegistrationConfig.getRegistrationId(regName);
        String condition = String.format("registration_id = '%s'", regId);
        client.deleteRecordsTable("\"REGISTRATION_HISTORY\"", condition);
        client.deleteRecordsTable("\"REGISTRATION\"", condition);
    }


    @Given("I clear the saved registration context")
    public void iClearRegistrationContext() {
        context.lastRegistrationId = "";
        context.savedRegistrationOpt = Optional.empty();
    }


    @Given("I set the expected org_id to {word}")
    public void iSetExpectedOrgId(String name) {
        expectedOrgId = Utility.getOrganizationId(name);
        LOG.info("Expected org_id set to " + expectedOrgId);
    }


    @Given("I POST the official ITS mapping for {word}")
    public void iPostNewItsMapping(String ecrmId) {
        String atlasId = Utility.getItsMapping(ecrmId);
        if (RequestContainer.build().doesITSMappingExist(atlasId, itsApiKey)) {
            LOG.info(String.format("Mapping already exists for %s to %s", atlasId, ecrmId));
            return;
        }
        RequestContainer.build().postITSMapping(atlasId, ecrmId, itsApiKey);
        LOG.info(String.format("Created new mapping for %s to %s", atlasId, ecrmId));
    }


    @Given("I POST an alternate ITS mapping for {word}")
    public void iPostRandomItsMapping(String ecrmId) {
        String atlasId = Utility.getItsMapping(ecrmId);
        String altEcrmId = "alt" + ecrmId;
        RequestContainer.build().postITSMapping(atlasId, altEcrmId, itsApiKey);
        LOG.info(String.format("Created random mapping for %s to %s", atlasId, altEcrmId));
    }


    @Given("I DELETE our alternate ITS mapping for {word}")
    public void iDeleteRandomItsMapping(String ecrmId) {
        String atlasId = Utility.getItsMapping(ecrmId);
        String altEcrmId = "alt" + ecrmId;
        RequestContainer.build().deleteITSMapping(atlasId, altEcrmId, itsApiKey);
        LOG.info(String.format("Deleted mapping for %s to %s", atlasId, altEcrmId));
    }


    @Given("I DELETE our ITS mapping for {word}")
    public void iDeleteItsMapping(String ecrmId) {
        String atlasId = Utility.getItsMapping(ecrmId);
        if (!RequestContainer.build().doesITSMappingExist(atlasId, itsApiKey)) {
            LOG.info(String.format("No current mapping for %s to %s", atlasId, ecrmId));
            return;
        }
        RequestContainer.build().deleteITSMapping(atlasId, ecrmId, itsApiKey);
        LOG.info(String.format("Deleted mapping for %s to %s", atlasId, ecrmId));
    }


    @When("I POST a new registration specifying the following properties:")
    public void iPostNewRegistration(DataTable paramTable) {
        int successCode = 201; // Created
        var params = new HashMap<>(paramTable.asMap(String.class, Object.class));
        utility.replaceParmValues(params);

        request = RequestContainer.build().submitEntity(HttpOp.POST, REGISTRATION, params);
        var expectedStatus = context.popExpectedStatus(successCode);
        var entity = request.call(expectedStatus).getResponseEntity(PostRegistrationResult.class);
        if (expectedStatus.getCode() == successCode) {
            assertNotNull(entity);
            context.lastRegistrationId = entity.data().registration_id;
            LOG.info("Registration created: {}", context.lastRegistrationId);
        }
    }

    private boolean needsManualFix(Registration registration) {
        return (registration.product_id == null || registration.ecrm_opportunity_id == null
                || registration.org_id == null || registration.ecrm_account_id == null
                || registration.site_id == null || registration.ecrm_site_id == null);
    }


    @Then("the response should include the new registration")
    public void crudResponseShouldIncludeNewRegistration() {

        var expected = new HashMap<>(request.getBodyProps());

        expected.put("org_id", expectedOrgId);

        // Payload must include either a service delivery point id or flexible asset id. We can use either to get the expected site id.
        String siteId = RegistrationConfig.getSiteIdFromSdpOrFa(expected.getOrDefault("service_delivery_point_id", "").toString(),
                expected.getOrDefault("flexible_asset_id", "").toString());
        expected.put("site_id", siteId);

        // If these fields are specified as null, remove them from the expected response
        Arrays.asList("product_id", "ecrm_opportunity_id", "portfolio_id", "registration_set_id").forEach(field -> {
            if (expected.get(field) == null)
                expected.remove(field);
        });

        // Get the ITS mappings for ecrm_account_id and ecrm_site_id, if they exist
        // This code was modified to support ITAPPSIT-3566: ITS site mapping is too long for type character varying(18)
        Optional<String> ecrmAcctIdOpt = RequestContainer.build().getITSMapping(expectedOrgId, itsApiKey);
        ecrmAcctIdOpt.ifPresent(s -> {
            if (!s.contains("Invalid")) {
                expected.put("ecrm_account_id", s);
            }
        });
        Optional<String> ecrmSiteIdOpt = RequestContainer.build().getITSMapping(expected.get("site_id").toString(), itsApiKey);
        ecrmSiteIdOpt.ifPresent(s -> {
            if (!s.contains("Invalid")) {
                expected.put("ecrm_site_id", s);
            }
        });

        // Determine if needs_manual_fix should be set to true
        expected.put("needs_manual_fix", needsManualFix(JSON.convertValue(expected, new TypeReference<>() {})));

        // Validate the POST response
        List<String> errors = EntityValidator.build()
                .withRequest(request)
                .withExpected(expected)
                .ignoreActualNulls()
                .compare();
        assertTrue(errors.isEmpty(), String.join("\n", errors));

        // Save the registration for later updates
        var respMap = request.getDataAsList().get(0);
        respMap.put("deleted", false);  // this is added by the API when the registration is saved in the database
        Registration reg = JSON.convertValue(respMap, Registration.class);
        context.savedRegistrationOpt = Optional.of(reg);

        // Also save added properties for later use
        context.lastUpdatedBy = respMap.getOrDefault("last_updated_by", "missing").toString();
        context.lastUpdatedDttmUtc = respMap.getOrDefault("last_updated_dttm_utc", "missing").toString();

        LOG.info("Response result verified");
    }


    private void updateStringOrNull(Registration reg, HashMap<String, Object> props, String propName) {
        if (props.containsKey(propName)) {
            Object obj = props.get(propName);
            String newVal = (obj == null ? null : obj.toString());
            switch (propName) {
                case "status" -> reg.status = newVal;
                case "product_id" -> reg.product_id = newVal;
                case "flexible_asset_id" -> reg.flexible_asset_id = newVal;
                case "service_delivery_point_id" -> reg.service_delivery_point_id = newVal;
                case "ecrm_opportunity_id" -> reg.ecrm_opportunity_id = newVal;
                case "last_updated_by" -> reg.last_updated_by = newVal;
                case "portfolio_id" -> reg.portfolio_id = newVal;
                case "registration_set_id" -> reg.registration_set_id = newVal;
                default -> fail("Unsupported field");
            }
        }
    }

    @Then("the response should include the updated registration")
    public void crudResponseShouldUpdatedRegistration() {

        var respMap = Collections.unmodifiableMap(request.getDataAsList().get(0));
        var bodyProps = request.getBodyProps();
        String regId = (String) respMap.getOrDefault("registration_id", "No registration id!");
        assertTrue(context.savedRegistrationOpt.isPresent(), "Something's wrong! No saved registration");
        var reg = context.savedRegistrationOpt.get();
        assertEquals(reg.registration_id, regId);

        // Update derived ecrm values if necessary
        boolean refreshTrue = request.url.endsWith("refresh=true");

        String sdpId = (String) bodyProps.get("service_delivery_point_id");
        String faId = (String) bodyProps.get("flexible_asset_id");

        if (sdpId == null && faId == null) {
            // If both sdp and fa are null, API sets derived fields to null.
            reg.site_id = null;
            reg.ecrm_site_id = null;
        } else {
            // If refresh=true was specified, of if SDP or FA have changed, update the derived fields
            // This code was modified to support ITAPPSIT-3566: ITS site mapping is too long for type character varying(18)
            refreshTrue = refreshTrue || !Objects.equals(reg.service_delivery_point_id, sdpId) || !Objects.equals(reg.flexible_asset_id, faId);
            if (refreshTrue) {
                String siteId = RegistrationConfig.getSiteIdFromSdpOrFa(sdpId, faId);
                reg.site_id = siteId;
                reg.ecrm_site_id = RequestContainer.build().getITSMapping(siteId, itsApiKey).orElse(null);
                if (reg.ecrm_site_id != null && reg.ecrm_site_id.contains("Invalid")) {
                    reg.ecrm_site_id = null;
                }
                reg.ecrm_account_id = RequestContainer.build().getITSMapping(reg.org_id, itsApiKey).orElse(null);
                if (reg.ecrm_account_id != null && reg.ecrm_account_id.contains("Invalid")) {
                    reg.ecrm_account_id = null;
                }
            }
            reg.service_delivery_point_id = sdpId;
            reg.flexible_asset_id = faId;
        }

        // Update other fields that were in the PUT payload
        Stream.of("status", "product_id", "ecrm_opportunity_id", "last_updated_by", "portfolio_id", "registration_set_id")
                .forEach(name -> updateStringOrNull(reg, bodyProps, name));

        // Determine if needs_manual_fix should be set to true
        reg.needs_manual_fix = needsManualFix(reg);

        // Now verify that the PUT response is identical to the expected updated registration.
        var regMap = JSON.convertValue(reg, new TypeReference<HashMap<String, Object>>() {});
        regMap.remove("last_updated_dttm_utc");  // this is updated automatically in db
        List<String> errors = EntityValidator.build()
                .withRequest(request)
                .withExpected(regMap)
                .removeExpectedNulls()
                .compare();
        assertTrue(errors.isEmpty(), String.join("\n", errors));

        // finally, update the saved registration
        regMap.put("last_updated_dttm_utc", respMap.getOrDefault("last_updated_dttm_utc", "No last_updated_dttm_utc!"));
        context.savedRegistrationOpt = Optional.of(JSON.convertValue(regMap, new TypeReference<>(){}));

        LOG.info("Response verified");
    }


    @Then("needs_manual_fix should be {word}")
    public void needsManualFixShouldBe(String expectedParm) {

        assertTrue(context.savedRegistrationOpt.isPresent(), "Something's wrong! No saved registration");
        Boolean expected = Boolean.parseBoolean(expectedParm);
        assertEquals(expected, context.savedRegistrationOpt.get().needs_manual_fix, "Invalid needs_manual_fix!");

        LOG.info(String.format("needs_manual_fix verified as %b", expected));
    }


    @Then("GET registration should return the current state of the registration")
    public void getRegistrationShouldReturnNewEntity() {

        assertTrue(context.savedRegistrationOpt.isPresent(), "Something's wrong! No saved registration");
        var regMap = JSON.convertValue(context.savedRegistrationOpt.get(), new TypeReference<HashMap<String, Object>>() {});
        var request = RequestContainer.build().getLastEntity(REGISTRATION);
        var getRequest = request.call();

        List<String> errors = EntityValidator.build()
                .withRequest(getRequest)
                .withExpected(regMap)
                .removeExpectedNulls()
                .ignoreActualNulls()
                .compare();
        assertTrue(errors.isEmpty(), String.join("\n", errors));

        LOG.info("Registration verified");
    }


    boolean sendFullPutPayload = true;


    @Given("I set sendFullPutPayload to {word}")
    public void iSetsendFullPutPayload(String flag) {
        sendFullPutPayload = Boolean.parseBoolean(flag);
    }


    @When("I update the registration with new values:")
    public void iPutRegistration(DataTable paramTable) {

        int successCode = 200;

        var params = new HashMap<>(paramTable.asMap(String.class, Object.class));
        utility.replaceParmValues(params);

        var reg = context.savedRegistrationOpt.orElseThrow(() -> new IllegalStateException("Something's wrong! No saved registration"));

        // ITAPPSIT-3399 changes the behavior of PUT from PATCH to a true PUT. To avoid rewriting existing scenarios, I added this
        // code to fill out the PUT payload with existing values.
        if (sendFullPutPayload) {
            // Fill out payload
            Stream.of("status", "service_delivery_point_id", "flexible_asset_id", "product_id", "ecrm_opportunity_id", "last_updated_by", "portfolio_id", "registration_set_id")
                    .filter(prop -> !params.containsKey(prop))
                    .forEach(prop -> params.put(prop, switch (prop) {
                        case "status" -> reg.status;
                        case "service_delivery_point_id" -> reg.service_delivery_point_id;
                        case "flexible_asset_id" -> reg.flexible_asset_id;
                        case "product_id" -> reg.product_id;
                        case "ecrm_opportunity_id" -> reg.ecrm_opportunity_id;
                        case "last_updated_by" -> reg.last_updated_by;
                        case "portfolio_id" -> reg.portfolio_id;
                        case "registration_set_id" -> reg.registration_set_id;
                        default -> fail("something went wrong");
                    }));
        } else {
            // Send partial payload (missing optional properties wil be set to null in db)
            Stream.of("status", "service_delivery_point_id", "flexible_asset_id", "product_id", "ecrm_opportunity_id", "last_updated_by", "portfolio_id", "registration_set_id")
                    .filter(prop -> !params.containsKey(prop))
                    .forEach(prop -> {
                        switch (prop) {
                            case "status" -> reg.status = null;
                            case "service_delivery_point_id" -> reg.service_delivery_point_id = null;
                            case "flexible_asset_id" -> reg.flexible_asset_id = null;
                            case "product_id" -> reg.product_id = null;
                            case "ecrm_opportunity_id" -> reg.ecrm_opportunity_id = null;
                            case "last_updated_by" -> reg.last_updated_by = null;
                            case "portfolio_id" -> reg.portfolio_id = null;
                            case "registration_set_id" -> reg.registration_set_id = null;
                            default -> fail("something went wrong");
                        }
                    });
        }

        Optional<String> refreshOpt = params.containsKey("refresh")
                ? Optional.of(params.remove("refresh").toString())
                : Optional.empty();

        // Make the PUT request
        HttpStatus expectedStatus = context.popExpectedStatus(successCode);
        request = RequestContainer.build();
        var payload = new HashMap<>(params);
        params.entrySet().stream()
                .filter(e -> e.getValue() != null)
                .filter(e -> "<missing>".equals(e.getValue().toString())).map(Map.Entry::getKey)
                .toList()
                .forEach(payload::remove);
        request.submitEntity(HttpOp.PUT, REGISTRATION, payload).addIdToPath(context.lastRegistrationId).addRefresh(refreshOpt)
                .call(expectedStatus).getResponseEntity(PutRegistrationResult.class);

        if (expectedStatus.getCode() == successCode) {
            LOG.info(String.format("PUT returned %d", successCode));
        }
    }


    @When("I DELETE my registration")
    public void iDeleteRegistration() {
        int successCode = 204; // No Content
        assertTrue(context.savedRegistrationOpt.isPresent(), "Something's wrong! No saved registration");
        var registration = context.savedRegistrationOpt.get();
        registration.deleted = true;
        HttpStatus expectedStatus = context.popExpectedStatus(successCode);
        request = RequestContainer.build().deleteEntity(REGISTRATION, registration.registration_id);
        request.call(expectedStatus);
        if (expectedStatus.getCode() == successCode) {
            LOG.info("Registration {} deleted", registration.registration_id);
        }
    }


    @When("expecting an error, I DELETE the registration with id {word}")
    public void iDeleteRegistrationId(String id) {
        request = RequestContainer.build().deleteEntity(REGISTRATION, id);
        request.call(context.popExpectedStatus(204));
    }

}
