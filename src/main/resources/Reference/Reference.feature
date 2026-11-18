Feature: Validate reference endpoints

  Note: Settlement API on devtest uses dev ref data, so no point in running this file on devtest

  Background:
    Given I start with an empty context
    And this scenario is not supported for the devtest environment


  Scenario Outline: Validate endpoint enumerations
    When I call the reference service endpoint <endpoint>
    Then the endpoint response should match the expected enumeration
    Examples:
      | endpoint                             |
      | settlement_asset_types               |
      | settlement_business_process_statuses |
      | settlement_interval_sources          |
      | settlement_item_statuses             |
      | settlement_levels                    |
      | settlement_statuses                  |
      | settlement_types                     |
      | registration_statuses                |
      | api_categories/platforms             |
      | settlement_pipeline_statuses         |
      | settlement_pipeline_steps            |
      | settlement_pipeline_levels           |
