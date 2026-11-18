Feature: Settlement API authorization


  Background:
    Given I start with an empty context
    # These scenarios require calling the external API
    And this scenario is not supported for the devtest environment


  Scenario: SETTLEMENT_USER and SETTLEMENT_ADMIN resources

    Given I log in as a settlement API user

    # User can POST
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

    # User can GET
    And GET settlement should return the new entity

    # User can GET audit log
    But no entries should be found in the settlement audit log

    # User can PUT
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
    Then the response should include the updated settlement

    # User cannot PATCH
    Given I expect the next API call to return a status code of 403 and message of "Access denied."
    When I PATCH the settlement with new values:
      | settlement_id         | <last-settlement-id>             |
      | settlement_status | PRELIMINARY        |
      | change_comments   | Update settlement_status via PATCH    |
    Then the expected status should be returned

    # User cannot DELETE
    Given I expect the next API call to return a status code of 403 and message of "Access denied."
    When I DELETE the settlement
    Then the expected status should be returned

    Given I log in as a settlement API admin

    # Admin can PATCH
    When I PATCH the settlement with new values:
      | settlement_id         | <last-settlement-id>             |
      | settlement_status | PRELIMINARY        |
      | change_comments   | Update settlement_status via PATCH    |
    Then the response should include the updated settlement

    # Admin can DELETE
    When I DELETE the settlement
    Then the DELETE settlement details should specify 0 settlement items and 0 settlement item intervals
    And changes should be recorded in the settlement audit log


    Scenario: User has ADMIN resource but does not have access to product in Atlas

      Given I stop here because "qaa-ids-platformprovider-manager has disappeared from Atlas dev, need to set up a new user"

      Given this scenario is only supported for the dev environment
      Given I log in as a settlement API no_product_access

      Given I expect the next API call to return a status code of 403 and details of "Atlas error: Access denied"
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
      Then the expected status should be returned