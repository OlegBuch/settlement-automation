Feature: Additional feature tests for PUT /registrations

  References:

  <CONFLUENCE_URL>/display/XP/Settlement+Data+Service+-+Data+Model
  ITAPPSIT-3882: add registration_set_id to SMD API registration and reg hist
  BDAP-1709 Create API - Participation: /registrations endpoints
  BDAP-1708: Create data model, tables, migrations - Participation

  Prerequsities: The scenario 'Create ITS mappings' in Registration.feature


  Background:
    Given I start with an empty context
    * I log in as a settlement API admin
    * I set the expected org_id to SmdQaOrg1


  Scenario:  PUT: if product_id or ecrm_opportunity_id is passed as null, set needs_manual_fix = true

    * -> POST a new registration
    Given I delete all existing table rows for the registration registration1
    When I POST a new registration specifying the following properties:
      | status                    | INACTIVE |
      | registration_id                        | <registration1>  |
      | product_id                | <uuid>                  |
      | service_delivery_point_id         | <registration1-sdp>                  |
      | ecrm_opportunity_id       | abc                  |
      |last_updated_by            | <username>                  |
    Then the response should include the new registration
    And needs_manual_fix should be false
    And GET registration should return the current state of the registration
    And the registration history should reflect the new operation

    * -> PUT null ecrm_opportunity_id. Result: ecrm_opportunity_id = null, needs_manual_fix = true
    When I update the registration with new values:
      | ecrm_opportunity_id              | <null>                  |
    Then the response should include the updated registration
    And needs_manual_fix should be true
    And GET registration should return the current state of the registration
    And the registration history should reflect the update operation

    * -> PUT valid ecrm_opportunity_id. Result: ecrm_opportunity_id set, needs_manual_fix = false
    When I update the registration with new values:
      | ecrm_opportunity_id              | foo                  |
    Then the response should include the updated registration
    And needs_manual_fix should be false
    And GET registration should return the current state of the registration
    And the registration history should reflect the update operation

    * -> PUT null product_id. Result: product_id = null, needs_manual_fix = true
    When I update the registration with new values:
      | product_id              | <null>                  |
    Then the response should include the updated registration
    And needs_manual_fix should be true
    And GET registration should return the current state of the registration
    And the registration history should reflect the update operation

    * -> PUT valid product_id. Result: product_id set, needs_manual_fix = false
    When I update the registration with new values:
      | product_id              | <uuid>                  |
    Then the response should include the updated registration
    And needs_manual_fix should be false
    And GET registration should return the current state of the registration
    And the registration history should reflect the update operation


  Scenario: Change null fields to non-null and vice-versa

    * -> POST payload only includes mandatory fields
    Given I delete all existing table rows for the registration registration1
    When I POST a new registration specifying the following properties:
      | registration_id | <registration1> |
      | status          | ON_HOLD         |
      | service_delivery_point_id    | <registration1-sdp> |
      | last_updated_by | <username>          |
    Then the response should include the new registration
    And GET registration should return the current state of the registration
    And the registration history should reflect the new operation

    * -> PUT: change null fields to non-null
    When I update the registration with new values:
      | flexible_asset_id    | <uuid> |
      | ecrm_opportunity_id       | abc                  |
    Then the response should include the updated registration
    * GET registration should return the current state of the registration
    * the registration history should reflect the update operation

    * -> PUT: change non-null field to null
    When I update the registration with new values:
      | ecrm_opportunity_id       | <null>                  |
    Then the response should include the updated registration
    * GET registration should return the current state of the registration
    * the registration history should reflect the update operation


  Scenario: PUT: fields specified in payload with unchanged values does not trigger history row

    Given I delete all existing table rows for the registration registration1

    * -> POST a new registration for QAA_IDS_REGIS_REG_ONE_SRC with all properties
    When I POST a new registration specifying the following properties:
      | status                    | INACTIVE |
      | registration_id                        | <registration1>  |
      | product_id                | <uuid>                  |
      | service_delivery_point_id         | <registration1-sdp>                  |
      | ecrm_opportunity_id       | abc                  |
      |last_updated_by            | <username>                  |
    Then the response should include the new registration
    * GET registration should return the current state of the registration
    * the registration history should reflect the new operation

    * -> PUT: fields specified in payload with unchanged values does not trigger history row
    * -> Note: by design, a change ONLY to last_updated_by causes the stored reg to be updated,
    * -> but no history row is created (since none of the fields we care about were updated).
    When I update the registration with new values:
      | status                    | INACTIVE |
      | ecrm_opportunity_id       | abc                  |
      |last_updated_by            | <username>                  |
    Then the response should include the updated registration
    * GET registration should return the current state of the registration
    * the registration history should not be updated


  Scenario: PUT error cases

    * -> PUT on a non-existent registration_id returns 404 Not Found
    * -> In order to accomodate the changes I made for ITAPPSIT-3399, I need to create a registration to get it into the context, then hard-delete it from the db
    Given I delete all existing table rows for the registration registration1
    When I POST a new registration specifying the following properties:
      | status                    | INACTIVE |
      | registration_id                        | <registration1>  |
      | product_id                | <uuid>                  |
      | service_delivery_point_id         | <registration1-sdp>                  |
      | ecrm_opportunity_id       | abc                  |
      |last_updated_by            | <username>                  |
    Then the response should include the new registration
    Given I delete all existing table rows for the registration registration1
    Given I expect the next API call to return a status code of 404 and details of "Registration not found"
    When I update the registration with new values:
      | status                    | INACTIVE |
      | ecrm_opportunity_id       | abc                  |
    Then the expected status should be returned

    * -> POST a new registration
    When I POST a new registration specifying the following properties:
      | status                    | INACTIVE |
      | registration_id                        | <registration1>  |
      | product_id                | <uuid>                  |
      | service_delivery_point_id         | <registration1-sdp>                  |
      | ecrm_opportunity_id       | abc                  |
      |last_updated_by            | <username>                  |
    Then the response should include the new registration
    And the registration history should reflect the new operation

    * -> PUT returns 400 for invalid status enum
    Given I expect the next API call to return a status code of 400 and details of "Invalid status"
    When I update the registration with new values:
      | status          | FOO    |
    Then the expected status should be returned

    * -> PUT returns 400 for missing mandatory field
    Given I expect the next API call to return a status code of 400 and details of "\"last_updated_by\" is not allowed to be empty"
    When I update the registration with new values:
      | status                    | ACTIVE |
      |last_updated_by            | <empty-string>                  |
    Then the expected status should be returned
    Given I expect the next API call to return a status code of 400 and details of "The request failed validation"
    When I update the registration with new values:
      | status                    | ACTIVE |
      |last_updated_by            | <null>                  |
    Then the expected status should be returned

    * -> PUT returns 400 if ECRM id > 18 characters
    Given I expect the next API call to return a status code of 400 and details of "The request failed validation"
    When I update the registration with new values:
      | ecrm_opportunity_id | a1234567890123456789 |
      | last_updated_by     | <username>               |
    Then the expected status should be returned

    And the registration history should not be updated


  Scenario: PUT: missing optional fields in payload should be set to null in db (ITAPPSIT-3399)

    Given I delete all existing table rows for the registration registration1

    * -> POST a new registration for QAA_IDS_REGIS_REG_ONE_SRC with all properties
    When I POST a new registration specifying the following properties:
      | status                    | INACTIVE |
      | registration_id                        | <registration1>  |
      | product_id                | <uuid>                  |
      | service_delivery_point_id         | <registration1-sdp>                  |
      | flexible_asset_id         | <uuid>                  |
      | ecrm_opportunity_id       | abc                  |
      | portfolio_id       | <uuid>                  |
      | registration_set_id       | <uuid>                  |
      |last_updated_by            | <username>                  |
    Then the response should include the new registration
    * GET registration should return the current state of the registration
    * the registration history should reflect the new operation

    * -> PUT: specify a partial payload. Missing optional properties should be set to null in db table.
    Given I set sendFullPutPayload to false
    When I update the registration with new values:
      | service_delivery_point_id         | <registration3-sdp>                  |
      |last_updated_by            | <username>                  |
    Then the response should include the updated registration
    * needs_manual_fix should be true
    * GET registration should return the current state of the registration
    * the registration history should reflect the update operation