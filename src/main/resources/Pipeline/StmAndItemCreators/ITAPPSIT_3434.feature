Feature: Feature tests for ITAPPSIT-3434

  ITAPPSIT-3434: settlement creator: AESO OR creator should run monthly and quarterly

  After discussion with Nate, we are changing the behavior of the quarterly process to require that all 3 monthly settlements exist. Therefore:

  - if less than 3 monthly settlements exist -> log error, user needs to manually run monthly settlements to create, then re-run quarterly settlement
  - if 3 monthly settlements exist -> rerun 3 monthly settlements (this is the expected normal situation for AESO OR)

  Also note:

  - a month settlement with deleted=true doesn't count (it must be manually re-created before running quarterly)
  - the quarterly process looks up existing settlements that match by product_id, settlement_type, and overlapping start/end dttm utc.
  - The values of the various status fields (settlement_status, business_process_status, processing_status) are ignored because they will be re-calculated anyway.


  Background:
    Given I start with an empty context
    And I log in as a settlement API admin
    And this scenario is only supported for the preprd environment


  Scenario: Progressive creation of monthly settlements followed by quarterly settlement

    Given I want to do a scheduled settlement for product: AESO type: ANCILLARY as of: "2025-07-14T00:00:00Z"
    And I log all the registration history rows for that product
    And I generate the expected scheduled settlements
    And I delete any pre-existing expected settlements from the database

    * -> Trigger the quarterly settlement. It should fail because the monthly settlements do not exist.
    Given I want to do a scheduled settlement for product: AESO type: ANCILLARY as of: "2025-07-14T00:00:00Z"
    When I invoke the settlement creator lambda
    Then no settlements should have been created

    * -> Create the first monthly settlement
    Given I want to do a scheduled settlement for product: AESO type: ANCILLARY as of: "2025-05-01T00:00:00Z"
    And I generate the expected scheduled settlement
    And I verify that the expected settlement covers the PREVIOUS_1_FULL_MONTH
    When I invoke the settlement creator lambda
    Then the expected settlements should be created and no others should be created
    And I generate the expected settlement items for the saved scheduled settlement
    When I retrieve all of the pipeline history rows for our saved settlement up to pipeline_step: ECO status: REQUESTED
    Then only the 7 expected settlement items should have been created
    Given I save the expected settlement items for later verification

    * -> Trigger the quarterly settlement. It should still fail.
    Given I want to do a scheduled settlement for product: AESO type: ANCILLARY as of: "2025-07-14T00:00:00Z"
    When I invoke the settlement creator lambda
    Then no settlements should have been created
    When I retrieve any new pipeline history rows for our saved settlements
    Then no pipeline history rows should have been retrieved

    * -> Create the second monthly settlement
    Given I want to do a scheduled settlement for product: AESO type: ANCILLARY as of: "2025-06-01T00:00:00Z"
    And I generate the expected scheduled settlement
    And I verify that the expected settlement covers the PREVIOUS_1_FULL_MONTH
    When I invoke the settlement creator lambda
    Then the expected settlements should be created and no others should be created
    And I generate the expected settlement items for the saved scheduled settlement
    When I retrieve all of the pipeline history rows for our saved settlement up to pipeline_step: ECO status: REQUESTED
    Then the expected settlement items for all saved settlements should have been created
    And only the 13 expected settlement items should have been created for the last settlement
    Given I save the expected settlement items for later verification

    * -> Trigger the quarterly settlement. It should still fail.
    Given I want to do a scheduled settlement for product: AESO type: ANCILLARY as of: "2025-07-14T00:00:00Z"
    When I invoke the settlement creator lambda
    Then no settlements should have been created
    When I retrieve any new pipeline history rows for our saved settlements
    And no pipeline history rows should have been retrieved

    * -> Create the third monthly settlement
    Given I want to do a scheduled settlement for product: AESO type: ANCILLARY as of: "2025-07-01T00:00:00Z"
    And I generate the expected scheduled settlement
    And I verify that the expected settlement covers the PREVIOUS_1_FULL_MONTH
    When I invoke the settlement creator lambda
    Then the expected settlements should be created and no others should be created
    And I generate the expected settlement items for the saved scheduled settlement
    When I retrieve all of the pipeline history rows for our saved settlement up to pipeline_step: ECO status: REQUESTED
    Then the expected settlement items for all saved settlements should have been created
    And only the 19 expected settlement items should have been created for the last settlement
    Given I save the expected settlement items for later verification


    * -> Trigger the quarterly settlement. It should succeed, but not create new monthly settlements or items.
    Given I want to do a scheduled settlement for product: AESO type: ANCILLARY as of: "2025-07-14T00:00:00Z"
    When I invoke the settlement creator lambda
    Given I expect 3 quarterly settlements - the same pipeline_run_id - have been processed by the pipeline
    Then no settlements should have been created
    When I retrieve any new pipeline history rows for our saved settlements
    Then only the 3 saved settlements should have been created earlier
