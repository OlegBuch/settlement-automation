Feature: Full Hierarchy for Product rules endpoints

  References:

  ITAPPSIT-4170: SMD API: link product_rule_group to fragment and detail tables

  Background:
    Given I start with an empty context
    And I log in as a settlement API admin


  #
  # Full hierarchy integration: parameter → fragment → group → product rule → details
  #
  Scenario: Full hierarchy lifecycle - parameter linked to fragment, fragment linked to group, group linked to product rule, details linked to group

    And I delete all existing product rule details for product rule product id a1b2c3d4-58cc-4372-a567-0e02b2c3d479
    And I delete all existing product rule groups for product rule product id a1b2c3d4-58cc-4372-a567-0e02b2c3d479
    And I delete all existing product rules with product id a1b2c3d4-58cc-4372-a567-0e02b2c3d479
    Given I delete all existing product rule fragments with name IntFragmentName
    And I delete all existing product rule parameters with name IntParamName

    # ── Step 1: Create parameter ──
  When I POST a new product rule parameter specifying the following properties
  | name      | IntParamName |
  | type      | string       |
  | validator | {}           |
  Then the response should include the new product rule parameter
  And I save this product rule parameter id as IntParamId

    # ── Step 2: Create fragment ──
  When I POST a new product rule fragment specifying the following properties
  | name        | IntFragmentName |
  | description | integration test fragment |
  | validator   | {}              |
  Then the response should include the new product rule fragment
  And I save this product rule fragment id as IntFragmentId

    # ── Step 3: Link parameter to fragment ──
  Given I set the context product rule fragment id to IntFragmentId
  And I expect the next API call to return a status code of 200 and details of "OK"
  When I PUT parameters "IntParamId,false" for the current product rule fragment
  Then the PUT parameters expected status should be returned

    # ── Step 4: Create product rule ──
  When I POST a new product rule specifying the following properties
  | product_id | a1b2c3d4-58cc-4372-a567-0e02b2c3d479 |
  | name       | IntProductRule                        |
  Then the response should include the new product rule
  And I save this product rule product id as IntProductRuleProductId
  And I save this product rule id as IntProductRuleId

    # ── Step 5: Create product rule group linked to product rule ──
  And I delete all existing product rule groups for saved product rule IntProductRuleId and name IntGroup
  When I POST a new product rule group specifying the following properties
  | product_rule_id | IntProductRuleId |
  | name            | IntGroup         |
  Then the response should include the new product rule group
  And I save this product rule group id as IntGroupId

    # ── Step 6: Link fragment (already carrying parameter) to the group ──
  Given I set the context product rule group id to IntGroupId
  And I expect the next API call to return a status code of 200 and details of "OK"
  When I PUT fragments "IntFragmentId" for the current product rule group
  Then the PUT fragments expected status should be returned

    # ── Step 7: Create product rule detail linking group and parameter ──
  When I POST a new product rule detail specifying the following properties
  | pr_group_id         | IntGroupId |
  | pr_parameter_def_id | IntParamId |
  | value               | IntValue   |
  | start_dttm_utc      | 2026-01-01T00:00:00Z |
  | end_dttm_utc        | 2027-01-01T00:00:00Z |
  Then the response should include the new product rule detail
  And I save this product rule detail id as IntDetailId

    # ── Step 8: GET product rule with include_details=true - verify full hierarchy ──
  Given I set the context product rule product id to IntProductRuleProductId
  When I GET the product rule by product id with include_details true
  Then the product rule should contain groups with fragments and parameters

    # ── Step 9: Unlink fragment from group (PUT empty fragments list) ──
  Given I set the context product rule group id to IntGroupId
  And I expect the next API call to return a status code of 200 and details of "OK"
  When I PUT fragments " " for the current product rule group
  Then the PUT fragments expected status should be returned

    # ── Step 10: GET product rule - group should now have no fragments ──
  Given I set the context product rule product id to IntProductRuleProductId
  When I GET the product rule by product id with include_details true
  Then the product rule group IntGroupId should include no fragments

    # ── Step 11: Try to delete product rule - fails because group still exists ──
  Given I set the context product rule product id to IntProductRuleProductId
  And I expect the next API call to return a status code of 400 and details of "Cannot delete Product Rule associated to Groups"
  When I DELETE my product rule
  Then the expected status should be returned

    # ── Step 12: Delete product rule detail ──
  Given I set the context product rule detail id to IntDetailId
  When I DELETE my product rule detail

    # ── Step 13: Delete product rule group ──
  Given I set the context product rule group id to IntGroupId
  When I DELETE my product rule group

    # ── Step 14: GET product rule - groups should be empty now ──
  Given I set the context product rule product id to IntProductRuleProductId
  When I GET the product rule by product id with include_details true
  Then the product rule should have no groups

  # Now delete product rule (no groups left)
    And I delete all existing product rules with product id a1b2c3d4-58cc-4372-a567-0e02b2c3d479

  # Unlink parameter from fragment before deleting fragment
    Given I set the context product rule fragment id to IntFragmentId
    And I expect the next API call to return a status code of 200 and details of "OK"
    When I PUT parameters "" for the current product rule fragment
    Then the PUT parameters expected status should be returned

  # Now delete fragment (no parameters linked)
    Given I delete all existing product rule fragments with name IntFragmentName

  # Now delete parameter (no fragments linked)
    And I delete all existing product rule parameters with name IntParamName
