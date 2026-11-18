package com.enernoc.bdap.shared;


import com.enernoc.bdap.model.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.sql.*;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;

import static org.junit.jupiter.api.Assertions.*;

public class PostgresClient {

    private final String url;
    private final String schema;
    private final String user;
    private final String password;

    private static final Logger LOG = LoggerFactory.getLogger("PostgresClient");
    private final Context context = Context.getContext();

    public PostgresClient(HashMap<String, String> secretValues) {
        url =  String.format("jdbc:postgresql://%s:%s/%s?ssl=true&sslmode=require",
                secretValues.getOrDefault("DB_MASTER_HOST", secretValues.getOrDefault("DB_HOST", "missing")),
                secretValues.getOrDefault("DB_PORT", "missing"),
                secretValues.getOrDefault("DB_DATABASE", "missing"));
        schema = secretValues.getOrDefault("DB_SCHEMA", "missing");
        user = secretValues.getOrDefault("DB_ADMIN_USER", "missing");
        password = secretValues.getOrDefault("DB_ADMIN_PASSWORD", "missing");
    }


    public void deleteRecordsTable(String dataTable, String condition) throws Throwable {
        assertTrue(Arrays.asList("devtest", "dev", "preprd").contains(Context.targetEnv),
                String.format("Deleting records from '%s' is not supported!", Context.targetEnv));

        try (Connection con = DriverManager.getConnection(this.url, this.user, this.password);
             Statement st = con.createStatement()) {
            String query = String.format("delete from %s.%s where %s", schema, dataTable, condition);
            LOG.info("POSTGRESDELETE=" + query);
            int countdelete = st.executeUpdate(query);
            LOG.info(String.format("postgres deleted the following number of records: %d\n", countdelete));
        } catch (SQLException ex) {
            LOG.info("Error executing db " + ex.getMessage());
            throw ex;
        }
    }

    // Generic helper: select rows from an arbitrary table
    public List<HashMap<String, Object>> selectRecordsTable(String tableName,
                                                            String condition,
                                                            String orderByColumn) throws Exception {

        assertTrue(Arrays.asList("devtest", "dev", "preprd").contains(Context.targetEnv),
                String.format("Selecting records in '%s' env is not supported!", Context.targetEnv));

        StringBuilder builder = new StringBuilder();
        builder.append(String.format("select * from %s.%s", schema, tableName));
        if (condition != null && !condition.isBlank()) {
            builder.append(" where ").append(condition);
        }
        if (orderByColumn != null && !orderByColumn.isBlank()) {
            builder.append(" order by ").append(orderByColumn);
        }
        String query = builder.toString();
        LOG.info("POSTGRESQUERY=" + query);

        List<HashMap<String, Object>> rows = new ArrayList<>();

        try (Connection con = DriverManager.getConnection(this.url, this.user, this.password);
             Statement st = con.createStatement();
             ResultSet rs = st.executeQuery(query)) {

            ResultSetMetaData meta = rs.getMetaData();
            int colCount = meta.getColumnCount();

            while (rs.next()) {
                HashMap<String, Object> row = new HashMap<>();
                for (int i = 1; i <= colCount; i++) {
                    String colName = meta.getColumnLabel(i);
                    row.put(colName, rs.getObject(i));
                }
                rows.add(row);
            }
        } catch (SQLException ex) {
            LOG.info("Error executing db " + ex.getMessage());
            throw ex;
        }

        return rows;
    }


    public TreeMap<Long, RegistrationFieldHistoryRow> getFieldHistoryRows(String query) throws Throwable{
        assertTrue(Arrays.asList("devtest", "dev", "preprd").contains(Context.targetEnv), String.format("Updating records in '%s' env is not supported!", Context.targetEnv));

        var rows = new TreeMap<Long, RegistrationFieldHistoryRow>();

        Statement st = null;
        try (Connection con = DriverManager.getConnection(this.url, this.user, this.password)){
            st = con.createStatement();
            LOG.info("POSTGRESQUERY=" + query);
            try (ResultSet rs = st.executeQuery(query)) {
                while (rs.next()) {
                    var r = new RegistrationFieldHistoryRow();
                    r.registration_history_id = rs.getLong("id");
                    r.registration_id = rs.getString("registration_id");
                    r.field_name = rs.getString("field_name");
                    r.field_value = rs.getString("field_value");
                    r.effective_start_dttm_utc = rs.getString("effective_start_dttm_utc");
                    r.effective_end_dttm_utc = rs.getString("effective_end_dttm_utc");
                    r.override_reason = rs.getString("override_reason");
                    r.effective_start_dttm_orig_utc = rs.getString("effective_start_dttm_orig_utc");
                    r.last_updated_dttm_utc = rs.getString("last_updated_dttm_utc");
                    r.last_updated_by = rs.getString("last_updated_by");
                    rows.put(r.registration_history_id, r);
                }
            }
        }
        catch (SQLException ex) {
            LOG.info("Error executing db " + ex.getMessage());
            throw (ex);
        }
        finally{
            if (st != null) {
                try {
                    st.close();
                } catch (SQLException e) {
                    LOG.info("Error closing connection " + e.getMessage());
                }
            }
        }
        return rows;
    }


    public int runUpdateQuery(String query) throws Throwable{
        assertTrue(Arrays.asList("devtest", "dev", "preprd").contains(Context.targetEnv), String.format("Updating records in '%s' env is not supported!", Context.targetEnv));

        int count;
        Statement st = null;
        try (Connection con = DriverManager.getConnection(this.url, this.user, this.password)){
            st = con.createStatement();
            LOG.info("POSTGRESQUERY=" + query);
            count = st.executeUpdate(query) ;
            LOG.info(String.format("postgres updated the following number of records: %d\n", count));
        }
        catch (SQLException ex) {
            LOG.info("Error executing db " + ex.getMessage());
            throw (ex);
        }
        finally{
            if (st != null) {
                try {
                    st.close();
                } catch (SQLException e) {
                    LOG.info("Error closing connection " + e.getMessage());
                }
            }
        }
        return count;
    }


    public List<RegistrationHistory> getRegistrationHistoryRows(String regId) throws Throwable {
        assertTrue(Arrays.asList("devtest", "dev", "preprd").contains(Context.targetEnv),
                String.format("Updating records in '%s' env is not supported!", Context.targetEnv));

        String query = String.format("select * from settlement_metadata.\"REGISTRATION_HISTORY\" where registration_id = '%s' order by id asc", regId);
        LOG.info("POSTGRESQUERY=" + query);

        List<RegistrationHistory> rows = new ArrayList<>();
        try (Connection con = DriverManager.getConnection(this.url, this.user, this.password);
             Statement st = con.createStatement();
             ResultSet rs = st.executeQuery(query)) {
            while (rs.next()) {
                rows.add(buildRegHistoryEntity(rs));
            }
        } catch (SQLException ex) {
            LOG.info("Error executing db " + ex.getMessage());
            throw ex;
        }
        return rows;
    }


    // Returns a map of active registration row lists by registration id. Each list is ordered by effective_start_dttm_utc.
    public HashMap<String, SortedMap<Long, RegistrationHistory>> getActiveRegHistoryRowsForProductId(String productId) throws Throwable {

        String query = String.format("select * from settlement_metadata.\"REGISTRATION_HISTORY\" where product_id = '%s' and status = 'ACTIVE' and deleted = false order by id asc", productId);
        LOG.info("POSTGRESQUERY=" + query);

        List<RegistrationHistory> rows = new ArrayList<>();
        try (Connection con = DriverManager.getConnection(this.url, this.user, this.password);
             Statement st = con.createStatement();
             ResultSet rs = st.executeQuery(query)) {
            while (rs.next()) {
                rows.add(buildRegHistoryEntity(rs));
            }
        } catch (SQLException ex) {
            LOG.info("Error executing db " + ex.getMessage());
            throw ex;
        }

        var histByRegs = new HashMap<String, SortedMap<Long, RegistrationHistory>>();
        rows.forEach(row -> histByRegs.computeIfAbsent(row.registration_id, k -> new TreeMap<>()).put(ZonedDateTime.parse(row.effective_start_dttm_utc).toEpochSecond(), row));

        // If no rows found, histByRegs wil be empty
        return histByRegs;
    }


    private RegistrationHistory buildRegHistoryEntity(ResultSet rs) throws SQLException {
        var r = new RegistrationHistory();
        r.id = rs.getLong("id");
        r.registration_id = rs.getString("registration_id");
        r.status = rs.getString("status");
        r.product_id = rs.getString("product_id");
        r.flexible_asset_id = rs.getString("flexible_asset_id");
        r.service_delivery_point_id = rs.getString("service_delivery_point_id");
        r.org_id = rs.getString("org_id");
        r.site_id = rs.getString("site_id");
        r.ecrm_account_id = rs.getString("ecrm_account_id");
        r.ecrm_site_id = rs.getString("ecrm_site_id");
        r.ecrm_opportunity_id = rs.getString("ecrm_opportunity_id");
        r.portfolio_id = rs.getString("portfolio_id");
        r.registration_set_id = rs.getString("registration_set_id");
        r.deleted = rs.getBoolean("deleted");
        r.needs_manual_fix = rs.getBoolean("needs_manual_fix");
        r.effective_start_dttm_utc = Utility.normalizeDateTime(rs.getString("effective_start_dttm_utc"));
        r.effective_end_dttm_utc = Utility.normalizeDateTime(rs.getString("effective_end_dttm_utc"));
        r.last_updated_dttm_utc = Utility.normalizeDateTime(rs.getString("last_updated_dttm_utc"));
        r.last_updated_by = rs.getString("last_updated_by");
        return r;
    }


    public ArrayList<FinancialPointRow> getAllFinancialPointRows(String query) throws Throwable{
        assertTrue(Arrays.asList("devtest", "dev", "preprd").contains(Context.targetEnv), String.format("'%s' env is not supported!", Context.targetEnv));

        var rows = new ArrayList<FinancialPointRow>();

        Statement st = null;
        try (Connection con = DriverManager.getConnection(this.url, this.user, this.password)){
            st = con.createStatement();
            LOG.info("POSTGRESQUERY=" + query);
            try (ResultSet rs = st.executeQuery(query)) {
                while (rs.next()) {
                    var r = new FinancialPointRow();
                    r.id = rs.getLong("id");
                    r.level_id = rs.getString("level_id");
                    r.level_type = rs.getString("level_type");
                    r.financial_point_id = rs.getString("financial_point_id");
                    r.channel_id = rs.getInt("channel_id");
                    r.financial_point_type = rs.getString("financial_point_type");
                    r.start_dttm_utc = rs.getString("start_dttm_utc").replace(" ", "T");
                    r.end_dttm_utc = rs.getString("end_dttm_utc").replace(" ", "T");
                    r.zone_id = rs.getString("zone_id");
                    r.deleted = rs.getBoolean("deleted");
                    r.last_updated_dttm_utc = rs.getString("last_updated_dttm_utc");
                    r.last_updated_by = rs.getString("last_updated_by");
                    rows.add(r);
                }
            }
        }
        catch (SQLException ex) {
            LOG.info("Error executing db " + ex.getMessage());
            throw (ex);
        }
        finally{
            if (st != null) {
                try {
                    st.close();
                } catch (SQLException e) {
                    LOG.info("Error closing connection " + e.getMessage());
                }
            }
        }
        return rows;
    }


     public List<Settlement> getSettlementRows(String productId, String settlementType, String startDttm, boolean deleted) throws Exception {

        String query = String.format("select * from settlements where product_id = '%s' AND settlement_type = '%s' AND start_dttm_utc = '%s' AND deleted = %s",
                productId, settlementType, startDttm, deleted);
        LOG.info("POSTGRESQUERY=" + query);

        List<Settlement> rows = new ArrayList<>();

        try (Connection con = DriverManager.getConnection(this.url, this.user, this.password);
             Statement st = con.createStatement();
             ResultSet rs = st.executeQuery(query)) {
            while (rs.next()) {
                var r = new Settlement();
                r.settlement_id = rs.getString("settlement_id");
                r.product_id = rs.getString("product_id");
                r.deleted = rs.getBoolean("deleted");
                r.start_dttm_utc = Utility.normalizeDateTime(rs.getString("start_dttm_utc"));
                r.end_dttm_utc = Utility.normalizeDateTime(rs.getString("end_dttm_utc"));
                r.business_process_status = rs.getString("business_process_status");
                r.event_id = rs.getString("event_id");
                r.description = rs.getString("description");
                r.processing_status = rs.getString("processing_status");
                r.settlement_status = rs.getString("settlement_status");
                r.settlement_type = rs.getString("settlement_type");
                r.settlement_subtype = rs.getString("settlement_subtype");
                r.source_system_type = rs.getString("source_system_type");
                r.last_updated_dttm_utc = Utility.normalizeDateTime(rs.getString("last_updated_dttm_utc"));
                r.last_updated_by = rs.getString("last_updated_by");
                r.inputs_available_until_dttm_utc = rs.getString("inputs_available_until_dttm_utc");
                rows.add(r);
            }
        } catch (SQLException ex) {
            LOG.info("Error executing db " + ex.getMessage());
            throw ex;
        }

        return rows;
    }


    public List<Settlement> getSettlementRowsCreatedAfter(String lastUpdatedDttm) throws Exception {
        assertTrue(Arrays.asList("devtest", "dev", "preprd").contains(Context.targetEnv),
                String.format("Updating records in '%s' env is not supported!", Context.targetEnv));

        String query = String.format("select * from settlements where last_updated_dttm_utc > TIMESTAMP WITH TIME ZONE '%s' AND deleted = false", lastUpdatedDttm);
        LOG.info("POSTGRESQUERY=" + query);

        List<Settlement> rows = new ArrayList<>();

        try (Connection con = DriverManager.getConnection(this.url, this.user, this.password);
             Statement st = con.createStatement();
             ResultSet rs = st.executeQuery(query)) {
            while (rs.next()) {
                var r = new Settlement();
                r.settlement_id = rs.getString("settlement_id");
                r.product_id = rs.getString("product_id");
                r.deleted = rs.getBoolean("deleted");
                r.start_dttm_utc = Utility.normalizeDateTime(rs.getString("start_dttm_utc"));
                r.end_dttm_utc = Utility.normalizeDateTime(rs.getString("end_dttm_utc"));
                r.business_process_status = rs.getString("business_process_status");
                r.event_id = rs.getString("event_id");
                r.description = rs.getString("description");
                r.processing_status = rs.getString("processing_status");
                r.settlement_status = rs.getString("settlement_status");
                r.settlement_type = rs.getString("settlement_type");
                r.settlement_subtype = rs.getString("settlement_subtype");
                r.source_system_type = rs.getString("source_system_type");
                r.last_updated_dttm_utc = Utility.normalizeDateTime(rs.getString("last_updated_dttm_utc"));
                r.last_updated_by = rs.getString("last_updated_by");
                r.inputs_available_until_dttm_utc = rs.getString("inputs_available_until_dttm_utc");
                rows.add(r);
            }
        } catch (SQLException ex) {
            LOG.info("Error executing db " + ex.getMessage());
            throw ex;
        }

        return rows;
    }


    public List<Settlement> getQAASettlementRows(String productId, String type) throws Exception {
        assertTrue(Arrays.asList("devtest", "dev", "preprd").contains(Context.targetEnv),
                String.format("Updating records in '%s' env is not supported!", Context.targetEnv));

        String query = String.format("select * from settlements where product_id = '%s' AND settlement_type = '%s' AND (settlement_subtype = 'QAA' OR left(description, 3) = 'QAA') AND deleted = false",
                productId, type);
        LOG.info("POSTGRESQUERY=" + query);

        List<Settlement> rows = new ArrayList<>();

        try (Connection con = DriverManager.getConnection(this.url, this.user, this.password);
             Statement st = con.createStatement();
             ResultSet rs = st.executeQuery(query)) {
            while (rs.next()) {
                var r = new Settlement();
                r.settlement_id = rs.getString("settlement_id");
                r.product_id = rs.getString("product_id");
                r.deleted = rs.getBoolean("deleted");
                r.start_dttm_utc = Utility.normalizeDateTime(rs.getString("start_dttm_utc"));
                r.end_dttm_utc = Utility.normalizeDateTime(rs.getString("end_dttm_utc"));
                r.business_process_status = rs.getString("business_process_status");
                r.event_id = rs.getString("event_id");
                r.description = rs.getString("description");
                r.processing_status = rs.getString("processing_status");
                r.settlement_status = rs.getString("settlement_status");
                r.settlement_type = rs.getString("settlement_type");
                r.settlement_subtype = rs.getString("settlement_subtype");
                r.source_system_type = rs.getString("source_system_type");
                r.last_updated_dttm_utc = Utility.normalizeDateTime(rs.getString("last_updated_dttm_utc"));
                r.last_updated_by = rs.getString("last_updated_by");
                r.inputs_available_until_dttm_utc = rs.getString("inputs_available_until_dttm_utc");
                rows.add(r);
            }
        } catch (SQLException ex) {
            LOG.info("Error executing db " + ex.getMessage());
            throw ex;
        }

        return rows;
    }


    // Returns a map of prices, ordered by interval_dttm_end.
    public SortedMap<Long, Double> getPrices(String pointId, String startLocal, String endLocal) throws Throwable {

        var startDttm = Utility.normalizeDateTime(startLocal);
        var endDttm = Utility.normalizeDateTime(endLocal);
        var builder = new StringBuilder();
        {
            builder.append(String.format("select interval_dttm_end, value from ids.readings where space_id = '%s'", pointId));
            builder.append(String.format(" and interval_dttm_end between TIMESTAMP WITH TIME ZONE '%s'  and TIMESTAMP WITH TIME ZONE '%s'", startDttm, endDttm));
            builder.append(" order by interval_dttm_end asc");
        }
        var query = builder.toString();
        LOG.info("POSTGRESQUERY=" + query);

        SortedMap<Long, Double> prices = new TreeMap<>();
        try (Connection con = DriverManager.getConnection(this.url, this.user, this.password);
             Statement st = con.createStatement();
             ResultSet rs = st.executeQuery(query)) {
            while (rs.next()) {
                var epoch = ZonedDateTime.parse(Utility.normalizeDateTime(rs.getString(1))).toEpochSecond();
                prices.put(epoch, rs.getDouble(2));
            }
        } catch (SQLException ex) {
            LOG.info("Error executing db " + ex.getMessage());
            throw ex;
        }

        // If no readings found, map wil be empty
        return prices;
    }


    public double getEcoCustomerSplit(String opportunityId) {

        var query = String.format("select of_icap_payment  from ecrm_opportunity where external_id = '%s'", opportunityId);
        LOG.info("POSTGRESQUERY=" + query);

        double split = 0.0;
        try (Connection con = DriverManager.getConnection(this.url, this.user, this.password);
             Statement st = con.createStatement();
             ResultSet rs = st.executeQuery(query)) {
            int count = 0;
            while (rs.next()) {
                if (count++ > 0) {
                    fail("More than one ecrm_opportunity row found!");
                }
                split = rs.getDouble(1);
            }
        } catch (Exception ex) {
            LOG.info("Error executing query: " + ex.getMessage());
            fail(ex.toString());
        }

        return split / 100.0;
    }


    public void getEcoPayment(ECOcontainer.ECOobject eco, LocalDate month) throws Throwable {

        var query = String.format("select type, amount, updated, settlement_item_id, prebilled from transaction_source where settlement_item_id = '%s' and apply_month = '%s'", eco.settlementItemId, month.format(DateTimeFormatter.ISO_LOCAL_DATE));
        LOG.info("POSTGRESQUERY=" + query);

        try (Connection con = DriverManager.getConnection(this.url, this.user, this.password);
             Statement st = con.createStatement();
             ResultSet rs = st.executeQuery(query)) {
            while (rs.next()) {
                var transaction = new EcoTransactionRow();
                transaction.amount = rs.getDouble(2);
                transaction.updated = rs.getString(3);
                transaction.settlementItemId = rs.getString(4);
                boolean prebilled = rs.getBoolean(5);
                switch (rs.getString(1)) {
                    case "REV" -> {
                        assertFalse(eco.REVOpt.isPresent(), "More than one REV row returned!");
                        // ITAPPSIT-3910: ECO ancillary calcs incorrectly setting AESO OR revenue TS.prebilled=false
                        // According to Nate, all ancillary programs should have REV prebilled=true
                        assertTrue(prebilled, "REV row has prebilled = false, should be true!");
                        eco.REVOpt = Optional.of(transaction);
                    }
                    case "COGS" -> {
                        assertFalse(eco.COGSOpt.isPresent(), "More than one COGS row returned!");
                        switch (context.program) {
                            case AESO -> assertFalse(prebilled, "COGS row has prebilled = true, should be false for AESO!");
                            case FCAS -> assertTrue(prebilled, "COGS row has prebilled = false, should be true for FCAS!");
                            default -> fail("Need to add case statement for new program!");
                        }
                        eco.COGSOpt = Optional.of(transaction);
                    }
                    default -> fail(String.format("Unknown transaction type: '%s'", rs.getString(1)));
                }
            }
        } catch (Exception ex) {
            LOG.info("Error executing query: " + ex.getMessage());
            throw ex;
        }

        // If ECO cannot calculate transactions for a settlement id, and there are no existing transaction source lines, ECO won't create REV/COGS
        // If transaction source lines exists, ECO should create REV/COGS with zero values.
        // Note: a registration which IS valid for ECO calcs but has no cleared offers for the month has nothing to bill,
        // so ECO may also legitimately write no transaction source rows for it. This mirrors the expected-value logic
        // in FullPipeline.calcAESOMonthlyECOPayments(), which expects REV/COGS of 0.0 for such items.
        boolean ecoMaySkipWritingRows = !eco.isValidForEcoCalc() || eco.clearedOffers.isEmpty();
        if (eco.REVOpt.isEmpty() && ecoMaySkipWritingRows) {
            var transaction = new EcoTransactionRow();
            transaction.amount = 0.0;
            transaction.updated = Utility.epochToString(Context.testStartEpoch + 1);
            transaction.settlementItemId = eco.settlementItemId;
            eco.REVOpt = Optional.of(transaction);
            LOG.info(String.format("No REV found for %s but we assume ECO could not calculate REV (%s). Defaulting actual REV to 0.0",
                    eco.settlementItemId,
                    eco.isValidForEcoCalc() ? "no cleared offers" : "not valid for ECO calc"));
        }
        if (eco.COGSOpt.isEmpty() && ecoMaySkipWritingRows) {
            var transaction = new EcoTransactionRow();
            transaction.amount = 0.0;
            transaction.updated = Utility.epochToString(Context.testStartEpoch+ 1);
            transaction.settlementItemId = eco.settlementItemId;
            eco.COGSOpt = Optional.of(transaction);
            LOG.info(String.format("No COGS found for %s but we assume ECO could not calculate COGS (%s). Defaulting actual COGS to 0.0",
                    eco.settlementItemId,
                    eco.isValidForEcoCalc() ? "no cleared offers" : "not valid for ECO calc"));
        }

        var errors = new ArrayList<String>();
        {
            if (eco.REVOpt.isEmpty()) errors.add(String.format("Item %s: No REV row returned for valid ECO transaction!", eco.settlementItemId));
            if (eco.COGSOpt.isEmpty()) errors.add(String.format("Item %s: No COGS row returned for valid ECO transaction!", eco.settlementItemId));
        }
        assertTrue(errors.isEmpty(), String.join("\n", errors));
    }


    public void verifyNoEcoRowsForItem(ECOcontainer.ECOobject eco) throws Throwable {
        var query = String.format("select type, amount, updated, settlement_item_id from transaction_source where settlement_item_id = '%s'", eco.settlementItemId);
        LOG.info("POSTGRESQUERY=" + query);

        int numRows = 0;
        try (Connection con = DriverManager.getConnection(this.url, this.user, this.password);
             Statement st = con.createStatement();
             ResultSet rs = st.executeQuery(query)) {
            while (rs.next()) {
                numRows++;
            }
        } catch (Exception ex) {
            LOG.info("Error executing query: " + ex.getMessage());
            throw ex;
        }
        assertEquals(0, numRows, String.format("%d ECO rows present for item %s, none expected!", numRows, eco.settlementItemId));
    }



    public List<String> getLatestSuccessfulPipelineHistorySettlementIds(long epoch) throws Throwable {

        // This method will return an empty list if the job hasn't completed

        var createdDttm = Utility.epochToString(epoch);
        var builder = new StringBuilder();
        {
            builder.append("select settlement_id, pipeline_run_id, created_dttm_utc from settlement_metadata.\"pipeline_state_history\"");
            builder.append(String.format(" where created_dttm_utc > '%s' and pipeline_step='ECO' and status='STARTED'", createdDttm));
        }
        var query = builder.toString();
        LOG.info("POSTGRESQUERY=" + query);

        var settlementIds = new ArrayList<String>();
        var pipelineRunIds =  new ArrayList<String>();
        try (Connection con = DriverManager.getConnection(this.url, this.user, this.password);
             Statement st = con.createStatement();
             ResultSet rs = st.executeQuery(query)) {
            while (rs.next()) {
                var sid = rs.getString("settlement_id");
                if (!settlementIds.contains(sid)) {
                    settlementIds.add(sid);
                }
                var rid = rs.getString("pipeline_run_id");
                if (!pipelineRunIds.contains(rid)) {
                    pipelineRunIds.add(rid);
                }
            }
        } catch (SQLException ex) {
            LOG.info("Error executing db " + ex.getMessage());
            throw ex;
        }
        LOG.info(String.format("Pipeline run id(s): %s   Settlement id(s): %s", String.join(",", pipelineRunIds), settlementIds.isEmpty() ? "none" : String.join(",", settlementIds)));
        // It's okay if more then one DONE - SUCCESS row is returned for the same pipeline id and settlement.
        // But if someone else happened to trigger another run at the same time, we can't easily tell which pipeline id is ours.
        if (pipelineRunIds.stream().distinct().count() > 1) {
            fail("Recent pipeline history rows returned far more than one pipeline run!");
        }
        return settlementIds;
    }


    public Optional<String> getLatestPipelineHistoryForSettlementId(String settlementId, String step, String status, long epoch) throws Throwable {

        var createdDttm = Utility.epochToString(epoch);
        var builder = new StringBuilder();
        {
            builder.append("select pipeline_run_id, created_dttm_utc from settlement_metadata.\"pipeline_state_history\"");
            builder.append(String.format(" where settlement_id = '%s' and created_dttm_utc > '%s' and pipeline_step='%s' and status='%s'",
                    settlementId, createdDttm, step, status));
        }
        var query = builder.toString();
        LOG.info("POSTGRESQUERY=" + query);

        Optional<String> pipelineRunIdOpt = Optional.empty();
        try (Connection con = DriverManager.getConnection(this.url, this.user, this.password);
             Statement st = con.createStatement();
             ResultSet rs = st.executeQuery(query)) {
            if (rs.next()) {
                pipelineRunIdOpt = Optional.of(rs.getString("pipeline_run_id"));
            }
        } catch (SQLException ex) {
            LOG.info("Error executing db " + ex.getMessage());
            throw ex;
        }
        return pipelineRunIdOpt;
    }


    public List<String> getLatestSkippedPipelineHistorySettlementIds(long epoch, String detail) throws Throwable {

        // This method will return an empty list if the job hasn't completed

        var createdDttm = Utility.epochToString(epoch);
        var builder = new StringBuilder();
        {
            builder.append("select settlement_id, pipeline_run_id, created_dttm_utc from settlement_metadata.\"pipeline_state_history\"");
            builder.append(String.format(" where created_dttm_utc > '%s' and pipeline_step='CREATOR_REST' and status='SUCCESS' and detail='%s'", createdDttm, detail));
        }
        var query = builder.toString();
        LOG.info("POSTGRESQUERY=" + query);

        var settlementIds = new ArrayList<String>();
        var pipelineRunIds =  new ArrayList<String>();
        try (Connection con = DriverManager.getConnection(this.url, this.user, this.password);
             Statement st = con.createStatement();
             ResultSet rs = st.executeQuery(query)) {
            while (rs.next()) {
                var sid = rs.getString("settlement_id");
                if (!settlementIds.contains(sid)) {
                    settlementIds.add(sid);
                }
                var rid = rs.getString("pipeline_run_id");
                if (!pipelineRunIds.contains(rid)) {
                    pipelineRunIds.add(rid);
                }
            }
        } catch (SQLException ex) {
            LOG.info("Error executing db " + ex.getMessage());
            throw ex;
        }
        LOG.info(String.format("Pipeline run id(s): %s   Settlement id(s): %s", String.join(",", pipelineRunIds), settlementIds.isEmpty() ? "none" : String.join(",", settlementIds)));
        // It's okay if duplicate rows are returned for the same pipeline id.
        // But if someone else happened to trigger another run at the same time, we can't easily tell which pipeline id is ours.
        if (pipelineRunIds.stream().distinct().count() > 1) {
            fail("Recent pipeline history rows returned for more than one pipeline run!");
        }
        return settlementIds;
    }

    public List<HashMap<String, Object>> getSettlementItemsForSettlementRows(String settlementId) throws Exception {

        String query = String.format("select * from settlement_items where settlement_id = '%s'",
                settlementId);
        LOG.info("POSTGRESQUERY=" + query);

        var items = new ArrayList<HashMap<String, Object>>();
        try (Connection con = DriverManager.getConnection(this.url, this.user, this.password);
             Statement st = con.createStatement();
             ResultSet rs = st.executeQuery(query)) {
            while (rs.next()) {
                var map = new HashMap<String, Object>();
                map.put("settlement_item_id", rs.getString("settlement_item_id"));
                map.put("settlement_level", rs.getString("settlement_level"));
                map.put("settlement_level_id", rs.getString("settlement_level_id"));
                map.put("settlement_item_status", rs.getString("settlement_item_status"));
                map.put("deleted", rs.getBoolean("deleted"));
                map.put("atlas_settlement_level_id", rs.getString("atlas_settlement_level_id"));
                map.put("master_settlement_item_id", rs.getString("master_settlement_item_id"));
                map.put("registration_set_id", rs.getString("registration_set_id"));
                map.put("opportunity", rs.getString("ecrm_opportunity_id"));
                map.put("start_dttm_utc", rs.getString("start_dttm_utc"));
                map.put("end_dttm_utc", rs.getString("end_dttm_utc"));
                map.put("processing_status", rs.getString("processing_status"));
                Object isInactiveObj = rs.getObject("is_inactive");
                map.put("is_inactive", isInactiveObj);
                items.add(map);
            }
        } catch (SQLException ex) {
            LOG.info("Error executing db " + ex.getMessage());
            throw ex;
        }

        return items;
    }


    public void countUpdatedSettlementItemIntervals(ECOcontainer.ECOobject eco, long epoch) throws Exception {

        var updatedDttm = Utility.epochToString(epoch);
        String query = String.format("select interval_source, count(*), sum(revenue_value) as rev, sum(payment_value) as cogs from settlement_item_intervals where settlement_item_id = '%s' and last_updated_dttm_utc > '%s' group by interval_source",
                eco.settlementItemId, updatedDttm);
        LOG.info("POSTGRESQUERY=" + query);

        var summaries = new HashMap<String, ECOcontainer.intervalSummary>();
        try (Connection con = DriverManager.getConnection(this.url, this.user, this.password);
             Statement st = con.createStatement();
             ResultSet rs = st.executeQuery(query)) {
            while (rs.next()) {
                var summary = new ECOcontainer.intervalSummary();
                summary.count = rs.getLong("count");
                summary.REV = rs.getDouble("rev");
                summary.COGS = rs.getDouble("cogs");
                summaries.put(rs.getString("interval_source"), summary);
            }
        } catch (SQLException ex) {
            LOG.info("Error executing db " + ex.getMessage());
            throw ex;
        }

        eco.intervalSummaries.clear();
        eco.intervalSummaries.putAll(summaries);
    }


    public HashMap<Long, SettlementItemInterval> getUpdatedFCASIntervals(
            String itemId,
            long epoch
    ) throws Exception {

        String updatedDttm = Utility.epochToString(epoch);

        String query = String.format("""
            SELECT
                interval_dttm_utc,
                interval_source,
                is_armed,
                realtime_availability_kw,
                realtime_availability_kw_override,
                cleared_offer_kw,
                payment_value_override,
                payment_value,
                revenue_value,
                last_updated_dttm_utc
            FROM settlement_item_intervals
            WHERE settlement_item_id = '%s'
              AND last_updated_dttm_utc > '%s'
            ORDER BY interval_dttm_utc
            """,
                itemId,
                updatedDttm
        );

        LOG.info("POSTGRESQUERY={}", query);

        var intervals = new HashMap<Long, SettlementItemInterval>();

        try (
                Connection con = DriverManager.getConnection(this.url, this.user, this.password);
                Statement st = con.createStatement();
                ResultSet rs = st.executeQuery(query)
        ) {
            while (rs.next()) {
                var interval = new SettlementItemInterval();

                interval.settlement_item_id = itemId;

                String intervalDttm = rs.getString("interval_dttm_utc");
                interval.interval_dttm_utc = intervalDttm == null
                        ? null
                        : intervalDttm.replace(" ", "T");

                interval.interval_source = rs.getString("interval_source");

                interval.is_armed = getNullableBoolean(rs, "is_armed");

                interval.realtime_availability_kw = getNullableDouble(
                        rs,
                        "realtime_availability_kw"
                );

                // ITAPPSIT-3859: required for FCAS FINAL override precedence.
                interval.realtime_availability_kw_override = getNullableDouble(
                        rs,
                        "realtime_availability_kw_override"
                );

                interval.cleared_offer_kw = getNullableDouble(
                        rs,
                        "cleared_offer_kw"
                );

                // Model declares these as String (DECIMAL in db) - read directly, no numeric coercion.
                interval.payment_value_override = rs.getString("payment_value_override");
                interval.payment_value = rs.getString("payment_value");
                interval.revenue_value = rs.getString("revenue_value");

                String lastUpdated = rs.getString("last_updated_dttm_utc");
                interval.last_updated_dttm_utc = lastUpdated == null
                        ? null
                        : lastUpdated.replace(" ", "T");

                if (interval.interval_dttm_utc == null
                        || interval.interval_source == null
                        || interval.is_armed == null) {

                    fail(String.format(
                            "Null required interval field! interval_dttm_utc=%s " +
                                    "interval_source=%s is_armed=%s " +
                                    "realtime_availability_kw=%s " +
                                    "realtime_availability_kw_override=%s",
                            interval.interval_dttm_utc,
                            interval.interval_source,
                            interval.is_armed,
                            interval.realtime_availability_kw,
                            interval.realtime_availability_kw_override
                    ));
                }

                intervals.put(
                        ZonedDateTime.parse(interval.interval_dttm_utc).toEpochSecond(),
                        interval
                );
            }
        } catch (SQLException ex) {
            LOG.error("Error executing DB query: {}", query, ex);
            throw ex;
        }

        return intervals;
    }

    public List<SettlementItemInterval> getIntervalsForSettlementItem(
            String settlementItemId
    ) throws Exception {

        String query = String.format("""
            SELECT
                interval_dttm_utc,
                interval_source,
                is_armed,
                realtime_availability_kw,
                realtime_availability_kw_override,
                cleared_offer_kw,
                payment_value_override,
                payment_value,
                revenue_value,
                last_updated_dttm_utc
            FROM settlement_item_intervals
            WHERE settlement_item_id = '%s'
            ORDER BY interval_dttm_utc
            """,
                settlementItemId
        );

        LOG.info("POSTGRESQUERY={}", query);

        var intervals = new ArrayList<SettlementItemInterval>();

        try (
                Connection con = DriverManager.getConnection(this.url, this.user, this.password);
                Statement st = con.createStatement();
                ResultSet rs = st.executeQuery(query)
        ) {
            while (rs.next()) {
                var interval = new SettlementItemInterval();

                interval.settlement_item_id = settlementItemId;

                String intervalDttm = rs.getString("interval_dttm_utc");
                interval.interval_dttm_utc = intervalDttm == null
                        ? null
                        : intervalDttm.replace(" ", "T");

                interval.interval_source = rs.getString("interval_source");

                interval.is_armed = getNullableBoolean(rs, "is_armed");

                interval.realtime_availability_kw = getNullableDouble(
                        rs,
                        "realtime_availability_kw"
                );

                interval.realtime_availability_kw_override = getNullableDouble(
                        rs,
                        "realtime_availability_kw_override"
                );

                interval.cleared_offer_kw = getNullableDouble(
                        rs,
                        "cleared_offer_kw"
                );

                interval.payment_value_override = rs.getString("payment_value_override");
                interval.payment_value = rs.getString("payment_value");
                interval.revenue_value = rs.getString("revenue_value");

                String lastUpdated = rs.getString("last_updated_dttm_utc");
                interval.last_updated_dttm_utc = lastUpdated == null
                        ? null
                        : lastUpdated.replace(" ", "T");

                intervals.add(interval);
            }
        } catch (SQLException ex) {
            LOG.error("Error executing DB query: {}", query, ex);
            throw ex;
        }

        return intervals;
    }



    private Double getNullableDouble(ResultSet rs, String columnName) throws SQLException {
        double value = rs.getDouble(columnName);
        return rs.wasNull() ? null : value;
    }

    private Boolean getNullableBoolean(ResultSet rs, String columnName) throws SQLException {
        boolean value = rs.getBoolean(columnName);
        return rs.wasNull() ? null : value;
    }

        /**
         * Set payment_value_override for the first N intervals of the month for a given item.
         */
        public void setFcasPaymentOverridesForTest(String settlementItemId,
                                                   String monthStartUtc,   // normalized 'YYYY-MM-DDTHH:MM:SSZ'
                                                   int granSeconds,
                                                   int numIntervals,
                                                   double overrideValue) throws Throwable {

            assertTrue(Arrays.asList("devtest", "dev", "preprd").contains(Context.targetEnv),
                    String.format("Updating records in '%s' env is not supported!", Context.targetEnv));

            String overrideStr = String.format("%.6f", overrideValue);
            // update intervals from monthStartUtc up to monthStartUtc + numIntervals * granSeconds
            String query = String.format(
                    "update %s.settlement_item_intervals " +
                            "   set payment_value_override = %s " +
                            " where settlement_item_id = '%s' " +
                            "   and interval_dttm_utc >= TIMESTAMP WITH TIME ZONE '%s' ::timestamptz " +
                            "   and interval_dttm_utc <  TIMESTAMP WITH TIME ZONE '%s' ::timestamptz + interval '%d seconds'",
                    schema,
                    overrideStr,
                    settlementItemId,
                    monthStartUtc,
                    monthStartUtc,
                    numIntervals * granSeconds);

            runUpdateQuery(query);
        }

        /**
         * Set realtime_availability_kw_override for the first N intervals of the month for a given item.
         */
        public void setFcasRealtimeAvailabilityOverridesForTest(String settlementItemId,
                                                                String monthStartUtc,
                                                                int granSeconds,
                                                                int numIntervals,
                                                                double overrideValueKw) throws Throwable {

            assertTrue(Arrays.asList("devtest", "dev", "preprd").contains(Context.targetEnv),
                    String.format("Updating records in '%s' env is not supported!", Context.targetEnv));

            String query = String.format(
                    "update %s.settlement_item_intervals " +
                            "   set realtime_availability_kw_override = %f " +
                            " where settlement_item_id = '%s' " +
                            "   and interval_dttm_utc >= TIMESTAMP WITH TIME ZONE '%s' " +
                            "   and interval_dttm_utc <  TIMESTAMP WITH TIME ZONE '%s' + interval '%d seconds'",
                    schema,
                    overrideValueKw,
                    settlementItemId,
                    monthStartUtc,
                    monthStartUtc,
                    numIntervals * granSeconds);

            runUpdateQuery(query);
        }



        /**
         * Set payment_value_override for the first N intervals of the month for a given AESO item.
         * Reuses the same pattern as setFcasPaymentOverridesForTest.
         */
        public void setAesoPaymentOverridesForTest(String settlementItemId,
                                                   String monthStartUtc,   // normalized 'YYYY-MM-DDTHH:MM:SSZ'
                                                   int granSeconds,
                                                   int numIntervals,
                                                   double overrideValue) throws Throwable {

            assertTrue(Arrays.asList("devtest", "dev", "preprd").contains(Context.targetEnv),
                    String.format("Updating records in '%s' env is not supported!", Context.targetEnv));

            String overrideStr = String.format("%.6f", overrideValue);
            // update intervals from monthStartUtc up to monthStartUtc + numIntervals * granSeconds
            String query = String.format(
                    "update %s.settlement_item_intervals " +
                            "   set payment_value_override = %s " +
                            " where settlement_item_id = '%s' " +
                            "   and interval_dttm_utc >= TIMESTAMP WITH TIME ZONE '%s' " +
                            "   and interval_dttm_utc <  TIMESTAMP WITH TIME ZONE '%s' + interval '%d seconds'",
                    schema,
                    overrideStr,
                    settlementItemId,
                    monthStartUtc,
                    monthStartUtc,
                    numIntervals * granSeconds);

            runUpdateQuery(query);
        }

        public void getFinalFcasEcoPayment(ECOcontainer.ECOobject eco, LocalDate month) throws Throwable {
            var query = String.format(
                    "select type, amount, updated, settlement_item_id, prebilled " +
                            "from transaction_source " +
                            "where settlement_item_id = '%s' and apply_month = '%s'",
                    eco.settlementItemId,
                    month.format(DateTimeFormatter.ISO_LOCAL_DATE)
            );
            LOG.info("POSTGRESQUERY=" + query);

            eco.REVOpt = Optional.empty();
            eco.COGSOpt = Optional.empty();

            try (Connection con = DriverManager.getConnection(this.url, this.user, this.password);
                 Statement st = con.createStatement();
                 ResultSet rs = st.executeQuery(query)) {

                while (rs.next()) {
                    var transaction = new EcoTransactionRow();
                    transaction.amount = rs.getDouble(2);
                    transaction.updated = rs.getString(3);
                    transaction.settlementItemId = rs.getString(4);
                    boolean prebilled = rs.getBoolean(5);
                    String type = rs.getString(1);

                    switch (type) {
                        case "REV" -> {
                            assertFalse(eco.REVOpt.isPresent(), "More than one REV row returned!");
                            // REV should always be prebilled=true
                            assertTrue(prebilled, "Final FCAS REV row has prebilled=false, should be true!");
                            eco.REVOpt = Optional.of(transaction);
                        }
                        case "COGS" -> {
                            assertFalse(eco.COGSOpt.isPresent(), "More than one COGS row returned!");
                            // For final FCAS, COGS must be prebilled=false
                            assertFalse(prebilled, "Final FCAS COGS row has prebilled=true, should be false!");
                            eco.COGSOpt = Optional.of(transaction);
                        }
                        default -> fail(String.format("Unknown transaction type: '%s'", type));
                    }
                }
            } catch (Exception ex) {
                LOG.info("Error executing query: " + ex.getMessage());
                throw ex;
            }

            var errors = new ArrayList<String>();
            if (eco.REVOpt.isEmpty()) {
                errors.add(String.format("Item %s: No REV row returned for final FCAS transaction!", eco.settlementItemId));
            }
            if (eco.COGSOpt.isEmpty()) {
                errors.add(String.format("Item %s: No COGS row returned for final FCAS transaction!", eco.settlementItemId));
            }
            assertTrue(errors.isEmpty(), String.join("\n", errors));
        }

        /**
         * Variant of getLatestSuccessfulPipelineHistorySettlementIds for quarterly settlements,
         * where each constituent monthly settlement may have its own pipeline_run_id.
         * Instead of asserting a single run id, we assert that all expected settlement ids
         * (from context.savedSettlements) were processed.
         *
         * Returns the list of matching settlement ids once all are found, or whatever
         * has been found so far (may be empty if none have completed yet).
         */
        public List<String> getLatestSuccessfulPipelineHistorySettlementIdsForQuarterly(
                long epoch, List<String> expectedSettlementIds) throws Throwable {

            var createdDttm = Utility.epochToString(epoch);

            // Build the IN clause from the expected settlement ids
            var inClause = expectedSettlementIds.stream()
                    .map(id -> "'" + id + "'")
                    .collect(java.util.stream.Collectors.joining(","));

            var builder = new StringBuilder();
            builder.append("select settlement_id, pipeline_run_id, created_dttm_utc ")
                    .append("from settlement_metadata.\"pipeline_state_history\" ")
                    .append(String.format(
                            "where created_dttm_utc > '%s' and pipeline_step='ECO' and status='STARTED' ",
                            createdDttm))
                    .append(String.format("and settlement_id in (%s)", inClause));

            var query = builder.toString();
            LOG.info("POSTGRESQUERY=" + query);

            var settlementIds = new ArrayList<String>();
            var pipelineRunIds = new ArrayList<String>();

            try {
                Connection con = DriverManager.getConnection(this.url, this.user, this.password);
                Statement st = con.createStatement();
                ResultSet rs = st.executeQuery(query);

                while (rs.next()) {
                    var sid = rs.getString("settlement_id");
                    if (!settlementIds.contains(sid)) settlementIds.add(sid);

                    var rid = rs.getString("pipeline_run_id");
                    if (!pipelineRunIds.contains(rid)) pipelineRunIds.add(rid);
                }
            } catch (SQLException ex) {
                LOG.info("Error executing db: " + ex.getMessage());
                throw ex;
            }

            LOG.info(String.format("Pipeline run id(s): %s   Settlement id(s): %s",
                    String.join(",", pipelineRunIds),
                    settlementIds.isEmpty() ? "none" : String.join(",", settlementIds)));

            // For quarterly settlements it is expected that each monthly settlement
            // has its own pipeline_run_id, so we do NOT assert a single run id here.
            // We only assert that the ids we found are a subset of the expected ones.
            var unexpected = settlementIds.stream()
                    .filter(id -> !expectedSettlementIds.contains(id))
                    .collect(java.util.stream.Collectors.toList());
            if (!unexpected.isEmpty()) {
                fail("Unexpected settlement ids found in pipeline history: " + String.join(",", unexpected));
            }

            return settlementIds;
        }


        public List<Settlement> getSettlementRowsForProductInRange(String productId, String startDttm, String endDttm) throws Exception {
            String query = String.format(
                    "select * from settlements where product_id = '%s' AND start_dttm_utc >= '%s' AND start_dttm_utc < '%s' AND deleted = false",
                    productId, startDttm, endDttm);
            LOG.info("POSTGRESQUERY=" + query);

            List<Settlement> rows = new ArrayList<>();
            try (Connection con = DriverManager.getConnection(this.url, this.user, this.password);
                 Statement st = con.createStatement();
                 ResultSet rs = st.executeQuery(query)) {
                while (rs.next()) {
                    var r = new Settlement();
                    r.settlement_id = rs.getString("settlement_id");
                    r.product_id = rs.getString("product_id");
                    r.deleted = rs.getBoolean("deleted");
                    r.start_dttm_utc = Utility.normalizeDateTime(rs.getString("start_dttm_utc"));
                    r.end_dttm_utc = Utility.normalizeDateTime(rs.getString("end_dttm_utc"));
                    r.business_process_status = rs.getString("business_process_status");
                    r.event_id = rs.getString("event_id");
                    r.description = rs.getString("description");
                    r.processing_status = rs.getString("processing_status");
                    r.settlement_status = rs.getString("settlement_status");
                    r.settlement_type = rs.getString("settlement_type");
                    r.settlement_subtype = rs.getString("settlement_subtype");
                    r.source_system_type = rs.getString("source_system_type");
                    r.last_updated_dttm_utc = Utility.normalizeDateTime(rs.getString("last_updated_dttm_utc"));
                    r.last_updated_by = rs.getString("last_updated_by");
                    r.inputs_available_until_dttm_utc = rs.getString("inputs_available_until_dttm_utc");
                    rows.add(r);
                }
            } catch (SQLException ex) {
                LOG.info("Error executing db " + ex.getMessage());
                throw ex;
            }
            return rows;
        }

        public List<HashMap<String, Object>> getReconciledRegistrationHistoryRows(String productId, String rangeStartUtc, String rangeEndUtc) throws Exception {
            String query = String.format(
                    "select * from settlement_metadata.\"REGISTRATION_HISTORY_RECONCILED\" " +
                            "where product_id = '%s' " +
                            "and (effective_start_dttm_utc, effective_end_dttm_utc) OVERLAPS (TIMESTAMP WITH TIME ZONE '%s', TIMESTAMP WITH TIME ZONE '%s') " +
                            "and deleted = false and status = 'ACTIVE' " +
                            "order by effective_start_dttm_utc asc",
                    productId, rangeStartUtc, rangeEndUtc);
            LOG.info("POSTGRESQUERY=" + query);

            var rows = new ArrayList<HashMap<String, Object>>();
            try (Connection con = DriverManager.getConnection(this.url, this.user, this.password);
                 Statement st = con.createStatement();
                 ResultSet rs = st.executeQuery(query)) {

                ResultSetMetaData meta = rs.getMetaData();
                int colCount = meta.getColumnCount();
                while (rs.next()) {
                    var row = new HashMap<String, Object>();
                    for (int i = 1; i <= colCount; i++) {
                        String colName = meta.getColumnLabel(i);
                        if ("effective_start_dttm_utc".equals(colName) || "effective_end_dttm_utc".equals(colName)
                                || "last_updated_dttm_utc".equals(colName)) {
                            Timestamp ts = rs.getTimestamp(i);
                            row.put(colName, ts == null ? null : ts.toInstant().atOffset(ZoneOffset.UTC).toString());
                        } else {
                            Object val = rs.getObject(i);
                            row.put(colName, val == null ? null : val.toString());
                        }
                    }
                    rows.add(row);
                }
            } catch (SQLException ex) {
                LOG.info("Error executing db " + ex.getMessage());
                throw ex;
            }
            return rows;
        }

    }
