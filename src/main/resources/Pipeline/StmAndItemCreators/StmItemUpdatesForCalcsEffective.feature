Feature: Feature tests for settlement creator to take product rule parameters for calc effective start/end dates into effect.

  ITAPPSIT-3773: Implement Business Logic to update settlement creator to take product rule parameters for calc effective start/end dates into effect.


  Background:
    Given I start with an empty context
    And I log in as a settlement API admin
    # Rules are set up correctly only in preprd
    And this scenario is only supported for the preprd environment


  Scenario: Settlement should be created if asof date matches first month allowed by CALCS_EFFECTIVE_START_DTTM_UTC

    * -> This scenario uses FCASRaise1Sec rule with a CALCS_EFFECTIVE_START_DTTM_UTC set by developer to match official program rules
    * -> CALCS_EFFECTIVE_START_DTTM_UTC is set to 2025-01-01T00:00:00Z, so first month allowed is Jan 2025

    Given I want to do a scheduled settlement for product: FCASRaise1Sec type: ANCILLARY as of: "2025-02-01T00:00:00Z"
    And I generate the expected scheduled settlement
    And I delete any pre-existing expected settlements from the database
    Given I generate the expected settlement items for the saved scheduled settlement
    Then 1 applicable registration history rows should be returned
    * ->  Expected: 2 items total (1 PORTFOLIO, 1 REGISTRATION)
    And there should be 2 expected settlement items
    When I invoke the settlement creator lambda
    Then the expected settlements should be created and no others should be created
    When I retrieve all of the pipeline history rows for our saved settlement up to pipeline_step: ECO status: REQUESTED
    Then the expected settlement items should have been created


  Scenario: No settlement should be created if asof date is before first month allowed by CALCS_EFFECTIVE_START_DTTM_UTC

    * -> This scenario uses FCASRaise1Sec rule with a CALCS_EFFECTIVE_START_DTTM_UTC set by developer to match official program rules
    * -> CALCS_EFFECTIVE_START_DTTM_UTC is set to 2025-01-01T00:00:00Z, so first month allowed is Jan 2025

    Given I want to do a scheduled settlement for product: FCASRaise1Sec type: ANCILLARY as of: "2025-01-01T00:00:00Z"
    And I generate the expected scheduled settlement
    And I delete any pre-existing expected settlements from the database
    # Following stepdef prevents error in last stepdef if the db is a little slow to do the commit
    And I wait 3 seconds
    # Following stepdefs verifies that there are in fact reg histories rows for the requested month,
    # so settlement would have been created if it was allowed by CALCS_EFFECTIVE_END_DTTM_UTC
    Given I generate the expected settlement items for the saved scheduled settlement
    Then 1 applicable registration history rows should be returned
    When I invoke the settlement creator lambda
    And I wait 30 seconds
    Then no settlements should have been created


  Scenario: Settlement should be created if asof date matches last month allowed by CALCS_EFFECTIVE_END_DTTM_UTC

    * -> We don't want to use FCASRaise1Sec rule because CALCS_EFFECTIVE_START_DTTM_UTC is set to effective infinity,
    * -> so we use AESO rule with a CALCS_EFFECTIVE_END_DTTM_UTC set by QAA
    * -> CALCS_EFFECTIVE_END_DTTM_UTC is set to 2100-12-31T00:00:00Z, so last month allowed is November 2100

    Given I want to do a scheduled settlement for product: AESO type: ANCILLARY as of: "2100-12-01T00:00:00Z"
    And I generate the expected scheduled settlement
    And I delete any pre-existing expected settlements from the database
    And I verify that the expected settlement covers the PREVIOUS_1_FULL_MONTH
    Given I generate the expected settlement items for the saved scheduled settlement
    Then 9 applicable registration history rows should be returned
    And there should be 9 expected settlement items
    When I invoke the settlement creator lambda
    Then the expected settlements should be created and no others should be created
    When I retrieve all of the pipeline history rows for our saved settlement up to pipeline_step: ECO status: REQUESTED
    Then the expected settlement items should have been created


  Scenario: No settlement should be created if asof date is after last month allowed by CALCS_EFFECTIVE_END_DTTM_UTC

    * -> We don't want to use FCASRaise1Sec rule because CALCS_EFFECTIVE_START_DTTM_UTC is set to effective infinity,
    * -> so we use AESO rule with a CALCS_EFFECTIVE_END_DTTM_UTC set by QAA
    * -> CALCS_EFFECTIVE_END_DTTM_UTC is set to 2100-12-31T00:00:00Z, so last month allowed is November 2100

    Given I want to do a scheduled settlement for product: AESO type: ANCILLARY as of: "2101-01-01T00:00:00Z"
    And I generate the expected scheduled settlement
    And I delete any pre-existing expected settlements from the database
    # Following stepdef prevents error in last stepdef if the db is a little slow to do the commit
    And I wait 3 seconds
    # Following stepdefs verifies that there are in fact reg histories rows for the requested month,
    # so settlement would have been created if it was allowed by CALCS_EFFECTIVE_END_DTTM_UTC
    Given I generate the expected settlement items for the saved scheduled settlement
    Then 9 applicable registration history rows should be returned
    When I invoke the settlement creator lambda
    And I wait 30 seconds
    Then no settlements should have been created
