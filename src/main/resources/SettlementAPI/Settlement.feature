Feature: Feature tests for settlements

  Reference: <CONFLUENCE_URL>/display/PMENA/Settlement+API+-+Technical+Design
  <JIRA_URL>/browse/ITAPPSIT-4063

  Background:
    Given I start with an empty context
    And I log in as a settlement API admin


  Scenario: Simple settlement life cycle

    # POST a new settlement
    When I POST a settlement with the following properties:
      | settlement_type         | ONGOING_DATA_SUBMISSION             |
      | settlement_subtype      | TVA event                           |
      | start_dttm_utc          | 2023-09-05T08:00:00Z                |
      | end_dttm_utc            | 2023-09-05T08:30:00Z                |
      | event_id                | <uuid> |
      | description             | QAA test: create settlement                        |
      | settlement_status       | PRELIMINARY                         |
      | business_process_status | NOT_STARTED                         |
      | source_system_type      | NGP                                 |
      | product_id              |    <product1>  |
      | processing_status       |   FOO   |
    Then the response should include the new settlement
    And GET settlement should return the new entity
    But no entries should be found in the settlement audit log

    # PUT: update all properties
    When I PUT the settlement with new values:
      | settlement_id         | <last-settlement-id>             |
      | settlement_type   | MONTHLY_BILL_SAVINGS |
      | settlement_subtype      | foo                          |
      | start_dttm_utc          | 2023-09-08T12:00:00Z                |
      | end_dttm_utc            | 2023-09-08T12:30:00Z                |
      | event_id                | <uuid> |
      | description             | QAA test: update all properties   |
      | settlement_status       | AWAITING_DATA                         |
      | business_process_status | IN_PROCESS                         |
      | source_system_type      | CLASSIC_DR                                 |
      | change_comments   | Update all properties    |
      | product_id              |    <product2>  |
      | processing_status       |   BAR   |
    Then the response should include the updated settlement
    * GET settlement should return the updated entity
    * changes should be recorded in the settlement audit log

      # PUT: only include required properties
    # Missing properties will be updated to null
    When I PUT the settlement with new values:
      | settlement_id         | <last-settlement-id>             |
      | settlement_type   | EVENT |
      | settlement_subtype      | Test TVA event                           |
      | start_dttm_utc          | 2023-09-08T11:00:00Z                |
      | end_dttm_utc            | 2023-09-08T11:30:00Z                |
      | settlement_status       | PRELIMINARY                         |
      | business_process_status | COMPLETE                         |
      | change_comments   | Update required properties    |
    Then the response should include the updated settlement
    * GET settlement should return the updated entity
    * changes should be recorded in the settlement audit log

    # PATCH: update a single property
    When I PATCH the settlement with new values:
      | settlement_id         | <last-settlement-id>             |
      | settlement_status | FINALIZED        |
      | change_comments   | Update settlement_status via PATCH    |
    Then the response should include the updated settlement
    * GET settlement should return the updated entity
    * changes should be recorded in the settlement audit log

    # DELETE: cannot delete finalized settlement
    Given I expect the next API call to return a status code of 400 and details of "cannot delete settlement where status=FINALIZED"
    Then DELETE settlement should return the expected status

    # PATCH: revert the status
    When I PATCH the settlement with new values:
      | settlement_id         | <last-settlement-id>             |
      | settlement_status | PRELIMINARY        |
      | change_comments   | Revert settlement_status via PATCH    |
    Then the response should include the updated settlement

    # DELETE: now we can delete the settlement
    When I DELETE the settlement
    Then the DELETE settlement details should specify 0 settlement items and 0 settlement item intervals
    And changes should be recorded in the settlement audit log

    # Verify all endpoints fail for a deleted settlement
    Given I expect the next API call to return a status code of 404 and details of "no settlement found for id"
    Then GET settlement should return the expected status

    Given I expect the next API call to return a status code of 404 and details of "no settlement found for id"
    Then PUT settlement should return the expected status

    Given I expect the next API call to return a status code of 404 and details of "no settlement found for id"
    Then PATCH settlement should return the expected status

    Given I expect the next API call to return a status code of 404 and details of "no settlement found for id"
    Then DELETE settlement should return the expected status

    # Verify you cannot create an item under a deleted settlement
    Given I expect the next API call to return a status code of 400 and details of "Error unable to create SettlementItem. Cannot find Settlement for settlement_id"
    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | REGISTRATION         |
      | settlement_level_id    | <uuid>             |
      | submitted_indicator    | true                 |
      | settlement_item_status | NO_DATA        |
      | asset_type             | LOAD                 |
    Then the expected status should be returned


  Scenario: Create and immediately delete a settlement

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
    And GET settlement should return the new entity
    But no entries should be found in the settlement audit log

    # include_deleted=true should return settlement whether it is deleted or not
    When I set include_deleted=true
    Then GET settlement should return the new entity

     # included just for completeness
    When I set include_deleted=false
    Then GET settlement should return the new entity

    When I DELETE the settlement
    Then the DELETE settlement details should specify 0 settlement items and 0 settlement item intervals
    And changes should be recorded in the settlement audit log

    Given I expect the next API call to return a status code of 404 and details of "no settlement found for id"
    # include_deleted default is FALSE
    When I set include_deleted=missing
    Then GET settlement should return the expected status

    Given I expect the next API call to return a status code of 404 and details of "no settlement found for id"
    When I set include_deleted=false
    Then GET settlement should return the expected status

    But if I set include_deleted=true
    Then GET settlement should return the deleted entity


  Scenario: Only one settlement can ever be created for a specific event

    Given I want to log all API responses

      # Because settlement rows in the db are never physically deleted (only marked as deleted) and
      # the event_id is used for a unique index, only one settlement can ever be created for a
      # specific event, even if the original settlement is deleted.

    When I POST a settlement with the following properties:
      | settlement_type         | ONGOING_DATA_SUBMISSION     |
      | settlement_subtype      | TVA event                   |
      | start_dttm_utc          | 2023-09-05T08:00:00.123Z    |
      | end_dttm_utc            | 2023-09-05T08:30:00.456Z    |
      | event_id                | <uuid>                      |
      | description             | QAA test: create settlement |
      | settlement_status       | PRELIMINARY                 |
      | business_process_status | NOT_STARTED                 |
      | source_system_type      | NGP                         |
    And I save the event_id
    Then the response should include the new settlement
    And GET settlement should return the new entity
    But no entries should be found in the settlement audit log

    Given I expect the next API call to return a status code of 400 and details of "the event_id supplied already exists for another settlement"
    When I POST a settlement with the following properties:
      | settlement_type         | ONGOING_DATA_SUBMISSION                       |
      | settlement_subtype      | Actually, it's a ISO-NE event                 |
      | start_dttm_utc          | 2023-09-05T09:25:00.123Z                      |
      | end_dttm_utc            | 2023-09-05T09:45:00.456Z                      |
      | event_id                | <last-event-id>                               |
      | description             | QAA test: re-create settlement for same event |
      | settlement_status       | PRELIMINARY                                   |
      | business_process_status | IN_PROCESS                                    |
      | source_system_type      | CLASSIC_DR                                    |
    Then the expected status should be returned

    When I DELETE the settlement
    Then the DELETE settlement details should specify 0 settlement items and 0 settlement item intervals
    And changes should be recorded in the settlement audit log

    Given I expect the next API call to return a status code of 404 and details of "no settlement found for id"
    Then GET settlement should return the expected status

    # Cannot create a new settlement with the same event id as a deleted settlement
    Given I expect the next API call to return a status code of 400 and details of "the event_id supplied already exists for another settlement"
    When I POST a settlement with the following properties:
      | settlement_type         | ONGOING_DATA_SUBMISSION                       |
      | settlement_subtype      | No wait, it's actually a PJM event            |
      | start_dttm_utc          | 2023-09-05T08:25:00.123Z                      |
      | end_dttm_utc            | 2023-09-05T08:45:00.456Z                      |
      | event_id                | <last-event-id>                               |
      | description             | QAA test: re-create settlement for same event |
      | settlement_status       | PRELIMINARY                                   |
      | business_process_status | IN_PROCESS                                    |
      | source_system_type      | CLASSIC_DR                                    |
    Then the expected status should be returned

    # Attempting to reassign another settlement to the event should also fail
    When I POST a settlement with the following properties:
      | settlement_type         | ONGOING_DATA_SUBMISSION        |
      | settlement_subtype      | TVA event                      |
      | start_dttm_utc          | 2023-09-05T08:00:00.123Z           |
      | end_dttm_utc            | 2023-09-05T08:30:00.456Z           |
      | event_id                | <uuid>                         |
      | description             | QAA test: Settlement lifecycle |
      | settlement_status       | AWAITING_DATA                  |
      | business_process_status | NOT_STARTED                    |
      | source_system_type      | NGP                            |
    Then the response should include the new settlement

    Given I expect the next API call to return a status code of 400 and details of "event_id supplied already exists for another settlement"
    When I PUT the settlement with new values:
      | settlement_id         | <last-settlement-id>             |
      | settlement_type         | ONGOING_DATA_SUBMISSION        |
      | settlement_subtype      | TVA event                      |
      | start_dttm_utc          | 2023-09-05T08:00:00.123Z           |
      | end_dttm_utc            | 2023-09-05T08:30:00.456Z           |
      | event_id                | <saved-event-id>                         |
      | description             | QAA test: Settlement lifecycle |
      | settlement_status       | AWAITING_DATA                  |
      | business_process_status | NOT_STARTED                    |
      | source_system_type      | NGP                            |
      | change_comments    | event_id already exists |
    Then the expected status should be returned

    # Cleanup
    Given I DELETE the settlement


  Scenario: Creating or updating settlement with invalid reference data is an error

    Given I want to log all API responses

    Given I expect the next API call to return a status code of 400 and details of "Choose from: EVENT,ENROLLMENT,ONGOING_DATA_SUBMISSION,MONTHLY_BILL_SAVINGS"
    When I POST a settlement with the following properties:
      | settlement_type         | FOOBAR        |
      | settlement_subtype      | TVA event                      |
      | start_dttm_utc          | 2023-09-05T08:00:00.123Z           |
      | end_dttm_utc            | 2023-09-05T08:30:00.456Z           |
      | event_id                | <uuid>                         |
      | description             | QAA test: Invalid reference data |
      | settlement_status       | AWAITING_DATA                  |
      | business_process_status | NOT_STARTED                    |
      | source_system_type      | NGP                            |
    Then the expected status should be returned

    When I POST a settlement with the following properties:
      | settlement_type         | ONGOING_DATA_SUBMISSION        |
      | settlement_subtype      | TVA event                      |
      | start_dttm_utc          | 2023-09-05T08:00:00.123Z           |
      | end_dttm_utc            | 2023-09-05T08:30:00.456Z           |
      | event_id                | <uuid>                         |
      | description             | QAA test: Invalid reference data |
      | settlement_status       | AWAITING_DATA                  |
      | business_process_status | NOT_STARTED                    |
      | source_system_type      | NGP                            |
    Then the response should include the new settlement

    Given I expect the next API call to return a status code of 400 and details of "Choose from: AWAITING_DATA,PRELIMINARY,FINALIZED,NO_DATA"
    When I PUT the settlement with new values:
      | settlement_id         | <last-settlement-id>             |
      | settlement_status | FOOBAR               |
      | settlement_type   | EVENT |
      | settlement_subtype      | TVA event                      |
      | start_dttm_utc          | 2023-09-05T08:00:00.123Z           |
      | end_dttm_utc            | 2023-09-05T08:30:00.456Z           |
      | business_process_status | NOT_STARTED                    |
      | change_comments    | Invalid reference data |
    Then the expected status should be returned

    # Cleanup
    Given I DELETE the settlement



  Scenario: POST, PUT, PATCH settlement errors

    Given I expect the next API call to return a status code of 400 and details of "body: data must have required property"
    When I POST a settlement with the following properties:
      | settlement_type         | ONGOING_DATA_SUBMISSION             |
    Then the expected status should be returned

    Given I expect the next API call to return a status code of 400 and details of "data/product_id must match format 'uuid'"
    When I POST a settlement with the following properties:
      | product_id              | NotUuid                                  |
      | settlement_type         | ONGOING_DATA_SUBMISSION                  |
      | settlement_subtype      | <empty-string>                           |
      | start_dttm_utc          | 2023-09-05T08:00:00.123Z                 |
      | end_dttm_utc            | 2023-09-05T08:30:00.456Z                 |
      | event_id                | <uuid>                                   |
      | description             | QAA test: product_id is not uuid |
      | settlement_status       | AWAITING_DATA                            |
      | business_process_status | NOT_STARTED                              |
      | source_system_type      | NGP                                      |
    Then the expected status should be returned

    Given I expect the next API call to return a status code of 403 and details of "Atlas error: Request failed with status code 403"
    When I POST a settlement with the following properties:
      | product_id              | 90000000-87e3-4639-9702-ec51a50e7de7                                  |
      | settlement_type         | ONGOING_DATA_SUBMISSION                  |
      | settlement_subtype      | Test event                           |
      | start_dttm_utc          | 2023-09-05T08:00:00.123Z                 |
      | end_dttm_utc            | 2023-09-05T08:30:00.456Z                 |
      | event_id                | <uuid>                                   |
      | description             | QAA test: unknown product_id |
      | settlement_status       | AWAITING_DATA                            |
      | business_process_status | NOT_STARTED                              |
      | source_system_type      | NGP                                      |
    Then the expected status should be returned

    Given I expect the next API call to return a status code of 400 and details of "processing status must be <= 15 chars"
    When I POST a settlement with the following properties:
      | settlement_type         | ONGOING_DATA_SUBMISSION                  |
      | settlement_subtype      | Test event                           |
      | start_dttm_utc          | 2023-09-05T08:00:00.123Z                 |
      | end_dttm_utc            | 2023-09-05T08:30:00.456Z                 |
      | event_id                | <uuid>                                   |
      | description             | QAA test: processing_status > 15 chars |
      | settlement_status       | AWAITING_DATA                            |
      | business_process_status | NOT_STARTED                              |
      | source_system_type      | NGP                                      |
      | processing_status       |   abcdefghijklmnop   |
    Then the expected status should be returned

    Given I expect the next API call to return a status code of 400 and details of "settlement subtype is required"
    When I POST a settlement with the following properties:
      | settlement_type         | ONGOING_DATA_SUBMISSION        |
      | settlement_subtype      | <empty-string>                      |
      | start_dttm_utc          | 2023-09-05T08:00:00.123Z           |
      | end_dttm_utc            | 2023-09-05T08:30:00.456Z           |
      | event_id                | <uuid>                         |
      | description             | QAA test: Required field is empty string |
      | settlement_status       | AWAITING_DATA                  |
      | business_process_status | NOT_STARTED                    |
      | source_system_type      | NGP                            |
    Then the expected status should be returned

    Given I expect the next API call to return a status code of 400 and details of "source system type must be <= 17 chars"
    When I POST a settlement with the following properties:
      | settlement_type         | ONGOING_DATA_SUBMISSION        |
      | settlement_subtype      | TVA event                      |
      | start_dttm_utc          | 2023-09-05T08:00:00.123Z           |
      | end_dttm_utc            | 2023-09-05T08:30:00.456Z           |
      | event_id                | <uuid>                         |
      | description             | QAA test: source_system_type string length is too long |
      | settlement_status       | AWAITING_DATA                  |
      | business_process_status | NOT_STARTED                    |
      | source_system_type      | 12345678901234567890                            |
    Then the expected status should be returned

    Given I expect the next API call to return a status code of 400 and details of "start date must be before end date"
    Given I POST a settlement with the following properties:
      | settlement_type         | ONGOING_DATA_SUBMISSION        |
      | settlement_subtype      | TVA event                      |
      | start_dttm_utc          | 2023-09-05T08:00:00.123Z           |
      | end_dttm_utc            | 2023-08-05T08:30:00.456Z           |
      | event_id                | <uuid>                         |
      | description             | QAA test: end_dttm_utc <  start_dttm_utc |
      | settlement_status       | AWAITING_DATA                  |
      | business_process_status | NOT_STARTED                    |
      | source_system_type      | NGP                            |
    Then the expected status should be returned

    Given I POST a settlement with the following properties:
      | settlement_type         | ONGOING_DATA_SUBMISSION        |
      | settlement_subtype      | TVA event                      |
      | start_dttm_utc          | 2023-09-05T08:00:00.123Z           |
      | end_dttm_utc            | 2023-09-05T08:30:00.456Z           |
      | event_id                | <uuid>                         |
      | description             | QAA test: Invalid reference data |
      | settlement_status       | AWAITING_DATA                  |
      | business_process_status | NOT_STARTED                    |
      | source_system_type      | NGP                            |
    Then the response should include the new settlement

    # PUT: if no fields changed, should return 200
    When I PUT the settlement with new values:
      | settlement_id         | <last-settlement-id>             |
      | settlement_type         | ONGOING_DATA_SUBMISSION        |
      | settlement_subtype      | TVA event                      |
      | start_dttm_utc          | 2023-09-05T08:00:00.123Z           |
      | end_dttm_utc            | 2023-09-05T08:30:00.456Z           |
      | event_id                | <last-event-id>                         |
      | description             | QAA test: Invalid reference data |
      | settlement_status       | AWAITING_DATA                  |
      | business_process_status | NOT_STARTED                    |
      | source_system_type      | NGP                            |
      # "No update expected" tells the following stepdef that the response is actually identical to the existing settlement.
      | change_comments   | No update expected   |
    Then the response should include the updated settlement

    Given I expect the next API call to return a status code of 400 and details of "settlement type is required"
    When I PUT the settlement with new values:
      | settlement_id         | <last-settlement-id>             |
      | settlement_type         | <empty-string>        |
      | settlement_subtype      | TVA event                      |
      | start_dttm_utc          | 2023-09-05T08:00:00.123Z           |
      | end_dttm_utc            | 2023-09-05T08:30:00.456Z           |
      | event_id                | <last-event-id>                         |
      | description             | QAA test: Required field is empty string |
      | settlement_status       | AWAITING_DATA                  |
      | business_process_status | NOT_STARTED                    |
      | source_system_type      | NGP                            |
      | change_comments   | No actual updates   |
    Then the expected status should be returned

    Given I expect the next API call to return a status code of 400 and details of "data/product_id must match format 'uuid'"
    When I PUT the settlement with new values:
      | settlement_id         | <last-settlement-id>             |
      | settlement_type         | ONGOING_DATA_SUBMISSION        |
      | settlement_subtype      | TVA event                      |
      | start_dttm_utc          | 2023-09-05T08:00:00.123Z           |
      | end_dttm_utc            | 2023-09-05T08:30:00.456Z           |
      | event_id                | <last-event-id>                         |
      | description             | QAA test: product_id not uuid |
      | settlement_status       | AWAITING_DATA                  |
      | business_process_status | NOT_STARTED                    |
      | source_system_type      | NGP                            |
      | product_id              | NotUuid                                  |
      | change_comments   | No actual updates   |
    Then the expected status should be returned

    Given I expect the next API call to return a status code of 403 and details of "Atlas error: Request failed with status code 403"
    When I PUT the settlement with new values:
      | settlement_id         | <last-settlement-id>             |
      | settlement_type         | ONGOING_DATA_SUBMISSION        |
      | settlement_subtype      | TVA event                      |
      | start_dttm_utc          | 2023-09-05T08:00:00.123Z           |
      | end_dttm_utc            | 2023-09-05T08:30:00.456Z           |
      | event_id                | <last-event-id>                         |
      | description             | QAA test: unknown product_id |
      | settlement_status       | AWAITING_DATA                  |
      | business_process_status | NOT_STARTED                    |
      | source_system_type      | NGP                            |
      | product_id              |  90000000-87e3-4639-9702-ec51a50e7de7                                  |
      | change_comments   | No actual updates   |
    Then the expected status should be returned

    Given I expect the next API call to return a status code of 400 and details of "processing status must be <= 15 chars"
    When I PUT the settlement with new values:
      | settlement_id         | <last-settlement-id>             |
      | settlement_type         | ONGOING_DATA_SUBMISSION        |
      | settlement_subtype      | TVA event                      |
      | start_dttm_utc          | 2023-09-05T08:00:00.123Z           |
      | end_dttm_utc            | 2023-09-05T08:30:00.456Z           |
      | event_id                | <last-event-id>                         |
      | description             | QAA test: unknown uuid |
      | settlement_status       | AWAITING_DATA                  |
      | business_process_status | NOT_STARTED                    |
      | source_system_type      | NGP                            |
      | processing_status       |   abcdefghijklmnop   |
      | change_comments   | No actual updates   |
    Then the expected status should be returned

    Given I expect the next API call to return a status code of 400 and details of "start date must be before end date"
    When I PUT the settlement with new values:
      | settlement_id         | <last-settlement-id>             |
      | settlement_type         | ONGOING_DATA_SUBMISSION        |
      | settlement_subtype      | TVA event                      |
      | start_dttm_utc          | 2023-09-05T08:00:00.123Z           |
      | end_dttm_utc            | 2023-08-05T08:30:00.456Z           |
      | event_id                | <last-event-id>                         |
      | description             | QAA test: end_dttm_utc <  start_dttm_utc |
      | settlement_status       | AWAITING_DATA                  |
      | business_process_status | NOT_STARTED                    |
      | source_system_type      | NGP                            |
      | change_comments   | No actual updates   |
    Then the expected status should be returned

    Given I expect the next API call to return a status code of 400 and details of "body: data must have required property 'settlement_type'"
    When I PUT the settlement with new values:
      | settlement_id         | <last-settlement-id>             |
      | settlement_type | <missing>        |
      | change_comments   | PUT will fail if mandatory field is missing    |
    Then the expected status should be returned
    And no entries should be found in the settlement audit log

    Given I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I PATCH the settlement with new values:
      | settlement_id         | <last-settlement-id>             |
      | settlement_status | AWAITING_DATA        |
      | change_comments   | Update settlement_status via PATCH    |
    Then the expected status should be returned
    And no entries should be found in the settlement audit log

    Given I expect the next API call to return a status code of 400 and details of "body: data must have required property 'settlement_id'"
    When I PATCH the settlement with new values:
      | settlement_status | FINALIZED        |
      | change_comments   | Update settlement_status via PATCH    |
    Then the expected status should be returned
    And no entries should be found in the settlement audit log

    Given I expect the next API call to return a status code of 400 and details of "processing status must be <= 15 chars"
    When I PATCH the settlement with new values:
      | settlement_id         | <last-settlement-id>             |
      | settlement_status | PRELIMINARY        |
      | processing_status       |   abcdefghijklmnop   |
      | change_comments   | processing status must be <= 15 chars    |
    Then the expected status should be returned
    And no entries should be found in the settlement audit log

    # Cleanup
    Given I DELETE the settlement

    # PUT and PATCH specify a settlement that doesn't exist
    Given I expect the next API call to return a status code of 404 and details of "no settlement found for id"
    When I PUT the settlement with new values:
      | settlement_id         | <uuid>             |
      | settlement_type   | EVENT |
      | settlement_subtype      | Test TVA event                           |
      | start_dttm_utc          | 2023-09-08T11:00:00Z                |
      | end_dttm_utc            | 2023-09-08T11:30:00Z                |
      | event_id                | <uuid> |
      | description             | QAA test: audit log                           |
      | settlement_status       | AWAITING_DATA                         |
      | business_process_status | IN_PROCESS                         |
      | source_system_type      | CLASSIC_DR                                 |
      | change_comments   | Update all properties    |
    Then the expected status should be returned

    Given I expect the next API call to return a status code of 404 and details of "no settlement found for id"

    When I PATCH the settlement with new values:
      | settlement_id         | <uuid>             |
      | settlement_status | FINALIZED        |
      | change_comments   | Update settlement_status via PATCH    |
    Then the expected status should be returned


  Scenario: Treatment of explicit null values

    Given I want to log all API requests
    Given I want to log all API responses

    # POST a new settlement with nulls
    # Nulls are returned by GET settlement
    When I POST a settlement with the following properties:
      | settlement_type         | ONGOING_DATA_SUBMISSION             |
      | settlement_subtype      | TVA event                           |
      | start_dttm_utc          | 2023-09-05T08:00:00Z                |
      | end_dttm_utc            | 2023-09-05T08:30:00Z               |
      | event_id                | <null> |
      | description             | <null>                       |
      | settlement_status       | AWAITING_DATA                         |
      | business_process_status | NOT_STARTED                         |
      | source_system_type      | <null>                                 |
      | processing_status       |   <null>   |
    Then the response should include the new settlement
    And GET settlement should return the new entity
    But no entries should be found in the settlement audit log

    # PUT: change nulls to real values
    When I PUT the settlement with new values:
      | settlement_id         | <last-settlement-id>             |
      | settlement_type         | ONGOING_DATA_SUBMISSION             |
      | settlement_subtype      | TVA event                           |
      | start_dttm_utc          | 2023-09-05T08:00:00Z                |
      | end_dttm_utc            | 2023-09-05T08:30:00Z               |
      | event_id                | <uuid> |
      | description             | foo                       |
      | settlement_status       | AWAITING_DATA                         |
      | business_process_status | IN_PROCESS                         |
      | source_system_type      | PROCUREMENT                                |
      | processing_status       |   FOO   |
      | change_comments    | Change business_process_status |
    Then the response should include the updated settlement
    * GET settlement should return the updated entity
    * changes should be recorded in the settlement audit log

    # PUT: change real values to nulls
    # Nulls are returned by GET settlement, but audit log returns empty strings
    When I PUT the settlement with new values:
      | settlement_id         | <last-settlement-id>             |
      | settlement_type         | ONGOING_DATA_SUBMISSION             |
      | settlement_subtype      | TVA event                           |
      | start_dttm_utc          | 2023-09-05T08:00:00Z                |
      | end_dttm_utc            | 2023-09-05T08:30:00Z               |
      | event_id                | <null> |
      | description             | <null>                       |
      | settlement_status       | AWAITING_DATA                         |
      | business_process_status | IN_PROCESS                         |
      | source_system_type      | <null>                                 |
      | processing_status       |   <null>   |
      | change_comments    | Change business_process_status |
    Then the response should include the updated settlement
    * GET settlement should return the updated entity
    * changes should be recorded in the settlement audit log

    # Cleanup
    Given I DELETE the settlement

    # POST a new settlement with all non-nulls
    When I POST a settlement with the following properties:
      | settlement_type         | ONGOING_DATA_SUBMISSION             |
      | settlement_subtype      | TVA event                           |
      | start_dttm_utc          | 2023-09-05T08:00:00Z                |
      | end_dttm_utc            | 2023-09-05T08:30:00Z               |
      | event_id                | <uuid> |
      | description             | Non-null test                      |
      | settlement_status       | AWAITING_DATA                         |
      | business_process_status | NOT_STARTED                         |
      | source_system_type      | NGP                                |
      | product_id              | <product1>                         |
     | processing_status       | FOOBAR                             |
    Then the response should include the new settlement
    And GET settlement should return the new entity
    But no entries should be found in the settlement audit log

    # PUT: missing properties become nulls
    When I PUT the settlement with new values:
      | settlement_id         | <last-settlement-id>             |
      | settlement_type         | ONGOING_DATA_SUBMISSION             |
      | settlement_subtype      | TVA event                           |
      | start_dttm_utc          | 2023-09-05T08:00:00Z                |
      | end_dttm_utc            | 2023-09-05T08:30:00Z               |
      | settlement_status       | AWAITING_DATA                         |
      | business_process_status | IN_PROCESS                         |
      | change_comments    | Change business_process_status |
    Then the response should include the updated settlement
    * GET settlement should return the updated entity
    * changes should be recorded in the settlement audit log

     # Cleanup
    Given I DELETE the settlement


  Scenario: PATCH processing_status

    # POST a new settlement
    When I POST a settlement with the following properties:
      | settlement_type         | ONGOING_DATA_SUBMISSION             |
      | settlement_subtype      | TVA event                           |
      | start_dttm_utc          | 2023-09-05T08:00:00Z                |
      | end_dttm_utc            | 2023-09-05T08:30:00Z                |
      | event_id                | <uuid> |
      | description             | PATCH /processing_status                        |
      | settlement_status       | PRELIMINARY                         |
      | business_process_status | NOT_STARTED                         |
      | source_system_type      | NGP                                 |
      | processing_status       |   FOO   |
    Then the response should include the new settlement
    And GET settlement should return the new entity
    But no entries should be found in the settlement audit log

    # PATCH processing_status
    When I PATCH the settlement with new values:
      | settlement_id         | <last-settlement-id>             |
      | processing_status | BAR        |
      | change_comments   | Update processing_status via PATCH    |
    Then the response should include the updated settlement
    * GET settlement should return the updated entity

     # PATCH settlement_status
    When I PATCH the settlement with new values:
      | settlement_id         | <last-settlement-id>             |
      | settlement_status       | FINALIZED                         |
      | change_comments   | Update settlement_status via PATCH    |
    Then the response should include the updated settlement
    * GET settlement should return the updated entity
    * changes should be recorded in the settlement audit log

    # PATCH both
    When I PATCH the settlement with new values:
      | settlement_id         | <last-settlement-id>             |
      | processing_status | WOWZER        |
      | settlement_status       | AWAITING_DATA                         |
      | change_comments   | Update both via PATCH    |
    Then the response should include the updated settlement
    * GET settlement should return the updated entity
    * changes should be recorded in the settlement audit log

    # cleanup
    When I DELETE the settlement
    Then the DELETE settlement details should specify 0 settlement items and 0 settlement item intervals


  Scenario: inputs_available_until_dttm_utc field behavior at settlement level

  # POST: create settlement without the field -> defaults to null
    When I POST a settlement with the following properties:
      | settlement_type                | ONGOING_DATA_SUBMISSION         |
      | settlement_subtype             | TVA event                       |
      | start_dttm_utc                 | 2026-06-17T14:27:02.620Z        |
      | end_dttm_utc                   | 2026-06-17T14:57:02.620Z        |
      | event_id                       | <uuid>                          |
      | description                    | QAA test: inputs field behavior  |
      | settlement_status              | PRELIMINARY                     |
      | business_process_status        | NOT_STARTED                     |
      | source_system_type             | NGP                             |
    Then the response should include the new settlement
    And GET settlement should return the new entity
    And the settlement inputs_available_until_dttm_utc field should be null
    When I DELETE the settlement

  # POST: explicit null
#    Given I expect the next API call to return a status code of 400 and details of "body: data/inputs_available_until_dttm_utc must match pattern 'Z$'"
#    When I POST a settlement with the following properties:
#      | settlement_type                | ONGOING_DATA_SUBMISSION         |
#      | settlement_subtype             | TVA event                       |
#      | start_dttm_utc                 | 2026-06-17T14:27:02.620Z        |
#      | end_dttm_utc                   | 2026-06-17T14:57:02.620Z        |
#      | event_id                       | <uuid>                          |
#      | description                    | QAA test: inputs field null      |
#      | settlement_status              | PRELIMINARY                     |
#      | business_process_status        | NOT_STARTED                     |
#      | source_system_type             | NGP                             |
#      | inputs_available_until_dttm_utc | null                           |
#    Then the expected status should be returned

  # POST: set future timestamp
    When I POST a settlement with the following properties:
      | settlement_type                | ONGOING_DATA_SUBMISSION         |
      | settlement_subtype             | TVA event                       |
      | start_dttm_utc                 | 2026-06-17T14:27:02.620Z        |
      | end_dttm_utc                   | 2026-06-17T14:57:02.620Z        |
      | event_id                       | <uuid>                          |
      | description                    | QAA test: inputs field future   |
      | settlement_status              | PRELIMINARY                     |
      | business_process_status        | NOT_STARTED                     |
      | source_system_type             | NGP                             |
      | inputs_available_until_dttm_utc | 2126-06-17T15:27:02.620Z       |
    Then the response should include the new settlement
    And GET settlement should return the new entity
    And the settlement inputs_available_until_dttm_utc field should be set
    When I DELETE the settlement

  # POST: set past timestamp - can not delete it
    When I POST a settlement with the following properties:
      | settlement_type                | ONGOING_DATA_SUBMISSION         |
      | settlement_subtype             | TVA event                       |
      | start_dttm_utc                 | 2026-06-17T14:27:02.620Z        |
      | end_dttm_utc                   | 2026-06-17T14:57:02.620Z        |
      | event_id                       | <uuid>                          |
      | description                    | QAA test: inputs field past     |
      | settlement_status              | PRELIMINARY                     |
      | business_process_status        | NOT_STARTED                     |
      | source_system_type             | NGP                             |
      | inputs_available_until_dttm_utc | 2025-06-17T13:27:02.620Z       |
    Then the response should include the new settlement
    And GET settlement should return the new entity
    And the settlement inputs_available_until_dttm_utc field should be set
    Given I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I DELETE the settlement
    Then the expected status should be returned

    # PUT: future timestamp - can delete settlement
    When I PUT the settlement with new values:
          | settlement_id                  | <last-settlement-id>            |
          | inputs_available_until_dttm_utc | 2126-06-17T15:27:02.620Z       |
          | change_comments               | Set inputs_available_until     |
          | settlement_type         | ONGOING_DATA_SUBMISSION             |
          | settlement_subtype      | TVA event                           |
          | start_dttm_utc          | 2023-09-05T08:00:00Z                |
          | end_dttm_utc            | 2023-09-05T08:30:00Z                |
          | settlement_status       | PRELIMINARY                         |
          | business_process_status | NOT_STARTED                         |
        Then the response should include the updated settlement
        And GET settlement should return the updated entity
        And the settlement inputs_available_until_dttm_utc field should be set
    When I DELETE the settlement
    Then the DELETE settlement details should specify 0 settlement items and 0 settlement item intervals

  # POST: invalid timestamp
    Given I expect the next API call to return a status code of 400 and details of "data/inputs_available_until_dttm_utc must match pattern 'Z$'"
    When I POST a settlement with the following properties:
      | settlement_type                | ONGOING_DATA_SUBMISSION         |
      | settlement_subtype             | TVA event                       |
      | start_dttm_utc                 | 2026-06-17T14:27:02.620Z        |
      | end_dttm_utc                   | 2026-06-17T14:57:02.620Z        |
      | event_id                       | <uuid>                          |
      | description                    | QAA test: inputs field invalid  |
      | settlement_status              | PRELIMINARY                     |
      | business_process_status        | NOT_STARTED                     |
      | source_system_type             | NGP                             |
      | inputs_available_until_dttm_utc | not-a-timestamp                |
    Then the expected status should be returned

Scenario: Check that PATCH works with inputs_available_until_dttm_utc
  # PATCH: allowed for inputs_available_until_dttm_utc
    When I POST a settlement with the following properties:
      | settlement_type                | ONGOING_DATA_SUBMISSION         |
      | settlement_subtype             | TVA event                       |
      | start_dttm_utc                 | 2026-06-17T14:27:02.620Z        |
      | end_dttm_utc                   | 2026-06-17T14:57:02.620Z        |
      | event_id                       | <uuid>                          |
      | description                    | QAA test: inputs field behavior  |
      | settlement_status              | PRELIMINARY                     |
      | business_process_status        | NOT_STARTED                     |
      | source_system_type             | NGP                             |
    Then the response should include the new settlement
    And GET settlement should return the new entity
    And the settlement inputs_available_until_dttm_utc field should be null

    When I PATCH the settlement with new values:
      | settlement_id                  | <last-settlement-id>            |
      | inputs_available_until_dttm_utc | 2025-06-17T13:27:02.620Z       |
      | change_comments               | Set inputs_available_until     |
    And the settlement inputs_available_until_dttm_utc field should be set

    Given I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I DELETE the settlement
    Then the expected status should be returned

    # DELETE after PATCH
    When I PATCH the settlement with new values:
      | settlement_id                  | <last-settlement-id>            |
      | inputs_available_until_dttm_utc | 2125-06-17T13:27:02.620Z       |
      | change_comments               | Set inputs_available_until     |
    And the settlement inputs_available_until_dttm_utc field should be set
    When I DELETE the settlement