package com.enernoc.bdap.stepdefs;

import com.enernoc.bdap.shared.Context;
import com.enernoc.bdap.shared.PostgresClient;
import io.cucumber.java.en.Given;
import io.cucumber.java.en.Then;

import java.util.HashMap;
import java.util.List;
import java.util.Optional;

import static com.enernoc.bdap.shared.Context.metadataSecretValues;
import static org.junit.jupiter.api.Assertions.*;

public class RegistrationHistoryReconciledSteps {

    private final PostgresClient postgresClient = new PostgresClient(metadataSecretValues);
    private final Context context = Context.getContext();

    public RegistrationHistoryReconciledSteps() {
    }

    @Then("the registration history reconciliation table should contain overridden rows for registration_id {string}")
    public void registrationHistoryReconciledShouldContainOverriddenRows(String registrationIdKeyOrValue) throws Exception {
        String registrationId = Optional.ofNullable(context.savedValues.get(registrationIdKeyOrValue))
                .map(Object::toString)
                .orElse(registrationIdKeyOrValue);

        String condition = String.format(
                "registration_id = '%s' AND has_override = true",
                registrationId
        );

        List<HashMap<String, Object>> rows = postgresClient.selectRecordsTable(
                "\"REGISTRATION_HISTORY_RECONCILED\"",
                condition,
                "effective_start_dttm_utc"
        );

        assertFalse(rows.isEmpty(), String.format("Expected at least 1 reconciled row with has_override=true for registration_id %s, but found %d",
                registrationId, rows.size()));

        for (HashMap<String, Object> row : rows) {
            assertEquals(registrationId, row.get("registration_id").toString());
            assertEquals(Boolean.TRUE, row.get("has_override"));
            assertNotNull(row.get("effective_start_dttm_utc"));
            assertNotNull(row.get("effective_end_dttm_utc"));
        }
    }

    @Given("I hard delete all test registration history overrides for known effective windows")
    public void hardDeleteAllTestOverridesForKnownWindows() throws Throwable {
        String condition = """
            (effective_start_dttm_utc = TIMESTAMPTZ '2026-04-01T07:33:38.213Z'
             AND effective_end_dttm_utc   = TIMESTAMPTZ '2026-04-02T10:33:38.213Z')
          OR
            (effective_start_dttm_utc = TIMESTAMPTZ '2026-04-10T07:33:38.213Z'
             AND effective_end_dttm_utc   = TIMESTAMPTZ '2026-04-10T08:33:38.213Z')
           \s""";

        postgresClient.deleteRecordsTable("\"REGISTRATION_HISTORY_OVERRIDE\"", condition);
    }

}