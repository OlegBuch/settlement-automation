package com.enernoc.bdap.shared;

import com.enernoc.bdap.model.RegistrationConfig;

import java.time.Instant;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static java.time.ZoneOffset.UTC;
import static org.junit.jupiter.api.Assertions.*;


public class Utility {

    private final Context context = Context.getContext();

    private final List<String> doNotConvertList = List.of("payment_value", "revenue_value", "payment_penalty_value", "payment_value_estimated", "revenue_value_estimated");


    public  void replaceParmValues(HashMap<String, Object> params) {

        params.forEach((name, value) -> {
            if (value == null) {
                // For empty cells empty string semantics:
                 params.replace(name, "");
                return;
            }
            String strippedValue = value.toString().replace("<", "").replace(">", "");
            if ("site_id".equals(name) && Context.itsMappings.containsKey(strippedValue)) {
                params.replace(name, getItsMapping(strippedValue));
            } else {
                switch (value.toString()) {
                    case "<uuid>" -> params.replace(name, UUID.randomUUID().toString());
                    case "<fixed-uuid>" -> params.replace(name, "00000000-1111-2222-3333-444455556666");
                    case "<username>" -> params.replace(name, UUID.randomUUID().toString().substring(0, 5) + "@enel.com");
                    case "<null>" -> params.replace(name, null);
                    case "<empty-string>", "<empty>" -> params.replace(name, "");
                    case "<random-int>" -> params.replace(name, (int) (Math.random() * 10000));
                    case "<last-event-id>" -> {
                        assertFalse(context.lastEventId.isBlank());
                        params.replace(name, context.lastEventId);
                    }
                    case "<saved-event-id>" -> {
                        assertFalse(context.savedEventId.isBlank());
                        params.replace(name, context.savedEventId);
                    }
                    case "<last-settlement-id>" -> {
                        assertFalse(context.lastSettlementId.isBlank());
                        params.replace(name, context.lastSettlementId);
                    }
                    case "<last-settlement-item-id>" -> {
                        assertFalse(context.lastSettlementItemId.isBlank());
                        params.replace(name, context.lastSettlementItemId);
                    }
                    case "<dlq-settlement-item-id>" -> {
                        assertFalse(context.lastDlqSettlementItemId.isBlank());
                        params.replace(name, context.lastDlqSettlementItemId);
                    }
                    case "<settlement-item-id-1>" -> {
                        assertFalse(context.savedSettlementItemId1.isBlank());
                        params.replace(name, context.savedSettlementItemId1);
                    }
                    case "<settlement-item-id-2>" -> {
                        assertFalse(context.savedSettlementItemId2.isBlank());
                        params.replace(name, context.savedSettlementItemId2);
                    }
                    case "<last-settlement-level-id>" -> {
                        assertFalse(context.lastSettlementLevelId.isBlank());
                        params.replace(name, context.lastSettlementLevelId);
                    }
                    case "<last-atlas-settlement-level-id>" -> {
                        assertFalse(context.lastAtlasSettlementLevelId == null || context.lastAtlasSettlementLevelId.isBlank());
                        params.replace(name, context.lastAtlasSettlementLevelId);
                    }
                    case "<last-registration-id>" -> {
                        assertFalse(context.lastRegistrationId.isBlank());
                        params.replace(name, context.lastRegistrationId);
                    }
                    case "<last-registration-set-id>" -> {
                        assertFalse(context.lastRegistrationSetId.isBlank());
                        params.replace(name, context.lastRegistrationSetId);
                    }
                    case "<last-portfolio-id>" -> {
                        assertFalse(context.lastPortfolioId.isBlank());
                        params.replace(name, context.lastPortfolioId);
                    }
                    case "<last-updated-by>" -> {
                        assertFalse(context.lastUpdatedBy.isBlank());
                        params.replace(name, context.lastUpdatedBy);
                    }
                    case "<last-updated-dttm-utc>" -> {
                        assertFalse(context.lastUpdatedDttmUtc.isBlank());
                        params.replace(name, context.lastUpdatedDttmUtc);
                    }
                    case "<last-pipeline-run-id>" -> {
                        assertFalse(context.lastPipelineRunId.isBlank());
                        params.replace(name, context.lastPipelineRunId);
                    }
                    case "<product1>" -> {
                        assertFalse(Context.productId1.isBlank());
                        params.replace(name, Context.productId1);
                    }
                    case "<product2>" -> {
                        assertFalse(Context.productId2.isBlank());
                        params.replace(name, Context.productId2);
                    }
                    case "<product3>" -> {
                        assertFalse(Context.productId3.isBlank());
                        params.replace(name, Context.productId3);
                    }
                    case "<registration1>", "<registration2>", "<registration3>", "<registration4>", "<registration5>", "<registration6>", "<registration7>" -> {
                        params.replace(name, RegistrationConfig.getRegistrationId(strippedValue));
                    }
                    case "<registration1-fa>", "<registration2-fa>", "<registration3-fa>", "<registration4-fa>", "<registration5-fa>", "<registration6-fa>", "<registration7-fa>" -> {
                        params.replace(name, RegistrationConfig.getFlexibleAssetId(strippedValue.replace("-fa", "")));
                    }
                    case "<registration1-sdp>", "<registration2-sdp>", "<registration3-sdp>", "<registration4-sdp>", "<registration5-sdp>", "<registration6-sdp>", "<registration7-sdp>" -> {
                        params.replace(name, RegistrationConfig.getServiceDeliveryPointId(strippedValue.replace("-sdp", "")));
                    }
                    case "<missing>" -> {
                    } // this needs special treatment by caller
                    default -> { // tag for generic saved values
                        if (value.toString().startsWith("<") && value.toString().endsWith(">")) {
                            String val = value.toString();
                            String tag = val.substring(1, val.length() - 1);
                            assertTrue(context.savedValues.containsKey(tag), "Saved values does not contain '" + tag + "'");
                            params.replace(name, context.savedValues.get(tag));
                        } else { // convert number strings to numbers (except for Decimal fields)
                            if (value instanceof String && !doNotConvertList.contains(name)) {
                                if (value.toString().matches("-??\\d+")) {
                                    try {
                                        int val = Integer.parseInt(value.toString());
                                        params.replace(name, val);
                                    } catch (NumberFormatException e) {
                                        // keep value as string
                                    }
                                } else if (value.toString().matches("-??\\d+[.]??\\d+")) {
                                    try {
                                        double val = Double.parseDouble(value.toString());
                                        params.replace(name, val);
                                    } catch (NumberFormatException e) {
                                        // keep value as string
                                    }
                                }
                            }
                        }
                    }
                }
            }
        });
    }


    public static String epochToString(long epochSecond) {
        return ZonedDateTime.ofInstant(Instant.ofEpochSecond(epochSecond), UTC).format(DateTimeFormatter.ISO_INSTANT);
    }


    public static String epochToStringFull(long epochSecond, ZoneId zone) {
        return ZonedDateTime.ofInstant(Instant.ofEpochSecond(epochSecond), zone).format(DateTimeFormatter.ISO_ZONED_DATE_TIME);
    }


    public static ZonedDateTime epochToZonedDateTimeUTC(long epochSecond) {
        return ZonedDateTime.ofInstant(Instant.ofEpochSecond(epochSecond), UTC);
    }


    public static String normalizeDateTime(String source) {
        if (source == null) return "null";
        return ZonedDateTime.parse(source.replace(" ", "T"))
                .withZoneSameInstant(ZoneId.of("UTC"))
                .format(Context.fullDttmFormat);
    }


    public static String normalizeZonedDateTime(ZonedDateTime source) {
        if (source == null) return "null";
        return source
                .withZoneSameInstant(ZoneId.of("UTC"))
                .format(Context.fullDttmFormat);
    }


    public static void stringToBoolean(HashMap<String, Object> map) {
        map.forEach((name, value) -> {
            if (value != null) {
                switch (value.toString()) {
                    case "true" -> map.replace(name, true);
                    case "false" -> map.replace(name, false);
                    case "null"  -> map.replace(name, null);
                }
            }
        });
    }


    public static String objectToStringOrNull(Object obj) {
        return (obj == null) ? null : obj.toString();
    }


    public static boolean testStringNotNullOrBlank(String str) {
        return (str != null && !str.isBlank());
    }


    public static boolean testObjsEqual(String name, Object expected, Object actual) {
        if (expected == null && actual == null) {
            return true;
        }
        if (expected != null) {
            if (name.contains("dttm")) {
                var expectedDttm = ZonedDateTime.parse(expected.toString());
                var actualDttm = ZonedDateTime.parse(actual.toString());
                return expectedDttm.isEqual(actualDttm);
            }
            if (expected instanceof Double && actual instanceof Integer) {
                return expected.equals(Double.parseDouble(String.valueOf(actual)));
            }
            if (expected instanceof Double && actual instanceof Double) {
                return areDoublesEqualEnough((Double) expected, (Double) actual);
            }
            return expected.equals(actual);
        }
        return false; // expected == null && actual != null
    }


    public static boolean areDoublesEqualEnough(Double expected, Double actual) {
        if (expected == null || actual == null) {
            fail("Value is null!!");
            return false;  // unreachable but makes compiler happy
        }
        if (expected.equals(actual)) {
            return true;
        }
        // If direct comparison of doubles failed, try comparing to a fixed precision
        String format = expected > 10000 ? "%.3f" : "%.6f";
        String expectedStr = String.format(format, expected);
        String actualStr = String.format(format, actual);
        return (expectedStr.equals(actualStr));
    }


    public static String getOrganizationId(String name) {
        assertTrue(Context.organizationIds.containsKey(name), String.format("Organization '%s' not found in configuration.json!", name));
        HashMap<String, String> envIds = Context.organizationIds.get(name);
        String env = "devtest".equals(Context.targetEnv) ? "dev" : Context.targetEnv;
        assertTrue(envIds.containsKey(env), String.format("Organization '%s' does not have an id for '%s' in configuration.json!", name, env));
        return envIds.get(env);
    }


    public static String getItsMapping(String name) {
        assertTrue(Context.itsMappings.containsKey(name), String.format("ITS mapping '%s' not found in configuration.json!", name));
        HashMap<String, String> envIds = Context.itsMappings.get(name);
        String env = "devtest".equals(Context.targetEnv) ? "dev" : Context.targetEnv;
        assertTrue(envIds.containsKey(env), String.format("ITS mapping '%s' does not have an id for '%s' in configuration.json!", name, env));
        return envIds.get(env);
    }


    public static String getProductRuleFromConfig(String name) {
        assertTrue(Context.productRules.containsKey(name), String.format("Product rule '%s' not found in configuration.json!", name));
        HashMap<String, String> envIds = Context.productRules.get(name);
        String env = "devtest".equals(Context.targetEnv) ? "dev" : Context.targetEnv;
        assertTrue(envIds.containsKey(env), String.format("Product rule '%s' does not have an id for '%s' in configuration.json!", name, env));
        assertFalse(envIds.get(env).isBlank(), "Product rule id is empty in configuration.json!");
        return envIds.get(env);
    }

    public static boolean nateOverlaps(long startEpochMs, long endEpochMs, long startEpochMs2, long endEpochMs2) {

        if (startEpochMs > endEpochMs || startEpochMs2 > endEpochMs2) {
            fail();
        }

        //both date ranges are the same point
        if (startEpochMs == endEpochMs && startEpochMs2 == endEpochMs2 && startEpochMs == startEpochMs2) {
            return true;
        }

        //start of one date range is within the other
        if (startEpochMs <= startEpochMs2 && startEpochMs2 < endEpochMs) {
            return true;
        }
        if (startEpochMs2 <= startEpochMs && startEpochMs < endEpochMs2) {
            return true;
        }

        return false;
    }


    public static boolean datesOverlap(long blueStart, long blueEnd, long redStart, long redEnd) {
        //mimic postgres's "overlaps" function
        //return true if two date ranges overlap
        //start date is inclusive, end date is exclusive (unless start = end, in which case it is inclusive)
        if (blueStart > blueEnd || redStart > redEnd) {
            fail("Utility.datesOverlap(): blueStart must be <= blueEnd and redStart must be <= redEnd");
        }
        if (blueStart == blueEnd && redStart == redEnd && blueStart == redEnd) {
            return true;
        }
        if (blueStart <= redStart && redStart < blueEnd) {
            return true;
        }
        if (redStart <= blueStart && blueStart < redEnd) {
            return true;
        }
        return false;
    }


    public static boolean datesOverlap(ZonedDateTime blueStart, ZonedDateTime blueEnd, ZonedDateTime redStart, ZonedDateTime redEnd) {
        return datesOverlap(blueStart.toEpochSecond(), blueEnd.toEpochSecond(), redStart.toEpochSecond(), redEnd.toEpochSecond());
    }


    public static ZonedDateTime roundTimeUpToInterval(ZonedDateTime dttm, int intervalLengthMinutes) {

        var date = dttm.withZoneSameInstant(UTC);

        int minutes = date.getMinute();
        int seconds = date.getSecond();
        int milliseconds = date.getNano() / 1000000;

        int minutesRounded = intervalLengthMinutes * (int) Math.ceil((minutes + seconds / 60.0 + milliseconds / 1000.0 / 60.0) / intervalLengthMinutes);
        if (minutesRounded != minutes) {
            if (minutesRounded == 60) {
                date = date.plusHours(1).withMinute(0);
            } else {
                date = date.withMinute(minutesRounded);
            }
            date = date.withSecond(0).withNano(0);
        }
        return date;
    }


    public static String roundTimeUpToInterval(String dttm, int intervalLengthMinutes) {
        return Utility.normalizeZonedDateTime(roundTimeUpToInterval(ZonedDateTime.parse(dttm), intervalLengthMinutes));
    }


    public static String getMinimumDate(String blue, String red) {
        var blueDttm = ZonedDateTime.parse(blue).withZoneSameInstant(UTC);
        var redDttm = ZonedDateTime.parse(red).withZoneSameInstant(UTC);
        return blueDttm.isBefore(redDttm) ?  normalizeZonedDateTime(blueDttm) : normalizeZonedDateTime(redDttm);
    }


    public static String getMaximumDate(String blue, String red) {
        var blueDttm = ZonedDateTime.parse(blue).withZoneSameInstant(UTC);
        var redDttm = ZonedDateTime.parse(red).withZoneSameInstant(UTC);
        return blueDttm.isAfter(redDttm) ?  normalizeZonedDateTime(blueDttm) : normalizeZonedDateTime(redDttm);
    }


    public static boolean areDatesEqual(String blue, String red) {
        var blueDttm = ZonedDateTime.parse(blue.replace(" ", "T")).withZoneSameInstant(UTC);
        var redDttm = ZonedDateTime.parse(red.replace(" ", "T")).withZoneSameInstant(UTC);
        return blueDttm.equals(redDttm);
    }

    public static void stringToNumber(Map<String, Object> params, String... numericKeys) {
        for (String key : numericKeys) {
            Object v = params.get(key);

                if (!(v instanceof String s)) {
                    // v is null, Boolean, Number, etc. – leave as-is
                    continue;
                }

                if (s.isBlank()) {
                    // Empty override: keep as "" so the API sees an invalid value and returns 400
                    // Do NOT convert to null or a number.
                    params.put(key, s);
                    continue;
                }
                try {
                    params.put(key, new java.math.BigDecimal(s)); // or Integer / Long if preferred
                } catch (NumberFormatException ignored) {
                    // leave as string for negative tests
                }
            }
        }

    @SuppressWarnings("unchecked")
    public static Map<String, Object> toStringObjectMap(Object o) {
        if (!(o instanceof Map<?, ?> m)) {
            throw new IllegalArgumentException("Not a Map: " + o);
        }
        for (Object k : m.keySet()) {
            if (!(k instanceof String)) {
                throw new IllegalArgumentException("Non‑String key in map: " + k);
            }
        }
        return (Map<String, Object>) m;
    }



}
