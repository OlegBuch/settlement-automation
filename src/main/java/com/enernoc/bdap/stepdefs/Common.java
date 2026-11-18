package com.enernoc.bdap.stepdefs;

import com.enernoc.bdap.model.*;
import com.enernoc.bdap.shared.Context;
import com.enernoc.bdap.shared.EcoCredentials;
import com.enernoc.bdap.shared.Utility;
import io.cucumber.java.ParameterType;
import io.cucumber.java.en.*;
import io.restassured.http.ContentType;
import io.restassured.path.json.JsonPath;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.File;
import java.nio.file.Files;
import java.time.Duration;
import java.util.*;

import static com.enernoc.bdap.model.EntityType.*;
import static com.enernoc.bdap.shared.Context.testStartEpoch;
import static io.restassured.RestAssured.given;
import static org.junit.jupiter.api.Assertions.*;


public class Common {

    private static final Logger LOG = LoggerFactory.getLogger("Common");
    private Context context;


    @ParameterType(".*")
    public RegistrationAdjective registrationAdjective(String str) {
        return RegistrationAdjective.get(str);
    }

    @Given("^I start with an empty context$")
    public void I_start_with_empty_context()  {
        context = Context.getNewContext();
    }


    @Given("this scenario is only supported for the {word} environment")
    public void thisScenarioOnlySupportedForEnv(String env) {
        if (!env.equals(Context.targetEnv)) {
            fail("This scenario is only supported for the " + env + " environment!");
        }
    }


    @Given("this scenario is not supported for the {word} environment")
    public void thisScenarioNotSupportedForEnv(String env) {
        if (env.equals(Context.targetEnv)) {
            fail("This scenario is not supported for the " + env + " environment!");
        }
    }


    @Given("^-> ([^\"]*)$")
    public void logMessageHyphen(String msg) {
        LOG.info(String.format("\n===> %s\n", msg));
    }


    @Given("^> ([^\"]*)$")
    public void logMessageArrow(String msg) {
        LOG.info(String.format("\n==> %s\n", msg));
    }


    @Given("^I want to log all API requests")
    public void iLogAllAPIRequests() {
        context.logAllAPIRequests = true;
    }


    @Given("^I want to log all API responses$")
    public void iLogAllAPIResponses() {
        context.logAllAPIResponses = true;
    }

    @Given("^I want to turn on all logging$")
    public void iWantTurnOnLogging() {
        context.logAllAPIRequests = true;
        context.logAllAPIResponses = true;
    }


    @Given("^I want to turn off all logging$")
    public void iWantTurnOffLogging() {
        context.logAllAPIRequests = false;
        context.logAllAPIResponses = false;
    }

    @Given("^log on$")
    public void iTurnOnLogging() {
        iWantTurnOnLogging();
    }

    @Given("^log off$")
    public void iTurnOffLogging() {
        iWantTurnOffLogging();
    }


    @Given("^stop$")
    public void iStopHere() {
        fail("I stopped here");
    }


    @Given("I stop here because {string}")
    public void iStopHereMsg(String msg) {
        fail(msg);
    }


    @Given("This scenario fails because {string}")
    public void scenarioFailsBecause(String msg) {
        fail(msg);
    }


    @Given("I need to implement this scenario")
    public void iNeedImplementScenario() {
        fail("I need to implement this scenario");
    }


    // Syntactic sugar to preface a list of operative stepdefs
    @Given("I do all of the following:")
    public void iDoAllFollowing() {
        LOG.info("I do all of the following:");
    }


    // Syntactic sugar to preface a list of verification stepdefs
    @Given("all of the following stepdefs should pass:")
    public void allFollowingShouldPass() {
        LOG.info("All of the following stepdefs should pass:");
    }


    @When("I wait {int} seconds")
    public void iWaitSeconds(int seconds) throws Exception {
        Thread.sleep(Duration.ofSeconds(seconds));
    }


    @Given("I do not send enoc_session")
    public void iDoNotSendEnocSession() {
        context.includeEnocSession = false;
        LOG.info("enoc_session will not be included on API calls");
    }


    @Given("I do not send an API key")
    public void iDoNotSendAPIKey() {
        context.includeApiKey = false;
        LOG.info("API key will not be included on API calls");
    }


    @Given("I send an invalid enoc_session")
    public void iSendInvalidEnocSession() {
        context.includeInvalidEnocSession = true;
        LOG.info("invalid enoc_session will be included on API calls");
    }

    @Given("I send a valid enoc_session")
    public void iSendValidEnocSession() {
        context.includeEnocSession = true;
        context.includeInvalidEnocSession = false;
        LOG.info("Valid enoc_session will be included on API calls");
    }


    @Given("I send an invalid API key")
    public void iSendInvalidAPIKey() {
        context.includeInvalidApiKey = true;
        LOG.info("invalid API key will be included on API calls");
    }


    @Given("I send a valid API key")
    public void iSendValidAPIKey() {
        context.includeApiKey = true;
        context.includeInvalidApiKey = false;
        LOG.info("valid API key will be included on API calls");
    }

    @Given("I set the context registration id to {string}")
    public void iSetContextLastRegistrationId(String choice) {
        context.lastRegistrationId = switch (choice) {
            case "random uuid" -> UUID.randomUUID().toString();
            case "non-uuid" -> "foo";
            case "empty string" -> "";
            default -> choice;
        };
    }


    @Given("I reset the test start epoch and clear the pipeline settlement lists")
    public void iSetTestStartEpoch() {
        context.pipelineSettlementsProcessed.clear();
        context.pipelineSettlementsSkipped.clear();
        long epoch = System.currentTimeMillis() / 1000;
        testStartEpoch = epoch;
        LOG.info(String.format("Test start epoch reset to '%s'", Utility.epochToZonedDateTimeUTC(testStartEpoch)));
    }


    @ParameterType(".*")
    public UserCredentials userCredentials(String str) {return UserCredentials.valueOf(str.toUpperCase());}

    @Given("I log in as a settlement API {userCredentials}")
    public void iLogInAsSettlementUser(UserCredentials user) throws Exception {
        assertNotNull(user.username, "User name not found in AWS secret!");
        assertNotNull(user.password, "User password not found in AWS secret!");
        assertNotNull(user.realm, "User realm not found in AWS secret!");
        String propKey = String.format("ATLAS_SESSION_%s_%s", Context.targetEnv, user.username);
        File tokenFile = new File(propKey);
        if (tokenFile.exists() && (System.currentTimeMillis() - tokenFile.lastModified() < Duration.ofHours(8).toMillis())) {
            Context.enocSession = new String(Files.readAllBytes(tokenFile.toPath()));
            LOG.info("Re-using session for {}", user.username);
        } else {
            var traceid = UUID.randomUUID();
            LOG.info("Login x-enelx-trace-id: " + traceid);
            Map<String, String> userMap = Map.of("username", user.username, "password", user.password, "realm", user.realm);
            String response = given().header("x-enelx-trace-id", traceid).contentType(ContentType.JSON).body(userMap)
                    .when().post(Context.targetLoginUrl).then().log().ifValidationFails().assertThat().statusCode(200)
                    .extract().asString();
            Context.enocSession = JsonPath.from(response).getString("data.enoc_session");
            Files.writeString(tokenFile.toPath(), Context.enocSession);
            LOG.info("Login successful for {}", user.username);
        }
    }


    @Given("I set the Energy Markets program to {word}")
    public void iSetProgram(String programName) {
        context.program = Context.PROGRAM.valueOf(programName);
    }


    @Given("I expect the next API call to return a status code of {int} and details of {string}")
    public void iExpectNextStatusCode(int code, String details) {
        assertTrue(context.expectedStatus.isEmpty(), "Cannot call this stepdef more than once before a CRUD operation!");
        context.expectedStatus.push(HttpStatus.build().withCode(code).withDetails(details));
        LOG.info(String.format("Expected status set: %d", code));
    }


    @Given("I expect the next API call to return a status code of {int} and message of {string}")
    public void iExpectNextStatusCodeMessage(int code, String message) {
        assertTrue(context.expectedStatus.isEmpty(), "Cannot call this stepdef more than once before a CRUD operation!");
        context.expectedStatus.push(HttpStatus.build().withCode(code).withMessage(message));
        LOG.info(String.format("Expected status set: %d", code));
    }


    @When("{word} {entityType} should return the expected status")
    public void iGetEntityExpectedStatus(String op, EntityType entityType) {

        String entityId = switch (entityType) {
            case SETTLEMENT -> context.lastSettlementId;
            case SETTLEMENT_ITEM -> context.lastSettlementItemId;
            case REGISTRATION -> context.lastRegistrationId;
            default -> fail("Unsupported entity type");
        };

        // PUT and PATCH require dummy payloads to pass swagger validation
        RequestContainer request = switch (op) {
            case "GET" -> RequestContainer.build().getEntity(entityType, entityId);
            case "PUT" -> RequestContainer.build().submitEntity(HttpOp.PUT, entityType, new HashMap<>() {{
                switch (entityType) {
                    case SETTLEMENT -> {
                        this.put("settlement_id", entityId);
                        this.put("settlement_status", "FINALIZED");
                        this.put("settlement_type", "EVENT");
                        this.put("settlement_subtype", "foo");
                        this.put("start_dttm_utc", "2023-09-08T11:00:00Z");
                        this.put("end_dttm_utc", "2023-09-08T12:00:00Z");
                        this.put("business_process_status", "IN_PROCESS");
                        this.put("event_id", UUID.randomUUID().toString());
                        this.put("source_system_type", "CLASSIC_DR");
                        this.put("description","foo");
                        this.put("change_comments","foo");
                    }
                    case SETTLEMENT_ITEM -> {
                        this.put("settlement_item_id", entityId);
                        this.put("change_comments", "foo");
                    }
                    default -> fail("Unsupported entity type");
                };
            }});
            case "PATCH" -> RequestContainer.build().submitEntity(HttpOp.PATCH, entityType, new HashMap<>() {{
                switch (entityType) {
                    case SETTLEMENT -> {
                        this.put("settlement_id", entityId);
                        this.put("settlement_status", "FINALIZED");
                        this.put("change_comments", "foo");
                    }
                    case SETTLEMENT_ITEM -> {
                        this.put("settlement_item_id", entityId);
                        this.put("change_comments", "foo");
                    }
                    default -> fail("Unsupported entity type");
                };
            }});
            case "DELETE" -> RequestContainer.build().deleteEntity(entityType, entityId);
            default -> fail("Unsupported http op");
        };

        if ("GET".equals(op) && SETTLEMENT.equals(entityType)) {
            context.includeDeletedOpt.ifPresent(flag -> request.addQueryParm("include_deleted", flag));
        }
        if ("GET".equals(op) && REGISTRATION.equals(entityType)) {
            context.doRegistrationBackfillOpt.ifPresent(flag -> request.addQueryParm("backfill", flag));
        }
        request.call(context.popExpectedStatus(200)).getResponseEntity(APIResponses.BasicResult.class);
    }


    @Then("the expected status should be returned")
    public void expectedStatusShouldBeReturned() {
        // This stepdef is mainly syntatic sugar, because status validation is actually done in RequestContainer.call()
        assertTrue(context.lastRequest.statusVerified, "the response status was not verified!");
        LOG.info(String.format("Response status verified: %d '%s'", context.lastRequest.response.getStatusCode(),
                context.lastRequest.responseMap.getOrDefault("detail", "<no details>")));
    }


    @When("(if )I set include_deleted={word}")
    public void ifISetIncludeDeleted(String value) {
        context.includeDeletedOpt = switch (value) {
            case "true" -> Optional.of(true);
            case "false" -> Optional.of(false);
            case "missing" -> Optional.empty();
            default -> fail(String.format("Invalid value: '%s'", value));
        };
    }


    @When("(if )I set include_details={word}")
    public void ifISetIncludeDetails(String value) {
        context.includeDetailsOpt = switch (value) {
            case "true" -> Optional.of(true);
            case "false" -> Optional.of(false);
            case "missing" -> Optional.empty();
            default -> fail(String.format("Invalid value: '%s'", value));
        };
    }


    @When("(if )I set registration backfill={word}")
    public void ifISetRegBackfill(String value) {
        context.doRegistrationBackfillOpt = switch (value) {
            case "true" -> Optional.of(true);
            case "false" -> Optional.of(false);
            case "missing" -> Optional.empty();
            default -> fail(String.format("Invalid value: '%s'", value));
        };
    }

    @Given("I log in to Atlas v4 as {string} and store the enoc_session")
    public void iLogInToAtlasV4AndStoreSession(String userKey) throws Exception {
        assertNotNull(Context.ecoExternalUsers, "ecoExternalUsers not loaded from configuration.json");

        Map<String, Map<String, String>> envUsers = Context.ecoExternalUsers.get(Context.targetEnv);
        assertNotNull(envUsers, "Environment " + Context.targetEnv + " not found in ecoExternalUsers");

        Map<String, String> userCreds = envUsers.get(userKey);
        assertNotNull(userCreds, "User key '" + userKey + "' not found in ecoExternalUsers for env " + Context.targetEnv);

        String username = userCreds.get("username");
        String password = EcoCredentials.password("ecoExternalUsers", Context.targetEnv, userKey);
        assertNotNull(username, "username missing for " + userKey);
        assertNotNull(password, "password missing for " + userKey);

        // Construct Atlas v4 Login URL
        String atlasLoginUrl = Context.targetLoginUrl.replaceAll("/api/v[0-9]+/sessions/login", "/api/v4/sessions/login");
        if (!atlasLoginUrl.contains("/api/v4/sessions/login")) {
            atlasLoginUrl = atlasLoginUrl + "/api/v4/sessions/login";
        }

        LOG.info("🔑 Attempting Atlas v4 login for external user: {} at {}", userKey, atlasLoginUrl);

        Map<String, String> payload = Map.of("username", username, "password", password);

        String response = given()
                .relaxedHTTPSValidation()
                .contentType(ContentType.JSON)
                .body(payload)
                .when()
                .post(atlasLoginUrl)
                .then()
                .log().ifValidationFails()
                .assertThat().statusCode(200)
                .extract().asString();

        String session = JsonPath.from(response).getString("enoc_session");
        if (session == null || session.isEmpty()) {
            session = JsonPath.from(response).getString("data.enoc_session");
        }

        assertNotNull(session, "Failed to extract enoc_session from Atlas v4 login response. Raw: " + response);
        Context.enocSession = session;

        // CRITICAL: Clear Basic Auth credentials so RequestContainer does NOT send the Authorization header
        Context.ecoBasicAuthUser = "";
        Context.ecoBasicAuthPass = "";
        context.includeAuthorization = false;

        LOG.info("✅ Successfully acquired enoc_session for Atlas user {}. Basic Auth cleared.", userKey);
    }


}
