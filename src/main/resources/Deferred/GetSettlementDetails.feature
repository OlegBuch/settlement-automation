Feature: GET settlement_details


  Background:
    Given I stop here because 'DEFERRED per agreement with Yanis'
    Given I start with an empty context
    And I log in as a settlement API user


  Scenario: Set up settlements for GET settlement_details scenarios

      # Scenario only needs to be run once per env
    Given I verify that no settlement exists with the event "QAA: GET settlement_details: Event 2"

    #Given I DELETE settlement with the settlement_id 6a913bc4-d2e4-4cbd-971c-347f9e00477c
    #Given I stop here

    When I POST a settlement with the following properties:
      | settlement_type         | ONGOING_DATA_SUBMISSION        |
      | settlement_subtype      | TVA event                      |
      | settlement_status       | PRELIMINARY                    |
      | business_process_status | NOT_STARTED                    |
      | description             | QAA: GET settlement_details        |
      | event_id                | QAA: GET settlement_details: Event 2 |
      | start_dttm_utc          | 2018-10-05T08:00:00.000Z       |
      | end_dttm_utc            | 2018-10-05T08:30:00.000Z       |
      | source_system_type      | NGP                            |
    Then the response should include the new settlement

    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | REGISTRATION         |
      | settlement_level_id    | QAA: GET settlement_details: Level 1             |
      | settlement_item_status | AWAITING_DATA        |
      | submitted_indicator    | true                 |
      | asset_type             | LOAD                 |
    Then the response should include the new settlement_item
    Given I save the settlement_item id for later use with the tag Item1
    And I POST a set of 1 intervals for settlement_item_id Item1

    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | ACCOUNT         |
      | settlement_level_id    | QAA: GET settlement_details: Level 2             |
      | settlement_item_status | PRELIMINARY        |
      | submitted_indicator    | false                 |
      | asset_type             | DER_BESS                 |
    Then the response should include the new settlement_item
    Given I save the settlement_item id for later use with the tag Item2
    And I POST a set of 2 intervals for settlement_item_id Item2

      # Following item tests that queries do not return deleted items
    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | ACCOUNT         |
      | settlement_level_id    | QAA: GET settlement_details: Deleted             |
      | settlement_item_status | PRELIMINARY        |
      | submitted_indicator    | false                 |
      | asset_type             | DER_BESS                 |
    Then the response should include the new settlement_item
    Given I save the settlement_item id for later use with the tag Item3
    And I POST a set of 2 intervals for settlement_item_id Item3

    Given I set the last settlement_item id from the tag Item3
    And I DELETE the settlement_item
    Then the DELETE settlement_item details should specify 2 settlement item intervals


  Scenario: GET settlement_details

    Given a settlement exists for the event 'QAA: GET settlement_details: Event 2'
    Given I want to log all API responses
    When I call GET settlement_details
