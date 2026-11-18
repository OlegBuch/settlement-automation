package com.enernoc.bdap.shared;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import software.amazon.awssdk.core.SdkBytes;
import software.amazon.awssdk.services.lambda.LambdaClient;
import software.amazon.awssdk.services.lambda.model.InvokeRequest;
import software.amazon.awssdk.services.lambda.model.InvokeResponse;
import software.amazon.awssdk.services.lambda.model.LambdaException;


public class AwsLambda {

    private static final Logger LOG = LoggerFactory.getLogger("AwsLambda");

    private final LambdaClient client = LambdaClient.builder()
            .region(Context.region).credentialsProvider(new StaticCredentialsProvider().withKeyset(Context.CREDENTIAL_KEYSET))
            .build();

    private String lambdaName = "";

    public AwsLambda(String name) {
        lambdaName = name;
    }

    public void invoke(String parms) {
        InvokeResponse res;
        try {
            SdkBytes payload = SdkBytes.fromUtf8String(parms);

            InvokeRequest request = InvokeRequest.builder()
                    .functionName(lambdaName)
                    .payload(payload)
                    .build();

            res = client.invoke(request);
            String value = res.payload().asUtf8String();
            if (value != null && !value.equals("null")) {
                System.out.println(value);
            }

        } catch (LambdaException e) {
            System.err.println(e.getMessage());
            System.exit(1);
        }
    }
}
