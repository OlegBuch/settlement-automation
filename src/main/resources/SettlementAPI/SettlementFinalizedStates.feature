Feature: Feature test for settlement finalized states

  Reference: <CONFLUENCE_URL>/display/PMENA/Settlement+API+-+Technical+Design
  Covers scenarios in: featureSettlementTest/src/it/scala/com/enelx/settlement/featuretests/SettlementFinalizedStatesFeature.scala


  Background:
    Given I start with an empty context
    And I log in as a settlement API admin

  Scenario: Settlement lifecycle: FINALIZED or NO_DATA status

    When I POST a settlement with the following properties:
      | settlement_type         | ONGOING_DATA_SUBMISSION        |
      | settlement_subtype      | TVA event                      |
      | start_dttm_utc          | 2023-09-05T08:00:00Z           |
      | end_dttm_utc            | 2023-09-05T09:00:00Z           |
      | event_id                | <uuid>                         |
      | description             | QAA test: Settlement lifecycle |
      | settlement_status       | AWAITING_DATA                  |
      | business_process_status | NOT_STARTED                    |
      | source_system_type      | NGP                            |
    Then the response should include the new settlement

    When I POST a settlement_item with the following properties:
      | settlement_id         | <last-settlement-id>             |
      | settlement_level      | REGISTRATION                           |
      | atlas_settlement_level_id          | <uuid>                |
      | submitted_indicator            | true                |
      | settlement_item_status                | FINALIZED |
      | asset_type                            | LOAD                   |
      | start_dttm_utc          | 2023-09-05T08:00:00Z           |
      | end_dttm_utc            | 2023-09-05T08:30:00Z           |
    Then the response should include the new settlement_item

    # FINALIZE the settlement
    When I PUT the settlement with new values:
      | settlement_id         | <last-settlement-id>             |
      | settlement_type         | ONGOING_DATA_SUBMISSION        |
      | settlement_subtype      | TVA event                      |
      | start_dttm_utc          | 2023-09-05T08:00:00Z           |
      | end_dttm_utc            | 2023-09-05T09:00:00Z           |
      | event_id                | <last-event-id>                         |
      | description             | QAA test: Settlement lifecycle |
      | settlement_status | FINALIZED                  |
      | business_process_status | NOT_STARTED                    |
      | source_system_type      | NGP                            |
      | change_comments   | AWAITING_DATA -> FINALIZED |
    Then the response should include the updated settlement
    And GET settlement should return the updated entity

    # Un-finalize the item and try to update it. PUT should still fail.
    Given I expect the next API call to return a status code of 200 and details of "Successfully updated the settlement_item_status to PRELIMINARY for settlement_item_id"
    When I PATCH the settlement_item with new values:
      | settlement_item_id     | <last-settlement-item-id>  |
      | settlement_item_status | PRELIMINARY                  |
      | change_comments        | FINALIZED -> PRELIMINARY |
    Then the expected status should be returned

    Given I expect the next API call to return a status code of 400 and details of "cannot update SettlementItem for a Settlement which is already FINALIZED"
    When I PUT the settlement_item with new values:
      | settlement_id          | <last-settlement-id> |
      | settlement_item_id     | <last-settlement-item-id>  |
      | settlement_level       | REGISTRATION         |
      | atlas_settlement_level_id    | <last-atlas-settlement-level-id>             |
      | submitted_indicator    | false                 |
      | settlement_item_status | PRELIMINARY                  |
      | asset_type             | LOAD                 |
      | change_comments        | Change submitted_indicator |
    Then the expected status should be returned

      # Try to revert status via PUT
    Given I expect the next API call to return a status code of 400 and details of "cannot update a settlement_status which is already in a FINALIZED state"
    When I PUT the settlement with new values:
      | settlement_id         | <last-settlement-id>             |
      | settlement_type         | ONGOING_DATA_SUBMISSION        |
      | settlement_subtype      | TVA event                      |
      | start_dttm_utc          | 2023-09-05T08:00:00Z           |
      | end_dttm_utc            | 2023-09-05T09:00:00Z           |
      | event_id                | <last-event-id>                         |
      | description             | QAA test: Settlement lifecycle |
      | settlement_status | AWAITING_DATA                  |
      | business_process_status | NOT_STARTED                    |
      | source_system_type      | NGP                            |
      | change_comments   | FINALIZED -> AWAITING_DATA |
    Then the expected status should be returned

      # Try to update another field via PUT
    Given I expect the next API call to return a status code of 400 and details of "cannot update a settlement_status which is already in a FINALIZED state"
    When I PUT the settlement with new values:
      | settlement_id         | <last-settlement-id>             |
      | settlement_type         | ONGOING_DATA_SUBMISSION        |
      | settlement_subtype      | TVA event                      |
      | start_dttm_utc          | 2023-09-05T08:00:00Z           |
      | end_dttm_utc            | 2023-09-05T09:00:00Z           |
      | event_id                | <last-event-id>                         |
      | description             | QAA test: Settlement lifecycle |
      | settlement_status | FINALIZED                  |
      | business_process_status | NOT_STARTED                    |
      | source_system_type | CLASSIC_DR                |
      | change_comments    | Change source_system_type |
    Then the expected status should be returned

    # Try to post a settlement item
    Given I expect the next API call to return a status code of 400 and details of "cannot create a settlement_item for a settlement with a settlement_status of FINALIZED"
    When I POST a settlement_item with the following properties:
      | settlement_id         | <last-settlement-id>             |
      | settlement_level      | REGISTRATION                           |
      | atlas_settlement_level_id          | <last-atlas-settlement-level-id>                |
      | registration_set_id      |      <uuid>                |
      | portfolio_id                  |      <uuid>                |
      | submitted_indicator            | true                |
      | settlement_item_status                | AWAITING_DATA |
      | asset_type                            | LOAD                   |
      | start_dttm_utc          | 2023-09-05T08:30:00Z           |
      | end_dttm_utc            | 2023-09-05T09:00:00Z           |
    Then the expected status should be returned

    # Use PATCH to revert the settlement status
    When I PATCH the settlement with new values:
      | settlement_id         | <last-settlement-id>             |
      | settlement_status | AWAITING_DATA              |
      | change_comments   | FINALIZED -> AWAITING_DATA |
    Then the response should include the updated settlement
    * GET settlement should return the updated entity
    * changes should be recorded in the settlement audit log

    # Now you can PUT updated fields in the settlement
    When I PUT the settlement with new values:
      | settlement_id         | <last-settlement-id>             |
      | settlement_type         | ONGOING_DATA_SUBMISSION        |
      | settlement_subtype      | TVA event                      |
      | start_dttm_utc          | 2023-09-05T08:00:00Z           |
      | end_dttm_utc            | 2023-09-05T09:00:00Z           |
      | event_id                | <last-event-id>                         |
      | description             | QAA test: Settlement lifecycle |
      | settlement_status | AWAITING_DATA                  |
      | business_process_status | NOT_STARTED                    |
      | source_system_type | CLASSIC_DR                |
      | change_comments    | Change source_system_type |
    Then the response should include the updated settlement
    * GET settlement should return the updated entity
    * changes should be recorded in the settlement audit log

    # And you can update an existing settlement item
    When I PUT the settlement_item with new values:
      | settlement_id          | <last-settlement-id> |
      | settlement_item_id     | <last-settlement-item-id>  |
      | settlement_level       | REGISTRATION         |
      | atlas_settlement_level_id          | <uuid>                |
      | registration_set_id      |      <uuid>                |
      | portfolio_id                  |      <uuid>                |
      | start_dttm_utc          | 2023-09-05T08:00:00Z           |
      | end_dttm_utc            | 2023-09-05T08:30:00Z           |
      | submitted_indicator    | true                 |
      | settlement_item_status | PRELIMINARY                  |
      | asset_type             | LOAD_APPARENT                 |
      | change_comments        | Change asset_type |
    Then the response should include the updated settlement_item

    # And you can POST a new settlement item
    When I POST a settlement_item with the following properties:
      | settlement_id         | <last-settlement-id>             |
      | settlement_level      | REGISTRATION                           |
      | atlas_settlement_level_id          | <last-atlas-settlement-level-id>                |
      | submitted_indicator            | true                |
      | settlement_item_status                | AWAITING_DATA |
      | asset_type                            | LOAD                   |
      | start_dttm_utc          | 2023-09-05T08:30:00Z           |
      | end_dttm_utc            | 2023-09-05T09:00:00Z           |
    Then the response should include the new settlement_item

    # Cleanup
    Given I DELETE the settlement

    # Now test NO_DATA as a final state
    When I POST a settlement with the following properties:
      | settlement_type         | ONGOING_DATA_SUBMISSION        |
      | settlement_subtype      | TVA event                      |
      | start_dttm_utc          | 2023-09-05T08:00:00Z           |
      | end_dttm_utc            | 2023-09-05T09:00:00Z           |
      | event_id                | <uuid>                         |
      | description             | QAA test: Settlement lifecycle |
      | settlement_status       | AWAITING_DATA                  |
      | business_process_status | NOT_STARTED                    |
      | source_system_type      | NGP                            |
    Then the response should include the new settlement

    When I POST a settlement_item with the following properties:
      | settlement_id         | <last-settlement-id>             |
      | settlement_level      | REGISTRATION                           |
      | atlas_settlement_level_id          | <uuid>                |
      | submitted_indicator            | true                |
      | settlement_item_status                | FINALIZED |
      | asset_type                            | LOAD                   |
      | start_dttm_utc          | 2023-09-05T08:00:00Z           |
      | end_dttm_utc            | 2023-09-05T08:30:00Z           |
    Then the response should include the new settlement_item

    # Set the settlement to NO_DATA
    When I PUT the settlement with new values:
      | settlement_id         | <last-settlement-id>             |
      | settlement_type         | ONGOING_DATA_SUBMISSION        |
      | settlement_subtype      | TVA event                      |
      | start_dttm_utc          | 2023-09-05T08:00:00Z           |
      | end_dttm_utc            | 2023-09-05T09:00:00Z           |
      | event_id                | <last-event-id>                         |
      | description             | QAA test: Settlement lifecycle |
      | settlement_status       | NO_DATA                  |
      | business_process_status | NOT_STARTED                    |
      | source_system_type      | NGP                            |
      | change_comments   | AWAITING_DATA -> NO_DATA |
    Then the response should include the updated settlement
    And GET settlement should return the updated entity

    # Un-finalize the item. It can be updated if settlement is still NO_DATA.
    Given I expect the next API call to return a status code of 200 and details of "Successfully updated the settlement_item_status to PRELIMINARY for settlement_item_id"
    When I PATCH the settlement_item with new values:
      | settlement_item_id     | <last-settlement-item-id>  |
      | settlement_item_status | PRELIMINARY                  |
      | change_comments        | FINALIZED -> PRELIMINARY |
    Then the expected status should be returned

    When I PUT the settlement_item with new values:
      | settlement_id          | <last-settlement-id> |
      | settlement_item_id     | <last-settlement-item-id>  |
      | settlement_level       | REGISTRATION         |
      | atlas_settlement_level_id          | <uuid>                |
      | registration_set_id      |      <uuid>                |
      | portfolio_id                  |      <uuid>                |
      | submitted_indicator    | true                 |
      | settlement_item_status | PRELIMINARY                  |
      | asset_type             | LOAD_APPARENT                 |
      | change_comments        | Change asset_type |
    Then the response should include the updated settlement_item

    Given I expect the next API call to return a status code of 400 and details of "cannot update a settlement_status which is already in a NO_DATA state"
    When I PUT the settlement with new values:
      | settlement_id         | <last-settlement-id>             |
      | settlement_type         | ONGOING_DATA_SUBMISSION        |
      | settlement_subtype      | TVA event                      |
      | start_dttm_utc          | 2023-09-05T08:00:00Z           |
      | end_dttm_utc            | 2023-09-05T09:00:00Z           |
      | event_id                | <last-event-id>                         |
      | description             | QAA test: Settlement lifecycle |
      | settlement_status       | NO_DATA                  |
      | business_process_status | NOT_STARTED                    |
      | source_system_type | CLASSIC_DR                |
      | change_comments    | Change source_system_type |
    Then the expected status should be returned

     # Try to post a settlement item
    Given I expect the next API call to return a status code of 400 and details of "cannot create a settlement_item for a settlement with a settlement_status of NO_DATA"
    When I POST a settlement_item with the following properties:
      | settlement_id         | <last-settlement-id>             |
      | settlement_level      | REGISTRATION                           |
      | atlas_settlement_level_id          | <last-atlas-settlement-level-id>                |
      | submitted_indicator            | true                |
      | settlement_item_status                | AWAITING_DATA |
      | asset_type                            | LOAD                   |
      | start_dttm_utc          | 2023-09-05T08:30:00Z           |
      | end_dttm_utc            | 2023-09-05T09:00:00Z           |
    Then the expected status should be returned

  # Use PATCH to revert the status
    When I PATCH the settlement with new values:
      | settlement_id         | <last-settlement-id>             |
      | settlement_status | AWAITING_DATA              |
      | change_comments   | NO_DATA -> AWAITING_DATA |
    Then the response should include the updated settlement
    * GET settlement should return the updated entity
    * changes should be recorded in the settlement audit log

    # Now you can PUT updated fields
    When I PUT the settlement with new values:
      | settlement_id         | <last-settlement-id>             |
      | settlement_type         | ONGOING_DATA_SUBMISSION        |
      | settlement_subtype      | TVA event                      |
      | start_dttm_utc          | 2023-09-05T08:00:00Z           |
      | end_dttm_utc            | 2023-09-05T09:00:00Z           |
      | event_id                | <last-event-id>                         |
      | description             | QAA test: Settlement lifecycle |
      | settlement_status       | AWAITING_DATA                  |
      | business_process_status | NOT_STARTED                    |
      | source_system_type | CLASSIC_DR                |
      | change_comments    | Change source_system_type |
    Then the response should include the updated settlement
    * GET settlement should return the updated entity
    * changes should be recorded in the settlement audit log

  # Cleanup
    Given I DELETE the settlement


  Scenario: Cannot finalize a settlement until all items are finalized

      Given I want to log all API requests
      Given I want to log all API responses

    When I POST a settlement with the following properties:
      | settlement_type         | ONGOING_DATA_SUBMISSION                  |
      | settlement_subtype      | TVA event                                |
      | start_dttm_utc          | 2023-09-05T08:00:00Z                     |
      | end_dttm_utc            | 2023-09-05T08:30:00Z                     |
      | event_id                | <uuid>                                   |
      | description             | QAA test: settlement for finalized states |
      | settlement_status       | PRELIMINARY                              |
      | business_process_status | NOT_STARTED                              |
      | source_system_type      | NGP                                      |
    Then the response should include the new settlement

    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | REGISTRATION         |
      | atlas_settlement_level_id    | <uuid>            |
      | submitted_indicator    | true                 |
      | settlement_item_status | AWAITING_DATA        |
      | asset_type             | LOAD                 |
      | start_dttm_utc          | 2023-09-05T08:00:00Z           |
      | end_dttm_utc            | 2023-09-05T08:30:00Z           |
    Then the response should include the new settlement_item
    Given I save the settlement_item id for later use with the tag item1_id

      When I POST a settlement_item with the following properties:
        | settlement_id          | <last-settlement-id> |
        | settlement_level       | REGISTRATION         |
        | atlas_settlement_level_id    | <uuid>            |
        | submitted_indicator    | true                 |
        | settlement_item_status | AWAITING_DATA        |
        | asset_type             | LOAD                 |
        | start_dttm_utc          | 2023-09-05T08:00:00Z           |
        | end_dttm_utc            | 2023-09-05T08:30:00Z           |
      Then the response should include the new settlement_item
      Given I save the settlement_item id for later use with the tag item2_id

      Given I expect the next API call to return a status code of 400 and details of "cannot update settlement_status to FINALIZED until all connected SettlementItems have a settlement_item_status of FINALIZED or NO_DATA"
      When I PUT the settlement with new values:
        | settlement_id         | <last-settlement-id>             |
        | settlement_type         | ONGOING_DATA_SUBMISSION                  |
        | settlement_subtype      | TVA event                                |
        | start_dttm_utc          | 2023-09-05T08:00:00Z                     |
        | end_dttm_utc            | 2023-09-05T08:30:00Z                     |
        | settlement_status | FINALIZED                  |
        | business_process_status | NOT_STARTED                              |
        | change_comments   | AWAITING_DATA -> FINALIZED |
      Then the expected status should be returned

      # Finalize just one of the two items
      Given I expect the next API call to return a status code of 200 and details of "Successfully updated the settlement_item_status to FINALIZED for settlement_item_id"
      When I PATCH the settlement_item with new values:
        | settlement_item_id     | <item1_id> |
        | settlement_item_status | FINALIZED               |
        | change_comments        | finalized  |
      Then the expected status should be returned

      Given I expect the next API call to return a status code of 400 and details of "cannot update settlement_status to NO_DATA until all connected SettlementItems have a settlement_item_status of FINALIZED or NO_DATA"
      When I PUT the settlement with new values:
        | settlement_id         | <last-settlement-id>             |
        | settlement_type         | ONGOING_DATA_SUBMISSION                  |
        | settlement_subtype      | TVA event                                |
        | start_dttm_utc          | 2023-09-05T08:00:00Z                     |
        | end_dttm_utc            | 2023-09-05T08:30:00Z                     |
        | settlement_status | NO_DATA                  |
        | business_process_status | NOT_STARTED                              |
        | change_comments   | AWAITING_DATA -> FINALIZED |
      Then the expected status should be returned

      # Finalize the other item
      Given I expect the next API call to return a status code of 200 and details of "Successfully updated the settlement_item_status to NO_DATA for settlement_item_id"
      When I PATCH the settlement_item with new values:
        | settlement_item_id     | <item2_id> |
        | settlement_item_status | NO_DATA               |
        | change_comments        | no data  |
      Then the expected status should be returned

      When I PUT the settlement with new values:
        | settlement_id         | <last-settlement-id>             |
        | settlement_type         | ONGOING_DATA_SUBMISSION                  |
        | settlement_subtype      | TVA event                                |
        | start_dttm_utc          | 2023-09-05T08:00:00Z                     |
        | end_dttm_utc            | 2023-09-05T08:30:00Z                     |
        | settlement_status | NO_DATA                  |
        | business_process_status | NOT_STARTED                              |
        | change_comments   | AWAITING_DATA -> NO_DATA |
      Then the response should include the updated settlement

      # Cleanup
      When I DELETE the settlement
      Then the DELETE settlement details should specify 2 settlement items and 0 settlement item intervals
      And changes should be recorded in the settlement audit log
