package com.enernoc.bdap.model;

import java.util.List;
import java.util.HashMap;
import java.util.Map;
import java.time.ZonedDateTime;

public class ProductRuleFragments {

    public int id;
    public String name;
    public List<Parameter> parameters;
    public String last_updated_dttm_utc;
    public String last_updated_by;
    public String description;
    public Map<String, Object> validator;

    public static class Parameter {
        public int id;
        public String name;
        public boolean required;
        public String type;
        public List<Detail> details;
    }

    public static class Detail {
        public int id;
        public int pr_group_id;
        public int pr_parameter_def_id;
        public String value;
        public String start_dttm_utc;
        public String end_dttm_utc;
        public String last_updated_dttm_utc;
        public String last_updated_by;
    }

    /**
     * Collects parameter details whose date range overlaps [rangeStart, rangeEnd).
     * Returns a map of parameter name -> list of matching Detail entries.
     */
    public Map<String, List<Detail>> getDetailsForDateRange(
            ZonedDateTime rangeStart, ZonedDateTime rangeEnd) {

        Map<String, List<Detail>> result = new HashMap<>();
        if (parameters == null) return result;

        for (var param : parameters) {
            if (param.details == null) continue;

            var matching = param.details.stream()
                    .filter(d -> {
                        var detailStart = ZonedDateTime.parse(
                                d.start_dttm_utc.replace(" ", "T")
                                        .replaceAll("\\+00$", "+00:00"));
                        var detailEnd   = ZonedDateTime.parse(
                                d.end_dttm_utc.replace(" ", "T")
                                        .replaceAll("\\+00$", "+00:00"));
                        // Overlap: detail starts before rangeEnd AND ends after rangeStart
                        return detailStart.isBefore(rangeEnd) && detailEnd.isAfter(rangeStart);
                    })
                    .toList();

            if (!matching.isEmpty()) {
                result.put(param.name, matching);
            }
        }
        return result;
    }
}