Feature: CRUD for product rule details

  # Uses /api/v1/productruledetails endpoints.
  # Covers:
  # - GET by id
  # - POST create (201, 400 validation, 409 overlap conflict, auth errors)
  # - PUT update (200, 400 validation, 404 missing, 409 overlap conflict, auth errors)
  # - DELETE (204 success, 404 missing, 400 invalid id, auth errors)

  Background:
    Given I start with an empty context
    And I log in as a settlement API admin

  #
  # Happy-path CRUD lifecycle
  # make sure to have pr_group_id - 1 and pr_paramter_def_id - 3
  Scenario: Full CRUD lifecycle for product rule detail
    Given I delete all existing product rule details for product group id 1 and parameter 3

    # POST -> 201
    When I POST a new product rule detail specifying the following properties
      | pr_parameter_def_id  | 3                                     |
      | value                | May                                   |
      | start_dttm_utc       | 2026-05-01T00:00:00Z                  |
      | end_dttm_utc         | 2026-06-01T00:00:00Z                  |
      | pr_group_id          | 1                  |
    Then the response should include the new product rule detail

    # GET by id -> 200
    When I GET the product rule detail by id
    Then GET product rule detail should return the current state

    # PUT -> 200, change value and window
    When I update the product rule detail with new values
      | pr_parameter_def_id  | 3                                     |
      | value          | June                                |
      | start_dttm_utc | 2026-06-01T00:00:00Z                |
      | end_dttm_utc   | 2026-07-01T00:00:00Z                |
      | pr_group_id          | 1                  |
    Then the response should include the updated product rule detail
    And GET product rule detail should return the current state

    # DELETE -> 204
    When I DELETE my product rule detail

    # GET after delete -> 404
    Given I expect the next API call to return a status code of 404 and details of "not found"
    When I GET the product rule detail by id
    Then the expected status should be returned

  #
  # Basic GET /productruledetails/{id}
  #
  Scenario: GET product rule detail returns 404 when not found
    Given I set the context product rule detail ID to 999999
    And I expect the next API call to return a status code of 404 and details of "not found"
    When I GET the product rule detail by id
    Then the expected status should be returned

  #
  # POST /productruledetails validations (201, 400, 409, auth)
  #
  Scenario: POST creates product rule detail
    Given I delete all existing product rule details for product group id 1 and parameter 3
    When I POST a new product rule detail specifying the following properties
      | pr_group_id      | 1 |
      | pr_parameter_def_id  | 3                                     |
      | value                | ValueA                                |
      | start_dttm_utc       | 2026-01-01T00:00:00Z                  |
      | end_dttm_utc         | 2026-02-01T00:00:00Z                  |
    Then the response should include the new product rule detail

  Scenario: POST fails with 401 if ENOC session is missing
    Given I do not include the ENOC session header
    And I expect the next API call to return a status code of 401 and message of "Unauthorized"
    When I POST a new product rule detail specifying the following properties
      | pr_group_id      | 1 |
      | pr_parameter_def_id  | 3                                     |
      | value                | AuthDetail1                           |
      | start_dttm_utc       | 2026-01-01T00:00:00Z                  |
      | end_dttm_utc         | 2026-02-01T00:00:00Z                  |
    Then the expected status should be returned

  Scenario: POST fails with 403 if API key is missing
    Given I do not include the API key header
    And I expect the next API call to return a status code of 403 and message of "Forbidden"
    When I POST a new product rule detail specifying the following properties
      | pr_group_id     | 1 |
      | pr_parameter_def_id  | 3                                     |
      | value                | AuthDetail2                           |
      | start_dttm_utc       | 2026-01-01T00:00:00Z                  |
      | end_dttm_utc         | 2026-02-01T00:00:00Z                  |
    Then the expected status should be returned

  Scenario: POST returns 400 when mandatory fields are missing or invalid
    # missing pr_group_id
    Given I delete all existing product rule details for product group id 1 and parameter 3
    Given I expect the next API call to return a status code of 400 and details of "failed validation"
    When I POST a new product rule detail specifying the following properties
      | pr_parameter_def_id  | 3                                     |
      | value                | MissingProductRuleId                  |
      | start_dttm_utc       | 2026-01-01T00:00:00Z                  |
      | end_dttm_utc         | 2026-02-01T00:00:00Z                  |
    Then the expected status should be returned

    # missing pr_parameter_def_id
    Given I expect the next API call to return a status code of 400 and details of "failed validation"
    When I POST a new product rule detail specifying the following properties
      | pr_group_id      | 3 |
      | value                | MissingParamDef                       |
      | start_dttm_utc       | 2026-01-01T00:00:00Z                  |
      | end_dttm_utc         | 2026-02-01T00:00:00Z                  |
    Then the expected status should be returned

    # missing or empty timeframe
    Given I expect the next API call to return a status code of 400 and details of "failed validation"
    When I POST a new product rule detail specifying the following properties
      | pr_group_id      | 3 |
      | pr_parameter_def_id  | 3                                     |
      | value                | MissingStart                          |
      | end_dttm_utc         | 2026-02-01T00:00:00Z                  |
    Then the expected status should be returned

    Given I expect the next API call to return a status code of 400 and details of "failed validation"
    When I POST a new product rule detail specifying the following properties
      | pr_group_id     | 1 |
      | pr_parameter_def_id  | 3                                     |
      | value                | MissingEnd                            |
      | start_dttm_utc       | 2026-01-01T00:00:00Z                  |
    Then the expected status should be returned

  Scenario: POST returns 409 when timeframe overlaps for same rule and parameter
    Given I delete all existing product rule details for product group id 1 and parameter 3
    And I POST a new product rule detail specifying the following properties
      | pr_group_id   | 1 |
      | pr_parameter_def_id  | 3                                     |
      | value                | Base                                 |
      | start_dttm_utc       | 2026-01-01T00:00:00Z                  |
      | end_dttm_utc         | 2026-02-01T00:00:00Z                  |
    Then the response should include the new product rule detail

    # Overlapping timeframe for same pr_group_id + param -> 409
    Given I expect the next API call to return a status code of 409 and details of "overlapping dates already exists"
    When I POST a new product rule detail specifying the following properties
      | pr_group_id      | 1 |
      | pr_parameter_def_id  | 3                                     |
      | value                | Overlap                               |
      | start_dttm_utc       | 2026-01-01T00:00:00Z                  |
      | end_dttm_utc         | 2026-02-15T00:00:00Z                  |
    Then the expected status should be returned

  Scenario: POST returns 400 when pr_group_id does not exist
    Given I expect the next API call to return a status code of 400 and details of "does not exist"
    When I POST a new product rule detail specifying the following properties
      | pr_group_id      | 1000000                                    |
      | pr_parameter_def_id  | 1                                     |
      | value                | InvalidRuleId                         |
      | start_dttm_utc       | 2026-01-01T00:00:00Z                  |
      | end_dttm_utc         | 2026-02-01T00:00:00Z                  |
    Then the expected status should be returned

  Scenario: POST returns 400 when pr_parameter_def_id does not exist
    Given I expect the next API call to return a status code of 400 and details of "does not exist"
    When I POST a new product rule detail specifying the following properties
      | pr_group_id      | 1 |
      | pr_parameter_def_id  | 1000000                                  |
      | value                | InvalidParamId                        |
      | start_dttm_utc       | 2026-01-01T00:00:00Z                  |
      | end_dttm_utc         | 2026-02-01T00:00:00Z                  |
    Then the expected status should be returned

  Scenario: POST returns 400 when mandatory values are empty
    Given I delete all existing product rule details for product group id 1 and parameter 3
    Given I expect the next API call to return a status code of 400 and details of "failed validation"
    When I POST a new product rule detail specifying the following properties
      | pr_parameter_def_id  |                                   |
      | pr_group_id      | 1 |
      | value                | InvalidParamId                        |
      | start_dttm_utc       | 2026-01-01T00:00:00Z                  |
      | end_dttm_utc         | 2026-02-01T00:00:00Z                  |
    Then the expected status should be returned

    Given I expect the next API call to return a status code of 400 and details of "failed validation"
    When I POST a new product rule detail specifying the following properties
      | pr_group_id      | |
      | pr_parameter_def_id  |   3                                |
      | value                | InvalidParamId                        |
      | start_dttm_utc       | 2026-01-01T00:00:00Z                  |
      | end_dttm_utc         | 2026-02-01T00:00:00Z                  |
    Then the expected status should be returned

    Given I expect the next API call to return a status code of 400 and details of "failed validation"
    When I POST a new product rule detail specifying the following properties
      | pr_group_id      | 1 |
      | pr_parameter_def_id  | 3                                  |
      | value                |   test                      |
      | start_dttm_utc       |                  |
      | end_dttm_utc         | 2026-02-01T00:00:00Z                  |
    Then the expected status should be returned

    Given I expect the next API call to return a status code of 400 and details of "failed validation"
    When I POST a new product rule detail specifying the following properties
      | pr_group_id      | 1 |
      | pr_parameter_def_id  | 3                                  |
      | value                |   test                      |
      | start_dttm_utc       | 2026-02-01T00:00:00Z                 |
      | end_dttm_utc         |                   |
    Then the expected status should be returned

  #
  # PUT /productruledetails/{id} validations
  #
  Scenario: PUT returns 404 when product rule detail does not exist
    Given I set the context product rule detail ID to 999999
    And I expect the next API call to return a status code of 404 and details of "not found"
    When I update the product rule detail with new values
      | pr_group_id      | 999999 |
      | pr_parameter_def_id  | 9                                     |
      | value | MissingDetail |
      | start_dttm_utc       | 2026-01-01T00:00:00Z                  |
      | end_dttm_utc         | 2026-02-01T00:00:00Z                  |
    Then the expected status should be returned

  Scenario: PUT returns 400 when mandatory body fields are invalid
    Given I delete all existing product rule details for product group id 1 and parameter 9
    And I POST a new product rule detail specifying the following properties
      | pr_group_id      | 1 |
      | pr_parameter_def_id  | 9                                     |
      | value                | PutValid                              |
      | start_dttm_utc       | 2026-01-01T00:00:00Z                  |
      | end_dttm_utc         | 2026-02-01T00:00:00Z                  |
    Then the response should include the new product rule detail
    And I save this product rule detail id as PutInvalidDetailId

    And I set the context product rule detail id to PutInvalidDetailId
    And I expect the next API call to return a status code of 400 and details of "failed validation"
    When I update the product rule detail with new values
      | pr_group_id      | 1 |
      | pr_parameter_def_id  | 9                                     |
      | start_dttm_utc |  2026-01-01T00:00:00Z  |
      | end_dttm_utc   |  2026-02-01T00:00:00Z  |
    Then the expected status should be returned

    And I set the context product rule detail id to PutInvalidDetailId
    And I expect the next API call to return a status code of 400 and details of "failed validation"
    When I update the product rule detail with new values
      | pr_group_id      | 1 |
      | value                | PutValid                              |
      | start_dttm_utc |  2026-01-01T00:00:00Z  |
      | end_dttm_utc   |  2026-02-01T00:00:00Z  |
    Then the expected status should be returned

    And I set the context product rule detail id to PutInvalidDetailId
    And I expect the next API call to return a status code of 400 and details of "failed validation"
    When I update the product rule detail with new values
      | pr_parameter_def_id  | 11                                     |
      | value                | PutValid                              |
      | start_dttm_utc |  2026-01-01T00:00:00Z  |
      | end_dttm_utc   |  2026-02-01T00:00:00Z  |
    Then the expected status should be returned

  Scenario: PUT returns 409 when updated timeframe overlaps existing detail
    # Create two non-overlapping details for same rule+param
    Given I delete all existing product rule details for product group id 1 and parameter 10
    And I POST a new product rule detail specifying the following properties
      | pr_group_id      | 1 |
      | pr_parameter_def_id  | 10                                    |
      | value                | First                                |
      | start_dttm_utc       | 2026-01-01T00:00:00Z                  |
      | end_dttm_utc         | 2026-02-01T00:00:00Z                  |
    Then the response should include the new product rule detail

    And I POST a new product rule detail specifying the following properties
      | pr_group_id      | 1 |
      | pr_parameter_def_id  | 10                                    |
      | value                | Second                               |
      | start_dttm_utc       | 2026-03-01T00:00:00Z                  |
      | end_dttm_utc         | 2026-04-01T00:00:00Z                  |
    Then the response should include the new product rule detail
    And I save this product rule detail id as OverlapDetailId

    # Try to move second detail to overlap first -> 409
    And I set the context product rule detail id to OverlapDetailId
    And I expect the next API call to return a status code of 409 and details of "overlapping dates already exists"
    When I update the product rule detail with new values
      | pr_group_id      | 1 |
      | pr_parameter_def_id  | 10                                     |
      | value                | PutBase                               |
      | start_dttm_utc | 2026-01-01T00:00:00Z |
      | end_dttm_utc   | 2026-02-01T00:00:00Z |

    Then the expected status should be returned

  Scenario: PUT returns 400 when pr_group_id does not exist
    # Create a valid detail first
    Given I delete all existing product rule details for product group id 1 and parameter 2
    And I POST a new product rule detail specifying the following properties
      | pr_group_id      | 1 |
      | pr_parameter_def_id  | 2                                     |
      | value                | PutBase                               |
      | start_dttm_utc       | 2026-01-01T00:00:00Z                  |
      | end_dttm_utc         | 2026-02-01T00:00:00Z                  |
    Then the response should include the new product rule detail
    And I save this product rule detail id as PutInvalidRuleId

    And I set the context product rule detail id to PutInvalidRuleId
    And I expect the next API call to return a status code of 400 and details of "does not exist"
    When I update the product rule detail with new values
      | pr_group_id      | 999999999                                    |
      | pr_parameter_def_id  | 2                                     |
      | value                | PutBase                               |
      | start_dttm_utc       | 2026-01-01T00:00:00Z                  |
      | end_dttm_utc         | 2026-02-01T00:00:00Z                  |

    Then the expected status should be returned

  Scenario: PUT returns 400 when pr_parameter_def_id does not exist
    # Create a valid detail first
    Given I delete all existing product rule details for product group id 1 and parameter 2
    And I POST a new product rule detail specifying the following properties
      | pr_group_id      | 1 |
      | pr_parameter_def_id  | 2                                   |
      | value                | PutBase2                              |
      | start_dttm_utc       | 2026-01-01T00:00:00Z                  |
      | end_dttm_utc         | 2026-02-01T00:00:00Z                  |
    Then the response should include the new product rule detail
    And I save this product rule detail id as PutInvalidParamId

    And I set the context product rule detail id to PutInvalidParamId
    And I expect the next API call to return a status code of 400 and details of "does not exist"
    When I update the product rule detail with new values
      | pr_parameter_def_id  | 999999999                                  |
      | pr_group_id      | 11 |
      | value                | PutBase2                              |
      | start_dttm_utc       | 2026-01-01T00:00:00Z                  |
      | end_dttm_utc         | 2026-02-01T00:00:00Z                  |
    Then the expected status should be returned


  Scenario: PUT returns 400 when mandatory values are empty
  # Arrange: create a valid detail we can update
    Given I delete all existing product rule details for product group id 1 and parameter 3
    And I POST a new product rule detail specifying the following properties
      | pr_group_id      | 1                                     |
      | pr_parameter_def_id  | 3                                     |
      | value                | BaseValue                             |
      | start_dttm_utc       | 2026-01-01T00:00:00Z                  |
      | end_dttm_utc         | 2026-02-01T00:00:00Z                  |
    Then the response should include the new product rule detail
    And I save this product rule detail id as EmptyPutDetailId

  # pr_parameter_def_id empty
    And I set the context product rule detail id to EmptyPutDetailId
    And I expect the next API call to return a status code of 400 and details of "failed validation"
    When I update the product rule detail with new values
      | pr_parameter_def_id  |                                     |
      | pr_group_id      | 1                                    |
      | value                | BaseValue                             |
      | start_dttm_utc       | 2026-01-01T00:00:00Z                  |
      | end_dttm_utc         | 2026-02-01T00:00:00Z                  |

    Then the expected status should be returned

  # pr_group_id empty
    And I set the context product rule detail id to EmptyPutDetailId
    And I expect the next API call to return a status code of 400 and details of "failed validation"
    When I update the product rule detail with new values
      | pr_group_id      |                                     |
      | pr_parameter_def_id  | 3                                     |
      | value                | BaseValue                             |
      | start_dttm_utc       | 2026-01-01T00:00:00Z                  |
      | end_dttm_utc         | 2026-02-01T00:00:00Z                  |

    Then the expected status should be returned


  # start_dttm_utc empty
    And I set the context product rule detail id to EmptyPutDetailId
    And I expect the next API call to return a status code of 400 and details of "failed validation"
    When I update the product rule detail with new values
      | start_dttm_utc       |                                     |
      | pr_group_id      | 1                                     |
      | pr_parameter_def_id  | 3                                     |
      | value                | BaseValue                             |
      | end_dttm_utc         | 2026-02-01T00:00:00Z                  |

    Then the expected status should be returned

  # end_dttm_utc empty
    And I set the context product rule detail id to EmptyPutDetailId
    And I expect the next API call to return a status code of 400 and details of "failed validation"
    When I update the product rule detail with new values
      | end_dttm_utc         |                                     |
      | pr_group_id      | 1                                     |
      | pr_parameter_def_id  | 3                                     |
      | value                | BaseValue                             |
      | start_dttm_utc       | 2026-01-01T00:00:00Z                  |

    Then the expected status should be returned

  # all mandatory fields empty at once
    And I set the context product rule detail id to EmptyPutDetailId
    And I expect the next API call to return a status code of 400 and details of "failed validation"
    When I update the product rule detail with new values
      | pr_group_id      |                                     |
      | pr_parameter_def_id  |                                     |
      | value                |                                     |
      | start_dttm_utc       |                                     |
      | end_dttm_utc         |                                     |
    Then the expected status should be returned

  #
  # DELETE /productruledetails/{id}
  #
  Scenario: DELETE returns 204 when detail exists
    Given I delete all existing product rule details for product group id 1 and parameter 11
    And I POST a new product rule detail specifying the following properties
      | pr_group_id      | 1 |
      | pr_parameter_def_id  | 11                                    |
      | value                | DeletableDetail                       |
      | start_dttm_utc       | 2026-01-01T00:00:00Z                  |
      | end_dttm_utc         | 2026-02-01T00:00:00Z                  |
    Then the response should include the new product rule detail
    And I save this product rule detail id as DeletableDetailId

    Given I set the context product rule detail id to DeletableDetailId
    When I DELETE my product rule detail

    Given I expect the next API call to return a status code of 404 and details of "not found"
    When I GET the product rule detail by id
    Then the expected status should be returned

  Scenario: DELETE returns 404 when detail does not exist
    Given I set the context product rule detail ID to 999999
    And I expect the next API call to return a status code of 404 and details of "not found"
    When I DELETE my product rule detail
    Then the expected status should be returned
