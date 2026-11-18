Feature: Feature test for settlement items

  Reference: <CONFLUENCE_URL>/display/PMENA/Settlement+API+-+Technical+Design
  Covers scenarios in: featureSettlementTest/src/it/scala/com/enelx/settlement/featuretests/SettlementItemFeature.scala

  ITAPPSIT-3885: settlement api: add registration_set_id to settlement item
  ITAPPSIT-3356: add "processing_status" text field to settlement_items and settlement API endpoints
  ITAPPSIT-4063: introduce inputs_available_until_dttm_utc field for settlements and is_active column for settlement_items

  Background:
    Given I start with an empty context
    And I log in as a settlement API admin


  Scenario: Basic tests for settlement item

    # POST a new settlement
    When I POST a settlement with the following properties:
      | settlement_type         | ONGOING_DATA_SUBMISSION             |
      | settlement_subtype      | TVA event                           |
      | start_dttm_utc          | 2023-09-05T08:00:00Z                |
      | end_dttm_utc            | 2023-09-05T09:00:00Z                |
      | event_id                | <uuid> |
      | description             | QAA test: create settlement                        |
      | settlement_status       | PRELIMINARY                         |
      | business_process_status | NOT_STARTED                         |
      | source_system_type      | NGP                                 |
    Then the response should include the new settlement

    # POST a new settlement item with all properties
    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | REGISTRATION         |
      | settlement_level_id    | <uuid>             |
      | submitted_indicator    | true                 |
      | settlement_item_status | PRELIMINARY        |
      | asset_type             | LOAD                 |
      | processing_status      |  CREATING  |
    |atlas_settlement_level_id | <uuid>               |
      | registration_set_id      |      <uuid>                |
      | portfolio_id                  |      <uuid>                |
  |ecrm_opportunity_id     |      abcdefghijklmnopqr                |
  | ecrm_account_id        |   123456789012345678   |
  | ecrm_site_id           |       098765432109876543            |
      | start_dttm_utc          | 2023-09-05T08:00:00Z                |
      | end_dttm_utc            | 2023-09-05T08:30:00Z                |
    Then the response should include the new settlement_item
    * GET settlement_item should return the new entity
    * no entries should be found in the settlement_item audit log

     # PUT: Update all properties
    When I PUT the settlement_item with new values:
      | settlement_id          | <last-settlement-id> |
      | settlement_item_id     | <last-settlement-item-id>   |
      | settlement_level       | METER                       |
      | settlement_level_id    | Level 1 |
      | submitted_indicator    | false                       |
      | settlement_item_status | AWAITING_DATA                     |
      | asset_type             | DER_BESS                    |
      | processing_status      |  IN_PROCESS  |
      |atlas_settlement_level_id | <uuid>              |
      | registration_set_id      |      <uuid>                |
      | portfolio_id                   |      <uuid>                |
      |ecrm_opportunity_id     |      123defghijklmnopqr                |
      | ecrm_account_id        |   abc456789012345678   |
      | ecrm_site_id           |       def765432109876543            |
      | start_dttm_utc          | 2023-09-05T08:30:00Z                |
      | end_dttm_utc            | 2023-09-05T09:00:00Z                |
      | change_comments        | Update all properties       |
    Then the response should include the updated settlement_item
    * GET settlement_item should return the updated entity
    * changes should be recorded in the settlement_item audit log

    # PUT: if no fields changed, should return 200
    When I PUT the settlement_item with new values:
      | settlement_id          | <last-settlement-id> |
      | settlement_item_id     | <last-settlement-item-id>   |
      | settlement_level       | METER                       |
      | settlement_level_id    | Level 1 |
      | submitted_indicator    | false                       |
      | settlement_item_status | AWAITING_DATA                     |
      | asset_type             | DER_BESS                    |
      | processing_status      |  IN_PROCESS  |
      |atlas_settlement_level_id | <last-atlas-settlement-level-id>              |
      | registration_set_id     |      <last-registration-set-id>                |
      | portfolio_id                 |      <last-portfolio-id>                |
      |ecrm_opportunity_id     |      123defghijklmnopqr                |
      | ecrm_account_id        |   abc456789012345678   |
      | ecrm_site_id           |       def765432109876543            |
      | start_dttm_utc          | 2023-09-05T08:30:00Z                |
      | end_dttm_utc            | 2023-09-05T09:00:00Z                |
      # "No update expected" tells the following stepdef that the response is actually identical to the existing item.
      | change_comments        | No update expected       |
    Then the response should include the updated settlement_item

    # PATCH: Update a single property
    Given I expect the next API call to return a status code of 200 and details of "Successfully updated the settlement_item_status to PRELIMINARY for settlement_item_id"
    When I PATCH the settlement_item with new values:
      | settlement_item_id     | <last-settlement-item-id> |
      | settlement_item_status | PRELIMINARY               |
      | change_comments        | Update a single property  |
    Then the expected status should be returned
    * GET settlement_item should return the updated entity

    # ITAPPSIT-3356: PATCH: Update processing_status
    Given I expect the next API call to return a status code of 200 and details of "Successfully updated processing_status to COMPLETE for settlement_item_id"
    When I PATCH the settlement_item with new values:
      | settlement_item_id     | <last-settlement-item-id> |
      | processing_status | COMPLETE               |
      | change_comments        | Update processing_status  |
    Then the expected status should be returned
    * GET settlement_item should return the updated entity
    * changes should be recorded in the settlement_item audit log

     # Cleanup
    Given I DELETE the settlement


  Scenario: POST all properties, PUT only mandatory properties

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
    Then the response should include the new settlement
    And GET settlement should return the new entity

    # POST a new settlement item with all properties
    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | REGISTRATION         |
      | settlement_level_id    | <uuid>             |
      | submitted_indicator    | true                 |
      | settlement_item_status | PRELIMINARY        |
      | asset_type             | LOAD                 |
      | processing_status      |  CREATING  |
      |atlas_settlement_level_id | <uuid>               |
      | registration_set_id    |      <uuid>                |
      | portfolio_id                |      <uuid>                |
      |ecrm_opportunity_id     |      abcdefghijklmnopqr                |
      | ecrm_account_id        |   123456789012345678   |
      | ecrm_site_id           |       098765432109876543            |
      | start_dttm_utc          | 2023-09-05T08:00:00Z                |
      | end_dttm_utc            | 2023-09-05T08:30:00Z                |
    Then the response should include the new settlement_item
    * GET settlement_item should return the new entity

     # PUT: Update only mandatory properties. Optional properties should be set to null.
      When I PUT the settlement_item with new values:
        | settlement_id          | <last-settlement-id> |
        | settlement_item_id     | <last-settlement-item-id>   |
        | settlement_level       | METER                       |
        | settlement_level_id    | Level 1 |
        | submitted_indicator    | false                       |
        | settlement_item_status | AWAITING_DATA                     |
        | asset_type             | DER_BESS                    |
        | change_comments        | Update mandatory properties       |
      Then the response should include the updated settlement_item
      * GET settlement_item should return the updated entity
      * changes should be recorded in the settlement_item audit log

      # PUT: Update only the optional properties
    When I PUT the settlement_item with new values:
      | settlement_id          | <last-settlement-id> |
      | settlement_item_id     | <last-settlement-item-id>   |
      | settlement_level       | METER                       |
      | settlement_level_id    | Level 1 |
      | submitted_indicator    | false                       |
      | settlement_item_status | AWAITING_DATA                     |
      | asset_type             | DER_BESS                    |
      | processing_status      |  IN_PROCESS  |
      | change_comments        | Update optional properties       |
      |atlas_settlement_level_id | <uuid>              |
      | registration_set_id         |      <uuid>                |
      | portfolio_id                     |      <uuid>                |
      |ecrm_opportunity_id     |      123defghijklmnopqr                |
      | ecrm_account_id        |   abc456789012345678   |
      | ecrm_site_id           |       def765432109876543            |
      | start_dttm_utc          | 2023-09-05T08:10:00Z                |
      | end_dttm_utc            | 2023-09-05T08:20:00Z                |
    Then the response should include the updated settlement_item
    * GET settlement_item should return the updated entity
    * changes should be recorded in the settlement_item audit log

        # Cleanup
    Given I DELETE the settlement


  Scenario: POST mandatory properties only, PUT all properties

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
      Then the response should include the new settlement

    # POST a new settlement item with only mandatory properties
      When I POST a settlement_item with the following properties:
        | settlement_id          | <last-settlement-id> |
        | settlement_level       | REGISTRATION         |
        | settlement_level_id    | <uuid>             |
        | submitted_indicator    | true                 |
        | settlement_item_status | PRELIMINARY        |
        | asset_type             | LOAD                 |
        | start_dttm_utc          | 2023-09-05T08:00:00Z                |
        | end_dttm_utc            | 2023-09-05T08:30:00Z                |
      Then the response should include the new settlement_item
      * GET settlement_item should return the new entity

      # PUT: Update only the optional properties (i.e. change them from null)
      When I PUT the settlement_item with new values:
        | settlement_id          | <last-settlement-id> |
        | settlement_item_id     | <last-settlement-item-id>   |
        | settlement_level       | METER                       |
        | settlement_level_id    | Level 1 |
        | submitted_indicator    | true                       |
        | settlement_item_status | AWAITING_DATA                     |
        | asset_type             | DER_BESS                    |
        | processing_status      |  IN_PROCESS  |
        | change_comments        | Update optional properties       |
        |atlas_settlement_level_id | <uuid>              |
        | registration_set_id         |      <uuid>                |
        | portfolio_id                     |      <uuid>                |
        |ecrm_opportunity_id     |      123defghijklmnopqr                |
        | ecrm_account_id        |   abc456789012345678   |
        | ecrm_site_id           |       def765432109876543            |
        | start_dttm_utc          | 2023-09-05T08:10:00Z                |
        | end_dttm_utc            | 2023-09-05T08:20:00Z                |
      Then the response should include the updated settlement_item
      * GET settlement_item should return the updated entity
      * changes should be recorded in the settlement_item audit log

        # Cleanup
      Given I DELETE the settlement


  Scenario: Error cases

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
      Then the response should include the new settlement

    # POST a new settlement item
      When I POST a settlement_item with the following properties:
        | settlement_id          | <last-settlement-id> |
        | settlement_level       | REGISTRATION         |
        | settlement_level_id    | Level 1             |
        | submitted_indicator    | true                 |
        | settlement_item_status | PRELIMINARY        |
        | asset_type             | LOAD                 |
        |atlas_settlement_level_id | <uuid>               |
        |ecrm_opportunity_id     |      abcdefghijklmnopqr                |
        | ecrm_account_id        |   123456789012345678   |
        | ecrm_site_id           |       098765432109876543            |
        | start_dttm_utc          | 2023-09-05T08:00:00Z                |
        | end_dttm_utc            | 2023-09-05T08:30:00Z                |
      Then the response should include the new settlement_item

    # POST: Settlement not found
    Given I expect the next API call to return a status code of 400 and details of "Cannot find Settlement for settlement_id"
    When I POST a settlement_item with the following properties:
      | settlement_id          | <uuid> |
      | settlement_level       | REGISTRATION         |
      | settlement_level_id    | <uuid>             |
      | submitted_indicator    | true                 |
      | settlement_item_status | AWAITING_DATA        |
      | asset_type             | LOAD                 |
      | start_dttm_utc          | 2023-09-05T08:00:00Z                |
      | end_dttm_utc            | 2023-09-05T08:30:00Z                |
    Then the expected status should be returned

    # POST: Missing mandatory field
    Given I expect the next API call to return a status code of 400 and details of "body: data must have required property 'settlement_id'"
    When I POST a settlement_item with the following properties:
      | settlement_level       | REGISTRATION         |
      | settlement_level_id    | Item 1             |
      | submitted_indicator    | true                 |
      | settlement_item_status | AWAITING_DATA        |
      | asset_type             | LOAD                 |
      | start_dttm_utc          | 2023-09-05T08:00:00Z                |
      | end_dttm_utc            | 2023-09-05T08:30:00Z                |
    Then the expected status should be returned

    # POST: Mandatory field is empty string
    Given I expect the next API call to return a status code of 400 and details of "settlement level is required"
    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | <empty-string>         |
      | settlement_level_id    | Item 1             |
      | submitted_indicator    | true                 |
      | settlement_item_status | AWAITING_DATA        |
      | asset_type             | LOAD                 |
      | start_dttm_utc          | 2023-09-05T08:00:00Z                |
      | end_dttm_utc            | 2023-09-05T08:30:00Z                |
    Then the expected status should be returned

    # POST: Invalid reference value
    # Note: apparently API validation stops on first error
    Given I expect the next API call to return a status code of 400 and details of "Choose from: METER,ACCOUNT,REGISTRATION,RESOURCE"
    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | FOO         |
      | settlement_level_id    | Item invalid             |
      | submitted_indicator    | true                 |
      | settlement_item_status | AWAITING_DATA        |
      | asset_type             | LOAD                 |
      | start_dttm_utc          | 2023-09-05T08:00:00Z                |
      | end_dttm_utc            | 2023-09-05T08:30:00Z                |
    Then the expected status should be returned

    # POST: Invalid property type
    Given I expect the next API call to return a status code of 400 and details of "submitted_indicator must be boolean"
    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | REGISTRATION         |
      | settlement_level_id    | Item invalid             |
      | submitted_indicator    | foo                 |
      | settlement_item_status | AWAITING_DATA        |
      | asset_type             | LOAD                 |
      | start_dttm_utc          | 2023-09-05T08:00:00Z                |
      | end_dttm_utc            | 2023-09-05T08:30:00Z                |
    Then the expected status should be returned

    #--- PUT errors

    # PUT: Settlement item not found
    Given I expect the next API call to return a status code of 404 and details of "unable to retrieve SettlementItem to update for settlement_item_id="
    When I PUT the settlement_item with new values:
      | settlement_id          | <last-settlement-id> |
      | settlement_item_id     | <uuid>   |
      | settlement_level       | METER         |
      | settlement_level_id    | foo            |
      | submitted_indicator    | true                 |
      | settlement_item_status | AWAITING_DATA        |
      | start_dttm_utc          | 2023-09-05T08:00:00Z                |
      | end_dttm_utc            | 2023-09-05T08:30:00Z                |
      | asset_type             | LOAD                 |
      | change_comments        | Settlement item not found       |
    Then the expected status should be returned

    # PUT: cannot update the settlement id
    Given I expect the next API call to return a status code of 400 and details of "cannot update the settlement id"
    When I PUT the settlement_item with new values:
      | settlement_id          | <uuid> |
      | settlement_item_id     | <last-settlement-item-id>   |
      | settlement_level       | METER         |
      | settlement_level_id    | foo            |
      | submitted_indicator    | true                 |
      | settlement_item_status | AWAITING_DATA        |
      | start_dttm_utc          | 2023-09-05T08:00:00Z                |
      | end_dttm_utc            | 2023-09-05T08:30:00Z                |
      | asset_type             | LOAD                 |
      | change_comments        | Settlement item not found       |
    Then the expected status should be returned

    # POST another item, and then try to change its settlement_level_id to an existing one
    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | REGISTRATION         |
      | settlement_level_id    | bar             |
      | submitted_indicator    | false                 |
      | settlement_item_status | PRELIMINARY        |
      | asset_type             | LOAD                 |
      | start_dttm_utc          | 2023-09-05T08:00:00Z                |
      | end_dttm_utc            | 2023-09-05T08:30:00Z                |
    Then the response should include the new settlement_item

    Given I expect the next API call to return a status code of 400 and details of "a settlement item already exists for the provided settlement_id, settlement_level_id, and time"
    When I PUT the settlement_item with new values:
      | settlement_id          | <last-settlement-id> |
      | settlement_item_id     | <last-settlement-item-id>   |
      | settlement_level       | METER                       |
      | settlement_level_id    | Level 1 |
      | submitted_indicator    | false                       |
      | settlement_item_status | AWAITING_DATA                     |
      | start_dttm_utc          | 2023-09-05T08:00:00Z                |
      | end_dttm_utc            | 2023-09-05T08:30:00Z                |
      | asset_type             | DER_BESS                    |
      | change_comments        | Duplicate settlement_level_id       |
    Then the expected status should be returned

     # PUT: Invalid reference value
    Given I expect the next API call to return a status code of 400 and details of "Choose from: AWAITING_DATA,PRELIMINARY,FINALIZED,NO_DATA"
    When I PUT the settlement_item with new values:
      | settlement_id          | <last-settlement-id> |
      | settlement_item_id     | <last-settlement-item-id> |
      | settlement_level       | METER         |
      | settlement_level_id    | foo            |
      | submitted_indicator    | true                 |
      | settlement_item_status | FOO        |
      | start_dttm_utc          | 2023-09-05T08:00:00Z                |
      | end_dttm_utc            | 2023-09-05T08:30:00Z                |
      | asset_type             | LOAD                 |
      | change_comments        | Invalid ref value  |
    Then the expected status should be returned

      # PUT: Missing mandatory field
    Given I expect the next API call to return a status code of 400 and details of "data must have required property 'settlement_item_id'"
    When I PUT the settlement_item with new values:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | METER         |
      | settlement_level_id    | foo            |
      | submitted_indicator    | true                 |
      | settlement_item_status | PRELIMINARY        |
      | start_dttm_utc          | 2023-09-05T08:00:00Z                |
      | end_dttm_utc            | 2023-09-05T08:30:00Z                |
      | asset_type             | LOAD                 |
      | change_comments  | PUT will fail if mandatory field is missing |
    Then the expected status should be returned

    # PUT: Mandatory field is empty string
    Given I expect the next API call to return a status code of 400 and details of "settlement level id is required"
    When I PUT the settlement_item with new values:
      | settlement_id          | <last-settlement-id> |
      | settlement_item_id     | <last-settlement-item-id> |
      | settlement_level       | METER         |
      | settlement_level_id    | <empty-string>            |
      | submitted_indicator    | true                 |
      | settlement_item_status | PRELIMINARY        |
      | start_dttm_utc          | 2023-09-05T08:00:00Z                |
      | end_dttm_utc            | 2023-09-05T08:30:00Z                |
      | asset_type             | LOAD                 |
      | change_comments  | PUT will fail if mandatory field is empty string |
    Then the expected status should be returned

      # PUT: ECRM id must be 18 characters
      Given I expect the next API call to return a status code of 400 and details of "ecrm account id must be 18 chars"
      When I PUT the settlement_item with new values:
        | settlement_id          | <last-settlement-id>                             |
        | settlement_item_id     | <last-settlement-item-id>                        |
        | settlement_level       | METER                                            |
        | settlement_level_id    | Level 1                                   |
        | submitted_indicator    | true                                             |
        | settlement_item_status | PRELIMINARY                                      |
        | start_dttm_utc          | 2023-09-05T08:00:00Z                |
        | end_dttm_utc            | 2023-09-05T08:30:00Z                |
        | asset_type             | LOAD                                             |
        | ecrm_account_id        | foo                                              |
        | change_comments        | PUT will fail if ecrm id is not 18 chars |
      Then the expected status should be returned

    #--- PATCH errors

    # PATCH: Settlement item not found
    Given I expect the next API call to return a status code of 404 and details of "no settlement item found for id"
    When I PATCH the settlement_item with new values:
      | settlement_item_id     | foo |
      | settlement_item_status | PRELIMINARY               |
      | change_comments        | Invalid ref value  |
    Then the expected status should be returned

     # PATCH: Invalid reference value
    Given I expect the next API call to return a status code of 400 and details of "Choose from: AWAITING_DATA,PRELIMINARY,FINALIZED,NO_DATA"
    When I PATCH the settlement_item with new values:
      | settlement_item_id     | <last-settlement-item-id> |
      | settlement_item_status | FOO               |
      | change_comments        | Invalid ref value  |
    Then the expected status should be returned

    # PATCH: Missing mandatory field
    Given I expect the next API call to return a status code of 400 and details of "body: data must have required property 'settlement_item_id'"
    When I PATCH the settlement_item with new values:
      | settlement_item_id    | <missing>                                   |
      | settlement_item_status | AWAITING_DATA                     |
      | change_comments  | Error case |
    Then the expected status should be returned

    # PATCH: Non-supported field
    Given I expect the next API call to return a status code of 400 and details of "Not a valid patch_type"
    When I PATCH the settlement_item with new values:
      | settlement_item_id    | <last-settlement-item-id>                                   |
      | atlas_settlement_level_id | <uuid>                    |
      | change_comments  | Error case |
    Then the expected status should be returned

    # PATCH: Status already set
    Given I expect the next API call to return a status code of 400 and details of "settlement item status is already PRELIMINARY"
    When I PATCH the settlement_item with new values:
      | settlement_item_id     | <last-settlement-item-id> |
      | settlement_item_status | PRELIMINARY               |
      | change_comments        | Status already set  |
    Then the expected status should be returned

    # Verify no changes were actually made
    * no entries should be found in the settlement_item audit log

    # Cleanup
    When I DELETE the settlement
    Then the DELETE settlement details should specify 2 settlement items and 0 settlement item intervals


  Scenario: Settlement item lifecycle: FINALIZED or NO_DATA status

    When I POST a settlement with the following properties:
      | settlement_type         | ONGOING_DATA_SUBMISSION        |
      | settlement_subtype      | TVA event                      |
      | start_dttm_utc          | 2023-09-05T08:00:00Z           |
      | end_dttm_utc            | 2023-09-05T08:30:00Z           |
      | event_id                | <uuid>                         |
      | description             | QAA test: Settlement lifecycle |
      | settlement_status       | AWAITING_DATA                  |
      | business_process_status | NOT_STARTED                    |
      | source_system_type      | NGP                            |
    Then the response should include the new settlement

    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | REGISTRATION         |
      | settlement_level_id    | <uuid>             |
      | submitted_indicator    | true                 |
      | settlement_item_status | AWAITING_DATA        |
      |atlas_settlement_level_id | <uuid>               |
      | registration_set_id      |      <uuid>                |
      | portfolio_id                  |      <uuid>                |
      | asset_type             | LOAD                 |
      | start_dttm_utc          | 2023-09-05T08:00:00Z           |
      | end_dttm_utc            | 2023-09-05T08:30:00Z           |
    Then the response should include the new settlement_item

    # Change the status to FINALIZED
    When I PUT the settlement_item with new values:
      | settlement_id          | <last-settlement-id> |
      | settlement_item_id     | <last-settlement-item-id>  |
      | settlement_level       | REGISTRATION         |
      | settlement_level_id    | <uuid>             |
      | submitted_indicator    | true                 |
      | settlement_item_status | FINALIZED                  |
      |atlas_settlement_level_id | <last-atlas-settlement-level-id>               |
      | registration_set_id      |      <last-registration-set-id>                |
      | portfolio_id                  |      <last-portfolio-id>                |
      | asset_type             | LOAD                 |
      | start_dttm_utc          | 2023-09-05T08:00:00Z           |
      | end_dttm_utc            | 2023-09-05T08:30:00Z           |
      | change_comments        | AWAITING_DATA -> FINALIZED |
    Then the response should include the updated settlement_item
    And changes should be recorded in the settlement_item audit log

      # PUT: cannot revert status
    Given I expect the next API call to return a status code of 400 and details of "cannot update a settlement item status which is already in a FINALIZED state for settlement_item_id"
    When I PUT the settlement_item with new values:
      | settlement_id          | <last-settlement-id> |
      | settlement_item_id     | <last-settlement-item-id> |
      | settlement_level       | REGISTRATION         |
      | settlement_level_id    | <uuid>             |
      | submitted_indicator    | true                 |
      | settlement_item_status | PRELIMINARY               |
      |atlas_settlement_level_id | <last-atlas-settlement-level-id>               |
      | registration_set_id      |      <last-registration-set-id>                |
      | portfolio_id                  |      <last-portfolio-id>                |
      | asset_type             | LOAD                 |
      | start_dttm_utc          | 2023-09-05T08:00:00Z           |
      | end_dttm_utc            | 2023-09-05T08:30:00Z           |
      | change_comments        | FINALIZED -> PRELIMINARY  |
    Then the expected status should be returned
    And no additional changes should be recorded in the settlement_item audit log

    # PUT: cannot change any field of a finalized item (v0 allows this for item, but not for settlement; for v1 we decided not to allow it for any entity)
    Given I expect the next API call to return a status code of 400 and details of "cannot update a settlement item status which is already in a FINALIZED state for settlement_item_id"
    When I PUT the settlement_item with new values:
      | settlement_id          | <last-settlement-id> |
      | settlement_item_id     | <last-settlement-item-id> |
      | settlement_level       | REGISTRATION         |
      | settlement_level_id    | <uuid>             |
      | submitted_indicator    | true                 |
      | settlement_item_status | FINALIZED               |
      |atlas_settlement_level_id | <last-atlas-settlement-level-id>               |
      | registration_set_id      |      <last-registration-set-id>                |
      | portfolio_id                  |      <last-portfolio-id>                |
      | asset_type             | LOAD                 |
      | start_dttm_utc          | 2023-09-05T08:00:00Z           |
      | end_dttm_utc            | 2023-09-05T08:30:00Z           |
      | change_comments        | Set new level id  |
    Then the expected status should be returned

    # PATCH: can revert status
    Given I expect the next API call to return a status code of 200 and details of "Successfully updated the settlement_item_status to PRELIMINARY for settlement_item_id"
    When I PATCH the settlement_item with new values:
      | settlement_item_id     | <last-settlement-item-id>  |
      | settlement_item_status | PRELIMINARY                  |
      | change_comments        | FINALIZED -> PRELIMINARY |
    Then the expected status should be returned
    * GET settlement_item should return the updated entity
    * changes should be recorded in the settlement_item audit log

    # Now test NO_DATA as a final state

    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | REGISTRATION         |
      | settlement_level_id    | <uuid>             |
      | submitted_indicator    | true                 |
      | settlement_item_status | NO_DATA        |
      |atlas_settlement_level_id | <uuid>               |
      | registration_set_id      |      <uuid>                |
      | portfolio_id                  |      <uuid>                |
      | asset_type             | LOAD                 |
      | start_dttm_utc          | 2023-09-05T08:00:00Z           |
      | end_dttm_utc            | 2023-09-05T08:30:00Z           |
    Then the response should include the new settlement_item

     # PUT: cannot revert status
    Given I expect the next API call to return a status code of 400 and details of "cannot update a settlement item status which is already in a NO_DATA state for settlement_item_id"
    When I PUT the settlement_item with new values:
      | settlement_id          | <last-settlement-id> |
      | settlement_item_id     | <last-settlement-item-id> |
      | settlement_level       | REGISTRATION         |
      | settlement_level_id    | <uuid>             |
      | submitted_indicator    | true                 |
      | settlement_item_status | PRELIMINARY               |
      |atlas_settlement_level_id | <last-atlas-settlement-level-id>               |
      | registration_set_id      |      <last-registration-set-id>                |
      | portfolio_id                  |      <last-portfolio-id>                |
      | asset_type             | LOAD                 |
      | start_dttm_utc          | 2023-09-05T08:00:00Z           |
      | end_dttm_utc            | 2023-09-05T08:30:00Z           |
      | change_comments        | NO_DATA -> PRELIMINARY  |
    Then the expected status should be returned

    # PUT: cannot change any field of a finalized item
    Given I expect the next API call to return a status code of 400 and details of "cannot update a settlement item status which is already in a NO_DATA state for settlement_item_id"
    When I PUT the settlement_item with new values:
      | settlement_id          | <last-settlement-id> |
      | settlement_item_id     | <last-settlement-item-id> |
      | settlement_level       | REGISTRATION         |
      | settlement_level_id    | <uuid>             |
      | submitted_indicator    | true                 |
      | settlement_item_status | NO_DATA               |
      |atlas_settlement_level_id | <last-atlas-settlement-level-id>               |
      | registration_set_id      |      <last-registration-set-id>                |
      | portfolio_id                  |      <last-portfolio-id>                |
      | asset_type             | LOAD                 |
      | start_dttm_utc          | 2023-09-05T08:00:00Z           |
      | end_dttm_utc            | 2023-09-05T08:30:00Z           |
      | change_comments        | Set new level id  |
    Then the expected status should be returned

     # PATCH: can revert status
    Given I expect the next API call to return a status code of 200 and details of "Successfully updated the settlement_item_status to PRELIMINARY for settlement_item_id"
    When I PATCH the settlement_item with new values:
      | settlement_item_id     | <last-settlement-item-id>  |
      | settlement_item_status | PRELIMINARY                  |
      | change_comments        | NO_DATA -> PRELIMINARY |
    Then the expected status should be returned
    * GET settlement_item should return the updated entity
    * changes should be recorded in the settlement_item audit log

    # Cleanup
    Given I DELETE the settlement


    Scenario: GET settlement_item errors

      Given I expect the next API call to return a status code of 404 and details of "no settlement item found for settlement item id"
      When I call GET settlement_item for id 9876d4e0-4655-4133-b190-8a23076732f5
      Then the expected status should be returned

      Given I expect the next API call to return a status code of 400 and details of "settlement_item_id must match format 'uuid'"
      When I call GET settlement_item for id foo
      Then the expected status should be returned

      # ==============================================================================
      # DELETE settlement_item – parent settlement inputs_available_until_dttm_utc
      # ==============================================================================

  Scenario: DELETE settlement_item is allowed when parent settlement inputs_available_until_dttm_utc is null
    When I POST a settlement with the following properties:
      | settlement_type                 | ONGOING_DATA_SUBMISSION |
      | settlement_subtype              | TVA event               |
      | start_dttm_utc                  | 2023-09-05T08:00:00Z    |
      | end_dttm_utc                    | 2023-09-05T09:00:00Z    |
      | event_id                        | <uuid>                  |
      | description                     | QAA test: delete item parent null |
      | settlement_status               | PRELIMINARY             |
      | business_process_status         | NOT_STARTED             |
      | source_system_type              | NGP                     |
    Then the response should include the new settlement
    And GET settlement should return the new entity
    And the settlement inputs_available_until_dttm_utc field should be null

    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | REGISTRATION         |
      | settlement_level_id    | <uuid>               |
      | submitted_indicator    | true                 |
      | settlement_item_status | PRELIMINARY          |
      | asset_type             | LOAD                 |
      | processing_status      | CREATING             |
    Then the response should include the new settlement_item
    And GET settlement_item should return the new entity

    When I DELETE the settlement_item
    When I DELETE the settlement

  Scenario: DELETE settlement_item is allowed when parent settlement inputs_available_until_dttm_utc is in the future
    When I POST a settlement with the following properties:
      | settlement_type                 | ONGOING_DATA_SUBMISSION          |
      | settlement_subtype              | TVA event                        |
      | start_dttm_utc                  | 2023-09-05T08:00:00Z             |
      | end_dttm_utc                    | 2023-09-05T09:00:00Z             |
      | event_id                        | <uuid>                           |
      | description                     | QAA test: delete item parent future |
      | settlement_status               | PRELIMINARY                      |
      | business_process_status         | NOT_STARTED                      |
      | source_system_type              | NGP                              |
      | inputs_available_until_dttm_utc | 2126-06-17T15:27:02.620Z         |
    Then the response should include the new settlement
    And GET settlement should return the new entity
    And the settlement inputs_available_until_dttm_utc field should be set

    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | REGISTRATION         |
      | settlement_level_id    | <uuid>               |
      | submitted_indicator    | true                 |
      | settlement_item_status | PRELIMINARY          |
      | asset_type             | LOAD                 |
      | processing_status      | CREATING             |
    Then the response should include the new settlement_item
    And GET settlement_item should return the new entity

    When I DELETE the settlement_item
    When I DELETE the settlement

  Scenario: DELETE settlement_item is blocked when parent settlement inputs_available_until_dttm_utc is in the past
    When I POST a settlement with the following properties:
      | settlement_type                 | ONGOING_DATA_SUBMISSION         |
      | settlement_subtype              | TVA event                       |
      | start_dttm_utc                  | 2023-09-05T08:00:00Z            |
      | end_dttm_utc                    | 2023-09-05T09:00:00Z            |
      | event_id                        | <uuid>                          |
      | description                     | QAA test: delete item parent past |
      | settlement_status               | PRELIMINARY                     |
      | business_process_status         | NOT_STARTED                     |
      | source_system_type              | NGP                             |
      | inputs_available_until_dttm_utc | 2021-06-17T13:27:02.620Z        |
    Then the response should include the new settlement
    And GET settlement should return the new entity
    And the settlement inputs_available_until_dttm_utc field should be set

    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | REGISTRATION         |
      | settlement_level_id    | <uuid>               |
      | submitted_indicator    | true                 |
      | settlement_item_status | PRELIMINARY          |
      | asset_type             | LOAD                 |
      | processing_status      | CREATING             |
    Then the response should include the new settlement_item
    And GET settlement_item should return the new entity

    Given I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I DELETE the settlement_item
    Then the expected status should be returned

    # update settlement with inputs_available_until_dttm_utc future time and delete settlement_item and settlement
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
    When I DELETE the settlement_item
    When I DELETE the settlement

    # ==============================================================================
    # is_inactive – CREATE
    # ==============================================================================

  Scenario: Create settlement_item without is_inactive defaults to null
    When I POST a settlement with the following properties:
      | settlement_type         | ONGOING_DATA_SUBMISSION              |
      | settlement_subtype      | TVA event                            |
      | start_dttm_utc          | 2023-09-05T08:00:00Z                 |
      | end_dttm_utc            | 2023-09-05T09:00:00Z                 |
      | event_id                | <uuid>                               |
      | description             | QAA test: is_inactive not provided   |
      | settlement_status       | PRELIMINARY                          |
      | business_process_status | NOT_STARTED                          |
      | source_system_type      | NGP                                  |
    Then the response should include the new settlement

    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | REGISTRATION         |
      | settlement_level_id    | <uuid>               |
      | submitted_indicator    | true                 |
      | settlement_item_status | PRELIMINARY          |
      | asset_type             | LOAD                 |
      | processing_status      | CREATING             |
    Then the response should include the new settlement_item
    And GET settlement_item should return the new entity
    And the settlement_item is_inactive field should be null

  # Cleanup
    When I DELETE the settlement_item
    When I DELETE the settlement


  Scenario: Create settlement_item with is_inactive = null explicitly
    When I POST a settlement with the following properties:
      | settlement_type         | ONGOING_DATA_SUBMISSION              |
      | settlement_subtype      | TVA event                            |
      | start_dttm_utc          | 2023-09-05T08:00:00Z                 |
      | end_dttm_utc            | 2023-09-05T09:00:00Z                 |
      | event_id                | <uuid>                               |
      | description             | QAA test: is_inactive explicit null  |
      | settlement_status       | PRELIMINARY                          |
      | business_process_status | NOT_STARTED                          |
      | source_system_type      | NGP                                  |
    Then the response should include the new settlement

    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | REGISTRATION         |
      | settlement_level_id    | <uuid>               |
      | submitted_indicator    | true                 |
      | settlement_item_status | PRELIMINARY          |
      | asset_type             | LOAD                 |
      | processing_status      | CREATING             |
      | is_inactive            | null                 |
    Then the response should include the new settlement_item
    And GET settlement_item should return the new entity
    And the settlement_item is_inactive field should be null

  # Cleanup
    When I DELETE the settlement_item
    When I DELETE the settlement


  Scenario: Create settlement_item with is_inactive = true
    When I POST a settlement with the following properties:
      | settlement_type         | ONGOING_DATA_SUBMISSION         |
      | settlement_subtype      | TVA event                       |
      | start_dttm_utc          | 2023-09-05T08:00:00Z            |
      | end_dttm_utc            | 2023-09-05T09:00:00Z            |
      | event_id                | <uuid>                          |
      | description             | QAA test: is_inactive true      |
      | settlement_status       | PRELIMINARY                     |
      | business_process_status | NOT_STARTED                     |
      | source_system_type      | NGP                             |
    Then the response should include the new settlement

    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | REGISTRATION         |
      | settlement_level_id    | <uuid>               |
      | submitted_indicator    | true                 |
      | settlement_item_status | PRELIMINARY          |
      | asset_type             | LOAD                 |
      | processing_status      | CREATING             |
      | is_inactive            | true                 |
    Then the response should include the new settlement_item
    And GET settlement_item should return the new entity
    And the settlement_item is_inactive field should be true

  # Cleanup
    When I DELETE the settlement_item
    When I DELETE the settlement


  Scenario: Create settlement_item with is_inactive = false
    When I POST a settlement with the following properties:
      | settlement_type         | ONGOING_DATA_SUBMISSION         |
      | settlement_subtype      | TVA event                       |
      | start_dttm_utc          | 2023-09-05T08:00:00Z            |
      | end_dttm_utc            | 2023-09-05T09:00:00Z            |
      | event_id                | <uuid>                          |
      | description             | QAA test: is_inactive false     |
      | settlement_status       | PRELIMINARY                     |
      | business_process_status | NOT_STARTED                     |
      | source_system_type      | NGP                             |
    Then the response should include the new settlement

    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | REGISTRATION         |
      | settlement_level_id    | <uuid>               |
      | submitted_indicator    | true                 |
      | settlement_item_status | PRELIMINARY          |
      | asset_type             | LOAD                 |
      | processing_status      | CREATING             |
      | is_inactive            | false                |
    Then the response should include the new settlement_item
    And GET settlement_item should return the new entity
    And the settlement_item is_inactive field should be false

  # Cleanup
    When I DELETE the settlement_item
    When I DELETE the settlement


  Scenario: Create settlement_item with invalid is_inactive value returns 400
    When I POST a settlement with the following properties:
      | settlement_type         | ONGOING_DATA_SUBMISSION              |
      | settlement_subtype      | TVA event                            |
      | start_dttm_utc          | 2023-09-05T08:00:00Z                 |
      | end_dttm_utc            | 2023-09-05T09:00:00Z                 |
      | event_id                | <uuid>                               |
      | description             | QAA test: is_inactive invalid parent |
      | settlement_status       | PRELIMINARY                          |
      | business_process_status | NOT_STARTED                          |
      | source_system_type      | NGP                                  |
    Then the response should include the new settlement

    Given I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | REGISTRATION         |
      | settlement_level_id    | <uuid>               |
      | submitted_indicator    | true                 |
      | settlement_item_status | PRELIMINARY          |
      | asset_type             | LOAD                 |
      | processing_status      | CREATING             |
      | is_inactive            | not-a-boolean        |
    Then the expected status should be returned

  # Cleanup
    When I DELETE the settlement


    # ==============================================================================
    # is_inactive – PUT / PATCH lifecycle
    # ==============================================================================

  Scenario: PUT/PATCH settlement_item is_inactive from null to true then false then null
    When I POST a settlement with the following properties:
      | settlement_type         | ONGOING_DATA_SUBMISSION               |
      | settlement_subtype      | TVA event                             |
      | start_dttm_utc          | 2023-09-05T08:00:00Z                  |
      | end_dttm_utc            | 2023-09-05T09:00:00Z                  |
      | event_id                | <uuid>                                |
      | description             | QAA test: is_inactive lifecycle       |
      | settlement_status       | PRELIMINARY                           |
      | business_process_status | NOT_STARTED                           |
      | source_system_type      | NGP                                   |
    Then the response should include the new settlement

    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | REGISTRATION         |
      | settlement_level_id    | <uuid>               |
      | submitted_indicator    | true                 |
      | settlement_item_status | PRELIMINARY          |
      | asset_type             | LOAD                 |
      | processing_status      | CREATING             |
    Then the response should include the new settlement_item
    And GET settlement_item should return the new entity
    And the settlement_item is_inactive field should be null

  # PUT: null → false
    When I PUT the settlement_item with new values:
      | settlement_id          | <last-settlement-id>      |
      | settlement_item_id     | <last-settlement-item-id> |
      | settlement_level       | REGISTRATION              |
      | settlement_level_id    | <last-settlement-level-id> |
      | submitted_indicator    | true                      |
      | settlement_item_status | PRELIMINARY               |
      | asset_type             | LOAD                      |
      | processing_status      | CREATING                  |
      | is_inactive            | false                      |
      | change_comments        | Set is_inactive to false   |
    Then the response should include the updated settlement_item
    And GET settlement_item should return the updated entity
    And the settlement_item is_inactive field should be false
    And changes should be recorded in the settlement_item audit log

  # PATCH: false → true
    When I PATCH the settlement_item with new values:
      | settlement_item_id | <last-settlement-item-id> |
      | change_comments    | Set is_inactive to true  |
      | is_inactive        | true                     |
    And GET settlement_item should return the updated entity
    And the settlement_item is_inactive field should be true
    And changes should be recorded in the settlement_item audit log

  # PATCH: true → null
    When I PATCH the settlement_item with new values:
      | settlement_item_id | <last-settlement-item-id> |
      | is_inactive        | null                      |
      | change_comments    | Clear is_inactive         |
    And GET settlement_item should return the updated entity
    And the settlement_item is_inactive field should be null
    And changes should be recorded in the settlement_item audit log

  # PUT: null → true
    When I PUT the settlement_item with new values:
      | settlement_id          | <last-settlement-id>      |
      | settlement_item_id     | <last-settlement-item-id> |
      | settlement_level       | REGISTRATION              |
      | settlement_level_id    | <last-settlement-level-id> |
      | submitted_indicator    | true                      |
      | settlement_item_status | PRELIMINARY               |
      | asset_type             | LOAD                      |
      | processing_status      | CREATING                  |
      | is_inactive            | true                      |
      | change_comments        | Set is_inactive to true   |
    Then the response should include the updated settlement_item
    And GET settlement_item should return the updated entity
    And the settlement_item is_inactive field should be true
    And changes should be recorded in the settlement_item audit log

  # Cleanup
    When I DELETE the settlement_item
    When I DELETE the settlement


   # Negative checks for is_inactive
  Scenario: PUT/PATCH settlement_item set incorrect values for is_inactive
    When I POST a settlement with the following properties:
      | settlement_type         | ONGOING_DATA_SUBMISSION               |
      | settlement_subtype      | TVA event                             |
      | start_dttm_utc          | 2023-09-05T08:00:00Z                  |
      | end_dttm_utc            | 2023-09-05T09:00:00Z                  |
      | event_id                | <uuid>                                |
      | description             | QAA test: is_inactive lifecycle       |
      | settlement_status       | PRELIMINARY                           |
      | business_process_status | NOT_STARTED                           |
      | source_system_type      | NGP                                   |
    Then the response should include the new settlement

    When I POST a settlement_item with the following properties:
      | settlement_id          | <last-settlement-id> |
      | settlement_level       | REGISTRATION         |
      | settlement_level_id    | <uuid>               |
      | submitted_indicator    | true                 |
      | settlement_item_status | PRELIMINARY          |
      | asset_type             | LOAD                 |
      | processing_status      | CREATING             |
    Then the response should include the new settlement_item
    And GET settlement_item should return the new entity
    And the settlement_item is_inactive field should be null

  # PUT: incorrect is_inactive
    Given I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I PUT the settlement_item with new values:
      | settlement_id          | <last-settlement-id>      |
      | settlement_item_id     | <last-settlement-item-id> |
      | settlement_level       | REGISTRATION              |
      | settlement_level_id    | <last-settlement-level-id> |
      | submitted_indicator    | true                      |
      | settlement_item_status | PRELIMINARY               |
      | asset_type             | LOAD                      |
      | processing_status      | CREATING                  |
      | is_inactive            | test                    |
      | change_comments        | Set is_inactive incorrect   |
    Then the expected status should be returned

    # PATCH: incorrect is_inactive
    Given I expect the next API call to return a status code of 400 and message of "Bad Request"

    When I PATCH the settlement_item with new values:
      | settlement_item_id | <last-settlement-item-id> |
      | change_comments    | Set is_inactive to true  |
      | is_inactive        | 12312313                     |
    Then the expected status should be returned

  # Cleanup
    When I DELETE the settlement_item
    When I DELETE the settlement