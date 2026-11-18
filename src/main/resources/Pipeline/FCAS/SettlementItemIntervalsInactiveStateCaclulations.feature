Feature: Feature ECO: ancillary calcs should output $0 for revenue and payment if settlement item inactive=true

  <JIRA_URL>/browse/ITAPPSIT-4157

  In order to test this make sure:
  You have product id eb073537-0e40-4178-aaca-bea9fae106cf inside registration table
  You have a set of rows for the testing period in our case August 2026 at registration_history table with gaps for estimated payment_value_estimated and revenue_value_estimated checks
  Also for checking FINAL mode we should cover mode ESTIMATED for June and September before actually running FINAL mode for July/August/September quarter
  {
  "product_ids":["eb073537-0e40-4178-aaca-bea9fae106cf"],
  "mode": "FINAL",
  "start_date": "2026-07-01",
  "end_date": "2026-09-30"
  }
  ecrm_account_id and ecrm_site_id and ecrm_opportunity_id are related and inserted inside registration_history table for the month we are testing
  ecrm data can be grabbed either from ECO db or through UI
  <ECO_URL>/transaction/sites/60064 - for example siteId
  <ECO_URL>/transaction/accounts/47539 - account_id
  opportunity_id can be found based on this inside ecrm_opportunity table inside ECO db
  we set pricing inside  settlement_metadata."financial_point_mapping" table with market price and actual received price
  we insert inside ids.readings table - for both price types - intervals for the whole month with 5 min interval in our case August
  do not forget to check splunk logs here
  <SPLUNK_URL>
  or here
  <SPLUNK_URL>
  with a query like
  index="stm_preprd" "0beb00a7-97af-4af2-957c-1a2223fa20d7" (level=error OR level=warn)
  where index - env
  "uuid" - pipeline run id
  (level=error OR level=warn) - check only errors

  Background:
    Given I start with an empty context
    And I log in as a settlement API prdadmin
    And I set the settlement time zone to "Australia/Brisbane"
    And I set the Energy Markets program to FCAS


  # Create a settlement to run FINAL mode later
  # Remember that in order to check final mode - for any quarter/period we check - we need to create 3 months of settlement
  # so run mode: estimated for 3 months
  Scenario: Preprd: Create a settlement for July 2026 for FCAS Raise 5 Min
    Given I want to do a scheduled settlement for product: FCASRaise5Min type: ANCILLARY as of: "2026-08-01T00:00:00Z"
    Given I generate the expected scheduled settlements
    Then I verify that non-deleted settlements exist for product_id "eb073537-0e40-4178-aaca-bea9fae106cf"
    When I set inputs_available_until_dttm_utc to null for all non-deleted settlements with product_id "eb073537-0e40-4178-aaca-bea9fae106cf"
    And I delete any pre-existing expected settlements from the database
    When I POST a run-settlement-pipeline request with body
      | product_ids | eb073537-0e40-4178-aaca-bea9fae106cf |
      | mode        | ESTIMATED                            |
      | start_date  | 2026-07-01                           |
      | end_date    | 2026-07-31                           |
    Then the run-settlement-pipeline response status should be 200
    Then I save the pipeline_run_id from the response
    When I retrieve all of the pipeline history rows for the last run
    Then the pipeline history mode should be "ESTIMATED"
    Then I retrieve all pipeline history rows for the current pipeline_run_id up to pipeline_step: CREATOR_FIRST status: SUCCESS

  # Create a settlement to run FINAL mode later and check payment_value and revenue_value for inactive settlement items
  Scenario: Preprd: Create a settlement and items for August 2026 for FCAS Raise 5 Min - check gappy data intervals has 0 as payment_value_estimated and revenue_value_estimated

    Given this scenario is only supported for the preprd environment

    Given I want to do a scheduled settlement for product: FCASRaise5Min type: ANCILLARY as of: "2026-09-01T00:00:00Z"
    And I log all the registration history rows for that product
    And I generate the expected scheduled settlement
    And I generate the expected settlement items for the saved scheduled settlement
    Then I verify that non-deleted settlements exist for product_id "eb073537-0e40-4178-aaca-bea9fae106cf"
    When I set inputs_available_until_dttm_utc to null for all non-deleted settlements with product_id "eb073537-0e40-4178-aaca-bea9fae106cf"
    And I delete any pre-existing expected settlements from the database
    And I verify that the expected settlement covers the PREVIOUS_1_FULL_MONTH
    When I invoke the settlement creator lambda
    When I retrieve all of the pipeline history rows for the last run
    Then the pipeline history mode should be "ESTIMATED"
    Then the expected settlements should be created and no others should be created
    When I retrieve all of the pipeline history rows for our saved settlement up to pipeline_step: ECO status: REQUESTED
    Given I retrieve the existing matching settlement from the database
    Given I query settlement_items for the saved settlement and identify inactive items
    Then all estimated intervals for inactive settlement items should have zero payment_value_estimated and revenue_value_estimated values
    Given I query settlement_items for the saved settlement and identify active items
    Then all estimated intervals for active settlement items should have non-zero payment_value_estimated and revenue_value_estimated values

  # Create a settlement to run FINAL mode and check payment_value and revenue_value for inactive settlement items
  Scenario: Preprd: Create a settlement for September 2026 for FCAS Raise 5 Min
    Given I want to do a scheduled settlement for product: FCASRaise5Min type: ANCILLARY as of: "2026-10-01T00:00:00Z"
    Given I generate the expected scheduled settlements
    Then I verify that non-deleted settlements exist for product_id "eb073537-0e40-4178-aaca-bea9fae106cf"
    When I set inputs_available_until_dttm_utc to null for all non-deleted settlements with product_id "eb073537-0e40-4178-aaca-bea9fae106cf"
    And I delete any pre-existing expected settlements from the database
    When I POST a run-settlement-pipeline request with body
      | product_ids | eb073537-0e40-4178-aaca-bea9fae106cf |
      | mode        | ESTIMATED                            |
      | start_date  | 2026-09-01                           |
      | end_date    | 2026-09-30                           |
    Then the run-settlement-pipeline response status should be 200
    Then I save the pipeline_run_id from the response
    When I retrieve all of the pipeline history rows for the last run
    Then the pipeline history mode should be "ESTIMATED"
    Then I retrieve all pipeline history rows for the current pipeline_run_id up to pipeline_step: CREATOR_FIRST status: SUCCESS


    # Run settlement pipeline in a FINAL mode and check payment_value and revenue_value for inactive settlement items
  Scenario: Preprd: Create a settelement for September 2026 for FCAS Raise 5 Min
    Given I want to do a scheduled settlement for product: FCASRaise5Min type: ANCILLARY as of: "2026-09-01T00:00:00Z"
    Given I generate the expected scheduled settlements
    When I POST a run-settlement-pipeline request with body
      | product_ids | eb073537-0e40-4178-aaca-bea9fae106cf |
      | mode        | FINAL                            |
      | start_date  | 2026-07-01                           |
      | end_date    | 2026-09-30                           |
    Then the run-settlement-pipeline response status should be 200
    Then I save the pipeline_run_id from the response
    When I retrieve all of the pipeline history rows for the last run
    Then the pipeline history mode should be "FINAL"
    Then I retrieve all pipeline history rows for the current pipeline_run_id up to pipeline_step: CREATOR_FIRST status: SUCCESS
    Given I retrieve the existing matching settlement from the database
    Given I query settlement_items for the saved settlement and identify inactive items
    Then all intervals for inactive settlement items should have zero payment, revenue, and estimated values
