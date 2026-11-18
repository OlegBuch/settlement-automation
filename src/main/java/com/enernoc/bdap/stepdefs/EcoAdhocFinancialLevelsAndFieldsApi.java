package com.enernoc.bdap.stepdefs;

import com.enernoc.bdap.model.*;
import com.enernoc.bdap.shared.Context;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.cucumber.java.ParameterType;
import io.cucumber.java.en.Given;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;
import io.restassured.http.ContentType;
import io.restassured.path.json.JsonPath;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.File;
import java.nio.file.Files;
import java.time.Duration;
import java.util.*;

import static com.enernoc.bdap.model.Endpoint.GET_ADHOC_FINANCIAL_API_LEVELS;
import static io.restassured.RestAssured.given;
import static org.junit.jupiter.api.Assertions.*;

public class EcoAdhocFinancialLevelsAndFieldsApi {

    private static final Logger LOG = LoggerFactory.getLogger(EcoAdhocFinancialLevelsAndFieldsApi.class);

    private final Context context = Context.getContext();
    private RequestContainer request;
    private String lastLevelUuid;


    // ──────────────────────────────────────────────
    // ECO Login Steps
    // ──────────────────────────────────────────────

    @Given("I am trying to log in as an ECO admin")
    public void iLogInAsEcoAdmin() throws Exception {
        loginAsEcoUser(UserCredentialsEco.ECO_ADMIN);
    }

    @Given("I log in as an ECO user without ADHOC_FINANCIAL_API_ADMIN permission")
    public void iLogInAsEcoUserWithoutAdminPermission() throws Exception {
        // ECO_USER has ADHOC_FINANCIAL_API_READ only, NOT ADHOC_FINANCIAL_API_ADMIN
        loginAsEcoUser(UserCredentialsEco.ECO_USER);
    }


    /**
     * Shared ECO login logic. Authenticates via login/password and stores
     * the resulting session token in Context.enocSession with file-based caching.
     */
    private void loginAsEcoUser(UserCredentialsEco user) {
        String username = user.getUsername();
        String password = user.getPassword();

        assertNotNull(username, "ECO username not found in configuration.json for key: " + user.name());
        assertNotNull(password, "ECO password not found in configuration.json for key: " + user.name());

        // Store credentials for Basic Auth header generation
        Context.ecoBasicAuthUser = username;
        Context.ecoBasicAuthPass = password;

        LOG.info("ECO Basic Auth configured for {} ({})", username, user.name());
    }


    @ParameterType(".*")
    public UserCredentialsEco ecoUserCredentials(String str) {
        return UserCredentialsEco.valueOf(str.toUpperCase());
    }

    /**
     * Shared ECO login logic.
     * 1. Sets ECO Basic Auth credentials from configuration.json.
     * 2. Fetches enoc_session from Atlas SSO using the proven Settlement ADMIN credentials.
     */
    @Given("I log in as an ECO {ecoUserCredentials} and get session")
    public void iLogInAsEcoUserAndGetSession(UserCredentialsEco ecoUser) throws Exception {
        // 1. Set ECO Basic Auth credentials (Required for ALL ECO API endpoints)
        Context.ecoBasicAuthUser = ecoUser.getUsername();
        Context.ecoBasicAuthPass = ecoUser.getPassword();
        assertNotNull(Context.ecoBasicAuthUser, "ECO username not found in configuration.json!");
        assertNotNull(Context.ecoBasicAuthPass, "ECO password not found in configuration.json!");

        LOG.info("ECO Basic Auth configured for {} ({})", ecoUser.getUsername(), ecoUser.name());

        // 2. Get enoc_session using the SETTLEMENT Atlas credentials (from AWS Secrets)
        // Atlas SSO is centralized, so we use the proven Settlement ADMIN user to get the token.
        UserCredentials atlasUser = UserCredentials.ADMIN;
        assertNotNull(atlasUser.username, "Atlas user name not found in AWS secret!");
        assertNotNull(atlasUser.password, "Atlas password not found in AWS secret!");
        assertNotNull(atlasUser.realm, "Atlas realm not found in AWS secret!");

        String propKey = String.format("ATLAS_SESSION_%s_%s", Context.targetEnv, atlasUser.username);
        File tokenFile = new File(propKey);

        if (tokenFile.exists() && (System.currentTimeMillis() - tokenFile.lastModified() < Duration.ofHours(8).toMillis())) {
            Context.enocSession = new String(Files.readAllBytes(tokenFile.toPath()));
            LOG.info("Re-using Atlas session for {}", atlasUser.username);
        } else {
            var traceid = UUID.randomUUID();
            LOG.info("Atlas Login x-enelx-trace-id: " + traceid);
            Map<String, String> userMap = Map.of("username", atlasUser.username, "password", atlasUser.password, "realm", atlasUser.realm);

            String response = given().header("x-enelx-trace-id", traceid).contentType(ContentType.JSON).body(userMap)
                    .when().post(Context.targetLoginUrl).then().log().ifValidationFails().assertThat().statusCode(200)
                    .extract().asString();

            Context.enocSession = JsonPath.from(response).getString("data.enoc_session");
            Files.writeString(tokenFile.toPath(), Context.enocSession);
            LOG.info("Atlas Login successful for {}, session acquired for ECO usage.", atlasUser.username);
        }
    }

    // ──────────────────────────────────────────────
    // Auth failure steps (login/password based)
    // ──────────────────────────────────────────────

    @Given("I do not include ECO credentials")
    public void iDoNotIncludeEcoCredentials() {
        context.includeEnocSession = false;
        context.includeApiKey = false;
        LOG.info("No authentication headers will be sent on the next ECO API call");
    }

    @Given("I include invalid ECO credentials")
    public void iIncludeInvalidEcoCredentials() {
        // ECO uses Basic Auth, not enoc_session tokens
        Context.ecoBasicAuthUser = "invalid-user";
        Context.ecoBasicAuthPass = "invalid-password";
        context.includeEnocSession = true;
        LOG.info("Invalid ECO Basic Auth credentials will be sent on the next API call");
    }

    @Given("I include ECO credentials with username only")
    public void iIncludeEcoCredentialsWithUsernameOnly() {
        String username = UserCredentialsEco.ECO_ADMIN.getUsername();
        Context.ecoBasicAuthUser = username;
        Context.ecoBasicAuthPass = "";
        context.includeEnocSession = true;
        LOG.info("ECO credentials will be sent with username '{}' and empty password", username);
    }

    @Given("I include ECO credentials with password only")
    public void iIncludeEcoCredentialsWithPasswordOnly() {
        String password = UserCredentialsEco.ECO_ADMIN.getPassword();
        Context.ecoBasicAuthUser = "";
        Context.ecoBasicAuthPass = password;
        context.includeEnocSession = true;
        LOG.info("ECO credentials will be sent with password '{}' and empty username", password);
    }


    // ──────────────────────────────────────────────
    // GET /api/v1/adhoc-financial/levels
    // ──────────────────────────────────────────────

    @When("I GET all adhoc financial levels")
    public void iGetAllAdhocFinancialLevels() {
        request = RequestContainer.build()
                .getWithEcoUrl(GET_ADHOC_FINANCIAL_API_LEVELS, "");
        request.call(context.popExpectedStatus(200));
    }

    @Then("the adhoc financial levels list should be returned")
    public void adhocFinancialLevelsListShouldBeReturned() {
        List<HashMap<String, Object>> list = request.getDataAsList();
        assertNotNull(list, "Adhoc financial levels response is null!");
        assertFalse(list.isEmpty(), "No adhoc financial levels returned!");

        ObjectMapper mapper = new ObjectMapper();
        for (HashMap<String, Object> raw : list) {
            EcoAdhocFinancialLevel level = mapper.convertValue(raw, EcoAdhocFinancialLevel.class);
            validateAdhocFinancialLevel(level);
        }

        LOG.info("All {} adhoc financial levels validated successfully", list.size());
    }

    /**
     * Validates that an EcoAdhocFinancialLevel has all required fields
     * present, non-null, and of the correct type.
     */
    private void validateAdhocFinancialLevel(EcoAdhocFinancialLevel level) {
        assertNotNull(level, "Level object is null!");

        // id — must be a valid UUID string
        assertNotNull(level.id, "level.id is null!");
        assertFalse(level.id.isBlank(), "level.id is empty!");
        assertDoesNotThrow(() -> java.util.UUID.fromString(level.id),
                "level.id is not a valid UUID: " + level.id);

        // level_type — must be a known enum value
        assertNotNull(level.level_type, "level.level_type is null!");
        assertTrue(
                level.level_type.equals("PROGRAM") || level.level_type.equals("PRODUCT"),
                "level.level_type has unexpected value: " + level.level_type);

        // level_field_name — must be non-empty
        assertNotNull(level.level_field_name, "level.level_field_name is null!");
        assertFalse(level.level_field_name.isBlank(), "level.level_field_name is empty!");

        // display_name — must be non-empty
        assertNotNull(level.display_name, "level.display_name is null!");
        assertFalse(level.display_name.isBlank(), "level.display_name is empty!");

        // last_updated_by — must be non-empty
        assertNotNull(level.last_updated_by, "level.last_updated_by is null!");
        assertFalse(level.last_updated_by.isBlank(), "level.last_updated_by is empty!");

        // last_updated_dttm_utc — must be a valid ISO-8601 datetime
        assertNotNull(level.last_updated_dttm_utc, "level.last_updated_dttm_utc is null!");
        assertDoesNotThrow(() -> java.time.ZonedDateTime.parse(level.last_updated_dttm_utc),
                "level.last_updated_dttm_utc is not valid ISO-8601: " + level.last_updated_dttm_utc);
    }


    // ──────────────────────────────────────────────
    // GET /api/v1/adhoc-financial/levels/{level_uuid}/fields
    // ──────────────────────────────────────────────

    @Given("I set the context level UUID to a valid flex level UUID")
    public void iSetContextLevelUuidToValid() {
        // Reuse the response from the previous "I GET all adhoc financial levels" step
        assertNotNull(context.lastRequest, "No previous request found! Call 'I GET all adhoc financial levels' first.");
        List<HashMap<String, Object>> levels = context.lastRequest.getDataAsList();
        assertFalse(levels.isEmpty(), "No flex levels available to use as test data!");

        this.lastLevelUuid = String.valueOf(levels.get(0).get("id"));
        LOG.info("Using valid level UUID from previous response: {}", lastLevelUuid);
    }

    @Given("I set the context level UUID to {string}")
    public void iSetContextLevelUuid(String uuid) {
        this.lastLevelUuid = uuid;
    }

    @When("I GET the fields for the current level")
    public void iGetFieldsForCurrentLevel() {
        assertNotNull(lastLevelUuid, "No level UUID set! Use 'I set the context level UUID to' first.");
        String pathSuffix = String.format("%s/fields", lastLevelUuid);

        request = RequestContainer.build()
                .getWithEcoUrl(GET_ADHOC_FINANCIAL_API_LEVELS, pathSuffix);
        request.call(context.popExpectedStatus(200));
    }

    @Then("the level fields response should be returned")
    public void levelFieldsResponseShouldBeReturned() {
        List<HashMap<String, Object>> list = request.getDataAsList();
        assertNotNull(list, "Level fields response is null!");
        assertFalse(list.isEmpty(), "No level fields returned!");

        ObjectMapper mapper = new ObjectMapper();
        for (HashMap<String, Object> raw : list) {
            EcoAdhocFinancialField field = mapper.convertValue(raw, EcoAdhocFinancialField.class);
            validateAdhocFinancialField(field);
        }

        LOG.info("All {} level fields validated successfully", list.size());
    }

    /**
     * Validates that an EcoAdhocFinancialField has all required fields
     * present, non-null, and of the correct type/format.
     */
    private void validateAdhocFinancialField(EcoAdhocFinancialField field) {
        assertNotNull(field, "Field object is null!");

        // id — must be a positive integer
        assertNotNull(field.id, "field.id is null!");
        assertTrue(field.id > 0, "field.id must be positive, got: " + field.id);

        // name — must be non-blank
        assertNotNull(field.name, "field.name is null!");
        assertFalse(field.name.isBlank(), "field.name is empty!");

        // type — must be a known field type
        assertNotNull(field.type, "field.type is null!");
        assertTrue(
                field.type.equals("TEXT") || field.type.equals("NUMERIC"),
                "field.type has unexpected value: " + field.type);

        // last_updated_by — must be non-blank
        assertNotNull(field.last_updated_by, "field.last_updated_by is null!");
        assertFalse(field.last_updated_by.isBlank(), "field.last_updated_by is empty!");

        // last_updated_dttm_utc — must be valid ISO-8601 datetime
        assertNotNull(field.last_updated_dttm_utc, "field.last_updated_dttm_utc is null!");
        assertDoesNotThrow(() -> java.time.ZonedDateTime.parse(field.last_updated_dttm_utc),
                "field.last_updated_dttm_utc is not valid ISO-8601: " + field.last_updated_dttm_utc);
    }

}