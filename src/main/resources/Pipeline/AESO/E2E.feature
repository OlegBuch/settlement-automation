Feature: Scenarios for AESO E2E testing on preprd

  <CONFLUENCE_URL>/display/XP/Settlement+Pipeline+MVP%3A+End+to+End+%28E2E%29+testing
  <JIRA_URL>/browse/BDAP-2179
  <JIRA_URL>/browse/ITAPPSIT-3861

  Background:
    Given this scenario is only supported for the preprd environment
    Given I start with an empty context
    * I log in as a settlement API admin
    * I set the settlement time zone to "America/Edmonton"
    * I set the Energy Markets program to AESO

  Scenario: Re-create January 2026

    Given I want to do a scheduled settlement for product: AESO type: ANCILLARY as of: "2026-02-01T00:00:00Z"
    And I generate the expected scheduled settlement
    Then I verify that non-deleted settlements exist for product_id "a1643547-425b-4856-8177-524371fa77e6"
    When I set inputs_available_until_dttm_utc to null for all non-deleted settlements with product_id "a1643547-425b-4856-8177-524371fa77e6"
    And I delete all pre-existing expected settlements from the database
    When I POST a run-settlement-pipeline request with body
      | product_ids | a1643547-425b-4856-8177-524371fa77e6 |
      | mode        | FINAL                                |
      | start_date  | 2026-01-01                           |
      | end_date    | 2026-01-31                           |
    Then the run-settlement-pipeline response status should be 200
    Then I save the pipeline_run_id from the response
    And I wait until 1 settlements have been processed by the pipeline
    And I retrieve the existing matching settlement from the database

    Given I generate the expected settlement items for the saved scheduled settlement
    When I retrieve all of the pipeline history rows for our saved settlement up to pipeline_step: DONE status: SUCCESS
    Then the expected settlement items should have been created

    Given I set up an E2E test using the following parameters for the settlement that was just run:
      | month | January |
      | year  | 2026    |
    And I get the financial points for the settlement
    And I get the pool_price prices
    And I get the daily_discount_price prices
    And I get cleared offers from MOM
    And I calculate the expected monthly ECO payments for the settlement
    Then the ECO payments should equal the expected payments
    And the ECO transaction rows should be updated
    And all the settlement item intervals should be updated


  Scenario: Re-create February 2026

    Given I want to do a scheduled settlement for product: AESO type: ANCILLARY as of: "2026-03-01T00:00:00Z"
    And I generate the expected scheduled settlement
    Then I verify that non-deleted settlements exist for product_id "a1643547-425b-4856-8177-524371fa77e6"
    When I set inputs_available_until_dttm_utc to null for all non-deleted settlements with product_id "a1643547-425b-4856-8177-524371fa77e6"
    And I delete all pre-existing expected settlements from the database
    When I POST a run-settlement-pipeline request with body
      | product_ids | a1643547-425b-4856-8177-524371fa77e6 |
      | mode        | FINAL                                |
      | start_date  | 2026-02-01                           |
      | end_date    | 2026-02-28                           |
    Then the run-settlement-pipeline response status should be 200
    Then I save the pipeline_run_id from the response
    And I wait until 1 settlements have been processed by the pipeline
    And I retrieve the existing matching settlement from the database

    Given I generate the expected settlement items for the saved scheduled settlement
    When I retrieve all of the pipeline history rows for our saved settlement up to pipeline_step: DONE status: SUCCESS
    Then the expected settlement items should have been created

    Given I set up an E2E test using the following parameters for the settlement that was just run:
      | month | February |
      | year  | 2026     |
    And I get the financial points for the settlement
    And I get the pool_price prices
    And I get the daily_discount_price prices
    And I get cleared offers from MOM
    And I calculate the expected monthly ECO payments for the settlement
    Then the ECO payments should equal the expected payments
    And the ECO transaction rows should be updated
    And all the settlement item intervals should be updated


  Scenario: Re-create March 2026

    Given I want to do a scheduled settlement for product: AESO type: ANCILLARY as of: "2026-04-01T00:00:00Z"
    And I generate the expected scheduled settlement
    Then I verify that non-deleted settlements exist for product_id "a1643547-425b-4856-8177-524371fa77e6"
    When I set inputs_available_until_dttm_utc to null for all non-deleted settlements with product_id "a1643547-425b-4856-8177-524371fa77e6"
    And I delete all pre-existing expected settlements from the database
    When I POST a run-settlement-pipeline request with body
      | product_ids | a1643547-425b-4856-8177-524371fa77e6 |
      | mode        | FINAL                                |
      | start_date  | 2026-03-01                           |
      | end_date    | 2026-03-31                           |
    Then the run-settlement-pipeline response status should be 200
    Then I save the pipeline_run_id from the response
    And I wait until 1 settlements have been processed by the pipeline
    And I retrieve the existing matching settlement from the database

    Given I generate the expected settlement items for the saved scheduled settlement
    When I retrieve all of the pipeline history rows for our saved settlement up to pipeline_step: DONE status: SUCCESS
    Then the expected settlement items should have been created

    Given I set up an E2E test using the following parameters for the settlement that was just run:
      | month | March |
      | year  | 2026  |
    And I get the financial points for the settlement
    And I get the pool_price prices
    And I get the daily_discount_price prices
    And I get cleared offers from MOM
    And I calculate the expected monthly ECO payments for the settlement
    Then the ECO payments should equal the expected payments
    And the ECO transaction rows should be updated
    And all the settlement item intervals should be updated

  Scenario: BDAP-2181: Recalculate existing settlement for past 1 month - no inputs changed
  # Verify that the settlement item intervals and ECO transaction rows are re-calculated even if the inputs do not change
  # Precondition: the March 2026 settlement already exists (run "Re-create March 2026" first)

    Given I want to do a scheduled settlement for product: AESO type: ANCILLARY as of: "2026-04-01T00:00:00Z"
    And I log all the registration history rows for that product
    And I generate the expected scheduled settlement
    And I retrieve the existing matching settlement from the database
    And I generate the expected settlement items for the saved scheduled settlement
    When I POST a run-settlement-pipeline request with body
      | product_ids | a1643547-425b-4856-8177-524371fa77e6 |
      | mode        | FINAL                                |
      | start_date  | 2026-01-01                           |
      | end_date    | 2026-03-31                           |
    Then the run-settlement-pipeline response status should be 200
    Then I save the pipeline_run_id from the response
    And I retrieve all pipeline history rows for the current pipeline_run_id up to pipeline_step: DONE status: SUCCESS
    Then no new settlements should have been created since the pipeline was triggered

    Given I set up an E2E test using the following parameters for the settlement that was just run:
      | month | March |
      | year  | 2026  |
    And I get the financial points for the settlement
    And I get the pool_price prices
    And I get the daily_discount_price prices
    And I get cleared offers from MOM
    And I calculate the expected monthly ECO payments for the settlement
    Then the settlement and items should not be updated
    But all the settlement item intervals should be updated
    And the ECO payments should equal the expected payments
    And the ECO transaction rows should be updated


  Scenario: BDAP-2182: Recalculate existing settlements for past 3 months - pricing change
  # To update prices, use the scenarios 'Load pool/discount pricing for preprd E2E testing' in 'Create_QAA_AESO_TEST_MARKET2.feature'
  # in xplatform-automation. Change the offset values in the stepdefs to get different randomization.
  # Do the following runs of this scenario:
  #   1. After updating only pool pricing for all months
  #   2. After updating only discount pricing for all months
  #   3. After updating both prices for all months
  #   4. After updating the pool pricing for only the first month (values for second and third month should be recalculated but unchanged)
  # BDAP-2183: to update MOM offers, follow "How to Update MOM Offers Using the UI" in
  # <CONFLUENCE_URL>/display/XP/How+to+create+test+MOM+cleared+offers
  #
  # Precondition: the January, February and March 2026 settlements already exist
  # (run the three "Re-create ... 2026" scenarios first)

  # Run the quarterly pipeline for Q1 2026
    Given I want to do a scheduled settlement for product: AESO type: ANCILLARY as of: "2026-04-14T00:00:00Z"
    And I generate the expected scheduled settlements
    And I retrieve the existing matching settlements from the database
    And I generate the expected settlement items for the saved scheduled settlements
    When I POST a run-settlement-pipeline request with body
      | product_ids | a1643547-425b-4856-8177-524371fa77e6 |
      | mode        | FINAL                                |
      | start_date  | 2026-01-01                           |
      | end_date    | 2026-03-31                           |
    Then the run-settlement-pipeline response status should be 200
    Then I save the pipeline_run_id from the response
    And I expect 3 quarterly settlements - the same pipeline_run_id - have been processed by the pipeline
    Then no new settlements should have been created since the pipeline was triggered

  # Verify January
    Given I set up an E2E test using the following parameters for the settlement that was just run:
      | month | January |
      | year  | 2026    |
    And I get the financial points for the settlement
    And I get the pool_price prices
    And I get the daily_discount_price prices
    And I get cleared offers from MOM
    And I calculate the expected monthly ECO payments for the settlement
    Then the settlement and items should not be updated
    But all the settlement item intervals should be updated
    And the ECO payments should equal the expected payments
    And the ECO transaction rows should be updated

#   Verify February
    Given I set up an E2E test using the following parameters for the settlement that was just run:
      | month | February |
      | year  | 2026     |
    And I get the financial points for the settlement
    And I get the pool_price prices
    And I get the daily_discount_price prices
    And I get cleared offers from MOM
    And I calculate the expected monthly ECO payments for the settlement
    Then the settlement and items should not be updated
    But all the settlement item intervals should be updated
    And the ECO payments should equal the expected payments
    And the ECO transaction rows should be updated

  # Verify March
    Given I set up an E2E test using the following parameters for the settlement that was just run:
      | month | March |
      | year  | 2026  |
    And I get the financial points for the settlement
    And I get the pool_price prices
    And I get the daily_discount_price prices
    And I get cleared offers from MOM
    And I calculate the expected monthly ECO payments for the settlement
    Then the settlement and items should not be updated
    But all the settlement item intervals should be updated
    And the ECO payments should equal the expected payments
    And the ECO transaction rows should be updated


  Scenario: QAA code test: Verify ECO results for quarterly job without running lambda

    * -> All three month settlements must already exist.
    Given I want to do a scheduled settlement for product: AESO type: ANCILLARY as of: "2026-04-14T00:00:00Z"
    And I generate the expected scheduled settlements
    And I generate the expected settlement items for the saved scheduled settlements
    And I retrieve the existing matching settlements from the database

    * -> Verify January
    Given I set up an E2E test using the following parameters for the settlement that was just run:
      | month           | January                                  |
      | year            | 2026                                 |
    And I get the financial points for the settlement
    And I get the pool_price prices
    And I get the daily_discount_price prices
    And I get cleared offers from MOM
    And I calculate the expected monthly ECO payments for the settlement
    Then the ECO payments should equal the expected payments
    And none of the settlement item intervals should be updated

    * -> Verify February
    Given I set up an E2E test using the following parameters for the settlement that was just run:
      | month           | February                                  |
      | year            | 2026                                 |
    And I get the financial points for the settlement
    And I get the pool_price prices
    And I get the daily_discount_price prices
    And I get cleared offers from MOM
    And I calculate the expected monthly ECO payments for the settlement
    Then the ECO payments should equal the expected payments
    And none of the settlement item intervals should be updated

    * -> Verify March
    Given I set up an E2E test using the following parameters for the settlement that was just run:
      | month           | March                                  |
      | year            | 2026                                 |
    And I get the financial points for the settlement
    And I get the pool_price prices
    And I get the daily_discount_price prices
    And I get cleared offers from MOM
    And I calculate the expected monthly ECO payments for the settlement
    Then the ECO payments should equal the expected payments
    But the ECO transaction rows should not be updated
    And none of the settlement item intervals should be updated

  Scenario: AESO payment_value_override is applied by the quarterly final run (Q1 2026)
  # Precondition: January, February and March 2026 settlements already exist

    Given I want to do a scheduled settlement for product: AESO type: ANCILLARY as of: "2026-04-14T00:00:00Z"
    And I generate the expected scheduled settlements
    And I retrieve the existing matching settlements from the database
    And I generate the expected settlement items for the saved scheduled settlements

  # 1) Set the override BEFORE the quarterly run
    Given I set up an E2E test using the following parameters for the settlement that was just run:
      | month | March |
      | year  | 2026  |
    And I get the financial points for the settlement
    And I get the pool_price prices
    And I get the daily_discount_price prices
    And I get cleared offers from MOM
    And I choose a registration item with at least one cleared offer
    And I set a fixed payment_value override of 100.000000 for the first 12 existing intervals of that registration

  # 2) Quarterly final run
    When I POST a run-settlement-pipeline request with body
      | product_ids | a1643547-425b-4856-8177-524371fa77e6 |
      | mode        | FINAL                                |
      | start_date  | 2026-01-01                           |
      | end_date    | 2026-03-31                           |
    Then the run-settlement-pipeline response status should be 200
    Then I save the pipeline_run_id from the response
    And I expect 3 quarterly settlements - the same pipeline_run_id - have been processed by the pipeline

  # 3) Verify
    Then the payment for the first 12 existing intervals should be 100.000000
    And I calculate the expected monthly ECO payments for the settlement
    And the ECO payments should equal the expected payments
    And the ECO transaction rows should be updated
    And all the settlement item intervals should be updated


  Scenario: Re-create October 2026

    Given I want to do a scheduled settlement for product: AESO type: ANCILLARY as of: "2026-11-01T00:00:00Z"
    And I generate the expected scheduled settlement
    Then I verify that non-deleted settlements exist for product_id "a1643547-425b-4856-8177-524371fa77e6"
    When I set inputs_available_until_dttm_utc to null for all non-deleted settlements with product_id "a1643547-425b-4856-8177-524371fa77e6"
    And I delete all pre-existing expected settlements from the database
    When I POST a run-settlement-pipeline request with body
      | product_ids | a1643547-425b-4856-8177-524371fa77e6 |
      | mode        | FINAL                                |
      | start_date  | 2026-10-01                           |
      | end_date    | 2026-10-31                           |
    Then the run-settlement-pipeline response status should be 200
    Then I save the pipeline_run_id from the response
    And I wait until 1 settlements have been processed by the pipeline
    And I retrieve the existing matching settlement from the database

    Given I generate the expected settlement items for the saved scheduled settlement
    When I retrieve all of the pipeline history rows for our saved settlement up to pipeline_step: DONE status: SUCCESS
    Then the expected settlement items should have been created

    Given I set up an E2E test using the following parameters for the settlement that was just run:
      | month | October |
      | year  | 2026    |
    And I get the financial points for the settlement
    And I get the pool_price prices
    And I get the daily_discount_price prices
    And I get cleared offers from MOM
    And I calculate the expected monthly ECO payments for the settlement
    Then the ECO payments should equal the expected payments
    And the ECO transaction rows should be updated
    And all the settlement item intervals should be updated

  Scenario: Re-create November 2026

    Given I want to do a scheduled settlement for product: AESO type: ANCILLARY as of: "2026-12-01T00:00:00Z"
    And I generate the expected scheduled settlement
    Then I verify that non-deleted settlements exist for product_id "a1643547-425b-4856-8177-524371fa77e6"
    When I set inputs_available_until_dttm_utc to null for all non-deleted settlements with product_id "a1643547-425b-4856-8177-524371fa77e6"
    And I delete all pre-existing expected settlements from the database
    When I POST a run-settlement-pipeline request with body
      | product_ids | a1643547-425b-4856-8177-524371fa77e6 |
      | mode        | FINAL                                |
      | start_date  | 2026-11-01                           |
      | end_date    | 2026-11-30                           |
    Then the run-settlement-pipeline response status should be 200
    Then I save the pipeline_run_id from the response
    And I wait until 1 settlements have been processed by the pipeline
    And I retrieve the existing matching settlement from the database

    Given I generate the expected settlement items for the saved scheduled settlement
    When I retrieve all of the pipeline history rows for our saved settlement up to pipeline_step: DONE status: SUCCESS
    Then the expected settlement items should have been created

    Given I set up an E2E test using the following parameters for the settlement that was just run:
      | month | November |
      | year  | 2026    |
    And I get the financial points for the settlement
    And I get the pool_price prices
    And I get the daily_discount_price prices
    And I get cleared offers from MOM
    And I calculate the expected monthly ECO payments for the settlement
    Then the ECO payments should equal the expected payments
    And the ECO transaction rows should be updated
    And all the settlement item intervals should be updated


  Scenario: Re-create December 2026

    Given I want to do a scheduled settlement for product: AESO type: ANCILLARY as of: "2027-01-01T00:00:00Z"
    And I generate the expected scheduled settlement
    Then I verify that non-deleted settlements exist for product_id "a1643547-425b-4856-8177-524371fa77e6"
    When I set inputs_available_until_dttm_utc to null for all non-deleted settlements with product_id "a1643547-425b-4856-8177-524371fa77e6"
    And I delete all pre-existing expected settlements from the database
    When I POST a run-settlement-pipeline request with body
      | product_ids | a1643547-425b-4856-8177-524371fa77e6 |
      | mode        | FINAL                                |
      | start_date  | 2026-12-01                           |
      | end_date    | 2026-12-31                           |
    Then the run-settlement-pipeline response status should be 200
    Then I save the pipeline_run_id from the response
    And I wait until 1 settlements have been processed by the pipeline
    And I retrieve the existing matching settlement from the database

    Given I generate the expected settlement items for the saved scheduled settlement
    When I retrieve all of the pipeline history rows for our saved settlement up to pipeline_step: DONE status: SUCCESS
    Then the expected settlement items should have been created

    Given I set up an E2E test using the following parameters for the settlement that was just run:
      | month | December |
      | year  | 2026    |
    And I get the financial points for the settlement
    And I get the pool_price prices
    And I get the daily_discount_price prices
    And I get cleared offers from MOM
    And I calculate the expected monthly ECO payments for the settlement
    Then the ECO payments should equal the expected payments
    And the ECO transaction rows should be updated
    And all the settlement item intervals should be updated

  Scenario: Recalculate existing settlements for past 3 months - Last quarter of 2026

  # Run the quarterly pipeline for Q4 2026
    Given I want to do a scheduled settlement for product: AESO type: ANCILLARY as of: "2027-01-14T00:00:00Z"
    And I generate the expected scheduled settlements
    And I retrieve the existing matching settlements from the database
    And I generate the expected settlement items for the saved scheduled settlements
    When I POST a run-settlement-pipeline request with body
      | product_ids | a1643547-425b-4856-8177-524371fa77e6 |
      | mode        | FINAL                                |
      | start_date  | 2026-10-01                           |
      | end_date    | 2026-12-31                           |
    Then the run-settlement-pipeline response status should be 200
    Then I save the pipeline_run_id from the response
    And I expect 3 quarterly settlements - the same pipeline_run_id - have been processed by the pipeline
    Then no new settlements should have been created since the pipeline was triggered

  # Verify October
    Given I set up an E2E test using the following parameters for the settlement that was just run:
      | month | October |
      | year  | 2026    |
    And I get the financial points for the settlement
    And I get the pool_price prices
    And I get the daily_discount_price prices
    And I get cleared offers from MOM
    And I calculate the expected monthly ECO payments for the settlement
    Then the settlement and items should not be updated
    But all the settlement item intervals should be updated
    And the ECO payments should equal the expected payments
    And the ECO transaction rows should be updated

#   Verify November
    Given I set up an E2E test using the following parameters for the settlement that was just run:
      | month | November |
      | year  | 2026     |
    And I get the financial points for the settlement
    And I get the pool_price prices
    And I get the daily_discount_price prices
    And I get cleared offers from MOM
    And I calculate the expected monthly ECO payments for the settlement
    Then the settlement and items should not be updated
    But all the settlement item intervals should be updated
    And the ECO payments should equal the expected payments
    And the ECO transaction rows should be updated

  # Verify December
    Given I set up an E2E test using the following parameters for the settlement that was just run:
      | month | December |
      | year  | 2026  |
    And I get the financial points for the settlement
    And I get the pool_price prices
    And I get the daily_discount_price prices
    And I get cleared offers from MOM
    And I calculate the expected monthly ECO payments for the settlement
    Then the settlement and items should not be updated
    But all the settlement item intervals should be updated
    And the ECO payments should equal the expected payments
    And the ECO transaction rows should be updated
