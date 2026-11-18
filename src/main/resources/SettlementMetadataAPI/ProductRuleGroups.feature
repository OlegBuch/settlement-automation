Feature: CRUD for product rule groups

  ITAPPSIT-4169: SMD API: create product_rule_group table and API CRUD endpoints

  # Uses /api/v1/productrulegroups endpoints.
  # Covers:
  # - GET all (200, auth errors)
  # - GET by id (200, 400 invalid id, 404 missing, auth errors)
  # - POST create (201, 400 validation, 409 duplicate, auth errors)
  # - PUT update (200, 400 validation, 404 missing, 409 duplicate, auth errors)
  # - DELETE (204 success, 400 invalid id type, 404 missing, auth errors)

  Background:
    Given I start with an empty context
    And I log in as a settlement API admin


  #
  # GET all
  #
  Scenario: GET all product rule groups returns 200
    When I GET all product rule groups
    Then the product rule groups list should be returned

  Scenario: GET all fails with 401 if ENOC session is missing
    Given I do not include the ENOC session header
    And I expect the next API call to return a status code of 401 and message of "Unauthorized"
    When I GET all product rule groups
    Then the expected status should be returned

  Scenario: GET all fails with 403 if API key is missing
    Given I do not include the API key header
    And I expect the next API call to return a status code of 403 and message of "Forbidden"
    When I GET all product rule groups
    Then the expected status should be returned


  #
  # GET by id
  #
  Scenario: GET by id returns 200 for existing group
    Given I GET a real product rule id and save it as RealProductRuleId
    And I delete all existing product rule groups for saved product rule RealProductRuleId and name GetByIdGroup
    And I POST a new product rule group specifying the following properties
      | product_rule_id | RealProductRuleId |
      | name            | GetByIdGroup      |
    Then the response should include the new product rule group
    And I save this product rule group id as GetByIdGroupId

    Given I set the context product rule group id to GetByIdGroupId
    When I GET the product rule group by id
    Then GET product rule group should return the current state

    Given I set the context product rule group id to GetByIdGroupId
    Then I DELETE my product rule group


  #
  # Random-name create/delete flow
  #
  Scenario: Create a product rule group with random name and then delete it
    Given I GET a real product rule id and save it as RealProductRuleId
    And I generate a random product rule group name and save it as RandomProductRuleGroupName
    And I delete all existing product rule groups for saved product rule RealProductRuleId and name RandomProductRuleGroupName

    When I POST a new product rule group specifying the following properties
      | product_rule_id | RealProductRuleId          |
      | name            | RandomProductRuleGroupName |
    Then the response should include the new product rule group
    And I save this product rule group id as RandomProductRuleGroupId

    Given I set the context product rule group id to RandomProductRuleGroupId
    When I GET the product rule group by id
    Then GET product rule group should return the current state

    Given I set the context product rule group id to RandomProductRuleGroupId
    When I DELETE my product rule group

    Given I set the context product rule group id to RandomProductRuleGroupId
    And I expect the next API call to return a status code of 404 and details of "not found"
    When I GET the product rule group by id
    Then the expected status should be returned


  #
  # Full CRUD flow
  #
  Scenario: Full CRUD lifecycle for product rule group
    Given I GET a real product rule id and save it as RealProductRuleId
    And I delete all existing product rule groups for saved product rule RealProductRuleId and name TestGroup1
    And I delete all existing product rule groups for saved product rule RealProductRuleId and name TestGroup1Updated

    # POST -> 201
    When I POST a new product rule group specifying the following properties
      | product_rule_id | RealProductRuleId |
      | name            | TestGroup1        |
    Then the response should include the new product rule group
    And the product rule group response should contain fields
      | id                    |
      | product_rule_id       |
      | name                  |
      | last_updated_dttm_utc |
      | last_updated_by       |

    # GET by id -> 200
    When I GET the product rule group by id
    Then GET product rule group should return the current state

    # GET all -> 200 and list contains our group
    When I GET all product rule groups
    Then the product rule groups list should contain my group

    # PUT -> 200
    When I update the product rule group with new values
      | product_rule_id | RealProductRuleId |
      | name            | TestGroup1Updated |
    Then the response should include the updated product rule group
    And GET product rule group should return the current state

    # DELETE -> 204
    When I DELETE my product rule group

    # GET after delete -> 404
    Given I expect the next API call to return a status code of 404 and details of "not found"
    When I GET the product rule group by id
    Then the expected status should be returned


  #
  # GET validations
  #
  Scenario: GET by id fails with 401 if ENOC session is missing
    Given I set the context product rule group id to random valid id
    And I do not include the ENOC session header
    And I expect the next API call to return a status code of 401 and message of "Unauthorized"
    When I GET the product rule group by id
    Then the expected status should be returned

  Scenario: GET by id fails with 403 if API key is missing
    Given I set the context product rule group id to random valid id
    And I do not include the API key header
    And I expect the next API call to return a status code of 403 and message of "Forbidden"
    When I GET the product rule group by id
    Then the expected status should be returned

  Scenario: GET by id fails with 400 if id is not numeric
    Given I set the context product rule group ID to non-numeric
    And I expect the next API call to return a status code of 400 and details of "The request failed validation"
    When I GET the product rule group by id
    Then the expected status should be returned

  Scenario: GET by id fails with 404 if group does not exist
    Given I set the context product rule group ID to 99999999
    And I expect the next API call to return a status code of 404 and details of "not found"
    When I GET the product rule group by id
    Then the expected status should be returned


  #
  # POST validations
  #
  Scenario: POST creates product rule group
    Given I GET a real product rule id and save it as RealProductRuleId
    And I delete all existing product rule groups for saved product rule RealProductRuleId and name SCHEDULE_GROUP_2
    When I POST a new product rule group specifying the following properties
      | product_rule_id | RealProductRuleId |
      | name            | SCHEDULE_GROUP_2  |
    Then the response should include the new product rule group

    And I DELETE my product rule group

  Scenario: POST fails with 401 if ENOC session is missing
    Given I do not include the ENOC session header
    And I expect the next API call to return a status code of 401 and message of "Unauthorized"
    When I POST a new product rule group specifying the following properties
      | product_rule_id | 11         |
      | name            | AuthGroup1 |
    Then the expected status should be returned

  Scenario: POST fails with 403 if API key is missing
    Given I do not include the API key header
    And I expect the next API call to return a status code of 403 and message of "Forbidden"
    When I POST a new product rule group specifying the following properties
      | product_rule_id | 11         |
      | name            | AuthGroup2 |
    Then the expected status should be returned

  Scenario: POST returns 400 when required fields missing or invalid
    Given I expect the next API call to return a status code of 400 and details of "failed validation"
    When I POST a new product rule group specifying the following properties
      | name | MissingProductRuleId |
    Then the expected status should be returned

    Given I expect the next API call to return a status code of 400 and details of "failed validation"
    When I POST a new product rule group specifying the following properties
      | product_rule_id |      |
      | name            | Bad1 |
    Then the expected status should be returned

    Given I expect the next API call to return a status code of 400 and details of '"name" is not allowed to be empty'
    When I POST a new product rule group specifying the following properties
      | product_rule_id | 11 |
      | name            |    |
    Then the expected status should be returned

  Scenario: POST returns 400 when product_rule_id does not exist
    Given I expect the next API call to return a status code of 400 and details of "does not exist"
    When I POST a new product rule group specifying the following properties
      | product_rule_id | 999999999   |
      | name            | InvalidRule |
    Then the expected status should be returned

  Scenario: POST returns 409 when name already exists for same product rule
    Given I GET a real product rule id and save it as RealProductRuleId
    And I delete all existing product rule groups for saved product rule RealProductRuleId and name DuplicateGroup
    And I POST a new product rule group specifying the following properties
      | product_rule_id | RealProductRuleId |
      | name            | DuplicateGroup    |
    Then the response should include the new product rule group

    Given I expect the next API call to return a status code of 409 and details of "already exists"
    When I POST a new product rule group specifying the following properties
      | product_rule_id | RealProductRuleId |
      | name            | DuplicateGroup    |
    Then the expected status should be returned

    When I DELETE my product rule group


  #
  # PUT validations
  #
  Scenario: PUT returns 404 when group does not exist
    Given I set the context product rule group ID to 99999999
    And I expect the next API call to return a status code of 404 and details of "not found"
    When I update the product rule group with new values
      | product_rule_id | 11           |
      | name            | MissingGroup |
    Then the expected status should be returned

  Scenario: PUT returns 400 when id is not numeric
    Given I set the context product rule group ID to non-numeric
    And I expect the next API call to return a status code of 400 and details of "The request failed validation"
    When I update the product rule group with new values
      | product_rule_id | 11                |
      | name            | NonNumericIdGroup |
    Then the expected status should be returned

  Scenario: PUT returns 400 when mandatory body fields are empty or invalid
    Given I GET a real product rule id and save it as RealProductRuleId
    And I delete all existing product rule groups for saved product rule RealProductRuleId and name InvalidPutGroup
    And I POST a new product rule group specifying the following properties
      | product_rule_id | RealProductRuleId |
      | name            | InvalidPutGroup   |
    Then the response should include the new product rule group
    And I save this product rule group id as InvalidPutGroupId

    And I set the context product rule group id to InvalidPutGroupId
    And I expect the next API call to return a status code of 400 and details of "failed validation"
    When I update the product rule group with new values
      | name | InvalidPutGroupUpdated |
    Then the expected status should be returned

    And I set the context product rule group id to InvalidPutGroupId
    And I expect the next API call to return a status code of 400 and details of "failed validation"
    When I update the product rule group with new values
      | product_rule_id | RealProductRuleId |
    Then the expected status should be returned

    And I set the context product rule group id to InvalidPutGroupId
    And I expect the next API call to return a status code of 400 and details of "failed validation"
    When I update the product rule group with new values
      | product_rule_id |   |
      | name            | X |
    Then the expected status should be returned

    And I set the context product rule group id to InvalidPutGroupId
    And I expect the next API call to return a status code of 400 and details of '"name" is not allowed to be empty'
    When I update the product rule group with new values
      | product_rule_id | RealProductRuleId |
      | name            |                   |
    Then the expected status should be returned

    Given I set the context product rule group id to InvalidPutGroupId
    When I DELETE my product rule group

  Scenario: PUT returns 400 when product_rule_id does not exist
    Given I GET a real product rule id and save it as RealProductRuleId
    And I delete all existing product rule groups for saved product rule RealProductRuleId and name PutInvalidRuleGroup
    And I POST a new product rule group specifying the following properties
      | product_rule_id | RealProductRuleId   |
      | name            | PutInvalidRuleGroup |
    Then the response should include the new product rule group
    And I save this product rule group id as PutInvalidRuleGroupId

    And I set the context product rule group id to PutInvalidRuleGroupId
    And I expect the next API call to return a status code of 400 and details of "does not exist"
    When I update the product rule group with new values
      | product_rule_id | 999999999           |
      | name            | PutInvalidRuleGroup |
    Then the expected status should be returned

    Given I set the context product rule group id to PutInvalidRuleGroupId
    When I DELETE my product rule group

  Scenario: PUT returns 409 when new name collides with existing group on same rule
    Given I GET a real product rule id and save it as RealProductRuleId
    And I delete all existing product rule groups for saved product rule RealProductRuleId and name GroupA
    And I delete all existing product rule groups for saved product rule RealProductRuleId and name GroupB

    When I POST a new product rule group specifying the following properties
      | product_rule_id | RealProductRuleId |
      | name            | GroupA            |
    Then the response should include the new product rule group
    And I save this product rule group id as GroupAId

    When I POST a new product rule group specifying the following properties
      | product_rule_id | RealProductRuleId |
      | name            | GroupB            |
    Then the response should include the new product rule group
    And I save this product rule group id as GroupBId

    Given I set the context product rule group id to GroupBId
    And I expect the next API call to return a status code of 409 and details of "already exists"
    When I update the product rule group with new values
      | product_rule_id | RealProductRuleId |
      | name            | GroupA            |
    Then the expected status should be returned

    Given I set the context product rule group id to GroupAId
    When I DELETE my product rule group

    Given I set the context product rule group id to GroupBId
    When I DELETE my product rule group

  Scenario: PUT returns 401 and 403 for auth errors
    Given I GET a real product rule id and save it as RealProductRuleId
    And I delete all existing product rule groups for saved product rule RealProductRuleId and name PutAuthGroup
    And I POST a new product rule group specifying the following properties
      | product_rule_id | RealProductRuleId |
      | name            | PutAuthGroup      |
    Then the response should include the new product rule group
    And I save this product rule group id as PutAuthGroupId

    Given I set the context product rule group id to PutAuthGroupId
    And I do not include the ENOC session header
    And I expect the next API call to return a status code of 401 and message of "Unauthorized"
    When I update the product rule group with new values
      | product_rule_id | RealProductRuleId |
      | name            | PutAuthGroup-401  |
    Then the expected status should be returned

    Given I set the context product rule group id to PutAuthGroupId
    And I do not include the API key header
    And I expect the next API call to return a status code of 403 and message of "Forbidden"
    When I update the product rule group with new values
      | product_rule_id | RealProductRuleId |
      | name            | PutAuthGroup-403  |
    Then the expected status should be returned

    Given I set the context product rule group id to PutAuthGroupId
    * I send a valid API key
    * I send a valid enoc_session
    Then I DELETE my product rule group


  #
  # DELETE validations
  #
  Scenario: DELETE returns 204 when group exists
    Given I GET a real product rule id and save it as RealProductRuleId
    And I delete all existing product rule groups for saved product rule RealProductRuleId and name DeletableGroup
    And I POST a new product rule group specifying the following properties
      | product_rule_id | RealProductRuleId |
      | name            | DeletableGroup    |
    Then the response should include the new product rule group
    And I save this product rule group id as DeletableGroupId

    Given I set the context product rule group id to DeletableGroupId
    When I DELETE my product rule group

    Given I expect the next API call to return a status code of 404 and details of "not found"
    When I GET the product rule group by id
    Then the expected status should be returned

  Scenario: DELETE returns 404 when group does not exist
    Given I set the context product rule group ID to 99999999
    And I expect the next API call to return a status code of 404 and details of "not found"
    When I DELETE my product rule group
    Then the expected status should be returned

  Scenario: DELETE returns 400 when id is not numeric
    Given I set the context product rule group ID to non-numeric
    And I expect the next API call to return a status code of 400 and details of 'The request failed validation'
    When I DELETE my product rule group
    Then the expected status should be returned

  Scenario: DELETE returns 401 and 403 for auth errors
    Given I GET a real product rule id and save it as RealProductRuleId
    And I delete all existing product rule groups for saved product rule RealProductRuleId and name DeleteAuthGroup
    And I POST a new product rule group specifying the following properties
      | product_rule_id | RealProductRuleId |
      | name            | DeleteAuthGroup   |
    Then the response should include the new product rule group
    And I save this product rule group id as DeleteAuthGroupId

    Given I set the context product rule group id to DeleteAuthGroupId
    And I do not include the ENOC session header
    And I expect the next API call to return a status code of 401 and message of "Unauthorized"
    When I DELETE my product rule group
    Then the expected status should be returned

    Given I set the context product rule group id to DeleteAuthGroupId
    And I do not include the API key header
    And I expect the next API call to return a status code of 403 and message of "Forbidden"
    When I DELETE my product rule group
    Then the expected status should be returned

    Given I set the context product rule group id to DeleteAuthGroupId
    * I send a valid API key
    * I send a valid enoc_session
    Then I DELETE my product rule group


  #
  # PUT /productrulegroups/{id}/fragments
  #
  Scenario: PUT fragments links fragments to a product rule group
    Given I GET a real product rule id and save it as RealProductRuleId
    And I delete all existing product rule groups for saved product rule RealProductRuleId and name FragmentLinkGroup
    And I POST a new product rule group specifying the following properties
      | product_rule_id | RealProductRuleId  |
      | name            | FragmentLinkGroup  |
    Then the response should include the new product rule group
    And I save this product rule group id as FragmentLinkGroupId

    # Assume fragment ids 1,2 exist
    Given I set the context product rule group id to FragmentLinkGroupId
    And I expect the next API call to return a status code of 200 and details of "OK"
    When I PUT fragments "1 2" for the current product rule group
    Then the PUT fragments expected status should be returned

    When I GET the product rule group by id
    Then GET product rule group should return the current state

    # Now unlink by sending empty array
    Given I set the context product rule group id to FragmentLinkGroupId
    And I expect the next API call to return a status code of 200 and details of "OK"
    When I PUT fragments " " for the current product rule group
    Then the PUT fragments expected status should be returned

    # Verify via GET that fragments list is empty
    When I GET the product rule group by id
    Then GET product rule group should return the current state
    And the product rule group should include no fragments

    Given I set the context product rule group id to FragmentLinkGroupId
    When I DELETE my product rule group


  Scenario: PUT fragments returns 404 when product rule group does not exist
    Given I set the context product rule group ID to 99999999
    And I expect the next API call to return a status code of 404 and message of "Not Found"
    When I PUT fragments "1 2" for the current product rule group
    Then the PUT fragments expected status should be returned


  Scenario: PUT fragments returns 404 when any fragment does not exist
    Given I GET a real product rule id and save it as RealProductRuleId
    And I delete all existing product rule groups for saved product rule RealProductRuleId and name Fragment404Group
    And I POST a new product rule group specifying the following properties
      | product_rule_id | RealProductRuleId |
      | name            | Fragment404Group  |
    Then the response should include the new product rule group
    And I save this product rule group id as Fragment404GroupId

    Given I set the context product rule group id to Fragment404GroupId
    And I expect the next API call to return a status code of 404 and message of "Not Found"
    When I PUT fragments "99999999" for the current product rule group
    Then the PUT fragments expected status should be returned

    Given I set the context product rule group id to Fragment404GroupId
    When I DELETE my product rule group


  Scenario: PUT fragments returns 400 when more than 200 fragments specified
    Given I GET a real product rule id and save it as RealProductRuleId
    And I delete all existing product rule groups for saved product rule RealProductRuleId and name FragmentTooManyGroup
    And I POST a new product rule group specifying the following properties
      | product_rule_id | RealProductRuleId    |
      | name            | FragmentTooManyGroup |
    Then the response should include the new product rule group
    And I save this product rule group id as FragmentTooManyGroupId

    Given I set the context product rule group id to FragmentTooManyGroupId
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I PUT 201 fragments for the current product rule group expecting HTTP status 400
    Then the PUT fragments expected status should be returned


  Scenario: PUT fragments returns 400 when pr_fragment_id is not a number
    Given I GET a real product rule id and save it as RealProductRuleId
    And I delete all existing product rule groups for saved product rule RealProductRuleId and name FragmentInvalidIdGroup
    And I POST a new product rule group specifying the following properties
      | product_rule_id | RealProductRuleId      |
      | name            | FragmentInvalidIdGroup |
    Then the response should include the new product rule group
    And I save this product rule group id as FragmentInvalidIdGroupId

    Given I set the context product rule group id to FragmentInvalidIdGroupId
    And I expect the next API call to return a status code of 400 and message of "Bad Request"
    When I PUT fragments body with non-numeric fragment id for the current product rule group
    Then the PUT fragments expected status should be returned

    Given I set the context product rule group id to FragmentInvalidIdGroupId
    When I DELETE my product rule group