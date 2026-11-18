Feature: CRUD for product rules

  # Uses /api/v1/productrules endpoints.
  # Covers:
  # - GET (all, one product rule)
  # - POST create (201, 400 validation, 409 conflict, auth errors)
  # - PUT update (200, 400 validation, 404 missing, 409 conflict, auth errors)
  # - DELETE (204 success, 400 in use / invalid id type, 404 missing, auth errors)
  # Note: GET /productrules and GET /productrules/{product_id} already exist.
  # Note: product_id is always a UUID string in tests.

  Background:
    Given I start with an empty context
    And I log in as a settlement API admin

  #
  # Happy‑path CRUD
  #
  Scenario: Full CRUD lifecycle for product rule
    Given I delete all existing product rules with product id 11111111-1111-1111-1111-111111111111
    And I delete all existing product rules with product id 22222222-2222-2222-2222-222222222222

    # POST -> 201
    When I POST a new product rule specifying the following properties
      | product_id | 11111111-1111-1111-1111-111111111111 |
      | name       | TestRule1                            |
    Then the response should include the new product rule
    And the product rule response should contain fields
      | product_id            |
      | name                  |
      | last_updated_dttm_utc |
      | last_updated_by       |

    # GET by product_id -> 200 (existing GET endpoint)
    When I GET the product rule by product id
    Then GET product rule should return the current state

    # GET all -> 200 and list contains our rule (existing GET endpoint)
    When I GET all product rules
    Then the product rules list should contain my rule

    # PUT -> 200, change name
    When I update the product rule with new values
      | name | TestRule1Updated |
      | product_id | 11111111-1111-1111-1111-111111111111 |

    Then the response should include the updated product rule
    And GET product rule should return the current state

    # DELETE -> 204
    When I DELETE my product rule

    # GET after delete -> 404
    Given I expect the next API call to return a status code of 404 and details of "Product Rule not found"
    When I GET the product rule by product id
    Then the expected status should be returned

  #
  # Auth and basic GET /productrules
  #
  Scenario: GET all product rules returns 200
    When I GET all product rules
    Then the product rules list should be returned

  Scenario: GET all fails with 401 if ENOC session is missing
    Given I do not include the ENOC session header
    And I expect the next API call to return a status code of 401 and message of "Unauthorized"
    When I GET all product rules
    Then the expected status should be returned

  Scenario: GET all fails with 403 if API key is missing
    Given I do not include the API key header
    And I expect the next API call to return a status code of 403 and message of "Forbidden"
    When I GET all product rules
    Then the expected status should be returned

  Scenario: GET all succeeds with enel-x-trace-id header
    Given I set the enel-x-trace-id header to 8471beed-18bd-40a7-bcc9-6e0813b9526c
    When I GET all product rules
    Then the product rules list should be returned

  #
  # POST /productrules validations (201, 400, 409, auth)
  #
  Scenario: POST creates product rule
    Given I delete all existing product rules with product id 33333333-3333-3333-3333-333333333333
    When I POST a new product rule specifying the following properties
      | product_id | 33333333-3333-3333-3333-333333333333 |
      | name       | SCHEDULE_2_RULE                       |
    Then the response should include the new product rule

  Scenario: POST fails with 401 if ENOC session is missing
    Given I do not include the ENOC session header
    And I expect the next API call to return a status code of 401 and message of "Unauthorized"
    When I POST a new product rule specifying the following properties
      | product_id | 44444444-4444-4444-4444-444444444444 |
      | name       | AuthRule1                            |
    Then the expected status should be returned

  Scenario: POST fails with 403 if API key is missing
    Given I do not include the API key header
    And I expect the next API call to return a status code of 403 and message of "Forbidden"
    When I POST a new product rule specifying the following properties
      | product_id | 55555555-5555-5555-5555-555555555555 |
      | name       | AuthRule2                            |
    Then the expected status should be returned

  Scenario: POST returns 400 when required fields missing or invalid
    # missing product_id
    Given I expect the next API call to return a status code of 400 and details of "The request failed validation"
    When I POST a new product rule specifying the following properties
      | name | MissingProductIdRule |
    Then the expected status should be returned

    # missing name
    Given I expect the next API call to return a status code of 400 and details of "The request failed validation"
    When I POST a new product rule specifying the following properties
      | product_id | 66666666-6666-6666-6666-666666666666 |
    Then the expected status should be returned

    # incorrect types (product_id not a string UUID, name not a string)
    Given I expect the next API call to return a status code of 400 and details of "The request failed validation"
    When I POST a new product rule specifying the following properties
      | product_id | 99      |
      | name       | NameOk  |
    Then the expected status should be returned

    Given I expect the next API call to return a status code of 400 and details of "The request failed validation"
    When I POST a new product rule specifying the following properties
      | product_id | 77777777-7777-7777-7777-777777777777 |
      | name       | 10                                    |
    Then the expected status should be returned

    # empty values
    Given I expect the next API call to return a status code of 400 and details of "failed validation"
    When I POST a new product rule specifying the following properties
      | product_id |                                         |
      | name       | EmptyProduct                            |
    Then the expected status should be returned

    Given I expect the next API call to return a status code of 400 and details of "not allowed to be empty"
    When I POST a new product rule specifying the following properties
      | product_id | 88888888-8888-8888-8888-888888888888 |
      | name       |                                      |
    Then the expected status should be returned

    # extra fields not allowed (last_updated_by cannot be provided)
    Given I expect the next API call to return a status code of 400 and details of "not allowed"
    When I POST a new product rule specifying the following properties
      | product_id      | 99999999-9999-9999-9999-999999999999 |
      | name            | ExtraFieldRule                        |
      | last_updated_by | not-allowed                           |
      | extra           | not-allowed                           |
    Then the expected status should be returned

  Scenario: POST returns 409 when product_id already exists
    Given I delete all existing product rules with product id 2e3110a6-c1ba-44b8-85f6-8ead85efb760
    And I POST a new product rule specifying the following properties
      | product_id | 2e3110a6-c1ba-44b8-85f6-8ead85efb760 |
      | name       | RuleA                                |
    Then the response should include the new product rule

    # Second POST with same product_id -> 409
    Given I expect the next API call to return a status code of 409 and details of "already exists"
    When I POST a new product rule specifying the following properties
      | product_id | 2e3110a6-c1ba-44b8-85f6-8ead85efb760 |
      | name       | RuleB                                |
    Then the expected status should be returned

  Scenario: POST returns 409 when name already exists
    Given I delete all existing product rules with product id 2e3110a6-c1ba-44b8-85f6-8ead85efb762
    And I POST a new product rule specifying the following properties
      | product_id | 2e3110a6-c1ba-44b8-85f6-8ead85efb762 |
      | name       | RuleD                                |
    Then the response should include the new product rule

    # Second POST with same name -> 409
    Given I expect the next API call to return a status code of 409 and details of "already exists"
    When I POST a new product rule specifying the following properties
      | product_id | 2e3110a6-c1ba-44b8-85f6-8ead85efb762 |
      | name       | RuleD                                |
    Then the expected status should be returned



  #
  # PUT /productrules/{product_id} validations
  #
  Scenario: PUT returns 404 when product rule does not exist
    Given I set the context product rule product id to 00000000-0000-0000-0000-000000000999
    And I expect the next API call to return a status code of 404 and details of "not found"
    When I update the product rule with new values
      | name | MissingRule |
      | product_id| 00000000-0000-0000-0000-000000000999 |
    Then the expected status should be returned

  Scenario: PUT returns 400 when product_id path parameter is invalid
    Given I set the context product rule product ID to non-uuid
    And I expect the next API call to return a status code of 400 and details of "The request failed validation"
    When I update the product rule with new values
      | name | NonUuidRule |
    Then the expected status should be returned

  Scenario: PUT returns 400 when mandatory body fields are empty
    Given I delete all existing product rules with product id 5c9b9879-6cb2-4d84-80c9-731e5b247d81
    And I POST a new product rule specifying the following properties
      | product_id | 5c9b9879-6cb2-4d84-80c9-731e5b247d81|
      | name       | InvalidPutRule                       |
    Then the response should include the new product rule
    And I save this product rule product id as InvalidPutProductId

    And I set the context product rule product id to InvalidPutProductId
    And I expect the next API call to return a status code of 400 and details of "not allowed to be empty"
    When I update the product rule with new values
      | name |    |
      | product_id |  5c9b9879-6cb2-4d84-80c9-731e5b247d81  |

    Then the expected status should be returned

    And I set the context product rule product id to InvalidPutProductId
    And I expect the next API call to return a status code of 400 and details of "failed validation"
    When I update the product rule with new values
      | product_id |    |
      | name | 00   |
    Then the expected status should be returned


  Scenario: PUT returns 400 when mandatory body fields are incorrect
    Given I delete all existing product rules with product id 079d3c1f-e38c-4ec1-a267-8124dd74c6f8
    And I POST a new product rule specifying the following properties
      | product_id | 079d3c1f-e38c-4ec1-a267-8124dd74c6f8 |
      | name       | InvalidPutRule2                        |
    Then the response should include the new product rule
    And I save this product rule product id as InvalidPutProductId2

    And I set the context product rule product id to InvalidPutProductId2
    And I expect the next API call to return a status code of 400 and details of "failed validation"
    When I update the product rule with new values
      | name | 99 |
      | product_id | 123123 |
    Then the expected status should be returned


  Scenario: PUT returns 409 when new product_id collides with existing rule
    # Create two rules with distinct product_ids
    Given I delete all existing product rules with product id 2e3110a6-c1ba-44b8-85f6-8ead85efb760
    And I delete all existing product rules with product id 2e3110a6-c1ba-44b8-85f6-8ead85efb761

    When I POST a new product rule specifying the following properties
      | product_id | 2e3110a6-c1ba-44b8-85f6-8ead85efb760 |
      | name       | RuleA                                |
    Then the response should include the new product rule

    When I POST a new product rule specifying the following properties
      | product_id | 2e3110a6-c1ba-44b8-85f6-8ead85efb761 |
      | name       | RuleB                                |
    Then the response should include the new product rule
    And I save this product rule product id as ProductBId

    # Attempt to change ProductB rule to use ProductA id -> 409
    Given I set the context product rule product id to 2e3110a6-c1ba-44b8-85f6-8ead85efb761
    And I expect the next API call to return a status code of 409 and details of "already exists"
    When I update the product rule with new values
      | product_id | 2e3110a6-c1ba-44b8-85f6-8ead85efb760 |
      | name       | RuleB                                |
    Then the expected status should be returned

    # Attempt to change ProductB rule to use ProductA name -> 409
    Given I set the context product rule product id to 2e3110a6-c1ba-44b8-85f6-8ead85efb761
    And I expect the next API call to return a status code of 409 and details of "already exists"
    When I update the product rule with new values
      | product_id | 2e3110a6-c1ba-44b8-85f6-8ead85efb761 |
      | name       | RuleA                                |
    Then the expected status should be returned


  Scenario: PUT returns 401 and 403 for auth errors
    Given I delete all existing product rules with product id 2e3110a6-c1ba-44b8-85f6-8ead85efb761
    And I POST a new product rule specifying the following properties
      | product_id | 2e3110a6-c1ba-44b8-85f6-8ead85efb761 |
      | name       | PutAuthRule                          |
    Then the response should include the new product rule
    And I save this product rule product id as PutAuthProductId

    # 401
    Given I set the context product rule product id to PutAuthProductId
    And I do not include the ENOC session header
    And I expect the next API call to return a status code of 401 and message of "Unauthorized"
    When I update the product rule with new values
      | name | PutAuthRule-401 |
    Then the expected status should be returned

    # 403
    Given I set the context product rule product id to PutAuthProductId
    And I do not include the API key header
    And I expect the next API call to return a status code of 403 and message of "Forbidden"
    When I update the product rule with new values
      | name | PutAuthRule-403 |
    Then the expected status should be returned

  #
  # DELETE /productrules/{product_id} validations
  #
  Scenario: DELETE returns 204 when product rule exists
    Given I delete all existing product rules with product id 12121212-1212-1212-1212-121212121212
    And I POST a new product rule specifying the following properties
      | product_id | 12121212-1212-1212-1212-121212121212 |
      | name       | DeletableRule                        |
    Then the response should include the new product rule
    And I save this product rule product id as 12121212-1212-1212-1212-121212121212

    Given I set the context product rule product id to 12121212-1212-1212-1212-121212121212
    When I DELETE my product rule

    Given I expect the next API call to return a status code of 404 and details of "Product Rule not found"
    When I GET the product rule by product id
    Then the expected status should be returned

  Scenario: DELETE returns 404 when product rule does not exist
    Given I set the context product rule product id to 00000000-0000-0000-0000-000000000999
    And I expect the next API call to return a status code of 404 and details of "not found"
    When I DELETE my product rule
    Then the expected status should be returned

  Scenario: DELETE returns 400 when product_id is invalid
    Given I set the context product rule product ID to non-uuid
    And I expect the next API call to return a status code of 400 and details of "The request failed validation"
    When I DELETE my product rule
    Then the expected status should be returned

  Scenario: DELETE returns 401 and 403 for auth errors
    Given I delete all existing product rules with product id 13131313-1313-1313-1313-131313131313
    And I POST a new product rule specifying the following properties
      | product_id | 13131313-1313-1313-1313-131313131313 |
      | name       | DeleteAuthRule                       |
    Then the response should include the new product rule
    And I save this product rule product id as DeleteAuthProductId

    # 401
    Given I set the context product rule product id to DeleteAuthProductId
    And I do not include the ENOC session header
    And I expect the next API call to return a status code of 401 and message of "Unauthorized"
    When I DELETE my product rule
    Then the expected status should be returned

    # 403
    Given I set the context product rule product id to DeleteAuthProductId
    And I do not include the API key header
    And I expect the next API call to return a status code of 403 and message of "Forbidden"
    When I DELETE my product rule
    Then the expected status should be returned

