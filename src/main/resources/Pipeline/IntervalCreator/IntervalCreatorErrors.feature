Feature: Error scenarios for settlement interval creator lambda

  ITAPPSIT-3383: Settlement Creator Parent/Settlement Lambda business logic

  These scenarios use the product rules defined in the SQL files in this repo.

  Background:
    Given I start with an empty context
    And I log in as a settlement API admin


  Scenario: Various validation errors

    # POST a new settlement
    When I POST a settlement with the following properties:
      | settlement_type         | ONGOING_DATA_SUBMISSION             |
      | settlement_subtype      | TVA event                           |
      | start_dttm_utc          | 2024-02-05T23:00:00Z                |
      | end_dttm_utc            | 2024-02-06T06:00:00Z                |
      | event_id                | <uuid> |
      | description             | QAA test: MOM offers exist                        |
      | settlement_status       | PRELIMINARY                         |
      | business_process_status | NOT_STARTED                         |
      | source_system_type      | NGP                                 |
    Then the response should include the new settlement

    # POST a new settlement item with all properties
    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | REGISTRATION         |
      | settlement_level_id    | QAA: SQS Test: Level 1             |
      | submitted_indicator    | true                 |
      | settlement_item_status | PRELIMINARY        |
      | asset_type             | LOAD                 |
      | processing_status      |  CREATING  |
      |atlas_settlement_level_id | acf52c44-d146-4ca2-970f-734c97709b6c               |
      |ecrm_opportunity_id     |      abcdefghijklmnopqr                |
      | ecrm_account_id        |   123456789012345678   |
      | ecrm_site_id           |       098765432109876543            |
      | start_dttm_utc         | 2024-02-06T05:00:00.000Z                |
      | end_dttm_utc         | 2024-02-06T06:00:00.000Z                |
    Then the response should include the new settlement_item

    Given -> Invalid currency value
    When I send a message to the SQS Intervals Input Queue using the saved item and these properties:
      |currency | FOO               |
    And I receive a message from the SQS Intervals Output Queue
    Then the SQS Intervals Output message should match:
      | action| TASK_COMPLETED|
      | status  | FAILURE     |
      | error.description |  settlement API failed to create intervals |
      | error.code        |    Error                               |
      | error.stack_trace  |  Bad Request    |

    Given -> Offer duration does not match product rules interval length
    When I send a message to the SQS Intervals Input Queue using the saved item and these properties:
      |interval_length_minutes |60|
    And I receive a message from the SQS Intervals Output Queue
    Then the SQS Intervals Output message should match:
      | action| TASK_COMPLETED|
      | status  | FAILURE     |
      | error.description |  offer duration does not match product rules interval length: 15 != 60 |
      | error.code        |    Error                               |

    Given -> product_rule_intervals_kw_source_system invalid
    When I send a message to the SQS Intervals Input Queue using the saved item and these properties:
      |product_rule_intervals_kw_source_system | FOO               |
    And I receive a message from the SQS Intervals Output Queue
    Then the SQS Intervals Output message should match:
      | action| TASK_COMPLETED|
      | status  | FAILURE     |
      | error.description |  Unsupported kW source type |
      | error.code        |    Error                               |

    Given -> Registration not found in registration table
    When I send a message to the SQS Intervals Input Queue using the saved item and these properties:
      |atlas_settlement_level_id | <uuid>               |
    And I receive a message from the SQS Intervals Output Queue
    Given I DELETE the settlement
    Then the SQS Intervals Output message should match:
      | action| TASK_COMPLETED|
      | status  | FAILURE     |
      | error.description |  failed to get MOM cleared offers |
      | error.code        |    Error                               |
      | error.stack_trace                  |        Failed to find program information in the database for source registration code <atlas_settlement_level_id>    |

    Given -> Validate that no intervals were created
    Given I expect the next API call to return a status code of 404 and details of "no settlement item intervals found for settlement item id"
    When I call GET settlement_item_intervals with settlement_item_id: <last-settlement-item-id> per_page: default direction: forward
    Then the expected status should be returned