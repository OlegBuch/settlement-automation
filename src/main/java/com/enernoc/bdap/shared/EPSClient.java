package com.enernoc.bdap.shared;

import com.enernoc.bdap.model.EventWorkflowRow;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.sql.*;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;


public class EPSClient {

    private static final Logger LOG = LoggerFactory.getLogger("EPSClient");
    private final Context context = Context.getContext();

    private final String url;
    private final String user;
    private final String password;


    public EPSClient(HashMap<String, String> secretValues) {
        url =  String.format("jdbc:postgresql://%s:%s/%s?ssl=true&sslmode=require",
                Context.stmCreateSecretValues.getOrDefault("EPS_DB_HOST", "missing"),
                secretValues.getOrDefault("EPS_DB_PORT", "missing"),
                secretValues.getOrDefault("EPS_DB_DATABASE", "missing"));
        user = secretValues.getOrDefault("EPS_DB_USERNAME", "missing");
        password = secretValues.getOrDefault("EPS_DB_PASSWORD", "missing");
    }


    public List<EventWorkflowRow> getEpsWorkflowRows(String column, String value) throws Throwable {

        String query = "select * from event_node_workflow"
                + String.format(" where %s = '%s' order by event_node_start_time asc", column, value);
        LOG.info("POSTGRESQUERY=" + query);

        List<EventWorkflowRow> rows = new ArrayList<>();
        try (Connection con = DriverManager.getConnection(this.url, this.user, this.password);
             Statement st = con.createStatement();
             ResultSet rs = st.executeQuery(query)) {
            while (rs.next()) {
                rows.add(buildEventWorkflowRow(rs));
            }
        } catch (SQLException ex) {
            LOG.info("Error executing db " + ex.getMessage());
            throw ex;
        }
        return rows;
    }


    private EventWorkflowRow buildEventWorkflowRow(ResultSet rs) throws SQLException {
        var r = new EventWorkflowRow();
        r.event_node_id = rs.getString("event_node_id");
        r.product_id = rs.getString("product_id");
        r.registration_id = rs.getString("registration_id");
        r.registration_id = rs.getString("registration_set_id");
        r.workflow_status = rs.getString("workflow_status");
        r.event_node_start_time = normalizeEventWorkflowDateTime(rs.getString("event_node_start_time"));
        r.event_node_end_time = normalizeEventWorkflowDateTime(rs.getString("event_node_end_time"));
        r.curtail_complete = normalizeEventWorkflowDateTime(rs.getString("curtail_complete"));
        r.curtail_exception_resolved = normalizeEventWorkflowDateTime(rs.getString("curtail_exception_resolved"));
        r.cancelled = normalizeEventWorkflowDateTime(rs.getString("cancelled"));
        return r;
    }


    public static ZonedDateTime normalizeEventWorkflowDateTime(String source) {
        if (source == null) {
            return null;
        }
        var local = LocalDateTime.parse(source.replace(" ", "T"));
        return ZonedDateTime.of(local, ZoneId.of("UTC"));
    }
}
