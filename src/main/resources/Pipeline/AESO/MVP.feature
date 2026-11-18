Feature: Scenarios for AESO MVP testing on preprd

  <CONFLUENCE_URL>/display/XP/Settlement+Pipeline+MVP%3A+use+cases

  Background:
    Given this scenario is only supported for the preprd environment
    Given I start with an empty context
    * I log in as a settlement API admin
    * I set the settlement time zone to "America/Edmonton"
    * I set the Energy Markets program to AESO


  Scenario: ITAPPSIT-3534: settlement MVP test: rerun pipeline for FINALIZED settlement

    * -> Note: All three month settlements must already exist. If not, run the re-create scenarios in E2E.feature.

    * -> Make sure all settlements are initialized to non-finalized
    Given I want to do a scheduled settlement for product: AESO type: ANCILLARY as of: "2025-07-14T00:00:00Z"
    And I generate the expected scheduled settlements
    And I generate the expected settlement items for the saved scheduled settlements
    And I retrieve the existing matching settlements from the database
    And I un-finalize any finalized settlements
    # Wait a few seconds to make sure PATCHes above have replicated
    Given I wait 5 seconds
    And I reset the test start epoch and clear the pipeline settlement lists

    * -> Verify April and finalize it
    Given I set up an E2E test using the following parameters for the settlement that was just run:
      | month           | April                                  |
      | year            | 2025                                 |
    And I get the financial points for the settlement
    And I get the pool_price prices
    And I get the daily_discount_price prices
    And I get cleared offers from MOM
    And I calculate the expected monthly ECO payments for the settlement
    Then the ECO payments should equal the expected payments
    Given I save the expected ECO objects for later use

    When I PATCH the settlement with new values:
      | settlement_id         | <last-settlement-id>             |
      | settlement_status | FINALIZED              |
      | change_comments   | PRELIMINARY -> FINALIZED |
    Then the response should include the updated settlement

    * -> Verify May and finalize it
    Given I set up an E2E test using the following parameters for the settlement that was just run:
      | month           | May                                  |
      | year            | 2025                                 |
    And I get the financial points for the settlement
    And I get the pool_price prices
    And I get the daily_discount_price prices
    And I get cleared offers from MOM
    And I calculate the expected monthly ECO payments for the settlement
    Then the ECO payments should equal the expected payments
    Given I save the expected ECO objects for later use

    When I PATCH the settlement with new values:
      | settlement_id         | <last-settlement-id>             |
      | settlement_status | FINALIZED              |
      | change_comments   | PRELIMINARY -> FINALIZED |
    Then the response should include the updated settlement

    * -> Verify June and finalize it
    Given I set up an E2E test using the following parameters for the settlement that was just run:
      | month           | June                                  |
      | year            | 2025                                 |
    And I get the financial points for the settlement
    And I get the pool_price prices
    And I get the daily_discount_price prices
    And I get cleared offers from MOM
    And I calculate the expected monthly ECO payments for the settlement
    Then the ECO payments should equal the expected payments
    Given I save the expected ECO objects for later use

    When I PATCH the settlement with new values:
      | settlement_id         | <last-settlement-id>             |
      | settlement_status | FINALIZED              |
      | change_comments   | PRELIMINARY -> FINALIZED |
    Then the response should include the updated settlement


    * -> Run the quarterly job and verify that all the settlements were skipped

    # Wait a few seconds to make sure PATCHes above have replicated
    Given I wait 5 seconds
    And I reset the test start epoch and clear the pipeline settlement lists

    Given I want to do a scheduled settlement for product: AESO type: ANCILLARY as of: "2025-07-14T00:00:00Z"
    And I invoke the settlement creator lambda
    And I wait until 3 settlements have been skipped by the pipeline with the detail "skipping+further+processing+of+finalized+settlement"
    Then no settlements should have been created

    * -> Verify April was skipped
    Given I set up an E2E test using the following parameters for the settlement that was just run:
      | month           | April                                  |
      | year            | 2025                                 |
    And I load the expected ECO payments from the saved objects
    Then the settlement and items should not be updated
    And none of the settlement item intervals should be updated
    And the ECO payments should still equal the expected payments
    But the ECO transaction rows should not be updated

    * -> Verify May was skipped and un-finalize it
    Given I set up an E2E test using the following parameters for the settlement that was just run:
      | month           | May                                  |
      | year            | 2025                                 |
    And I load the expected ECO payments from the saved objects
    Then the settlement and items should not be updated
    And none of the settlement item intervals should be updated
    And the ECO payments should still equal the expected payments
    But the ECO transaction rows should not be updated

    When I PATCH the settlement with new values:
      | settlement_id         | <last-settlement-id>             |
      | settlement_status | PRELIMINARY              |
      | change_comments   | FINALIZED -> PRELIMINARY |
    Then the response should include the updated settlement

    * -> Verify June was skipped
    Given I set up an E2E test using the following parameters for the settlement that was just run:
      | month           | June                                  |
      | year            | 2025                                 |
    And I load the expected ECO payments from the saved objects
    Then the settlement and items should not be updated
    And none of the settlement item intervals should be updated
    And the ECO payments should still equal the expected payments
    But the ECO transaction rows should not be updated


    * -> Run the quarterly job again and verify that only May was processed

    # Wait a few seconds to make sure PATCH above has replicated
    Given I wait 5 seconds
    And I reset the test start epoch and clear the pipeline settlement lists

    Given I want to do a scheduled settlement for product: AESO type: ANCILLARY as of: "2025-07-14T00:00:00Z"
    And I invoke the settlement creator lambda
    And I wait until 2 settlements have been skipped by the pipeline with the detail "skipping+further+processing+of+finalized+settlement"
    And I wait until 1 settlements have been processed by the pipeline
    Then no settlements should have been created

    * -> Verify April was skipped and un-finalize it
    Given I set up an E2E test using the following parameters for the settlement that was just run:
      | month           | April                                  |
      | year            | 2025                                 |
    And I load the expected ECO payments from the saved objects
    Then the settlement and items should not be updated
    And none of the settlement item intervals should be updated
    And the ECO payments should still equal the expected payments
    But the ECO transaction rows should not be updated

    When I PATCH the settlement with new values:
      | settlement_id         | <last-settlement-id>             |
      | settlement_status | PRELIMINARY              |
      | change_comments   | FINALIZED -> PRELIMINARY |
    Then the response should include the updated settlement

    * -> Verify May was processed
    Given I set up an E2E test using the following parameters for the settlement that was just run:
      | month           | May                                  |
      | year            | 2025                                 |
    And I load the expected ECO payments from the saved objects
    Then the settlement and items should not be updated
    But all the settlement item intervals should be updated
    And the ECO payments should equal the expected payments
    And the ECO transaction rows should be updated

    * -> Verify June was skipped and un-finalize it
    Given I set up an E2E test using the following parameters for the settlement that was just run:
      | month           | June                                  |
      | year            | 2025                                 |
    And I load the expected ECO payments from the saved objects
    Then the settlement and items should not be updated
    And none of the settlement item intervals should be updated
    And the ECO payments should still equal the expected payments
    But the ECO transaction rows should not be updated

    When I PATCH the settlement with new values:
      | settlement_id         | <last-settlement-id>             |
      | settlement_status | PRELIMINARY              |
      | change_comments   | FINALIZED -> PRELIMINARY |
    Then the response should include the updated settlement
    # The following wait prevents the next scenario from failing on the stepdef 'no settlements should have been created'
    # because the last_updated_dttm_utc on the patched settlement only has a resolution of one second
    Given I wait 5 seconds


  Scenario: ITAPPSIT-3535: settlement MVP test: rerun pipeline for FINALIZED item: finalize all items

    * -> Note: All three month settlements must already exist. If not, run the re-create scenarios in E2E.feature.

    * -> Make sure all items are initialized to non-finalized
    Given I want to do a scheduled settlement for product: AESO type: ANCILLARY as of: "2025-07-01T00:00:00Z"
    And I generate the expected scheduled settlements
    And I generate the expected settlement items for the saved scheduled settlements
    And I retrieve the existing matching settlements from the database
    Given I set up an E2E test using the following parameters for the settlement that was just run:
      | month           | June                                  |
      | year            | 2025                                 |
    Given I un-finalize any finalized settlement items
    # Wait a few seconds to make sure PATCHes above have replicated
    Given I wait 5 seconds
    And I reset the test start epoch and clear the pipeline settlement lists

    * -> Run the monthly job to get the latest results and change the items to FINALIZED.
    Given I want to do a scheduled settlement for product: AESO type: ANCILLARY as of: "2025-07-01T00:00:00Z"
    And I generate the expected scheduled settlement
    And I generate the expected settlement items for the saved scheduled settlement
    And I invoke the settlement creator lambda
    And I wait until 1 settlements have been processed by the pipeline
    Then no settlements should have been created

    * -> Get the ECO results for June for later comparison
    Given I set up an E2E test using the following parameters for the settlement that was just run:
      | month           | June                                  |
      | year            | 2025                                 |
    And I get the financial points for the settlement
    And I get the pool_price prices
    And I get the daily_discount_price prices
    And I get cleared offers from MOM
    And I calculate the expected monthly ECO payments for the settlement
    Then the ECO payments should equal the expected payments
    And the settlement and items should not be updated
    But all the settlement item intervals should be updated
    And the ECO transaction rows should be updated
    Given I save the expected ECO objects for later use

    * -> FINALIZE all items

    Given I finalize all of the settlement items

    * -> Run the monthly job again and verify that all the items were skipped

    # Wait a few seconds to make sure PATCHes above have replicated
    Given I wait 5 seconds
    And I reset the test start epoch and clear the pipeline settlement lists

    Given I want to do a scheduled settlement for product: AESO type: ANCILLARY as of: "2025-07-01T00:00:00Z"
    And I generate the expected scheduled settlement
    And I generate the expected settlement items for the saved scheduled settlement
    And I invoke the settlement creator lambda
    And I wait until 1 settlements have been skipped by the pipeline with the detail "no+items+to+process+(skipped+9+finalized+items)"
    Then no settlements should have been created

    * -> Verify all items for June were skipped
    Given I set up an E2E test using the following parameters for the settlement that was just run:
      | month           | June                                  |
      | year            | 2025                                 |
    And I load the expected ECO payments from the saved objects
    Then the settlement and items should not be updated
    And none of the settlement item intervals should be updated
    And the ECO payments should still equal the expected payments
    But the ECO transaction rows should not be updated

    * -> un-FINALIZE all items

    Given I un-finalize any finalized settlement items


  Scenario: ITAPPSIT-3535: FINALIZE only a single item

    For MVP, this scenario results in Creator still passing the finalized item to ECO for recalculation.
    ECO will update the transactions, but settlement API will not allow ECO to update intervals for the finalized item.
    We are not sure what the desired behavior is.

    * -> Make sure all items are initialized to non-finalized
    Given I want to do a scheduled settlement for product: AESO type: ANCILLARY as of: "2025-07-01T00:00:00Z"
    And I generate the expected scheduled settlements
    And I generate the expected settlement items for the saved scheduled settlements
    And I retrieve the existing matching settlements from the database
    Given I set up an E2E test using the following parameters for the settlement that was just run:
      | month           | June                                  |
      | year            | 2025                                 |
    Given I un-finalize any finalized settlement items
    # Wait a few seconds to make sure PATCHes above have replicated
    Given I wait 5 seconds
    And I reset the test start epoch and clear the pipeline settlement lists

    * -> Run the monthly job to get the settlement items for June 2025
    Given I want to do a scheduled settlement for product: AESO type: ANCILLARY as of: "2025-07-01T00:00:00Z"
    And I generate the expected scheduled settlement
    And I generate the expected settlement items for the saved scheduled settlement
    And I invoke the settlement creator lambda
    And I wait until 1 settlements have been processed by the pipeline
    Then no settlements should have been created

    * -> Get the ECO results for June for later comparison
    Given I set up an E2E test using the following parameters for the settlement that was just run:
      | month           | June                                  |
      | year            | 2025                                 |
    And I get the financial points for the settlement
    And I get the pool_price prices
    And I get the daily_discount_price prices
    And I get cleared offers from MOM
    And I calculate the expected monthly ECO payments for the settlement
    Then the ECO payments should equal the expected payments
    And the ECO transaction rows should be updated
    And the settlement and items should not be updated
    But all the settlement item intervals should be updated
    Given I save the expected ECO objects for later use

    * -> FINALIZE one of the items

    When I finalize one of the settlement items

    * -> Run the monthly job again

    # Wait a few seconds to make sure PATCH above has replicated
    Given I wait 5 seconds
    And I reset the test start epoch and clear the pipeline settlement lists

    Given I want to do a scheduled settlement for product: AESO type: ANCILLARY as of: "2025-07-01T00:00:00Z"
    And I generate the expected scheduled settlement
    And I generate the expected settlement items for the saved scheduled settlement
    And I invoke the settlement creator lambda
    And I wait until 1 settlements have been processed by the pipeline
    Then no settlements should have been created

    * -> Verify June again
    Given I set up an E2E test using the following parameters for the settlement that was just run:
      | month           | June                                  |
      | year            | 2025                                 |
    And I load the expected ECO payments from the saved objects
    Then the ECO payments should equal the expected payments
    And the ECO transaction rows should be updated
    And the settlement and items should not be updated
    And only intervals for non-finalized undeleted settlement items should be updated

    * -> un-FINALIZE all items

    Given I un-finalize any finalized settlement items


  Scenario: ITAPPSIT-3540: missing offers

    #Given I stop here because "You need to complete the setup steps in SQL_scripts ITAPPSIT-3540.sql on a new environment"
    #Given I stop here because "You need to set up the COM offers on a new environment"

    * -> Note: Verify that the final stepdef reports these stats for one of the regs: OFFER: 168 MISSING: 553

    * -> Run the monthly job to create the new settlement for November 2025
    Given I want to do a scheduled settlement for product: AESO type: ANCILLARY as of: "2025-12-01T00:00:00Z"
    And I generate the expected scheduled settlement
    And I delete any pre-existing expected settlements from the database
    And I generate the expected settlement items for the saved scheduled settlement
    And I invoke the settlement creator lambda
    And I wait until 1 settlements have been processed by the pipeline

    * -> Verify November
    Given I set up an E2E test using the following parameters for the settlement that was just run:
      | month           | November                                  |
      | year            | 2025                                 |

    Given I get the financial points for the settlement
    And I get the pool_price prices
    And I get the daily_discount_price prices
    And I get cleared offers from MOM
    And I calculate the expected monthly ECO payments for the settlement
    Then the ECO payments should equal the expected payments
    And the ECO transaction rows should be updated
    And all the settlement item intervals should be updated
    And the settlement interval stats should be correct


  Scenario: ITAPPSIT-3540: settlement MVP test: COM offers includes opt-outs

  The effect of COM opt-outs is that the MOM cleared-offer capacity value is zero. There is no other change to the offer.

    #Given I stop here because "You need to complete the setup steps in SQL_scripts ITAPPSIT-3540.sql"
    Given I stop here because "You need to set up some COM offers with opt-outs. This will have to be done in a future month that has MOM offers."

    * -> Run the monthly job to create the new settlement for June 2025
    Given I want to do a scheduled settlement for product: AESO type: ANCILLARY as of: "2025-07-01T00:00:00Z"
    And I generate the expected scheduled settlement
    And I generate the expected settlement items for the saved scheduled settlement
    And I invoke the settlement creator lambda
    And I wait until 1 settlements have been processed by the pipeline

    * -> Verify June
    Given I set up an E2E test using the following parameters for the settlement that was just run:
      | month           | June                                  |
      | year            | 2025                                 |

    Given I get the financial points for the settlement
    And I get the pool_price prices
    And I get the daily_discount_price prices
    And I get cleared offers from MOM
    And I calculate the expected monthly ECO payments for the settlement
    Then the ECO payments should equal the expected payments
    And the ECO transaction rows should be updated
    And all the settlement item intervals should be updated


  Scenario: ITAPPSIT-3533: recalculate settlement after item is marked as deleted

    Note: in many scenarios we delete the settlement before running the creator job. In this scenario, we just delete one of the settlement items. It should be re-created.

    * -> Run the monthly job to get the settlement items for June 2025
    Given I want to do a scheduled settlement for product: AESO type: ANCILLARY as of: "2025-07-01T00:00:00Z"
    And I generate the expected scheduled settlement
    And I generate the expected settlement items for the saved scheduled settlement
    And I invoke the settlement creator lambda
    And I wait until 1 settlements have been processed by the pipeline

    * -> Verify June (this also saves the list of settlement items)
    Given I set up an E2E test using the following parameters for the settlement that was just run:
      | month           | June                                  |
      | year            | 2025                                 |
    And I get the financial points for the settlement
    And I get the pool_price prices
    And I get the daily_discount_price prices
    And I get cleared offers from MOM
    And I calculate the expected monthly ECO payments for the settlement
    Then the ECO payments should equal the expected payments
    Given I save the expected ECO objects for later use

    * -> Delete one of the settlement items
    Given I save one of the item ids with 720 expected intervals for later use
    And I DELETE the settlement_item
    Then the DELETE settlement_item details should specify 1 settlement item and 720 settlement item intervals

     # Wait a few seconds to make sure DELETE above has replicated
    Given I wait 5 seconds
    And I reset the test start epoch and clear the pipeline settlement lists

    * -> Run the monthly job again.
    Given I want to do a scheduled settlement for product: AESO type: ANCILLARY as of: "2025-07-01T00:00:00Z"
    And I generate the expected scheduled settlement
    And I generate the expected settlement items for the saved scheduled settlement
    And I invoke the settlement creator lambda
    And I wait until 1 settlements have been processed by the pipeline
    Then no settlements should have been created

    * -> Verify June again
    Given I set up an E2E test using the following parameters for the settlement that was just run:
      | month           | June                                  |
      | year            | 2025                                 |
    And I get the financial points for the settlement
    And I get the pool_price prices
    And I get the daily_discount_price prices
    And I get cleared offers from MOM
    And I calculate the expected monthly ECO payments for the settlement
    Then the ECO payments should equal the expected payments
    And the ECO transaction rows should be updated
    And all the settlement item intervals should be updated


  Scenario: ITAPPSIT-3533: recalculate settlement after item intervals are marked as deleted

  In this scenario, we just delete the intervals from one of the settlement items. They should be re-created.

    * -> Run the monthly job to get the settlement items for June 2025
    Given I want to do a scheduled settlement for product: AESO type: ANCILLARY as of: "2025-07-01T00:00:00Z"
    And I generate the expected scheduled settlement
    And I generate the expected settlement items for the saved scheduled settlement
    And I invoke the settlement creator lambda
    And I wait until 1 settlements have been processed by the pipeline

    * -> Verify June (this also saves the list of settlement items)
    Given I set up an E2E test using the following parameters for the settlement that was just run:
      | month           | June                                  |
      | year            | 2025                                 |
    And I get the financial points for the settlement
    And I get the pool_price prices
    And I get the daily_discount_price prices
    And I get cleared offers from MOM
    And I calculate the expected monthly ECO payments for the settlement
    Then the ECO payments should equal the expected payments
    Given I save the expected ECO objects for later use

    * -> Delete the intervals from one of the settlement items
    Given I save one of the item ids with 720 expected intervals for later use
    And  I expect the next API call to return a status code of 200 and details of "Deleted 720 settlement_item_interval(s)"
    And I DELETE the settlement_item_intervals
    Then the expected status should be returned

     # Wait a few seconds to make sure DELETE above has replicated
    Given I wait 5 seconds
    And I reset the test start epoch and clear the pipeline settlement lists

    * -> Run the monthly job again.
    Given I want to do a scheduled settlement for product: AESO type: ANCILLARY as of: "2025-07-01T00:00:00Z"
    And I generate the expected scheduled settlement
    And I generate the expected settlement items for the saved scheduled settlement
    And I invoke the settlement creator lambda
    And I wait until 1 settlements have been processed by the pipeline
    Then no settlements should have been created

    * -> Verify June again
    Given I set up an E2E test using the following parameters for the settlement that was just run:
      | month           | June                                  |
      | year            | 2025                                 |
    And I get the financial points for the settlement
    And I get the pool_price prices
    And I get the daily_discount_price prices
    And I get cleared offers from MOM
    And I calculate the expected monthly ECO payments for the settlement
    Then the ECO payments should equal the expected payments
    And the ECO transaction rows should be updated
    And all the settlement item intervals should be updated
