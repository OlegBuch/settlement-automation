Feature: Feature tests for registration field history

  References:

  <CONFLUENCE_URL>/display/XP/Settlement+Data+Service+-+Data+Model
  <GITHUB_URL>/xplatform/settlement-metadata-api
  BDAP-1772: Create API - Participation - GET /registration_field_history endpoint

  Prerequsities: The scenario 'Create ITS mappings' in Registration.feature

  Background:
    Given I stop here because "this feaure is post-MVP"
    Given I start with an empty context
    And I log in as a settlement API admin


    Scenario: Set up a complex registration history

      Given I set the expected org_id to SmdQaOrg1
      And I delete all existing table rows for the registration registration2

      * -> POST a new registration for QAA_IDS_REGIS_REG_30MIN_SRC with all properties
      When I POST a new registration specifying the following properties:
        | status                    | INACTIVE |
        | registration_id                        | <registration2>  |
        | product_id                | <uuid>                  |
        | flexible_asset_id         | <uuid>                  |
        | site_id              | <SmdQaSite1>                  |
        | ecrm_opportunity_id       | abc                  |
        |last_updated_by            | <uuid>                  |
      Then the response should include the new registration
      And the registration history should reflect the new operation

      * -> Manually update the registration history rows
      Given I manually update the most recent registration field history rows effective_start_dttm_utc with the following values:
        | effective_start_dttm_utc | 2020-01-01T00:00:00.000Z|
        | override_reason          | Set 1       |
      Then the manual updates should be reflected in the registration history

      * -> PUT: update the status and product_id fields several times
      When I update the registration with new values:
        | status                    | STARTED |
        | product_id                | <uuid>                  |
        |last_updated_by            | <uuid>                  |
      Then the response should include the updated registration
      And the registration history should reflect the update operation

      Given I manually update the most recent registration field history rows effective_start_dttm_utc with the following values:
        | effective_start_dttm_utc | 2020-06-01T00:00:00.000Z|
        | override_reason          | Set 2       |
      Then the manual updates should be reflected in the registration history

      When I update the registration with new values:
        | status                    | INPROGRESS |
        | ecrm_opportunity_id       | xyz                  |
        |last_updated_by            | <uuid>                  |
      Then the response should include the updated registration
      And the registration history should reflect the update operation

      Given I manually update the most recent registration field history rows effective_start_dttm_utc with the following values:
        | effective_start_dttm_utc | 2021-01-01T00:00:00.000Z|
        | override_reason          | Set 3      |
      Then the manual updates should be reflected in the registration history

      When I update the registration with new values:
        | status                    | DONE |
        |last_updated_by            | <uuid>                  |
      Then the response should include the updated registration
      And the registration history should reflect the update operation

      Given I manually update the most recent registration field history rows effective_start_dttm_utc with the following values:
        | effective_start_dttm_utc | 2021-06-01T00:00:00.000Z|
        | override_reason          | Set 4       |
      Then the manual updates should be reflected in the registration history


      Scenario: Verify conditionals around dates

        * -> start_dttm_utc is inclusive of row's effective_start_dttm_utc
        * -> end_dttm_utc is exclusive of effective_start_dttm_utc
        * -> start_dttm_utc is exclusive of effective_end_dttm_utc
        * -> special case: if start_dttm_utc and end_dttm_utc both = effective_start_time_utc, then return row (postgres considers this a single time instant)

      Given I retrieve and save the complete registration history for registration2

        * -> No date range given should return the entire history
        When I call GET registration_field_history as follows:
          | id                  | <registration2>               |
          | id_type             | registration         |
        Then the registration field history response should contain 16 rows
        And the correct set of registration field history rows should be returned

        * -> end_dttm_utc < effective_start_time_utc of first row, no rows should be retrieved
        Given I expect the next API call to return a status code of 404 and details of "No registration field history found"
        When I call GET registration_field_history as follows:
          | id                  | <registration2>               |
          | id_type             | registration         |
          | start_dttm_utc | 2019-01-01T00:00:00Z |
          | end_dttm_utc   | 2019-12-31T00:00:00Z |
        Then the expected status should be returned

        * -> end_dttm_utc = effective_start_time_utc of first row, no rows should be retrieved
        Given I expect the next API call to return a status code of 404 and details of "No registration field history found"
        When I call GET registration_field_history as follows:
          | id                  | <registration2>               |
          | id_type             | registration         |
          | start_dttm_utc | 2019-01-01T00:00:00Z |
          | end_dttm_utc   | 2020-01-01T00:00:00Z |
        Then the expected status should be returned

        * -> end_dttm_utc > effective_start_time_utc of first row
        * -> Result: all of first set
        When I call GET registration_field_history as follows:
          | id                  | <registration2>               |
          | id_type             | registration         |
          | start_dttm_utc | 2019-01-01T00:00:00Z |
          | end_dttm_utc   | 2020-01-01T00:00:01Z |
        Then the correct set of registration field history rows should be returned

        * > start_dttm_utc < effective_start_time_utc, and end_dttm_utc > effective_start_time_utc and < effective_end_time_utc
        * -> Result: all of first set
        When I call GET registration_field_history as follows:
          | id                  | <registration2>               |
          | id_type             | registration         |
          | start_dttm_utc | 2019-12-31T00:00:00Z |
          | end_dttm_utc   | 2020-01-01T00:00:01Z |
        Then the correct set of registration field history rows should be returned

        * > start_dttm_utc < effective_start_time_utc, and end_dttm_utc = effective_end_time_utc
        * -> Result: all of first set
        When I call GET registration_field_history as follows:
          | id                  | <registration2>               |
          | id_type             | registration         |
          | start_dttm_utc | 2019-12-31T00:00:00Z |
          | end_dttm_utc   | 2020-06-01T00:00:00Z |
        Then the correct set of registration field history rows should be returned

        * > start_dttm_utc < effective_start_time_utc, and end_dttm_utc > effective_end_time_utc
        * -> Result: all of first set
        When I call GET registration_field_history as follows:
          | id                  | <registration2>               |
          | id_type             | registration         |
          | start_dttm_utc | 2019-12-31T00:00:00Z |
          | end_dttm_utc   | 2020-06-01T00:00:01Z |
        Then the correct set of registration field history rows should be returned

        * > start_dttm_utc = effective_start_time_utc and end_dttm_utc < effective_end_time_utc
        * -> Result: all of first set
        When I call GET registration_field_history as follows:
          | id                  | <registration2>               |
          | id_type             | registration         |
          | start_dttm_utc | 2020-01-01T00:00:00Z |
          | end_dttm_utc   | 2020-05-31T23:59:59Z |
        Then the correct set of registration field history rows should be returned

        * > start_dttm_utc = effective_end_time_utc and end_dttm_utc > effective_start_time_utc of second set of rows
        * -> Result: all of second set plus previous infinity rows
        When I call GET registration_field_history as follows:
          | id                  | <registration2>               |
          | id_type             | registration         |
          | start_dttm_utc | 2020-06-01T00:00:00Z |
          | end_dttm_utc   | 2020-06-01T00:00:01Z |
        Then the correct set of registration field history rows should be returned

        * > start_dttm_utc = effective_start_time_utc of last set, end_dttm_utc not specified
        * -> Result: all of last set plus previous infinity rows
        When I call GET registration_field_history as follows:
          | id                  | <registration2>               |
          | id_type             | registration         |
          | start_dttm_utc | 2021-06-01T00:00:00Z |
        Then the correct set of registration field history rows should be returned

        * -> start_dttm_utc = effective_start_time_utc of third set, end_dttm_utc = effective_start_time_utc of fourth set
        * -> Result: all of third set plus all previous infinity rows
        When I call GET registration_field_history as follows:
          | id                  | <registration2>               |
          | id_type             | registration         |
          | start_dttm_utc | 2021-01-01T00:00:00.000Z |
          | end_dttm_utc   | 2021-06-01T00:00:00.000Z |
        Then the correct set of registration field history rows should be returned

        * -> start_dttm_utc < effective_start_time_utc of all sets, end_dttm_utc = effective_start_time_utc of fourth set.
        * -> Result: all first, second and third set rows
        When I call GET registration_field_history as follows:
          | id                  | <registration2>               |
          | id_type             | registration         |
          | start_dttm_utc | 2019-01-01T00:00:00.000Z |
          | end_dttm_utc   | 2021-06-01T00:00:00.000Z |
        Then the correct set of registration field history rows should be returned

        * -> start_dttm_utc > effective_end_time_utc of fourth set
        * -> Restult: all infinity rows
        When I call GET registration_field_history as follows:
          | id                  | <registration2>               |
          | id_type             | registration         |
          | start_dttm_utc | 2500-01-01T00:00:00.000Z |
          | end_dttm_utc   | 2600-06-01T00:00:00.000Z |
        Then the correct set of registration field history rows should be returned


  Scenario: Verify special cases where start_dttm_utc and end_dttm_utc are equal (postgres considers this a single time instant)

    Given I retrieve and save the complete registration history for registration2

    * -> start_dttm_utc and end_dttm_utc both = effective_start_time_utc of first set
    * -> Result: all of first set
    When I call GET registration_field_history as follows:
      | id                  | <registration2>               |
      | id_type             | registration         |
      | start_dttm_utc | 2020-01-01T00:00:00Z |
      | end_dttm_utc   | 2020-01-01T00:00:00Z |
    Then the correct set of registration field history rows should be returned

    * -> start_dttm_utc and end_dttm_utc both are > effective_start and < effective_end of first set
    * -> Result: all of first set
    When I call GET registration_field_history as follows:
      | id                  | <registration2>               |
      | id_type             | registration         |
      | start_dttm_utc | 2020-05-01T00:00:00Z |
      | end_dttm_utc   | 2020-05-01T00:00:00Z |
    Then the correct set of registration field history rows should be returned

    * -> start_dttm_utc and end_dttm_utc both = effective_end_time_utc of first set of rows = effective_start_time of second set
    * -> Result: all of second set and infinity rows of first set
    When I call GET registration_field_history as follows:
      | id                  | <registration2>               |
      | id_type             | registration         |
      | start_dttm_utc | 2020-06-01T00:00:00Z |
      | end_dttm_utc   | 2020-06-01T00:00:00Z |
    Then the correct set of registration field history rows should be returned

    * -> start_dttm_utc and end_dttm_utc both = effective_end of second set of rows = effective_start of third set
    * -> Result: all of third set and previous infinity rows
    When I call GET registration_field_history as follows:
      | id                  | <registration2>               |
      | id_type             | registration         |
      | start_dttm_utc | 2021-01-01T00:00:00Z |
      | end_dttm_utc   | 2021-01-01T00:00:00Z |
    Then the correct set of registration field history rows should be returned

    * -> start_dttm_utc and end_dttm_utc both > effective_start of third set and < effective_end
    * -> Result: all of third set and previous infinity rows
    When I call GET registration_field_history as follows:
      | id                  | <registration2>               |
      | id_type             | registration         |
      | start_dttm_utc | 2021-01-02T00:00:00Z |
      | end_dttm_utc   | 2021-01-02T00:00:00Z |
    Then the correct set of registration field history rows should be returned

    * -> start_dttm_utc and end_dttm_utc both = effective_start of fourth set of rows
    * -> Result: all of fourth set and previous infinity rows
    When I call GET registration_field_history as follows:
      | id                  | <registration2>               |
      | id_type             | registration         |
      | start_dttm_utc | 2021-06-01T00:00:00Z |
      | end_dttm_utc   | 2021-06-01T00:00:00Z |
    Then the correct set of registration field history rows should be returned

    * -> start_dttm_utc and end_dttm_utc both > effective_start of last set of rows
    * -> Result: all infinity rows
    When I call GET registration_field_history as follows:
      | id                  | <registration2>               |
      | id_type             | registration         |
      | start_dttm_utc | 2021-07-01T00:00:00Z |
      | end_dttm_utc   | 2021-07-01T00:00:00Z |
    Then the correct set of registration field history rows should be returned
