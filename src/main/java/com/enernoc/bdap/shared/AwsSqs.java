package com.enernoc.bdap.shared;

import com.enernoc.bdap.model.SettlementItem;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.PropertyNamingStrategy;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import software.amazon.awssdk.services.sqs.SqsClient;
import software.amazon.awssdk.services.sqs.model.*;

import java.time.*;
import java.util.*;

import static software.amazon.awssdk.services.sqs.model.MessageSystemAttributeName.SENT_TIMESTAMP;


public class AwsSqs {

    public static class Extras {
        public SettlementItem settlementItem;
        public String productRuleIntervalsKwSourceSystem;
        public int intervalLengthMinutes;
        public String currency;
    }

    public static class OrchestratorExtras {
        public String startAtStep;
    }

    public static class SqsMessageCommon {
        public String action;
        public String status;
        public String step;
        public String caller;
        public String pipelineRunId;
        public String settlementId;
        public String settlementItemId;
        public String productId;
        public String mode;
    }

    public static class OrchestratorSqsInputMessage extends SqsMessageCommon {
        public OrchestratorExtras extras;
    }

    public static class CreateIntervalsSqsInputMessage extends SqsMessageCommon {
        public Extras extras;
    }

    public static class Error {
        public String description;
        public String code;
        public ArrayList<String> stack_trace;
    }

    public static class CreateIntervalsSqsOutputMessage extends SqsMessageCommon {
        public Error error;
    }

    public static class CreateItemsSqsInputMessage extends SqsMessageCommon {

    }

    public static class EcoSqsOutputMessage extends SqsMessageCommon {

    }

    public static class CreateIntervalsSqsInputDLQMessage extends SqsMessageCommon {

    }

    public static class EcoSqsInternalInputDLQMessage extends SqsMessageCommon {

    }

    private static final Logger LOG = LoggerFactory.getLogger("AwsSqs");
    private static final ObjectMapper JSON = new ObjectMapper().setPropertyNamingStrategy(PropertyNamingStrategy.SNAKE_CASE);

    private String sqsUrl = "";


    private final SqsClient client = SqsClient.builder()
            .region(Context.region).credentialsProvider(new StaticCredentialsProvider().withKeyset(Context.CREDENTIAL_KEYSET))
            .build();


    public static AwsSqs build() {
        return new AwsSqs();
    }


    public AwsSqs withUrl(String url) {
        this.sqsUrl = url;
        return this;
    }


    public void sendSqsMessage(String msg) {

        var msgReq = SendMessageRequest.builder()
                .queueUrl(sqsUrl)
                .messageBody(msg)
                .build();

        client.sendMessage(msgReq);
    }


    public void sendSqsMessageWithDelay(String msg, int delaySecs) {

        var msgReq = SendMessageRequest.builder()
                .queueUrl(sqsUrl)
                .messageBody(msg)
                .delaySeconds(delaySecs)
                .build();

        client.sendMessage(msgReq);
    }


    public void sendSqsMessageToFifoQueue(String msg) {

        var msgReq = SendMessageRequest.builder()
                .queueUrl(sqsUrl)
                .messageBody(msg)
                .messageGroupId("QAATeam")
                .messageDeduplicationId(UUID.randomUUID().toString())
                .build();

        client.sendMessage(msgReq);
    }



    public <T> SortedMap<ZonedDateTime, T>  getSqsMessagesForPipelineRunId(String id, int secsTimeout, Class<T> clazz) throws Exception {

        var allMsgs = new TreeMap<ZonedDateTime, T>();

        for (int i = 0; i < secsTimeout; i++) {
            var receiveMessageRequest = ReceiveMessageRequest.builder()
                    .queueUrl(sqsUrl)
                    .maxNumberOfMessages(10)
                    .messageSystemAttributeNames(SENT_TIMESTAMP)
                    .build();
            List<Message> messages = client.receiveMessage(receiveMessageRequest).messages();
            for (Message m : messages) {
                var dttm = ZonedDateTime.ofInstant(Instant.ofEpochMilli(Long.parseLong(m.attributes().get(SENT_TIMESTAMP))), ZoneOffset.UTC);
                HashMap<String, Object> msgMap = JSON.readValue(m.body(), new TypeReference<>() {});
                if (msgMap.getOrDefault("pipeline_run_id", "").equals(id)) {
                    allMsgs.put(dttm, JSON.readValue(m.body(), clazz));
                }
            }
            if (!allMsgs.isEmpty()) {
                break;
            }
            Thread.sleep(1000);
        }

        return allMsgs;

    }

}
