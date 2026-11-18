Feature: Feature test for ITAPPSIT-3420

  ITAPPSIT-3420: settlement db should allow multiple items per settlement_id + registration if they do not overlap in time

  Note: settlement_item.settlement_level_id is not used by Settlement pipeline. DR systems currently uses settlement_level_id = ECRM registration id when settlement_level = REGISTRATION.
  Pipeline uses atlas_settlement_level_id = Atlas registration uuid when settlement_level = REGISTRATION.

  Background:
    Given I start with an empty context
    And I log in as a settlement API admin


  Scenario: Multiple items can be created under the same settlement for the same atlas_settlement_level_id as long as the time ranges don't overlap

    When I POST a settlement with the following properties:
      | settlement_type         | ANCILLARY             |
      | settlement_subtype      | AESO event                           |
      | start_dttm_utc          | 2023-09-05T07:00:00.000Z                |
      | end_dttm_utc            | 2023-09-06T07:00:00.000Z                |
      | event_id                | <uuid> |
      | description             | QAA test: create settlement                        |
      | settlement_status       | PRELIMINARY                         |
      | business_process_status | NOT_STARTED                         |
      | source_system_type      | NGP                                 |
    Then the response should include the new settlement

    Given -> Create an item for the third hour
    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
     | settlement_level       | REGISTRATION         |
      |atlas_settlement_level_id | <uuid>              |
      | submitted_indicator    | false                 |
      | settlement_item_status | AWAITING_DATA        |
      | asset_type             | LOAD                 |
      | start_dttm_utc          | 2023-09-05T09:00:00.000Z                |
      | end_dttm_utc            | 2023-09-05T10:00:00.000Z                |
    Then the response should include the new settlement_item

    Given -> You cannot create an item that overlaps the start-time of the first item
    Given I expect the next API call to return a status code of 400 and details of "a settlement item already exists for the provided settlement_id, atlas_settlement_level_id, and time"
    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | REGISTRATION         |
      |atlas_settlement_level_id | <last-atlas-settlement-level-id>              |
      | submitted_indicator    | true                 |
      | settlement_item_status | AWAITING_DATA        |
      | asset_type             | LOAD                 |
      | start_dttm_utc          | 2023-09-05T08:00:00.000Z                |
      | end_dttm_utc            | 2023-09-05T09:01:00.000Z                |
    Then the expected status should be returned

    Given -> You cannot create an item that overlaps the end-time of the first item
    Given I expect the next API call to return a status code of 400 and details of "a settlement item already exists for the provided settlement_id, atlas_settlement_level_id, and time"
    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | REGISTRATION         |
      |atlas_settlement_level_id | <last-atlas-settlement-level-id>              |
      | submitted_indicator    | true                 |
      | settlement_item_status | AWAITING_DATA        |
      | asset_type             | LOAD                 |
      | start_dttm_utc          | 2023-09-05T09:59:00.000Z                |
      | end_dttm_utc            | 2023-09-05T11:00:00.000Z                |
    Then the expected status should be returned

    Given -> You cannot create an item with null dates if any item already exists
    Given I expect the next API call to return a status code of 400 and details of "a settlement item already exists for the provided settlement_id, atlas_settlement_level_id, and time"
    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | REGISTRATION         |
      |atlas_settlement_level_id | <last-atlas-settlement-level-id>              |
      | submitted_indicator    | true                 |
      | settlement_item_status | AWAITING_DATA        |
      | asset_type             | LOAD                 |
    Then the expected status should be returned

    Given -> However, you can create an item that abuts the start time of the first item
    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | REGISTRATION         |
      |atlas_settlement_level_id | <last-atlas-settlement-level-id>              |
      | submitted_indicator    | false                 |
      | settlement_item_status | AWAITING_DATA        |
      | asset_type             | LOAD                 |
      | start_dttm_utc          | 2023-09-05T08:00:00.000Z                |
      | end_dttm_utc            | 2023-09-05T09:00:00.000Z                |
    Then the response should include the new settlement_item

    Given -> And you can create an item that abuts the end time of the first item
    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | REGISTRATION         |
      |atlas_settlement_level_id | <last-atlas-settlement-level-id>              |
      | submitted_indicator    | false                 |
      | settlement_item_status | AWAITING_DATA        |
      | asset_type             | LOAD                 |
      | start_dttm_utc          | 2023-09-05T10:00:00.000Z                |
      | end_dttm_utc            | 2023-09-05T11:00:00.000Z                |
    Then the response should include the new settlement_item

    Given -> And you can create an item that leaves a gap
    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | REGISTRATION         |
      |atlas_settlement_level_id | <last-atlas-settlement-level-id>              |
      | submitted_indicator    | false                 |
      | settlement_item_status | AWAITING_DATA        |
      | asset_type             | LOAD                 |
      | start_dttm_utc          | 2023-09-05T20:00:00.000Z                |
      | end_dttm_utc            | 2023-09-05T21:00:00.000Z                |
    Then the response should include the new settlement_item

    Given -> Now create another item for the same atlas_settlement_level_id but different date range to use for PUTs
    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | REGISTRATION         |
      |atlas_settlement_level_id | <last-atlas-settlement-level-id>              |
      | submitted_indicator    | false                 |
      | settlement_item_status | AWAITING_DATA        |
      | asset_type             | LOAD                 |
      | start_dttm_utc          | 2023-09-05T14:00:00.000Z                |
      | end_dttm_utc            | 2023-09-05T15:00:00.000Z                |
    Then the response should include the new settlement_item

    Given -> You can use PUT to move the item to abut an existing item
    When I PUT the settlement_item with new values:
      | settlement_id          | <last-settlement-id> |
      | settlement_item_id     | <last-settlement-item-id>   |
      | settlement_level       | REGISTRATION         |
      |atlas_settlement_level_id | <last-atlas-settlement-level-id>              |
      | submitted_indicator    | false                 |
      | settlement_item_status | AWAITING_DATA        |
      | asset_type             | LOAD                 |
      | start_dttm_utc          | 2023-09-05T11:00:00.000Z                |
      | end_dttm_utc            | 2023-09-05T12:00:00.000Z                |
      | change_comments        | Abut end time       |
    Then the response should include the updated settlement_item

    Given -> But you can't use PUT to create an overlapping item
    Given I expect the next API call to return a status code of 400 and details of "a settlement item already exists for the provided settlement_id, atlas_settlement_level_id, and time"
    When I PUT the settlement_item with new values:
      | settlement_id          | <last-settlement-id> |
      | settlement_item_id     | <last-settlement-item-id>   |
      | settlement_level       | REGISTRATION         |
      |atlas_settlement_level_id | <last-atlas-settlement-level-id>              |
      | submitted_indicator    | false                 |
      | settlement_item_status | AWAITING_DATA        |
      | asset_type             | LOAD                 |
      | start_dttm_utc          | 2023-09-05T07:00:00.000Z                |
      | end_dttm_utc            | 2023-09-05T08:01:00.000Z                |
      | change_comments        | Overlap start time       |
    Then the expected status should be returned

    Given -> And you can't use PUT to set the dates of an item to null. Note: this will succeed if there is only one item.
    Given I expect the next API call to return a status code of 400 and details of "a settlement item already exists for the provided settlement_id, atlas_settlement_level_id, and time"
    When I PUT the settlement_item with new values:
      | settlement_id          | <last-settlement-id> |
      | settlement_item_id     | <last-settlement-item-id>   |
      | settlement_level       | REGISTRATION         |
      |atlas_settlement_level_id | <last-atlas-settlement-level-id>              |
      | submitted_indicator    | false                 |
      | settlement_item_status | AWAITING_DATA        |
      | asset_type             | LOAD                 |
      | change_comments        | Null dates       |
    Then the expected status should be returned

    Given -> Now create an item with null dates (must use a different atlas_settlement_level_id)
    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | REGISTRATION         |
      |atlas_settlement_level_id | <uuid>              |
      | submitted_indicator    | false                 |
      | settlement_item_status | AWAITING_DATA        |
      | asset_type             | LOAD                 |
    Then the response should include the new settlement_item

    Given -> If an item with null dates exists, you cannot create another item with null dates
    Given I expect the next API call to return a status code of 400 and details of "a settlement item already exists for the provided settlement_id, atlas_settlement_level_id, and time"
    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | REGISTRATION         |
      |atlas_settlement_level_id | <last-atlas-settlement-level-id>              |
      | submitted_indicator    | true                 |
      | settlement_item_status | AWAITING_DATA        |
      | asset_type             | LOAD                 |
    Then the expected status should be returned

    Given -> If an item with null dates exists, you cannot create another item with any dates
    Given I expect the next API call to return a status code of 400 and details of "a settlement item already exists for the provided settlement_id, atlas_settlement_level_id, and time"
    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | REGISTRATION         |
      |atlas_settlement_level_id | <last-atlas-settlement-level-id>              |
      | submitted_indicator    | true                 |
      | settlement_item_status | AWAITING_DATA        |
      | asset_type             | LOAD                 |
      | start_dttm_utc          | 2023-09-05T16:00:00.000Z                |
      | end_dttm_utc            | 2023-09-05T17:00:00.000Z                |
    Then the expected status should be returned

    Given -> Cleanup
    When I DELETE the settlement
    Then the DELETE settlement details should specify 6 settlement items and 0 settlement item intervals


    Scenario: Multiple items can be created under the same settlement with overlapping time ranges if the atlas_settlement_level_ids are different

      When I POST a settlement with the following properties:
        | settlement_type         | ANCILLARY             |
        | settlement_subtype      | AESO event                           |
        | start_dttm_utc          | 2023-09-05T07:00:00.000Z                |
        | end_dttm_utc            | 2023-09-06T07:00:00.000Z                |
        | event_id                | <uuid> |
        | description             | QAA test: create settlement                        |
        | settlement_status       | PRELIMINARY                         |
        | business_process_status | NOT_STARTED                         |
        | source_system_type      | NGP                                 |
      Then the response should include the new settlement

      Given -> Create an item for the third hour
      When I POST a settlement_item with the following properties:
        | settlement_id          | <last-settlement-id> |
        | settlement_level       | REGISTRATION         |
        |atlas_settlement_level_id | <uuid>              |
        | submitted_indicator    | false                 |
        | settlement_item_status | AWAITING_DATA        |
        | asset_type             | LOAD                 |
        | start_dttm_utc          | 2023-09-05T09:00:00.000Z                |
        | end_dttm_utc            | 2023-09-05T10:00:00.000Z                |
      Then the response should include the new settlement_item

      Given -> You cannot create another item with an overlapping time range for the same atlas_settlement_level_id
      Given I expect the next API call to return a status code of 400 and details of "a settlement item already exists for the provided settlement_id, atlas_settlement_level_id, and time"
      When I POST a settlement_item with the following properties:
        | settlement_id          | <last-settlement-id> |
        | settlement_level       | REGISTRATION         |
        |atlas_settlement_level_id | <last-atlas-settlement-level-id>              |
        | submitted_indicator    | true                 |
        | settlement_item_status | AWAITING_DATA        |
        | asset_type             | LOAD                 |
        | start_dttm_utc          | 2023-09-05T09:00:00.000Z                |
        | end_dttm_utc            | 2023-09-05T11:00:00.000Z                |
      Then the expected status should be returned

      Given -> But you can create another item with an overlapping time range with a different atlas_settlement_level_id
      When I POST a settlement_item with the following properties:
        | settlement_id          | <last-settlement-id> |
        | settlement_level       | REGISTRATION         |
        |atlas_settlement_level_id | <uuid>              |
        | submitted_indicator    | false                 |
        | settlement_item_status | AWAITING_DATA        |
        | asset_type             | LOAD                 |
        | start_dttm_utc          | 2023-09-05T09:00:00.000Z                |
        | end_dttm_utc            | 2023-09-05T11:00:00.000Z                |
      Then the response should include the new settlement_item

      Given -> Cleanup
      When I DELETE the settlement
      Then the DELETE settlement details should specify 2 settlement items and 0 settlement item intervals


    Scenario: Multiple items can be created with the same atlas_settlement_level_id and overlapping time ranges under different parent settlements

      Given -> Create the first settlement
      When I POST a settlement with the following properties:
        | settlement_type         | EVENT             |
        | settlement_subtype      | AESO event                           |
        | start_dttm_utc          | 2023-09-05T07:00:00.000Z                |
        | end_dttm_utc            | 2023-09-06T07:00:00.000Z                |
        | event_id                | <uuid> |
        | description             | QAA test: create settlement                        |
        | settlement_status       | PRELIMINARY                         |
        | business_process_status | NOT_STARTED                         |
        | source_system_type      | NGP                                 |
      Then the response should include the new settlement

      Given -> Create an item for the third hour
      When I POST a settlement_item with the following properties:
        | settlement_id          | <last-settlement-id> |
        | settlement_level       | REGISTRATION         |
        |atlas_settlement_level_id | <uuid>              |
        | submitted_indicator    | false                 |
        | settlement_item_status | AWAITING_DATA        |
        | asset_type             | LOAD                 |
        | start_dttm_utc          | 2023-09-05T09:00:00.000Z                |
        | end_dttm_utc            | 2023-09-05T10:00:00.000Z                |
      Then the response should include the new settlement_item

      Given -> Create the second settlement
      When I POST a settlement with the following properties:
        | settlement_type         | EVENT             |
        | settlement_subtype      | AESO event                           |
        | start_dttm_utc          | 2023-09-05T07:00:00.000Z                |
        | end_dttm_utc            | 2023-09-06T07:00:00.000Z                |
        | event_id                | <uuid> |
        | description             | QAA test: create settlement                        |
        | settlement_status       | PRELIMINARY                         |
        | business_process_status | NOT_STARTED                         |
        | source_system_type      | NGP                                 |
      Then the response should include the new settlement

      Given -> Create an item for the third hour with the same atlas_settlement_level_id
      When I POST a settlement_item with the following properties:
        | settlement_id          | <last-settlement-id> |
        | settlement_level       | REGISTRATION         |
        |atlas_settlement_level_id | <last-atlas-settlement-level-id>              |
        | submitted_indicator    | false                 |
        | settlement_item_status | AWAITING_DATA        |
        | asset_type             | LOAD                 |
        | start_dttm_utc          | 2023-09-05T09:00:00.000Z                |
        | end_dttm_utc            | 2023-09-05T10:00:00.000Z                |
      Then the response should include the new settlement_item

      Given -> Cleanup
      Given I DELETE all settlements created in this scenario


    Scenario: item's date range must fall within the parent settlement's time range

      Given -> Create the settlement
      When I POST a settlement with the following properties:
        | settlement_type         | EVENT             |
        | settlement_subtype      | AESO event                           |
        | start_dttm_utc          | 2023-09-05T07:00:00.000Z                |
        | end_dttm_utc            | 2023-09-06T07:00:00.000Z                |
        | event_id                | <uuid> |
        | description             | QAA test: create settlement                        |
        | settlement_status       | PRELIMINARY                         |
        | business_process_status | NOT_STARTED                         |
        | source_system_type      | NGP                                 |
      Then the response should include the new settlement

      Given -> You cannot create an item whose start-time is before the settlement start-time
      Given I expect the next API call to return a status code of 400 and details of "item start_dttm_utc must be within bounds of settlement start and end dates"
      When I POST a settlement_item with the following properties:
        | settlement_id          | <last-settlement-id> |
        | settlement_level       | REGISTRATION         |
        |atlas_settlement_level_id | <uuid>              |
        | submitted_indicator    | false                 |
        | settlement_item_status | AWAITING_DATA        |
        | asset_type             | LOAD                 |
        | start_dttm_utc          | 2023-09-05T06:59:00.000Z                |
        | end_dttm_utc            | 2023-09-06T07:00:00.000Z                |
      Then the expected status should be returned

      Given -> You cannot create an item whose end-time is after the settlement end-time
      Given I expect the next API call to return a status code of 400 and details of "item end_dttm_utc must be within bounds of settlement start and end dates"
      When I POST a settlement_item with the following properties:
        | settlement_id          | <last-settlement-id> |
        | settlement_level       | REGISTRATION         |
        |atlas_settlement_level_id | <uuid>              |
        | submitted_indicator    | false                 |
        | settlement_item_status | AWAITING_DATA        |
        | asset_type             | LOAD                 |
        | start_dttm_utc          | 2023-09-05T07:00:00.000Z                |
        | end_dttm_utc            | 2023-09-06T07:01:00.000Z                |
      Then the expected status should be returned

      Given -> You cannot create an item whose times are both beyond the settlement times
      Given I expect the next API call to return a status code of 400 and details of "item start_dttm_utc must be within bounds of settlement start and end dates"
      When I POST a settlement_item with the following properties:
        | settlement_id          | <last-settlement-id> |
        | settlement_level       | REGISTRATION         |
        |atlas_settlement_level_id | <uuid>              |
        | submitted_indicator    | false                 |
        | settlement_item_status | AWAITING_DATA        |
        | asset_type             | LOAD                 |
        | start_dttm_utc          | 2023-09-05T01:00:00.000Z                |
        | end_dttm_utc            | 2023-09-06T23:00:00.000Z                |
      Then the expected status should be returned

      Given -> You cannot create an item whose times are both before the settlement start-time
      Given I expect the next API call to return a status code of 400 and details of "item start_dttm_utc must be within bounds of settlement start and end dates"
      When I POST a settlement_item with the following properties:
        | settlement_id          | <last-settlement-id> |
        | settlement_level       | REGISTRATION         |
        |atlas_settlement_level_id | <uuid>              |
        | submitted_indicator    | false                 |
        | settlement_item_status | AWAITING_DATA        |
        | asset_type             | LOAD                 |
        | start_dttm_utc          | 2023-09-01T00:00:00.000Z                |
        | end_dttm_utc            | 2023-09-03T00:00:00.000Z                |
      Then the expected status should be returned

      Given -> You cannot create an item whose times are both after the settlement end-time
      Given I expect the next API call to return a status code of 400 and details of "item start_dttm_utc must be within bounds of settlement start and end dates"
      When I POST a settlement_item with the following properties:
        | settlement_id          | <last-settlement-id> |
        | settlement_level       | REGISTRATION         |
        |atlas_settlement_level_id | <uuid>              |
        | submitted_indicator    | false                 |
        | settlement_item_status | AWAITING_DATA        |
        | asset_type             | LOAD                 |
        | start_dttm_utc          | 2023-10-01T00:00:00.000Z                |
        | end_dttm_utc            | 2023-10-03T00:00:00.000Z                |
      Then the expected status should be returned

      Given -> But you can create an item whose time range is exactly equal to the settlement
      When I POST a settlement_item with the following properties:
        | settlement_id          | <last-settlement-id> |
        | settlement_level       | REGISTRATION         |
        |atlas_settlement_level_id | <uuid>              |
        | submitted_indicator    | false                 |
        | settlement_item_status | AWAITING_DATA        |
        | asset_type             | LOAD                 |
        | start_dttm_utc          | 2023-09-05T07:00:00.000Z                |
        | end_dttm_utc            | 2023-09-06T07:00:00.000Z                |
      Then the response should include the new settlement_item

      Given -> You can also change the settlement dates to a range outside of the items
      When I PUT the settlement with new values:
        | settlement_id         | <last-settlement-id>             |
        | settlement_type         | EVENT             |
        | settlement_subtype      | AESO event                           |
        | start_dttm_utc          | 2023-03-20T01:00:00.000Z                |
        | end_dttm_utc            | 2023-03-21T01:00:00.000Z                |
        | event_id                | <last-event-id> |
        | description             | QAA test: update dates   |
        | settlement_status       | PRELIMINARY                         |
        | business_process_status | NOT_STARTED                         |
        | source_system_type      | NGP                                 |
        | change_comments   | Update dates    |

      Then the response should include the updated settlement

      Given -> Cleanup
      When I DELETE the settlement
      Then the DELETE settlement details should specify 1 settlement items and 0 settlement item intervals


  Scenario: Duplicate atlas_settlement_level_id and overlapping date range is not allowed PUT

    Given -> POST a settlement and item
    When I POST a settlement with the following properties:
      | settlement_type         | ONGOING_DATA_SUBMISSION             |
      | settlement_subtype      | TVA event                           |
      | start_dttm_utc          | 2023-09-05T08:00:00.000Z                |
      | end_dttm_utc            | 2023-09-05T08:30:00.000Z                |
      | event_id                | <uuid> |
      | description             | QAA test: create settlement                        |
      | settlement_status       | PRELIMINARY                         |
      | business_process_status | NOT_STARTED                         |
      | source_system_type      | NGP                                 |
    Then the response should include the new settlement

    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | REGISTRATION         |
      |atlas_settlement_level_id | 15afb028-0855-48a6-9320-9d4e5dee11bb              |
      | submitted_indicator    | false                 |
      | settlement_item_status | AWAITING_DATA        |
      | asset_type             | LOAD                 |
      | start_dttm_utc          | 2023-09-05T08:00:00.000Z                |
      | end_dttm_utc            | 2023-09-05T08:30:00.000Z                |
    Then the response should include the new settlement_item

    Given -> POST another item with the same time range but a different atlas_settlement_level_id
    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | REGISTRATION         |
      |atlas_settlement_level_id | 25afb028-0855-48a6-9320-9d4e5dee11bb              |
      | submitted_indicator    | false                 |
      | settlement_item_status | AWAITING_DATA        |
      | asset_type             | LOAD                 |
      | start_dttm_utc          | 2023-09-05T08:00:00.000Z                |
      | end_dttm_utc            | 2023-09-05T08:30:00.000Z                |
    Then the response should include the new settlement_item

    Given -> You can't use PUT to change the atlas_settlement_level_id and create an overlapping item
    Given I expect the next API call to return a status code of 400 and details of "a settlement item already exists for the provided settlement_id, atlas_settlement_level_id, and time"
    When I PUT the settlement_item with new values:
      | settlement_id          | <last-settlement-id> |
      | settlement_item_id     | <last-settlement-item-id>   |
      | settlement_level       | REGISTRATION         |
      |atlas_settlement_level_id | 15afb028-0855-48a6-9320-9d4e5dee11bb              |
      | submitted_indicator    | false                 |
      | settlement_item_status | AWAITING_DATA        |
      | asset_type             | LOAD                 |
      | start_dttm_utc          | 2023-09-05T08:00:00.000Z                |
      | end_dttm_utc            | 2023-09-05T08:30:00.000Z                |
      | change_comments        | Change  atlas_settlement_level_id      |
    Then the expected status should be returned

    # PATCH: atlas_settlement_level_id is not supported
    Given I expect the next API call to return a status code of 400 and details of "Not a valid patch_type"
    When I PATCH the settlement_item with new values:
      | settlement_item_id    | <last-settlement-item-id>                                   |
      | atlas_settlement_level_id  | <uuid> |
      | change_comments  | Error case |
    Then the expected status should be returned

    Given -> Cleanup
    When I DELETE the settlement
    Then the DELETE settlement details should specify 2 settlement items and 0 settlement item intervals
