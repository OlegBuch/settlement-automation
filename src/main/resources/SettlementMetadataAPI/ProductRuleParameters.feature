Feature: CRUD for product rule parameters

  # Uses /api/v1/product-rule-parameters endpoints.
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
  Scenario: Full CRUD lifecycle for product rule parameter
    Given I delete all existing product rule parameters with name TestParam1
    And I delete all existing product rule parameters with name TestParam1Updated

    # POST -> 201
    When I POST a new product rule parameter specifying the following properties
      | name            | TestParam1        |
      | type            | string            |
      | validator       | {"min":1,"max":5} |
    Then the response should include the new product rule parameter
    And the product rule parameter response should contain fields
      | id                    |
      | name                  |
      | type                  |
      | validator             |
      | last_updated_dttm_utc |
      | last_updated_by       |

    # GET by id -> 200
    When I GET the product rule parameter by id
    Then GET product rule parameter should return the current state

    # GET all -> 200 and list contains our parameter
    When I GET all product rule parameters
    Then the product rule parameters list should contain my parameter

    # PUT -> 200, change name/type/validator/last_updated_by
    When I update the product rule parameter with new values
      | name            | TestParam1Updated     |
      | type            | text                  |
      | validator       | {"min":10,"max":50}   |
    Then the response should include the updated product rule parameter
    And GET product rule parameter should return the current state

    # DELETE -> 204
    When I DELETE my product rule parameter

    # GET after delete -> 404
    Given I expect the next API call to return a status code of 404 and details of "Product Rule Parameter not found"
    When I GET the product rule parameter by id
    Then the expected status should be returned

  #
  # Auth and basic GET /product-rule-parameters
  #
  Scenario: GET all product rule parameters returns 200
    When I GET all product rule parameters
    Then the product rule parameters list should be returned

  Scenario: GET all fails with 401 if ENOC session is missing
    Given I do not include the ENOC session header
    And I expect the next API call to return a status code of 401 and message of "Unauthorized"
    When I GET all product rule parameters
    Then the expected status should be returned

  Scenario: GET all fails with 403 if API key is missing
    Given I do not include the API key header
    And I expect the next API call to return a status code of 403 and message of "Forbidden"
    When I GET all product rule parameters
    Then the expected status should be returned

  Scenario: GET all succeeds with enel-x-trace-id header
    Given I set the enel-x-trace-id header to 8471beed-18bd-40a7-bcc9-6e0813b9526c
    When I GET all product rule parameters
    Then the product rule parameters list should be returned

  #
  # GET /product-rule-parameters/{id}
  #
  Scenario: GET by id returns 200 for existing parameter
    Given I delete all existing product rule parameters with name GetByIdParam
    And I POST a new product rule parameter specifying the following properties
      | name            | GetByIdParam      |
      | type            | string            |
      | validator       | {}                |
    Then the response should include the new product rule parameter
    And I save this product rule parameter id as GetByIdParamId

    Given I set the context product rule parameter id to GetByIdParamId
    When I GET the product rule parameter by id
    Then GET product rule parameter should return the current state

  Scenario: GET by id fails with 401 if ENOC session is missing
    Given I set the context product rule parameter id to random valid id
    And I do not include the ENOC session header
    And I expect the next API call to return a status code of 401 and message of "Unauthorized"
    When I GET the product rule parameter by id
    Then the expected status should be returned

  Scenario: GET by id fails with 403 if API key is missing
    Given I set the context product rule parameter id to random valid id
    And I do not include the API key header
    And I expect the next API call to return a status code of 403 and message of "Forbidden"
    When I GET the product rule parameter by id
    Then the expected status should be returned

  Scenario: GET by id fails with 400 if id is not numeric
    Given I set the context product rule parameter ID to non-numeric
    And I expect the next API call to return a status code of 400 and details of "Invalid id parameter: must be a number"
    When I GET the product rule parameter by id
    Then the expected status should be returned

  Scenario: GET by id fails with 404 if parameter does not exist
    Given I set the context product rule parameter ID to 99999999
    And I expect the next API call to return a status code of 404 and details of "Product Rule Parameter not found"
    When I GET the product rule parameter by id
    Then the expected status should be returned

  #
  # POST validations (201, 400, 409, auth)
  #
  Scenario: POST creates product rule parameter
    Given I delete all existing product rule parameters with name SCHEDULE_2
    When I POST a new product rule parameter specifying the following properties
      | name            | SCHEDULE_2         |
      | type            | test                  |
      | validator       | {"min":1,"max":99} |
    Then the response should include the new product rule parameter

  Scenario: POST fails with 401 if ENOC session is missing
    Given I do not include the ENOC session header
    And I expect the next API call to return a status code of 401 and message of "Unauthorized"
    When I POST a new product rule parameter specifying the following properties
      | name            | AuthParam1         |
      | type            | string            |
      | validator       | {}                |
    Then the expected status should be returned

  Scenario: POST fails with 403 if API key is missing
    Given I do not include the API key header
    And I expect the next API call to return a status code of 403 and message of "Forbidden"
    When I POST a new product rule parameter specifying the following properties
      | name            | AuthParam2         |
      | type            | string            |
      | validator       | {}                |
    Then the expected status should be returned

  Scenario: POST returns 400 when required fields missing or invalid
    Given I expect the next API call to return a status code of 400 and details of "The request failed validation"
    When I POST a new product rule parameter specifying the following properties
      | type            | string            |
      | validator       | {}                |
    Then the expected status should be returned

    Given I expect the next API call to return a status code of 400 and details of "The request failed validation"
    When I POST a new product rule parameter specifying the following properties
      | name            | MissingTypeParam  |
      | validator       | {}                |
    Then the expected status should be returned

    Given I expect the next API call to return a status code of 400 and details of "The request failed validation"
    When I POST a new product rule parameter specifying the following properties
      | name            | MissingTypeParam  |
      | type            | test99            |
    Then the expected status should be returned

    # incorrect values for mandatory fields
    Given I expect the next API call to return a status code of 400 and details of "The request failed validation"
    When I POST a new product rule parameter specifying the following properties
      | type            | 99            |
      | name            | name                   |
      | validator       | {}                |
    Then the expected status should be returned

    Given I expect the next API call to return a status code of 400 and details of "The request failed validation"
    When I POST a new product rule parameter specifying the following properties
      | type            | string            |
      | name            | 10  |
      | validator       | {}                |
    Then the expected status should be returned

    Given I expect the next API call to return a status code of 400 and details of "The request failed validation"
    When I POST a new product rule parameter specifying the following properties
      | name            | MissingTypeParam  |
      | type            | test            |
      | validator       | 99                |
    Then the expected status should be returned

    #empty values for mandatory fields
    Given I expect the next API call to return a status code of 400 and details of "not allowed to be empty"
    When I POST a new product rule parameter specifying the following properties
      | type            |             |
      | name            | name                   |
      | validator       | {}                |
    Then the expected status should be returned

    Given I expect the next API call to return a status code of 400 and details of "not allowed to be empty"
    When I POST a new product rule parameter specifying the following properties
      | type            | string            |
      | name            |                   |
      | validator       | {}                |
    Then the expected status should be returned

    Given I expect the next API call to return a status code of 400 and details of "failed validation"
    When I POST a new product rule parameter specifying the following properties
      | name            | MissingTypeParam  |
      | type            | test            |
      | validator       |                |
    Then the expected status should be returned

    Given I expect the next API call to return a status code of 400 and details of "not allowed"
    When I POST a new product rule parameter specifying the following properties
      | name            | EmptyNameParam    |
      | type            | string            |
      | validator       | {}                |
      | extra           | not-allowed       |
    Then the expected status should be returned

  Scenario: POST returns 400 when validator is not an object
    Given I expect the next API call to return a status code of 400 and details of "failed"
    When I POST a new product rule parameter specifying the following properties
      | name            | BadValidatorParam |
      | type            | string            |
      | validator       | 99                |
    Then the expected status should be returned

  Scenario: POST returns 409 when name already exists
    Given I delete all existing product rule parameters with name DuplicateParam
    And I POST a new product rule parameter specifying the following properties
      | name            | DuplicateParam    |
      | type            | string            |
      | validator       | {}                |
    Then the response should include the new product rule parameter

    # Second POST with same name -> 409
    Given I expect the next API call to return a status code of 409 and details of "already exists"
    When I POST a new product rule parameter specifying the following properties
      | name            | DuplicateParam    |
      | type            | string            |
      | validator       | {}                |
    Then the expected status should be returned

  #
  # PUT validations
  #
  Scenario: PUT returns 404 when parameter does not exist
    Given I set the context product rule parameter ID to 99999999
    And I expect the next API call to return a status code of 404 and details of "not found"
    When I update the product rule parameter with new values
      | name            | MissingParam      |
      | type            | string            |
      | validator       | {}                |
    Then the expected status should be returned

  Scenario: PUT returns 400 when id is not numeric
    Given I set the context product rule parameter ID to non-numeric
    And I expect the next API call to return a status code of 400 and details of "number"
    When I update the product rule parameter with new values
      | name            | NonNumericIdParam |
      | type            | string            |
      | validator       | {}                |
    Then the expected status should be returned

  Scenario: PUT returns 400 when mandatory body fields - name/type/validator are empty
    Given I delete all existing product rule parameters with name InvalidPutParam
    And I POST a new product rule parameter specifying the following properties
      | name            | InvalidPutParam   |
      | type            | string            |
      | validator       | {}                |
    Then the expected status should be returned

    And I expect the next API call to return a status code of 400 and details of "not allowed to be empty"
    When I update the product rule parameter with new values
      | name            |                   |
      | type            | string            |
      | validator       | {}                |
    Then the expected status should be returned

    Given I delete all existing product rule parameters with name InvalidPutParam
    And I POST a new product rule parameter specifying the following properties
      | name            | InvalidPutParam   |
      | type            | string            |
      | validator       | {}                |
    Then the expected status should be returned

    And I expect the next API call to return a status code of 400 and details of "not allowed to be empty"
    When I update the product rule parameter with new values
      | name            |    InvalidPutParam1               |
      | type            |             |
      | validator       | {}                |
    Then the expected status should be returned

    Given I delete all existing product rule parameters with name InvalidPutParam
    And I POST a new product rule parameter specifying the following properties
      | name            | InvalidPutParam   |
      | type            | string            |
      | validator       | {}                |
    Then the expected status should be returned

    And I expect the next API call to return a status code of 400 and details of "failed validation"
    When I update the product rule parameter with new values
      | name            |    InvalidPutParam1               |
      | type            |       string      |
      | validator       |                 |
    Then the expected status should be returned


  Scenario: PUT returns 400 when mandatory body fields - are incorrect
    Given I delete all existing product rule parameters with name InvalidPutParam
    And I POST a new product rule parameter specifying the following properties
      | name            | InvalidPutParam   |
      | type            | string            |
      | validator       | {}                |
    Then the expected status should be returned

    And I expect the next API call to return a status code of 400 and details of "failed validation"
    When I update the product rule parameter with new values
      | name            | 99                   |
      | type            | string            |
      | validator       | {}                |
    Then the expected status should be returned

    Given I delete all existing product rule parameters with name InvalidPutParam
    And I POST a new product rule parameter specifying the following properties
      | name            | InvalidPutParam   |
      | type            | string            |
      | validator       | {}                |
    Then the expected status should be returned

    And I expect the next API call to return a status code of 400 and details of "failed validation"
    When I update the product rule parameter with new values
      | name            |    InvalidPutParam1               |
      | type            |           0999292929  |
      | validator       | {}                |
    Then the expected status should be returned

    Given I delete all existing product rule parameters with name InvalidPutParam
    And I POST a new product rule parameter specifying the following properties
      | name            | InvalidPutParam   |
      | type            | string            |
      | validator       | {}                |
    Then the expected status should be returned

    And I expect the next API call to return a status code of 400 and details of "failed validation"
    When I update the product rule parameter with new values
      | name            |    InvalidPutParam1               |
      | type            |       string      |
      | validator       |          567887678       |
    Then the expected status should be returned



  Scenario: PUT returns 409 when new name collides with existing parameter
    # Create two parameters with distinct names
    Given I delete all existing product rule parameters with name ParamA
    And I delete all existing product rule parameters with name ParamB

    When I POST a new product rule parameter specifying the following properties
      | name            | ParamA            |
      | type            | string            |
      | validator       | {}                |
    Then the response should include the new product rule parameter

    When I POST a new product rule parameter specifying the following properties
      | name            | ParamB            |
      | type            | string            |
      | validator       | {}                |
    Then the response should include the new product rule parameter
    And I save this product rule parameter id as ParamBId

    # Attempt to rename ParamB -> ParamA -> 409
    Given I set the context product rule parameter id to ParamBId
    And I expect the next API call to return a status code of 409 and details of "already exists"
    When I update the product rule parameter with new values
      | name            | ParamA            |
      | type            | string            |
      | validator       | {}                |
    Then the expected status should be returned

  Scenario: PUT returns 401 and 403 for auth errors
    Given I delete all existing product rule parameters with name PutAuthParam
    And I POST a new product rule parameter specifying the following properties
      | name            | PutAuthParam      |
      | type            | string            |
      | validator       | {}                |
    Then the response should include the new product rule parameter

    And I save this product rule parameter id as PutAuthParamId

    # 401
    Given I set the context product rule parameter id to PutAuthParamId
    And I do not include the ENOC session header
    And I expect the next API call to return a status code of 401 and message of "Unauthorized"
    When I update the product rule parameter with new values
      | name            | PutAuthParam-401  |
      | type            | string            |
      | validator       | {}                |
    Then the expected status should be returned

    # 403
    Given I set the context product rule parameter id to PutAuthParamId
    And I do not include the API key header
    And I expect the next API call to return a status code of 403 and message of "Forbidden"
    When I update the product rule parameter with new values
      | name            | PutAuthParam-403  |
      | type            | string            |
      | validator       | {}                |
    Then the expected status should be returned

  #
  # DELETE validations
  #
  Scenario: DELETE returns 204 when parameter exists
    Given I delete all existing product rule parameters with name DeletableParam
    And I POST a new product rule parameter specifying the following properties
      | name            | DeletableParam    |
      | type            | string            |
      | validator       | {}                |
    Then the response should include the new product rule parameter
    And I save this product rule parameter id as DeletableParamId

    Given I set the context product rule parameter id to DeletableParamId
    When I DELETE my product rule parameter

    Given I expect the next API call to return a status code of 404 and details of "Product Rule Parameter not found"
    When I GET the product rule parameter by id
    Then the expected status should be returned


  Scenario: DELETE returns 404 when parameter does not exist
    Given I set the context product rule parameter ID to 99999999
    And I expect the next API call to return a status code of 404 and details of "not found"
    When I DELETE my product rule parameter
    Then the expected status should be returned

  Scenario: DELETE returns 400 when id is not numeric
    Given I set the context product rule parameter ID to non-numeric
    And I expect the next API call to return a status code of 400 and details of "must be a number"
    When I DELETE my product rule parameter
    Then the expected status should be returned

  Scenario: DELETE returns 401 and 403 for auth errors
    Given I delete all existing product rule parameters with name DeleteAuthParam
    And I POST a new product rule parameter specifying the following properties
      | name            | DeleteAuthParam   |
      | type            | string            |
      | validator       | {}                |
    Then the response should include the new product rule parameter
    And I save this product rule parameter id as DeleteAuthParamId

    # 401
    Given I set the context product rule parameter id to DeleteAuthParamId
    And I do not include the ENOC session header
    And I expect the next API call to return a status code of 401 and message of "Unauthorized"
    When I DELETE my product rule parameter
    Then the expected status should be returned

    # 403
    Given I set the context product rule parameter id to DeleteAuthParamId
    And I do not include the API key header
    And I expect the next API call to return a status code of 403 and message of "Forbidden"
    When I DELETE my product rule parameter
    Then the expected status should be returned
