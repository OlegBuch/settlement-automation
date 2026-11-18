Feature: ITAPPSIT-3886 Update settlement creator to query EPS for armed status by registration_set_id


  Description:
  Update CreateItemsService to populate settlement item.registration_set_id from registration history.
  This ensures that products like Raise 1 sec (which don't have direct EPS rows) can find armed status
  via the shared registration_set_id from the 5-min product.


  Armed Status Logic (from Confluence):
  - 5-min intervals are 'armed' if they fall within an EPS armed period.
  - EPS armed periods are derived from event_node_workflow rows.
  - This fix allows 1-sec products to link to those workflow rows via registration_set_id.


  Background:
    Given I start with an empty context
    And I log in as a settlement API prdadmin
    And I set the settlement time zone to "Australia/Brisbane"
    And I set the Energy Markets program to FCAS

 # This scenario verifies the specific data the developer created in PREPRD.
  @preprd @verification
  Scenario: Preprd: Verify existing Nov 2025 settlement for FCASRaise1Sec (Armed Status Check)

  # Do not forget to delete all previous settlements before running the scenario
  # If the test failed at 129 line at lambda creator step
  # Given I DELETE settlement with the settlement_id {settlement_id}

    Given this scenario is only supported for the preprd environment

  # Define the product + as-of date
    Given I want to do a scheduled settlement for product: FCASRaise1Sec type: ANCILLARY as of: "2025-11-01T00:00:00Z"

  # Build expectations from product rules
    And I generate the expected scheduled settlements
    And I log all the registration history rows for that product

  # Clean up any old tests to ensure a fresh run
    Then I verify that non-deleted settlements exist for product_id "1ef635c7-65b2-4945-bdcb-aa2606956cfd"
    When I set inputs_available_until_dttm_utc to null for all non-deleted settlements with product_id "1ef635c7-65b2-4945-bdcb-aa2606956cfd"
    And I delete any pre-existing expected settlements from the database

  # Create the settlement via the real pipeline
    When I invoke the settlement creator lambda
    Then the expected settlements should be created and no others should be created

  # Work with the newly-created settlement
    And I retrieve the existing matching settlement from the database
    And I generate the expected settlement items for the saved scheduled settlement

  # Pipeline history + item-level verification
    When I retrieve all of the pipeline history rows for our saved settlement up to pipeline_step: DONE status: SUCCESS
    Then the expected settlement items should have been created
    And the expected armed status by registration set:
      | registration_set_id                         | expected_armed |
      | 19d667cc-9c8b-466d-88b4-478604714380         | true           |
      | 9999ecb3-56ae-4705-ad53-e6f5bcb72d22         | false          |
      | NULL                                         | false          |

    And the registration-level settlement item intervals should match the expected armed status

    # This scenario verifies the specific data the developer created in PREPRD.
  @preprd @verification
  Scenario: Preprd: Verify Nov 2025 settlement for FCAS Raise 5 Min (Armed Status Check)

    #Do not forget to delete all previous settlements before running the scenario
    #If the test failed at 129 line at lambda creator step
    #Given I DELETE settlement with the settlement_id {settlement_id}

    Given this scenario is only supported for the preprd environment

  # Define the product + as-of date
    Given I want to do a scheduled settlement for product: FCASRaise5Min type: ANCILLARY as of: "2025-11-01T00:00:00Z"

  # Build expectations from product rules
    And I generate the expected scheduled settlements
    And I log all the registration history rows for that product

  # Clean up any old tests to ensure a fresh run
    Then I verify that non-deleted settlements exist for product_id "eb073537-0e40-4178-aaca-bea9fae106cf"
    When I set inputs_available_until_dttm_utc to null for all non-deleted settlements with product_id "eb073537-0e40-4178-aaca-bea9fae106cf"
    And I delete any pre-existing expected settlements from the database

  # Create the settlement via the real pipeline
    When I invoke the settlement creator lambda
    Then the expected settlements should be created and no others should be created

  # Work with the newly-created settlement
    And I retrieve the existing matching settlement from the database
    And I generate the expected settlement items for the saved scheduled settlement

  # Pipeline history + item-level verification + armed status check
    When I retrieve all of the pipeline history rows for our saved settlement up to pipeline_step: DONE status: SUCCESS
    Then the expected settlement items should have been created
    And the expected armed status by registration set:
      | registration_set_id                         | expected_armed |
      | 19d667cc-9c8b-466d-88b4-478604714380         | true           |

    And the registration-level settlement item intervals should match the expected armed status


  # Optional full-pipeline / ECO regression
  Scenario: Run regression to make sure pipeline is not broken/ECO regression

    # Program + timezone
    Given I set the settlement time zone to "Australia/Brisbane"
    And I set the Energy Markets program to FCAS

    # Define which settlement to create
    And I want to do a scheduled settlement for product: FCASRaise5Min type: ANCILLARY as of: "2025-11-01T00:00:00Z"
    And I generate the expected scheduled settlements
    And I log all the registration history rows for that product

    # Clean + create
    And I delete any pre-existing expected settlements from the database
    When I invoke the settlement creator lambda
    Then the expected settlements should be created and no others should be created

    # Work with the new settlement
    And I retrieve the existing matching settlement from the database
    And I generate the expected settlement items for the saved scheduled settlement

    # Full-pipeline / ECO checks
    When I retrieve all of the pipeline history rows for our saved settlement up to pipeline_step: DONE status: SUCCESS
    Then the expected settlement items should have been created
    And I set up an E2E test using the following parameters for the settlement that was just retrieved:
      | month               | October |
      | year                | 2025     |
      | granularity_seconds | 300      |
    Then the latest FCAS intervals should match the expected intervals for each settlement item
    And I get the financial points for the settlement
    And I get the market_price prices
    And I calculate the expected monthly ECO payments for the settlement
    Then the ECO payments should equal the expected payments
