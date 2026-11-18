Feature: Feature tests for registration history

  References:

  <CONFLUENCE_URL>/display/XP/Settlement+Data+Service+-+Data+Model
  <GITHUB_URL>/xplatform/settlement-metadata-api
  BDAP-1772: Create API - Participation - GET /registration_history endpoint

  Prerequsities: The scenario 'Create ITS mappings' in Registration.feature

  Background:
    Given I start with an empty context
    And I log in as a settlement API admin


  Scenario: Set up a complex registration history

    Given I set the expected org_id to SmdQaOrg1
    And I delete all existing table rows for the registration registration1
    And I delete all existing table rows for the registration registration2
    And I delete all existing table rows for the registration registration3

    * -> POST a new registration for registration1
    When I POST a new registration specifying the following properties:
      | status                    | INACTIVE |
      | registration_id                        | <registration1>  |
      | product_id                | <product1>                  |
      | flexible_asset_id         | <registration1-fa>                  |
      | ecrm_opportunity_id       | abc                  |
      |last_updated_by            | <username>                  |
    Then the response should include the new registration
    And the registration history should reflect the new operation

    * -> PUT: update fields several times
    When I update the registration with new values:
      | status                    | <null> |
      | service_delivery_point_id                | <uuid>                  |
      |last_updated_by            | <username>                  |
    Then the response should include the updated registration
    And the registration history should reflect the update operation

    When I update the registration with new values:
      | status                    | ACTIVE |
      | ecrm_opportunity_id       | xyz                  |
      |last_updated_by            | <username>                  |
    Then the response should include the updated registration
    And the registration history should reflect the update operation

    * -> DELETE the registration
    When I DELETE my registration
    Then the registration history should reflect the delete operation

    * -> Re-create the registration
    When I POST a new registration specifying the following properties:
      | status                    | INACTIVE |
      | registration_id                        | <registration1>  |
      | product_id                | <product1>                  |
      | flexible_asset_id         | <registration1-fa>                  |
      | ecrm_opportunity_id       | abc                  |
      |last_updated_by            | <username>                  |
    Then the response should include the new registration
    And GET registration should return the current state of the registration
    And the registration history should reflect the recreate operation

    When I update the registration with new values:
      | status                    | ON_HOLD |
      |last_updated_by            | <username>                  |
    Then the response should include the updated registration
    And the registration history should reflect the update operation

    When I update the registration with new values:
      | status                    | ACTIVE |
      |last_updated_by            | <username>                  |
    Then the response should include the updated registration
    And the registration history should reflect the update operation

    Given I manually update the registration history rows effective_start_dttm_utc with the following values:
      | 2020-02-01T00:00:00.000Z|
      | 2020-07-01T00:00:00.000Z|
      | 2021-02-01T00:00:00.000Z|
      | 2021-07-01T00:00:00.000Z|
      | 2022-02-01T00:00:00.000Z|
      | 2022-07-01T00:00:00.000Z|
      | 2023-02-01T00:00:00.000Z|
    Then the registration history should reflect the manual updates

    * -> POST a new registration for registration2
    When I POST a new registration specifying the following properties:
      | status                    | ACTIVE |
      | registration_id                        | <registration2>  |
      | product_id                | <product1>                  |
      | service_delivery_point_id         | <registration2-sdp>                  |
      | ecrm_opportunity_id       | foo                  |
      |last_updated_by            | <username>                  |
    Then the response should include the new registration
    And the registration history should reflect the new operation

    * -> PUT: update fields several times
    When I update the registration with new values:
      | status                    | RETIRED |
      | flexible_asset_id                | <uuid>                  |
      |last_updated_by            | <username>                  |
    Then the response should include the updated registration
    And the registration history should reflect the update operation

    When I update the registration with new values:
      | status                    | READY_TO_ENROLL |
      | ecrm_opportunity_id       | bar                  |
      |last_updated_by            | <username>                  |
    Then the response should include the updated registration
    And the registration history should reflect the update operation

    When I update the registration with new values:
      | status                    | READY_TO_ACCEPTANCE_TEST |
      |last_updated_by            | <username>                  |
    Then the response should include the updated registration
    And the registration history should reflect the update operation

    Given I manually update the registration history rows effective_start_dttm_utc with the following values:
      | 2020-01-01T00:00:00.000Z|
      | 2020-06-01T00:00:00.000Z|
      | 2021-01-01T00:00:00.000Z|
      | 2021-06-01T00:00:00.000Z|
    Then the registration history should reflect the manual updates

    * -> POST a new registration for registration3
    When I POST a new registration specifying the following properties:
      | status                    | RETIRED |
      | registration_id                        | <registration3>  |
      | product_id                | <product2>                  |
      | service_delivery_point_id         | <registration3-sdp>                  |
      | ecrm_opportunity_id       | wow                  |
      |last_updated_by            | <username>                  |
    Then the response should include the new registration
    And the registration history should reflect the new operation

    * -> PUT: update fields several times
    When I update the registration with new values:
      | status                    | ON_HOLD |
      | flexible_asset_id                | <uuid>                  |
      |last_updated_by            | <username>                  |
    Then the response should include the updated registration
    And the registration history should reflect the update operation

    When I update the registration with new values:
      | status                    | INACTIVE |
      | ecrm_opportunity_id       | hooboy                  |
      |last_updated_by            | <username>                  |
    Then the response should include the updated registration
    And the registration history should reflect the update operation

    When I update the registration with new values:
      | status                    | RETIRED |
      |last_updated_by            | <username>                  |
    Then the response should include the updated registration
    And the registration history should reflect the update operation

    Given I manually update the registration history rows effective_start_dttm_utc with the following values:
      | 2020-03-01T00:00:00.000Z|
      | 2020-04-01T00:00:00.000Z|
      | 2021-03-01T00:00:00.000Z|
      | 2021-04-01T00:00:00.000Z|
    Then the registration history should reflect the manual updates


  Scenario: Verify conditionals around dates

    * -> start_dttm_utc is inclusive of row's effective_start_dttm_utc
    * -> end_dttm_utc is exclusive of effective_start_dttm_utc
    * -> start_dttm_utc is exclusive of effective_end_dttm_utc
    * -> special case: if start_dttm_utc and end_dttm_utc both = effective_start_time_utc, then return row (postgres considers this a single time instant)

    Given I retrieve and save the complete registration history for registration2

    * -> No date range given should return the entire history
    When I call GET registration_history as follows:
      | id                  | <registration2>               |
      | id_type             | registration         |
    Then the registration history response should contain 4 rows
    And the correct set of registration history rows should be returned: '1,2,3,4'

    * -> start_dttm_utc < effective_start_time_utc of first row and end_dttm_utc > effective_start_time_utc of fourth row
    * -> Result: rows 1,2,3,4
    When I call GET registration_history as follows:
      | id                  | <registration2>               |
      | id_type             | registration         |
      | start_dttm_utc | 2019-01-01T00:00:00Z |
      | end_dttm_utc   | 2025-12-31T00:00:00Z |
    Then the registration history response should contain 4 rows
    And the correct set of registration history rows should be returned: '1,2,3,4'

    * -> end_dttm_utc < effective_start_time_utc of first row, no rows should be retrieved
    Given I expect the next API call to return a status code of 404 and details of "No registration history found"
    When I call GET registration_history as follows:
      | id                  | <registration2>               |
      | id_type             | registration         |
      | start_dttm_utc | 2019-01-01T00:00:00Z |
      | end_dttm_utc   | 2019-12-31T00:00:00Z |
    Then the expected status should be returned

    * -> end_dttm_utc = effective_start_time_utc of first row, no rows should be retrieved
    Given I expect the next API call to return a status code of 404 and details of "No registration history found"
    When I call GET registration_history as follows:
      | id                  | <registration2>               |
      | id_type             | registration         |
      | start_dttm_utc | 2019-01-01T00:00:00Z |
      | end_dttm_utc   | 2020-01-01T00:00:00Z |
    Then the expected status should be returned

    * > start_dttm_utc < effective_start_time_utc of first row, and end_dttm_utc < effective_end_time_utc
    * -> Result: first row
    When I call GET registration_history as follows:
      | id                  | <registration2>               |
      | id_type             | registration         |
      | start_dttm_utc | 2019-12-31T00:00:00Z |
      | end_dttm_utc   | 2020-01-01T00:00:01Z |
    Then the correct set of registration history rows should be returned: '1'

    * > start_dttm_utc < effective_start_time_utc, and end_dttm_utc = effective_end_time_utc
    * -> Result: first row
    When I call GET registration_history as follows:
      | id                  | <registration2>               |
      | id_type             | registration         |
      | start_dttm_utc | 2019-12-31T00:00:00Z |
      | end_dttm_utc   | 2020-06-01T00:00:00Z |
    Then the correct set of registration history rows should be returned: '1'

    * > start_dttm_utc < effective_start_time_utc, and end_dttm_utc > effective_start_time_utc of second row
    * -> Result: first and second rows
    When I call GET registration_history as follows:
      | id                  | <registration2>               |
      | id_type             | registration         |
      | start_dttm_utc | 2019-12-31T00:00:00Z |
      | end_dttm_utc   | 2020-06-01T00:00:01Z |
    Then the correct set of registration history rows should be returned: '1,2'

    * > start_dttm_utc = effective_start_time_utc and end_dttm_utc < effective_end_time_utc
    * -> Result: first row
    When I call GET registration_history as follows:
      | id                  | <registration2>               |
      | id_type             | registration         |
      | start_dttm_utc | 2020-01-01T00:00:00Z |
      | end_dttm_utc   | 2020-05-31T23:59:59Z |
    Then the correct set of registration history rows should be returned: '1'

    * > start_dttm_utc > effective_start_time_utc and end_dttm_utc  < effective_end_time_utc
    * -> Result: first row
    When I call GET registration_history as follows:
      | id                  | <registration2>               |
      | id_type             | registration         |
      | start_dttm_utc | 2020-01-02T00:00:00Z |
      | end_dttm_utc   | 2020-05-01T00:00:00Z |
    Then the correct set of registration history rows should be returned: '1'

    * > start_dttm_utc = effective_start_time_utc of second row and end_dttm_utc > effective_start_time_utc of second row
    * -> Result: second row
    When I call GET registration_history as follows:
      | id                  | <registration2>               |
      | id_type             | registration         |
      | start_dttm_utc | 2020-06-01T00:00:00Z |
      | end_dttm_utc   | 2020-06-01T00:00:01Z |
    Then the correct set of registration history rows should be returned: '2'

    * > start_dttm_utc > effective_start_time_utc of second row and end_dttm_utc > effective_start_time_utc of second row
    * -> Result: second row
    When I call GET registration_history as follows:
      | id                  | <registration2>               |
      | id_type             | registration         |
      | start_dttm_utc | 2020-06-05T00:00:00Z |
      | end_dttm_utc   | 2020-07-01T00:00:01Z |
    Then the correct set of registration history rows should be returned: '2'

    * > start_dttm_utc > effective_start_time_utc of second row and end_dttm_utc > effective_start_time_utc of third row
    * -> Result: second and third rows
    When I call GET registration_history as follows:
      | id                  | <registration2>               |
      | id_type             | registration         |
      | start_dttm_utc | 2020-07-01T00:00:00Z |
      | end_dttm_utc   | 2021-02-01T00:00:01Z |
    Then the correct set of registration history rows should be returned: '2,3'

    * > start_dttm_utc < effective_start_time_utc of third row and end_dttm_utc > effective_start_time_utc of fourth row
    * -> Result: second, third, and fourth rows
    When I call GET registration_history as follows:
      | id                  | <registration2>               |
      | id_type             | registration         |
      | start_dttm_utc | 2020-08-01T00:00:00Z |
      | end_dttm_utc   | 2025-06-01T00:00:01Z |
    Then the correct set of registration history rows should be returned: '2,3,4'

    * -> start_dttm_utc = effective_start_time_utc of third row, end_dttm_utc = effective_start_time_utc of fourth row
    * -> Result: third row
    When I call GET registration_history as follows:
      | id                  | <registration2>               |
      | id_type             | registration         |
      | start_dttm_utc | 2021-01-01T00:00:00.000Z |
      | end_dttm_utc   | 2021-06-01T00:00:00.000Z |
    Then the correct set of registration history rows should be returned: '3'

    * -> start_dttm_utc > effective_start_time_utc of third row, end_dttm_utc > effective_start_time_utc of fourth row
    * -> Result: third and fourth rows
    When I call GET registration_history as follows:
      | id                  | <registration2>               |
      | id_type             | registration         |
      | start_dttm_utc | 2021-02-01T00:00:00.000Z |
      | end_dttm_utc   | 2021-07-01T00:00:00.000Z |
    Then the correct set of registration history rows should be returned: '3,4'

    * -> start_dttm_utc < effective_start_time_utc of all rows, end_dttm_utc = effective_start_time_utc of fourth row
    * -> Result: first, second and third rows
    When I call GET registration_history as follows:
      | id                  | <registration2>               |
      | id_type             | registration         |
      | start_dttm_utc | 2019-01-01T00:00:00.000Z |
      | end_dttm_utc   | 2021-06-01T00:00:00.000Z |
    Then the correct set of registration history rows should be returned: '1,2,3'

    * -> start_dttm_utc and end_dttm_utc > effective_start_time_utc of last row
    * -> Result: fourth row
    When I call GET registration_history as follows:
      | id                  | <registration2>               |
      | id_type             | registration         |
      | start_dttm_utc | 2500-01-01T00:00:00.000Z |
      | end_dttm_utc   | 2600-06-01T00:00:00.000Z |
    Then the correct set of registration history rows should be returned: '4'

    * > start_dttm_utc = effective_start_time_utc of last row, end_dttm_utc not specified
    * -> Result: fourth row
    When I call GET registration_history as follows:
      | id                  | <registration2>               |
      | id_type             | registration         |
      | start_dttm_utc | 2021-06-01T00:00:00Z |
    Then the correct set of registration history rows should be returned: '4'


  Scenario: Verify special cases where start_dttm_utc and end_dttm_utc are equal (postgres considers this a single time instant)

    Given I retrieve and save the complete registration history for registration2

    * -> start_dttm_utc and end_dttm_utc both < effective_start_time_utc of first row
    Given I expect the next API call to return a status code of 404 and details of "No registration history found"
    When I call GET registration_history as follows:
      | id                  | <registration2>               |
      | id_type             | registration         |
      | start_dttm_utc | 2019-12-31T00:00:00Z |
      | end_dttm_utc   | 2019-12-31T00:00:00Z |
    Then the expected status should be returned

    * -> start_dttm_utc and end_dttm_utc both = effective_start_time_utc of first row
    * -> Result: first row
    When I call GET registration_history as follows:
      | id                  | <registration2>               |
      | id_type             | registration         |
      | start_dttm_utc | 2020-01-01T00:00:00Z |
      | end_dttm_utc   | 2020-01-01T00:00:00Z |
    Then the correct set of registration history rows should be returned: '1'

    * -> start_dttm_utc and end_dttm_utc both are > effective_start and < effective_end of first row
    * -> Result: first row
    When I call GET registration_history as follows:
      | id                  | <registration2>               |
      | id_type             | registration         |
      | start_dttm_utc | 2020-05-01T00:00:00Z |
      | end_dttm_utc   | 2020-05-01T00:00:00Z |
    Then the correct set of registration history rows should be returned: '1'

    * -> start_dttm_utc and end_dttm_utc both = effective_end_time_utc of first row and = effective_start_time of second row
    * -> Result: second row
    When I call GET registration_history as follows:
      | id                  | <registration2>               |
      | id_type             | registration         |
      | start_dttm_utc | 2020-06-01T00:00:00Z |
      | end_dttm_utc   | 2020-06-01T00:00:00Z |
    Then the correct set of registration history rows should be returned: '2'

    * -> start_dttm_utc and end_dttm_utc both = effective_end of second row and = effective_start of third row
    * -> Result: third row
    When I call GET registration_history as follows:
      | id                  | <registration2>               |
      | id_type             | registration         |
      | start_dttm_utc | 2021-01-01T00:00:00Z |
      | end_dttm_utc   | 2021-01-01T00:00:00Z |
    Then the correct set of registration history rows should be returned: '3'

    * -> start_dttm_utc and end_dttm_utc both > effective_start of third row and < effective_end
    * -> Result: third row
    When I call GET registration_history as follows:
      | id                  | <registration2>               |
      | id_type             | registration         |
      | start_dttm_utc | 2021-01-02T00:00:00Z |
      | end_dttm_utc   | 2021-01-02T00:00:00Z |
    Then the correct set of registration history rows should be returned: '3'

    * -> start_dttm_utc and end_dttm_utc both = effective_start of fourth row
    * -> Result: fourth row
    When I call GET registration_history as follows:
      | id                  | <registration2>               |
      | id_type             | registration         |
      | start_dttm_utc | 2021-06-01T00:00:00Z |
      | end_dttm_utc   | 2021-06-01T00:00:00Z |
    Then the correct set of registration history rows should be returned: '4'

    * -> start_dttm_utc and end_dttm_utc both > effective_start of last row
    * -> Result: fourth row
    When I call GET registration_history as follows:
      | id                  | <registration2>               |
      | id_type             | registration         |
      | start_dttm_utc | 2021-07-01T00:00:00Z |
      | end_dttm_utc   | 2021-07-01T00:00:00Z |
    Then the correct set of registration history rows should be returned: '4'


    Scenario: id_type = PRODUCT

      Given I retrieve and save the complete registration history for registration1
      Given I retrieve and save the complete registration history for registration2
      Given I retrieve and save the complete registration history for registration3

      * -> end_dttm_utc < effective_start_time_utc of first row, no rows should be retrieved
      Given I expect the next API call to return a status code of 404 and details of "No registration history found"
      When I call GET registration_history as follows:
        | id                  | <product1>               |
        | id_type             | product         |
        | start_dttm_utc | 2019-01-01T00:00:00Z |
        | end_dttm_utc   | 2019-12-31T00:00:00Z |
      Then the expected status should be returned

      * -> No date range, include_deleted missing
      When I call GET registration_history as follows:
        | id                  | <product1>               |
        | id_type             | product         |
      Then the registration history response should contain 10 rows
      And the correct set of registration history rows should be returned for each registration:
      |registration1|1,2,3,5,6,7|
      |registration2|1,2,3,4|

      * -> No date range, include_deleted = false
      When I call GET registration_history as follows:
        | id                  | <product1>               |
        | id_type             | product         |
      | include_deleted     | false           |
      Then the registration history response should contain 10 rows
      And the correct set of registration history rows should be returned for each registration:
        |registration1|1,2,3,5,6,7|
        |registration2|1,2,3,4|

      * -> No date range, include_deleted = true
      When I call GET registration_history as follows:
        | id                  | <product1>               |
        | id_type             | product         |
        | include_deleted     | true           |
      Then the registration history response should contain 11 rows
      And the correct set of registration history rows should be returned for each registration:
        |registration1|1,2,3,4,5,6,7|
        |registration2|1,2,3,4|

      When I call GET registration_history as follows:
        | id                  | <product2>               |
        | id_type             | product         |
      # This will fail if there are registrations for this product...history needs to be fixed
      # Try it on both dev and preprd
      Then the registration history response should contain at least 4 rows
      And the correct set of registration history rows should be returned for each registration:
        |registration3|1,2,3,4|

      * -> No registration is associated with the product
      Given I expect the next API call to return a status code of 404 and details of "No registration history found"
      When I call GET registration_history as follows:
        | id                  | <uuid>               |
        | id_type             | product         |
      Then the expected status should be returned

      * -> start_dttm_utc and end_dttm_utc are in middle of rows
      When I call GET registration_history as follows:
        | id                  | <product1>               |
        | id_type             | product         |
        | start_dttm_utc | 2020-06-10T00:00:00Z |
        | end_dttm_utc   | 2021-02-05T00:00:00Z |
      Then the registration history response should contain 5 rows
      And the correct set of registration history rows should be returned for each registration:
        |registration1|1,2,3|
        |registration2|2,3|

      * -> start_dttm_utc and end_dttm_utc are on boundaries of registration 1
      When I call GET registration_history as follows:
        | id                  | <product1>               |
        | id_type             | product         |
        | start_dttm_utc | 2020-07-01T00:00:00Z |
        | end_dttm_utc   | 2021-02-01T00:00:00Z |
      Then the registration history response should contain 3 rows
      And the correct set of registration history rows should be returned for each registration:
        |registration1|2|
        |registration2|2,3|

      * -> start_dttm_utc and end_dttm_utc both > effective_start of last row
      When I call GET registration_history as follows:
        | id                  | <product1>               |
        | id_type             | product         |
        | start_dttm_utc | 2022-08-01T00:00:00Z |
        | end_dttm_utc   | 2022-08-01T00:00:00Z |
      Then the registration history response should contain 2 rows
      And the correct set of registration history rows should be returned for each registration:
        |registration1|6|
        |registration2|4|


      Scenario: Status values are specified

        Given I retrieve and save the complete registration history for registration1
        Given I retrieve and save the complete registration history for registration2
        Given I retrieve and save the complete registration history for registration3

        * -> Product. No date range given. More than one status exists. Also, invalid enum is accepted by design.
        When I call GET registration_history as follows:
          | id                  | <product1>               |
          | id_type             | product         |
        | statuses              | ACTIVE,ON_HOLD,FOO          |
        Then the registration history response should contain 4 rows
        And the correct set of registration history rows should be returned for each registration:
          |registration1|3,6,7|
          |registration2|1|

        * -> Product. Same as above, but include_deleted = true
        When I call GET registration_history as follows:
          | id                  | <product1>               |
          | id_type             | product         |
          | statuses              | ACTIVE,ON_HOLD,FOO          |
        | include_deleted       | true                        |
        Then the registration history response should contain 5 rows
        And the correct set of registration history rows should be returned for each registration:
          |registration1|3,4,6,7|
          |registration2|1|

        * -> Product. Same as above, but date range spans entire history
        When I call GET registration_history as follows:
          | id                  | <product1>               |
          | id_type             | product         |
          | statuses              | ACTIVE,ON_HOLD,FOO          |
          | include_deleted       | true                        |
          |       start_dttm_utc                |2019-01-01T00:00:00Z          |
          |end_dttm_utc   |  2024-06-01T00:00:00.000Z |
        Then the registration history response should contain 5 rows
        And the correct set of registration history rows should be returned for each registration:
          |registration1|3,4,6,7|
          |registration2|1|

        * -> Product. Date range given. Multiple values exist but not all are in date range.
        When I call GET registration_history as follows:
          | id                  | <product1>               |
          | id_type             | product         |
          | statuses              | ACTIVE,ON_HOLD          |
          |       start_dttm_utc                |2020-01-01T00:00:00Z          |
          |end_dttm_utc   |  2021-08-01T00:00:00.000Z |
        Then the registration history response should contain 2 rows
        And the correct set of registration history rows should be returned for each registration:
          |registration1|3|
          |registration2|1|

        * -> Product. Same as above but include_deleted = true
        When I call GET registration_history as follows:
          | id                  | <product1>               |
          | id_type             | product         |
          | statuses              | ACTIVE,ON_HOLD          |
          | include_deleted       | true                        |
          |       start_dttm_utc                |2020-01-01T00:00:00Z          |
          |end_dttm_utc   |  2021-08-01T00:00:00.000Z |
        Then the registration history response should contain 3 rows
        And the correct set of registration history rows should be returned for each registration:
          |registration1|3,4|
          |registration2|1|

        * -> Product. Date range given. Multiple values exist but none are in date range.
        Given I expect the next API call to return a status code of 404 and details of "No registration history found"
        When I call GET registration_history as follows:
          | id                  | <product1>               |
          | id_type             | product         |
          | statuses              | ACTIVE          |
          | start_dttm_utc    |2020-06-01T00:00:00.000Z          |
          |end_dttm_utc   | 2021-01-15T00:00:00.000Z |
        Then the expected status should be returned

        * -> Registration. Date range spans entire history
        When I call GET registration_history as follows:
          | id                  | <registration1>               |
          | id_type             | registration         |
          | statuses              | ACTIVE          |
          | start_dttm_utc                |2019-07-01T00:00:00Z          |
          |end_dttm_utc   | 2024-02-01T00:00:00Z |
        Then the registration history response should contain 2 rows
        And the correct set of registration history rows should be returned: '3,7'

        * -> Registration. Same as above but include_deleted = true
        When I call GET registration_history as follows:
          | id                  | <registration1>               |
          | id_type             | registration         |
          | statuses              | ACTIVE          |
          | include_deleted       | true                        |
          | start_dttm_utc                |2019-07-01T00:00:00Z          |
          |end_dttm_utc   | 2024-02-01T00:00:00Z |
        Then the registration history response should contain 3 rows
        And the correct set of registration history rows should be returned: '3,4,7'

        * -> Registration. Date range includes multiple values.
        When I call GET registration_history as follows:
          | id                  | <registration2>               |
          | id_type             | registration         |
          | statuses              | ACTIVE,READY_TO_ACCEPTANCE_TEST,READY_TO_ENROLL,RETIRED          |
        |       start_dttm_utc                |2020-07-01T00:00:00Z          |
        |end_dttm_utc   | 2021-02-01T00:00:00Z |
        Then the registration history response should contain 2 rows
        And the correct set of registration history rows should be returned: '2,3'

        * -> Registration. Two rows with the status exist but only one is in the date range.
        When I call GET registration_history as follows:
          | id                  | <registration3>               |
          | id_type             | registration         |
          | statuses              | RETIRED          |
          | start_dttm_utc    |2020-01-01T00:00:00Z          |
          |end_dttm_utc   | 2020-06-01T00:00:00Z |
        Then the registration history response should contain 1 rows
        And the correct set of registration history rows should be returned: '1'

        * -> Registration. Two rows with the status exist but none are in the date range.
        Given I expect the next API call to return a status code of 404 and details of "No registration history found"
        When I call GET registration_history as follows:
          | id                  | <registration3>               |
          | id_type             | registration         |
          | statuses              | RETIRED          |
          | start_dttm_utc    |2020-05-01T00:00:00Z          |
          |end_dttm_utc   | 2020-06-01T00:00:00Z |
        Then the expected status should be returned

        * -> Registration. Date range not specified but no row with status exists.
        Given I expect the next API call to return a status code of 404 and details of "No registration history found"
        When I call GET registration_history as follows:
          | id                  | <registration3>               |
          | id_type             | registration         |
          | statuses              | READY_TO_ACCEPTANCE_TEST          |
        Then the expected status should be returned


  Scenario: Paging: per_page query parameter

    Given I retrieve and save the complete registration history for registration1
    Given I retrieve and save the complete registration history for registration2

    * -> per_page = 0
    Given I expect the next API call to return a status code of 400 and details of "\"per_page\" must be greater than or equal to 1"
    When I call GET registration_history as follows:
      | id                  | <product1>               |
      | id_type             | product         |
      | include_deleted       | true                        |
    | per_page              | 0                           |
    Then the expected status should be returned

    * -> per_page = 1
    When I call GET registration_history as follows:
      | id                  | <product1>               |
      | id_type             | product         |
      | include_deleted       | true                        |
      | per_page              | 1                           |
    Then the registration history response should contain 11 rows
    And the correct set of registration history rows should be returned for each registration:
      |registration1|1,2,3,4,5,6,7|
      |registration2|1,2,3,4|

    * -> per_page = 3
    When I call GET registration_history as follows:
      | id                  | <product1>               |
      | id_type             | product         |
      | include_deleted       | true                        |
      | per_page              | 3                           |
    Then the registration history response should contain 11 rows
    And the correct set of registration history rows should be returned for each registration:
      |registration1|1,2,3,4,5,6,7|
      |registration2|1,2,3,4|

    * -> per_page = (total - 1)
    When I call GET registration_history as follows:
      | id                  | <product1>               |
      | id_type             | product         |
      | include_deleted       | true                        |
      | per_page              | 10                           |
    Then the registration history response should contain 11 rows
    And the correct set of registration history rows should be returned for each registration:
      |registration1|1,2,3,4,5,6,7|
      |registration2|1,2,3,4|

    * -> per_page = total
    When I call GET registration_history as follows:
      | id                  | <product1>               |
      | id_type             | product         |
      | include_deleted       | true                        |
      | per_page              | 11                           |
    Then the registration history response should contain 11 rows
    And the correct set of registration history rows should be returned for each registration:
      |registration1|1,2,3,4,5,6,7|
      |registration2|1,2,3,4|

    * -> per_page = (total + 1)
    When I call GET registration_history as follows:
      | id                  | <product1>               |
      | id_type             | product         |
      | include_deleted       | true                        |
      | per_page              | 12                           |
    Then the registration history response should contain 11 rows
    And the correct set of registration history rows should be returned for each registration:
      |registration1|1,2,3,4,5,6,7|
      |registration2|1,2,3,4|

    * -> per_page = large number
    When I call GET registration_history as follows:
      | id                  | <product1>               |
      | id_type             | product         |
      | include_deleted       | true                        |
      | per_page              | 1000                           |
    Then the registration history response should contain 11 rows
    And the correct set of registration history rows should be returned for each registration:
      |registration1|1,2,3,4,5,6,7|
      |registration2|1,2,3,4|

    * -> registration
    When I call GET registration_history as follows:
      | id                  | <registration1>               |
      | id_type             | registration         |
      | include_deleted       | true                        |
      | per_page              | 2                           |
    Then the registration history response should contain 7 rows
    And the correct set of registration history rows should be returned for each registration:
      |registration1|1,2,3,4,5,6,7|


  Scenario: Paging: page query parameter

    Given I retrieve and save the complete registration history for registration1
    Given I retrieve and save the complete registration history for registration2

    * -> page = 0
    Given I expect the next API call to return a status code of 400 and details of "\"page\" must be greater than or equal to 1"
    When I call GET registration_history as follows:
      | id                  | <product1>               |
      | id_type             | product         |
      | include_deleted       | true                        |
      | page              | 0                           |
    Then the expected status should be returned

    * -> page = 1
    When I call GET registration_history as follows:
      | id                  | <product1>               |
      | id_type             | product         |
      | include_deleted       | true                        |
      | per_page              | 3                           |
    | page              | 1                           |
    Then the registration history response should contain 3 rows
    And these rows should be returned for each registration:
      |registration1|1,2,3|

    * -> page = 2
    When I call GET registration_history as follows:
      | id                  | <product1>               |
      | id_type             | product         |
      | include_deleted       | true                        |
      | per_page              | 3                           |
      | page              | 2                           |
    Then the registration history response should contain 3 rows
    And these rows should be returned for each registration:
      |registration1|4,5,6|

    * -> page = 3
    When I call GET registration_history as follows:
      | id                  | <product1>               |
      | id_type             | product         |
      | include_deleted       | true                        |
      | per_page              | 3                           |
      | page              | 3                           |
    Then the registration history response should contain 3 rows
    And these rows should be returned for each registration:
      |registration1|7|
      |registration2|1,2|

    * -> page = last page
    When I call GET registration_history as follows:
      | id                  | <product1>               |
      | id_type             | product         |
      | include_deleted       | true                        |
      | per_page              | 3                           |
      | page              | 4                           |
    Then the registration history response should contain 2 rows
    And these rows should be returned for each registration:
      |registration2|3,4|

    * -> page > last page
    Given I expect the next API call to return a status code of 500 and details of "Invalid page number in query"
    When I call GET registration_history as follows:
      | id                  | <product1>               |
      | id_type             | product         |
      | include_deleted       | true                        |
      | page              | 1000                           |
    Then the expected status should be returned

    * -> page with other query parameters
    When I call GET registration_history as follows:
      | id                  | <product1>               |
      | id_type             | product         |
      | statuses              | ACTIVE,ON_HOLD          |
      |       start_dttm_utc                |2020-01-01T00:00:00Z          |
      |end_dttm_utc   |  2021-08-01T00:00:00.000Z |
    | per_page      | 1                         |
    | page          | 2                         |
    Then the registration history response should contain 1 rows
    And these rows should be returned for each registration:
      |registration2|1|

    * -> id_type = registration
    When I call GET registration_history as follows:
      | id                  | <registration2>               |
      | id_type             | registration         |
      | include_deleted       | true                        |
      | per_page              | 2                           |
    | page                  | 2                           |
    Then the registration history response should contain 2 rows
    And these rows should be returned for each registration:
      | registration2 | 3,4 |

    Scenario: New GET param: "user_raw_history" set to true

      Given I retrieve and save the complete registration history for registration1

      * -> use_raw_history = true.
      When I call GET registration_history as follows:
        | id                  | <registration1>               |
        | id_type             | registration         |
        | use_raw_history    | true                        |
      Then the registration history response should contain at least 1 rows

  Scenario: New GET param: "use_raw_history" set to false

    Given I retrieve and save the complete registration history for registration1

    * -> use_raw_history = false.
    When I call GET registration_history as follows:
      | id                  | <registration1>               |
      | id_type             | registration         |
      | use_raw_history    | false                        |
    Then the registration history response should contain at least 1 rows
    Then the most recent registration history row should have has_override false

  Scenario: GET fails with 400 if use_raw_history is not a boolean
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I call GET registration_history as follows:
      | id                  | <registration1>               |
      | id_type             | registration         |
      | use_raw_history    | test                        |
    Then the expected status should be returned
