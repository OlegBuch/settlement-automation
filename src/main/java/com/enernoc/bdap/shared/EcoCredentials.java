package com.enernoc.bdap.shared;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.File;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;

/**
 * Resolves ECO passwords, which are no longer stored in configuration.json.
 * Usernames stay in configuration.json ("ecoUsers" / "ecoExternalUsers").
 *
 * Lookup order for section / env / userKey (e.g. ecoUsers / preprd / admin):
 *   1. environment variable  ECOUSERS_PREPRD_ADMIN_PASSWORD
 *   2. local, gitignored file config/eco-credentials.local.json
 *      { "ecoUsers": { "preprd": { "admin": { "password": "..." } } } }
 *   3. AWS Secrets Manager secret "qaa-<env>", key ECOUSERS_ADMIN_PASSWORD
 */
public final class EcoCredentials {

    private static final Logger LOG = LoggerFactory.getLogger("EcoCredentials");
    private static final ObjectMapper JSON = new ObjectMapper();
    public static final String LOCAL_FILE = "config/eco-credentials.local.json";

    private static Map<String, Map<String, Map<String, Map<String, String>>>> localFile;

    private EcoCredentials() {
    }

    public static String password(String section, String env, String userKey) {
        String envVar = String.format("%s_%s_%s_PASSWORD", section, env, userKey)
                .toUpperCase(Locale.ROOT).replaceAll("[^A-Z0-9_]", "_");
        String fromEnv = System.getenv(envVar);
        if (fromEnv != null && !fromEnv.isBlank()) {
            return fromEnv;
        }

        Optional<String> fromFile = fromLocalFile(section, env, userKey);
        if (fromFile.isPresent()) {
            return fromFile.get();
        }

        String secretKey = String.format("%s_%s_PASSWORD", section, userKey)
                .toUpperCase(Locale.ROOT).replaceAll("[^A-Z0-9_]", "_");
        String fromSecret = Context.idsSecretValues.get(secretKey);
        if (fromSecret != null && !fromSecret.isBlank()) {
            return fromSecret;
        }

        throw new IllegalStateException(String.format(
                "No password for %s/%s/%s. Set env var %s, add it to %s, or add key %s to AWS secret qaa-%s.",
                section, env, userKey, envVar, LOCAL_FILE, secretKey, env));
    }

    private static synchronized Optional<String> fromLocalFile(String section, String env, String userKey) {
        if (localFile == null) {
            File file = new File(LOCAL_FILE);
            if (!file.isFile()) {
                localFile = Map.of();
            } else {
                try {
                    localFile = JSON.readValue(file, new TypeReference<>() {
                    });
                } catch (Exception e) {
                    LOG.warn("Could not read {}: {}", LOCAL_FILE, e.getMessage());
                    localFile = Map.of();
                }
            }
        }
        return Optional.ofNullable(localFile.get(section))
                .map(envs -> envs.get(env))
                .map(users -> users.get(userKey))
                .map(creds -> creds.get("password"))
                .filter(p -> !p.isBlank());
    }
}
