Feature: CRUD for product rule fragments

  # Uses /api/v1/productrulefragments endpoints.
  # Covers:
  # - GET all (200, auth errors)
  # - GET by id (200, 400 invalid id, 404 missing, auth errors)
  # - POST create (201, 400 validation, 409 duplicate, auth errors)
  # - PUT update (200, 400 validation, 409 duplicate, 404 missing, auth errors)
  # - DELETE (204 success, 400 in use / invalid id type, 404 missing, auth errors)

  Background:
    Given I start with an empty context
    And I log in as a settlement API admin

  #
  # Happy‑path CRUD
  #
  Scenario: Full CRUD lifecycle for product rule fragment
    Given I delete all existing product rule fragments with name TestFragment1
    And I delete all existing product rule fragments with name TestFragment1Updated

    # POST -> 201
    When I POST a new product rule fragment specifying the following properties
      | name        | TestFragment1        |
      | description | string               |
      | validator   | {"min":1,"max":5}    |
    Then the response should include the new product rule fragment
    And the product rule fragment response should contain fields
      | id                    |
      | name                  |
      | description           |
      | validator             |
      | last_updated_dttm_utc |
      | last_updated_by       |

    # GET by id -> 200
    When I GET the product rule fragment by id
    Then GET product rule fragment should return the current state

    # GET all -> 200 and list contains our fragment
    When I GET all product rule fragments
    Then the product rule fragments list should contain my fragment

    # PUT -> 200, change name/description/validator/last_updated_by
    When I update the product rule fragment with new values
      | name        | TestFragment1Updated  |
      | description | text                   |
      | validator   | {"min":10,"max":50}    |
    Then the response should include the updated product rule fragment
    And GET product rule fragment should return the current state

    # DELETE -> 204
    When I DELETE my product rule fragment

    # GET after delete -> 404
    Given I expect the next API call to return a status code of 404 and details of "Product Rule Fragment not found"
    When I GET the product rule fragment by id
    Then the expected status should be returned

  #
  # Auth and basic GET /productrulefragments
  #
  Scenario: GET all product rule fragments returns 200
    When I GET all product rule fragments
    Then the product rule fragments list should be returned

  Scenario: GET all fails with 401 if ENOC session is missing
    Given I do not include the ENOC session header
    And I expect the next API call to return a status code of 401 and message of "Unauthorized"
    When I GET all product rule fragments
    Then the expected status should be returned

  Scenario: GET all fails with 403 if API key is missing
    Given I do not include the API key header
    And I expect the next API call to return a status code of 403 and message of "Forbidden"
    When I GET all product rule fragments
    Then the expected status should be returned

  Scenario: GET all succeeds with enel-x-trace-id header
    Given I set the enel-x-trace-id header to 8471beed-18bd-40a7-bcc9-6e0813b9526c
    When I GET all product rule fragments
    Then the product rule fragments list should be returned

  #
  # GET /productrulefragments/{id}
  #
  Scenario: GET by id returns 200 for existing fragment
    Given I delete all existing product rule fragments with name GetByIdFragment
    And I POST a new product rule fragment specifying the following properties
      | name        | GetByIdFragment      |
      | description | string               |
      | validator   | {}                   |
    Then the response should include the new product rule fragment
    And I save this product rule fragment id as GetByIdFragmentId

    Given I set the context product rule fragment id to GetByIdFragmentId
    When I GET the product rule fragment by id
    Then GET product rule fragment should return the current state

  Scenario: GET by id fails with 401 if ENOC session is missing
    Given I set the context product rule fragment id to random valid id
    And I do not include the ENOC session header
    And I expect the next API call to return a status code of 401 and message of "Unauthorized"
    When I GET the product rule fragment by id
    Then the expected status should be returned

  Scenario: GET by id fails with 403 if API key is missing
    Given I set the context product rule fragment id to random valid id
    And I do not include the API key header
    And I expect the next API call to return a status code of 403 and message of "Forbidden"
    When I GET the product rule fragment by id
    Then the expected status should be returned

  Scenario: GET by id fails with 400 if id is not numeric
    Given I set the context product rule fragment ID to non-numeric
    And I expect the next API call to return a status code of 400 and details of "Invalid id parameter: must be a number"
    When I GET the product rule fragment by id
    Then the expected status should be returned

  Scenario: GET by id fails with 404 if fragment does not exist
    Given I set the context product rule fragment ID to 99999999
    And I expect the next API call to return a status code of 404 and details of "Product Rule Fragment not found"
    When I GET the product rule fragment by id
    Then the expected status should be returned

  #
  # POST validations (201, 400, 409, auth)
  #
  Scenario: POST creates product rule fragment
    Given I delete all existing product rule fragments with name SCHEDULE_2
    When I POST a new product rule fragment specifying the following properties
      | name        | SCHEDULE_2           |
      | description | test                 |
      | validator   | {"min":1,"max":99}   |
    Then the response should include the new product rule fragment

  Scenario: POST fails with 401 if ENOC session is missing
    Given I do not include the ENOC session header
    And I expect the next API call to return a status code of 401 and message of "Unauthorized"
    When I POST a new product rule fragment specifying the following properties
      | name        | AuthFragment1        |
      | description | string               |
      | validator   | {}                   |
    Then the expected status should be returned

  Scenario: POST fails with 403 if API key is missing
    Given I do not include the API key header
    And I expect the next API call to return a status code of 403 and message of "Forbidden"
    When I POST a new product rule fragment specifying the following properties
      | name        | AuthFragment2        |
      | description | string               |
      | validator   | {}                   |
    Then the expected status should be returned

  Scenario: POST returns 400 when required fields missing or invalid
    Given I expect the next API call to return a status code of 400 and details of "The request failed validation"
    When I POST a new product rule fragment specifying the following properties
      | description | string               |
      | validator   | {}                   |
    Then the expected status should be returned

    Given I expect the next API call to return a status code of 400 and details of "The request failed validation"
    When I POST a new product rule fragment specifying the following properties
      | name        | MissingDescriptionFragment |
      | validator   | {}                         |
    Then the expected status should be returned

    Given I expect the next API call to return a status code of 400 and details of "The request failed validation"
    When I POST a new product rule fragment specifying the following properties
      | name        | MissingDescriptionFragment |
      | description | test99                     |
    Then the expected status should be returned

    # incorrect values for mandatory fields
    Given I expect the next API call to return a status code of 400 and details of "The request failed validation"
    When I POST a new product rule fragment specifying the following properties
      | description | 99                  |
      | name        | name                |
      | validator   | {}                  |
    Then the expected status should be returned

    Given I expect the next API call to return a status code of 400 and details of "The request failed validation"
    When I POST a new product rule fragment specifying the following properties
      | description | string              |
      | name        | 10                  |
      | validator   | {}                  |
    Then the expected status should be returned

    Given I expect the next API call to return a status code of 400 and details of "The request failed validation"
    When I POST a new product rule fragment specifying the following properties
      | name        | MissingDescriptionFragment |
      | description | test                       |
      | validator   | 99                         |
    Then the expected status should be returned

    # empty values for mandatory fields
    Given I expect the next API call to return a status code of 400 and details of "not allowed to be empty"
    When I POST a new product rule fragment specifying the following properties
      | description |                      |
      | name        | name                 |
      | validator   | {}                   |
    Then the expected status should be returned

    Given I expect the next API call to return a status code of 400 and details of "not allowed to be empty"
    When I POST a new product rule fragment specifying the following properties
      | description | string               |
      | name        |                      |
      | validator   | {}                   |
    Then the expected status should be returned

    Given I expect the next API call to return a status code of 400 and details of "failed validation"
    When I POST a new product rule fragment specifying the following properties
      | name        | MissingDescriptionFragment |
      | description | test                       |
      | validator   |                            |
    Then the expected status should be returned

    Given I expect the next API call to return a status code of 400 and details of "not allowed"
    When I POST a new product rule fragment specifying the following properties
      | name        | EmptyNameFragment     |
      | description | string                |
      | validator   | {}                    |
      | extra       | not-allowed           |
    Then the expected status should be returned

  Scenario: POST returns 400 when validator is not an object
    Given I expect the next API call to return a status code of 400 and details of "failed"
    When I POST a new product rule fragment specifying the following properties
      | name        | BadValidatorFragment |
      | description | string               |
      | validator   | 99                   |
    Then the expected status should be returned

  Scenario: POST returns 409 when name already exists
    Given I delete all existing product rule fragments with name DuplicateFragment
    And I POST a new product rule fragment specifying the following properties
      | name        | DuplicateFragment    |
      | description | string               |
      | validator   | {}                   |
    Then the response should include the new product rule fragment

    # Second POST with same name -> 409
    Given I expect the next API call to return a status code of 409 and details of "already exists"
    When I POST a new product rule fragment specifying the following properties
      | name        | DuplicateFragment    |
      | description | string               |
      | validator   | {}                   |
    Then the expected status should be returned

  #
  # PUT validations
  #
  Scenario: PUT returns 404 when fragment does not exist
    Given I set the context product rule fragment ID to 99999999
    And I expect the next API call to return a status code of 404 and details of "not found"
    When I update the product rule fragment with new values
      | name        | MissingFragment      |
      | description | string               |
      | validator   | {}                   |
    Then the expected status should be returned

  Scenario: PUT returns 400 when id is not numeric
    Given I set the context product rule fragment ID to non-numeric
    And I expect the next API call to return a status code of 400 and details of "number"
    When I update the product rule fragment with new values
      | name        | NonNumericIdFragment |
      | description | string               |
      | validator   | {}                   |
    Then the expected status should be returned

  Scenario: PUT returns 400 when mandatory body fields - name/description/validator are empty
    Given I delete all existing product rule fragments with name InvalidPutFragment
    And I POST a new product rule fragment specifying the following properties
      | name        | InvalidPutFragment   |
      | description | string               |
      | validator   | {}                   |
    Then the expected status should be returned

    And I expect the next API call to return a status code of 400 and details of "not allowed to be empty"
    When I update the product rule fragment with new values
      | name        |                      |
      | description | string               |
      | validator   | {}                   |
    Then the expected status should be returned

    Given I delete all existing product rule fragments with name InvalidPutFragment
    And I POST a new product rule fragment specifying the following properties
      | name        | InvalidPutFragment   |
      | description | string               |
      | validator   | {}                   |
    Then the expected status should be returned

    And I expect the next API call to return a status code of 400 and details of "not allowed to be empty"
    When I update the product rule fragment with new values
      | name        | InvalidPutFragment1  |
      | description |                      |
      | validator   | {}                   |
    Then the expected status should be returned

    Given I delete all existing product rule fragments with name InvalidPutFragment
    And I POST a new product rule fragment specifying the following properties
      | name        | InvalidPutFragment   |
      | description | string               |
      | validator   | {}                   |
    Then the expected status should be returned

    And I expect the next API call to return a status code of 400 and details of "failed validation"
    When I update the product rule fragment with new values
      | name        | InvalidPutFragment1  |
      | description | string               |
      | validator   |                      |
    Then the expected status should be returned

  Scenario: PUT returns 400 when mandatory body fields are incorrect
    Given I delete all existing product rule fragments with name InvalidPutFragment
    And I POST a new product rule fragment specifying the following properties
      | name        | InvalidPutFragment   |
      | description | string               |
      | validator   | {}                   |
    Then the expected status should be returned

    And I expect the next API call to return a status code of 400 and details of "failed validation"
    When I update the product rule fragment with new values
      | name        | 99                   |
      | description | string               |
      | validator   | {}                   |
    Then the expected status should be returned

    Given I delete all existing product rule fragments with name InvalidPutFragment
    And I POST a new product rule fragment specifying the following properties
      | name        | InvalidPutFragment   |
      | description | string               |
      | validator   | {}                   |
    Then the expected status should be returned

    And I expect the next API call to return a status code of 400 and details of "failed validation"
    When I update the product rule fragment with new values
      | name        | InvalidPutFragment1  |
      | description | 0999292929           |
      | validator   | {}                   |
    Then the expected status should be returned

    Given I delete all existing product rule fragments with name InvalidPutFragment
    And I POST a new product rule fragment specifying the following properties
      | name        | InvalidPutFragment   |
      | description | string               |
      | validator   | {}                   |
    Then the expected status should be returned

    And I expect the next API call to return a status code of 400 and details of "failed validation"
    When I update the product rule fragment with new values
      | name        | InvalidPutFragment1  |
      | description | string               |
      | validator   | 567887678            |
    Then the expected status should be returned

  Scenario: PUT returns 409 when new name collides with existing fragment
    # Create two fragments with distinct names
    Given I delete all existing product rule fragments with name FragmentA
    And I delete all existing product rule fragments with name FragmentB

    When I POST a new product rule fragment specifying the following properties
      | name        | FragmentA            |
      | description | string               |
      | validator   | {}                   |
    Then the response should include the new product rule fragment

    When I POST a new product rule fragment specifying the following properties
      | name        | FragmentB            |
      | description | string               |
      | validator   | {}                   |
    Then the response should include the new product rule fragment
    And I save this product rule fragment id as FragmentBId

    # Attempt to rename FragmentB -> FragmentA -> 409
    Given I set the context product rule fragment id to FragmentBId
    And I expect the next API call to return a status code of 409 and details of "already exists"
    When I update the product rule fragment with new values
      | name        | FragmentA           |
      | description | string              |
      | validator   | {}                  |
    Then the expected status should be returned

  Scenario: PUT returns 401 and 403 for auth errors
    Given I delete all existing product rule fragments with name PutAuthFragment
    And I POST a new product rule fragment specifying the following properties
      | name        | PutAuthFragment     |
      | description | string              |
      | validator   | {}                  |
    Then the response should include the new product rule fragment

    And I save this product rule fragment id as PutAuthFragmentId

    # 401
    Given I set the context product rule fragment id to PutAuthFragmentId
    And I do not include the ENOC session header
    And I expect the next API call to return a status code of 401 and message of "Unauthorized"
    When I update the product rule fragment with new values
      | name        | PutAuthFragment-401 |
      | description | string              |
      | validator   | {}                  |
    Then the expected status should be returned

    # 403
    Given I set the context product rule fragment id to PutAuthFragmentId
    And I do not include the API key header
    And I expect the next API call to return a status code of 403 and message of "Forbidden"
    When I update the product rule fragment with new values
      | name        | PutAuthFragment-403 |
      | description | string              |
      | validator   | {}                  |
    Then the expected status should be returned

  #
  # DELETE validations
  #
  Scenario: DELETE returns 204 when fragment exists
    Given I delete all existing product rule fragments with name DeletableFragment
    And I POST a new product rule fragment specifying the following properties
      | name        | DeletableFragment   |
      | description | string              |
      | validator   | {}                  |
    Then the response should include the new product rule fragment
    And I save this product rule fragment id as DeletableFragmentId

    Given I set the context product rule fragment id to DeletableFragmentId
    When I DELETE my product rule fragment

    Given I expect the next API call to return a status code of 404 and details of "Product Rule Fragment not found"
    When I GET the product rule fragment by id
    Then the expected status should be returned

  Scenario: DELETE returns 404 when fragment does not exist
    Given I set the context product rule fragment ID to 99999999
    And I expect the next API call to return a status code of 404 and details of "not found"
    When I DELETE my product rule fragment
    Then the expected status should be returned

  Scenario: DELETE returns 400 when id is not numeric
    Given I set the context product rule fragment ID to non-numeric
    And I expect the next API call to return a status code of 400 and details of "must be a number"
    When I DELETE my product rule fragment
    Then the expected status should be returned

  Scenario: DELETE returns 401 and 403 for auth errors
    Given I delete all existing product rule fragments with name DeleteAuthFragment
    And I POST a new product rule fragment specifying the following properties
      | name        | DeleteAuthFragment  |
      | description | string              |
      | validator   | {}                  |
    Then the response should include the new product rule fragment
    And I save this product rule fragment id as DeleteAuthFragmentId

    # 401
    Given I set the context product rule fragment id to DeleteAuthFragmentId
    And I do not include the ENOC session header
    And I expect the next API call to return a status code of 401 and message of "Unauthorized"
    When I DELETE my product rule fragment
    Then the expected status should be returned

    # 403
    Given I set the context product rule fragment id to DeleteAuthFragmentId
    And I do not include the API key header
    And I expect the next API call to return a status code of 403 and message of "Forbidden"
    When I DELETE my product rule fragment
    Then the expected status should be returned

  #
  # PUT /product-rule-fragments/{fragment_id}/parameters
  #
  Scenario: Create a product rule fragment and link parameters to it and the delete it, unlinking parameters first
    Given I generate a random product rule fragment name and save it as ParamLinkFragmentName
    And I delete all existing product rule fragments with name ParamLinkFragmentName
    And I POST a new product rule fragment specifying the following properties
      | name        | ParamLinkFragmentName |
      | description | string                |
      | validator   | {}                    |
    Then the response should include the new product rule fragment
    And I save this product rule fragment id as ParamLinkFragmentId

  # Link parameters
    And I set the context product rule fragment id to ParamLinkFragmentId
    And I expect the next API call to return a status code of 200 and details of "OK"
    When I PUT parameters "1,true 2,true" for the current product rule fragment
    Then the PUT parameters expected status should be returned

  # Try to delete while parameters are linked -> expect 400
    And I set the context product rule fragment id to ParamLinkFragmentId
    And I expect the next API call to return a status code of 400 and message of "Bad request"
    When I delete the current product rule fragment

  # Unlink parameters by sending empty array
    And I set the context product rule fragment id to ParamLinkFragmentId
    And I expect the next API call to return a status code of 200 and details of "OK"
    When I PUT parameters "EMPTY" for the current product rule fragment
    Then the PUT parameters expected status should be returned
    And I GET the product rule fragment by id including parameters
    Then the GET response should include an empty product_rule_parameter_ids array

  # Now delete should succeed -> expect 200
    And I set the context product rule fragment id to ParamLinkFragmentId
    And I expect the next API call to return a status code of 204 and details of "OK"
    When I delete the current product rule fragment


  Scenario: PUT parameters links a fragment to the given parameters
    Given I generate a random product rule fragment name and save it as ParamLinkFragmentName
    And I POST a new product rule fragment specifying the following properties
      | name        | ParamLinkFragmentName   |
      | description | string               |
      | validator   | {}                   |
    Then the response should include the new product rule fragment
    And I save this product rule fragment id as ParamLinkFragmentId

    # Assume parameter ids 1,2 exist
    And I set the context product rule fragment id to ParamLinkFragmentId
    And I expect the next API call to return a status code of 200 and details of "OK"
    When I PUT parameters "1,true 2,true" for the current product rule fragment
    Then the PUT parameters expected status should be returned

    # GET with include_parameters=true should show product_rule_parameter_ids
    Given I set the context product rule fragment id to ParamLinkFragmentId
    When I GET the product rule fragment by id including parameters
    Then the product rule fragment should include parameter ids
      | 1 |
      | 2 |

  Scenario: PUT parameters returns 404 when fragment does not exist
    Given I set the context product rule fragment ID to 99999999
    And I expect the next API call to return a status code of 404 and message of "not found"
    When I PUT parameters "1,true 2,true" for the current product rule fragment
    Then the PUT parameters expected status should be returned

  Scenario: PUT parameters returns 404 when any parameter does not exist
    Given I delete all existing product rule fragments with name ParamLinkFragment404
    And I POST a new product rule fragment specifying the following properties
      | name        | ParamLinkFragment404 |
      | description | string               |
      | validator   | {}                   |
    Then the response should include the new product rule fragment
    And I save this product rule fragment id as ParamLinkFragment404Id

    And I set the context product rule fragment id to ParamLinkFragment404Id
    And I expect the next API call to return a status code of 404 and message of "ids do not exist"
    When I PUT parameters "99999999,true" for the current product rule fragment
    Then the PUT parameters expected status should be returned

  Scenario: PUT parameters returns 400 when more than 200 parameters specified
    Given I delete all existing product rule fragments with name ParamLinkFragmentTooMany
    And I POST a new product rule fragment specifying the following properties
      | name        | ParamLinkFragmentTooMany |
      | description | string                   |
      | validator   | {}                       |
    Then the response should include the new product rule fragment
    And I save this product rule fragment id as ParamLinkTooManyId

    And I set the context product rule fragment id to ParamLinkTooManyId
    # 400 if > 200; here we send 201 ids
    And I expect the next API call to return a status code of 400 and message of "Cannot update more than 200 parameters at once"
    When I PUT 201 parameters for the current product rule fragment expecting HTTP status 400
    Then the PUT parameters expected status should be returned

  Scenario: PUT parameters with empty array clears product_rule_parameter_ids
    Given I delete all existing product rule fragments with name EmptyParamsFragment
    And I POST a new product rule fragment specifying the following properties
      | name        | EmptyParamsFragment |
      | description | test                |
      | validator   | {"test":"test2"}    |
    Then the response should include the new product rule fragment
    And I save this product rule fragment id as EmptyParamsFragmentId

    And I set the context product rule fragment id to EmptyParamsFragmentId
    And I expect the next API call to return a status code of 200 and message of "OK"
    When I PUT parameters "EMPTY" for the current product rule fragment
    Then the PUT parameters expected status should be returned

    When I GET the product rule fragment by id including parameters
    Then the GET response should include an empty product_rule_parameter_ids array

  Scenario: GET product rule fragment with non-boolean include_parameters returns 400
    Given I delete all existing product rule fragments with name ParamLinkFragmentBadInclude
    And I POST a new product rule fragment specifying the following properties
      | name        | ParamLinkFragmentBadInclude |
      | description | string                      |
      | validator   | {}                          |
    Then the response should include the new product rule fragment
    And I save this product rule fragment id as ParamLinkBadIncludeId

    Given I set the context product rule fragment id to ParamLinkBadIncludeId
    And I expect the next API call to return a status code of 400 and details of "The request failed validation"
    When I GET the product rule fragment by id including parameters value "test"
    Then the expected status should be returned
