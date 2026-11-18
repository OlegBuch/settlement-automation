package com.enernoc.bdap.shared;

import com.enernoc.bdap.model.RequestContainer;

import java.time.ZonedDateTime;
import java.util.*;
import java.util.stream.Collectors;

import static com.enernoc.bdap.model.Endpoint.GET_SETTLEMENT_ITEM_INTERVALS;
import static org.junit.jupiter.api.Assertions.*;
import static org.junit.jupiter.api.Assertions.assertFalse;

public class EntityValidator {

    private RequestContainer request;
    private HashMap<String, Object> expected = new HashMap<>();
    private HashMap<String, Object> actual  = new HashMap<>();
    private boolean ignoreActualNulls = false;

    public static EntityValidator build() {
        return new EntityValidator();
    }


    public EntityValidator withRequest(RequestContainer requestp) {
        this.request = requestp;
        this.actual.putAll(request.getDataAsList().get(0));
        assertFalse(this.actual.isEmpty(), "Entity not returned in response!!");
        return this;
    }

    public EntityValidator withActual(RequestContainer requestp, HashMap<String, Object> actualMap) {
        this.request = requestp;
        this.actual.putAll(actualMap);
        assertFalse(this.actual.isEmpty(), "Entity not returned in response!!");
        return this;
    }

    public EntityValidator withExpected(HashMap<String, Object> expectedp) {
        this.expected.putAll(expectedp);
        return this;
    }

    public EntityValidator removeExpectedNulls() {
        expected = new HashMap<>(expected.entrySet().stream().filter(entry -> entry.getValue() != null).collect(Collectors.toMap(Map.Entry::getKey, Map.Entry::getValue)));
        return this;
    }

    public EntityValidator ignoreActualNulls() {
        ignoreActualNulls = true;
        return this;
    }

    public List<String> compare() {
        List<String> errors = new ArrayList<>();

        assertFalse(expected.isEmpty(),"No expected entity");
        assertFalse(actual.isEmpty(),"No actual entity");

        // Some endpoints return change_comments, some don't, but it's only important in audit log,
        // and our audit log validation verifies it explicitly, so we can ignore it here.
        // However, there's a special case where PUT doesn't actually cause an update.
        boolean isUpdateExpected = !"No update expected".equals(expected.getOrDefault("change_comments","na"));
        expected.remove("change_comments");
        actual.remove("change_comments");


        // Validate last_updated_dttm_utc and last_updated_by added by endpoint
        String key = "last_updated_by";
        if (actual.containsKey(key) && !expected.containsKey(key)) {  // if expected also contains the key, we'll check for equality below
            String lub = actual.get(key).toString();
            try {
                UUID uuid = UUID.fromString(lub); // validate that value matches uuid schema
            } catch (Exception e) {
                errors.add(String.format("Invalid 'last_updated_by': '%s'!", lub));
            }
            actual.remove(key);
        }
        key = "last_updated_dttm_utc";
        if (actual.containsKey(key) && !expected.containsKey(key)) {
            if (isUpdateExpected) {
                String lastUpdatedDttm = actual.get(key).toString();
                ZonedDateTime dttm = ZonedDateTime.parse(lastUpdatedDttm);
                if (!GET_SETTLEMENT_ITEM_INTERVALS.equals(request.endpoint)) {  // interval list will have earlier timestamps, so no point in verifying
                    if (dttm.toEpochSecond() < Context.crudEpoch) {
                        errors.add(String.format("last_updated_dttm_utc '%s' is BEFORE the time CRUD request is sent '%s'!", lastUpdatedDttm, Utility.epochToString(Context.crudEpoch)));
                    } else if ((dttm.toEpochSecond() - Context.crudEpoch) > 30) {
                        errors.add(String.format("last_updated_dttm_utc '%s' is greater than 30 seconds after the time CRUD request is sent '%s'!", lastUpdatedDttm, Utility.epochToString(Context.crudEpoch)));
                    }
                }
            }
            actual.remove(key);
            expected.remove(key); // we don't want to compare against any previous value
        }

        // Validate created_dttm_utc (returned for intervals only)
        key = "created_dttm_utc";
        if (actual.containsKey(key) && !expected.containsKey(key)) {  // if expected also contains the key, we'll check for equality below
            String lastUpdatedDttm = actual.get(key).toString();
            ZonedDateTime dttm = ZonedDateTime.parse(lastUpdatedDttm);
               if (dttm.toEpochSecond() < Context.testStartEpoch) {
                    errors.add(String.format("created_dttm_utc '%s' is BEFORE the test initialization time '%s'!", lastUpdatedDttm, Utility.epochToString(Context.testStartEpoch)));
                } else if ((dttm.toEpochSecond() - Context.testStartEpoch) > 600) {  // we are assuming that no feature-file will take longer than 10 minutes to run
                    errors.add(String.format("created_dttm_utc '%s' is greater than 10 minutes after the test initialization time '%s'!", lastUpdatedDttm, Utility.epochToString(Context.testStartEpoch)));
                }
            actual.remove(key);
        }

        expected.forEach((name, expval) ->{
            Object actval = actual.getOrDefault(name, "Missing");
            actual.remove(name);
            if (name.endsWith("utc") && expval != null) { // this is needed for compensate for inconsistent formatting of timestamps in responses
                expval = ZonedDateTime.parse(expval.toString()).toString();
                actval = ZonedDateTime.parse(actval.toString()).toString();
            }
            if (expval instanceof Double && actval instanceof Integer) {
                actval = Double.valueOf((Integer) actval);
            }
            if (strIsNumber(expval) && strIsNumber(actval)) {
                Double exptemp = Double.parseDouble((String) expval);
                Double acttemp = Double.parseDouble((String) actval);
                if (!acttemp.equals(exptemp)) {
                    errors.add(String.format("Unexpected value returned in response for '%s'. Expected: '%s'  Actual: '%s'", name, expval, actval));
                }
            } else {
                if (!Objects.equals(expval, actval)) {
                    errors.add(String.format("Unexpected value returned in response for '%s'. Expected: '%s'  Actual: '%s'", name, expval, actval));
                }
            }
        });

        // GET settlement defaults the following properties to null
        if (actual.containsKey("product_id") && actual.get("product_id") == null) {
           actual.remove("product_id");
       }
        if (actual.containsKey("processing_status") && actual.get("processing_status") == null) {
            actual.remove("processing_status");
        }

        // GET settlement_item defaults the following properties to null
        if (actual.containsKey("sub_settlement_items") && actual.get("sub_settlement_items") == null) {
            actual.remove("sub_settlement_items");
        }
        if (actual.containsKey("intervals") && actual.get("intervals") == null) {
            actual.remove("intervals");
        }

        // If 'deleted' wasn't expected but its value is null or false, ignore it
        if (actual.containsKey("deleted") && (actual.get("deleted") == null || (!(Boolean) actual.get("deleted")))) {
            actual.remove("deleted");
        }

        // If 'deleted' wasn't expected but its value is true and include_deleted = true, ignore it
        if (actual.containsKey("deleted") && ((Boolean) actual.getOrDefault("deleted", false))) {
            Context.getContext().includeDeletedOpt.ifPresent(value -> {
                if (value) actual.remove("deleted");
            });
        }

        // Now check for extra properties returned
        if (ignoreActualNulls) {
            actual.entrySet().removeIf(entry -> entry.getValue() == null);
        }
        actual.forEach((name, val) -> errors.add(String.format("Extra property returned in response. '%s': '%s'", name, val == null ? "null" : val.toString())));
        return errors;
    }

    private boolean strIsNumber(Object str) {
        if (!(str instanceof String)) {
            return false;
        }
        try {
            Double.parseDouble((String) str);
            return true;
        } catch (NumberFormatException e) {
            return false;
        }
    }
}
