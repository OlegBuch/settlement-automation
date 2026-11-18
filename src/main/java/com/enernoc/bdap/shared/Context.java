package com.enernoc.bdap.shared;

import com.enernoc.bdap.model.*;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.restassured.path.json.JsonPath;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import software.amazon.awssdk.regions.Region;

import java.io.File;
import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.function.Supplier;

import static org.junit.jupiter.api.Assertions.*;

public class Context {

    private static final Logger LOG = LoggerFactory.getLogger("Context");
    private static final ObjectMapper JSON = new ObjectMapper();

    private static Optional<Context> contextOpt = Optional.empty();

    private static final Supplier<AssertionError> NO_CONTEXT = () -> new AssertionError("You forgot the background stepdef 'I start with an empty context'");

    public static String enocSession = "";

    public final static String targetEnv;
    public static long crudEpoch = 0L;
    public static long testStartEpoch = 0L;
    public static final String EFFECTIVE_END_INFINITY = "9999-12-31T00:00:00.000Z";
    public static final ZonedDateTime EFFECTIVE_END_DTTM = ZonedDateTime.parse(EFFECTIVE_END_INFINITY);
    public static final DateTimeFormatter fullDttmFormat = DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss.SSSX");

    public final static String targetLoginUrl;
    public final static String targetRefUrl;
    public final static Map<String, List<String>> refEnums;
    public final static String productId1, productId2, productId3;
    public final static Map<String, HashMap<String, String>> organizationIds;
    public final static RegistrationConfig registrationConfigs = new RegistrationConfig();
    public final static Map<String, HashMap<String, String>> itsMappings;
    public final static Map<String, HashMap<String, String>> productRules;

    // Settlement API urls and API key
    public final static String targetBaseUrl;
    public final static String getSettlementsUrl;
    public final static String getSettlementDetailsUrl;
    public final static String getSettlementItemsUrl;
    public final static String getSettlementItemIntervalsSummaryUrl;
    public final static String settlementUrl ;
    public final static String settlementItemUrl;
    public final static String settlementItemIntervalsUrl;
    public final static String settlementAuditLogUrl;
    public final static String settlementItemAuditLogUrl;
    public final static String settlementItemIntervalsAuditLogUrl;
    public static String settlementApiKey;
    public static String refDataApiKey;
    public static String settlementCreatorApiKey;
    public static String finEngineApiKey;

    // Settlement Metadata API urls and API key
    public final static String targetMetadataUrl;
    public final static String getProductRulesUrl;
    public final static String registrationUrl;
    public final static String registrationHistoryUrl;
    public final static String registrationFieldHistoryUrl;
    public final static String getFinancialPointMappingUrl;
    public final static String pipelineStateUrl;
    public final static String productRuleParametersUrl;
    public final static String productRuleFragmentsUrl;
    public final static String productRulesUrl;
    public final static String productRuleDetailsUrl;
    public final static String registrationHistoryOverridesUrl;
    public final static String productRuleGroupsUrl;
    public static String metadataApiKey;
    public final static String ecoUrl;
    public final static String ecoExternalUrl;
    public final static String ecoExternalUrlFinancialSearch;
    public final static String adHocFinancialLevels;
    public final static String finEngineUrl;
    public final static String finEnginePingUrl;
    public final static String adHocFinancialSearchUrl;
    public final static String adHocFinancialUrl;
    public String lastCreatedAdhocFinancialId = null;

    //Settlement Creator API
    public static final String targetSettlementCreatorUrl;
    public final static String settlementCreatorPingUrl;
    public final static String settlementCreatorRunPipeline;

    // Service urls and lamba ARNs
    public final static String itsUrl;
    public final static String momUrl;
    public final static String createSettlementSQSOutputUrl;
    public final static String createIntervalsSQSInputUrl;
    public final static String createIntervalsSQSOutputUrl;
    public final static String orchestratorSQSInputQueueUrl;
    public final static String creatorSQSInputQueueUrl;
    public final static String ecoSQSInputQueueUrl;
    public final static String ecoSQSOutputQueueUrl;
    public final static String createItemsSQSInputUrl;
    public final static String createSettlementSQSOutputDLQUrl;
    public final static String createItemsSQSInputDLQUrl;
    public final static String createIntervalsSQSOutputDLQUrl;
    public final static String createIntervalsSQSInputDLQUrl;
    public final static String ecoInternalSQSInputDLQUrl;
    public final static String createSettlementArn;

    // AWS credentials for this session
    public static final Region region = Region.US_WEST_2;
    public static final String CREDENTIAL_KEY_FILE ;
    public static final String CREDENTIAL_KEYSET;

    // Runtime variables
    public boolean logAllAPIRequests = false;
    public boolean logAllAPIResponses = false;
    public boolean includeEnocSession = true;
    public boolean includeApiKey = true;
    public boolean includeInvalidEnocSession = false;
    public boolean includeInvalidApiKey = false;
    public Optional<Boolean> includeDeletedOpt = Optional.empty();
    public Optional<Boolean> includeDetailsOpt = Optional.empty();
    public Optional<Boolean> doRegistrationBackfillOpt = Optional.empty();
    public RequestContainer lastRequest;
    public String lastEventId = "";
    public String savedEventId = "";
    public String lastSettlementId = "";
    public Settlement existingSettlement;
    public String lastSettlementItemId = "";
    public String lastDlqSettlementItemId = "";
    public String savedSettlementItemId1 = "";
    public String savedSettlementItemId2 = "";
    public String lastSettlementLevelId = "";
    public String lastAtlasSettlementLevelId = "";
    public String lastRegistrationId = "";
    public String lastRegistrationSetId = "";
    public String lastPortfolioId = "";
    public String lastUpdatedBy = "";
    public String lastUpdatedDttmUtc = "";
    public String lastPipelineRunId = "";
    public List<PipelineStateItem> lastPipelineStateItems = new ArrayList<>();
    public final Deque<HttpStatus> expectedStatus = new ArrayDeque<>();
    public final HashMap<String, String> savedValues = new HashMap<>(); // indexed by user-supplied tag
    public final HashMap<String, HashMap<String, Object>> savedSettlements = new HashMap<>();  // indexed by settlement id
    public final HashMap<String, HashMap<String, Object>> savedSettlementItems = new HashMap<>();  // indexed by settlement item id
    public Optional<Registration> savedRegistrationOpt = Optional.empty();
    public static HashMap<String, String> settlementSecretValues = new HashMap<>();
    public static HashMap<String, String> stmCreateSecretValues = new HashMap<>();
    public static HashMap<String, String> metadataSecretValues = new HashMap<>();
    public static HashMap<String, String> idsSecretValues = new HashMap<>();
    private final HashMap<String, SortedMap<Long, RegistrationHistory>> registrationHistoryMap = new HashMap<>();  // indexed by id sequence key
    private Map<String, Boolean> expectedArmedByRegistrationSetId;

    public final ArrayList<Settlement.ScheduledSettlement> expectedSettlements = new ArrayList<>();
    public final ArrayList<SettlementItem> expectedSettlementItems = new ArrayList<>();
    public final ArrayList<SettlementItem> expectedSettlementItemsSaved = new ArrayList<>();
    public final List<Settlement> pipelineSettlementsProcessed = new ArrayList<>();
    public final List<Settlement> pipelineSettlementsSkipped = new ArrayList<>();
    public List<HashMap<String, Object>> pipelineHistoryForLastRun = new ArrayList<>();
    public HashMap<String, Object> lastApiResponseData = new HashMap<>();
    public long pipelineInvokeEpoch = 0;
    public static Map<String, Map<String, Map<String, String>>> ecoUserCredentials;
    public static String ecoBasicAuthUser = "";
    public static String ecoBasicAuthPass = "";
    public static String ecoBasicAuthKey = "";
    // Header control flags and values
    public Boolean includeAuthorization = true;
    public String authorizationToken;
    public static Map<String, Map<String, Map<String, String>>> ecoExternalUsers;
    public final static String settlementItemTimeboundUrl;
    public final static String settlementItemTimeboundAuditLogUrl;
    public String lastSettlementItemTimeboundId = "";
    public final static String settlementItemTimeboundBaseUrl;

    // Query parameter state
    public String searchId;
    public String searchIdType;
    public Boolean isDuplicateIdType = false;
    public String searchIdTypeDuplicate;
    public Map<String, String> extraQueryParams;



    public enum PROGRAM {AESO, FCAS}
    public PROGRAM program;

    static {
        File configFile = (new File("configuration.json"));
        JsonPath json = new JsonPath(configFile);
        targetEnv = json.getString("env");
        targetLoginUrl = json.getString(String.format("atlas.url.%s", targetEnv));
        targetRefUrl = json.getString(String.format("reference.url.%s", targetEnv));
        refEnums = json.getMap("reference.endpoints");
        productId1 = json.getString(String.format("products.product1.%s", ("dev".equals(targetEnv) || "devtest".equals(targetEnv) ? "dev" : targetEnv)));
        productId2 = json.getString(String.format("products.product2.%s", ("dev".equals(targetEnv) || "devtest".equals(targetEnv) ? "dev" : targetEnv)));
        productId3 = json.getString(String.format("products.product3.%s", ("dev".equals(targetEnv) || "devtest".equals(targetEnv) ? "dev" : targetEnv)));
        organizationIds = json.getMap("organizations");
        registrationConfigs.registrations = JSON.convertValue(json.getMap("registrations"), new TypeReference<>() {});
        itsMappings = json.getMap("itsMappings");
        productRules = json.getMap("productRules");

        targetBaseUrl = String.format("%s/v1", json.getString(String.format("settlementApi.url.%s", targetEnv)));
        getSettlementsUrl = String.format("%s/settlements", targetBaseUrl);
        getSettlementDetailsUrl = String.format("%s/settlement_details", targetBaseUrl);
        getSettlementItemsUrl = String.format("%s/settlement_items", targetBaseUrl);
        getSettlementItemIntervalsSummaryUrl = String.format("%s/settlement_item_interval_summary", targetBaseUrl);
        settlementUrl = String.format("%s/settlement", targetBaseUrl);
        settlementItemUrl = String.format("%s/settlement_item", targetBaseUrl);
        settlementItemIntervalsUrl = String.format("%s/settlement_item_intervals", targetBaseUrl);
        settlementAuditLogUrl = String.format("%s/settlement_audit", targetBaseUrl);
        settlementItemAuditLogUrl = String.format("%s/settlement_item_audit", targetBaseUrl);
        settlementItemIntervalsAuditLogUrl = String.format("%s/settlement_item_intervals_audit", targetBaseUrl);

        targetMetadataUrl = String.format("%s/v1", json.getString(String.format("settlementMetadataApi.url.%s", targetEnv)));
        getProductRulesUrl = String.format("%s/productrules", targetMetadataUrl);
        registrationUrl = String.format("%s/registrations", targetMetadataUrl);
        registrationHistoryUrl = String.format("%s/registration_history", targetMetadataUrl);
        registrationFieldHistoryUrl = String.format("%s/registration_field_history", targetMetadataUrl);
        getFinancialPointMappingUrl = String.format("%s/financialpointmappings", targetMetadataUrl);
        pipelineStateUrl = String.format("%s/pipelinestate", targetMetadataUrl);
        productRuleParametersUrl = String.format("%s/productruleparameters", targetMetadataUrl);
        productRuleFragmentsUrl = String.format("%s/productrulefragments", targetMetadataUrl);
        productRulesUrl = String.format("%s/productrules", targetMetadataUrl);
        productRuleDetailsUrl = String.format("%s/productruledetails", targetMetadataUrl);
        registrationHistoryOverridesUrl = String.format("%s/registration_history_overrides", targetMetadataUrl);
        productRuleGroupsUrl = String.format("%s/productrulegroups", targetMetadataUrl);
        ecoUrl = json.getString(String.format("ecoApi.url.%s", targetEnv));
        adHocFinancialLevels = String.format("%s/api/v1/adhoc-financial/levels", ecoUrl);
        finEngineUrl = json.getString(String.format("finEngineApi.url.%s", targetEnv));
        finEnginePingUrl = String.format("%s/api/v1/ping", finEngineUrl);
        adHocFinancialSearchUrl = String.format("%s/api/v1/adhoc-financial/search", ecoUrl);
        adHocFinancialUrl = String.format("%s/api/v1/adhoc-financial", ecoUrl);
        ecoExternalUrl = json.getString(String.format("ecoExternalApi.url.%s", targetEnv));
        ecoExternalUrlFinancialSearch = String.format("%s/api/v1/adhoc-financial/search", ecoExternalUrl);
        ecoExternalUsers = JSON.convertValue(
                json.getMap("ecoExternalUsers"),
                new TypeReference<>() {
                }
        );

        itsUrl = json.getString(String.format("its.url.%s", targetEnv));
        momUrl = json.getString(String.format("mom.url.%s", targetEnv));
        createSettlementSQSOutputUrl = json.getString(String.format("createSettlementOutputSQS.url.%s", targetEnv));
        createIntervalsSQSInputUrl = json.getString(String.format("createIntervalsInputSQS.url.%s", targetEnv));
        createIntervalsSQSOutputUrl = json.getString(String.format("createIntervalsOutputSQS.url.%s", targetEnv));
        orchestratorSQSInputQueueUrl = json.getString(String.format("orchestratorInputFifoSQS.url.%s", targetEnv));
        creatorSQSInputQueueUrl = json.getString(String.format("creatorInputFifoSQS.url.%s", targetEnv));
        ecoSQSInputQueueUrl = json.getString(String.format("ecoInputSQS.url.%s", targetEnv));
        ecoSQSOutputQueueUrl = json.getString(String.format("ecoOutputSQS.url.%s", targetEnv));
        createItemsSQSInputUrl = json.getString(String.format("createItemsInputSQS.url.%s", targetEnv));
        createSettlementSQSOutputDLQUrl = json.getString(String.format("createSettlementOutputSQS_DLQ.url.%s", targetEnv));
        createItemsSQSInputDLQUrl = json.getString(String.format("createItemsInputSQS_DLQ.url.%s", targetEnv));
        createIntervalsSQSOutputDLQUrl = json.getString(String.format("createIntervalsOutputSQS_DLQ.url.%s", targetEnv));
        createIntervalsSQSInputDLQUrl = json.getString(String.format("createIntervalsInputSQS_DLQ.url.%s", targetEnv));
        ecoInternalSQSInputDLQUrl = json.getString(String.format("ecoInternalInputSQS_DLQ.url.%s", targetEnv));
        createSettlementArn =  json.getString(String.format("createSettlementArn.url.%s", targetEnv));

        targetSettlementCreatorUrl = String.format("%s/v1", json.getString(String.format("settlementCreatorApi.url.%s", targetEnv)));
        settlementCreatorPingUrl = String.format("%s/ping", targetSettlementCreatorUrl);
        settlementCreatorRunPipeline = String.format("%s/run-settlement-pipeline", targetSettlementCreatorUrl);

        settlementItemTimeboundBaseUrl = String.format("%s/v1",
                json.getString(String.format("settlementItemTimeboundApi.url.%s", targetEnv)));
        settlementItemTimeboundUrl = String.format("%s/settlement_item_timebound", settlementItemTimeboundBaseUrl);
        settlementItemTimeboundAuditLogUrl = String.format("%s/settlement_item_timebound_audit", settlementItemTimeboundBaseUrl);


        CREDENTIAL_KEY_FILE = String.format("%s/.aws/credentials", System.getProperty("user.home"));
        CREDENTIAL_KEYSET = json.getString("awsKeyset");

        System.out.printf("***** Target environment: %s   Host: %s\n", targetEnv, targetBaseUrl);

        ecoUserCredentials = JSON.convertValue(
                json.getMap("ecoUsers"),
                new TypeReference<>() {
                }
        );
    }

    public static Context getNewContext() {
        Context context = new Context();
        contextOpt = Optional.of(context);
        AwsSecretsManager secretsManager = new AwsSecretsManager();
        metadataSecretValues = secretsManager.getValueMap("tf-smd-api-" + Context.targetEnv);
        metadataApiKey = metadataSecretValues.getOrDefault("API_KEYS", "missing");
        settlementSecretValues = secretsManager.getValueMap(String.format("tf-stm-%s-settlement-api", Context.targetEnv));
        settlementApiKey = settlementSecretValues.getOrDefault("API_KEYS", "missing");
        refDataApiKey = settlementSecretValues.getOrDefault("REF_DATA_API_KEY", "missing");
        testStartEpoch = System.currentTimeMillis() / 1000;
        idsSecretValues = secretsManager.getValueMap("qaa-" + Context.targetEnv);
        stmCreateSecretValues = secretsManager.getValueMap("tf-stmcreate-" + Context.targetEnv);
        settlementCreatorApiKey = stmCreateSecretValues.getOrDefault("SETTLEMENT_CREATOR_API_KEY", "missing");
        Map<String, String> finEngineSecretValues = secretsManager.getValueMap("tf-finout-" + Context.targetEnv);
        finEngineApiKey = finEngineSecretValues.getOrDefault("FINENGINE_OUTER_API_KEY", "missing");

        return context;
    }

    public static Context getContext() {
        return contextOpt.orElseThrow(NO_CONTEXT);
    }


    public HttpStatus popExpectedStatus(int defaultCode) {
        return expectedStatus.isEmpty() ? HttpStatus.build().withCode(defaultCode) : expectedStatus.pop();
    }


    public HttpStatus popExpectedStatus() {
        assertFalse(expectedStatus.isEmpty(), "You need to use the stepdef 'I expect the next API call to return...'!");
        return expectedStatus.pop();
    }


    public SortedMap<Long, RegistrationHistory> getContextRegistrationHistory(String regId) {
        assertTrue(registrationHistoryMap.containsKey(regId), "No saved history in context!");
        var contextHistory = registrationHistoryMap.get(regId);
        assertFalse(contextHistory.isEmpty(), "Context history is empty!");
        return contextHistory;
    }


    public void initializeContextRegistrationHistory(String regId, SortedMap<Long, RegistrationHistory> history) {
        registrationHistoryMap.put(regId, history);
    }

    public Map<String, Boolean> getExpectedArmedByRegistrationSetId() {
        return expectedArmedByRegistrationSetId;
    }

    public void setExpectedArmedByRegistrationSetId(Map<String, Boolean> expected) {
        this.expectedArmedByRegistrationSetId = expected;
    }

    private Context() {
        LOG.info(String.format("Creating a fresh context. JVM: %s %s", System.getProperty("java.vendor", "Vendor: unknown"),
                System.getProperty("java.vendor.version", "Version: unknown")));
    }
}
