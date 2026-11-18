Feature: CRUD for product rule fragments

  Reference: <JIRA_URL>/browse/ITAPPSIT-4056

  Background:
    Given I start with an empty context
    And I log in as a settlement API user

  #Check that settlement user can not use DELETE operation on SMD API
  Scenario: Delete for product rule fragment
  # DELETE -> 403
    When I DELETE my product rule fragment with id 1 and get 403 status code