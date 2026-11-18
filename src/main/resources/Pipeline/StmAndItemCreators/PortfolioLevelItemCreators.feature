
Feature: Feature tests for FCAS portfolio-level item creation

  ITAPPSIT-3888: settlement creator: fix logic that links registration items to portfolio items
  ITAPPSIT-3885: settlement api: add registration_set_id to settlement item
  ITAPPSIT-3827: Implement scenarios to verify ITAPPSIT-3764 (update settlement creator to create PORTFOLIO-level items).

  These scenarios use the FCASRaise1Sec product rule and rely on pre-existing registration history
  to validate the creation of PORTFOLIO and REGISTRATION level settlement items.

  Prerequisite: The registration history for these scenarios must already exist.

  Background:
    Given I start with an empty context
    And I log in as a settlement API admin


  Scenario: Two registrations in one portfolio for the entire settlement period
    # Only dev has all of the registration history
    Given this scenario is only supported for the dev environment
    * -> Assumes the reg history contains two active registrations under the same portfolio_id for the period.
    Given I want to do a scheduled settlement for product: FCASRaise1Sec type: ANCILLARY as of: "2025-11-01T00:00:00Z"
    And I log all the registration history rows for that product
    And I generate the expected scheduled settlement
    And I delete any pre-existing expected settlements from the database
    And I verify that the expected settlement covers the PREVIOUS_1_FULL_MONTH

    Given I generate the expected settlement items for the saved scheduled settlement
    Then 2 applicable registration history rows should be returned
    * ->  Expected: 3 items total (1 PORTFOLIO, 2 REGISTRATION with different reg ids under the same portfolio)
    And there should be 3 expected settlement items

    When I invoke the settlement creator lambda
    Then the expected settlements should be created and no others should be created
    When I retrieve all of the pipeline history rows for our saved settlement up to pipeline_step: ECO status: REQUESTED
    Then the expected settlement items should have been created


  Scenario: A registration that is not part of a portfolio for the start of the period
    # Only dev has all of the registration history
    Given this scenario is only supported for the dev environment
    * -> Assumes the reg history contains an active registration with two rows for the period, with the first row having a null portfolio_id
    Given I want to do a scheduled settlement for product: FCASRaise1Sec type: ANCILLARY as of: "2025-12-01T00:00:00Z"
    And I log all the registration history rows for that product
    And I generate the expected scheduled settlement
    And I delete any pre-existing expected settlements from the database
    And I verify that the expected settlement covers the PREVIOUS_1_FULL_MONTH

    Given I generate the expected settlement items for the saved scheduled settlement
    Then 2 applicable registration history rows should be returned
    * -> Expected: 3 items total (1 PORTFOLIO, 1 REGISTRATION without portfolio, 1 with portfolio)
    And there should be 3 expected settlement items

    When I invoke the settlement creator lambda
    Then the expected settlements should be created and no others should be created
    When I retrieve all of the pipeline history rows for our saved settlement up to pipeline_step: ECO status: REQUESTED
    Then the expected settlement items should have been created


  Scenario: A registration that is not part of a portfolio for the end of the period
    # Only dev has all of the registration history
    Given this scenario is only supported for the dev environment
    * -> Assumes the reg history contains an active registration with two rows for the period, with the last row having a null portfolio_id
    Given I want to do a scheduled settlement for product: FCASRaise1Sec type: ANCILLARY as of: "2026-03-01T00:00:00Z"
    And I log all the registration history rows for that product
    And I generate the expected scheduled settlement
    And I delete any pre-existing expected settlements from the database
    And I verify that the expected settlement covers the PREVIOUS_1_FULL_MONTH

    Given I generate the expected settlement items for the saved scheduled settlement
    Then 2 applicable registration history rows should be returned
    * -> Expected: 3 items total (1 PORTFOLIO, 1 REGISTRATION without portfolio, 1 with portfolio)
    And there should be 3 expected settlement items

    When I invoke the settlement creator lambda
    Then the expected settlements should be created and no others should be created
    When I retrieve all of the pipeline history rows for our saved settlement up to pipeline_step: ECO status: REQUESTED
    Then the expected settlement items should have been created


  Scenario: A registration that changes portfolio in the middle of a settlement period
    # Only dev has all of the registration history
    Given this scenario is only supported for the dev environment
    * -> Verifies two REGISTRATION items are created for one registration, each linked to a different PORTFOLIO parent.
    * -> Assumes the reg history contains a registration that moves from one portfolio to another during the period.
    Given I want to do a scheduled settlement for product: FCASRaise1Sec type: ANCILLARY as of: "2026-02-01T00:00:00Z"
    And I log all the registration history rows for that product
    And I generate the expected scheduled settlement
    And I delete any pre-existing expected settlements from the database
    And I verify that the expected settlement covers the PREVIOUS_1_FULL_MONTH

    Given I generate the expected settlement items for the saved scheduled settlement
    Then 3 applicable registration history rows should be returned
    * -> Expected: 5 items total (2 PORTFOLIO, 3 REGISTRATION)
    And there should be 5 expected settlement items

    When I invoke the settlement creator lambda
    Then the expected settlements should be created and no others should be created
    When I retrieve all of the pipeline history rows for our saved settlement up to pipeline_step: ECO status: REQUESTED
    Then the expected settlement items should have been created


  Scenario: Preprd: a registration that changes portfolio in the middle of a settlement period
    # Only preprd has all of the registration history
    Given this scenario is only supported for the preprd environment
    * -> Verifies two REGISTRATION items are created for one registration, each linked to a different PORTFOLIO parent.
    * -> Assumes the reg history contains a registration that moves from one portfolio to another during the period.
    Given I want to do a scheduled settlement for product: FCASRaise1Sec type: ANCILLARY as of: "2025-11-01T00:00:00Z"
    And I log all the registration history rows for that product
    And I generate the expected scheduled settlement
    And I delete any pre-existing expected settlements from the database
    And I verify that the expected settlement covers the PREVIOUS_1_FULL_MONTH

    Given I generate the expected settlement items for the saved scheduled settlement
    Then 2 applicable registration history rows should be returned
    * -> Expected: 4 items total (2 PORTFOLIO, 2 REGISTRATION)
    And there should be 4 expected settlement items

    When I invoke the settlement creator lambda
    Then the expected settlements should be created and no others should be created
    When I retrieve all of the pipeline history rows for our saved settlement up to pipeline_step: ECO status: REQUESTED
    Then the expected settlement items should have been created
