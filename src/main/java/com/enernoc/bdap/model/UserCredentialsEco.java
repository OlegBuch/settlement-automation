package com.enernoc.bdap.model;

import com.enernoc.bdap.shared.Context;
import com.enernoc.bdap.shared.EcoCredentials;
import java.util.Map;

public enum UserCredentialsEco {

    ECO_USER("user"),
    ECO_ADMIN("admin");

    private final String configKey;

    // Cached values - populated on first access via getters
    private String username;
    private String password;
    private boolean initialized = false;

    UserCredentialsEco(String configKey) {
        this.configKey = configKey;
    }

    /**
     * Lazily loads credentials from Context.ecoUserCredentials on first access.
     * Safe to call after Context static block has run.
     */
    private void ensureInitialized() {
        if (initialized) return;

        Map<String, String> creds = getStringStringMap();
        this.username = creds.get("username");
        if (this.username == null) {
            throw new IllegalStateException(
                    String.format("ECO username missing in configuration.json for env=%s, key=%s",
                            Context.targetEnv, configKey));
        }
        this.password = EcoCredentials.password("ecoUsers", Context.targetEnv, configKey);

        this.initialized = true;
    }

    private Map<String, String> getStringStringMap() {
        Map<String, Map<String, Map<String, String>>> ecoUsers = Context.ecoUserCredentials;
        Map<String, Map<String, String>> envUsers = ecoUsers != null
                ? ecoUsers.get(Context.targetEnv)
                : null;
        Map<String, String> creds = envUsers != null
                ? envUsers.get(configKey)
                : null;

        if (creds == null || !creds.containsKey("username")) {

            throw new IllegalStateException(
                    String.format("ECO credentials not found in configuration.json for env=%s, key=%s",
                            Context.targetEnv, configKey));
        }
        return creds;
    }

    public String getUsername() {
        ensureInitialized();
        return username;
    }

    public String getPassword() {
        ensureInitialized();
        return password;
    }
}