package com.enernoc.bdap.shared;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.secretsmanager.SecretsManagerClient;
import software.amazon.awssdk.services.secretsmanager.model.GetSecretValueRequest;
import software.amazon.awssdk.services.secretsmanager.model.GetSecretValueResponse;
import software.amazon.awssdk.services.secretsmanager.model.SecretsManagerException;

import java.util.HashMap;

import static org.junit.jupiter.api.Assertions.fail;


public class AwsSecretsManager {

    private static final ObjectMapper JSON = new ObjectMapper();

    private final SecretsManagerClient secretsClient = SecretsManagerClient.builder()
            .region(Context.region).credentialsProvider(new StaticCredentialsProvider().withKeyset(Context.CREDENTIAL_KEYSET))
            .build();


    public HashMap<String, String> getValueMap(String secretName) {

        var values = new HashMap<String, String>();
        try {
            GetSecretValueRequest valueRequest = GetSecretValueRequest.builder()
                    .secretId(secretName)
                    .build();

            GetSecretValueResponse valueResponse = secretsClient.getSecretValue(valueRequest);
            values.putAll(JSON.readValue(valueResponse.secretString(), new TypeReference<>(){}));
        } catch (SecretsManagerException e) {
            fail(e.awsErrorDetails().errorMessage());
        } catch (Exception e) {
            fail(e.toString());
        }
        return values;
    }
}
