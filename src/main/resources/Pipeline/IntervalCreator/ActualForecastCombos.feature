Feature: Scenarios for combinations of actual and forecast MOM offers

  ITAPPSIT-3383: Settlement Creator Parent/Settlement Lambda business logic

  AC:
  Settlement_item_intervals should be created/updated for the entire time period specified by the item's start and end dttms.
  The properties of each interval are based on the existence of MOM offers, as follows:

  - No forecast or actual offer is returned by MOM. Result: interval_source=MISSING, cleared_offer_kw=null, original_offer_kw=null
  - Actual offer exists, but no forecast offer. Result: interval_source=OFFER, cleared_offer_kw=non-null, original_offer_kw=null (check with Alexis)
  - No actual offer, but forecast offer exists. Result: interval_source=OFFER, cleared_offer_kw=null, original_offer_kw=non-null (check with Alexis)
  - Both offers exist. Result: interval_source=OFFER,cleared_offer_kw=non-null, original_offer_kw=non-null


  Background:
    Given I start with an empty context
    And I log in as a settlement API admin


  Scenario: No forecast or actual offer is returned by MOM

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

    When I send a message to the SQS Intervals Input Queue using the saved item
    And I receive a message from the SQS Intervals Output Queue
    Then the SQS Intervals Output message should match:
      | action| TASK_COMPLETED|
      | status  | SUCCESS     |

    Given I generate expected intervals from MOM offers
    Then the database intervals should match the expected intervals
    And the database intervals should include 0 OFFER and 1 MISSING for a total of 1
