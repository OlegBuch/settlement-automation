Feature: PUT /registrations?refresh=true/false

  References:

  <CONFLUENCE_URL>/display/XP/Settlement+Data+Service+-+Data+Model
  BDAP-1709 Create API - Participation: /registrations endpoints
  BDAP-1708: Create data model, tables, migrations - Participation

  Prerequsities: The scenario 'Create ITS mappings' in Registration.feature

  Note: org_id is always derived from registration. Changing the site_id won't cause API to call Atlas to get the org. However, ITS will be called for the org_id mapping.


  Background:
    Given I start with an empty context
    * I log in as a settlement API admin
    * I set the expected org_id to SmdQaOrg1
    * I DELETE our alternate ITS mapping for SmdQaOrg1
    * I DELETE our alternate ITS mapping for SmdQaSite1
    * I POST the official ITS mapping for SmdQaOrg1
    * I POST the official ITS mapping for SmdQaSite1
    * I POST the official ITS mapping for SmdQaSite2


  Scenario: Refresh = false or missing, payload includes SDP/FA

    Given I delete all existing table rows for the registration registration1

    * -> POST a new registration
    When I POST a new registration specifying the following properties:
      | status                    | INACTIVE |
      | registration_id                        | <registration1>  |
      | product_id                | <uuid>                  |
      | service_delivery_point_id         | <registration1-sdp>                  |
      | ecrm_opportunity_id       | abc                  |
      |last_updated_by            | <username>                  |
    Then the response should include the new registration
    And GET registration should return the current state of the registration
    And the registration history should reflect the new operation

    * -> change the ITS mapping for org_id and site_id
    Given I DELETE our ITS mapping for SmdQaOrg1
    * I POST an alternate ITS mapping for SmdQaOrg1
    * I DELETE our ITS mapping for SmdQaSite1
    * I POST an alternate ITS mapping for SmdQaSite1

    * -> Payload includes existing SDP, Atlas and ITS should NOT be called (refresh missing)
    When I update the registration with new values:
      | service_delivery_point_id         | <registration1-sdp>                  |
      |last_updated_by            | <username>                  |
    Then the response should include the updated registration
    * needs_manual_fix should be false
    * GET registration should return the current state of the registration
    * the registration history should not be updated

    * -> Verify that refresh boolean value is used, not just the presence of the parameter
    * -> Payload includes existing SDP, Atlas and ITS should NOT be called (refresh = false)
    When I update the registration with new values:
      | service_delivery_point_id         | <registration1-sdp>                  |
      |last_updated_by            | <username>                  |
      | refresh                   | false                    |
    Then the response should include the updated registration
    * needs_manual_fix should be false
    * GET registration should return the current state of the registration
    * the registration history should not be updated

    * -> Payload includes existing SDP and another update, Atlas and ITS should NOT be called
    When I update the registration with new values:
      | service_delivery_point_id         | <registration1-sdp>                  |
      | product_id      | <uuid>       |
      | last_updated_by | <username>       |
    Then the response should include the updated registration
    * needs_manual_fix should be false
    * GET registration should return the current state of the registration
    * the registration history should reflect the update operation

    * ->  Payload includes new SDP, Atlas and ITS for site_id, plus ITS for org_id, should be called
    When I update the registration with new values:
      | service_delivery_point_id         | <registration2-sdp>                  |
      |last_updated_by            | <username>                  |
    Then the response should include the updated registration
    * needs_manual_fix should be false
    * GET registration should return the current state of the registration
    * the registration history should reflect the update operation

    * ->  Payload includes new SDP not found in Atlas.
    * -> Result: Because flexible_asset_id is also null, result is Error 500
    Given I expect the next API call to return a status code of 500 and details of "Error while retrieving registration derived fields: site_id not found"
    When I update the registration with new values:
      | service_delivery_point_id              | <uuid>                  |
      |last_updated_by            | <username>                  |
    Then the expected status should be returned
    * GET registration should return the current state of the registration
    * the registration history should not be updated

    * ->  Payload includes SDP = null
    * -> Result: Because flexible_asset_id is also null, result is Error 500
    Given I expect the next API call to return a status code of 500 and details of "Error while retrieving registration derived fields: site_id not found"
    When I update the registration with new values:
      | service_delivery_point_id              | <null>                  |
      |last_updated_by            | <username>                  |
    Then the expected status should be returned
    * GET registration should return the current state of the registration
    * the registration history should not be updated

    * -> ITAPPSIT-3566: ITS site mapping is too long for type character varying(18)
    Given I DELETE our alternate ITS mapping for SmdQaSite1
    * I POST the official ITS mapping for SmdQaSite1InvalidEcrmId
    When I update the registration with new values:
      | service_delivery_point_id         | <registration1-sdp>                  |
      |last_updated_by            | <username>                  |
    Then the response should include the updated registration
    * needs_manual_fix should be true
    * GET registration should return the current state of the registration
    * the registration history should reflect the update operation

    * -> Cleanup
    Given I DELETE our alternate ITS mapping for SmdQaOrg1
    * I DELETE our alternate ITS mapping for SmdQaSite1
    * I DELETE our alternate ITS mapping for SmdQaSite1InvalidEcrmId
    * I POST the official ITS mapping for SmdQaOrg1
    * I POST the official ITS mapping for SmdQaSite1

    * -> ITS site mapping is valid value. service_delivery_point_id is updated so all derived fields should be set.
    When I update the registration with new values:
      | service_delivery_point_id         | <registration2-sdp>                  |
      |last_updated_by            | <username>                  |
    Then the response should include the updated registration
    And needs_manual_fix should be false
    And GET registration should return the current state of the registration
    And the registration history should reflect the update operation


  Scenario: Refresh = true, payload includes existing FA

    Given I delete all existing table rows for the registration registration1

    * -> POST a new registration with all properties
    When I POST a new registration specifying the following properties:
      | status                    | INACTIVE |
      | registration_id                        | <registration1>  |
      | product_id                | <uuid>                  |
      | flexible_asset_id         | <registration1-fa>                  |
      | ecrm_opportunity_id       | abc                  |
      |last_updated_by            | <username>                  |
    Then the response should include the new registration
    And needs_manual_fix should be false
    And the registration history should reflect the new operation

    * -> change the ITS mapping for org_id and site_id
    Given I DELETE our ITS mapping for SmdQaOrg1
    * I POST an alternate ITS mapping for SmdQaOrg1
    * I DELETE our ITS mapping for SmdQaSite1
    * I POST an alternate ITS mapping for SmdQaSite1

    * -> Payload includes existing FA, both mappings are valid
    When I update the registration with new values:
      | flexible_asset_id         | <registration1-fa>                  |
      | refresh             | true                 |
    Then the response should include the updated registration
    * needs_manual_fix should be false
    * GET registration should return the current state of the registration
    * the registration history should reflect the update operation

    * -> Payload includes existing FA, ecrm_account_id mapping is missing
    Given I DELETE our alternate ITS mapping for SmdQaOrg1
    When I update the registration with new values:
      | flexible_asset_id         | <registration1-fa>                  |
      | refresh             | true                 |
    Then the response should include the updated registration
    * needs_manual_fix should be true
    * GET registration should return the current state of the registration
    * the registration history should reflect the update operation

    * -> Payload includes existing FA, ecrm_site_id mapping is missing
    Given I DELETE our alternate ITS mapping for SmdQaOrg1
    * I POST the official ITS mapping for SmdQaOrg1
    * I DELETE our alternate ITS mapping for SmdQaSite1
    When I update the registration with new values:
      | flexible_asset_id         | <registration1-fa>                  |
      | refresh             | true                 |
    Then the response should include the updated registration
    * needs_manual_fix should be true
    * GET registration should return the current state of the registration
    * the registration history should reflect the update operation

    * -> ITAPPSIT-3566: ITS account mapping is too long for type character varying(18)
    Given I DELETE our ITS mapping for SmdQaOrg1
    * I POST the official ITS mapping for SmdQaOrg1InvalidEcrmId
    When I update the registration with new values:
      | flexible_asset_id         | <registration1-fa>                  |
      | refresh             | true                 |
    Then the response should include the updated registration
    * needs_manual_fix should be true
    * GET registration should return the current state of the registration
    * the registration history should reflect the update operation

    * -> Update the registration so it has all derived values
    Given I DELETE our ITS mapping for SmdQaOrg1InvalidEcrmId
    * I POST the official ITS mapping for SmdQaOrg1
    * I POST the official ITS mapping for SmdQaSite1
    When I update the registration with new values:
      | flexible_asset_id         | <registration1-fa>                  |
      | refresh             | true                 |
    Then the response should include the updated registration
    * needs_manual_fix should be false
    * GET registration should return the current state of the registration
    * the registration history should reflect the update operation

    * -> Payload includes existing FA, ecrm_site_id mapping is invalid value
    * -> ITAPPSIT-3566: ITS site mapping is too long for type character varying(18)
    Given I DELETE our ITS mapping for SmdQaSite1
    Given I POST the official ITS mapping for SmdQaSite1InvalidEcrmId
    When I update the registration with new values:
      | flexible_asset_id         | <registration3-fa>                  |
      | refresh             | true                 |
    Then the response should include the updated registration
    * needs_manual_fix should be true
    * GET registration should return the current state of the registration
    * the registration history should reflect the update operation

    * -> Cleanup
    * I DELETE our ITS mapping for SmdQaSite1InvalidEcrmId
    * I POST the official ITS mapping for SmdQaSite1


  Scenario: Refresh = true, payload includes new FA

    Given I delete all existing table rows for the registration registration1

    * -> POST a new registration with all properties
    When I POST a new registration specifying the following properties:
      | status                    | INACTIVE |
      | registration_id                        | <registration1>  |
      | product_id                | <uuid>                  |
      | flexible_asset_id         | <registration1-fa>                  |
      | ecrm_opportunity_id       | abc                  |
      |last_updated_by            | <username>                  |
    Then the response should include the new registration
    And needs_manual_fix should be false
    And the registration history should reflect the new operation

    * -> change the ITS mapping for org_id
    Given I DELETE our ITS mapping for SmdQaOrg1
    * I POST an alternate ITS mapping for SmdQaOrg1

    * -> Payload includes new FA, both mappings are valid
    When I update the registration with new values:
      | flexible_asset_id         | <registration3-fa>                  |
      | refresh             | true                 |
    Then the response should include the updated registration
    * needs_manual_fix should be false
    * GET registration should return the current state of the registration
    * the registration history should reflect the update operation

    * -> Cleanup
    Given I DELETE our alternate ITS mapping for SmdQaOrg1
    * I POST the official ITS mapping for SmdQaOrg1

    * -> Payload includes new FA, ecrm_site_id mapping is missing
    Given I DELETE our ITS mapping for SmdQaSite1
    When I update the registration with new values:
      | flexible_asset_id         | <registration1-fa>                  |
      | refresh             | true                 |
    Then the response should include the updated registration
    * needs_manual_fix should be true
    * GET registration should return the current state of the registration
    * the registration history should reflect the update operation

    * -> Payload includes new FA, ecrm_site_id mapping is invalid value
    * -> ITAPPSIT-3566: ITS site mapping is too long for type character varying(18)
    Given I POST the official ITS mapping for SmdQaSite1InvalidEcrmId
    When I update the registration with new values:
      | flexible_asset_id         | <registration3-fa>                  |
      | refresh             | true                 |
    Then the response should include the updated registration
    * needs_manual_fix should be true
    * GET registration should return the current state of the registration
    * the registration history should reflect the update operation

    * -> Fix the mapping and try again
    Given I DELETE our ITS mapping for SmdQaSite1InvalidEcrmId
    * I POST the official ITS mapping for SmdQaSite1
    When I update the registration with new values:
      | flexible_asset_id         | <registration1-fa>                  |
      | refresh             | true                 |
    Then the response should include the updated registration
    * needs_manual_fix should be false
    * GET registration should return the current state of the registration
    * the registration history should reflect the update operation

    * ->  Payload includes FA = null
    * -> Result: Because SDP is also null, result is Error 500
    Given I expect the next API call to return a status code of 500 and details of "Error while retrieving registration derived fields: site_id not found"
    When I update the registration with new values:
      | flexible_asset_id              | <null>                  |
      | refresh             | true                 |
    Then the expected status should be returned
    * GET registration should return the current state of the registration
    * the registration history should not be updated
