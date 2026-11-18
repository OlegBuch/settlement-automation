Feature: Scenarios for deriving site_id from Atlas

  ITAPPSIT-3399: settlement metadata api - fetch site_id from Atlas

  Prerequsities: The scenario 'Create ITS mappings' in Registration.feature

  Background:
    Given I start with an empty context
    * I log in as a settlement API admin
    * I set the expected org_id to SmdQaOrgPoland


  Scenario: POST/PUT: if SDP is included in body and FA is missing or null, try to get site from Atlas via SDP

    Given I delete all existing table rows for the registration registration4
    * -> POST:  a registration with site = Krakow
    When I POST a new registration specifying the following properties:
      | status                    | INACTIVE |
      | registration_id                        | <registration4>  |
      | product_id                | <uuid>                  |
      | service_delivery_point_id         | <registration4-sdp>                  |
      | ecrm_opportunity_id       | abc                  |
      |last_updated_by            | <username>                  |
    Then the response should include the new registration
    And needs_manual_fix should be false
    And GET registration should return the current state of the registration
    And the registration history should reflect the new operation

    * -> PUT:  the SDP now points to site = Lodz
    When I update the registration with new values:
      | service_delivery_point_id         | <registration6-sdp>                  |
      | flexible_asset_id         | <null>                  |
    Then the response should include the updated registration
    * GET registration should return the current state of the registration
    And the registration history should reflect the update operation


  Scenario:POST/PUT: if both SDP and FA are included in body, first try to get site from Atlas via SDP

    Given I delete all existing table rows for the registration registration4
    * -> POST:  a registration with site = Krakow
    When I POST a new registration specifying the following properties:
      | status                    | INACTIVE |
      | registration_id                        | <registration4>  |
      | product_id                | <uuid>                  |
      | service_delivery_point_id         | <registration4-sdp>                  |
      | flexible_asset_id         | <uuid>                  |
      | ecrm_opportunity_id       | abc                  |
      |last_updated_by            | <username>                  |
    Then the response should include the new registration
    And needs_manual_fix should be false
    And GET registration should return the current state of the registration
    And the registration history should reflect the new operation

    * -> PUT:  the SDP now points to site = Lodz
    When I update the registration with new values:
      | service_delivery_point_id         | <registration6-sdp>                  |
      | flexible_asset_id         | <uuid>                  |
    Then the response should include the updated registration
    * GET registration should return the current state of the registration
    And the registration history should reflect the update operation


  Scenario:POST/PUT: if we failed to find site in Atlas via SDP, try to get site from Atlas via FA

    Given I delete all existing table rows for the registration registration5
    * -> POST:  a registration with site = Krakow
    When I POST a new registration specifying the following properties:
      | status                    | INACTIVE |
      | registration_id                        | <registration5>  |
      | product_id                | <uuid>                  |
      | service_delivery_point_id         | <uuid>                  |
      | flexible_asset_id         | <registration5-fa>                  |
      | ecrm_opportunity_id       | abc                  |
      |last_updated_by            | <username>                  |
    Then the response should include the new registration
    And needs_manual_fix should be false
    And GET registration should return the current state of the registration
    And the registration history should reflect the new operation

    * -> PUT:  (set up) the SDP points to site = Lodz
    When I update the registration with new values:
      | service_delivery_point_id         | <registration6-sdp>                  |
    Then the response should include the updated registration
    * GET registration should return the current state of the registration
    And the registration history should reflect the update operation

    * -> PUT:  (actual test) the FA points back to Krakow
    When I update the registration with new values:
      | service_delivery_point_id         | <uuid>                  |
      | flexible_asset_id         | <registration5-fa>                  |
    Then the response should include the updated registration
    * GET registration should return the current state of the registration
    And the registration history should reflect the update operation


  Scenario: POST/PUT: if SDP is not included in body or is null, try to get site from Atlas via FA

    Given I delete all existing table rows for the registration registration5
    * -> POST:  a registration with site = Krakow
    When I POST a new registration specifying the following properties:
      | status                    | INACTIVE |
      | registration_id                        | <registration5>  |
      | product_id                | <uuid>                  |
      | flexible_asset_id         | <registration5-fa>                  |
      | ecrm_opportunity_id       | abc                  |
      |last_updated_by            | <username>                  |
    Then the response should include the new registration
    And needs_manual_fix should be false
    And GET registration should return the current state of the registration
    And the registration history should reflect the new operation

    * -> PUT:  (set up) the FA points to a site in Org1 (not a supported business case but we just need to set up for the real test)
    When I update the registration with new values:
      | flexible_asset_id         | <registration1-fa>                  |
    Then the response should include the updated registration
    * GET registration should return the current state of the registration
    And the registration history should reflect the update operation

    * -> PUT:  (actual test) the FA points back to Krakow
    When I update the registration with new values:
      | service_delivery_point_id         | <null>                  |
      | flexible_asset_id         | <registration5-fa>                  |
    Then the response should include the updated registration
    * GET registration should return the current state of the registration
    And the registration history should reflect the update operation


  Scenario: PUT: if SDP is the same but FA has changed, call Atlas to get the site (using the above logic)

    Given I delete all existing table rows for the registration registration5
    * -> POST:  a registration with site = Krakow
    When I POST a new registration specifying the following properties:
      | status                    | INACTIVE |
      | registration_id                        | <registration5>  |
      | product_id                | <uuid>                  |
      | service_delivery_point_id         | <fixed-uuid>                  |
      | flexible_asset_id         | <registration5-fa>                  |
      | ecrm_opportunity_id       | abc                  |
      |last_updated_by            | <username>                  |
    Then the response should include the new registration
    And needs_manual_fix should be false
    And GET registration should return the current state of the registration
    And the registration history should reflect the new operation

    * -> PUT:  (set up) the FA points to a site in Org1 (not a supported business case but we just need to set up for the real test)
    When I update the registration with new values:
      | service_delivery_point_id         | <fixed-uuid>                  |
      | flexible_asset_id         | <registration1-fa>                  |
    Then the response should include the updated registration
    * GET registration should return the current state of the registration
    And the registration history should reflect the update operation

    * -> PUT:  (actual test) the FA points back to Krakow
    When I update the registration with new values:
      | service_delivery_point_id         | <fixed-uuid>              |
      | flexible_asset_id         | <registration5-fa>                  |
    Then the response should include the updated registration
    * GET registration should return the current state of the registration
    And the registration history should reflect the update operation


  Scenario: PUT: if both SDP and FA are the same, don't call Atlas to get the site (and don't call ITS)

    Given I delete all existing table rows for the registration registration5
    * -> POST:  a registration with site = Krakow
    When I POST a new registration specifying the following properties:
      | status                    | INACTIVE |
      | registration_id                        | <registration5>  |
      | product_id                | <uuid>                  |
      | service_delivery_point_id         | <fixed-uuid>                  |
      | flexible_asset_id         | <registration5-fa>                  |
      | ecrm_opportunity_id       | abc                  |
      |last_updated_by            | <username>                  |
    Then the response should include the new registration
    And needs_manual_fix should be false
    And GET registration should return the current state of the registration
    And the registration history should reflect the new operation

    * I DELETE our ITS mapping for SmdQaKrakow

    * -> PUT:  SDP and FA supplied but unchanged. No change in derived fields.
    When I update the registration with new values:
    | status | ACTIVE |
      | service_delivery_point_id         | <fixed-uuid>              |
      | flexible_asset_id         | <registration5-fa>                  |
    Then the response should include the updated registration
    * needs_manual_fix should be false
    * GET registration should return the current state of the registration
    * the registration history should reflect the update operation

    * -> PUT:  SDP changed but not found in Atlas, FA supplied but unchanged
    * -> expected result: Atlas and ITS called, site_id = Krakow, ecrm_site_id = null, needs_manual_fix = true
    When I update the registration with new values:
      | status | ACTIVE |
      | service_delivery_point_id         | <uuid>              |
      | flexible_asset_id         | <registration5-fa>                  |
    Then the response should include the updated registration
    * needs_manual_fix should be true
    * GET registration should return the current state of the registration
    * the registration history should reflect the update operation

    Given I POST the official ITS mapping for SmdQaKrakow


  Scenario: POST: if we didn't find site, return 500

    Given I delete all existing table rows for the registration registration5
    Given I expect the next API call to return a status code of 500 and details of "Error while retrieving registration derived fields: site_id not found"
    When I POST a new registration specifying the following properties:
      | status                    | INACTIVE |
      | registration_id                        | <registration5>  |
      | product_id                | <uuid>                  |
      | service_delivery_point_id         | <uuid>                  |
      | flexible_asset_id         | <uuid>                  |
      | ecrm_opportunity_id       | abc                  |
      |last_updated_by            | <username>                  |
    Then the expected status should be returned


  Scenario: PUT: if we didn't find site, return 500

    Given I delete all existing table rows for the registration registration5
    * -> POST:  a registration with site = Krakow
    When I POST a new registration specifying the following properties:
      | status                    | INACTIVE |
      | registration_id                        | <registration5>  |
      | product_id                | <uuid>                  |
      | flexible_asset_id         | <registration5-fa>                  |
      | ecrm_opportunity_id       | abc                  |
      |last_updated_by            | <username>                  |
    Then the response should include the new registration
    And needs_manual_fix should be false
    And GET registration should return the current state of the registration
    And the registration history should reflect the new operation

    Given I expect the next API call to return a status code of 500 and details of "Error while retrieving registration derived fields: site_id not found"
    When I update the registration with new values:
      | service_delivery_point_id         | <uuid>                  |
      | flexible_asset_id         | <uuid>                  |
    Then the expected status should be returned
    And GET registration should return the current state of the registration


  Scenario: POST: if both SDP and FA are missing, return 500

    Given I delete all existing table rows for the registration registration5
    Given I expect the next API call to return a status code of 500 and details of "Error while retrieving registration derived fields: site_id not found"
    When I POST a new registration specifying the following properties:
      | status                    | INACTIVE |
      | registration_id                        | <registration5>  |
      | product_id                | <uuid>                  |
      | ecrm_opportunity_id       | abc                  |
      |last_updated_by            | <username>                  |
    Then the expected status should be returned


  Scenario: PUT: if both SDP and FA are missing, return 500

    Given I delete all existing table rows for the registration registration5
    * -> POST:  a registration with site = Krakow
    When I POST a new registration specifying the following properties:
      | status                    | INACTIVE |
      | registration_id                        | <registration5>  |
      | product_id                | <uuid>                  |
      | flexible_asset_id         | <registration5-fa>                  |
      | ecrm_opportunity_id       | abc                  |
      |last_updated_by            | <username>                  |
    Then the response should include the new registration
    And needs_manual_fix should be false
    And GET registration should return the current state of the registration
    And the registration history should reflect the new operation

    Given I expect the next API call to return a status code of 500 and details of "Error while retrieving registration derived fields: site_id not found"
    When I update the registration with new values:
      | service_delivery_point_id         | <null>                  |
      | flexible_asset_id         | <null>                  |
    Then the expected status should be returned
    And GET registration should return the current state of the registration


