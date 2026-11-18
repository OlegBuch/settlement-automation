@settlement_item_timebound @extra_checks
Feature: Settlement item timebound API - extra negative and property checks

  # Additive file: existing scenarios are untouched. Steps marked NEW are in the Java list in the chat answer.
  # Cleanup deletes only the settlement_item/settlement (existing pattern); rows are soft deleted with the item.

  Background:
    Given I start with an empty context
    And I log in as a settlement API admin

  Scenario: GET list - extra negative and property checks
    When I POST a settlement with the following properties:
      | settlement_type         | ONGOING_DATA_SUBMISSION |
      | settlement_subtype      | TVA event               |
      | start_dttm_utc          | 2023-09-05T08:00:00Z    |
      | end_dttm_utc            | 2023-09-06T08:00:00Z    |
      | event_id                | <uuid>                  |
      | description             | QAA extra GET list |
      | settlement_status       | PRELIMINARY             |
      | business_process_status | NOT_STARTED             |
      | source_system_type      | NGP                     |
    Then the response should include the new settlement
    When I POST a settlement_item with the following properties:
      | settlement_id             | <last-settlement-id> |
      | settlement_level          | REGISTRATION         |
      | settlement_level_id       | QAA extra GET list G1    |
      | submitted_indicator       | true                 |
      | settlement_item_status    | AWAITING_DATA        |
      | atlas_settlement_level_id | <uuid>               |
      | asset_type                | LOAD                 |
      | start_dttm_utc            | 2023-09-05T08:00:00Z |
      | end_dttm_utc              | 2023-09-06T08:00:00Z |
    Then the response should include the new settlement_item
    And I save the settlement_item id for later use with the tag G1
    And I expect the next API call to return a status code of 200 and message of "OK"
    When I POST the following settlement_item_timebound rows:
      | settlement_item_id | start_dttm_utc       | end_dttm_utc         | interval_source | change_comments |
      | <G1>               | 2023-09-05T09:00:00Z | 2023-09-05T10:00:00Z | MEASURED        | g row 1         |
      | <G1>               | 2023-09-05T10:00:00Z | 2023-09-05T11:00:00Z | MEASURED        | g row 2         |
      | <G1>               | 2023-09-05T11:00:00Z | 2023-09-05T12:00:00Z | MEASURED        | g row 3         |
    Then the expected status should be returned

    # property: all rows returned across pages, per_page=1
    When I call GET settlement_item_timebound with settlement_item_id: <G1> start_dttm_utc: missing end_dttm_utc: missing per_page: 1 direction: forward
    Then GET settlement_item_timebound should return only expected active rows
    And GET settlement_item_timebound should return 3 rows
    And the settlement_item_timebound response should be paged

    # window boundaries (start: row end must be AFTER start; end: row start must be BEFORE end)
    When I call GET settlement_item_timebound with settlement_item_id: <G1> start_dttm_utc: 2023-09-05T10:00:00Z end_dttm_utc: missing per_page: 50 direction: forward
    Then GET settlement_item_timebound should return only expected active rows
    And GET settlement_item_timebound should return 2 rows

    When I call GET settlement_item_timebound with settlement_item_id: <G1> start_dttm_utc: missing end_dttm_utc: 2023-09-05T11:00:00Z per_page: 50 direction: forward
    Then GET settlement_item_timebound should return only expected active rows
    And GET settlement_item_timebound should return 2 rows

    When I call GET settlement_item_timebound with settlement_item_id: <G1> start_dttm_utc: 2023-09-05T10:00:00Z end_dttm_utc: 2023-09-05T11:00:00Z per_page: 50 direction: forward
    Then GET settlement_item_timebound should return 1 rows

    And I expect the next API call to return a status code of 404 and message of "Not Found"
    When I call GET settlement_item_timebound with settlement_item_id: <G1> start_dttm_utc: 2023-09-05T12:00:00Z end_dttm_utc: 2023-09-05T13:00:00Z per_page: 50 direction: forward
    Then the expected status should be returned

    And I expect the next API call to return a status code of 404 and message of "Not Found"
    When I call GET settlement_item_timebound with settlement_item_id: <G1> start_dttm_utc: 2023-09-05T08:00:00Z end_dttm_utc: 2023-09-05T09:00:00Z per_page: 50 direction: forward
    Then the expected status should be returned

    When I call GET settlement_item_timebound with settlement_item_id: <G1> start_dttm_utc: 2023-09-05T09:30:00Z end_dttm_utc: 2023-09-05T09:31:00Z per_page: 50 direction: forward
    Then GET settlement_item_timebound should return 1 rows

    # negatives with existing step
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I call GET settlement_item_timebound with settlement_item_id: <G1> start_dttm_utc: 2023-09-05T11:00:00Z end_dttm_utc: 2023-09-05T10:00:00Z per_page: 50 direction: forward
    Then the expected status should be returned
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I call GET settlement_item_timebound with settlement_item_id: <G1> start_dttm_utc: missing end_dttm_utc: missing per_page: -1 direction: forward
    Then the expected status should be returned

    # negatives / properties with raw query (NEW step)
    And I expect the next API call to return a status code of 200 and message of "OK"
    When I call GET settlement_item_timebound with settlement_item_id <G1> and raw query "per_page=0"
    Then the expected status should be returned

    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I call GET settlement_item_timebound with settlement_item_id <G1> and raw query "per_page=abc"
    Then the expected status should be returned

    And I expect the next API call to return a status code of 200 and message of "OK"
    When I call GET settlement_item_timebound with settlement_item_id <G1> and raw query "page=0"
    Then the expected status should be returned

    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I call GET settlement_item_timebound with settlement_item_id <G1> and raw query "page=abc"
    Then the expected status should be returned

    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I call GET settlement_item_timebound with settlement_item_id <G1> and raw query "include_deleted=maybe"
    Then the expected status should be returned

    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I call GET settlement_item_timebound with settlement_item_id <G1> and raw query "start_dttm_utc=not-a-date"
    Then the expected status should be returned

    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I call GET settlement_item_timebound with settlement_item_id <G1> and raw query "end_dttm_utc=not-a-date"
    Then the expected status should be returned

    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I call GET settlement_item_timebound with settlement_item_id <G1> and raw query "start_dttm_utc=2023-09-05T09:00:00%2B02:00"
    Then the expected status should be returned

    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I call GET settlement_item_timebound with settlement_item_id <G1> and raw query "end_dttm_utc=2023-09-05T10:00:00"
    Then the expected status should be returned

    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I call GET settlement_item_timebound with raw query "start_dttm_utc=2023-09-05T09:00:00Z"
    Then the expected status should be returned

    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I call GET settlement_item_timebound with raw query "settlement_item_id=not-a-uuid"
    Then the expected status should be returned

    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I call GET settlement_item_timebound with raw query "settlement_item_id="
    Then the expected status should be returned

    # page beyond the last page
    And I expect the next API call to return a status code of 404 and message of "Not Found"
    When I call GET settlement_item_timebound with settlement_item_id <G1> and raw query "per_page=1&page=99"
    Then the expected status should be returned

    # unknown item returns an empty list (confirm contract)
    And I expect the next API call to return a status code of 404 and message of "Not Found"
    When I call GET settlement_item_timebound with settlement_item_id: <uuid> start_dttm_utc: missing end_dttm_utc: missing per_page: 10 direction: forward
    Then the expected status should be returned

    # include_deleted on list
    When I POST a settlement_item_timebound row for <G1> from 2023-09-05T12:00:00Z to 2023-09-05T13:00:00Z
    And I save the last settlement_item_timebound id with the tag TB_G4
    When I DELETE settlement_item_timebound with id tag TB_G4
    Then the expected status should be returned

    Given I set include_deleted=missing
    When I call GET settlement_item_timebound with settlement_item_id: <G1> start_dttm_utc: missing end_dttm_utc: missing per_page: 50 direction: forward
    Then GET settlement_item_timebound should return 3 rows

    Given I set include_deleted=false
    When I call GET settlement_item_timebound with settlement_item_id: <G1> start_dttm_utc: missing end_dttm_utc: missing per_page: 50 direction: forward
    Then GET settlement_item_timebound should return 3 rows

    Given I set include_deleted=true
    When I call GET settlement_item_timebound with settlement_item_id: <G1> start_dttm_utc: missing end_dttm_utc: missing per_page: 50 direction: forward
    Then GET settlement_item_timebound should return 4 rows

    # gzip (NEW steps)
    Given I set include_deleted=missing
    When I call GET settlement_item_timebound with settlement_item_id <G1> and header "accept-encoding" = "gzip"
    Then the response header "content-encoding" should be "gzip"
    And the decompressed body should be valid JSON with meta.total 3
    When I call GET settlement_item_timebound with settlement_item_id <G1> and header "accept-encoding" = "identity"
    Then the response should not have header "content-encoding"
    And the decompressed body should be valid JSON with meta.total 3

    # cleanup
    When I DELETE the settlement_item
    Then the DELETE settlement_item details should specify 1 settlement items and 0 settlement item intervals
    When I DELETE the settlement
    Then the DELETE settlement details should specify 0 settlement items and 0 settlement item intervals

  Scenario: GET by id - property and negative checks
    When I POST a settlement with the following properties:
      | settlement_type         | ONGOING_DATA_SUBMISSION |
      | settlement_subtype      | TVA event               |
      | start_dttm_utc          | 2023-09-05T08:00:00Z    |
      | end_dttm_utc            | 2023-09-06T08:00:00Z    |
      | event_id                | <uuid>                  |
      | description             | QAA extra GET by id |
      | settlement_status       | PRELIMINARY             |
      | business_process_status | NOT_STARTED             |
      | source_system_type      | NGP                     |
    Then the response should include the new settlement
    When I POST a settlement_item with the following properties:
      | settlement_id             | <last-settlement-id> |
      | settlement_level          | REGISTRATION         |
      | settlement_level_id       | QAA extra GET by id G2    |
      | submitted_indicator       | true                 |
      | settlement_item_status    | AWAITING_DATA        |
      | atlas_settlement_level_id | <uuid>               |
      | asset_type                | LOAD                 |
      | start_dttm_utc            | 2023-09-05T08:00:00Z |
      | end_dttm_utc              | 2023-09-06T08:00:00Z |
    Then the response should include the new settlement_item
    And I save the settlement_item id for later use with the tag G2
    And I expect the next API call to return a status code of 200 and message of "OK"
    When I POST a settlement_item_timebound row with the following data:
      | settlement_item_id                 | <G2>                 |
      | start_dttm_utc                     | 2023-09-05T09:00:00Z |
      | end_dttm_utc                       | 2023-09-05T10:00:00Z |
      | interval_source                    | MEASURED             |
      | nomination_value                   | 100.5                |
      | nomination_uom                     | MW                   |
      | revenue_value                      | 500.80               |
      | payment_penalty_input_value        | -56.78               |
      | payment_penalty_value              | 9.873                |
      | payment_penalty_notes              | note                 |
      | currency                           | USD                  |
      | change_comments                    | get by id props      |
    Then the expected status should be returned
    And I save the last settlement_item_timebound id with the tag TB_G2
    When I call GET settlement_item_timebound for id tag TB_G2
    Then GET settlement_item_timebound by id should match saved row TB_G2
    And GET settlement_item_timebound by id should have field settlement_item_id equal to <G2>
    And GET settlement_item_timebound by id should have field interval_source equal to MEASURED
    And GET settlement_item_timebound by id should have field currency equal to USD
    And GET settlement_item_timebound by id should have field nomination_uom equal to MW
    And GET settlement_item_timebound by id should have field payment_nomination_uom equal to null
    And GET settlement_item_timebound by id should have field deleted equal to false
    And GET settlement_item_timebound by id should have a numeric field nomination_value equal to 100.5
    And GET settlement_item_timebound by id should have a numeric field payment_penalty_input_value equal to -56.78
    And GET settlement_item_timebound by id should have a string field revenue_value
    And GET settlement_item_timebound by id should have timestamps in UTC Z format

    Given I set include_deleted=true
    When I call GET settlement_item_timebound for id tag TB_G2
    Then GET settlement_item_timebound by id should have field deleted equal to false

    When I DELETE settlement_item_timebound with id tag TB_G2
    Then the expected status should be returned
    Given I set include_deleted=false
    And I expect the next API call to return a status code of 404 and message of "Not Found"
    When I call GET settlement_item_timebound for id tag TB_G2
    Then the expected status should be returned
    Given I set include_deleted=true
    When I call GET settlement_item_timebound for id tag TB_G2
    Then GET settlement_item_timebound by id should have field deleted equal to true

    Given I set include_deleted=missing
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I call GET settlement_item_timebound for id 00000000-0000-0000-0000-00000000000Z
    Then the expected status should be returned
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I call GET settlement_item_timebound for id 123
    Then the expected status should be returned
    And I expect the next API call to return a status code of 404 and message of "Not Found"
    When I call GET settlement_item_timebound for id 00000000-0000-0000-0000-000000000000
    Then the expected status should be returned
    Given I set include_deleted=missing
    And I expect the next API call to return a status code of 404 and message of "Not Found"
    When I call GET settlement_item_timebound for id tag TB_G2
    Then the expected status should be returned

    # cleanup
    When I DELETE the settlement_item
    Then the DELETE settlement_item details should specify 1 settlement items and 0 settlement item intervals
    When I DELETE the settlement
    Then the DELETE settlement details should specify 0 settlement items and 0 settlement item intervals

  Scenario: POST - extra negative and overlap checks
    When I POST a settlement with the following properties:
      | settlement_type         | ONGOING_DATA_SUBMISSION |
      | settlement_subtype      | TVA event               |
      | start_dttm_utc          | 2023-09-05T08:00:00Z    |
      | end_dttm_utc            | 2023-09-06T08:00:00Z    |
      | event_id                | <uuid>                  |
      | description             | QAA extra POST |
      | settlement_status       | PRELIMINARY             |
      | business_process_status | NOT_STARTED             |
      | source_system_type      | NGP                     |
    Then the response should include the new settlement
    When I POST a settlement_item with the following properties:
      | settlement_id             | <last-settlement-id> |
      | settlement_level          | REGISTRATION         |
      | settlement_level_id       | QAA extra POST P1    |
      | submitted_indicator       | true                 |
      | settlement_item_status    | AWAITING_DATA        |
      | atlas_settlement_level_id | <uuid>               |
      | asset_type                | LOAD                 |
      | start_dttm_utc            | 2023-09-05T08:00:00Z |
      | end_dttm_utc              | 2023-09-06T08:00:00Z |
    Then the response should include the new settlement_item
    And I save the settlement_item id for later use with the tag P1
    When I POST a settlement_item with the following properties:
      | settlement_id             | <last-settlement-id> |
      | settlement_level          | REGISTRATION         |
      | settlement_level_id       | QAA extra POST P2    |
      | submitted_indicator       | true                 |
      | settlement_item_status    | AWAITING_DATA        |
      | atlas_settlement_level_id | <uuid>               |
      | asset_type                | LOAD                 |
      | start_dttm_utc            | 2023-09-05T08:00:00Z |
      | end_dttm_utc              | 2023-09-06T08:00:00Z |
    Then the response should include the new settlement_item
    And I save the settlement_item id for later use with the tag P2
    And I expect the next API call to return a status code of 200 and message of "OK"
    When I POST a settlement_item_timebound row with the following data:
      | settlement_item_id | <P1> |
      | start_dttm_utc     | 2023-09-05T14:00:00Z |
      | end_dttm_utc       | 2023-09-05T15:00:00Z |
      | interval_source    | MEASURED |
      | change_comments    | baseline |
    Then the expected status should be returned
    And I save the last settlement_item_timebound id with the tag TB_P1

    # required fields missing (one by one)
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I POST a settlement_item_timebound row with the following data:
      | start_dttm_utc     | 2023-09-05T09:00:00Z |
      | end_dttm_utc       | 2023-09-05T10:00:00Z |
      | settlement_item_id | <P1> |
      | change_comments | missing interval_source |
    Then the expected status should be returned
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I POST a settlement_item_timebound row with the following data:
      | settlement_item_id | <P1> |
      | end_dttm_utc       | 2023-09-05T10:00:00Z |
      | interval_source    | MEASURED |
      | change_comments | missing start_dttm_utc |
    Then the expected status should be returned
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I POST a settlement_item_timebound row with the following data:
      | settlement_item_id | <P1> |
      | start_dttm_utc     | 2023-09-05T09:00:00Z |
      | interval_source    | MEASURED |
      | change_comments | missing end_dttm_utc |
    Then the expected status should be returned
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I POST a settlement_item_timebound row with the following data:
      | start_dttm_utc     | 2023-09-05T09:00:00Z |
      | end_dttm_utc       | 2023-09-05T10:00:00Z |
      | interval_source    | MEASURED |
      | change_comments | missing settlement_item_id |
    Then the expected status should be returned

    # invalid values
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I POST a settlement_item_timebound row with the following data:
      | settlement_item_id | <P1> |
      | start_dttm_utc     | 2023-09-05T09:00:00Z |
      | end_dttm_utc       | 2023-09-05T09:00:00Z |
      | interval_source    | MEASURED |
      | change_comments    | end equals start |
    Then the expected status should be returned
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I POST a settlement_item_timebound row with the following data:
      | settlement_item_id | <P1> |
      | start_dttm_utc     | 2023-09-05T09:00:00Z |
      | end_dttm_utc       | 2023-09-05T10:00:00Z |
      | interval_source    | measured |
      | change_comments    | lowercase source |
    Then the expected status should be returned
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I POST a settlement_item_timebound row with the following data:
      | settlement_item_id | <P1> |
      | start_dttm_utc     | 2023-09-05T09:00:00Z |
      | end_dttm_utc       | 2023-09-05T10:00:00Z |
      | interval_source    | <empty> |
      | change_comments    | empty source |
    Then the expected status should be returned
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I POST a settlement_item_timebound row with the following data:
      | settlement_item_id | <P1> |
      | start_dttm_utc     | 2023-09-05T09:00:00+02:00 |
      | end_dttm_utc       | 2023-09-05T10:00:00+02:00 |
      | interval_source    | MEASURED |
      | change_comments    | non UTC offset |
    Then the expected status should be returned
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I POST a settlement_item_timebound row with the following data:
      | settlement_item_id | <P1> |
      | start_dttm_utc     | 2023-09-05T09:00:00 |
      | end_dttm_utc       | 2023-09-05T10:00:00 |
      | interval_source    | MEASURED |
      | change_comments    | no timezone |
    Then the expected status should be returned
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I POST a settlement_item_timebound row with the following data:
      | settlement_item_id | <P1> |
      | start_dttm_utc     | not-a-date |
      | end_dttm_utc       | 2023-09-05T10:00:00Z |
      | interval_source    | MEASURED |
      | change_comments    | garbage start |
    Then the expected status should be returned
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I POST a settlement_item_timebound row with the following data:
      | settlement_item_id | <P1> |
      | start_dttm_utc     | 2023-09-05T09:00:00Z |
      | end_dttm_utc       | not-a-date |
      | interval_source    | MEASURED |
      | change_comments    | garbage end |
    Then the expected status should be returned
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I POST a settlement_item_timebound row with the following data:
      | settlement_item_id | <P1> |
      | start_dttm_utc     | 2023-02-30T09:00:00Z |
      | end_dttm_utc       | 2023-09-05T10:00:00Z |
      | interval_source    | MEASURED |
      | change_comments    | impossible date |
    Then the expected status should be returned
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I POST a settlement_item_timebound row with the following data:
      | settlement_item_id | not-a-uuid           |
      | start_dttm_utc     | 2023-09-05T09:00:00Z |
      | end_dttm_utc       | 2023-09-05T10:00:00Z |
      | interval_source    | MEASURED             |
    Then the expected status should be returned
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I POST a settlement_item_timebound row with the following data:
      | settlement_item_id | <P1> |
      | start_dttm_utc     | 2023-09-05T09:00:00Z |
      | end_dttm_utc       | 2023-09-05T10:00:00Z |
      | interval_source    | MEASURED |
      | currency | usd |
      | change_comments    | bad currency |
    Then the expected status should be returned
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I POST a settlement_item_timebound row with the following data:
      | settlement_item_id | <P1> |
      | start_dttm_utc     | 2023-09-05T09:00:00Z |
      | end_dttm_utc       | 2023-09-05T10:00:00Z |
      | interval_source    |  |
      | change_comments    | bad currency |
    Then the expected status should be returned
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I POST a settlement_item_timebound row with the following data:
      | settlement_item_id | <P1> |
      | start_dttm_utc     | 2023-09-05T09:00:00Z |
      | end_dttm_utc       | 2023-09-05T10:00:00Z |
      | interval_source    | MEASURED |
      | currency | US |
      | change_comments    | bad currency |
    Then the expected status should be returned
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I POST a settlement_item_timebound row with the following data:
      | settlement_item_id | <P1> |
      | start_dttm_utc     | 2023-09-05T09:00:00Z |
      | end_dttm_utc       | 2023-09-05T10:00:00Z |
      | interval_source    | MEASURED |
      | nomination_uom | <empty>, string, 1231231 |
      | change_comments    | bad nomination_uom |
    Then the expected status should be returned
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I POST a settlement_item_timebound row with the following data:
      | settlement_item_id | <P1> |
      | start_dttm_utc     | 2023-09-05T09:00:00Z |
      | end_dttm_utc       | 2023-09-05T10:00:00Z |
      | interval_source    | MEASURED |
      | payment_nomination_uom | bad_uom |
      | change_comments    | bad payment_nomination_uom |
    Then the expected status should be returned
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I POST a settlement_item_timebound row with the following data:
      | settlement_item_id | <P1> |
      | start_dttm_utc     | 2023-09-05T09:00:00Z |
      | end_dttm_utc       | 2023-09-05T10:00:00Z |
      | interval_source    | MEASURED |
      | payment_nomination_uom_estimated | bad_uom, bam uom |
      | change_comments    | bad payment_nomination_uom_estimated |
    Then the expected status should be returned
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I POST a settlement_item_timebound row with the following data:
      | settlement_item_id | <P1> |
      | start_dttm_utc     | 2023-09-05T09:00:00Z |
      | end_dttm_utc       | 2023-09-05T10:00:00Z |
      | interval_source    | MEASURED |
      | payment_penalty_input_uom | bad_uom, 123123213 |
      | change_comments    | bad payment_penalty_input_uom |
    Then the expected status should be returned

    # overlap boundaries against baseline 14:00-15:00 (start inclusive, end exclusive)
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I POST a settlement_item_timebound row with the following data:
      | settlement_item_id | <P1> |
      | start_dttm_utc     | 2023-09-05T13:59:59Z |
      | end_dttm_utc       | 2023-09-05T14:00:01Z |
      | interval_source    | MEASURED |
      | change_comments    | 1s overlap at start |
    Then the expected status should be returned
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I POST a settlement_item_timebound row with the following data:
      | settlement_item_id | <P1> |
      | start_dttm_utc     | 2023-09-05T14:59:59Z |
      | end_dttm_utc       | 2023-09-05T15:30:00Z |
      | interval_source    | MEASURED |
      | change_comments    | 1s overlap at end |
    Then the expected status should be returned
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I POST a settlement_item_timebound row with the following data:
      | settlement_item_id | <P1> |
      | start_dttm_utc     | 2023-09-05T14:00:00Z |
      | end_dttm_utc       | 2023-09-05T15:00:00Z |
      | interval_source    | MEASURED |
      | change_comments    | exact duplicate |
    Then the expected status should be returned
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I POST a settlement_item_timebound row with the following data:
      | settlement_item_id | <P1> |
      | start_dttm_utc     | 2023-09-05T13:00:00Z |
      | end_dttm_utc       | 2023-09-05T16:00:00Z |
      | interval_source    | MEASURED |
      | change_comments    | contains baseline |
    Then the expected status should be returned
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I POST a settlement_item_timebound row with the following data:
      | settlement_item_id | <P1> |
      | start_dttm_utc     | 2023-09-05T14:10:00Z |
      | end_dttm_utc       | 2023-09-05T14:20:00Z |
      | interval_source    | MEASURED |
      | change_comments    | inside baseline |
    Then the expected status should be returned
    And I expect the next API call to return a status code of 200 and message of "OK"
    When I POST a settlement_item_timebound row with the following data:
      | settlement_item_id | <P1> |
      | start_dttm_utc     | 2023-09-05T13:00:00Z |
      | end_dttm_utc       | 2023-09-05T14:00:00Z |
      | interval_source    | MEASURED |
      | change_comments    | touches at start |
    Then the expected status should be returned
    And I save the last settlement_item_timebound id with the tag TB_P1_BEFORE
    And I expect the next API call to return a status code of 200 and message of "OK"
    When I POST a settlement_item_timebound row with the following data:
      | settlement_item_id | <P1> |
      | start_dttm_utc     | 2023-09-05T15:00:00Z |
      | end_dttm_utc       | 2023-09-05T16:00:00Z |
      | interval_source    | MEASURED |
      | change_comments    | touches at end |
    Then the expected status should be returned
    And I save the last settlement_item_timebound id with the tag TB_P1_AFTER
    And I expect the next API call to return a status code of 200 and message of "OK"
    When I POST a settlement_item_timebound row with the following data:
      | settlement_item_id | <P2> |
      | start_dttm_utc     | 2023-09-05T14:00:00Z |
      | end_dttm_utc       | 2023-09-05T15:00:00Z |
      | interval_source    | MEASURED |
      | change_comments    | same range other item |
    Then the expected status should be returned
    And I save the last settlement_item_timebound id with the tag TB_P2

    # overlap inside one request and batch atomicity
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I POST the following settlement_item_timebound rows:
      | settlement_item_id | start_dttm_utc       | end_dttm_utc         | interval_source | change_comments |
      | <P1>               | 2023-09-05T18:00:00Z | 2023-09-05T19:00:00Z | MEASURED        | same req 1      |
      | <P1>               | 2023-09-05T18:30:00Z | 2023-09-05T19:30:00Z | MEASURED        | same req 2      |
    Then the expected status should be returned

    # overlap with a soft deleted row is allowed
    When I DELETE settlement_item_timebound with id tag TB_P1
    Then the expected status should be returned
    And I expect the next API call to return a status code of 200 and message of "OK"
    When I POST a settlement_item_timebound row with the following data:
      | settlement_item_id | <P1> |
      | start_dttm_utc     | 2023-09-05T14:00:00Z |
      | end_dttm_utc       | 2023-09-05T15:00:00Z |
      | interval_source    | MEASURED |
      | change_comments    | over deleted row |
    Then the expected status should be returned

    # nothing was created by any rejected call: baseline neighbours + the new row only
    When I call GET settlement_item_timebound with settlement_item_id: <P1> start_dttm_utc: missing end_dttm_utc: missing per_page: 50 direction: forward
    Then GET settlement_item_timebound should return only expected active rows
    And GET settlement_item_timebound should return 3 rows

    # mass assignment: client id and deleted flag are ignored
    And I expect the next API call to return a status code of 200 and message of "OK"
    When I POST a settlement_item_timebound row with the following data:
      | settlement_item_id           | <P2>                 |
      | settlement_item_timebound_id | 11111111-1111-1111-1111-111111111111 |
      | start_dttm_utc               | 2023-09-05T20:00:00Z |
      | end_dttm_utc                 | 2023-09-05T21:00:00Z |
      | interval_source              | MEASURED             |
    Then the expected status should be returned
    Then the last POST response should have a generated id different from 11111111-1111-1111-1111-111111111111 and deleted false

    # special characters are stored as plain text
    And I expect the next API call to return a status code of 200 and message of "OK"
    When I POST a settlement_item_timebound row with the following data:
      | settlement_item_id    | <P2>                 |
      | start_dttm_utc        | 2023-09-05T22:00:00Z |
      | end_dttm_utc          | 2023-09-05T23:00:00Z |
      | interval_source       | MEASURED             |
      | payment_penalty_notes | ' OR 1=1; -- <script>alert(1)</script> |
      | change_comments       | special chars        |
    Then the expected status should be returned
    And I save the last settlement_item_timebound id with the tag TB_P2_SPECIAL
    When I call GET settlement_item_timebound for id tag TB_P2_SPECIAL
    Then GET settlement_item_timebound by id should have field payment_penalty_notes equal to ' OR 1=1; -- <script>alert(1)</script>

    # empty array (NEW step)
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I POST an empty settlement_item_timebound array
    Then the expected status should be returned

    # cleanup
    When I DELETE settlement item with the id tag P1
    Then the DELETE settlement_item details should specify 1 settlement items and 0 settlement item intervals
    When I DELETE settlement item with the id tag P2
    Then the DELETE settlement_item details should specify 1 settlement items and 0 settlement item intervals
    When I DELETE the settlement
    Then the DELETE settlement details should specify 0 settlement items and 0 settlement item intervals

  Scenario: PUT and PATCH - extra negative and property checks
    When I POST a settlement with the following properties:
      | settlement_type         | ONGOING_DATA_SUBMISSION |
      | settlement_subtype      | TVA event               |
      | start_dttm_utc          | 2023-09-05T08:00:00Z    |
      | end_dttm_utc            | 2023-09-06T08:00:00Z    |
      | event_id                | <uuid>                  |
      | description             | QAA extra PUT PATCH |
      | settlement_status       | PRELIMINARY             |
      | business_process_status | NOT_STARTED             |
      | source_system_type      | NGP                     |
    Then the response should include the new settlement
    When I POST a settlement_item with the following properties:
      | settlement_id             | <last-settlement-id> |
      | settlement_level          | REGISTRATION         |
      | settlement_level_id       | QAA extra PUT PATCH U1    |
      | submitted_indicator       | true                 |
      | settlement_item_status    | AWAITING_DATA        |
      | atlas_settlement_level_id | <uuid>               |
      | asset_type                | LOAD                 |
      | start_dttm_utc            | 2023-09-05T08:00:00Z |
      | end_dttm_utc              | 2023-09-06T08:00:00Z |
    Then the response should include the new settlement_item
    And I save the settlement_item id for later use with the tag U1
    When I POST a settlement_item with the following properties:
      | settlement_id             | <last-settlement-id> |
      | settlement_level          | REGISTRATION         |
      | settlement_level_id       | QAA extra PUT PATCH U2    |
      | submitted_indicator       | true                 |
      | settlement_item_status    | AWAITING_DATA        |
      | atlas_settlement_level_id | <uuid>               |
      | asset_type                | LOAD                 |
      | start_dttm_utc            | 2023-09-05T08:00:00Z |
      | end_dttm_utc              | 2023-09-06T08:00:00Z |
    Then the response should include the new settlement_item
    And I save the settlement_item id for later use with the tag U2
    And I expect the next API call to return a status code of 200 and message of "OK"
    When I POST a settlement_item_timebound row with the following data:
      | settlement_item_id | <U1> |
      | start_dttm_utc     | 2023-09-05T09:00:00Z |
      | end_dttm_utc       | 2023-09-05T10:00:00Z |
      | interval_source    | MEASURED |
      | nomination_value | 10.5 |
      | nomination_uom | MW |
      | currency | USD |
      | change_comments    | u base |
    Then the expected status should be returned
    And I save the last settlement_item_timebound id with the tag TB_U1
    And I expect the next API call to return a status code of 200 and message of "OK"
    When I POST a settlement_item_timebound row with the following data:
      | settlement_item_id | <U1> |
      | start_dttm_utc     | 2023-09-05T12:00:00Z |
      | end_dttm_utc       | 2023-09-05T13:00:00Z |
      | interval_source    | MEASURED |
      | change_comments    | u other |
    Then the expected status should be returned
    And I save the last settlement_item_timebound id with the tag TB_U1_OTHER
    And I expect the next API call to return a status code of 200 and message of "OK"
    When I POST a settlement_item_timebound row with the following data:
      | settlement_item_id | <U2> |
      | start_dttm_utc     | 2023-09-05T09:30:00Z |
      | end_dttm_utc       | 2023-09-05T10:30:00Z |
      | interval_source    | MEASURED |
      | change_comments    | u other item |
    Then the expected status should be returned
    And I save the last settlement_item_timebound id with the tag TB_U2

    # PATCH happy path keeps the other columns
    When I PATCH settlement_item_timebound with id tag TB_U1 and values:
      | settlement_item_id | <U1> |
      | start_dttm_utc     | 2023-09-05T09:30:00Z |
      | end_dttm_utc       | 2023-09-05T10:30:00Z |
      | nomination_value | 12.5  |
      | change_comments  | patch |
    Then the expected status should be returned
    When I call GET settlement_item_timebound for id tag TB_U1
    Then GET settlement_item_timebound by id should have a numeric field nomination_value equal to 12.5
    And GET settlement_item_timebound by id should have field currency equal to USD
    And GET settlement_item_timebound by id should have field nomination_uom equal to MW

    # PATCH explicit null clears only that column
    When I PATCH settlement_item_timebound with id tag TB_U1 and values:
      | settlement_item_id | <U1> |
      | start_dttm_utc     | 2023-09-05T09:30:00Z |
      | end_dttm_utc       | 2023-09-05T10:30:00Z |
      | currency        | <null>   |
      | change_comments | clear cc |
    Then the expected status should be returned
    When I call GET settlement_item_timebound for id tag TB_U1
    Then GET settlement_item_timebound by id should have field currency equal to null
    And GET settlement_item_timebound by id should have field nomination_uom equal to MW

    # PUT replaces all columns: omitted optional columns become null
    When I PUT settlement_item_timebound with id tag TB_U1 and values:
      | settlement_item_id | <U1>                 |
      | start_dttm_utc     | 2023-09-05T09:00:00Z |
      | end_dttm_utc       | 2023-09-05T10:00:00Z |
      | interval_source    | MEASURED             |
      | revenue_value      | 77.10                |
      | change_comments    | put                  |
    Then the expected status should be returned
    When I call GET settlement_item_timebound for id tag TB_U1
    Then GET settlement_item_timebound by id should have field revenue_value equal to 77.10
    And GET settlement_item_timebound by id should have field nomination_uom equal to null
    And GET settlement_item_timebound by id should have field nomination_value equal to null

    # PUT required fields missing
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I PUT settlement_item_timebound with id tag TB_U1 and values:
      | settlement_item_id | <U1> |
      | start_dttm_utc     | 2023-09-05T09:00:00Z |
      | end_dttm_utc       | 2023-09-05T10:00:00Z |
      | change_comments | put missing interval_source |
    Then the expected status should be returned
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I PUT settlement_item_timebound with id tag TB_U1 and values:
      | settlement_item_id | <U1> |
      | end_dttm_utc       | 2023-09-05T10:00:00Z |
      | interval_source    | MEASURED |
      | change_comments | put missing start_dttm_utc |
    Then the expected status should be returned
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I PUT settlement_item_timebound with id tag TB_U1 and values:
      | settlement_item_id | <U1> |
      | start_dttm_utc     | 2023-09-05T09:00:00Z |
      | interval_source    | MEASURED |
      | change_comments | put missing end_dttm_utc |
    Then the expected status should be returned
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I PUT settlement_item_timebound with id tag TB_U1 and values:
      | start_dttm_utc     | 2023-09-05T09:00:00Z |
      | end_dttm_utc       | 2023-09-05T10:00:00Z |
      | interval_source    | MEASURED |
      | change_comments | put missing settlement_item_id |
    Then the expected status should be returned

    # invalid values on PUT
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I PUT settlement_item_timebound with id tag TB_U1 and values:
      | settlement_item_id | <U1>                 |
      | start_dttm_utc     | 2023-09-05T10:00:00Z |
      | end_dttm_utc       | 2023-09-05T09:00:00Z |
      | interval_source    | MEASURED             |
    Then the expected status should be returned
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I PUT settlement_item_timebound with id tag TB_U1 and values:
      | settlement_item_id | <U1>                 |
      | start_dttm_utc     | 2023-09-05T09:00:00Z |
      | end_dttm_utc       | 2023-09-05T09:00:00Z |
      | interval_source    | MEASURED             |
    Then the expected status should be returned
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I PUT settlement_item_timebound with id tag TB_U1 and values:
      | settlement_item_id | <U1>                 |
      | start_dttm_utc     | 2023-09-05T09:00:00Z |
      | end_dttm_utc       | 2023-09-05T10:00:00Z |
      | interval_source    | NOT_A_REAL_SRC       |
    Then the expected status should be returned
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I PUT settlement_item_timebound with id tag TB_U1 and values:
      | settlement_item_id | <U1>                 |
      | start_dttm_utc     | 2023-09-05T09:00:00+02:00 |
      | end_dttm_utc       | 2023-09-05T10:00:00+02:00 |
      | interval_source    | MEASURED             |
    Then the expected status should be returned
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I PUT settlement_item_timebound with id not-a-uuid and values:
      | settlement_item_id | <U1>                 |
      | start_dttm_utc     | 2023-09-05T09:00:00Z |
      | end_dttm_utc       | 2023-09-05T10:00:00Z |
      | interval_source    | MEASURED             |
    Then the expected status should be returned
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I PUT settlement_item_timebound with id <uuid> and values:
      | settlement_item_id | <U1>                 |
      | start_dttm_utc     | 2023-09-05T09:00:00Z |
      | end_dttm_utc       | 2023-09-05T10:00:00Z |
      | interval_source    | MEASURED             |
    Then the expected status should be returned
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I PUT settlement_item_timebound with id tag TB_U1 and values:
      | settlement_item_id | <uuid>               |
      | start_dttm_utc     | 2023-09-05T09:00:00Z |
      | end_dttm_utc       | 2023-09-05T10:00:00Z |
      | interval_source    | MEASURED             |
    Then the expected status should be returned

    # invalid values on PATCH (one column each)
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I PATCH settlement_item_timebound with id tag TB_U1 and values:
      | interval_source | NOT_A_REAL_SRC |
    Then the expected status should be returned
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I PATCH settlement_item_timebound with id tag TB_U1 and values:
      | interval_source | measured |
    Then the expected status should be returned
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I PATCH settlement_item_timebound with id tag TB_U1 and values:
      | currency | NOT_A_CURRENCY |
    Then the expected status should be returned
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I PATCH settlement_item_timebound with id tag TB_U1 and values:
      | currency | usd |
    Then the expected status should be returned
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I PATCH settlement_item_timebound with id tag TB_U1 and values:
      | nomination_uom | not_a_uom |
    Then the expected status should be returned
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I PATCH settlement_item_timebound with id tag TB_U1 and values:
      | payment_nomination_uom | not_a_uom |
    Then the expected status should be returned
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I PATCH settlement_item_timebound with id tag TB_U1 and values:
      | payment_nomination_uom_estimated | not_a_uom |
    Then the expected status should be returned
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I PATCH settlement_item_timebound with id tag TB_U1 and values:
      | payment_penalty_input_uom | not_a_uom |
    Then the expected status should be returned
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I PATCH settlement_item_timebound with id tag TB_U1 and values:
      | start_dttm_utc | not-a-date |
    Then the expected status should be returned
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I PATCH settlement_item_timebound with id tag TB_U1 and values:
      | end_dttm_utc | 2023-09-05T10:00:00 |
    Then the expected status should be returned
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I PATCH settlement_item_timebound with id tag TB_U1 and values:
      | start_dttm_utc | 2023-09-05T11:00:00Z |
    Then the expected status should be returned
      # new start is after the stored end 10:00 -> end must be > start
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I PATCH settlement_item_timebound with id tag TB_U1 and values:
      | end_dttm_utc | 2023-09-05T08:00:00Z |
    Then the expected status should be returned
      # new end is before the stored start 09:30 -> end must be > start
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I PATCH settlement_item_timebound with id <uuid> and values:
      | currency | USD |
    Then the expected status should be returned
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I PATCH settlement_item_timebound with id not-a-uuid and values:
      | currency | USD |
    Then the expected status should be returned

    # PATCH may not change protected columns
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I PATCH settlement_item_timebound with id tag TB_U1 and values:
      | deleted         | true    |
      | change_comments | sneak   |
    Then the row TB_U1 should not be deleted

    # overlap on PUT/PATCH (self update allowed, other row rejected, touching allowed)
    And I expect the next API call to return a status code of 200 and message of "OK"
    When I PATCH settlement_item_timebound with id tag TB_U1 and values:
      | settlement_item_id | <U1>               |
      | start_dttm_utc     | 2023-09-05T09:00:00Z |
      | end_dttm_utc       | 2023-09-05T10:00:00Z |
      | currency        | EUR       |
      | change_comments | self edit |
    Then the expected status should be returned
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I PATCH settlement_item_timebound with id tag TB_U1_OTHER and values:
      | start_dttm_utc | 2023-09-05T09:30:00Z |
      | end_dttm_utc   | 2023-09-05T12:30:00Z |
    Then the expected status should be returned
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I PUT settlement_item_timebound with id tag TB_U1_OTHER and values:
      | settlement_item_id | <U1>                 |
      | start_dttm_utc     | 2023-09-05T09:59:59Z |
      | end_dttm_utc       | 2023-09-05T13:00:00Z |
      | interval_source    | MEASURED             |
    Then the expected status should be returned
    And I expect the next API call to return a status code of 200 and message of "OK"
    When I PATCH settlement_item_timebound with id tag TB_U1_OTHER and values:
      | settlement_item_id | <U1>                 |
      | start_dttm_utc | 2023-09-05T10:00:00Z |
      | end_dttm_utc   | 2023-09-05T13:00:00Z |
      | change_comments    | move2 |
    Then the expected status should be returned

    # PATCH moves a row to another settlement item (allowed): overlap checked on the target item
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I PATCH settlement_item_timebound with id tag TB_U1 and values:
      | settlement_item_id | <U2>      |
      | change_comments    | move into overlap |
    Then the expected status should be returned
    Then settlement_item_timebound TB_U1 should still belong to <U1>
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I PATCH settlement_item_timebound with id tag TB_U1_OTHER and values:
      | start_dttm_utc     | 2023-09-05T09:59:59Z |
      | end_dttm_utc       | 2023-09-05T13:00:00Z |
      | settlement_item_id | <U2>      |
      | change_comments    | move |
    Then the expected status should be returned
    Then settlement_item_timebound TB_U1_OTHER should still belong to <U1>
    And I expect the next API call to return a status code of 404 and message of "Not Found"
    When I PATCH settlement_item_timebound with id tag TB_U1 and values:
      | settlement_item_id | <uuid>    |
      | start_dttm_utc     | 2023-09-05T09:59:59Z |
      | end_dttm_utc       | 2023-09-05T13:00:00Z |
      | change_comments    | move to unknown item |
    Then the expected status should be returned

    # PUT / PATCH on a soft deleted row -> 404
    When I DELETE settlement_item_timebound with id tag TB_U1
    Then the expected status should be returned
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I PUT settlement_item_timebound with id tag TB_U1 and values:
      | settlement_item_id | <U1>                 |
      | start_dttm_utc     | 2023-09-05T09:00:00Z |
      | end_dttm_utc       | 2023-09-05T10:00:00Z |
      | interval_source    | MEASURED             |
      | change_comments    | trying to move |
    Then the expected status should be returned
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I PATCH settlement_item_timebound with id tag TB_U1 and values:
      | currency | USD |
    Then the expected status should be returned

    # batch atomicity (NEW steps)
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I PATCH settlement_item_timebound with id tag TB_U1 and values:
      | start_dttm_utc  | 2023-09-05T14:30:00Z |
      | end_dttm_utc    | 2023-09-05T15:30:00Z |
      | change_comments | overlap patch         |
    Then the expected status should be returned

    When I call GET settlement_item_timebound for id tag TB_U2
    Then GET settlement_item_timebound by id should have field currency equal to null

    # audit is not written by rejected calls, and creation alone does not write an audit entry
    And I expect the next API call to return a status code of 404 and message of "Not Found"
    When I call GET settlement_item_timebound_audit for id tag TB_U2 per_page 10 direction forward
    Then the expected status should be returned
    And settlement_item_timebound audit should contain exactly 0 entries

    # cleanup
    When I DELETE settlement item with the id tag U1
    Then the DELETE settlement_item details should specify 1 settlement items and 0 settlement item intervals
    When I DELETE settlement item with the id tag U2
    Then the DELETE settlement_item details should specify 1 settlement items and 0 settlement item intervals
    When I DELETE the settlement
    Then the DELETE settlement details should specify 0 settlement items and 0 settlement item intervals

  Scenario: DELETE - extra negative and side effect checks
    When I POST a settlement with the following properties:
      | settlement_type         | ONGOING_DATA_SUBMISSION |
      | settlement_subtype      | TVA event               |
      | start_dttm_utc          | 2023-09-05T08:00:00Z    |
      | end_dttm_utc            | 2023-09-06T08:00:00Z    |
      | event_id                | <uuid>                  |
      | description             | QAA extra DELETE |
      | settlement_status       | PRELIMINARY             |
      | business_process_status | NOT_STARTED             |
      | source_system_type      | NGP                     |
    Then the response should include the new settlement
    When I POST a settlement_item with the following properties:
      | settlement_id             | <last-settlement-id> |
      | settlement_level          | REGISTRATION         |
      | settlement_level_id       | QAA extra DELETE D1    |
      | submitted_indicator       | true                 |
      | settlement_item_status    | AWAITING_DATA        |
      | atlas_settlement_level_id | <uuid>               |
      | asset_type                | LOAD                 |
      | start_dttm_utc            | 2023-09-05T08:00:00Z |
      | end_dttm_utc              | 2023-09-06T08:00:00Z |
    Then the response should include the new settlement_item
    And I save the settlement_item id for later use with the tag D1
    When I POST a settlement_item with the following properties:
      | settlement_id             | <last-settlement-id> |
      | settlement_level          | REGISTRATION         |
      | settlement_level_id       | QAA extra DELETE D2    |
      | submitted_indicator       | true                 |
      | settlement_item_status    | AWAITING_DATA        |
      | atlas_settlement_level_id | <uuid>               |
      | asset_type                | LOAD                 |
      | start_dttm_utc            | 2023-09-05T08:00:00Z |
      | end_dttm_utc              | 2023-09-06T08:00:00Z |
    Then the response should include the new settlement_item
    And I save the settlement_item id for later use with the tag D2
    And I expect the next API call to return a status code of 200 and message of "OK"
    When I POST a settlement_item_timebound row with the following data:
      | settlement_item_id | <D1> |
      | start_dttm_utc     | 2023-09-05T09:00:00Z |
      | end_dttm_utc       | 2023-09-05T10:00:00Z |
      | interval_source    | MEASURED |
      | change_comments    | d row 1 |
    Then the expected status should be returned
    And I save the last settlement_item_timebound id with the tag TB_D1
    And I expect the next API call to return a status code of 200 and message of "OK"
    When I POST a settlement_item_timebound row with the following data:
      | settlement_item_id | <D1> |
      | start_dttm_utc     | 2023-09-05T10:00:00Z |
      | end_dttm_utc       | 2023-09-05T11:00:00Z |
      | interval_source    | MEASURED |
      | change_comments    | d row 2 |
    Then the expected status should be returned
    And I save the last settlement_item_timebound id with the tag TB_D1_NEIGHBOUR
    And I expect the next API call to return a status code of 200 and message of "OK"
    When I POST a settlement_item_timebound row with the following data:
      | settlement_item_id | <D2> |
      | start_dttm_utc     | 2023-09-05T09:00:00Z |
      | end_dttm_utc       | 2023-09-05T10:00:00Z |
      | interval_source    | MEASURED |
      | change_comments    | d other item |
    Then the expected status should be returned
    And I save the last settlement_item_timebound id with the tag TB_D2

    When I DELETE settlement_item_timebound with id tag TB_D1
    Then the expected status should be returned

    # row is still stored but flagged; neighbours and other items untouched
    Given I set include_deleted=true
    When I call GET settlement_item_timebound for id tag TB_D1
    Then GET settlement_item_timebound by id should have field deleted equal to true
    And GET settlement_item_timebound by id should have field change_comments absent or not changed by delete
    When I call GET settlement_item_timebound for id tag TB_D1_NEIGHBOUR
    Then GET settlement_item_timebound by id should have field deleted equal to false
    When I call GET settlement_item_timebound for id tag TB_D2
    Then GET settlement_item_timebound by id should have field deleted equal to false
    Given I set include_deleted=missing
    When I call GET settlement_item_timebound with settlement_item_id: <D1> start_dttm_utc: missing end_dttm_utc: missing per_page: 50 direction: forward
    Then GET settlement_item_timebound should return 1 rows

    # second DELETE and variants -> 404, no extra audit row
    And I expect the next API call to return a status code of 404 and message of "Not Found"
    When I DELETE settlement_item_timebound with id tag TB_D1
    Then the expected status should be returned
    And I expect the next API call to return a status code of 404 and message of "Not Found"
    When I DELETE settlement_item_timebound with id tag TB_D1
    Then the expected status should be returned
    And I expect the next API call to return a status code of 404 and message of "Not Found"
    When I DELETE settlement_item_timebound with id 00000000-0000-0000-0000-000000000000
    Then the expected status should be returned
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I DELETE settlement_item_timebound with id not-a-uuid
    Then the expected status should be returned
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I DELETE settlement_item_timebound with id 123
    Then the expected status should be returned
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I DELETE settlement_item_timebound with id 00000000-0000-0000-0000-00000000000Z
    Then the expected status should be returned
    When I call GET settlement_item_timebound_audit for id tag TB_D1 per_page 10 direction forward
    Then settlement_item_timebound audit should contain exactly 1 entries
    And settlement_item_timebound audit changed fields should be "deleted"


    # DELETE is not reachable through the list or by id with include_deleted=false
    Given I set include_deleted=false
    And I expect the next API call to return a status code of 404 and message of "Not Found"
    When I call GET settlement_item_timebound for id tag TB_D1
    Then the expected status should be returned
    Given I set include_deleted=missing

    # POST after DELETE creates a different row; the old one stays deleted
    And I expect the next API call to return a status code of 200 and message of "OK"
    When I POST a settlement_item_timebound row with the following data:
      | settlement_item_id | <D1> |
      | start_dttm_utc     | 2023-09-05T09:00:00Z |
      | end_dttm_utc       | 2023-09-05T10:00:00Z |
      | interval_source    | MEASURED |
      | change_comments    | recreate |
    Then the expected status should be returned
    And I save the last settlement_item_timebound id with the tag TB_D1_NEW
    Then the saved ids TB_D1 and TB_D1_NEW should differ
    When I DELETE settlement_item_timebound with id tag TB_D1_NEW
    Then the expected status should be returned
    And I expect the next API call to return a status code of 404 and message of "Not Found"
    When I DELETE settlement_item_timebound with id tag TB_D1
    Then the expected status should be returned

    # cleanup
#    When I DELETE the settlement_item
#    Then the DELETE settlement_item details should specify 1 settlement items and 0 settlement item intervals
#    When I DELETE the settlement
#    Then the DELETE settlement details should specify 0 settlement items and 0 settlement item intervals

    # cleanup
    When I DELETE settlement item with the id tag D1
    Then the DELETE settlement_item details should specify 1 settlement items and 0 settlement item intervals
    When I DELETE settlement item with the id tag D2
    Then the DELETE settlement_item details should specify 1 settlement items and 0 settlement item intervals
    When I DELETE the settlement
    Then the DELETE settlement details should specify 0 settlement items and 0 settlement item intervals

