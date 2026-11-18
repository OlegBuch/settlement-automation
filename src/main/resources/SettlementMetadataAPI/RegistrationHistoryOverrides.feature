Feature: Feature tests for registration history overrides

  References:

  ITAPPSIT-4096: SMD API: add CRUD API endpoints for registration_history_override table

  Background:
    Given I start with an empty context
    And I log in as a settlement API admin

  Scenario: Full CRUD lifecycle for a registration history override
    And I hard delete all test registration history overrides for known effective windows

    # Generate a random registration id and use it consistently
    Given I generate a random registration id and save it as OverrideRegistrationId

    # POST -> 201 create override
    When I POST a new registration history override specifying the following properties
      | registration_id          | OverrideRegistrationId                     |
      | field_name               | portfolio_id                               |
      | field_value              | 69b78562-d1bc-46d7-90eb-d58d80f281e7       |
      | effective_start_dttm_utc | 2026-04-01T07:33:38.213Z                   |
      | effective_end_dttm_utc   | 2026-04-02T10:33:38.213Z                   |
      | override_reason          | test                                       |
    Then the response should include the new registration history override

    # PUT -> 200 update some fields
    When I update the registration history override with new values
      | field_name               | status                                     |
      | field_value              | 69b78562-d1bc-46d7-90eb-d58d80f281e7       |
      | effective_start_dttm_utc | 2026-04-10T07:33:38.213Z                   |
      | effective_end_dttm_utc   | 2026-04-10T08:33:38.213Z                   |
      | override_reason          | test-update                                |
    Then the response should include the updated registration history override

    # GET all for this registration_id -> 200 and list contains our override
    When I GET all registration history overrides for the current registration
    Then the registration history overrides list should contain my override

    # GET one by id -> 200 and body matches latest state
    When I GET the registration history override by id
    And the registration history override response should contain valid populated fields
    Then GET registration history override should return the current state

    # DELETE -> 204
    When I DELETE my registration history override

    # GET by id after delete -> 404
    Given I expect the next API call to return a status code of 404 and details of "not found"
    When I GET the registration history override by id
    Then the expected status should be returned


  #
  # POST /registration_history_overrides validations
  #
  Scenario: Check that POST validation works
    Given I do not include the ENOC session header
    And I expect the next API call to return a status code of 401 and message of "Unauthorized"
    When I POST a new registration history override specifying the following properties
      | registration_id          | 11111111-1111-1111-1111-111111111111 |
      | field_name               | portfolio_id                         |
      | field_value              | 69b78562-d1bc-46d7-90eb-d58d80f281e7 |
      | effective_start_dttm_utc | 2026-04-01T07:33:38.213Z             |
      | effective_end_dttm_utc   | 2026-04-02T10:33:38.213Z             |
      | override_reason          | test                                 |
    Then the expected status should be returned

  Scenario: POST fails with 403 if API key is missing
    Given I do not include the API key header
    And I expect the next API call to return a status code of 403 and message of "Forbidden"
    When I POST a new registration history override specifying the following properties
      | registration_id          | 22222222-2222-2222-2222-222222222222 |
      | field_name               | portfolio_id                         |
      | field_value              | 69b78562-d1bc-46d7-90eb-d58d80f281e7 |
      | effective_start_dttm_utc | 2026-04-01T07:33:38.213Z             |
      | effective_end_dttm_utc   | 2026-04-02T10:33:38.213Z             |
      | override_reason          | test                                 |
    Then the expected status should be returned

  Scenario: POST returns 400 when registration_id is invalid format
    Given I expect the next API call to return a status code of 400 and details of "failed validation"
    When I POST a new registration history override specifying the following properties
      | registration_id          | not-a-uuid                           |
      | field_name               | portfolio_id                         |
      | field_value              | 69b78562-d1bc-46d7-90eb-d58d80f281e7 |
      | effective_start_dttm_utc | 2026-04-01T07:33:38.213Z             |
      | effective_end_dttm_utc   | 2026-04-02T10:33:38.213Z             |
      | override_reason          | test                                 |
    Then the expected status should be returned

  Scenario: POST returns 400 when field_name is invalid
    Given I expect the next API call to return a status code of 400 and details of "must be one of"
    When I POST a new registration history override specifying the following properties
      | registration_id          | 33333333-3333-3333-3333-333333333333 |
      | field_name               | invalid_field_name                    |
      | field_value              | 69b78562-d1bc-46d7-90eb-d58d80f281e7 |
      | effective_start_dttm_utc | 2026-04-01T07:33:38.213Z             |
      | effective_end_dttm_utc   | 2026-04-02T10:33:38.213Z             |
      | override_reason          | test                                 |
    Then the expected status should be returned

  Scenario: POST returns 400 when field_value is not a string
    Given I expect the next API call to return a status code of 400 and details of "failed validation"
    When I POST a new registration history override specifying the following properties
      | registration_id          | 44444444-4444-4444-4444-444444444444 |
      | field_name               | portfolio_id                         |
      | field_value              | 12345                                |
      | effective_start_dttm_utc | 2026-04-01T07:33:38.213Z             |
      | effective_end_dttm_utc   | 2026-04-02T10:33:38.213Z             |
      | override_reason          | test                                 |
    Then the expected status should be returned

  Scenario: POST returns 400 when override_reason is not a string
    Given I expect the next API call to return a status code of 400 and details of "failed validation"
    When I POST a new registration history override specifying the following properties
      | registration_id          | 55555555-5555-5555-5555-555555555555 |
      | field_name               | portfolio_id                         |
      | field_value              | 69b78562-d1bc-46d7-90eb-d58d80f281e7 |
      | effective_start_dttm_utc | 2026-04-01T07:33:38.213Z             |
      | effective_end_dttm_utc   | 2026-04-02T10:33:38.213Z             |
      | override_reason          | 12345                                |
    Then the expected status should be returned

  Scenario: POST returns 400 when effective_start_dttm_utc is not a date
    Given I expect the next API call to return a status code of 400 and details of "failed validation"
    When I POST a new registration history override specifying the following properties
      | registration_id          | 66666666-6666-6666-6666-666666666666 |
      | field_name               | portfolio_id                         |
      | field_value              | 69b78562-d1bc-46d7-90eb-d58d80f281e7 |
      | effective_start_dttm_utc | not-a-date                           |
      | effective_end_dttm_utc   | 2026-04-02T10:33:38.213Z             |
      | override_reason          | test                                 |
    Then the expected status should be returned

  Scenario: POST returns 400 when effective_end_dttm_utc is not a date
    Given I expect the next API call to return a status code of 400 and details of "failed validation"
    When I POST a new registration history override specifying the following properties
      | registration_id          | 77777777-7777-7777-7777-777777777777 |
      | field_name               | portfolio_id                         |
      | field_value              | 69b78562-d1bc-46d7-90eb-d58d80f281e7 |
      | effective_start_dttm_utc | 2026-04-01T07:33:38.213Z             |
      | effective_end_dttm_utc   | not-a-date                           |
      | override_reason          | test                                 |
    Then the expected status should be returned

  Scenario: POST returns 400 when mandatory fields are missing
    # missing registration_id
    Given I expect the next API call to return a status code of 400 and details of "failed validation"
    When I POST a new registration history override specifying the following properties
      | field_name               | portfolio_id                         |
      | field_value              | 69b78562-d1bc-46d7-90eb-d58d80f281e7 |
      | effective_start_dttm_utc | 2026-04-01T07:33:38.213Z             |
      | effective_end_dttm_utc   | 2026-04-02T10:33:38.213Z             |
      | override_reason          | test                                 |
    Then the expected status should be returned

    # missing field_name
    Given I expect the next API call to return a status code of 400 and details of "failed validation"
    When I POST a new registration history override specifying the following properties
      | registration_id          | 88888888-8888-8888-8888-888888888888 |
      | field_value              | 69b78562-d1bc-46d7-90eb-d58d80f281e7 |
      | effective_start_dttm_utc | 2026-04-01T07:33:38.213Z             |
      | effective_end_dttm_utc   | 2026-04-02T10:33:38.213Z             |
      | override_reason          | test                                 |
    Then the expected status should be returned

    # missing effective_start_dttm_utc
    Given I expect the next API call to return a status code of 400 and details of "failed validation"
    When I POST a new registration history override specifying the following properties
      | registration_id          | 99999999-9999-9999-9999-999999999999 |
      | field_name               | portfolio_id                         |
      | field_value              | 69b78562-d1bc-46d7-90eb-d58d80f281e7 |
      | effective_end_dttm_utc   | 2026-04-02T10:33:38.213Z             |
      | override_reason          | test                                 |
    Then the expected status should be returned

    # missing effective_end_dttm_utc
    Given I expect the next API call to return a status code of 400 and details of "failed validation"
    When I POST a new registration history override specifying the following properties
      | registration_id          | aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa |
      | field_name               | portfolio_id                         |
      | field_value              | 69b78562-d1bc-46d7-90eb-d58d80f281e7 |
      | effective_start_dttm_utc | 2026-04-01T07:33:38.213Z             |
      | override_reason          | test                                 |
    Then the expected status should be returned

    # missing override_reason
    Given I expect the next API call to return a status code of 400 and details of "is required"
    When I POST a new registration history override specifying the following properties
      | registration_id          | aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa |
      | field_name               | portfolio_id                         |
      | field_value              | 69b78562-d1bc-46d7-90eb-d58d80f281e7 |
      | effective_start_dttm_utc | 2026-04-01T07:33:38.213Z             |
      | effective_end_dttm_utc   | 2026-04-01T10:33:38.213Z                                 |
    Then the expected status should be returned

    # missing field_value
    Given I expect the next API call to return a status code of 400 and details of "is required"
    When I POST a new registration history override specifying the following properties
      | registration_id          | aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa |
      | field_name               | portfolio_id                         |
      | effective_start_dttm_utc | 2026-04-01T07:33:38.213Z             |
      | effective_end_dttm_utc   | 2026-04-02T10:33:38.213Z             |
      | override_reason          | test                                 |
    Then the expected status should be returned


  Scenario: POST returns 400 when effective_start_dttm_utc equals effective_end_dttm_utc
    Given I expect the next API call to return a status code of 400 and details of "start must be < end"
    When I POST a new registration history override specifying the following properties
      | registration_id          | bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb |
      | field_name               | portfolio_id                         |
      | field_value              | 69b78562-d1bc-46d7-90eb-d58d80f281e7 |
      | effective_start_dttm_utc | 2026-04-01T07:33:38.213Z             |
      | effective_end_dttm_utc   | 2026-04-01T07:33:38.213Z             |
      | override_reason          | test                                 |
    Then the expected status should be returned

  Scenario: POST returns 400 when a duplicate override exists for same registration and field in overlapping range
    # First create a valid override
    Given I generate a random registration id and save it as OverrideRegistrationId
    When I POST a new registration history override specifying the following properties
      | registration_id          | OverrideRegistrationId |
      | field_name               | portfolio_id                         |
      | field_value              | 69b78562-d1bc-46d7-90eb-d58d80f281e7 |
      | effective_start_dttm_utc | 2026-04-01T07:33:38.213Z             |
      | effective_end_dttm_utc   | 2026-04-02T10:33:38.213Z             |
      | override_reason          | test                                 |
    Then the response should include the new registration history override

    # Second POST with same registration_id/field_name and overlapping dates -> 400
    Given I expect the next API call to return a status code of 400 and details of "Overlapping override timeframes"
    When I POST a new registration history override specifying the following properties
      | registration_id          | OverrideRegistrationId |
      | field_name               | portfolio_id                         |
      | field_value              | 69b78562-d1bc-46d7-90eb-d58d80f281e7 |
      | effective_start_dttm_utc | 2026-04-01T08:00:00.000Z             |
      | effective_end_dttm_utc   | 2026-04-01T09:00:00.000Z             |
      | override_reason          | test-dup                             |
    Then the expected status should be returned

    And I DELETE my registration history override

  #
  # PUT /registration_history_overrides validations
  #
  Scenario: PUT returns 404 when registration history override does not exist
    Given I expect the next API call to return a status code of 404 and details of "not found"
    When I update the registration history override with id "99999999" and new values
      | field_name               | status                                   |
      | field_value              | 69b78562-d1bc-46d7-90eb-d58d80f281e7     |
      | effective_start_dttm_utc | 2026-04-10T07:33:38.213Z                 |
      | effective_end_dttm_utc   | 2026-04-10T08:33:38.213Z                 |
      | override_reason          | test-update                              |
    Then the expected status should be returned

  Scenario: PUT returns 400 when id is invalid (non-numeric)
    Given I expect the next API call to return a status code of 400 and details of "failed validation"
    When I update the registration history override with id "not-an-id" and new values
      | field_name               | status                                   |
      | field_value              | 69b78562-d1bc-46d7-90eb-d58d80f281e7     |
      | effective_start_dttm_utc | 2026-04-10T07:33:38.213Z                 |
      | effective_end_dttm_utc   | 2026-04-10T08:33:38.213Z                 |
      | override_reason          | test-update                              |
    Then the expected status should be returned

  Scenario: PUT returns 404 when id path parameter is empty

    Given I expect the next API call to return a status code of 404 and details of "not found"
    When I update the registration history override with id "" and new values expecting failure
      | field_name               | status                                   |
      | field_value              | 69b78562-d1bc-46d7-90eb-d58d80f281e7     |
      | effective_start_dttm_utc | 2026-04-10T07:33:38.213Z                 |
      | effective_end_dttm_utc   | 2026-04-10T08:33:38.213Z                 |
      | override_reason          | test-update                              |
    Then the expected status should be returned

  # For the following, first create a valid override to update
  Scenario: PUT returns 400 when field_name is invalid
    # Setup override
    Given I generate a random registration id and save it as OverrideRegistrationId
    When I POST a new registration history override specifying the following properties
      | registration_id          | OverrideRegistrationId     |
      | field_name               | portfolio_id                             |
      | field_value              | 69b78562-d1bc-46d7-90eb-d58d80f281e7     |
      | effective_start_dttm_utc | 2026-04-01T07:33:38.213Z                 |
      | effective_end_dttm_utc   | 2026-04-02T10:33:38.213Z                 |
      | override_reason          | test                                     |
    Then the response should include the new registration history override

    Given I expect the next API call to return a status code of 400 and details of "must be one of"
    When I update the current registration history override with new values
      | field_name               | invalid_field_name                       |
      | field_value              | 69b78562-d1bc-46d7-90eb-d58d80f281e7     |
      | effective_start_dttm_utc | 2026-04-10T07:33:38.213Z                 |
      | effective_end_dttm_utc   | 2026-04-10T08:33:38.213Z                 |
      | override_reason          | test-update                              |
    Then the expected status should be returned
    And I DELETE my registration history override

  Scenario: PUT returns 400 when field_value is not a string
    Given I generate a random registration id and save it as OverrideRegistrationId
    When I POST a new registration history override specifying the following properties
      | registration_id          | OverrideRegistrationId     |
      | field_name               | portfolio_id                             |
      | field_value              | 69b78562-d1bc-46d7-90eb-d58d80f281e7     |
      | effective_start_dttm_utc | 2026-04-01T07:33:38.213Z                 |
      | effective_end_dttm_utc   | 2026-04-02T10:33:38.213Z                 |
      | override_reason          | test                                     |
    Then the response should include the new registration history override

    Given I expect the next API call to return a status code of 400 and details of "failed validation"
    When I update the current registration history override with new values
      | field_name               | status                                   |
      | field_value              | 12345                                    |
      | effective_start_dttm_utc | 2026-04-10T07:33:38.213Z                 |
      | effective_end_dttm_utc   | 2026-04-10T08:33:38.213Z                 |
      | override_reason          | test-update                              |
    Then the expected status should be returned
    And I DELETE my registration history override

  Scenario: PUT returns 400 when override_reason is not a string
    Given I generate a random registration id and save it as OverrideRegistrationId
    When I POST a new registration history override specifying the following properties
      | registration_id          | OverrideRegistrationId     |
      | field_name               | portfolio_id                             |
      | field_value              | 69b78562-d1bc-46d7-90eb-d58d80f281e7     |
      | effective_start_dttm_utc | 2026-04-01T07:33:38.213Z                 |
      | effective_end_dttm_utc   | 2026-04-02T10:33:38.213Z                 |
      | override_reason          | test                                     |
    Then the response should include the new registration history override

    Given I expect the next API call to return a status code of 400 and details of "failed validation"
    When I update the current registration history override with new values
      | field_name               | status                                   |
      | field_value              | 69b78562-d1bc-46d7-90eb-d58d80f281e7     |
      | effective_start_dttm_utc | 2026-04-10T07:33:38.213Z                 |
      | effective_end_dttm_utc   | 2026-04-10T08:33:38.213Z                 |
      | override_reason          | 12345                                    |
    Then the expected status should be returned
    And I DELETE my registration history override

  Scenario: PUT returns 400 when effective_start_dttm_utc is not a date
    Given I generate a random registration id and save it as OverrideRegistrationId
    When I POST a new registration history override specifying the following properties
      | registration_id          | OverrideRegistrationId     |
      | field_name               | portfolio_id                             |
      | field_value              | 69b78562-d1bc-46d7-90eb-d58d80f281e7     |
      | effective_start_dttm_utc | 2026-04-01T07:33:38.213Z                 |
      | effective_end_dttm_utc   | 2026-04-02T10:33:38.213Z                 |
      | override_reason          | test                                     |
    Then the response should include the new registration history override

    Given I expect the next API call to return a status code of 400 and details of "failed validation"
    When I update the current registration history override with new values
      | field_name               | status                                   |
      | field_value              | 69b78562-d1bc-46d7-90eb-d58d80f281e7     |
      | effective_start_dttm_utc | not-a-date                               |
      | effective_end_dttm_utc   | 2026-04-10T08:33:38.213Z                 |
      | override_reason          | test-update                              |
    Then the expected status should be returned
    And I DELETE my registration history override

  Scenario: PUT returns 400 when effective_end_dttm_utc is not a date
    Given I generate a random registration id and save it as OverrideRegistrationId
    When I POST a new registration history override specifying the following properties
      | registration_id          | OverrideRegistrationId     |
      | field_name               | portfolio_id                             |
      | field_value              | 69b78562-d1bc-46d7-90eb-d58d80f281e7     |
      | effective_start_dttm_utc | 2026-04-01T07:33:38.213Z                 |
      | effective_end_dttm_utc   | 2026-04-02T10:33:38.213Z                 |
      | override_reason          | test                                     |
    Then the response should include the new registration history override

    Given I expect the next API call to return a status code of 400 and details of "failed validation"
    When I update the current registration history override with new values
      | field_name               | status                                   |
      | field_value              | 69b78562-d1bc-46d7-90eb-d58d80f281e7     |
      | effective_start_dttm_utc | 2026-04-10T07:33:38.213Z                 |
      | effective_end_dttm_utc   | not-a-date                               |
      | override_reason          | test-update                              |
    Then the expected status should be returned
    And I DELETE my registration history override

  Scenario: PUT returns 400 when mandatory body fields are missing
    Given I generate a random registration id and save it as OverrideRegistrationId
    When I POST a new registration history override specifying the following properties
      | registration_id          | OverrideRegistrationId     |
      | field_name               | portfolio_id                             |
      | field_value              | 69b78562-d1bc-46d7-90eb-d58d80f281e7     |
      | effective_start_dttm_utc | 2026-04-01T07:33:38.213Z                 |
      | effective_end_dttm_utc   | 2026-04-02T10:33:38.213Z                 |
      | override_reason          | test                                     |
    Then the response should include the new registration history override

      # missing field_name
    Given I expect the next API call to return a status code of 400 and details of "failed validation"
    When I update the current registration history override with new values
      | field_value              | 69b78562-d1bc-46d7-90eb-d58d80f281e7     |
      | effective_start_dttm_utc | 2026-04-10T07:33:38.213Z                 |
      | effective_end_dttm_utc   | 2026-04-10T08:33:38.213Z                 |
      | override_reason          | test-update                              |
    Then the expected status should be returned

    # missing field_value
    Given I expect the next API call to return a status code of 400 and details of "failed validation"
    When I update the current registration history override with new values
      | field_name               | status                                   |
      | effective_start_dttm_utc | 2026-04-10T07:33:38.213Z                 |
      | effective_end_dttm_utc   | 2026-04-10T08:33:38.213Z                 |
      | override_reason          | test-update                              |
    Then the expected status should be returned

    # missing effective_start_dttm_utc
    Given I expect the next API call to return a status code of 400 and details of "failed validation"
    When I update the current registration history override with new values
      | field_name               | status                                   |
      | field_value              | 69b78562-d1bc-46d7-90eb-d58d80f281e7     |
      | effective_end_dttm_utc   | 2026-04-10T08:33:38.213Z                 |
      | override_reason          | test-update                              |
    Then the expected status should be returned

    # missing effective_end_dttm_utc
    Given I expect the next API call to return a status code of 400 and details of "failed validation"
    When I update the current registration history override with new values
      | field_name               | status                                   |
      | field_value              | 69b78562-d1bc-46d7-90eb-d58d80f281e7     |
      | effective_start_dttm_utc | 2026-04-10T07:33:38.213Z                 |
      | override_reason          | test-update                              |
    Then the expected status should be returned

    # missing override_reason
    Given I expect the next API call to return a status code of 400 and details of "failed validation"
    When I update the current registration history override with new values
      | field_name               | status                                   |
      | field_value              | 69b78562-d1bc-46d7-90eb-d58d80f281e7     |
      | effective_start_dttm_utc | 2026-04-10T07:33:38.213Z                 |
      | effective_end_dttm_utc   |  test-update                              |
    Then the expected status should be returned
    And I DELETE my registration history override

  Scenario: PUT returns 400 when effective_start_dttm_utc equals effective_end_dttm_utc
    Given I generate a random registration id and save it as OverrideRegistrationId
    When I POST a new registration history override specifying the following properties
      | registration_id          | OverrideRegistrationId     |
      | field_name               | portfolio_id                             |
      | field_value              | 69b78562-d1bc-46d7-90eb-d58d80f281e7     |
      | effective_start_dttm_utc | 2026-04-01T07:33:38.213Z                 |
      | effective_end_dttm_utc   | 2026-04-02T10:33:38.213Z                 |
      | override_reason          | test                                     |
    Then the response should include the new registration history override

    Given I expect the next API call to return a status code of 400 and details of "start must be < end"
    When I update the current registration history override with new values
      | field_name               | status                                   |
      | field_value              | 69b78562-d1bc-46d7-90eb-d58d80f281e7     |
      | effective_start_dttm_utc | 2026-04-10T07:33:38.213Z                 |
      | effective_end_dttm_utc   | 2026-04-10T07:33:38.213Z                 |
      | override_reason          | test-update                              |
    Then the expected status should be returned
    And I DELETE my registration history override

  Scenario: PUT returns 401 and 403 for auth errors
    Given I generate a random registration id and save it as OverrideRegistrationId
    When I POST a new registration history override specifying the following properties
      | registration_id          | OverrideRegistrationId     |
      | field_name               | portfolio_id                             |
      | field_value              | 69b78562-d1bc-46d7-90eb-d58d80f281e7     |
      | effective_start_dttm_utc | 2026-04-01T07:33:38.213Z                 |
      | effective_end_dttm_utc   | 2026-04-02T10:33:38.213Z                 |
      | override_reason          | test                                     |
    Then the response should include the new registration history override
    And I DELETE my registration history override

      # 401
    Given I do not include the ENOC session header
    And I expect the next API call to return a status code of 401 and message of "Unauthorized"
    When I update the current registration history override with new values
      | field_name               | status                                   |
      | field_value              | 69b78562-d1bc-46d7-90eb-d58d80f281e7     |
      | effective_start_dttm_utc | 2026-04-10T07:33:38.213Z                 |
      | effective_end_dttm_utc   | 2026-04-10T08:33:38.213Z                 |
      | override_reason          | test-update-401                          |
    Then the expected status should be returned

    # 403
    Given I do not include the API key header
    And I expect the next API call to return a status code of 403 and message of "Forbidden"
    When I update the current registration history override with new values
      | field_name               | status                                   |
      | field_value              | 69b78562-d1bc-46d7-90eb-d58d80f281e7     |
      | effective_start_dttm_utc | 2026-04-10T07:33:38.213Z                 |
      | effective_end_dttm_utc   | 2026-04-10T08:33:38.213Z                 |
      | override_reason          | test-update-403                          |
    Then the expected status should be returned

  Scenario: PUT updates registration history override and returns updated data
    Given I generate a random registration id and save it as OverrideRegistrationId
    When I POST a new registration history override specifying the following properties
      | registration_id          | OverrideRegistrationId                 |
      | field_name               | portfolio_id                           |
      | field_value              | 69b78562-d1bc-46d7-90eb-d58d80f281e7   |
      | effective_start_dttm_utc | 2026-04-01T07:33:38.213Z               |
      | effective_end_dttm_utc   | 2026-04-02T10:33:38.213Z               |
      | override_reason          | initial                                |
    Then the response should include the new registration history override

  # Perform the update
    When I update the registration history override with new values
      | field_name               | status                                 |
      | field_value              | active                                 |
      | effective_start_dttm_utc | 2026-04-10T07:33:38.213Z               |
      | effective_end_dttm_utc   | 2026-04-10T08:33:38.213Z               |
      | override_reason          | updated                                |
    Then the response should include the updated registration history override
    And the updated registration history override response should reflect the new values
    And I DELETE my registration history override

  #
  # GET all /registration_history_overrides validations
  #
  Scenario: GET all registration history overrides returns 401 when ENOC session header is missing
    Given I generate a random registration id and save it as OverrideRegistrationId
    When I POST a new registration history override specifying the following properties
      | registration_id          | OverrideRegistrationId                 |
      | field_name               | portfolio_id                           |
      | field_value              | 69b78562-d1bc-46d7-90eb-d58d80f281e7   |
      | effective_start_dttm_utc | 2026-04-01T07:33:38.213Z               |
      | effective_end_dttm_utc   | 2026-04-02T10:33:38.213Z               |
      | override_reason          | test                                   |
    Then the registration history overrides list should contain my override

    Given I expect the next API call to return a status code of 404 and message of "Not Found"
    When I GET all registration history overrides for registration_id "00000000-0000-0000-0000-000000000000"
    Then the expected status should be returned

    Given I expect the next API call to return a status code of 400 and details of "failed validation"
    When I GET all registration history overrides for registration_id "not-a-uuid"
    Then the expected status should be returned
    And I DELETE my registration history override

    Given I do not include the ENOC session header
    And I expect the next API call to return a status code of 401 and message of "Unauthorized"
    When I GET all registration history overrides for the current registration
    Then the expected status should be returned

    Given I do not include the API key header
    And I expect the next API call to return a status code of 403 and message of "Forbidden"
    When I GET all registration history overrides for the current registration
    Then the expected status should be returned


  Scenario: GET all registration history overrides
    Given I generate a random registration id and save it as OverrideRegistrationId
    When I POST a new registration history override specifying the following properties
      | registration_id          | OverrideRegistrationId                 |
      | field_name               | portfolio_id                           |
      | field_value              | 69b78562-d1bc-46d7-90eb-d58d80f281e7   |
      | effective_start_dttm_utc | 2026-04-01T07:33:38.213Z               |
      | effective_end_dttm_utc   | 2026-04-02T10:33:38.213Z               |
      | override_reason          | test                                   |
    Then the registration history overrides list should contain my override
    And I DELETE my registration history override

  Scenario: GET all registration history overrides works with params - include_deleted=true and registration_id
    Given I generate a random registration id and save it as OverrideRegistrationId
    When I POST a new registration history override specifying the following properties
      | registration_id          | OverrideRegistrationId                 |
      | field_name               | portfolio_id                           |
      | field_value              | 69b78562-d1bc-46d7-90eb-d58d80f281e7   |
      | effective_start_dttm_utc | 2026-04-01T07:33:38.213Z               |
      | effective_end_dttm_utc   | 2026-04-02T10:33:38.213Z               |
      | override_reason          | test                                   |
    And I DELETE my registration history override
    Then I GET all registration history overrides with include_deleted flag
    Then I GET all registration history overrides for the current registration_id including deleted
    And the registration history overrides list should contain valid populated items

  #
  # GET one /registration_history_overrides/{id}
  #
  Scenario: GET registration history override by id returns 401 when ENOC session header is missing
    Given I generate a random registration id and save it as OverrideRegistrationId
    When I POST a new registration history override specifying the following properties
      | registration_id          | OverrideRegistrationId                 |
      | field_name               | portfolio_id                           |
      | field_value              | 69b78562-d1bc-46d7-90eb-d58d80f281e7   |
      | effective_start_dttm_utc | 2026-04-01T07:33:38.213Z               |
      | effective_end_dttm_utc   | 2026-04-02T10:33:38.213Z               |
      | override_reason          | test                                   |
    Then the response should include the new registration history override
    And I DELETE my registration history override

    Given I do not include the ENOC session header
    And I expect the next API call to return a status code of 401 and message of "Unauthorized"
    When I GET the registration history override by id
    Then the expected status should be returned

  Scenario: GET registration history override by id returns 403 when API key header is missing
    Given I generate a random registration id and save it as OverrideRegistrationId
    When I POST a new registration history override specifying the following properties
      | registration_id          | OverrideRegistrationId                 |
      | field_name               | portfolio_id                           |
      | field_value              | 69b78562-d1bc-46d7-90eb-d58d80f281e7   |
      | effective_start_dttm_utc | 2026-04-01T07:33:38.213Z               |
      | effective_end_dttm_utc   | 2026-04-02T10:33:38.213Z               |
      | override_reason          | test                                   |
    Then the response should include the new registration history override
    And I DELETE my registration history override

    Given I do not include the API key header
    And I expect the next API call to return a status code of 403 and message of "Forbidden"
    When I GET the registration history override by id
    Then the expected status should be returned

  Scenario: GET registration history override by id returns 404 when id does not exist
    Given I expect the next API call to return a status code of 404 and details of "not found"
    When I GET the registration history override with id "99999999" including deleted
    Then the expected status should be returned

  Scenario: GET registration history override by id returns 400 when id format is invalid
    Given I expect the next API call to return a status code of 400 and details of "failed validation"
    When I GET the registration history override with id "not-an-id" including deleted
    Then the expected status should be returned

  Scenario: GET registration history override by id adding include_deleted=true
    Given I generate a random registration id and save it as OverrideRegistrationId
    When I POST a new registration history override specifying the following properties
      | registration_id          | OverrideRegistrationId                 |
      | field_name               | portfolio_id                           |
      | field_value              | 69b78562-d1bc-46d7-90eb-d58d80f281e7   |
      | effective_start_dttm_utc | 2026-04-01T07:33:38.213Z               |
      | effective_end_dttm_utc   | 2026-04-02T10:33:38.213Z               |
      | override_reason          | test                                   |
    Then the response should include the new registration history override
    And I DELETE my registration history override

    When I GET the registration history override by id including deleted
    Then the registration history override response should be marked as deleted

  #
  # DELETE /registration_history_overrides/{id}
  #
  Scenario: DELETE returns 404 when registration history override does not exist
    Given I expect the next API call to return a status code of 404 and details of "not found"
    When I DELETE registration history override with id "99999999"
    Then the expected status should be returned

  Scenario: DELETE returns 204 when registration history override exists
    Given I generate a random registration id and save it as OverrideRegistrationId
    When I POST a new registration history override specifying the following properties
      | registration_id          | OverrideRegistrationId                 |
      | field_name               | portfolio_id                           |
      | field_value              | 69b78562-d1bc-46d7-90eb-d58d80f281e7   |
      | effective_start_dttm_utc | 2026-04-01T07:33:38.213Z               |
      | effective_end_dttm_utc   | 2026-04-02T10:33:38.213Z               |
      | override_reason          | test                                   |
    Then the response should include the new registration history override

    When I DELETE my registration history override
    Then the delete should succeed

  Scenario: DELETE returns 401 and 403 for auth errors
    Given I generate a random registration id and save it as OverrideRegistrationId
    When I POST a new registration history override specifying the following properties
      | registration_id          | OverrideRegistrationId                 |
      | field_name               | portfolio_id                           |
      | field_value              | 69b78562-d1bc-46d7-90eb-d58d80f281e7   |
      | effective_start_dttm_utc | 2026-04-01T07:33:38.213Z               |
      | effective_end_dttm_utc   | 2026-04-02T10:33:38.213Z               |
      | override_reason          | test                                   |
    Then the response should include the new registration history override
    When I DELETE my registration history override

    # 401
    Given I do not include the ENOC session header
    And I expect the next API call to return a status code of 401 and message of "Unauthorized"
    When I DELETE my registration history override
    Then the expected status should be returned

    # 403
    Given I do not include the API key header
    And I expect the next API call to return a status code of 403 and message of "Forbidden"
    When I DELETE my registration history override
    Then the expected status should be returned

    # check that registration_id=4f961f28-2e83-4817-8e1e-0857099fe8e1 exists for the env
    # at registration table and registration_history tables for the following test scenario to work
    # RegistrationHistoryOverrides.sql can be use to insert this registration_id
    Scenario: Registration history reconciliation marks rows with overrides
    When I POST a new registration history override specifying the following properties
      | registration_id          | 4f961f28-2e83-4817-8e1e-0857099fe8e1               |
      | field_name               | status                               |
      | field_value              | 69b78562-d1bc-46d7-90eb-d58d80f281e7 |
      | effective_start_dttm_utc | 2026-04-15T07:33:38.213Z             |
      | effective_end_dttm_utc   | 2026-04-20T10:33:38.213Z             |
      | override_reason          | override-true-check                                 |
    Then the response should include the new registration history override

    Then the registration history reconciliation table should contain overridden rows for registration_id "4f961f28-2e83-4817-8e1e-0857099fe8e1"

      When I call GET registration_history as follows:
        | id                  | 4f961f28-2e83-4817-8e1e-0857099fe8e1               |
        | id_type             | registration         |
        | use_raw_history    | false                        |
      Then the registration history response should contain 3 rows

      When I call GET registration_history as follows:
        | id                  | 4f961f28-2e83-4817-8e1e-0857099fe8e1               |
        | id_type             | registration         |
        | use_raw_history    | true                        |
      Then the registration history response should contain 1 rows

    And I DELETE my registration history override