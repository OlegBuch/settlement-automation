Feature: GET settlements

  GET /settlements?{query_params}

  query_params:

  settlement_status (exact match)
  settlement_type (exact match)
  event_id (exact match)
  business_process_status (exact match)
  description (exact match) (not in Tech Design doc, but supported)
  start_dttm_utc_from (inclusive chronologically after)
  start_dttm_utc_to (inclusive chronologically before)

  Background:
    Given I start with an empty context
    And I log in as a settlement API user


  Scenario: Set up settlements for GET settlements scenarios

      # Scenario only needs to be run once per env. So if this stepdef fails, you can ignore the failure because it means that the setup is already complete.
    Given I verify that no settlement exists with the event "QAA: GET settlements S1: Event"

    When I POST a settlement with the following properties:
      | settlement_type         | ONGOING_DATA_SUBMISSION        |
      | settlement_subtype      | TVA event                      |
      | settlement_status       | PRELIMINARY                    |
      | business_process_status | NOT_STARTED                    |
      | description             | QAA: GET settlements S1        |
      | event_id                | QAA: GET settlements S1: Event |
      | start_dttm_utc          | 2020-10-05T08:00:00.000Z       |
      | end_dttm_utc            | 2020-10-05T08:30:00.000Z       |
      | source_system_type      | NGP                            |
    Then the response should include the new settlement

    When I POST a settlement with the following properties:
      | settlement_type         | ENROLLMENT                     |
      | settlement_subtype      | PJM event                      |
      | settlement_status       | PRELIMINARY                    |
      | business_process_status | COMPLETE                       |
      | description             | QAA: GET settlements S2        |
      | event_id                | QAA: GET settlements S2: Event |
      | start_dttm_utc          | 2020-10-05T09:00:00.000Z       |
      | end_dttm_utc            | 2020-10-05T09:30:00.000Z       |
      | source_system_type      | NGP                            |
    Then the response should include the new settlement

    When I POST a settlement with the following properties:
      | settlement_type         | MONTHLY_BILL_SAVINGS           |
      | settlement_subtype      | ISO event                      |
      | settlement_status       | AWAITING_DATA                  |
      | business_process_status | COMPLETE                       |
      | description             | QAA: GET settlements S3        |
      | event_id                | QAA: GET settlements S3: Event |
      | start_dttm_utc          | 2020-10-05T10:01:30.123Z       |
      | end_dttm_utc            | 2020-10-05T10:02:00.000Z       |
      | source_system_type      | NGP                            |
    Then the response should include the new settlement

      # Following settlement tests that queries do not return deleted settlements
    When I POST a settlement with the following properties:
      | settlement_type         | ONGOING_DATA_SUBMISSION       |
      | settlement_subtype      | TVA event                     |
      | settlement_status       | PRELIMINARY                   |
      | business_process_status | COMPLETE                      |
      | description             | QAA: GET settlements          |
      | event_id                | QAA: GET settlements: Deleted |
      | start_dttm_utc          | 2020-10-05T10:05:00Z          |
      | end_dttm_utc            | 2020-10-05T10:06:30Z          |
      | source_system_type      | NGP                           |
    Then the response should include the new settlement
    When I DELETE the settlement
    Then the DELETE settlement details should specify 0 settlement items and 0 settlement item intervals
    Given I expect the next API call to return a status code of 404 and details of "no settlement found for id"
    Then GET settlement should return the expected status

      # Following settlement tests the scenario where only start_dttm_utc_from is queried
    When I POST a settlement with the following properties:
      | settlement_type         | MONTHLY_BILL_SAVINGS           |
      | settlement_subtype      | ISO event                      |
      | settlement_status       | PRELIMINARY                    |
      | business_process_status | COMPLETE                       |
      | description             | QAA: GET settlements S4        |
      | event_id                | QAA: GET settlements S4: Event |
      | start_dttm_utc          | 2040-09-05T10:01:30.123Z       |
      | end_dttm_utc            | 2040-09-05T10:02:00.000Z       |
      | source_system_type      | NGP                            |
    Then the response should include the new settlement


  Scenario: Return all settlements in database

    When I set include_deleted=missing
    And I call GET settlements with the following parameters:
      | start_dttm_utc_from | 1980-01-01T00:00:00Z |
      | start_dttm_utc_to   | 3000-01-01T00:00:00Z |
    Then all settlements returned should match the query
    And only non-deleted settlements should be returned

    When I set include_deleted=false
    And I call GET settlements with the following parameters:
      | start_dttm_utc_from | 1980-01-01T00:00:00Z |
      | start_dttm_utc_to   | 3000-01-01T00:00:00Z |
    Then all settlements returned should match the query
    And only non-deleted settlements should be returned

    When I set include_deleted=true
    And I call GET settlements with the following parameters:
      | start_dttm_utc_from | 1980-01-01T00:00:00Z |
      | start_dttm_utc_to   | 3000-01-01T00:00:00Z |
    Then all settlements returned should match the query
    And both deleted and non-deleted settlements should be returned


  Scenario: Query time range

  start_dttm_utc_from: Datetime chronologically before or equal to Settlement Start Time
  start_dttm_utc_to: Datetime chronologically equal to or after Settlement Start Time

    # Verify millis just before and after range
    When I call GET settlements with the following parameters:
      | start_dttm_utc_from | 2020-10-05T07:59:59.999Z |
      | start_dttm_utc_to   | 2020-10-05T08:00:00.001Z |
    Then all settlements returned should match the query
    And the response should contain 1 settlement

    # Verify millis exactly equal to range
    When I call GET settlements with the following parameters:
      | start_dttm_utc_from | 2020-10-05T09:00:00.000Z |
      | start_dttm_utc_to   | 2020-10-05T09:00:00.000Z |
    Then all settlements returned should match the query
    And the response should contain 1 settlement

    # Verify millis just after range
    When I call GET settlements with the following parameters:
      | start_dttm_utc_from | 2020-10-05T08:00:00.001Z |
      | start_dttm_utc_to   | 2020-10-05T09:59:59.999Z |
    Then all settlements returned should match the query
    And the response should contain 1 settlement

    # No events after start-time (there is a deleted settlement that should not be returned)
    When I call GET settlements with the following parameters:
      | start_dttm_utc_from | 2020-10-05T10:01:30.124Z |
      | start_dttm_utc_to   | 2020-10-05T12:00:00.000Z |
    Then the response should not contain any settlements

    # No events before end-time
    When I call GET settlements with the following parameters:
      | start_dttm_utc_from | 1980-10-05T07:00:00.000Z |
      | start_dttm_utc_to   | 1980-10-05T07:59:59.999Z |
    Then the response should not contain any settlements

    # Specifying only start_dttm_utc_from is supported
    When I call GET settlements with the following parameters:
      | start_dttm_utc_from | 2039-08-07T01:00:00.000Z |
    Then all settlements returned should match the query


  Scenario: Query combinations of properties

    When I call GET settlements with the following parameters:
      | settlement_type         | ONGOING_DATA_SUBMISSION        |
      | settlement_status       | PRELIMINARY                    |
      | business_process_status | NOT_STARTED                    |
    Then all settlements returned should match the query
    And the response should contain more than 5 settlements

    When I call GET settlements with the following parameters:
      | settlement_type         | ONGOING_DATA_SUBMISSION        |
      | settlement_status       | PRELIMINARY                    |
      | business_process_status | NOT_STARTED                    |
      | description             | QAA: GET settlements S1        |
    Then all settlements returned should match the query
    And the response should contain 1 settlement

    When I call GET settlements with the following parameters:
      | settlement_type         | ONGOING_DATA_SUBMISSION        |
      | settlement_status       | PRELIMINARY                    |
      | start_dttm_utc_from          | 2020-10-05T08:00:00.000Z       |
      | start_dttm_utc_to            | 2020-10-05T08:30:00.000Z       |
    Then all settlements returned should match the query
    And the response should contain 1 settlement


  Scenario: Query individual properties

    # Verify all supported query properties individually

    When I call GET settlements with the following parameters:
      | settlement_type | ONGOING_DATA_SUBMISSION |
    Then all settlements returned should match the query

    When I call GET settlements with the following parameters:
      | settlement_status | PRELIMINARY |
    Then all settlements returned should match the query

    When I call GET settlements with the following parameters:
      | business_process_status | COMPLETE |
    Then all settlements returned should match the query

    When I call GET settlements with the following parameters:
      | event_id | QAA: GET settlements S2: Event |
    Then all settlements returned should match the query
    And the response should contain 1 settlement

    When I call GET settlements with the following parameters:
      | description | QAA: GET settlements S3 |
    Then all settlements returned should match the query
    And the response should contain 1 settlement

    # Verify that exact match is required

    When I call GET settlements with the following parameters:
      | event_id | QAA: GET settlements S2: event |
    Then the response should not contain any settlements

    When I call GET settlements with the following parameters:
      | description | QAA: GET settlements |
    Then the response should not contain any settlements

     # Verify that deleted settlement is not returned unless include_deleted=true

    When I set include_deleted=missing
    And I call GET settlements with event_id 'QAA: GET settlements: Deleted'
    Then the response should not contain any settlements

    When I set include_deleted=false
    And I call GET settlements with event_id 'QAA: GET settlements: Deleted'
    Then the response should not contain any settlements

    But if I set include_deleted=true
    When I call GET settlements with event_id 'QAA: GET settlements: Deleted'
    Then all settlements returned should match the query
    And the response should contain 1 settlement

   # Verify that following properties are unsupported

    Given I expect the next API call to return a status code of 400 and details of "At least one query parameter must be supplied"
    When I call GET settlements with settlement_subtype 'foo'
    Then the expected status should be returned

    Given I expect the next API call to return a status code of 400 and details of "At least one query parameter must be supplied"
    When I call GET settlements with source_system_type 'NGP'
    Then the expected status should be returned

    Given I expect the next API call to return a status code of 400 and details of "At least one query parameter must be supplied"
    When I call GET settlements with last_updated_by 'foo'
    Then the expected status should be returned

    Given I expect the next API call to return a status code of 400 and details of "At least one query parameter must be supplied"
    When I call GET settlements with last_updated_dttm_utc 'foo'
    Then the expected status should be returned


  Scenario: No settlements found

    When I call GET settlements with settlement_type 'FAKE'
    Then the response should not contain any settlements

    When I call GET settlements with settlement_status 'FAKE'
    Then the response should not contain any settlements

    When I call GET settlements with business_process_status 'FAKE'
    Then the response should not contain any settlements


  Scenario: GET settlements errors

    Given I expect the next API call to return a status code of 400 and details of "At least one query parameter must be supplied"
    When I call GET settlements with no query parameters
    Then the expected status should be returned

    Given I expect the next API call to return a status code of 400 and details of "At least one query parameter must be supplied"
    When I call GET settlements with an invalid query parameter foo = BAR
    Then the expected status should be returned

    Given I expect the next API call to return a status code of 400 and details of "Invalid startDttmUtcFrom, should be in ISO format"
    When I call GET settlements with an invalid query parameter start_dttm_utc_from = BAR
    Then the expected status should be returned

    Given I expect the next API call to return a status code of 400 and details of "Invalid startDttmUtcTo, should be in ISO format"
    When I call GET settlements with an invalid query parameter start_dttm_utc_to = BAR
    Then the expected status should be returned

    # End-time is before start-time
    Given I expect the next API call to return a status code of 400 and details of "start date must be before end date"
    Given I call GET settlements with the following parameters:
      | start_dttm_utc_from | 2018-08-07T01:00:00.000Z |
      | start_dttm_utc_to   | 2018-08-07T00:59:59.999Z |
    Then the expected status should be returned
