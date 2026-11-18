Feature: Feature test for the FCAS support stories

  FCAS epics:
  ITAPPSIT-3719: Retrieve inputs for FCAS Monthly estimates
  ITAPPSIT-3796: FCAS Settlement Foundations - Part 2
  ITAPPSIT-3702: Configure the FCAS payment calculation logic in ECO
  ITAPPSIT-3861: Update ECO to also do final FCAS calcs, taking overrides into account if present
  <CONFLUENCE_URL>/spaces/XP/pages/903460891/FCAS+Settlement+Pipeline+Implementation+Overview
  <CONFLUENCE_URL>/spaces/XP/pages/844210121/FCAS+Armed+Status


  Background:
    Given I start with an empty context
    And I log in as a settlement API prdadmin
    And I set the settlement time zone to "Australia/Brisbane"
    And I set the Energy Markets program to FCAS


  Scenario: Preprd: Re-create settlement and items for Jan 2025 for FCAS Raise 1 Sec - Test REG

    Given this scenario is only supported for the preprd environment

    Given I want to do a scheduled settlement for product: FCASRaise1Sec type: ANCILLARY as of: "2025-02-01T00:00:00Z"
    And I log all the registration history rows for that product
    And I generate the expected scheduled settlement
    And I generate the expected settlement items for the saved scheduled settlement
    Then I verify that non-deleted settlements exist for product_id "1ef635c7-65b2-4945-bdcb-aa2606956cfd"
    When I set inputs_available_until_dttm_utc to null for all non-deleted settlements with product_id "1ef635c7-65b2-4945-bdcb-aa2606956cfd"
    And I delete any pre-existing expected settlements from the database
    And I verify that the expected settlement covers the PREVIOUS_1_FULL_MONTH
    When I invoke the settlement creator lambda
    When I retrieve all of the pipeline history rows for the last run
    Then the pipeline history mode should be "ESTIMATED"
    Then the expected settlements should be created and no others should be created
    When I retrieve all of the pipeline history rows for our saved settlement up to pipeline_step: ECO status: REQUESTED
    Then the expected settlement items should have been created

    Given I set up an E2E test using the following parameters for the settlement that was just run:
      | month | January |
      | year  | 2025    |
      |granularity_seconds                 |       300                               |
    When I get cleared offers from MOM
    Then the latest FCAS intervals should match the expected intervals for each settlement item
    And I get the financial points for the settlement
    And I get the market_price prices
    And I calculate the expected monthly ECO payments for the settlement
    Then the ECO payments should equal the expected payments
    And the ECO transaction rows should be updated

  Scenario: Preprd: Re-run existing settlement and items for January 2025 for FCAS Raise 1 Sec - Test REG

    Given this scenario is only supported for the preprd environment

    Given I want to do a scheduled settlement for product: FCASRaise1Sec type: ANCILLARY as of: "2025-02-01T00:00:00Z"

    And I log all the registration history rows for that product
    And I generate the expected scheduled settlement
    And I generate the expected settlement items for the saved scheduled settlement
    And I verify that the expected settlement covers the PREVIOUS_1_FULL_MONTH
    When I invoke the settlement creator lambda
    When I retrieve all of the pipeline history rows for the last run
    Then the pipeline history mode should be "ESTIMATED"
    And I wait until 1 settlements have been processed by the pipeline
    Then no settlements should have been created

    Given I set up an E2E test using the following parameters for the settlement that was just run:
      | month | January |
      | year  | 2025    |
      |granularity_seconds                 |       300                               |
    When I get cleared offers from MOM
    Then the latest FCAS intervals should match the expected intervals for each settlement item
    And I get the financial points for the settlement
    And I get the market_price prices
    And I calculate the expected monthly ECO payments for the settlement
    Then the ECO payments should equal the expected payments
    And the ECO transaction rows should be updated

  Scenario: Preprd: verification without running lamba job

    Given this scenario is only supported for the preprd environment

    Given I want to do a scheduled settlement for product: FCASRaise1Sec type: ANCILLARY as of: "2025-02-01T00:00:00Z"
    And I log all the registration history rows for that product
    And I generate the expected scheduled settlement
    And I generate the expected settlement items for the saved scheduled settlement
    And I retrieve the existing matching settlement from the database

    Given I set up an E2E test using the following parameters for the settlement that was just retrieved:
      | month           | January                                  |
      | year            | 2025                                 |
      |granularity_seconds                 |       300                               |
    When I get cleared offers from MOM
    Then the latest FCAS intervals should match the expected intervals for each settlement item
    And I get the financial points for the settlement
    And I get the market_price prices
    And I calculate the expected monthly ECO payments for the settlement
    Then the ECO payments should equal the expected payments


  Scenario: Preprd: Re-create settlements and items for Q1 2025 for FCAS Raise 1 Sec rule for February and March

    #Run below 2 scenarios if we need data to run previous_full_quarter - January/Febryary/March

    #February
    Given I want to do a scheduled settlement for product: FCASRaise1Sec type: ANCILLARY as of: "2025-03-01T00:00:00Z"
    And I log all the registration history rows for that product
    And I generate the expected scheduled settlement
    And I generate the expected settlement items for the saved scheduled settlement
    Then I verify that non-deleted settlements exist for product_id "1ef635c7-65b2-4945-bdcb-aa2606956cfd"
    When I set inputs_available_until_dttm_utc to null for all non-deleted settlements with product_id "1ef635c7-65b2-4945-bdcb-aa2606956cfd"
    And I delete any pre-existing expected settlements from the database
    And I verify that the expected settlement covers the PREVIOUS_1_FULL_MONTH
    When I invoke the settlement creator lambda
    When I retrieve all of the pipeline history rows for the last run
    Then the pipeline history mode should be "ESTIMATED"
    Then the expected settlements should be created and no others should be created
    When I retrieve all of the pipeline history rows for our saved settlement up to pipeline_step: ECO status: REQUESTED
    And I set up an E2E test using the following parameters for the settlement that was just run:
      | month | February |
      | year  | 2025    |
      | granularity_seconds | 300 |
    And I get cleared offers from MOM
    And I get the financial points for the settlement
    And I get the market_price prices
    And I calculate the expected monthly ECO payments for the settlement
    Then the ECO payments should equal the expected payments
    And the ECO transaction rows should be updated

    #March
    Given I want to do a scheduled settlement for product: FCASRaise1Sec type: ANCILLARY as of: "2025-04-01T00:00:00Z"
    And I log all the registration history rows for that product
    And I generate the expected scheduled settlement
    And I generate the expected settlement items for the saved scheduled settlement
    Then I verify that non-deleted settlements exist for product_id "1ef635c7-65b2-4945-bdcb-aa2606956cfd"
    When I set inputs_available_until_dttm_utc to null for all non-deleted settlements with product_id "1ef635c7-65b2-4945-bdcb-aa2606956cfd"
    And I delete any pre-existing expected settlements from the database
    And I verify that the expected settlement covers the PREVIOUS_1_FULL_MONTH
    When I invoke the settlement creator lambda
    When I retrieve all of the pipeline history rows for the last run
    Then the pipeline history mode should be "ESTIMATED"
    Then the expected settlements should be created and no others should be created
    When I retrieve all of the pipeline history rows for our saved settlement up to pipeline_step: ECO status: REQUESTED
    And I set up an E2E test using the following parameters for the settlement that was just run:
      | month | March |
      | year  | 2025    |
      | granularity_seconds | 300 |
    And I get cleared offers from MOM
    And I get the financial points for the settlement
    And I get the market_price prices
    And I calculate the expected monthly ECO payments for the settlement
    Then the ECO payments should equal the expected payments
    And the ECO transaction rows should be updated


  Scenario: Preprd: Quarterly recalc-only for March 2025 FCAS Raise 1 Sec

  # Precondition: Jan, Feb, March PREVIOUS_1_FULL_MONTH scenarios has already ran
  # the January, February, March 2025 settlements and intervals in the DB.

    Given this scenario is only supported for the preprd environment

  # 1) Rebuild expected items for March from the monthly rule
    And I want to do a scheduled settlement for product: FCASRaise1Sec type: ANCILLARY as of: "2025-04-01T00:00:00Z"
    And I generate the expected scheduled settlement
    And I generate the expected settlement items for the saved scheduled settlement

  # 2) Trigger the quarterly job in FINAL mode (recalcOnly = true)
    Given I want to do a scheduled settlement for product: FCASRaise1Sec type: ANCILLARY as of: "2025-05-10T00:00:00Z"
    And I generate the expected scheduled settlements
    And I generate the expected settlement items for the saved scheduled settlements
    And I invoke the settlement creator lambda

  # ECO must have run for the existing March settlement, but no new settlements created
    And I wait until 3 settlements have been processed by the pipeline
    Then no settlements should have been created

  # 3) Now run the March E2E recalc using the existing March settlement
    Given I set up a recalc-only E2E test for March 2025
    And I get cleared offers from MOM
    And I get the financial points for the settlement
    And I get the actual_received_price prices
    And I calculate the expected monthly ECO payments for the settlement
    Then the settlement and items should not be updated
    But all the settlement item intervals should be updated
    And the ECO payments should equal the expected final payments

  Scenario: FCAS payment_value_override overrides computed payment
    Given this scenario is only supported for the preprd environment

  # 0) Ensure March settlement already exists (from a previous monthly run)
    And I want to do a scheduled settlement for product: FCASRaise1Sec type: ANCILLARY as of: "2025-04-01T00:00:00Z"
    And I generate the expected scheduled settlement
    And I generate the expected settlement items for the saved scheduled settlement
    Then I verify that non-deleted settlements exist for product_id "1ef635c7-65b2-4945-bdcb-aa2606956cfd"
    When I set inputs_available_until_dttm_utc to null for all non-deleted settlements with product_id "1ef635c7-65b2-4945-bdcb-aa2606956cfd"
    And I delete any pre-existing expected settlements from the database
    And I verify that the expected settlement covers the PREVIOUS_1_FULL_MONTH

    And I invoke the settlement creator lambda
    And I wait until 1 settlements have been processed by the pipeline

  # 1) Set overrides on existing March SII BEFORE quarterly recalc
    Given I set up a recalc-only E2E test for March 2025
    And I get cleared offers from MOM
    And I get the financial points for the settlement
    And I get the market_price prices
    And I choose a registration item with MOM availability and a portfolio parent
    And I set a fixed payment_value override of 100.000 for the first 12 existing intervals of that registration

  # 2) Now trigger the quarterly job in FINAL mode (recalcOnly = true)
    Given I want to do a scheduled settlement for product: FCASRaise1Sec type: ANCILLARY as of: "2025-05-10T00:00:00Z"
    And I generate the expected scheduled settlements
    And I generate the expected settlement items for the saved scheduled settlements
    And I invoke the settlement creator lambda
    Then no settlements should have been created

  # 3) Verify recalculated payments using test-side ECO
    And I choose a registration item with MOM availability and a portfolio parent
    Then the payment for the first 12 existing intervals should be 100
    And I get the actual_received_price prices
    And I calculate the expected monthly ECO payments for the settlement
    And the ECO payments should equal the expected final payments
    And the ECO transaction rows should be updated
    And all the settlement item intervals should be updated

  Scenario: FCAS realtime_availability_kw_override affects revenue
    Given this scenario is only supported for the preprd environment

  # 0) Ensure March settlement already exists (from a previous monthly run)
    And I want to do a scheduled settlement for product: FCASRaise1Sec type: ANCILLARY as of: "2025-04-01T00:00:00Z"
    And I generate the expected scheduled settlement
    And I generate the expected settlement items for the saved scheduled settlement
    Then I verify that non-deleted settlements exist for product_id "1ef635c7-65b2-4945-bdcb-aa2606956cfd"
    When I set inputs_available_until_dttm_utc to null for all non-deleted settlements with product_id "1ef635c7-65b2-4945-bdcb-aa2606956cfd"
    And I delete any pre-existing expected settlements from the database
    And I verify that the expected settlement covers the PREVIOUS_1_FULL_MONTH
    And I invoke the settlement creator lambda
    And I wait until 1 settlements have been processed by the pipeline

  # 1) Set realtime_availability overrides BEFORE quarterly recalc
    Given I set up a recalc-only E2E test for March 2025
    And I get cleared offers from MOM
    And I get the financial points for the settlement
    And I get the market_price prices
    And I choose a registration item with MOM availability and a portfolio parent
    And I set a fixed realtime_availability_kw override of 0.000000 for the first 12 existing intervals of that registration

  # 2) Trigger quarterly job in FINAL mode (recalcOnly = true)
    Given I want to do a scheduled settlement for product: FCASRaise1Sec type: ANCILLARY as of: "2025-05-10T00:00:00Z"
    And I generate the expected scheduled settlements
    And I generate the expected settlement items for the saved scheduled settlements
    And I invoke the settlement creator lambda
    Then no settlements should have been created

  # 3) Verify recalculated payments in DB
    And I choose a registration item with MOM availability and a portfolio parent
    Then the payment_value for the first 12 existing intervals should be 0.0000
    And all the settlement item intervals should be updated

  Scenario: FCAS payment_value_override takes precedence over realtime_availability_kw_override
    Given this scenario is only supported for the preprd environment

  # 0) Ensure March settlement already exists (from a previous monthly run)
    And I want to do a scheduled settlement for product: FCASRaise1Sec type: ANCILLARY as of: "2025-04-01T00:00:00Z"
    And I generate the expected scheduled settlement
    And I generate the expected settlement items for the saved scheduled settlement
    Then I verify that non-deleted settlements exist for product_id "1ef635c7-65b2-4945-bdcb-aa2606956cfd"
    When I set inputs_available_until_dttm_utc to null for all non-deleted settlements with product_id "1ef635c7-65b2-4945-bdcb-aa2606956cfd"
    And I delete any pre-existing expected settlements from the database
    And I verify that the expected settlement covers the PREVIOUS_1_FULL_MONTH
    And I invoke the settlement creator lambda
    And I wait until 1 settlements have been processed by the pipeline

  # 1) Set BOTH overrides on existing March SII BEFORE quarterly recalc
    Given I set up a recalc-only E2E test for March 2025
    And I get cleared offers from MOM
    And I get the financial points for the settlement
    And I get the actual_received_price prices
    And I choose a registration item with MOM availability and a portfolio parent
    And I set a fixed payment_value override of 100.000 for the first 12 existing intervals of that registration
    And I set a fixed realtime_availability_kw override of 500.000 for the first 12 existing intervals of that registration

  # 2) Trigger the quarterly job in FINAL mode (recalcOnly = true)
    Given I want to do a scheduled settlement for product: FCASRaise1Sec type: ANCILLARY as of: "2025-05-10T00:00:00Z"
    And I generate the expected scheduled settlements
    And I generate the expected settlement items for the saved scheduled settlements
    And I invoke the settlement creator lambda
    Then no settlements should have been created

  # 3) Verify recalculated payments using test-side ECO
    And I choose a registration item with MOM availability and a portfolio parent
    Then the payment for the first 12 existing intervals should be 100.0000
    And all the settlement item intervals should be updated

  # this is a test for non-armed status
  Scenario: FCAS realtime_availability_kw_override overrides is_armed=false for Portfolio Aggregation and ECO
    Given this scenario is only supported for the preprd environment

  # Register the existing January, February, March settlements into context.savedSettlements
  # (You need to create them prior from the steps above; we are only reading them here).
    Given I want to do a scheduled settlement for product: FCASRaise1Sec type: ANCILLARY as of: "2025-02-01T00:00:00Z"
    And I generate the expected scheduled settlement
    And I retrieve the existing matching settlement from the database

    Given I want to do a scheduled settlement for product: FCASRaise1Sec type: ANCILLARY as of: "2025-03-01T00:00:00Z"
    And I generate the expected scheduled settlement
    And I retrieve the existing matching settlement from the database

    Given I want to do a scheduled settlement for product: FCASRaise1Sec type: ANCILLARY as of: "2025-04-01T00:00:00Z"
    And I generate the expected scheduled settlement
    And I retrieve the existing matching settlement from the database

    Given I set up a recalc-only E2E test for March 2025
    And I get cleared offers from MOM
    And I get the financial points for the settlement
    And I get the actual_received_price prices

  # Select and set the override BEFORE triggering the quarterly FINAL job.
    And I choose a registration item with MOM availability and a portfolio parent
    And I set a fixed realtime_availability_kw override of 12 for all armed intervals of that registration

  # Trigger quarterly FINAL run.
    Given I want to do a scheduled settlement for product: FCASRaise1Sec type: ANCILLARY as of: "2025-05-10T00:00:00Z"
    And I generate the expected scheduled settlements
    And I generate the expected settlement items for the saved scheduled settlements
    When I invoke the settlement creator lambda


  # Wait for FINAL processing instead of merely proving no rows were created.
    And I expect 3 quarterly settlements - the same pipeline_run_id - have been processed by the pipeline
    Then no settlements should have been created

  # Rebuild test context only after ECO has completed.
    Given I set up a recalc-only E2E test for March 2025
    And I get cleared offers from MOM
    And I get the financial points for the settlement
    And I get the actual_received_price prices
    And I calculate the expected monthly ECO payments for the settlement
    Then all the settlement item intervals should be updated
    And the ECO payments should equal the expected final payments
    And the ECO transaction rows should be updated

    # to check for armed period use this sql query on EPS pre-prod db
  #  INSERT INTO event_node_workflow (
  #  event_node_id,
  #  event_id,
  #  workflow_status,
  #  initial_notif_included,
  #  follow_up_notif_included,
  #  curtail_included,
  #  restore_notif_included,
  #  restore_included,
  #  event_node_start_time,
  #  event_node_end_time,
  #  curtail_complete,
  #  curtail_exception_resolved,
  #  cancelled,
  #  registration_id,
  #  registration_set_id,
  #  product_id,
  #  registration_type,
  #  control_type,
  #  expected_capacity,
  #  expected_capacity_uom,
  #  workflow_id,
  #  created_dttm,
  #  last_updated_dttm
  #  ) VALUES (
  #  'test-node-' || to_char(clock_timestamp(), 'YYYYMMDDHH24MISSMS'),   -- event_node_id (unique text)
  #  'test-event-' || to_char(clock_timestamp(), 'YYYYMMDDHH24MISSMS'),  -- event_id (unique text)
  #  'WORKFLOW_COMPLETE',
  #  false,
  #  false,
  #  true,
  #  false,
  #  true,
  #  '2025-02-28 14:00:00.000',
  #  '2025-03-01 00:00:00.000',
  #  '2025-02-28 14:05:00.000',
  #  NULL,
  #  '2025-03-01 00:00:00.000',
  #  '61eacbe0-d853-4fd1-a50c-e32375475a70',
  #  '19d667cc-9c8b-466d-88b4-478604714380',
  #  '1ef635c7-65b2-4945-bdcb-aa2606956cfd',
  #  'LOAD',
  #  'MANUAL',
  #  500,
  #  'kW',
  #  5,
  #  now(),
  #  now()
  #  );