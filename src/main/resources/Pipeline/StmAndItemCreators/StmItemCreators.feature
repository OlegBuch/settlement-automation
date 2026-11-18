Feature: Feature tests for settlement and item creator lambdas

  ITAPPSIT-3366: Implement Business Logic to Settlement Creator - Item
  ITAPPSIT-3433: settlement creator: Items Lambda should round reg hist start/end datetimes up to interval boundary

  These scenarios use the AESO product rule.

  Prerequisite: the registration history set up by StmItemCreators.sql

  Background:
    Given I start with an empty context
    And I log in as a settlement API admin
    # Only preprd has all of the registration history
    And this scenario is only supported for the preprd environment


  Scenario: Test my registration-history filtering code

     # One reg row 2020 - 2030

    # Settlement start < row start

    # Settlement end < row start
    Given I generate the expected settlement items for product: "99643547-425b-4856-8177-524371fa77e6" length: 60 start: "2019-10-01T06:00:00Z" end: "2019-12-31T23:59:59Z"
    Then 0 applicable registration history rows should be returned

    # Settlement end = row start
    Given I generate the expected settlement items for product: "99643547-425b-4856-8177-524371fa77e6" length: 60 start: "2019-10-01T06:00:00Z" end: "2020-01-01T00:00:00Z"
    Then 0 applicable registration history rows should be returned

    # Settlement end > row start, < row end
    Given I generate the expected settlement items for product: "99643547-425b-4856-8177-524371fa77e6" length: 60 start: "2019-12-31T23:59:59Z" end: "2020-01-01T00:00:01Z"
    Then 1 applicable registration history rows should be returned

    # Settlement end = row end
    Given I generate the expected settlement items for product: "99643547-425b-4856-8177-524371fa77e6" length: 60 start: "2019-12-31T23:59:59Z" end: "2030-01-01T00:00:00Z"
    Then 1 applicable registration history row should be returned

    # Settlement end > row end
    Given I generate the expected settlement items for product: "99643547-425b-4856-8177-524371fa77e6" length: 60 start: "2019-12-31T23:59:59Z" end: "2030-01-01T00:00:01Z"
    Then 1 applicable registration history row should be returned

     # Settlement start = row start

    # Settlement end < row end
    Given I generate the expected settlement items for product: "99643547-425b-4856-8177-524371fa77e6" length: 60 start: "2020-01-01T00:00:00Z" end: "2029-12-31T23:59:59Z"
    Then 1 applicable registration history rows should be returned

    # Settlement end = row end
    Given I generate the expected settlement items for product: "99643547-425b-4856-8177-524371fa77e6" length: 60 start: "2020-01-01T00:00:00Z" end: "2030-01-01T00:00:00Z"
    Then 1 applicable registration history row should be returned

    # Settlement end > row end
    Given I generate the expected settlement items for product: "99643547-425b-4856-8177-524371fa77e6" length: 60 start: "2020-01-01T00:00:00Z" end: "2030-01-01T00:00:01Z"
    Then 1 applicable registration history row should be returned

    # Settlement start > row start

    # Settlement end < row end
    Given I generate the expected settlement items for product: "99643547-425b-4856-8177-524371fa77e6" length: 60 start: "2020-01-01T00:00:01Z" end: "2029-12-31T23:59:59Z"
    Then 1 applicable registration history rows should be returned

    # Settlement end = row end
    Given I generate the expected settlement items for product: "99643547-425b-4856-8177-524371fa77e6" length: 60 start: "2020-01-01T00:00:01Z" end: "2030-01-01T00:00:00Z"
    Then 1 applicable registration history row should be returned

    # Settlement end > row end
    Given I generate the expected settlement items for product: "99643547-425b-4856-8177-524371fa77e6" length: 60 start: "2029-12-31T23:56:56Z" end: "2030-01-01T00:00:01Z"
    Then 1 applicable registration history row should be returned

    # Settlement start = row end, settlement end > row end
    Given I generate the expected settlement items for product: "99643547-425b-4856-8177-524371fa77e6" length: 60 start: "2030-01-01T00:00:00Z" end: "2030-01-01T00:00:01Z"
    Then 0 applicable registration history rows should be returned

    # Settlement start > row end
    Given I generate the expected settlement items for product: "99643547-425b-4856-8177-524371fa77e6" length: 60 start: "2030-01-01T00:00:01Z" end: "2031-01-01T00:00:00Z"
    Then 0 applicable registration history rows should be returned


  Scenario: No settlement should be created if asof date doesn't match product rule

    * -> asof date is 1 day prior to rule date (01-14)
    Given I want to do a scheduled settlement for product: AESO type: ANCILLARY as of: "2025-01-13T00:00:00Z"
    And I delete any pre-existing QAA settlements
    # Following stepdef prevents error in last stepdef if the db is a little slow to do the commit
    And I wait 3 seconds
    When I invoke the settlement creator lambda
    Then no settlements should have been created

    * -> asof date is 1 day after the rule date (01-14)
    Given I want to do a scheduled settlement for product: AESO type: ANCILLARY as of: "2025-01-15T00:00:00Z"
    And I delete any pre-existing QAA settlements
    # Following stepdef prevents error in last stepdef if the db is a little slow to do the commit
    And I wait 3 seconds
    When I invoke the settlement creator lambda
    Then no settlements should have been created


  Scenario: Three registrations exist, all start after settlement period end date, no matches

    * -> Generate settlement for Dec 2023 (2023-12-01T07:00Z - 2024-01-01T06:00Z)
    * -> History 3a0cf195-c7bd-4080-bad5-27a8ead39088: 2024-07-01T06:00Z - 2025-01-01T00:00Z (does not match, start date = period end date)
    * -> History 8b482904-ab52-4cc2-afff-914c59664b4b: 2024-10-01T06:00Z - 2025-01-01T00:00Z (does not match, start date > period end date)
    * -> History 492826a4-ed56-4aff-bf45-6eedaa93c918: 2025-02-20 - 9999-12-31 (does not match, start date > period end date)

    Given I want to do a scheduled settlement for product: AESO type: ANCILLARY as of: "2024-01-01T00:00:00Z"
    And I log all the registration history rows for that product
    And I generate the expected scheduled settlement
    And I delete any pre-existing expected settlements from the database
    And I verify that the expected settlement covers the PREVIOUS_1_FULL_MONTH
    When I invoke the settlement creator lambda
    Then the expected settlement should be created and no others should be created

    Given I generate the expected settlement items for the saved scheduled settlement
    Then there should be 0 expected settlement items

    Given I retrieve all of the pipeline history rows for our saved settlement up to pipeline_step: CREATOR_REST status: STARTED
    And I timeout waiting for a pipeline history row for our saved settlement with pipeline_step: ECO status: REQUESTED
    Then no settlement items should have been created


  Scenario: Multiple registrations exist, only some match

    * -> Generate settlement and items for July 2024 (2024-07-01T06:00Z - 2024-08-01T06:00Z)
    * -> History 3a0cf195-c7bd-4080-bad5-27a8ead39088: 2024-07-01T06:00Z - 2025-01-01T00:00Z (matches, start date = period start date)
    * -> History 8b482904-ab52-4cc2-afff-914c59664b4b: 2024-10-01T06:00Z - 2025-01-01T00:00Z (does not match, start date > period end date)
    * -> History 492826a4-ed56-4aff-bf45-6eedaa93c918: 2025-02-20 - 9999-12-31 (does not match, start date > period end date)
    * -> There may be other history rows created from other tests.

    Given I want to do a scheduled settlement for product: AESO type: ANCILLARY as of: "2024-08-01T00:00:00Z"
    And I log all the registration history rows for that product
    And I generate the expected scheduled settlement
    And I delete any pre-existing expected settlements from the database
    And I verify that the expected settlement covers the PREVIOUS_1_FULL_MONTH
    When I invoke the settlement creator lambda
    Then the expected settlements should be created and no others should be created

    And I generate the expected settlement items for the saved scheduled settlement
    When I retrieve all of the pipeline history rows for our saved settlement up to pipeline_step: ECO status: REQUESTED
    Then the expected settlement items should have been created


  Scenario: Multiple registrations exist, at least two match

    * -> Generate settlement and items for Oct 2024 (2024-10-01T06:00Z - 2025-11-01T06:00Z)
    * -> History 3a0cf195-c7bd-4080-bad5-27a8ead39088: 2024-07-01T06:00Z - 2025-01-01T00:00 (matches, start date < period start date)
    * -> History 8b482904-ab52-4cc2-afff-914c59664b4b: 2024-10-01T06:00Z - 2025-01-01T00:00Z (matches, start date = period start date)
    * -> History 492826a4-ed56-4aff-bf45-6eedaa93c918: 2025-02-20 - 9999-12-31 (does not match, start date > period end date)
    * -> There may be other history rows created from other tests.

    #Given I DELETE settlement with the settlement_id 0a2828d3-fe95-4226-b1c3-5fe6d9089020
    #* stop

    Given I want to do a scheduled settlement for product: AESO type: ANCILLARY as of: "2024-11-01T00:00:00Z"
    And I log all the registration history rows for that product
    And I generate the expected scheduled settlement
    And I delete any pre-existing expected settlements from the database
    And I verify that the expected settlement covers the PREVIOUS_1_FULL_MONTH
    When I invoke the settlement creator lambda
    Then the expected settlements should be created and no others should be created

    Given I generate the expected settlement items for the saved scheduled settlement
    When I retrieve all of the pipeline history rows for our saved settlement up to pipeline_step: ECO status: REQUESTED
    Then the expected settlement items should have been created

    * -> Verify that if items already exist they are not created again
    When I send a message to the SQS Items Input Queue using the saved settlement
    And I wait 10 seconds
    When I retrieve all of the pipeline history rows for our saved settlement up to pipeline_step: ECO status: REQUESTED
    Then no new settlement items should have been created


  Scenario: ITAPPSIT-3785 - Settlement Creator sets ESTIMATED mode based on Product Rule
    # 1. Setup Input
    Given I want to do a scheduled settlement for product: FCASRaise5Min type: ANCILLARY as of: "2025-06-01T00:00:00Z"

    # 2. REQUIRED PREP: Generate the internal expectation objects
    # This logic calculates what the settlement start/end dates will be so we can find it later
    And I generate the expected scheduled settlement
    And I delete any pre-existing expected settlements from the database

    # 3. Action: Run the lambda
    When I invoke the settlement creator lambda

    # 4. REQUIRED CAPTURE: Find the settlement in DB and save the ID
    # This step locates the new row in the DB and saves its UUID to <last-settlement-id>
    Then the expected settlements should be created and no others should be created

    # 5. Wait for Persistence
    # Now <last-settlement-id> is populated, so this step will actually look for the correct ID
    And I retrieve all of the pipeline history rows for our saved settlement up to pipeline_step: CREATOR_FIRST status: SUCCESS

    # 6. Bridge Step: Load rows into context for API assertions
    When I GET the pipeline state history items with:
      | settlement_id | <last-settlement-id> |

    # 7. Assert Mode
    Then for each of the following settlements I should find the corresponding states:
      | settlement-id        | step          | status  | mode      |
      | <last-settlement-id> | CREATOR_FIRST | SUCCESS | ESTIMATED |


  Scenario: ITAPPSIT-3785 -  Settlement Creator defaults to FINAL mode if there are no 'estimated' fields with a value of 'true' in the Product Rule
    # 1. Setup Input
    Given I want to do a scheduled settlement for product: AESO type: ANCILLARY as of: "2025-06-01T00:00:00Z"

    # 2. REQUIRED PREP: Generate the internal expectation objects
    # This logic calculates what the settlement start/end dates will be so we can find it later
    And I generate the expected scheduled settlement
    And I delete any pre-existing expected settlements from the database

    # 3. Action: Run the lambda
    When I invoke the settlement creator lambda

    # 4. REQUIRED CAPTURE: Find the settlement in DB and save the ID
    # This step locates the new row in the DB and saves its UUID to <last-settlement-id>
    Then the expected settlements should be created and no others should be created

    # 5. Wait for Persistence
    # Now <last-settlement-id> is populated, so this step will actually look for the correct ID
    And I retrieve all of the pipeline history rows for our saved settlement up to pipeline_step: CREATOR_FIRST status: SUCCESS

    # 6. Bridge Step: Load rows into context for API assertions
    When I GET the pipeline state history items with:
      | settlement_id | <last-settlement-id> |

    # 7. Assert Mode
    Then for each of the following settlements I should find the corresponding states:
      | settlement-id        | step          | status  | mode      |
      | <last-settlement-id> | CREATOR_FIRST | SUCCESS | FINAL     |

  Scenario: Registration changes in middle of settlement period

    * I stop here because "reg history has to be updated to support this test"

    Given I want to do a scheduled settlement for product: AESO type: ANCILLARY as of: "2024-07-01T00:00:00Z"
    And I log all the registration history rows for that product
    And I generate the expected scheduled settlement
    And I delete any pre-existing expected settlements from the database
    And I verify that the expected settlement covers the PREVIOUS_1_FULL_MONTH
    When I invoke the settlement creator lambda
    Then the expected settlements should be created and no others should be created

    And I generate the expected settlement items for the saved scheduled settlement
    When I retrieve all of the pipeline history rows for our saved settlement up to pipeline_step: ECO status: REQUESTED
    Then only the 2 expected settlement items should have been created


  Scenario: Registration switches from active to inactive to active in middle of settlement period

    * I stop here because "reg history has to be updated to support this test"

    Given I want to do a scheduled settlement for product: AESO type: ANCILLARY as of: "2024-06-01T00:00:00Z"
    And I log all the registration history rows for that product
    And I generate the expected scheduled settlement
    And I delete any pre-existing expected settlements from the database
    And I verify that the expected settlement covers the PREVIOUS_1_FULL_MONTH
    When I invoke the settlement creator lambda
    Then the expected settlements should be created and no others should be created

    And I generate the expected settlement items for the saved scheduled settlement
    When I retrieve all of the pipeline history rows for our saved settlement up to pipeline_step: ECO status: REQUESTED
    Then only the 2 expected settlement items should have been created


  Scenario: Registration is deleted and re-created in middle of settlement period

    * I stop here because "reg history has to be updated to support this test"

    Given I want to do a scheduled settlement for product: AESO type: ANCILLARY as of: "2024-05-01T00:00:00Z"
    And I log all the registration history rows for that product
    And I generate the expected scheduled settlement
    And I delete any pre-existing expected settlements from the database
    And I verify that the expected settlement covers the PREVIOUS_1_FULL_MONTH
    When I invoke the settlement creator lambda
    Then the expected settlements should be created and no others should be created

    And I generate the expected settlement items for the saved scheduled settlement
    When I retrieve all of the pipeline history rows for our saved settlement up to pipeline_step: ECO status: REQUESTED
    Then only the 2 expected settlement items should have been created


  Scenario: Registration has jitter in middle of settlement period

    * -> History 3a0cf195-c7bd-4080-bad5-27a8ead39088: 2024-07-01T06:00Z - 2025-01-01T00:00Z (does not match, start date = period end date)
    * -> History 8b482904-ab52-4cc2-afff-914c59664b4b: 2024-10-01T06:00Z - 2025-01-01T00:00Z (does not match, start date > period end date)
    * -> History 492826a4-ed56-4aff-bf45-6eedaa93c918: 2025-02-20 - 9999-12-31 (does not match, start date > period end date)

    Given I want to do a scheduled settlement for product: AESO type: ANCILLARY as of: "2024-04-01T00:00:00Z"
    And I log all the registration history rows for that product
    And I generate the expected scheduled settlement
    And I delete any pre-existing expected settlements from the database
    And I verify that the expected settlement covers the PREVIOUS_1_FULL_MONTH
    When I invoke the settlement creator lambda
    Then the expected settlements should be created and no others should be created

    And I generate the expected settlement items for the saved scheduled settlement
    When I retrieve all of the pipeline history rows for our saved settlement up to pipeline_step: ECO status: REQUESTED
    Then only the 2 expected settlement items should have been created


