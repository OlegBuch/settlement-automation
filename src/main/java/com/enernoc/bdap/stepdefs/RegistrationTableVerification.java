package com.enernoc.bdap.stepdefs;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.cucumber.java.en.Given;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import static org.junit.jupiter.api.Assertions.*;

import java.io.*;
import java.nio.charset.StandardCharsets;
import java.util.*;

public class RegistrationTableVerification {

    private static final Logger LOG = LoggerFactory.getLogger("DataComparison");

    private String registrationCsvFilePath;
    private String atlasJsonFilePath;
    private Map<String, Map<String, String>> registrationData;
    private Map<String, Map<String, Object>> atlasExtractData;
    private List<Discrepancy> discrepancies = new ArrayList<>();
    private String discrepanciesFilePath;

    private static final Map<String, String> FIELD_MAPPING = Map.ofEntries(
            Map.entry("registration_id", "registration_id"),
            Map.entry("status", "registration_status"),
            Map.entry("product_id", "product_id"),
            Map.entry("flexible_asset_id", "flexible_asset_id"),
            Map.entry("site_id", "site_id"),
            Map.entry("org_id", "organization_id")
    );

    // --- Step definitions ---

    @Given("I have a CSV file at {string}")
    public void i_download_the_registration_table_into_a_local_file(String filePath) {
        this.registrationCsvFilePath = filePath;
    }

    @Given("I have a JSON file at {string}")
    public void i_have_a_json_file_at(String filePath) {
        this.atlasJsonFilePath = filePath;
        LOG.info("JSON file path set to: {}", this.atlasJsonFilePath);
    }

    @When("I compare the data in the registration file and the JSON file")
    public void i_compare_the_data_in_the_registration_file_and_the_json_file() throws IOException {
        assertNotNull(registrationCsvFilePath, "CVS file path must be set!");
        assertNotNull(atlasJsonFilePath, "JSON file path must be set!");
        LOG.info("Starting data comparison between {} and {}", registrationCsvFilePath, atlasJsonFilePath);
        registrationData = parseCsv(registrationCsvFilePath);
        atlasExtractData = parseJson(atlasJsonFilePath);
        discrepancies = compareData(registrationData, atlasExtractData);
        LOG.info("Comparison finished. Found {} discrepancies.", discrepancies.size());
    }

    @Then("I should see no differences")
    public void i_should_see_no_differences() {
        if (discrepancies != null && !discrepancies.isEmpty()) {
            fail("Number of discrepancies found: " + discrepancies.size() + ". See discrepancies.md for details.");
        }
        LOG.info("No differences found.");
    }

    @Then("I should generate a diff file at {string}")
    public void i_should_have_a_diff_file_generated_at(String filePath) throws IOException {
        this.discrepanciesFilePath = filePath;
        LOG.info("Generating discrepancies Markdown file at: {}", this.discrepanciesFilePath);
        generateMarkdownDiffFile(discrepancies, discrepanciesFilePath);

        File diffFile = new File(discrepanciesFilePath);
        if (!diffFile.exists() || diffFile.length() == 0) {
            LOG.warn("Discrepancies file might not have been generated or is empty at: {}", this.discrepanciesFilePath);
        } else {
            LOG.info("Discrepancies Markdown file generated successfully at: {}", this.discrepanciesFilePath);
        }
    }

    // --- Helper Methods ---

    private Map<String, Map<String, String>> parseCsv(String filePath) throws IOException {
        LOG.info("Parsing CSV file: {}", filePath);
        Map<String, Map<String, String>> data = new HashMap<>();
        try (BufferedReader reader = new BufferedReader(new InputStreamReader(new FileInputStream(filePath), StandardCharsets.UTF_8))) {
            String headerLine = reader.readLine();
            if (headerLine == null) {
                LOG.warn("CSV file {} is empty.", filePath);
                return data;
            }
            String[] headers = parseCsvLine(headerLine);
            int registrationIdIndex = -1;
            for (int i = 0; i < headers.length; i++) {
                if ("registration_id".equalsIgnoreCase(headers[i].replace("\"", "").trim())) {
                    registrationIdIndex = i;
                    break;
                }
            }
            assertTrue(registrationIdIndex != -1, "registration_id column not found in CSV header");

            String line;
            while ((line = reader.readLine()) != null) {
                if (line.trim().isEmpty()) continue;
                String[] values = parseCsvLine(line);
                if (values.length <= registrationIdIndex) continue;

                String rawRegistrationId = values[registrationIdIndex].trim();
                String registrationId = removeSurroundingQuotes(rawRegistrationId);

                if (registrationId.isEmpty()) {
                    LOG.warn("Empty registration ID: " + registrationId);
                    continue;
                }

                assertFalse(data.containsKey(registrationId),
                        "More than one line in CSV file has this registration id: " + registrationId);

                Map<String, String> record = new HashMap<>();
                for (int i = 0; i < headers.length; i++) {
                    String header = headers[i].replace("\"", "").trim();
                    String value = (i < values.length) ? removeSurroundingQuotes(values[i].trim()) : "";
                    record.put(header, value);
                }
                data.put(registrationId, record);
            }
        }
        LOG.info("Finished parsing CSV file: {}. Loaded {} records.", filePath, data.size());
        return data;
    }

    private String[] parseCsvLine(String line) {
        String[] tokens = line.split(",");
        for (int i = 0; i < tokens.length; i++) {
            tokens[i] = removeSurroundingQuotes(tokens[i].trim());
        }
        return tokens;
    }

    private String removeSurroundingQuotes(String value) {
        if (value == null) return null;
        value = value.trim();
        if (value.startsWith("\"") && value.endsWith("\"") && value.length() > 1) {
            return value.substring(1, value.length() - 1);
        }
        return value;
    }

    private Map<String, Map<String, Object>> parseJson(String filePath) throws IOException {
        LOG.info("Parsing JSON file: {}", filePath);
        Map<String, Map<String, Object>> data = new HashMap<>();
        ObjectMapper mapper = new ObjectMapper();

        try (Reader reader = new InputStreamReader(new FileInputStream(filePath), StandardCharsets.UTF_8)) {
            JsonNode root = mapper.readTree(reader);

            if (root.isArray()) {
                for (JsonNode node : root) {
                    if (node.isObject()) {
                        Map<String, Object> record = mapper.convertValue(node, new TypeReference<>() {});
                        Object registrationIdObject = record.get("registration_id");
                        String registrationId = (registrationIdObject != null) ? registrationIdObject.toString() : null;
                        if (registrationId != null && !registrationId.isEmpty()) {
                            assertFalse(data.containsKey(registrationId),
                                    "More than one object in JSON file has this registration id: " + registrationId);
                            data.put(registrationId, record);
                        }
                    }
                }
            } else {
                throw new IOException("JSON file '" + filePath + "' root is not an array of objects.");
            }
        }
        LOG.info("Finished parsing JSON file: {}. Loaded {} records.", filePath, data.size());
        return data;
    }

    private List<Discrepancy> compareData(Map<String, Map<String, String>> csvData, Map<String, Map<String, Object>> jsonData) {
        LOG.info("Comparing data from CSV ({} records) and JSON ({} records).", csvData.size(), jsonData.size());
        List<Discrepancy> diffs = new ArrayList<>();

        for (Map.Entry<String, Map<String, String>> csvEntry : csvData.entrySet()) {
            String registrationId = csvEntry.getKey();
            Map<String, String> csvRecord = csvEntry.getValue();

            if (!jsonData.containsKey(registrationId)) {
                diffs.add(Discrepancy.missingInJson(registrationId));
            } else {
                Map<String, Object> jsonRecord = jsonData.get(registrationId);
                compareFieldValues(registrationId, csvRecord, jsonRecord, diffs);
            }
        }

        for (Map.Entry<String, Map<String, Object>> jsonEntry : jsonData.entrySet()) {
            String registrationId = jsonEntry.getKey();
            if (!csvData.containsKey(registrationId)) {
                diffs.add(Discrepancy.missingInCsv(registrationId));
            }
        }
        LOG.info("Comparison completed. Found {} discrepancies (including field mismatches).", diffs.size());
        return diffs;
    }

    private void compareFieldValues(String registrationId, Map<String, String> csvRecord, Map<String, Object> jsonRecord, List<Discrepancy> diffs) {
        for (Map.Entry<String, String> entry : FIELD_MAPPING.entrySet()) {
            String csvField = entry.getKey();
            String jsonField = entry.getValue();

            String csvValue = csvRecord.get(csvField);
            Object jsonValueObj = jsonRecord.get(jsonField);
            String jsonValue = (jsonValueObj == null) ? null : jsonValueObj.toString();

            if (csvValue != null && csvValue.equalsIgnoreCase("NULL")) csvValue = null;
            if (jsonValue != null && jsonValue.equalsIgnoreCase("NULL")) jsonValue = null;

            if (!Objects.equals(csvValue, jsonValue)) {
                diffs.add(Discrepancy.fieldMismatch(
                        registrationId,
                        csvField,
                        jsonField,
                        csvValue == null ? "<null>" : csvValue,
                        jsonValue == null ? "<null>" : jsonValue
                ));
            }
        }
    }

    private void generateMarkdownDiffFile(List<Discrepancy> discrepancies, String filePath) throws IOException {
        if (discrepancies == null) discrepancies = Collections.emptyList();
        try (BufferedWriter writer = new BufferedWriter(new OutputStreamWriter(new FileOutputStream(filePath), StandardCharsets.UTF_8))) {
            writer.write("# Discrepancies Report\n\n");
            if (discrepancies.isEmpty()) {
                writer.write("_No discrepancies found._\n");
                return;
            }
            for (Discrepancy diff : discrepancies) {
                writer.write(diff.asMarkdown());
                writer.write("\n---\n\n");
            }
        }
    }

    private static class Discrepancy {
        enum Type { MISSING_JSON, MISSING_CSV, FIELD_MISMATCH }
        final Type type;
        final String registrationId;
        final String csvField;
        final String jsonField;
        final String csvValue;
        final String jsonValue;

        private Discrepancy(Type type, String registrationId, String csvField, String jsonField, String csvValue, String jsonValue) {
            this.type = type;
            this.registrationId = registrationId;
            this.csvField = csvField;
            this.jsonField = jsonField;
            this.csvValue = csvValue;
            this.jsonValue = jsonValue;
        }

        static Discrepancy missingInJson(String registrationId) {
            return new Discrepancy(Type.MISSING_JSON, registrationId, null, null, null, null);
        }
        static Discrepancy missingInCsv(String registrationId) {
            return new Discrepancy(Type.MISSING_CSV, registrationId, null, null, null, null);
        }
        static Discrepancy fieldMismatch(String registrationId, String csvField, String jsonField, String csvValue, String jsonValue) {
            return new Discrepancy(Type.FIELD_MISMATCH, registrationId, csvField, jsonField, csvValue, jsonValue);
        }

        String asMarkdown() {
            StringBuilder sb = new StringBuilder();
            sb.append("### Registration ID: `").append(registrationId).append("`\n\n");
            switch (type) {
                case MISSING_JSON:
                    sb.append("> ⚠️ **Missing in JSON (Atlas Extract)**\n");
                    break;
                case MISSING_CSV:
                    sb.append("> ⚠️ **Missing in CSV (Registration Table)**\n");
                    break;
                case FIELD_MISMATCH:
                    sb.append("**Field mismatch:**\n\n");
                    sb.append("| Field (CSV) | Field (JSON) | Value in CSV | Value in JSON |\n");
                    sb.append("|-------------|--------------|--------------|---------------|\n");
                    sb.append("| `").append(csvField).append("` | `")
                            .append(jsonField).append("` | `")
                            .append(csvValue == null ? "<null>" : csvValue).append("` | `")
                            .append(jsonValue == null ? "<null>" : jsonValue).append("` |\n");
                    break;
            }
            return sb.toString();
        }

        String asPlainText() {
            switch (type) {
                case MISSING_JSON:
                    return "Missing in JSON (Atlas Extract): Registration ID = " + registrationId;
                case MISSING_CSV:
                    return "Missing in CSV (Registration Table): Registration ID = " + registrationId;
                case FIELD_MISMATCH:
                    return String.format(
                            "Value mismatch for registration_id = %s, field '%s' (CSV) vs '%s' (JSON): CSV='%s', JSON='%s'",
                            registrationId, csvField, jsonField, csvValue, jsonValue
                    );
                default:
                    return "";
            }
        }
    }
}
