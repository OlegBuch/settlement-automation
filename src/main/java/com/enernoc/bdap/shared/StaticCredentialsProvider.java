package com.enernoc.bdap.shared;
import software.amazon.awssdk.auth.credentials.AwsCredentials;
import software.amazon.awssdk.auth.credentials.AwsCredentialsProvider;
import software.amazon.awssdk.auth.credentials.AwsSessionCredentials;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;


import java.io.File;
import java.util.HashMap;
import java.util.Map;
import java.util.Scanner;


public class StaticCredentialsProvider implements AwsCredentialsProvider {

    private static final Logger LOG = LoggerFactory.getLogger("StaticCredentialsProvider");

    private static final Map<String, Map<String, String>> KEYSET_DATABASE = new HashMap<>();
    private String accessKey = "foobar";
    private String secretKey = "foobar";
    private String sessionToken = "foobar";

    public StaticCredentialsProvider() {

        if (KEYSET_DATABASE.isEmpty()) {  // only load once per testing session
            Map<String, String> credentials = new HashMap<>();
            try (Scanner scanner = new Scanner(new File(Context.CREDENTIAL_KEY_FILE))) {
                while (scanner.hasNextLine()) {
                    String s = scanner.nextLine();
                    if (s.matches("\\[.*]")) { // key set name, e.g. [dcp-dev]
                        s = s.substring(1, s.length() - 1); // strip off enclosing brackets
                        credentials = new HashMap<>();
                        KEYSET_DATABASE.put(s, credentials);
                    } else {  // must be a key value
                        s = s.replaceAll("\\s ", ""); // remove all whitespace
                        String[] tokens = s.split("=");
                        if (tokens.length == 2) { // ignore invalid lines. We will check the validity of the keyset in withKeyset()
                            credentials.put(tokens[0], tokens[1]);
                        }
                    }
                }
            } catch (Exception e) {
                LOG.info("Could not load credentials file: " + e + ", will attempt to load default credentials");
            }
        }
    }

    public StaticCredentialsProvider withKeyset(String keySet) {
        if (KEYSET_DATABASE.isEmpty()) {
            return this; // assume default credentials
        }
        if (!KEYSET_DATABASE.containsKey(keySet)) {
            LOG.error("No key set found in credentials file for: " + keySet);
            System.exit(1);
        }
        Map<String, String> keys = KEYSET_DATABASE.get(keySet);
        boolean isValidKeySet = keys.containsKey("aws_access_key_id")
                && keys.containsKey("aws_secret_access_key")
                && keys.containsKey("aws_session_token");
        if (!isValidKeySet) {
            LOG.error("Invalid key set found in credentials file for: " + keySet);
            System.exit(1);
        }
        accessKey = keys.get("aws_access_key_id");
        secretKey = keys.get("aws_secret_access_key");
        sessionToken = keys.get("aws_session_token");
        return this;
    }


    @Override
    public AwsCredentials resolveCredentials() {
        return AwsSessionCredentials.builder().accessKeyId(accessKey).secretAccessKey(secretKey).sessionToken(sessionToken).build();
    }
}
