package com.enernoc.bdap.stepdefs;

import com.enernoc.bdap.shared.AwsSqs;
import com.enernoc.bdap.shared.Context;
import com.enernoc.bdap.shared.PostgresClient;
import com.enernoc.bdap.shared.Utility;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.PropertyNamingStrategy;
import io.cucumber.datatable.DataTable;
import io.cucumber.java.en.When;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.lang.reflect.Field;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;

import static com.enernoc.bdap.shared.AwsSqs.*;
import static com.enernoc.bdap.shared.Context.settlementSecretValues;
import static org.junit.jupiter.api.Assertions.fail;

public class Orchestrator {

    private static final Logger LOG = LoggerFactory.getLogger("Orchestrator");
    private static final ObjectMapper JSON = new ObjectMapper().setPropertyNamingStrategy(PropertyNamingStrategy.SNAKE_CASE);
    private final Context context = Context.getContext();
    private final PostgresClient client = new PostgresClient(settlementSecretValues);
    private final Utility utility = new Utility();

    private enum SqsQueue {
        ORCHESTRATOR_INPUT,
        INTERVALS_OUTPUT,
        ECO_OUTPUT,
        CREATE_INTERVALS_INPUT_DLQ,
        ECO_INPUT_DLQ
    }

    private void iSendMsgToSqsQueue(SqsQueue targetQueue, HashMap<String, Object> params) {
        String targetUrl = switch (targetQueue) {
            case ORCHESTRATOR_INPUT -> Context.orchestratorSQSInputQueueUrl;
            case INTERVALS_OUTPUT -> Context.createIntervalsSQSOutputUrl;
            case ECO_OUTPUT -> Context.ecoSQSOutputQueueUrl;
            case CREATE_INTERVALS_INPUT_DLQ -> Context.createIntervalsSQSInputDLQUrl;
            case ECO_INPUT_DLQ -> Context.ecoInternalSQSInputDLQUrl;
        };
        AwsSqs client = build().withUrl(targetUrl);
        SqsMessageCommon message = switch (targetQueue) {
            case ORCHESTRATOR_INPUT -> new OrchestratorSqsInputMessage();
            case INTERVALS_OUTPUT -> new CreateIntervalsSqsOutputMessage();
            case ECO_OUTPUT -> new EcoSqsOutputMessage();
            case CREATE_INTERVALS_INPUT_DLQ -> new CreateIntervalsSqsInputDLQMessage();
            case ECO_INPUT_DLQ -> new EcoSqsInternalInputDLQMessage();
        };
        message.settlementId = context.lastSettlementId;
        List<String> allowedFields = Arrays.stream(SqsMessageCommon.class.getDeclaredFields()).map(Field::getName).toList();
        int delay = 0;
        if (params.containsKey("delay")) {
            delay = Integer.parseInt(params.get("delay").toString());
            params.remove("delay");
        }
        // Apply property params, if any
        if (!params.isEmpty()) {
            utility.replaceParmValues(params);
            params.forEach((key, value) -> {
                String valStr = value.toString();
                if (allowedFields.contains(key)) {
                    Field field;
                    try {
                        field = SqsMessageCommon.class.getDeclaredField(key);
                        field.setAccessible(true);
                        field.set(message, valStr);
                    } catch (NoSuchFieldException | IllegalAccessException e) {
                        try {
                            field = message.getClass().getDeclaredField(key);
                            field.setAccessible(true);
                            field.set(message, valStr);
                        } catch (NoSuchFieldException | IllegalAccessException ex) {
                            fail("Failed to set field " + key + " in message");
                        }
                    }
                    LOG.info("Setting field " + key + " in message to " + valStr);
                } else if (key.equals("startAtStep")) {
                    if (message instanceof OrchestratorSqsInputMessage) {
                        ((OrchestratorSqsInputMessage) message).extras = new OrchestratorExtras();
                        ((OrchestratorSqsInputMessage) message).extras.startAtStep = valStr;
                    } else {
                        fail("Unknown field " + key + " in message");
                    }

                } else {
                    fail("Unknown field " + key + " in message");
                }
            });
            try {
                String msgString = JSON.writeValueAsString(message);
                if (targetQueue == SqsQueue.ORCHESTRATOR_INPUT) {
                    client.sendSqsMessageToFifoQueue(msgString);
                } else {
                    if (delay != 0) {
                        client.sendSqsMessageWithDelay(msgString, delay);
                    } else
                        client.sendSqsMessage(msgString);
                }
                LOG.info(String.format("Message sent with pipeline_run_id: %s  settlement_id: %s", context.lastPipelineRunId, context.lastSettlementId));
            } catch (JsonProcessingException e) {
                fail("Failed to convert message to JSON");
            }
        } else {
            fail("No property params to set in message");
        }
    }

    @When("^I send a message to the SQS (Orchestrator Input|Intervals Output|ECO Output|Intervals Input Dead Letter|ECO Input Dead Letter) Queue using the following parameters:$")
    public void iSendAMessageToSQSQueueUsingTheFollowingParameters(String queue, DataTable data) {
        var inputProps = new HashMap<>(data.asMap(String.class, Object.class));
        utility.replaceParmValues(inputProps);
        context.lastPipelineRunId = inputProps.get("pipelineRunId").toString();
        SqsQueue targetQueue = switch (queue) {
            case "Orchestrator Input" -> SqsQueue.ORCHESTRATOR_INPUT;
            case "Intervals Output" -> SqsQueue.INTERVALS_OUTPUT;
            case "ECO Output" -> SqsQueue.ECO_OUTPUT;
            case "Intervals Input Dead Letter" -> SqsQueue.CREATE_INTERVALS_INPUT_DLQ;
            case "ECO Input Dead Letter" -> SqsQueue.ECO_INPUT_DLQ;
            default -> throw new IllegalStateException("Unexpected value: " + queue);
        };
        iSendMsgToSqsQueue(targetQueue, new HashMap<>(data.asMap(String.class, Object.class)));
    }
}
