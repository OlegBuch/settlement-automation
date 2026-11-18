Feature: Feature test for settlement item hierarchy

  ITAPPS-3869: update settlement API to optionally allow linking item to master item under different settlement

  Reference: <CONFLUENCE_URL>/display/PMENA/Settlement+API+-+Technical+Design


  Background:
    Given I start with an empty context
    And I log in as a settlement API admin


  Scenario: Basic scenario for settlement hierarchy

    Given I want to log all API requests
    Given I want to log all API responses

    When I POST a settlement with the following properties:
      | settlement_type         | ONGOING_DATA_SUBMISSION                  |
      | settlement_subtype      | TVA event                                |
      | start_dttm_utc          | 2023-09-05T08:00:00.000Z                      |
      | end_dttm_utc            | 2023-09-05T08:30:00.000Z                      |
      | event_id                | <uuid>                                   |
      | description             | QAA test: Basic scenario for settlement hierarchy |
      | settlement_status       | PRELIMINARY                              |
      | business_process_status | NOT_STARTED                              |
      | source_system_type      | NGP                                      |
    Then the response should include the new settlement

    # POST Parent Item 1
    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | PORTFOLIO            |
      | settlement_level_id    | Level 1, Item 1      |
      | submitted_indicator    | true                 |
      | settlement_item_status | AWAITING_DATA        |
      | atlas_settlement_level_id | <uuid>            |
      | asset_type             | LOAD                 |
      | start_dttm_utc          | 2023-09-05T08:00:00.000Z                      |
      | end_dttm_utc            | 2023-09-05T08:30:00.000Z                      |
    Then the response should include the new settlement_item
    Given I save the settlement_item id for later use with the tag Level1_Item1_id

    # POST Child Item 1 (child of Parent 1)
    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | master_settlement_item_id |    <Level1_Item1_id>               |
      | settlement_level       | REGISTRATION         |
      | settlement_level_id    | Level 2, Item 1             |
      | submitted_indicator    | true                 |
      | settlement_item_status | AWAITING_DATA        |
      | atlas_settlement_level_id | <uuid>            |
      | registration_set_id      |      <uuid>                |
      | portfolio_id                  |      <uuid>                |
      | asset_type             | DER_FUEL_CELL                 |
      | start_dttm_utc          | 2023-09-05T08:00:00.000Z                      |
      | end_dttm_utc            | 2023-09-05T08:30:00.000Z                      |
    Then the response should include the new settlement_item
    And GET settlement_item should return the new entity

    # POST Child Item 2 (child of Parent 1)
    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | master_settlement_item_id |    <Level1_Item1_id>               |
      | settlement_level       | REGISTRATION         |
      | settlement_level_id    | Level 2, Item 2             |
      | submitted_indicator    | false                 |
      | settlement_item_status | PRELIMINARY        |
      | atlas_settlement_level_id | <uuid>            |
      | registration_set_id      |      <uuid>                |
      | portfolio_id                  |      <uuid>                |
      | asset_type             | DER_BESS                 |
      | start_dttm_utc          | 2023-09-05T08:00:00.000Z                      |
      | end_dttm_utc            | 2023-09-05T08:30:00.000Z                      |
    Then the response should include the new settlement_item
    And GET settlement_item should return the new entity

    When I call GET settlement_item for saved id Level1_Item1_id and include_sub_settlement_items = true
    Then the returned settlement item should contain the complete item hierarchy

    # POST Parent Item 2
    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | PORTFOLIO            |
      | settlement_level_id    | Level 1, Item 2      |
      | submitted_indicator    | true                 |
      | settlement_item_status | AWAITING_DATA        |
      | atlas_settlement_level_id | <uuid>            |
      | registration_set_id      |      <uuid>                |
      | portfolio_id                  |      <uuid>                |
      | asset_type             | LOAD                 |
      | start_dttm_utc          | 2023-09-05T08:00:00.000Z                      |
      | end_dttm_utc            | 2023-09-05T08:30:00.000Z                     |
    Then the response should include the new settlement_item
    Given I save the settlement_item id for later use with the tag Level1_Item2_id

    # POST Child Item 3 (child of Parent 2)
    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | master_settlement_item_id |    <Level1_Item2_id>               |
      | settlement_level       | REGISTRATION         |
      | settlement_level_id    | Level 2, Item 3             |
      | submitted_indicator    | false                 |
      | settlement_item_status | PRELIMINARY        |
      | atlas_settlement_level_id | <uuid>            |
      | registration_set_id      |      <uuid>                |
      | portfolio_id                  |      <uuid>                |
      | asset_type             | DER_BESS                 |
      | start_dttm_utc          | 2023-09-05T08:00:00.000Z                     |
      | end_dttm_utc            | 2023-09-05T08:30:00.000Z                     |
    Then the response should include the new settlement_item

    When I call GET settlement_item for saved id Level1_Item2_id and include_sub_settlement_items = true
    Then the returned settlement item should contain the complete item hierarchy

      # PUT: verify you can update a sub-item
    When I PUT the settlement_item with new values:
      | settlement_id          | <last-settlement-id> |
      | settlement_item_id     | <last-settlement-item-id>  |
      | master_settlement_item_id |    <Level1_Item2_id>               |
      | settlement_level       | REGISTRATION         |
      | settlement_level_id    | Level 2, Item 3             |
      | submitted_indicator    | false                 |
      | settlement_item_status | PRELIMINARY        |
      | atlas_settlement_level_id | <uuid>            |
      | registration_set_id      |      <uuid>                |
      | portfolio_id                  |      <uuid>                |
      | asset_type             | DER_FUEL_CELL                 |
      | start_dttm_utc          | 2023-09-05T08:00:00.000Z                     |
      | end_dttm_utc            | 2023-09-05T08:30:00.000Z                     |
      | change_comments        | Update asset type |
    Then the response should include the updated settlement_item
    * GET settlement_item should return the updated entity
    * changes should be recorded in the settlement_item audit log

      # PATCH: Move the child to the other parent
    Given I expect the next API call to return a status code of 200 and details of "Successfully updated the master_settlement_item_id"
    When I PATCH the settlement_item with new values:
      | settlement_item_id     | <last-settlement-item-id>  |
      | master_settlement_item_id |    <Level1_Item1_id>               |
      | change_comments        | Move to other parent |
    Then the expected status should be returned
    * GET settlement_item should return the updated entity
    * changes should be recorded in the settlement_item audit log

    When I call GET settlement_item for saved id Level1_Item1_id and include_sub_settlement_items = true
    Then the returned settlement item should contain the complete item hierarchy

    Given  I expect the next API call to return a status code of 404 and details of "The requested master_settlement_item or sub_settlement_items do not exist"
    When I call GET settlement_item for saved id Level1_Item2_id and include_sub_settlement_items = true
    Then the expected status should be returned

    When I call GET settlement_item for saved id Level1_Item2_id and include_sub_settlement_items = false
    Then the returned settlement item should only return the master item

      # DELETE
    When I DELETE the settlement
    Then the DELETE settlement details should specify 5 settlement items and 0 settlement item intervals
    And changes should be recorded in the settlement audit log

      # Should not be able to access any items under a deleted settlement
    Given I expect the next API call to return a status code of 404 and details of "no settlement item found for settlement item id"
    When I call GET settlement_item for saved id Level1_Item1_id and include_sub_settlement_items = true
    Then the expected status should be returned

    Given I expect the next API call to return a status code of 404 and details of "no settlement item found for settlement item id"
    When I call GET settlement_item for saved id Level1_Item1_id and include_sub_settlement_items = false
    Then the expected status should be returned


  Scenario: Master item is deleted

    Given I want to log all API requests
    Given I want to log all API responses

    When I POST a settlement with the following properties:
      | settlement_type         | ONGOING_DATA_SUBMISSION                  |
      | settlement_subtype      | TVA event                                |
      | start_dttm_utc          | 2023-09-05T08:00:00.000Z                     |
      | end_dttm_utc            | 2023-09-05T08:30:00.000Z                     |
      | event_id                | <uuid>                                   |
      | description             | QAA test: Basic scenario for settlement hierarchy |
      | settlement_status       | PRELIMINARY                              |
      | business_process_status | NOT_STARTED                              |
      | source_system_type      | NGP                                      |
    Then the response should include the new settlement

    # POST Parent
    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | PORTFOLIO            |
      | settlement_level_id    | Level 1              |
      | atlas_settlement_level_id | <uuid>            |
      | registration_set_id      |      <uuid>                |
      | portfolio_id                  |      <uuid>                |
      | submitted_indicator    | true                 |
      | settlement_item_status | AWAITING_DATA        |
      | asset_type             | LOAD                 |
      | start_dttm_utc          | 2023-09-05T08:00:00.000Z                     |
      | end_dttm_utc            | 2023-09-05T08:30:00.000Z                     |
    Then the response should include the new settlement_item
    Given I save the settlement_item id for later use with the tag Level1_id

    # POST Child
    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | master_settlement_item_id |    <Level1_id>               |
      | settlement_level       | REGISTRATION         |
      | settlement_level_id    | Level 2, Item 1             |
      | atlas_settlement_level_id | <uuid>            |
      | registration_set_id      |      <uuid>                |
      | portfolio_id                  |      <uuid>                |
      | submitted_indicator    | true                 |
      | settlement_item_status | AWAITING_DATA        |
      | asset_type             | DER_FUEL_CELL                 |
      | start_dttm_utc          | 2023-09-05T08:00:00.000Z                     |
      | end_dttm_utc            | 2023-09-05T08:30:00.000Z                     |
    Then the response should include the new settlement_item
    * I save the settlement_item id for later use with the tag Level2_id
    * GET settlement_item should return the new entity

    When I call GET settlement_item for saved id Level1_id and include_sub_settlement_items = true
    Then the returned settlement item should contain the complete item hierarchy

    Given I set the last settlement_item id from the tag Level1_id
    And I DELETE the settlement_item
    Then the DELETE settlement_item details should specify 2 settlement items and 0 settlement item intervals
    And changes should be recorded in the settlement_item audit log

    Given I expect the next API call to return a status code of 404 and details of "no settlement item found for settlement item id"
    When I call GET settlement_item for saved id Level1_id and include_sub_settlement_items = false
    Then the expected status should be returned

    Given I expect the next API call to return a status code of 404 and details of "no settlement item found for settlement item id"
    When I call GET settlement_item for saved id Level1_id and include_sub_settlement_items = true
    Then the expected status should be returned

        # Verify that child item was deleted
    Given I expect the next API call to return a status code of 404 and details of "no settlement item found for settlement item id"
    When I call GET settlement_item for saved id Level2_id and include_sub_settlement_items = true
    Then the expected status should be returned

    Given I expect the next API call to return a status code of 404 and details of "no settlement item found for settlement item id"
    When I call GET settlement_item for saved id Level2_id and include_sub_settlement_items = false
    Then the expected status should be returned

      # DELETE
    When I DELETE the settlement
    Then the DELETE settlement details should specify 0 settlement items and 0 settlement item intervals
    And changes should be recorded in the settlement audit log


  Scenario: Child items deleted

    Given I want to log all API requests
    Given I want to log all API responses

    When I POST a settlement with the following properties:
      | settlement_type         | ONGOING_DATA_SUBMISSION                  |
      | settlement_subtype      | TVA event                                |
      | start_dttm_utc          | 2023-09-05T08:00:00.000Z                     |
      | end_dttm_utc            | 2023-09-05T08:30:00.000Z                     |
      | event_id                | <uuid>                                   |
      | description             | QAA test: Basic scenario for settlement hierarchy |
      | settlement_status       | PRELIMINARY                              |
      | business_process_status | NOT_STARTED                              |
      | source_system_type      | NGP                                      |
    Then the response should include the new settlement

    # Create parent
    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | PORTFOLIO            |
      | settlement_level_id    | Level 1              |
      | submitted_indicator    | true                 |
      | settlement_item_status | AWAITING_DATA        |
      | atlas_settlement_level_id | <uuid>            |
      | registration_set_id      |      <uuid>                |
      | portfolio_id                  |      <uuid>                |
      | asset_type             | LOAD                 |
      | start_dttm_utc          | 2023-09-05T08:00:00.000Z                     |
      | end_dttm_utc            | 2023-09-05T08:30:00.000Z                     |
    Then the response should include the new settlement_item
    Given I save the settlement_item id for later use with the tag Level1_id

    # Create child
    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | master_settlement_item_id |    <Level1_id>               |
      | settlement_level       | REGISTRATION         |
      | settlement_level_id    | Level 2, Item 1             |
      | submitted_indicator    | true                 |
      | settlement_item_status | AWAITING_DATA        |
      | atlas_settlement_level_id | <uuid>            |
      | registration_set_id      |      <uuid>                |
      | portfolio_id                  |      <uuid>                |
      | asset_type             | DER_FUEL_CELL                 |
      | start_dttm_utc          | 2023-09-05T08:00:00.000Z                     |
      | end_dttm_utc            | 2023-09-05T08:30:00.000Z                     |
    Then the response should include the new settlement_item
    Given I save the settlement_item id for later use with the tag Level2_Item1_id

    # Create another child
    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | master_settlement_item_id |    <Level1_id>               |
      | settlement_level       | REGISTRATION         |
      | settlement_level_id    | Level 2, Item 2             |
      | submitted_indicator    | true                 |
      | settlement_item_status | AWAITING_DATA        |
      | atlas_settlement_level_id | <uuid>            |
      | registration_set_id      |      <uuid>                |
      | portfolio_id                  |      <uuid>                |
      | asset_type             | DER_FUEL_CELL                 |
      | start_dttm_utc          | 2023-09-05T08:00:00.000Z                     |
      | end_dttm_utc            | 2023-09-05T08:30:00.000Z                     |
    Then the response should include the new settlement_item
    Given I save the settlement_item id for later use with the tag Level2_Item2_id

    When I call GET settlement_item for saved id Level1_id and include_sub_settlement_items = false
    Then the returned settlement item should only return the master item

    When I call GET settlement_item for saved id Level1_id and include_sub_settlement_items = true
    Then the returned settlement item should contain the complete item hierarchy

    # Delete one child
    Given I set the last settlement_item id from the tag Level2_Item1_id
    And I DELETE the settlement_item
    Then the DELETE settlement_item details should specify 1 settlement item and 0 settlement item intervals

    Given I expect the next API call to return a status code of 404 and details of "no settlement item found for settlement item id"
    When I call GET settlement_item for saved id Level2_Item1_id and include_sub_settlement_items = false
    Then the expected status should be returned

    # GET parent should include the other child
    When I call GET settlement_item for saved id Level1_id and include_sub_settlement_items = true
    Then the returned settlement item should contain the complete item hierarchy

    # Delete the other child
    Given I set the last settlement_item id from the tag Level2_Item2_id
    And I DELETE the settlement_item
    Then the DELETE settlement_item details should specify 1 settlement item and 0 settlement item intervals

    # GET parent should not include either child
    Given I expect the next API call to return a status code of 404 and details of "The requested master_settlement_item or sub_settlement_items do not exist"
    When I call GET settlement_item for saved id Level1_id and include_sub_settlement_items = true
    Then the expected status should be returned

    # GET parent with include_sub_settlement_items = false should still succeed
    When I call GET settlement_item for saved id Level1_id and include_sub_settlement_items = false
    Then the returned settlement item should only return the master item

    # Delete the master
    When I DELETE settlement item with the id tag Level1_id
    Then the DELETE settlement_item details should specify 1 settlement item and 0 settlement item intervals

    # Try deleting the master again
    Given I expect the next API call to return a status code of 404 and details of "The settlement_item could already be deleted"
    When I DELETE settlement item with the id tag Level1_id
    Then the expected status should be returned

      # Cleanup
    When I DELETE the settlement
    Then the DELETE settlement details should specify 0 settlement items and 0 settlement item intervals
    And changes should be recorded in the settlement audit log


  Scenario: Hierachy is limited to a depth of two

    Given I want to log all API requests
    Given I want to log all API responses

    When I POST a settlement with the following properties:
      | settlement_type         | ONGOING_DATA_SUBMISSION                  |
      | settlement_subtype      | TVA event                                |
      | start_dttm_utc          | 2023-09-05T08:00:00.000Z                     |
      | end_dttm_utc            | 2023-09-05T08:30:00.000Z                     |
      | event_id                | <uuid>                                   |
      | description             | QAA test: Basic scenario for settlement hierarchy |
      | settlement_status       | PRELIMINARY                              |
      | business_process_status | NOT_STARTED                              |
      | source_system_type      | NGP                                      |
    Then the response should include the new settlement

    # POST Parent (Level 1)
    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | PORTFOLIO            |
      | settlement_level_id    | Level 1              |
      | submitted_indicator    | true                 |
      | settlement_item_status | AWAITING_DATA        |
      | atlas_settlement_level_id | <uuid>            |
      | registration_set_id      |      <uuid>                |
      | portfolio_id                  |      <uuid>                |
      | asset_type             | LOAD                 |
      | start_dttm_utc          | 2023-09-05T08:00:00.000Z                     |
      | end_dttm_utc            | 2023-09-05T08:30:00.000Z                     |
    Then the response should include the new settlement_item
    Given I save the settlement_item id for later use with the tag Level1_id

    # POST Child (Level 2)
    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | master_settlement_item_id |    <Level1_id>               |
      | settlement_level       | REGISTRATION         |
      | settlement_level_id    | Level 2, Item 1             |
      | submitted_indicator    | true                 |
      | settlement_item_status | AWAITING_DATA        |
      | atlas_settlement_level_id | <uuid>            |
      | registration_set_id      |      <uuid>                |
      | portfolio_id                  |      <uuid>                |
      | asset_type             | DER_FUEL_CELL                 |
      | start_dttm_utc          | 2023-09-05T08:00:00.000Z                     |
      | end_dttm_utc            | 2023-09-05T08:30:00.000Z                     |
    Then the response should include the new settlement_item
    Given I save the settlement_item id for later use with the tag Level2_id

    # POST another Child (Level 2)
    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | master_settlement_item_id |    <Level1_id>               |
      | settlement_level       | REGISTRATION         |
      | settlement_level_id    | Level 2, Item 2             |
      | submitted_indicator    | true                 |
      | settlement_item_status | AWAITING_DATA        |
      | atlas_settlement_level_id | <uuid>            |
      | registration_set_id      |      <uuid>                |
      | portfolio_id                  |      <uuid>                |
      | asset_type             | DER_FUEL_CELL                 |
      | start_dttm_utc          | 2023-09-05T08:00:00.000Z                     |
      | end_dttm_utc            | 2023-09-05T08:30:00.000Z                     |
    Then the response should include the new settlement_item

    When I call GET settlement_item for saved id Level1_id and include_sub_settlement_items = true
    Then the returned settlement item should contain the complete item hierarchy

    # POST attempt for Grandchild (Level 3), which should fail
    Given I expect the next API call to return a status code of 400 and details of "already has a parent"
    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | master_settlement_item_id |    <Level2_id>               |
      | settlement_level       | REGISTRATION         |
      | settlement_level_id    | Level 3, Item 1             |
      | submitted_indicator    | true                 |
      | settlement_item_status | AWAITING_DATA        |
      | atlas_settlement_level_id | <uuid>            |
      | registration_set_id      |      <uuid>                |
      | portfolio_id                  |      <uuid>                |
      | asset_type             | DER_FUEL_CELL                 |
      | start_dttm_utc          | 2023-09-05T08:00:00.000Z                     |
      | end_dttm_utc            | 2023-09-05T08:30:00.000Z                     |
    Then the expected status should be returned

    # POST another item to test PATCHING it to a child
    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | PORTFOLIO            |
      | settlement_level_id    | Another child        |
      | submitted_indicator    | true                 |
      | settlement_item_status | AWAITING_DATA        |
      | atlas_settlement_level_id | <uuid>            |
      | registration_set_id      |      <uuid>                |
      | portfolio_id                  |      <uuid>                |
      | asset_type             | DER_FUEL_CELL        |
      | start_dttm_utc          | 2023-09-05T08:00:00.000Z                     |
      | end_dttm_utc            | 2023-09-05T08:30:00.000Z                     |
    Then the response should include the new settlement_item
    Given I save the settlement_item id for later use with the tag AnotherChild

    Given I expect the next API call to return a status code of 400 and details of "already has a parent"
    When I PATCH the settlement_item with new values:
      | settlement_item_id     | <AnotherChild> |
      | master_settlement_item_id |    <Level2_id>               |
      | change_comments        | QAA test       |
    Then the expected status should be returned

      # Cleanup
    When I DELETE the settlement
    Then the DELETE settlement details should specify 4 settlement items and 0 settlement item intervals
    And changes should be recorded in the settlement audit log


  Scenario: Use PUT and PATCH to create sub-items

    When I POST a settlement with the following properties:
      | settlement_type         | ONGOING_DATA_SUBMISSION                  |
      | settlement_subtype      | TVA event                                |
      | start_dttm_utc          | 2023-09-05T08:00:00.000Z                     |
      | end_dttm_utc            | 2023-09-05T08:30:00.000Z                     |
      | event_id                | <uuid>                                   |
      | description             | QAA test |
      | settlement_status       | PRELIMINARY                              |
      | business_process_status | NOT_STARTED                              |
      | source_system_type      | NGP                                      |
    Then the response should include the new settlement

    # POST Parent Item
    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | PORTFOLIO            |
      | settlement_level_id    | Level 1              |
      | submitted_indicator    | true                 |
      | settlement_item_status | AWAITING_DATA        |
      | atlas_settlement_level_id | <uuid>            |
      | registration_set_id      |      <uuid>                |
      | portfolio_id                  |      <uuid>                |
      | asset_type             | LOAD                 |
      | start_dttm_utc          | 2023-09-05T08:00:00.000Z                     |
      | end_dttm_utc            | 2023-09-05T08:30:00.000Z                     |
    Then the response should include the new settlement_item
    Given I save the settlement_item id for later use with the tag Level1_id

    # POST another item that will be turned into a child via PATCH
    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | PORTFOLIO            |
      | settlement_level_id    | Level 2              |
      | submitted_indicator    | true                 |
      | settlement_item_status | AWAITING_DATA        |
      | atlas_settlement_level_id | <uuid>            |
      | registration_set_id      |      <uuid>                |
      | portfolio_id                  |      <uuid>                |
      | asset_type             | LOAD                 |
      | start_dttm_utc          | 2023-09-05T08:00:00.000Z                     |
      | end_dttm_utc            | 2023-09-05T08:30:00.000Z                     |
    Then the response should include the new settlement_item
    Given I save the settlement_item id for later use with the tag Level2_id

      # Cannot use PUT to change the master id
    Given I expect the next API call to return a status code of 400 and details of "cannot change the master_settlement_item_id"
    When I PUT the settlement_item with new values:
      | settlement_id          | <last-settlement-id> |
      | settlement_item_id     | <Level2_id> |
      | master_settlement_item_id |    <Level1_id>               |
      | settlement_level       | PORTFOLIO            |
      | settlement_level_id    | Level 2              |
      | submitted_indicator    | true                 |
      | settlement_item_status | AWAITING_DATA        |
      | atlas_settlement_level_id | <uuid>            |
      | registration_set_id      |      <uuid>                |
      | portfolio_id                  |      <uuid>                |
      | asset_type             | LOAD                 |
      | start_dttm_utc          | 2023-09-05T08:00:00.000Z                     |
      | end_dttm_utc            | 2023-09-05T08:30:00.000Z                     |
      | change_comments        | QAA test       |
    Then the expected status should be returned

      # But you can use PATCH
    Given I expect the next API call to return a status code of 200 and details of "Successfully updated the master_settlement_item_id"
    When I PATCH the settlement_item with new values:
      | settlement_item_id     | <Level2_id> |
      | master_settlement_item_id |    <Level1_id>               |
      | change_comments        | QAA test       |
    Then the expected status should be returned

    When I call GET settlement_item for saved id Level1_id and include_sub_settlement_items = true
    Then the returned settlement item should contain the complete item hierarchy

      # Item is already a child of the master (throws error in v0, but only to prevent extra audit log entry; v1 allows it)
    Given I expect the next API call to return a status code of 200 and details of "Successfully updated the master_settlement_item_id"
    When I PATCH the settlement_item with new values:
      | settlement_item_id     | <Level2_id> |
      | master_settlement_item_id |    <Level1_id>               |
      | change_comments        | QAA test       |
    Then the expected status should be returned

      # But you can't turn a master into its own child
    Given I expect the next API call to return a status code of 400 and details of "already has a parent"
    When I PATCH the settlement_item with new values:
      | settlement_item_id     | <Level2_id> |
      | master_settlement_item_id |    <Level2_id>               |
      | change_comments        | QAA test       |
    Then the expected status should be returned

      # Master item id does not exist
    Given I expect the next API call to return a status code of 404 and details of "no settlement item found for master settlement item id"
    When I PATCH the settlement_item with new values:
      | settlement_item_id     | <Level2_id> |
      | master_settlement_item_id |    <uuid>               |
      | change_comments        | QAA test       |
    Then the expected status should be returned

      # Child item id does not exist
    Given I expect the next API call to return a status code of 404 and details of "no settlement item found for id"
    When I PATCH the settlement_item with new values:
      | settlement_item_id     | <uuid> |
      | master_settlement_item_id |    <Level2_id>               |
      | change_comments        | QAA test       |
    Then the expected status should be returned

      # Master item was deleted
    Given I DELETE settlement item with the id tag Level1_id
    Given I expect the next API call to return a status code of 404 and details of "no settlement item found for id"
    When I PATCH the settlement_item with new values:
      | settlement_item_id     | <Level2_id> |
      | master_settlement_item_id |    <Level1_id>               |
      | change_comments        | QAA test       |
    Then the expected status should be returned

      # Delete
    Given I DELETE the settlement
    Then the DELETE settlement details should specify 0 settlement items and 0 settlement item intervals



  Scenario: Various errors

    Given I want to log all API requests
    Given I want to log all API responses

    When I POST a settlement with the following properties:
      | settlement_type         | ONGOING_DATA_SUBMISSION                  |
      | settlement_subtype      | TVA event                                |
      | start_dttm_utc          | 2023-09-05T08:00:00.000Z                     |
      | end_dttm_utc            | 2023-09-05T08:30:00.000Z                     |
      | event_id                | <uuid>                                   |
      | description             | QAA test |
      | settlement_status       | PRELIMINARY                              |
      | business_process_status | NOT_STARTED                              |
      | source_system_type      | NGP                                      |
    Then the response should include the new settlement

    # POST Parent Item
    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | PORTFOLIO            |
      | settlement_level_id    | Level 1              |
      | submitted_indicator    | true                 |
      | settlement_item_status | AWAITING_DATA        |
      | atlas_settlement_level_id | <uuid>            |
      | asset_type             | LOAD                 |
      | start_dttm_utc          | 2023-09-05T08:00:00.000Z                     |
      | end_dttm_utc            | 2023-09-05T08:30:00.000Z                     |
    Then the response should include the new settlement_item
    Given I save the settlement_item id for later use with the tag Level1_id

    # Master item does not exist
    Given I expect the next API call to return a status code of 404 and details of "no settlement item found for master settlement item id"
    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | master_settlement_item_id |    <uuid>               |
      | settlement_level       | REGISTRATION         |
      | settlement_level_id    | Level 2             |
      | submitted_indicator    | true                 |
      | settlement_item_status | AWAITING_DATA        |
      | atlas_settlement_level_id | <uuid>            |
      | asset_type             | DER_FUEL_CELL                 |
      | start_dttm_utc          | 2023-09-05T08:00:00.000Z                     |
      | end_dttm_utc            | 2023-09-05T08:30:00.000Z                     |
    Then the expected status should be returned

    # Master item exists, but settlement does not
    Given I expect the next API call to return a status code of 400 and details of "Cannot find Settlement for settlement_id"
    When I POST a settlement_item with the following properties:
      | settlement_id          | <uuid> |
      | master_settlement_item_id |    <Level1_id>               |
      | settlement_level       | REGISTRATION         |
      | settlement_level_id    | Level 2             |
      | submitted_indicator    | true                 |
      | settlement_item_status | AWAITING_DATA        |
      | atlas_settlement_level_id | <uuid>            |
      | asset_type             | DER_FUEL_CELL                 |
      | start_dttm_utc          | 2023-09-05T08:00:00.000Z                     |
      | end_dttm_utc            | 2023-09-05T08:30:00.000Z                     |
    Then the expected status should be returned

    When I POST a settlement with the following properties:
      | settlement_type         | ONGOING_DATA_SUBMISSION                  |
      | settlement_subtype      | TVA event  2                              |
      | start_dttm_utc          | 2023-09-05T09:00:00.000Z                     |
      | end_dttm_utc            | 2023-09-05T09:30:00.000Z                     |
      | event_id                | <uuid>                                   |
      | description             | QAA test |
      | settlement_status       | PRELIMINARY                              |
      | business_process_status | NOT_STARTED                              |
      | source_system_type      | NGP                                      |
    Then the response should include the new settlement

    # Sub-item does not specify the same settlement as master item
    Given I expect the next API call to return a status code of 400 and details of "settlement_items must have the same settlement_id"
    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | master_settlement_item_id |    <Level1_id>               |
      | settlement_level       | REGISTRATION         |
      | settlement_level_id    | Level 2             |
      | submitted_indicator    | true                 |
      | settlement_item_status | AWAITING_DATA        |
      | atlas_settlement_level_id | <uuid>            |
      | asset_type             | DER_FUEL_CELL                 |
      | start_dttm_utc          | 2023-09-05T09:00:00.000Z                     |
      | end_dttm_utc            | 2023-09-05T09:30:00.000Z                     |
    Then the expected status should be returned

     # Cleanup
    Given I DELETE all settlements created in this scenario


  Scenario: Master item is FINALIZED/NO_DATA

    When I POST a settlement with the following properties:
      | settlement_type         | ONGOING_DATA_SUBMISSION                  |
      | settlement_subtype      | TVA event                                |
      | start_dttm_utc          | 2023-09-05T08:00:00.000Z                     |
      | end_dttm_utc            | 2023-09-05T08:30:00.000Z                     |
      | event_id                | <uuid>                                   |
      | description             | QAA test |
      | settlement_status       | PRELIMINARY                              |
      | business_process_status | NOT_STARTED                              |
      | source_system_type      | NGP                                      |
    Then the response should include the new settlement

    # POST Parent Item 1
    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | PORTFOLIO            |
      | settlement_level_id    | Item 1               |
      | submitted_indicator    | true                 |
      | settlement_item_status | AWAITING_DATA        |
      | atlas_settlement_level_id | <uuid>            |
      | registration_set_id      |      <uuid>                |
      | portfolio_id                  |      <uuid>                |
      | asset_type             | LOAD                 |
      | start_dttm_utc          | 2023-09-05T08:00:00.000Z                     |
      | end_dttm_utc            | 2023-09-05T08:30:00.000Z                     |
    Then the response should include the new settlement_item
    Given I save the settlement_item id for later use with the tag Item1

    # POST Parent Item 2 as FINALIZED
    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | PORTFOLIO            |
      | settlement_level_id    | Item 2               |
      | submitted_indicator    | true                 |
      | settlement_item_status | FINALIZED            |
      | atlas_settlement_level_id | <uuid>            |
      | registration_set_id      |      <uuid>                |
      | portfolio_id                  |      <uuid>                |
      | asset_type             | LOAD                 |
      | start_dttm_utc          | 2023-09-05T08:00:00.000Z                     |
      | end_dttm_utc            | 2023-09-05T08:30:00.000Z                     |
    Then the response should include the new settlement_item
    Given I save the settlement_item id for later use with the tag Item2

    # POST Parent Item 3 as NO_DATA
    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | PORTFOLIO            |
      | settlement_level_id    | Item 3               |
      | submitted_indicator    | true                 |
      | settlement_item_status | NO_DATA              |
      | atlas_settlement_level_id | <uuid>            |
      | registration_set_id      |      <uuid>                |
      | portfolio_id                  |      <uuid>                |
      | asset_type             | LOAD                 |
      | start_dttm_utc          | 2023-09-05T08:00:00.000Z                     |
      | end_dttm_utc            | 2023-09-05T08:30:00.000Z                     |
    Then the response should include the new settlement_item
    Given I save the settlement_item id for later use with the tag Item3

    # You cannot post a sub-item under a FINALIZED or NO_DATA item
    Given I expect the next API call to return a status code of 400 and details of "master item is finalized with status=FINALIZED"
    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | master_settlement_item_id |    <Item2>               |
      | settlement_level       | REGISTRATION         |
      | settlement_level_id    | SubItem1             |
      | submitted_indicator    | true                 |
      | settlement_item_status | AWAITING_DATA        |
      | atlas_settlement_level_id | <uuid>            |
      | registration_set_id      |      <uuid>                |
      | portfolio_id                  |      <uuid>                |
      | asset_type             | DER_FUEL_CELL                 |
      | start_dttm_utc          | 2023-09-05T08:00:00.000Z                     |
      | end_dttm_utc            | 2023-09-05T08:30:00.000Z                     |
    Then the expected status should be returned

    Given I expect the next API call to return a status code of 400 and details of "master item is finalized with status=NO_DATA"
    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | master_settlement_item_id |    <Item3>               |
      | settlement_level       | REGISTRATION         |
      | settlement_level_id    | SubItem2             |
      | submitted_indicator    | true                 |
      | settlement_item_status | AWAITING_DATA        |
      | atlas_settlement_level_id | <uuid>            |
      | registration_set_id      |      <uuid>                |
      | portfolio_id                  |      <uuid>                |
      | asset_type             | DER_FUEL_CELL                 |
      | start_dttm_utc          | 2023-09-05T08:00:00.000Z                     |
      | end_dttm_utc            | 2023-09-05T08:30:00.000Z                     |
    Then the expected status should be returned

    # You also cannot move a sub-item to a FINALIZED or NO_DATA master
    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | master_settlement_item_id |    <Item1>               |
      | settlement_level       | REGISTRATION         |
      | settlement_level_id    | SubItem3             |
      | submitted_indicator    | true                 |
      | settlement_item_status | AWAITING_DATA        |
      | atlas_settlement_level_id | <uuid>            |
      | registration_set_id      |      <uuid>                |
      | portfolio_id                  |      <uuid>                |
      | asset_type             | DER_FUEL_CELL                 |
      | start_dttm_utc          | 2023-09-05T08:00:00.000Z                     |
      | end_dttm_utc            | 2023-09-05T08:30:00.000Z                     |
    Then the response should include the new settlement_item

    Given I expect the next API call to return a status code of 400 and details of "is finalized with status=FINALIZED"
    When I PATCH the settlement_item with new values:
      | settlement_item_id     | <last-settlement-item-id>  |
      | master_settlement_item_id |    <Item2>               |
      | change_comments        | Move to other parent |
    Then the expected status should be returned

    Given I expect the next API call to return a status code of 400 and details of "is finalized with status=NO_DATA"
    When I PATCH the settlement_item with new values:
      | settlement_item_id     | <last-settlement-item-id>  |
      | master_settlement_item_id |    <Item3>               |
      | change_comments        | Move to other parent |
    Then the expected status should be returned

    # Cleanup
    Given I DELETE the settlement
    Then the DELETE settlement details should specify 4 settlement items and 0 settlement item intervals


#  # ITAPPS-3869 is on hold
#
#  Scenario: ITAPPS-3869: update settlement API to optionally allow linking item to master item under different settlement
#
#    Given I want to log all API requests
#    Given I want to log all API responses
#
#    * -> Create the first settlement and portfolio -> registration hierarchy
#
#    When I POST a settlement with the following properties:
#      | settlement_type         | ONGOING_DATA_SUBMISSION                  |
#      | settlement_subtype      | FCAS                               |
#      | start_dttm_utc          | 2023-09-05T08:00:00.000Z                      |
#      | end_dttm_utc            | 2023-09-05T08:30:00.000Z                      |
#      | event_id                | <uuid>                                   |
#      | description             | ITAPPS-3869 Settlement 1|
#      | settlement_status       | PRELIMINARY                              |
#      | business_process_status | NOT_STARTED                              |
#      | source_system_type      | NGP                                      |
#    Then the response should include the new settlement
#    Given I save the settlement id for later use with the tag Settlement_1
#
#    When I POST a settlement_item with the following properties:
#      | settlement_id          | <Settlement_1> |
#      | settlement_level       | PORTFOLIO            |
#      | settlement_level_id    | Portfolio 1      |
#      | submitted_indicator    | true                 |
#      | settlement_item_status | AWAITING_DATA        |
#      | atlas_settlement_level_id | <uuid>            |
#      | asset_type             | LOAD                 |
#      | start_dttm_utc          | 2023-09-05T08:00:00.000Z                      |
#      | end_dttm_utc            | 2023-09-05T08:30:00.000Z                      |
#    Then the response should include the new settlement_item
#    Given I save the settlement_item id for later use with the tag Portfolio_1
#
#    When I POST a settlement_item with the following properties:
#      | settlement_id          | <Settlement_1> |
#      | master_settlement_item_id |    <Portfolio_1>               |
#      | settlement_level       | REGISTRATION         |
#      | settlement_level_id    | Registration 1             |
#      | submitted_indicator    | true                 |
#      | settlement_item_status | AWAITING_DATA        |
#      | atlas_settlement_level_id | <uuid>            |
#      | asset_type             | LOAD                 |
#      | start_dttm_utc          | 2023-09-05T08:00:00.000Z                      |
#      | end_dttm_utc            | 2023-09-05T08:30:00.000Z                      |
#    Then the response should include the new settlement_item
#    Given I save the settlement_item id for later use with the tag Registration_1
#
#    When I call GET settlement_item for saved id Portfolio_1 and include_sub_settlement_items = true
#    Then the returned settlement item should contain the complete item hierarchy
#
#    * -> Create the second settlement and portfolio
#
#    When I POST a settlement with the following properties:
#      | settlement_type         | ONGOING_DATA_SUBMISSION                  |
#      | settlement_subtype      | FCAS                                |
#      | start_dttm_utc          | 2023-09-05T08:00:00.000Z                      |
#      | end_dttm_utc            | 2023-09-05T08:30:00.000Z                      |
#      | event_id                | <uuid>                                   |
#      | description             | ITAPPS-3869 Settlement 2 |
#      | settlement_status       | PRELIMINARY                              |
#      | business_process_status | NOT_STARTED                              |
#      | source_system_type      | NGP                                      |
#    Then the response should include the new settlement
#    Given I save the settlement id for later use with the tag Settlement_2
#
#    When I POST a settlement_item with the following properties:
#      | settlement_id          | <Settlement_2> |
#      | settlement_level       | PORTFOLIO            |
#      | settlement_level_id    | Portfolio 2      |
#      | submitted_indicator    | true                 |
#      | settlement_item_status | AWAITING_DATA        |
#      | atlas_settlement_level_id | <uuid>            |
#      | asset_type             | LOAD                 |
#      | start_dttm_utc          | 2023-09-05T08:00:00.000Z                      |
#      | end_dttm_utc            | 2023-09-05T08:30:00.000Z                      |
#    Then the response should include the new settlement_item
#    Given I save the settlement_item id for later use with the tag Portfolio_2
#
#    When I call GET settlement_item for saved id Portfolio_2 and include_sub_settlement_items = false
#    Then the returned settlement item should only return the master item
#
#    * -> PATCH: Move the registration item from the first portfolio to the second
#
#    Given I expect the next API call to return a status code of 400 and details of "Error cannot link settlement_item to the provided master_settlement_item_id. Both settlement_items must have the same settlement_id"
#    When I PATCH the settlement_item with new values:
#      | settlement_item_id     | <Registration_1>  |
#      | master_settlement_item_id |    <Portfolio_2>               |
#      | change_comments        | Move to Portfolio 2 |
#    Then the expected status should be returned
#
#    Given I expect the next API call to return a status code of 200 and details of "Successfully updated"
#    When I PATCH the settlement_item with new values:
#      | settlement_item_id     | <Registration_1>  |
#      | master_settlement_item_id |    <Portfolio_2>               |
#      | change_comments        | Move to Portfolio 2 |
#      | force | true |
#    Then the expected status should be returned
#    * GET settlement_item should return the updated entity
#    * changes should be recorded in the settlement_item audit log
#
#    When I call GET settlement_item for saved id Portfolio_2 and include_sub_settlement_items = true
#    Then the returned settlement item should contain the complete item hierarchy
#
#    * -> Cleanup
#
#    When I DELETE settlement with the id tag Settlement_1
#    Then the DELETE settlement details should specify 2 settlement items and 0 settlement item intervals
#    And changes should be recorded in the settlement audit log
#
#    When I DELETE settlement with the id tag Settlement_2
#    Then the DELETE settlement details should specify 1 settlement items and 0 settlement item intervals
#    And changes should be recorded in the settlement audit log
#
#      # Should not be able to access any items under a deleted settlement
#    Given I expect the next API call to return a status code of 404 and details of "no settlement item found for settlement item id"
#    When I call GET settlement_item for saved id Portfolio_1 and include_sub_settlement_items = false
#    Then the expected status should be returned
#
#    Given I expect the next API call to return a status code of 404 and details of "no settlement item found for settlement item id"
#    When I call GET settlement_item for saved id Portfolio_2 and include_sub_settlement_items = true
#    Then the expected status should be returned
