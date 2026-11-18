Feature: Feature tests for registrations

  References:

  <CONFLUENCE_URL>/display/XP/Settlement+Data+Service+-+Data+Model
  ITAPPSIT-3882: add registration_set_id to SMD API registration and reg hist
  ITAPPSIT-3778: [BUG] ITAPPSIT-3740: GET /registrations un-deletes a deleted registration
  ITAPPSIT-3744: Add tests for ITAPPSIT-3740 story
  BDAP-1709 Create API - Participation: /registrations endpoints
  BDAP-1708: Create data model, tables, migrations - Participation

  Background:
    Given I start with an empty context
    * I log in as a settlement API admin
    * I set the expected org_id to SmdQaOrg1


  Scenario: Create ITS mappings

    # Create mapping for orgs for dev and preprd
    Given I POST the official ITS mapping for SmdQaOrg1
    Given I POST the official ITS mapping for SmdQaOrgPoland

    # Create mappings for sites.
    Given I POST the official ITS mapping for SmdQaSite1
    Given I POST the official ITS mapping for SmdQaSite2
    Given I POST the official ITS mapping for SmdQaKrakow
    Given I POST the official ITS mapping for SmdQaLodz


  Scenario: Simple registration life cycle

    Given I set the expected org_id to SmdQaOrgPoland

    # Org is QAA_IDS_REGIS
    Given I delete all existing table rows for the registration registration5

    * -> POST a new registration for Krakow using the flexible asset id
    When I POST a new registration specifying the following properties:
      | status                    | INACTIVE |
      | registration_id                        | <registration5>  |
      | product_id                | <uuid>                  |
      | flexible_asset_id         | <registration5-fa>                  |
      | ecrm_opportunity_id       | abc                  |
      | last_updated_by            | <username>                 |
      | portfolio_id              | <uuid>                     |
      | registration_set_id                          |  <uuid>                          |
    Then the response should include the new registration
    And needs_manual_fix should be false
    And GET registration should return the current state of the registration
    And the registration history should reflect the new operation

    * -> PUT: update all allowed properties. Site should now be Lodz.
    When I update the registration with new values:
      | status                    | READY_TO_ENROLL |
      | product_id                | <uuid>                  |
      | flexible_asset_id         | <uuid>                  |
      | service_delivery_point_id | <registration6-sdp>                  |
      | ecrm_opportunity_id       | def                  |
      |last_updated_by            | <username>                  |
      | portfolio_id              | <uuid>                     |
      | registration_set_id                          |  <uuid>                          |
    Then the response should include the updated registration
    * needs_manual_fix should be false
    * GET registration should return the current state of the registration
    * the registration history should reflect the update operation

    * -> PUT the same fields again to generate a third history row.  Site should now be Krakow.
    When I update the registration with new values:
      | status                    | ACTIVE |
      | product_id                | <uuid>                  |
      | flexible_asset_id         | <registration5-fa>                  |
      | service_delivery_point_id | <uuid>                  |
      | ecrm_opportunity_id       | xyz                  |
      |last_updated_by            | <username>                  |
      | portfolio_id              | <uuid>                     |
      | registration_set_id                          |  <uuid>                          |
    Then the response should include the updated registration
    * needs_manual_fix should be false
    * GET registration should return the current state of the registration
    * the registration history should reflect the update operation

    * -> DELETE the registration
    When I DELETE my registration
    Then the registration history should reflect the delete operation

    * -> Verify that GET, PUT, and DELETE endpoints return 404 for a deleted registration
    Given I expect the next API call to return a status code of 404 and details of "Registration not found"
    Then GET registration should return the expected status

    Given I expect the next API call to return a status code of 404 and details of "Registration not found"
    When I update the registration with new values:
      | status                    | ON_HOLD |
      | product_id                | <uuid>                  |
      | flexible_asset_id         | <uuid>                  |
      | service_delivery_point_id | <uuid>                  |
      | ecrm_opportunity_id       | ghi                  |
      |last_updated_by            | <username>                  |
    Then the expected status should be returned
    And the registration history should not be updated

    Given I expect the next API call to return a status code of 404 and details of "Registration not found"
    Then DELETE registration should return the expected status

    * -> Un-delete the registration by calling POST
    Given I clear the saved registration context
    When I POST a new registration specifying the following properties:
      | status                    | READY_TO_ACCEPTANCE_TEST |
      | registration_id                        | <registration5>  |
      | product_id                | <uuid>                  |
      | flexible_asset_id         | <registration5-fa>                  |
      | service_delivery_point_id | <uuid>                  |
      | ecrm_opportunity_id       | foobar                  |
      |last_updated_by            | <username>                  |
    Then the response should include the new registration
    * needs_manual_fix should be false
    * the registration history should reflect the recreate operation

    * -> Verify that GET, PUT, and DELETE work on the re-created registration
    And GET registration should return the current state of the registration

    When I update the registration with new values:
      | status                    | ON_HOLD |
      | product_id                | <uuid>                  |
      | flexible_asset_id         | <registration5-fa>                  |
      | service_delivery_point_id | <uuid>                  |
      | ecrm_opportunity_id       | another                  |
      | portfolio_id              | <uuid>                     |
      | registration_set_id                          |  <uuid>                          |
      |last_updated_by            | <username>                  |
    Then the response should include the updated registration
    * needs_manual_fix should be false
    * GET registration should return the current state of the registration
    * the registration history should reflect the update operation

    When I DELETE my registration
    Then the registration history should reflect the delete operation
    And the registration history response should contain 7 rows

    Given I expect the next API call to return a status code of 404 and details of "Registration not found"
    Then GET registration should return the expected status


  Scenario: ITS mapping errors

    Given I delete all existing table rows for the registration registration1

    * -> ITAPPSIT-3566: ITS site mapping is too long for type character varying(18)
    Given I DELETE our ITS mapping for SmdQaSite1
    Given I POST the official ITS mapping for SmdQaSite1InvalidEcrmId
    When I POST a new registration specifying the following properties:
      | status                    | INACTIVE |
      | registration_id                        | <registration1>  |
      | product_id                | <uuid>                  |
      | flexible_asset_id         | <registration1-fa>                  |
      | ecrm_opportunity_id       | abc                  |
      |last_updated_by            | <username>                  |
    Then the response should include the new registration
    And needs_manual_fix should be true
    And GET registration should return the current state of the registration
    And the registration history should reflect the new operation

    Given I delete all existing table rows for the registration registration1

    * -> Site mapping does not exist. Result: site_id set, ecrm_site_id = null, needs_manual_fix = true
    Given I DELETE our ITS mapping for SmdQaSite1InvalidEcrmId
    When I POST a new registration specifying the following properties:
      | status                    | INACTIVE |
      | registration_id                        | <registration1>  |
      | product_id                | <uuid>                  |
      | flexible_asset_id         | <registration1-fa>                  |
      | ecrm_opportunity_id       | abc                  |
      |last_updated_by            | <username>                  |
    Then the response should include the new registration
    And needs_manual_fix should be true
    And GET registration should return the current state of the registration
    And the registration history should reflect the new operation

    * -> Manually delete the registration
    Given I delete all existing table rows for the registration registration1
    And I clear the saved registration context

    * -> Org mapping does not exist. Result: org_id set, ecrm_account_id = null, site_id set, ecrm_site_id set, needs_manual_fix = true
    Given I DELETE our ITS mapping for SmdQaOrg1
    And I POST the official ITS mapping for SmdQaSite1
    When I POST a new registration specifying the following properties:
      | status                    | READY_TO_ENROLL |
      | registration_id                        | <registration1>  |
      | product_id                | <uuid>                  |
      | flexible_asset_id         | <registration1-fa>                  |
      | ecrm_opportunity_id       | def                  |
      |last_updated_by            | <username>                  |
    Then the response should include the new registration
    And needs_manual_fix should be true
    And GET registration should return the current state of the registration
    And the registration history should reflect the new operation

    * -> DELETE the registration
    Given I delete all existing table rows for the registration registration1
    And I clear the saved registration context

    * -> * -> ITAPPSIT-3566: ITS site mapping is too long for type character varying(18)
    Given I POST the official ITS mapping for SmdQaOrg1InvalidEcrmId
    When I POST a new registration specifying the following properties:
      | status                    | INACTIVE |
      | registration_id                        | <registration1>  |
      | product_id                | <uuid>                  |
      | flexible_asset_id         | <registration1-fa>                  |
      | ecrm_opportunity_id       | abc                  |
      |last_updated_by            | <username>                  |
    Then the response should include the new registration
    And needs_manual_fix should be true
    And GET registration should return the current state of the registration
    And the registration history should reflect the new operation

    * -> Cleanup
    Given I DELETE our ITS mapping for SmdQaOrg1InvalidEcrmId
    Given I POST the official ITS mapping for SmdQaOrg1

    * -> Re-create the registration. All fields should be set and needs_manual_fix = false
    Given I delete all existing table rows for the registration registration1
    And I clear the saved registration context
    When I POST a new registration specifying the following properties:
      | status                    | ACTIVE |
      | registration_id                        | <registration1>  |
      | product_id                | <uuid>                  |
      | flexible_asset_id         | <registration1-fa>                  |
      | ecrm_opportunity_id       | def                  |
      |last_updated_by            | <username>                  |
    Then the response should include the new registration
    And needs_manual_fix should be false
    And GET registration should return the current state of the registration
    And the registration history should reflect the new operation


    Scenario:  POST: if product_id or ecrm_opportunity_id is passed as null, set needs_manual_fix = true

      * -> POST null product_id. Result: product_id = null, needs_manual_fix = true
      Given I delete all existing table rows for the registration registration1
      When I POST a new registration specifying the following properties:
        | status                    | INACTIVE |
        | registration_id                        | <registration1>  |
        | product_id                | <null>                  |
        | service_delivery_point_id         | <registration1-sdp>                  |
        | ecrm_opportunity_id       | abc                  |
        |last_updated_by            | <username>                  |
      Then the response should include the new registration
      And needs_manual_fix should be true
      And GET registration should return the current state of the registration
      And the registration history should reflect the new operation

      * -> POST null ecrm_opportunity_id. Result: ecrm_opportunity_id = null, needs_manual_fix = true
      Given I delete all existing table rows for the registration registration1
      When I POST a new registration specifying the following properties:
        | status                    | INACTIVE |
        | registration_id         | <registration1>  |
        | product_id                | <uuid>                  |
        | flexible_asset_id         | <uuid>                  |
        | service_delivery_point_id         | <registration1-sdp> |
        | ecrm_opportunity_id       | <null>                  |
        |last_updated_by            | <username>                  |
      Then the response should include the new registration
      And needs_manual_fix should be true
      And GET registration should return the current state of the registration
      And the registration history should reflect the new operation


  Scenario:  POST: if product_id or ecrm_opportunity_id is missing, set needs_manual_fix = true

    * -> POST product_id missing. Result: product_id = null, needs_manual_fix = true
    Given I delete all existing table rows for the registration registration1
    When I POST a new registration specifying the following properties:
      | status                    | INACTIVE |
      | registration_id                        | <registration1>  |
      | flexible_asset_id         | <uuid>                  |
      | service_delivery_point_id         | <registration1-sdp> |
      | ecrm_opportunity_id       | abc                  |
      |last_updated_by            | <username>                  |
    Then the response should include the new registration
    And needs_manual_fix should be true
    And GET registration should return the current state of the registration
    And the registration history should reflect the new operation

    * -> POST ecrm_opportunity_id missing. Result: ecrm_opportunity_id = null, needs_manual_fix = true
    Given I delete all existing table rows for the registration registration1
    When I POST a new registration specifying the following properties:
      | status                    | INACTIVE |
      | registration_id         | <registration1>  |
      | product_id                | <uuid>                  |
      | flexible_asset_id         | <uuid>                  |
      | service_delivery_point_id         | <registration1-sdp> |
      |last_updated_by            | <username>                  |
    Then the response should include the new registration
    And needs_manual_fix should be true
    And GET registration should return the current state of the registration
    And the registration history should reflect the new operation


  Scenario: POST edge cases and errors

    Given I delete all existing table rows for the registration registration1

    * -> ITAPPSIT-3399: POST returns 400 if site_id is included in payload
    Given I expect the next API call to return a status code of 400 and details of '"site_id" is not allowed'
    When I POST a new registration specifying the following properties:
      | status              | INACTIVE             |
      | registration_id     | <registration1> |
      | product_id          | <uuid>          |
      | flexible_asset_id   | <uuid>          |
      | site_id             | <uuid>          |
      | ecrm_opportunity_id | abc             |
      | last_updated_by     | <username>          |
    Then the expected status should be returned

    * -> POST returns 400 for missing mandatory fields
    Given I expect the next API call to return a status code of 400 and details of "The request failed validation"
    When I POST a new registration specifying the following properties:
      | last_updated_by | <username> |
    Then the expected status should be returned

    Given I expect the next API call to return a status code of 400 and details of "The request failed validation"
    When I POST a new registration specifying the following properties:
      | registration_id | <registration1> |
    Then the expected status should be returned

    Given I expect the next API call to return a status code of 400 and details of "The request failed validation"
    When I POST a new registration specifying the following properties:
      | registration_id | <empty-string> |
      | last_updated_by | <username>         |
    Then the expected status should be returned

    Given I expect the next API call to return a status code of 400 and details of "\"last_updated_by\" is not allowed to be empty"
    When I POST a new registration specifying the following properties:
      | registration_id | <registration1> |
      | last_updated_by | <empty-string>  |
    Then the expected status should be returned

    Given I expect the next API call to return a status code of 400 and details of "The request failed validation"
    When I POST a new registration specifying the following properties:
      | registration_id | <null> |
      | last_updated_by | <username> |
    Then the expected status should be returned

    Given I expect the next API call to return a status code of 400 and details of "The request failed validation"
    When I POST a new registration specifying the following properties:
      | registration_id | <registration1> |
      | last_updated_by | <null>          |
    Then the expected status should be returned

    * -> POST returns 400 for invalid field type
    Given I expect the next API call to return a status code of 400 and details of "The request failed validation"
    When I POST a new registration specifying the following properties:
      | registration_id | <registration1> |
      | service_delivery_point_id        | <random-int>    |
      | last_updated_by | <username>          |
    Then the expected status should be returned

    * -> POST returns 400 for unsupported field
    Given I expect the next API call to return a status code of 400 and details of "\"foo\" is not allowed"
    When I POST a new registration specifying the following properties:
      | registration_id | <registration1> |
      | foo             | abc             |
      | last_updated_by | <username>          |
    Then the expected status should be returned

    * -> POST returns 400 for null optional field
    Given I expect the next API call to return a status code of 400 and details of "The request failed validation"
    When I POST a new registration specifying the following properties:
      | registration_id | <registration1> |
      | last_updated_by | <username>          |
      | status          | <null>          |
    Then the expected status should be returned

    * -> POST returns 400 if ECRM id > 18 characters
    Given I expect the next API call to return a status code of 400 and details of "The request failed validation"
    When I POST a new registration specifying the following properties:
      | registration_id     | <registration1>      |
      | ecrm_opportunity_id | a1234567890123456789 |
      | last_updated_by     | <username>               |
    Then the expected status should be returned

    * -> POST returns 500 if registration is not found in Atlas
    Given I expect the next API call to return a status code of 500 and details of "Error while retrieving OrgId derived fields to registration data"
    When I POST a new registration specifying the following properties:
      | status              | INACTIVE                                 |
      | registration_id     | <uuid> |
      | product_id          | <uuid>                               |
      | flexible_asset_id   | <uuid>                               |
      | ecrm_opportunity_id | abc                                  |
      | last_updated_by     | <username>                               |
    Then the expected status should be returned

    * -> POST returns 400 for invalid status enum
    Given I expect the next API call to return a status code of 400 and details of "Invalid status"
    When I POST a new registration specifying the following properties:
      | status              | FOO             |
      | registration_id     | <registration1> |
      | product_id          | <uuid>          |
      | flexible_asset_id   | <uuid>          |
      | ecrm_opportunity_id | abc             |
      | last_updated_by     | <username>          |
    Then the expected status should be returned

    Given I delete all existing table rows for the registration registration1

    * -> POST a new registration
    When I POST a new registration specifying the following properties:
      | status              | INACTIVE                             |
      | registration_id     | <registration1>                      |
      | product_id          | <uuid>                               |
      | flexible_asset_id   | <uuid>                               |
      | service_delivery_point_id         | <registration1-sdp>    |
      | ecrm_opportunity_id | abc                                  |
      | last_updated_by     | <username>                               |
    Then the response should include the new registration
    And the registration history should reflect the new operation

    * -> POST returns 409 Conflict if registration already exists
    Given I expect the next API call to return a status code of 409 and details of "Registration already exists"
    When I POST a new registration specifying the following properties:
      | status              | ON_HOLD                                 |
      | registration_id     | <registration1>                      |
      | product_id          | <uuid>                               |
      | flexible_asset_id   | <uuid>                               |
      | service_delivery_point_id         | <registration1-sdp>    |
      | ecrm_opportunity_id | abc                                  |
      | last_updated_by     | <username>                               |
    Then the expected status should be returned
    And the registration history should not be updated


  Scenario: GET error cases

    * -> GET without registration_id returns 404 Not Found
    Given I set the context registration id to "not specified"
    Given I expect the next API call to return a status code of 404 and message of "Not Found"
    Then GET registration should return the expected status

    * -> GET on a non-existent registration_id returns 404 Not Found
    Given I set the context registration id to "random uuid"
    Given I expect the next API call to return a status code of 404 and details of "Registration not found"
    Then GET registration should return the expected status

    * -> GET on a non-uuid returns 400 Bad Request
    Given I set the context registration id to "non-uuid"
    Given I expect the next API call to return a status code of 400 and details of "The request failed validation"
    Then GET registration should return the expected status


  Scenario: DELETE error cases

    * -> DELETE on a non-existent registration_id returns 404 Not Found
    Given I expect the next API call to return a status code of 404 and details of "Registration not found"
    When expecting an error, I DELETE the registration with id aaaaaaaa-bbbb-cccc-dddd-82af9de76630
    Then the expected status should be returned


  Scenario: Portfolio ID validation

    * -> Verify that uuid format is enforced

    Given I delete all existing table rows for the registration registration1

    * -> POST returns 400 for invalid portfolio_id (not a UUID)
    Given I expect the next API call to return a status code of 400 and details of "The request failed validation"
    When I POST a new registration specifying the following properties:
      | status                    | INACTIVE            |
      | registration_id           | <registration1>     |
      | product_id                | <uuid>              |
      | flexible_asset_id         | <registration1-fa>  |
      | ecrm_opportunity_id       | abc                 |
      | last_updated_by           | <username>          |
      | portfolio_id              | foo     |
    Then the expected status should be returned

    * -> POST returns 400 for empty string portfolio_id
    Given I expect the next API call to return a status code of 400 and details of "The request failed validation"
    When I POST a new registration specifying the following properties:
      | status                    | INACTIVE            |
      | registration_id           | <registration1>     |
      | product_id                | <uuid>              |
      | flexible_asset_id         | <registration1-fa>  |
      | ecrm_opportunity_id       | abc                 |
      | last_updated_by           | <username>          |
      | portfolio_id        | <empty-string>      |
    Then the expected status should be returned

    * -> POST a new registration with a valid portfolio_id
    When I POST a new registration specifying the following properties:
      | status                    | INACTIVE            |
      | registration_id           | <registration1>     |
      | product_id                | <uuid>              |
      | flexible_asset_id         | <registration1-fa>  |
      | ecrm_opportunity_id       | abc                 |
      | last_updated_by           | <username>          |
      | portfolio_id              | <uuid>              |
    Then the response should include the new registration
    And GET registration should return the current state of the registration
    * the registration history should reflect the new operation

    * -> PUT returns 400 for invalid portfolio_id (not a UUID)
    Given I expect the next API call to return a status code of 400 and details of "The request failed validation"
    When I update the registration with new values:
      | portfolio_id              | foo              |
    Then the expected status should be returned

    * -> PUT: update the portfolio_id with a valid uuid
    When I update the registration with new values:
      | portfolio_id              | <uuid>              |
    Then the response should include the updated registration
    And GET registration should return the current state of the registration
    * the registration history should reflect the update operation

    * -> Verify that a missing portfolio_id can be replaced with a valid id

    Given I delete all existing table rows for the registration registration1

    * -> POST a new registration without specifying portfolio_id
    When I POST a new registration specifying the following properties:
      | status                    | INACTIVE            |
      | registration_id           | <registration1>     |
      | product_id                | <uuid>              |
      | flexible_asset_id         | <registration1-fa>  |
      | ecrm_opportunity_id       | abc                 |
      | last_updated_by           | <username>          |
    Then the response should include the new registration
    And GET registration should return the current state of the registration
    * the registration history should reflect the new operation

    * -> Now update with a valid portfolio_id
    When I update the registration with new values:
      | portfolio_id              | <uuid>              |
    Then the response should include the updated registration
    And GET registration should return the current state of the registration
    * the registration history should reflect the update operation


  Scenario: Verify nullability of portfolio_id

    Given I delete all existing table rows for the registration registration1

    * -> POST uuid -> PUT null -> PUT uuid
    * -> POST a new registration with a portfolio_id
    When I POST a new registration specifying the following properties:
      | status                    | INACTIVE            |
      | registration_id           | <registration1>     |
      | product_id                | <uuid>              |
      | flexible_asset_id         | <registration1-fa>  |
      | ecrm_opportunity_id       | abc                 |
      | last_updated_by           | <username>          |
      | portfolio_id              | <uuid>              |
    Then the response should include the new registration
    And GET registration should return the current state of the registration
    * the registration history should reflect the new operation

    * -> PUT with portfolio_id = null
    When I update the registration with new values:
      | portfolio_id              | <null>              |
    Then the response should include the updated registration
    And GET registration should return the current state of the registration
    * the registration history should reflect the update operation

    * -> PUT with a valid portfolio_id
    When I update the registration with new values:
      | portfolio_id              | <uuid>              |
    Then the response should include the updated registration
    And GET registration should return the current state of the registration
    * the registration history should reflect the update operation

    Given I delete all existing table rows for the registration registration1

    * -> POST null -> PUT uuid -> PUT null
    * -> POST a new registration with a portfolio_id = null
    When I POST a new registration specifying the following properties:
      | status                    | INACTIVE            |
      | registration_id           | <registration1>     |
      | product_id                | <uuid>              |
      | flexible_asset_id         | <registration1-fa>  |
      | ecrm_opportunity_id       | abc                 |
      | last_updated_by           | <username>          |
      | portfolio_id              | <null>              |
    Then the response should include the new registration
    And GET registration should return the current state of the registration
    * the registration history should reflect the new operation

    * -> PUT with a valid portfolio_id
    When I update the registration with new values:
      | portfolio_id              | <uuid>              |
    Then the response should include the updated registration
    And GET registration should return the current state of the registration
    * the registration history should reflect the update operation

    * -> PUT with portfolio_id = null
    When I update the registration with new values:
      | portfolio_id              | <null>              |
    Then the response should include the updated registration
    And GET registration should return the current state of the registration
    * the registration history should reflect the update operation


  Scenario: Registration Set ID validation

    * -> Verify that uuid format is enforced

    Given I delete all existing table rows for the registration registration1

    * -> POST returns 400 for invalid registration_set_id (not a UUID)
    Given I expect the next API call to return a status code of 400 and details of "The request failed validation"
    When I POST a new registration specifying the following properties:
      | status                    | INACTIVE            |
      | registration_id           | <registration1>     |
      | product_id                | <uuid>              |
      | flexible_asset_id         | <registration1-fa>  |
      | ecrm_opportunity_id       | abc                 |
      | last_updated_by           | <username>          |
      | registration_set_id              | foo     |
    Then the expected status should be returned

    * -> POST returns 400 for empty string registration_set_id
    Given I expect the next API call to return a status code of 400 and details of "The request failed validation"
    When I POST a new registration specifying the following properties:
      | status                    | INACTIVE            |
      | registration_id           | <registration1>     |
      | product_id                | <uuid>              |
      | flexible_asset_id         | <registration1-fa>  |
      | ecrm_opportunity_id       | abc                 |
      | last_updated_by           | <username>          |
      | registration_set_id        | <empty-string>      |
    Then the expected status should be returned

    * -> POST a new registration with a valid registration_set_id
    When I POST a new registration specifying the following properties:
      | status                    | INACTIVE            |
      | registration_id           | <registration1>     |
      | product_id                | <uuid>              |
      | flexible_asset_id         | <registration1-fa>  |
      | ecrm_opportunity_id       | abc                 |
      | last_updated_by           | <username>          |
      | registration_set_id              | <uuid>              |
    Then the response should include the new registration
    And GET registration should return the current state of the registration
    * the registration history should reflect the new operation

    * -> PUT returns 400 for invalid registration_set_id (not a UUID)
    Given I expect the next API call to return a status code of 400 and details of "The request failed validation"
    When I update the registration with new values:
      | registration_set_id              | foo              |
    Then the expected status should be returned

    * -> PUT: update the registration_set_id with a valid uuid
    When I update the registration with new values:
      | registration_set_id              | <uuid>              |
    Then the response should include the updated registration
    And GET registration should return the current state of the registration
    * the registration history should reflect the update operation

    * -> Verify that a missing registration_set_id can be replaced with a valid id

    Given I delete all existing table rows for the registration registration1

    * -> POST a new registration without specifying registration_set_id
    When I POST a new registration specifying the following properties:
      | status                    | INACTIVE            |
      | registration_id           | <registration1>     |
      | product_id                | <uuid>              |
      | flexible_asset_id         | <registration1-fa>  |
      | ecrm_opportunity_id       | abc                 |
      | last_updated_by           | <username>          |
    Then the response should include the new registration
    And GET registration should return the current state of the registration
    * the registration history should reflect the new operation

    * -> Now update with a valid registration_set_id
    When I update the registration with new values:
      | registration_set_id              | <uuid>              |
    Then the response should include the updated registration
    And GET registration should return the current state of the registration
    * the registration history should reflect the update operation


  Scenario: Verify nullability of registration_set_id

    Given I delete all existing table rows for the registration registration1

    * -> POST uuid -> PUT null -> PUT uuid
    * -> POST a new registration with a registration_set_id
    When I POST a new registration specifying the following properties:
      | status                    | INACTIVE            |
      | registration_id           | <registration1>     |
      | product_id                | <uuid>              |
      | flexible_asset_id         | <registration1-fa>  |
      | ecrm_opportunity_id       | abc                 |
      | last_updated_by           | <username>          |
      | registration_set_id              | <uuid>              |
    Then the response should include the new registration
    And GET registration should return the current state of the registration
    * the registration history should reflect the new operation

    * -> PUT with registration_set_id = null
    When I update the registration with new values:
      | registration_set_id              | <null>              |
    Then the response should include the updated registration
    And GET registration should return the current state of the registration
    * the registration history should reflect the update operation

    * -> PUT with a valid registration_set_id
    When I update the registration with new values:
      | registration_set_id              | <uuid>              |
    Then the response should include the updated registration
    And GET registration should return the current state of the registration
    * the registration history should reflect the update operation

    Given I delete all existing table rows for the registration registration1

    * -> POST null -> PUT uuid -> PUT null
    * -> POST a new registration with a registration_set_id = null
    When I POST a new registration specifying the following properties:
      | status                    | INACTIVE            |
      | registration_id           | <registration1>     |
      | product_id                | <uuid>              |
      | flexible_asset_id         | <registration1-fa>  |
      | ecrm_opportunity_id       | abc                 |
      | last_updated_by           | <username>          |
      | registration_set_id              | <null>              |
    Then the response should include the new registration
    And GET registration should return the current state of the registration
    * the registration history should reflect the new operation

    * -> PUT with a valid registration_set_id
    When I update the registration with new values:
      | registration_set_id              | <uuid>              |
    Then the response should include the updated registration
    And GET registration should return the current state of the registration
    * the registration history should reflect the update operation

    * -> PUT with registration_set_id = null
    When I update the registration with new values:
      | registration_set_id              | <null>              |
    Then the response should include the updated registration
    And GET registration should return the current state of the registration
    * the registration history should reflect the update operation


  Scenario: ITAPPSIT-3778: Backfill flag

    Given I set the expected org_id to SmdQaOrgPoland

    # Org is QAA_IDS_REGIS
    Given I delete all existing table rows for the registration registration5

    * -> POST a new registration for Krakow using the flexible asset id
    When I POST a new registration specifying the following properties:
      | status                    | INACTIVE |
      | registration_id                        | <registration5>  |
      | product_id                | <uuid>                  |
      | flexible_asset_id         | <registration5-fa>                  |
      | ecrm_opportunity_id       | abc                  |
      |last_updated_by            | <username>                 |
      | portfolio_id              | <uuid>                     |
    Then the response should include the new registration
    And needs_manual_fix should be false
    And GET registration should return the current state of the registration
    And the registration history should reflect the new operation

    * -> DELETE the registration
    When I DELETE my registration
    * log on
    Then the registration history should reflect the delete operation

    Given I set registration backfill=missing
    And I expect the next API call to return a status code of 404 and details of "Registration not found"
    Then GET registration should return the expected status

    Given I set registration backfill=false
    And I expect the next API call to return a status code of 404 and details of "Registration not found"
    Then GET registration should return the expected status

    Given I set registration backfill=true
    And I expect the next API call to return a status code of 200 and message of "OK"
    Then GET registration should return the expected status

    # Note: I manually verified that the reg history is correct. Requires too many code changes to validate with automation.
    # You can uncomment the following line to get the history, but it will fail because backfill will re-create the registration
    # with actual properties from Atlas rather than the random values we used above.

    # And the registration history should reflect the recreate operation