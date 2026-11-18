package com.enernoc.bdap.model;

import java.util.List;

public class ProductRules {

    public String id;
    public String product_id;
    public String name;
    public String last_updated_dttm_utc;
    public String last_updated_by;
    public List<ProductRuleGroups> groups;

    // ✅ getGroups() — required by step code
    public List<ProductRuleGroups> getGroups() {
        return groups;
    }

    public static class ProductRuleGroups {
        public int id;
        public String name;
        public int product_rule_id;
        public String last_updated_dttm_utc;
        public String last_updated_by;
        public List<ProductRuleFragments> fragments;

        // ✅ getFragments() — required by step code
        public List<ProductRuleFragments> getFragments() {
            return fragments;
        }
    }
}