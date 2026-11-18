Feature: Verify DLQ logging lambda

  ITAPPSIT-3427: settlement creator DLQ logging lambda


  Background:
    Given I start with an empty context
    And I log in as a settlement API admin


  Scenario: Send a single message to DLQs and verify that they are logged in Splunk

    When I send a message to the SQS DLQ for settlement_output with the status "QAA_test_for_settlement_output_DLQ"
    And I send a message to the SQS DLQ for items_input with the status "QAA_test_for_items_input_DLQ"
    And I send a message to the SQS DLQ for intervals_output with the status "QAA_test_for_intervals_output_DLQ"
    Then I stop here because "Manually verify the Splunk log with the query: 'index=stm_<env> source=tf-stmcreate-<env>-dlq-logger'"


   Scenario: Stress test

     Given I run a stress test for the SQS DLQs sending 300 messages to each DLQ
     Then I stop here because "Manually verify the Splunk log with the two queries below"
  # This query verifies that the expected number of messages were written to each DLQ.
# index=stm_<env> source=tf-stmcreate-<env>-dlq-logger file | rex field=_raw "eventSourceARN\":\"(?<queue>.*)\",\"aws" | stats count by queue
  # This query verifies that there were no duplicate log messages. The count should equal the total number of messages sent.
  # index=stm_<env> source=tf-stmcreate-<env>-dlq-logger file | rex field=_raw "pipeline_run_id\":\"(?<pid>.*)\",\"settlement_id" | dedup pid | stats count
