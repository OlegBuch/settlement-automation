Feature: Verify retrieval of deleted entities

  ITAPPSIT-3328: settlement API: add optional parameter to GET endpoints to include deleted records in response

  Background:
    Given I start with an empty context
    And I log in as a settlement API admin


  Scenario: Child items deleted

    When I POST a settlement with the following properties:
      | settlement_type         | ANCILLARY                           |
      | settlement_subtype      | TVA event                                         |
      | start_dttm_utc          | 2023-09-05T08:00:00Z                              |
      | end_dttm_utc            | 2023-09-05T10:00:00Z                              |
      | event_id                | <uuid>                                            |
      | product_id              |  <product1>                                  |
      | description             | QAA test:  Verify retrieval of deleted entities |
      | settlement_status       | PRELIMINARY                                       |
      | business_process_status | NOT_STARTED                                       |
      | source_system_type      | NGP                                               |
    Then the response should include the new settlement

    # Create parent item
    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | REGISTRATION         |
      | settlement_level_id    | Level 1              |
      | submitted_indicator    | true                 |
      | settlement_item_status | AWAITING_DATA        |
      | asset_type             | LOAD                 |
      |atlas_settlement_level_id | <uuid>              |
      | start_dttm_utc          | 2023-09-05T08:00:00.000Z                              |
      | end_dttm_utc            | 2023-09-05T08:30:00.000Z                            |
    Then the response should include the new settlement_item
    Given I save the settlement_item id for later use with the tag Level1_id

    # Create child item
    When I POST a settlement_item with the following properties:
      | settlement_id             | <last-settlement-id> |
      | master_settlement_item_id | <Level1_id>          |
      | settlement_level          | REGISTRATION         |
      | settlement_level_id       | Level 2, Item 1      |
      | submitted_indicator       | true                 |
      | settlement_item_status    | AWAITING_DATA        |
      | asset_type                | DER_FUEL_CELL        |
      |atlas_settlement_level_id | <last-atlas-settlement-level-id>              |
      | start_dttm_utc          | 2023-09-05T08:30:00.000Z                              |
      | end_dttm_utc            | 2023-09-05T09:00:00.000Z                              |
    Then the response should include the new settlement_item
    Given I save the settlement_item id for later use with the tag Level2_Item1_id

    # Create another child item
    When I POST a settlement_item with the following properties:
      | settlement_id             | <last-settlement-id> |
      | master_settlement_item_id | <Level1_id>          |
      | settlement_level          | REGISTRATION         |
      | settlement_level_id       | Level 2, Item 2      |
      | submitted_indicator       | true                 |
      | settlement_item_status    | AWAITING_DATA        |
      | asset_type                | DER_FUEL_CELL        |
      |atlas_settlement_level_id | <last-atlas-settlement-level-id>              |
      | start_dttm_utc          | 2023-09-05T09:00:00.000Z                             |
      | end_dttm_utc            | 2023-09-05T09:30:00.000Z                       |
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

    # By default, deleted items are not returned
    Given I expect the next API call to return a status code of 404 and details of "no settlement item found for settlement item id"
    When I call GET settlement_item for saved id Level2_Item1_id and include_sub_settlement_items = false
    Then the expected status should be returned

      # GET parent should only include the other child
    When I call GET settlement_item for saved id Level1_id and include_sub_settlement_items = true
    Then the returned settlement item should contain the complete item hierarchy

    # Deleted items can be retrieved with include_deleted=true

     # First, for completeness, test include_deleted=false
    Given I set include_deleted=false
    Given I expect the next API call to return a status code of 404 and details of "no settlement item found for settlement item id"
    When I call GET settlement_item for saved id Level2_Item1_id and include_sub_settlement_items = false
    Then the expected status should be returned

    # Now test include_deleted=true
    Given I set include_deleted=true
    When I call GET settlement_item for saved id Level2_Item1_id and include_sub_settlement_items = missing
    Then GET settlement_item should return the Level2_Item1_id item

    When I call GET settlement_item for saved id Level1_id and include_sub_settlement_items = true
    Then the returned settlement item should contain the complete item hierarchy

    # Delete the other child
    Given I set the last settlement_item id from the tag Level2_Item2_id
    And I DELETE the settlement_item
    Then the DELETE settlement_item details should specify 1 settlement item and 0 settlement item intervals

    # GET parent should not include either child
    Given I set include_deleted=missing
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

    # Now test include_deleted=true
    Given I set include_deleted=true
    When I call GET settlement_item for saved id Level1_id and include_sub_settlement_items = missing
    Then GET settlement_item should return the Level1_id item
    When I call GET settlement_item for saved id Level1_id and include_sub_settlement_items = true
    Then the returned settlement item should contain the complete item hierarchy

      # Cleanup
    When I DELETE the settlement
    Then the DELETE settlement details should specify 0 settlement items and 0 settlement item intervals
    And changes should be recorded in the settlement audit log


  Scenario: DELETE settlement_item_intervals

    When I POST a settlement with the following properties:
      | settlement_type         | ONGOING_DATA_SUBMISSION                  |
      | settlement_subtype      | TVA event                                |
      | start_dttm_utc          | 2023-09-05T08:00:00Z                     |
      | end_dttm_utc            | 2023-09-05T10:30:00Z                     |
      | event_id                | <uuid>                                   |
      | description             | QAA test: DELETE settlement_item_intervals |
      | settlement_status       | PRELIMINARY                              |
      | business_process_status | NOT_STARTED                              |
      | source_system_type      | NGP                                      |
    Then the response should include the new settlement

    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | REGISTRATION         |
      | settlement_level_id    | Level 1             |
      | submitted_indicator    | true                 |
      | settlement_item_status | AWAITING_DATA        |
      | asset_type             | LOAD                 |
      |atlas_settlement_level_id | <uuid>              |
      | start_dttm_utc          | 2023-09-05T08:00:00Z                     |
      | end_dttm_utc            | 2023-09-05T09:00:00Z                     |
    Then the response should include the new settlement_item
    Given I save the settlement_item id for later use with the tag Item1

    Given  I expect the next API call to return a status code of 404 and details of "no settlement item intervals found to delete for settlement item id"
    When I DELETE the settlement_item_intervals
    Then the expected status should be returned

    Given I POST a set of 5 intervals for settlement_item_id Item1

    When I call GET settlement_item_intervals with settlement_item_id: <Item1> per_page: default direction: forward
    Then the GET settlement_item_intervals response should contain only non-deleted intervals

    # DELETE settlement_item_intervals

    When I DELETE the settlement_item_intervals
    Then the DELETE settlement_item_intervals details should specify the expected number of settlement item intervals
    And changes should be recorded in the settlement_item_intervals audit log

    Given  I expect the next API call to return a status code of 404 and details of "no settlement item intervals found for settlement item id"
    When I call GET settlement_item_intervals_summary
    Then the expected status should be returned

    Given I set include_deleted=missing
    Given I expect the next API call to return a status code of 404 and details of "no settlement item intervals found for settlement item id"
    When I call GET settlement_item_intervals with settlement_item_id: <Item1> per_page: default direction: forward
    Then the expected status should be returned

    Given I set include_deleted=false
    Given I expect the next API call to return a status code of 404 and details of "no settlement item intervals found for settlement item id"
    When I call GET settlement_item_intervals with settlement_item_id: <Item1> per_page: default direction: forward
    Then the expected status should be returned

    Given I set include_deleted=true
    When I call GET settlement_item_intervals with settlement_item_id: <Item1> per_page: default direction: forward
    Then the GET settlement_item_intervals response should contain all of the intervals including deleted

    # Now add a new set of intervals with different timestamps

    Given I POST a set of 3 intervals starting with interval 6 for settlement_item_id Item1

    Given I set include_deleted=false
    When I call GET settlement_item_intervals with settlement_item_id: <Item1> per_page: default direction: forward
    Then the GET settlement_item_intervals response should contain only non-deleted intervals

    Given I set include_deleted=true
    When I call GET settlement_item_intervals with settlement_item_id: <Item1> per_page: default direction: forward
    Then the GET settlement_item_intervals response should contain all of the intervals including deleted
    Given I set include_deleted=false

    # DELETE the new settlement_item_intervals

    When I DELETE the settlement_item_intervals
    Then the DELETE settlement_item_intervals details should specify the expected number of settlement item intervals
    And changes should be recorded in the settlement_item_intervals audit log

    Given  I expect the next API call to return a status code of 404 and details of "no settlement item intervals found for settlement item id"
    When I call GET settlement_item_intervals_summary
    Then the expected status should be returned

    Given I set include_deleted=false
    Given I expect the next API call to return a status code of 404 and details of "no settlement item intervals found for settlement item id"
    When I call GET settlement_item_intervals with settlement_item_id: <Item1> per_page: default direction: forward
    Then the expected status should be returned

    Given I set include_deleted=true
    When I call GET settlement_item_intervals with settlement_item_id: <Item1> per_page: default direction: forward
    Then the GET settlement_item_intervals response should contain all of the intervals including deleted

    # Now add a new set of intervals with the SAME timestamps as deleted intervals. POST is allowed to re-create deleted intervals.

    Given I reset the intervals start date and flags
    Given I POST a set of 3 intervals for settlement_item_id Item1

    Given I set include_deleted=false
    When I call GET settlement_item_intervals with settlement_item_id: <Item1> per_page: default direction: forward
    Then the GET settlement_item_intervals response should contain only non-deleted intervals

    Given I set include_deleted=true
    When I call GET settlement_item_intervals with settlement_item_id: <Item1> per_page: default direction: forward
    Then the GET settlement_item_intervals response should contain all of the intervals including deleted
    Given I set include_deleted=false

    # DELETE the new settlement_item_intervals

    When I DELETE the settlement_item_intervals
    Then the DELETE settlement_item_intervals details should specify the expected number of settlement item intervals
    # At this point the interval audit log is too complicated to easily validate

    Given  I expect the next API call to return a status code of 404 and details of "no settlement item intervals found for settlement item id"
    When I call GET settlement_item_intervals_summary
    Then the expected status should be returned

    Given I set include_deleted=false
    Given I expect the next API call to return a status code of 404 and details of "no settlement item intervals found for settlement item id"
    When I call GET settlement_item_intervals with settlement_item_id: <Item1> per_page: default direction: forward
    Then the expected status should be returned

    Given I set include_deleted=true
    When I call GET settlement_item_intervals with settlement_item_id: <Item1> per_page: default direction: forward
    Then the GET settlement_item_intervals response should contain all of the intervals including deleted

    # Cleanup

    When I DELETE the settlement_item
    Then the DELETE settlement_item details should specify 1 settlement item and 0 settlement item intervals
    And changes should be recorded in the settlement_item audit log

# DELETE settlement_item

    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | REGISTRATION         |
      | settlement_level_id    | Level 2             |
      | submitted_indicator    | true                 |
      | settlement_item_status | AWAITING_DATA        |
      | asset_type             | LOAD                 |
      |atlas_settlement_level_id | <uuid>              |
      | start_dttm_utc          | 2023-09-05T08:00:00Z                     |
      | end_dttm_utc            | 2023-09-05T09:00:00Z                     |
    Then the response should include the new settlement_item
    Given I save the settlement_item id for later use with the tag Item2

    Given I POST a set of 10 intervals for settlement_item_id Item2

    When I DELETE the settlement_item
    Then the DELETE settlement_item details should specify the expected number of settlement item intervals
    And changes should be recorded in the settlement_item audit log
    And changes should be recorded in the settlement_item_intervals audit log

    Given  I expect the next API call to return a status code of 404 and details of "no settlement item intervals found to delete for settlement item id"
    When I DELETE the settlement_item_intervals
    Then the expected status should be returned

    Given I set include_deleted=missing
    Given I expect the next API call to return a status code of 404 and details of "no settlement item intervals found for settlement item id"
    When I call GET settlement_item_intervals with settlement_item_id: <Item2> per_page: default direction: forward
    Then the expected status should be returned

    Given I set include_deleted=false
    Given I expect the next API call to return a status code of 404 and details of "no settlement item intervals found for settlement item id"
    When I call GET settlement_item_intervals with settlement_item_id: <Item2> per_page: default direction: forward
    Then the expected status should be returned

    Given I set include_deleted=true
    When I call GET settlement_item_intervals with settlement_item_id: <Item2> per_page: default direction: forward
    Then the GET settlement_item_intervals response should contain only non-deleted intervals


    # DELETE settlement

    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | REGISTRATION         |
      | settlement_level_id    | Level 3             |
      | submitted_indicator    | true                 |
      | settlement_item_status | AWAITING_DATA        |
      | asset_type             | LOAD                 |
      |atlas_settlement_level_id | <uuid>              |
      | start_dttm_utc          | 2023-09-05T08:00:00Z                     |
      | end_dttm_utc            | 2023-09-05T09:00:00Z                     |
    Then the response should include the new settlement_item
    Given I save the settlement_item id for later use with the tag Item3

    Given I POST a set of 10 intervals for settlement_item_id Item3

    When I DELETE the settlement
    Then the DELETE settlement details should specify 1 settlement items and 10 settlement item intervals
    And changes should be recorded in the settlement audit log
    And changes should be recorded in the settlement_item audit log
    And changes should be recorded in the settlement_item_intervals audit log

    Given I want to log all API responses
    Given  I expect the next API call to return a status code of 404 and details of "no settlement item intervals found to delete for settlement item id"
    When I DELETE the settlement_item_intervals
    Then the expected status should be returned

    Given I set include_deleted=missing
    Given I expect the next API call to return a status code of 404 and details of "no settlement item intervals found for settlement item id"
    When I call GET settlement_item_intervals with settlement_item_id: <Item3> per_page: default direction: forward
    Then the expected status should be returned

    Given I set include_deleted=false
    Given I expect the next API call to return a status code of 404 and details of "no settlement item intervals found for settlement item id"
    When I call GET settlement_item_intervals with settlement_item_id: <Item3> per_page: default direction: forward
    Then the expected status should be returned

    Given I set include_deleted=true
    When I call GET settlement_item_intervals with settlement_item_id: <Item3> per_page: default direction: forward
    Then the GET settlement_item_intervals response should contain only non-deleted intervals



