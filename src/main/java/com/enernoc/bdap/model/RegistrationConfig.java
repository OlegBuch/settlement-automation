package com.enernoc.bdap.model;

import com.enernoc.bdap.shared.Context;

import java.util.Map;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

public class RegistrationConfig {

    public Map<String, Registration> registrations;

    public static class Registration {
        public String name;
        public String devUuid;
        public String preprdUuid;
        public FlexibleAsset flexibleAsset;
        public ServiceDeliveryPoint serviceDeliveryPoint;
        public Site site;

        public static class FlexibleAsset {
            public String devUuid;
            public String preprdUuid;
        }

        public static class ServiceDeliveryPoint {
            public String devUuid;
            public String preprdUuid;
        }

        public static class Site {
            public String name;
            public String devUuid;
            public String preprdUuid;
        }
    }

    public Registration getRegistrationByName(String name) {
        assertTrue(registrations.containsKey(name), String.format("Registration %s not found in configuration.json!!", name));
        return registrations.get(name);
    }

    public static String getRegistrationId(String regName) {
        var reg = Context.registrationConfigs.getRegistrationByName(regName);
        var id = switch (Context.targetEnv) {
            case "devtest", "dev" -> reg.devUuid;
            case "preprd" -> reg.preprdUuid;
            default -> "";
        };
        assertFalse(id.isBlank(), String.format("Registration '%s' does not have an id for '%s' in configuration.json!", regName, Context.targetEnv));
        return id;
    }

    public static String getFlexibleAssetId(String regName) {
        var reg = Context.registrationConfigs.getRegistrationByName(regName);
        var id = switch (Context.targetEnv) {
            case "devtest", "dev" -> reg.flexibleAsset.devUuid;
            case "preprd" -> reg.flexibleAsset.preprdUuid;
            default -> "";
        };
        assertFalse(id.isBlank(), String.format("Registration '%s' does not have a flexible asset id for '%s' in configuration.json!", regName, Context.targetEnv));
        return id;
    }

    public static String getServiceDeliveryPointId(String regName) {
        var reg = Context.registrationConfigs.getRegistrationByName(regName);
        var id = switch (Context.targetEnv) {
            case "devtest", "dev" -> reg.serviceDeliveryPoint.devUuid;
            case "preprd" -> reg.serviceDeliveryPoint.preprdUuid;
            default -> "";
        };
        assertFalse(id.isBlank(), String.format("Registration '%s' does not have a service delivery point id for '%s' in configuration.json!", regName, Context.targetEnv));
        return id;
    }

    public static String getSiteIdFromName(String regName) {
        var reg = Context.registrationConfigs.getRegistrationByName(regName);
        var id = switch (Context.targetEnv) {
            case "devtest", "dev" -> reg.site.devUuid;
            case "preprd" -> reg.site.preprdUuid;
            default -> "";
        };
        assertFalse(id.isBlank(), String.format("Registration '%s' does not have a service delivery point id for '%s' in configuration.json!", regName, Context.targetEnv));
        return id;
    }

    // This method follows the algorithm in ITAPPSIT-3399
    public static String getSiteIdFromSdpOrFa(String sdpUuid, String faUuid) {
        String siteId = "";
        Optional<Registration> regOpt = Optional.empty();

        if (sdpUuid != null && !sdpUuid.isBlank()) { // First try to get the site via the SDP
            regOpt = Context.registrationConfigs.registrations.values().stream()
                    .filter(r -> sdpUuid.equals(switch (Context.targetEnv) {
                case "devtest", "dev" -> r.serviceDeliveryPoint.devUuid;
                case "preprd" -> r.serviceDeliveryPoint.preprdUuid;
                default -> "invalid env";
            })).findFirst();
        }

        if (regOpt.isEmpty() && faUuid != null && !faUuid.isBlank()) { // Try to get the site from the FA
            regOpt = Context.registrationConfigs.registrations.values().stream()
                    .filter(r -> faUuid.equals(switch (Context.targetEnv) {
                        case "devtest", "dev" -> r.flexibleAsset.devUuid;
                        case "preprd" -> r.flexibleAsset.preprdUuid;
                        default -> "invalid env";
                    })).findFirst();
        }

        if (regOpt.isPresent()) {
            siteId = switch (Context.targetEnv) {
                case "devtest", "dev" -> regOpt.get().site.devUuid;
                case "preprd" -> regOpt.get().site.preprdUuid;
                default -> "";
            };
        }
        assertFalse(siteId.isBlank(), "No site id found '%s' does not have a site id in configuration.json!");
        return siteId;
    }

}