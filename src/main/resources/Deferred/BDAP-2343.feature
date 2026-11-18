Feature: Validate Registrations in Settlement Metadata Match Recent Atlas Extract

  Scenario: Compare two data files with different formats and order
    Given I have a CSV file at "src/main/MetadataDB_registration_table/REGISTRATION.csv"
    And I have a JSON file at "src/main/Atlas_registration_extracts/20250513034606_registrations.json"
    When I compare the data in the registration file and the JSON file
    Then I should generate a diff file at "src/discrepancies.md"
    And I should see no differences