package com.enernoc.bdap.model;

import com.enernoc.bdap.shared.Context;

public enum UserCredentials {

    PRDADMIN(Context.metadataSecretValues.get("ATLAS_SYSTEM_USERNAME"), Context.metadataSecretValues.get("ATLAS_SYSTEM_PASSWORD"), "system"),
    ADMIN(Context.settlementSecretValues.get("QA_ADMIN_USER"), Context.settlementSecretValues.get("QA_ADMIN_PASSWORD"), Context.settlementSecretValues.get("QA_ADMIN_REALM")),
    USER(Context.settlementSecretValues.get("QA_USER_USER"), Context.settlementSecretValues.get("QA_USER_PASSWORD"), Context.settlementSecretValues.get("QA_USER_REALM")),
    // The following user has SETTLEMENT_ADMIN user on dev, but does not have access to products referenced by settlements
    NO_PRODUCT_ACCESS(Context.settlementSecretValues.get("QA_NO_PRODUCT_USER"), Context.settlementSecretValues.get("QA_NO_PRODUCT_PASSWORD"), Context.settlementSecretValues.get("QA_NO_PRODUCT_REALM")),
    NO_STM_ROLES_USER(Context.settlementSecretValues.get("NO_STM_ROLES_USER"), Context.settlementSecretValues.get("NO_STM_ROLES_USER_PWD"), "system");

    public final String username, password, realm;

    UserCredentials(String name, String password, String realm) {

        this.username = name;
        this.password = password;
        this.realm = realm;

    }
}
