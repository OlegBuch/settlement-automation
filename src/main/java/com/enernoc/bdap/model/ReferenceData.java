package com.enernoc.bdap.model;

import java.util.HashMap;
import java.util.List;

public class ReferenceData {

    public String code;
    public Integer id;
    public List<String> can_move_to_code;
    public HashMap<String, String> display_labels;

    public static String convertQueryParmToEndpoint(String queryParm) {
        if ("business_process_status".equals(queryParm)) {
            return "settlement_business_process_statuses";
        }
        return String.format("%s%s", queryParm, queryParm.charAt(queryParm.length() - 1) == 's' ? "es" : "s");
    }
}
