Feature: Basic feature tests for settlement creator lambda

  ITAPPSIT-3383: Settlement Creator Parent/Settlement Lambda business logic

  These scenarios use the product rules defined in the SQL files in this repo.

  Background:
    Given I start with an empty context
    And I log in as a settlement API admin


  Scenario: No MOM cleared offers exist (all intervals should have interval_source=MISSING)

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
      | end_dttm_utc         | 2024-02-06T05:15:00.000Z                |
    Then the response should include the new settlement_item

    Given -> Create one interval

    When I send a message to the SQS Intervals Input Queue using the saved item and these properties:
      | product_id         | a1643547-425b-4856-8177-524371fa77e6               |
    And I receive a message from the SQS Intervals Output Queue
    Then the SQS Intervals Output message should match:
      | action| TASK_COMPLETED|
      | status  | SUCCESS     |

    Given I generate expected intervals from MOM offers
    When I call GET settlement_item_intervals with settlement_item_id: <last-settlement-item-id> per_page: default direction: forward
    Then the database intervals should match the expected intervals
    And the database intervals should include 0 OFFER and 1 MISSING for a total of 1

    Given -> Re-create the first interval without deleting it and add a new one (it should succeed)

    When I send a message to the SQS Intervals Input Queue using the saved item and these properties:
      | end_dttm_utc         | 2024-02-06T05:30:00.000Z                |
    And I receive a message from the SQS Intervals Output Queue
    Then the SQS Intervals Output message should match:
      | action| TASK_COMPLETED|
      | status  | SUCCESS     |

    Given I generate expected intervals from MOM offers
    When I call GET settlement_item_intervals with settlement_item_id: <last-settlement-item-id> per_page: default direction: forward
    Then the database intervals should match the expected intervals
    And all of the returned intervals should have deleted=false
    And the database intervals should include 0 OFFER and 2 MISSING for a total of 2

    When I DELETE the settlement_item
    Then the DELETE settlement_item details should specify 1 settlement item and 2 settlement item intervals


  Scenario: MOM cleared offers exist for new settlement (all intervals should have interval_source=OFFER)

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

    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | REGISTRATION         |
      | settlement_level_id    | QAA: MOM offers             |
      | submitted_indicator    | true                 |
      | settlement_item_status | PRELIMINARY        |
      | asset_type             | LOAD                 |
      | processing_status      |  CREATING  |
      |atlas_settlement_level_id | acf52c44-d146-4ca2-970f-734c97709b6c               |
      |ecrm_opportunity_id     |      abcdefghijklmnopqr                |
      | ecrm_account_id        |   123456789012345678   |
      | ecrm_site_id           |       098765432109876543            |
      | start_dttm_utc         | 2024-02-06T05:00:00.000Z                |
      | end_dttm_utc         | 2024-02-06T05:15:00.000Z                |
    Then the response should include the new settlement_item

    Given -> Create one interval

    When I send a message to the SQS Intervals Input Queue using the saved item
    And I receive a message from the SQS Intervals Output Queue
    Then the SQS Intervals Output message should match:
      | action| TASK_COMPLETED|
      | status  | SUCCESS     |

    Given I generate expected intervals from MOM offers
    When I call GET settlement_item_intervals with settlement_item_id: <last-settlement-item-id> per_page: default direction: forward
    Then the database intervals should match the expected intervals
    And the database intervals should include 1 OFFER and 0 MISSING for a total of 1

    Given -> Re-create the first interval without deleting it and add a new one (it should succeed)

    When I send a message to the SQS Intervals Input Queue using the saved item and these properties:
      | end_dttm_utc         | 2024-02-06T05:30:00.000Z                |
    And I receive a message from the SQS Intervals Output Queue
    Then the SQS Intervals Output message should match:
      | action| TASK_COMPLETED|
      | status  | SUCCESS     |

    Given I generate expected intervals from MOM offers
    When I call GET settlement_item_intervals with settlement_item_id: <last-settlement-item-id> per_page: default direction: forward
    Then the database intervals should match the expected intervals
    And all of the returned intervals should have deleted=false
    And the database intervals should include 2 OFFER and 0 MISSING for a total of 2

    Given -> Delete the two intervals, then re-create them and add a third. New intervals should have deleted=false.

    Given I DELETE the settlement_item_intervals
    And if I set include_deleted=true
    When I call GET settlement_item_intervals with settlement_item_id: <last-settlement-item-id> per_page: default direction: forward
    Then all of the returned intervals should have deleted=true
    When I send a message to the SQS Intervals Input Queue using the saved item and these properties:
      | end_dttm_utc         | 2024-02-06T05:45:00.000Z                |
    And I receive a message from the SQS Intervals Output Queue
    Then the SQS Intervals Output message should match:
      | action| TASK_COMPLETED|
      | status  | SUCCESS     |

    Given I generate expected intervals from MOM offers
    When I call GET settlement_item_intervals with settlement_item_id: <last-settlement-item-id> per_page: default direction: forward
    Then the database intervals should match the expected intervals
    And all of the returned intervals should have deleted=false
    And the database intervals should include 3 OFFER and 0 MISSING for a total of 3

    Given -> Attempting to create intervals for a deleted item should fail

    When I DELETE the settlement_item
    Then the DELETE settlement_item details should specify 1 settlement item and 3 settlement item intervals
    And if I set include_deleted=true
    When I call GET settlement_item_intervals with settlement_item_id: <last-settlement-item-id> per_page: default direction: forward
    Then all of the returned intervals should have deleted=true

    When I send a message to the SQS Intervals Input Queue using the saved item and these properties:
      | end_dttm_utc         | 2024-02-06T05:00:00.000Z                |
    And I receive a message from the SQS Intervals Output Queue
    Then the SQS Intervals Output message should match:
      | action| TASK_COMPLETED|
      | status  | FAILURE     |
      | error.description |  settlement API failed to create intervals |
      | error.code        |    Error                               |


  Scenario: MOM cleared offers exist for some but not all intervals

    When I POST a settlement with the following properties:
      | settlement_type         | ONGOING_DATA_SUBMISSION             |
      | settlement_subtype      | TVA event                           |
      | start_dttm_utc          | 2024-02-05T22:15:00Z                |
      | end_dttm_utc            | 2024-02-05T23:00:00Z                |
      | event_id                | <uuid> |
      | description             | QAA test: some offers exist                        |
      | settlement_status       | PRELIMINARY                         |
      | business_process_status | NOT_STARTED                         |
      | source_system_type      | NGP                                 |
    Then the response should include the new settlement

    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | REGISTRATION         |
      | settlement_level_id    | QAA: MOM offers             |
      | submitted_indicator    | true                 |
      | settlement_item_status | PRELIMINARY        |
      | asset_type             | LOAD                 |
      | processing_status      |  CREATING  |
      |atlas_settlement_level_id | acf52c44-d146-4ca2-970f-734c97709b6c               |
      |ecrm_opportunity_id     |      abcdefghijklmnopqr                |
      | ecrm_account_id        |   123456789012345678   |
      | ecrm_site_id           |       098765432109876543            |
      | start_dttm_utc         | 2024-02-05T22:15:00Z                |
      | end_dttm_utc         | 2024-02-05T23:00:00Z                |
    Then the response should include the new settlement_item

    Given -> Create three missing intervals just prior to the first offer

    When I send a message to the SQS Intervals Input Queue using the saved item
    And I receive a message from the SQS Intervals Output Queue
    Then the SQS Intervals Output message should match:
      | action| TASK_COMPLETED|
      | status  | SUCCESS     |

    Given I generate expected intervals from MOM offers
    When I call GET settlement_item_intervals with settlement_item_id: <last-settlement-item-id> per_page: default direction: forward
    Then the database intervals should match the expected intervals
    And the database intervals should include 0 OFFER and 3 MISSING for a total of 3
