package com.enernoc.bdap.model;

public enum RegistrationAdjective {

        NEW, UPDATE, MANUAL_UPDATE, HISTORY_MANUAL_UPDATE, DELETE, RECREATE;

        public static RegistrationAdjective get(String typeName) {
            return RegistrationAdjective.valueOf(typeName.toUpperCase());

    }
}
