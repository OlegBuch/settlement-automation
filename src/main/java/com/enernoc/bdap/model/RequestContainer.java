package com.enernoc.bdap.model;

import com.enernoc.bdap.shared.Context;
import com.enernoc.bdap.shared.Utility;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.restassured.common.mapper.TypeRef;
import io.restassured.http.ContentType;
import io.restassured.response.Response;
import io.restassured.response.ValidatableResponse;
import io.restassured.specification.RequestSpecification;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.time.ZonedDateTime;
import java.util.*;
import java.util.stream.Collectors;

import static com.enernoc.bdap.model.Endpoint.*;
import static com.enernoc.bdap.model.Endpoint.ResponseType.*;
import static com.enernoc.bdap.model.EntityType.*;
import static com.enernoc.bdap.model.HttpOp.*;
import static com.enernoc.bdap.shared.Context.*;
import static io.restassured.RestAssured.given;
import static org.junit.jupiter.api.Assertions.*;
import io.restassured.config.DecoderConfig;
import io.restassured.config.RestAssuredConfig;

public class RequestContainer {

    private static final ObjectMapper JSON = new ObjectMapper();
    private static final Logger LOG = LoggerFactory.getLogger("RequestContainer");

    public String url;
    private final HashMap<String, Object> queryParms = new HashMap<>();
    private final HashMap<String, Object> bodyProps = new HashMap<>();
    private final List<HashMap<String, Object>> bodyPropsList = new ArrayList<>();
    private final Context context = Context.getContext();

    public Endpoint endpoint;
    public Response response;
    public HashMap<String, Object> responseMap;
    public boolean statusVerified = false;
    private String rawJsonPayload;
    private final HashMap<String, Object> headers = new HashMap<>();
    private boolean noContentDecoding = false;

    public RequestContainer withoutContentDecoding() {
        noContentDecoding = true;
        return this;
    }

    public RequestContainer addHeader(String name, Object value) {
        headers.put(name, value);
        return this;
    }

    public static RequestContainer build() {
        RequestContainer request = new RequestContainer();
        return request;
    }

    public RequestContainer addQueryParm(String name, Object value) {
        queryParms.put(name, value);
        return this;
    }

    public RequestContainer addQueryParms(HashMap<String, Object> params) {
        queryParms.putAll(params);
        return this;
    }

    public RequestContainer getEntities(EntityType entityType) {
        endpoint = entityType.get;
        assertNotNull(endpoint, "endpoint not supported!");
        assertEquals(LIST, endpoint.responseType, "endpoint does not return a list of entities!");
        url = endpoint.baseUrl;
        return this;
    }

    public RequestContainer getEntity(EntityType entityType, String id) {
        endpoint = entityType.get;
        assertNotNull(endpoint, "endpoint not supported!");
        assertEquals(MAP, endpoint.responseType, "endpoint does not return a single entity!");
        assertFalse(id == null || id.isEmpty(), "Entity id missing!!");
        url = endpoint.baseUrl;
        if (!"not specified".equals(id)) {
            url = url + "/" + id;
        }
        return this;
    }

    public RequestContainer getLastEntity(EntityType entityType) {
        return switch (entityType) {
            case SETTLEMENT -> getEntity(entityType, context.lastSettlementId);
            case SETTLEMENT_ITEM -> getEntity(entityType, context.lastSettlementItemId);
            case REGISTRATION -> getEntity(entityType, context.lastRegistrationId);
            default -> fail("Invalid entity type specified: " + entityType);
        };
    }

    public RequestContainer getWithUrl(EntityType entityType, String urlParm) {
        boolean isTimeboundEntity = entityType == SETTLEMENT_ITEM_TIMEBOUND
                || entityType == SETTLEMENT_ITEM_TIMEBOUNDS;
        String base = isTimeboundEntity ? settlementItemTimeboundBaseUrl : targetBaseUrl;
        url = String.format("%s/%s", base, urlParm.replace("/v1/", ""));
        endpoint = entityType.get;
        assertNotNull(endpoint, "endpoint not supported!");
        return this;
    }


    public RequestContainer getWithMetadataUrl(EntityType entityType, String urlParm) {
        url = String.format("%s/%s", targetMetadataUrl, urlParm.replace("/api/v1/", ""));
        endpoint = entityType.get;
        assertNotNull(endpoint, "endpoint not supported!");
        return this;
    }

    public RequestContainer addIdToPath(String id) {
        url += "/" + id;
        return this;
    }

    public RequestContainer addRefresh(Optional<String> refreshOpt) {
        refreshOpt.ifPresent(r -> url += "?refresh=" + refreshOpt.get());
        return this;
    }

    public RequestContainer submitEntity(HttpOp verb, EntityType entityType, HashMap<String, Object> props) {
        crudEpoch = ZonedDateTime.now().toEpochSecond();
        endpoint = switch (verb) {
            case POST -> entityType.post;
            case PUT -> entityType.put;
            case PATCH -> entityType.patch;
            default -> fail("Invalid http verb specified: " + verb);
        };
        assertNotNull(endpoint, "endpoint not supported!");
        url = endpoint.baseUrl;
        if (SETTLEMENT_ITEM.equals(entityType) && PATCH.equals(verb)) {
            var queryParmOpt = props.keySet().stream().filter(key -> !"settlement_item_id".equals(key) && !"change_comments".equals(key) && !"force".equals(key)).findFirst();
            assertTrue(queryParmOpt.isPresent(), "No property to patch in payload!");
            url += "?patch_type=" + queryParmOpt.get();
        }
        bodyProps.clear();
        bodyProps.putAll(props);
        return this;
    }

    public RequestContainer submitIntervals(HttpOp verb, List<HashMap<String, Object>> entityList) {
        crudEpoch = ZonedDateTime.now().toEpochSecond();
        endpoint = switch (verb) {
            case POST -> SETTLEMENT_ITEM_INTERVALS.post;
            case PUT -> SETTLEMENT_ITEM_INTERVALS.put;
            case PATCH -> SETTLEMENT_ITEM_INTERVALS.patch;
            default -> fail("Invalid verb!");
        };
        url = endpoint.baseUrl;
        bodyPropsList.clear();
        bodyPropsList.addAll(entityList);
        return this;
    }

    public RequestContainer deleteEntity(EntityType entityType, String id) {
        assertNotNull(entityType.delete);
        crudEpoch = ZonedDateTime.now().toEpochSecond();
        endpoint = entityType.delete;
        assertNotNull(endpoint, "endpoint not supported!");
        url = String.format("%s/%s", endpoint.baseUrl, id);
        return this;
    }

    public RequestContainer getAuditLog(EntityType entityType, String id) {
        endpoint = switch (entityType) {
            case SETTLEMENT -> GET_SETTLEMENT_AUDIT_LOG;
            case SETTLEMENT_ITEM -> GET_SETTLEMENT_ITEM_AUDIT_LOG;
            case SETTLEMENT_ITEM_INTERVALS -> GET_SETTLEMENT_ITEM_INTERVALS_AUDIT_LOG;
            case SETTLEMENT_ITEM_TIMEBOUND -> GET_SETTLEMENT_ITEM_TIMEBOUND_AUDIT_LOG;
            default -> fail("Invalid entity type specified: " + entityType);
        };
        url = String.format("%s/%s", endpoint.baseUrl, id);
        return this;
    }

    public RequestContainer getAuditLogUrl(EntityType entityType, String urlParm) {
        endpoint = switch (entityType) {
            case SETTLEMENT -> GET_SETTLEMENT_AUDIT_LOG;
            case SETTLEMENT_ITEM -> GET_SETTLEMENT_ITEM_AUDIT_LOG;
            case SETTLEMENT_ITEM_INTERVALS -> GET_SETTLEMENT_ITEM_INTERVALS_AUDIT_LOG;
            case SETTLEMENT_ITEM_TIMEBOUND -> GET_SETTLEMENT_ITEM_TIMEBOUND_AUDIT_LOG;
            default -> fail("Invalid entity type specified: " + entityType);
        };
        boolean isTimeboundEntity = entityType == SETTLEMENT_ITEM_TIMEBOUND;
        String base = isTimeboundEntity ? settlementItemTimeboundBaseUrl : targetBaseUrl;
        url = String.format("%s/%s", base, urlParm.replace("/v1/", ""));
        return this;
    }

    public RequestContainer getPipelineStateHistoryItem(HashMap<String, Object> props) {
        endpoint = GET_PIPELINE_STATE;
        url = getUrlForPipelineStateHistoryRequest(props);
        return this;
    }

    public RequestContainer postPipelineStateHistoryItem(HashMap<String, Object> props) {
        endpoint = POST_PIPELINE_STATE;
        url = getUrlForPipelineStateHistoryRequest(props);
        return this;
    }

    private String getUrlForPipelineStateHistoryRequest(HashMap<String, Object> props) {
        String returnString = props != null ? props.entrySet().stream().map(e -> e.getKey() + "=" + e.getValue().toString()).collect(Collectors.joining("&", endpoint.baseUrl + "?", "")) : endpoint.baseUrl;
        return returnString;
    }

    public void postITSMapping(String flexId, String ecrmId, String itsApiKey) {
        ItsMapping req = new ItsMapping();
        req.from.id = flexId;
        req.to.id = ecrmId;
        var temp = given().header("x-api-key", itsApiKey);
        if (context.logAllAPIRequests) {
            temp = temp.log().all();
        }
        var response = temp.with().contentType(ContentType.JSON).body(req).post(itsUrl + "/create");
        var tempR = response.then();
        if (context.logAllAPIResponses) {
            tempR = tempR.log().all(true);
        }
        HashMap<String, Object> responseMap = tempR.assertThat().statusCode(200).contentType(ContentType.JSON).extract().as(new TypeRef<>() {});
        HashMap<String, Object> data = (HashMap<String, Object>) responseMap.get("data");
        ItsMapping itsResult = JSON.convertValue(data, new TypeReference<>() {});
        assertNotNull(itsResult.to.id);
    }

    public void deleteITSMapping(String flexId, String ecrmId, String itsApiKey) {
        if (!doesITSMappingExist(flexId, itsApiKey)) {
            return;
        }
        ItsMapping req = new ItsMapping();
        req.from.id = flexId;
        req.to.id = ecrmId;
        var temp = given().header("x-api-key", itsApiKey);
        if (context.logAllAPIRequests) {
            temp = temp.log().all();
        }
        var response = temp.with().contentType(ContentType.JSON).body(req).post(itsUrl + "/delete");
        var tempR = response.then();
        if (context.logAllAPIResponses) {
            tempR = tempR.log().all(true);
        }
        HashMap<String, Object> responseMap = tempR.assertThat().statusCode(200).contentType(ContentType.JSON).extract().as(new TypeRef<>() {});
        HashMap<String, Object> data = (HashMap<String, Object>) responseMap.get("data");
        ItsMapping itsResult = JSON.convertValue(data, new TypeReference<>() {});
        assertNotNull(itsResult.to.id);
    }

    public boolean doesITSMappingExist(String flexId, String itsApiKey) {
        ItsMapping req = new ItsMapping();
        req.from.id = flexId;
        var temp = given().header("x-api-key", itsApiKey);
        if (context.logAllAPIRequests) {
            temp = temp.log().all();
        }
        var response = temp.with().contentType(ContentType.JSON).body(List.of(req)).post(itsUrl);
        var tempR = response.then();
        if (context.logAllAPIResponses) {
            tempR = tempR.log().all(true);
        }
        HashMap<String, Object> responseMap = tempR.assertThat().statusCode(200).contentType(ContentType.JSON).extract().as(new TypeRef<>() {});
        List<HashMap<String, Object>> data = (List<HashMap<String, Object>>) responseMap.get("data");
        return !data.isEmpty();
    }

    public Optional<String> getITSMapping(String flexId, String itsApiKey) {
        ItsMapping req = new ItsMapping();
        req.from.id = flexId;
        var temp = given().header("x-api-key", itsApiKey);
        if (context.logAllAPIRequests) {
            temp.log().all();
        }
        var response = temp.with().contentType(ContentType.JSON).body(List.of(req)).post(itsUrl);
        var tempR = response.then();
        if (context.logAllAPIResponses) {
            tempR = tempR.log().all(true);
        }
        HashMap<String, Object> responseMap = tempR.assertThat().statusCode(200).contentType(ContentType.JSON).extract().as(new TypeRef<>() {});
        List<HashMap<String, Object>> data = (List<HashMap<String, Object>>) responseMap.get("data");
        if (data.isEmpty()) {
            return Optional.empty();  // mapping does not exist
        }
        assertEquals(1, data.size(), "More than one mapping returned!");
        ItsMapping itsResult = JSON.convertValue(data.get(0), new TypeReference<>() {});
        assertNotNull(itsResult.to.id);
        return Optional.of(itsResult.to.id);
    }

    private RequestSpecification authorized() {
        var spec = given();

        if (endpoint != null && endpoint.api == API.ECO_API) {
            spec = spec.relaxedHTTPSValidation();
            spec = spec.header("Accept", "application/json, text/plain, */*");

            LOG.info("🔍 DEBUG AUTH: endpoint={}, ecoUser='{}', ecoPass='{}', enocSession='{}', includeAuth={}, authToken='{}'",
                    endpoint.name(), Context.ecoBasicAuthUser, Context.ecoBasicAuthPass, Context.enocSession,
                    context.includeAuthorization, context.authorizationToken);

            // 1. Handle Authorization (Basic Auth or explicit token)
            if (context.includeAuthorization != null && context.includeAuthorization) {
                if (context.authorizationToken != null) {
                    // Use explicit token (for valid, invalid, or empty token test cases)
                    spec = spec.header("Authorization", context.authorizationToken);
                } else if (!Context.ecoBasicAuthUser.isEmpty() && !Context.ecoBasicAuthPass.isEmpty()) {
                    // Fallback to Basic Auth if no explicit token is set but credentials exist
                    spec = spec.auth().basic(Context.ecoBasicAuthUser, Context.ecoBasicAuthPass);
                }
            }

            // 2. Handle enoc_session for the Search endpoint and Adhoc financial endpoints
            // Levels and Fields endpoints do NOT require the enoc_session header
            boolean isFinEngineEndpoints = (endpoint == Endpoint.POST_ADHOC_FINANCIAL_API_SEARCH || endpoint == Endpoint.POST_ADHOC_FINANCIAL ||
                    endpoint == Endpoint.GET_ADHOC_FINANCIAL ||
                    endpoint == Endpoint.PUT_ADHOC_FINANCIAL ||
                    endpoint == Endpoint.DELETE_ADHOC_FINANCIAL);

            if (isFinEngineEndpoints) {
                if (context.includeEnocSession) {
                    String sessionValue = Context.enocSession != null ? Context.enocSession : "";
                    spec = spec.header("enoc_session", sessionValue);
                    if (endpoint == Endpoint.POST_ADHOC_FINANCIAL && !Context.ecoBasicAuthKey.isEmpty() && context.includeApiKey) {
                        // Use encoded API key
                        spec = spec.header("Authorization", Context.ecoBasicAuthKey);
                    }
                }
            }
        } else {
            // Include API key if enabled (for non-ECO APIs)
            if (context.includeApiKey) {
                String apiKey = context.includeInvalidApiKey
                        ? "STWncF5rE9rg5DXNFdwZY6A4fjuFi7VRAuYcmBt1t8FeXJfZ8Qe2"
                        : switch (endpoint.api) {
                    case METADATA_API -> metadataApiKey;
                    case SETTLEMENT_API -> settlementApiKey;
                    case SETTLEMENT_CREATOR_API -> settlementCreatorApiKey;
                    case FIN_ENGINE_API -> finEngineApiKey;
                    default -> null;
                };

                switch (endpoint.api) {
                    case METADATA_API, SETTLEMENT_CREATOR_API, FIN_ENGINE_API -> spec = spec.header("x-api-key", apiKey);
                    case SETTLEMENT_API -> {
                        // TODO: temporary explicit override for settlement_item_timebound endpoints,
                        // which are hardcoded to an internal dev URL (see Context.settlementItemTimeboundBaseUrl)
                        // until this resource is deployed/routed on the standard per-environment settlementApi.url.
                        // Remove this special-case once that happens, leaving only the targetBaseUrl check below.
                        boolean isTimeboundEndpoint = endpoint == GET_SETTLEMENT_ITEM_TIMEBOUND
                                || endpoint == GET_SETTLEMENT_ITEM_TIMEBOUNDS
                                || endpoint == POST_SETTLEMENT_ITEM_TIMEBOUND
                                || endpoint == PUT_SETTLEMENT_ITEM_TIMEBOUND
                                || endpoint == PATCH_SETTLEMENT_ITEM_TIMEBOUND
                                || endpoint == DELETE_SETTLEMENT_ITEM_TIMEBOUND
                                || endpoint == GET_SETTLEMENT_ITEM_TIMEBOUND_AUDIT_LOG;

                        if (isTimeboundEndpoint || Context.targetBaseUrl.contains("internal")) {
                            spec = spec.header("x-api-key", apiKey);
                        }
                    }
                    default -> {}
                }
            }

            // Include enoc_session if enabled (for non-ECO APIs)
            if (context.includeEnocSession) {
                if (context.includeInvalidEnocSession) {
                    spec = spec.header("enoc_session",
                            "eyJzc29Ub2tlbiI6IjRRd2dQbDNLNHBSSmwtbGhSckxubEFseV92NC4qQUFKVFNRQUNNRElBQWxOTEFCeDBWbWRYUkZGc2RsTnNiRFZwVFUxNlRFdHZlamwyTW5wWWJEZzlBQVIwZVhCbEFBTkRWRk1BQWxNeEFBSXdNUS4uKiJ0");
                } else {
                    assertFalse(Context.enocSession.isBlank(),
                            "No user session! Maybe you forgot the stepdef 'Given I log in as a settlement API admin/user'");
                    spec = spec.header("enoc_session", Context.enocSession);
                }
            }
        }

        // Apply per-request custom headers (e.g., Accept-Encoding: gzip)
        if (!headers.isEmpty()) {
            for (Map.Entry<String, Object> h : headers.entrySet()) {
                spec = spec.header(h.getKey(), h.getValue());
            }
        }

        if (noContentDecoding) {
            // keep the body exactly as the server sent it, and stop RestAssured adding its own Accept-Encoding
            spec = spec.config(RestAssuredConfig.config()
                    .decoderConfig(DecoderConfig.decoderConfig().noContentDecoders()));
        }

        // Always include trace id — applies to ALL APIs including ECO
        var traceid = UUID.randomUUID();
        spec = spec.header("x-enelx-trace-id", traceid);
        if (!context.logAllAPIRequests) {
            LOG.info("x-enelx-trace-id: {}", traceid);
        }

        // Add appropriate log level
        spec = context.logAllAPIRequests ? spec.log().all(true) : spec.log().method().log().uri();

        return spec;
    }

    private Response addVerb(RequestSpecification spec) {
        return switch (endpoint.verb) {
            case POST -> spec.post(url);
            case PUT -> spec.put(url);
            case PATCH -> spec.patch(url);
            default -> {
                fail();
                yield spec.post(url); // won't be reached, but makes compiler happy
            }
        };
    }

    private Response authorizedWithJSON() {
        return addVerb(authorized().with().contentType(ContentType.JSON).body(bodyProps));
    }

    private Response authorizedWithJSONList() {
        return addVerb(authorized().with().contentType(ContentType.JSON).body(bodyPropsList));
    }

    /**
     * Sends an HTTP verb that the adhoc-financial endpoint does NOT support
     * (e.g. PATCH) to the {id} resource, for 405 Method Not Allowed tests.
     * Reuses GET_ADHOC_FINANCIAL's endpoint metadata purely so authorized()
     * applies the correct ECO / enoc_session headers - this does not perform a GET,
     * it fires the given verb directly and bypasses the call(HttpStatus) switch,
     * since there is no PATCH_ADHOC_FINANCIAL entry in the Endpoint enum.
     */
    public RequestContainer sendUnsupportedMethod(String httpMethod, String resource, String id) {
        endpoint = Endpoint.GET_ADHOC_FINANCIAL;
        url = String.format("%s/%s", endpoint.baseUrl, id);
        RequestSpecification spec = authorized();
        response = switch (httpMethod.toUpperCase()) {
            case "PATCH" -> spec.patch(url);
            case "OPTIONS" -> spec.options(url);
            case "HEAD" -> spec.head(url);
            case "TRACE" -> spec.request(io.restassured.http.Method.TRACE, url);
            default -> throw new IllegalArgumentException("Unsupported test verb: " + httpMethod);
        };
        return this;
    }

    /**
     * Asserts a raw status code without going through the JSON/"code"+"message"
     * pipeline in call(HttpStatus) - needed for verbs/paths that return a
     * Tomcat HTML error page (405, some 404s) rather than the ECO JSON envelope.
     */
    public RequestContainer assertRawStatusCode(int expectedCode) {
        var vr = context.logAllAPIResponses ? response.then().log().all(true) : response.then().log().ifValidationFails();
        vr.assertThat().statusCode(expectedCode);

        if (responseMap == null) {
            responseMap = new HashMap<>();
            responseMap.put("code", response.getStatusCode());
            responseMap.put("detail", response.getBody() != null ? response.getBody().asString() : "<no body>");
        }

        statusVerified = true;
        return this;
    }

    public RequestContainer call() {
        return call(HttpStatus.build().withCode(200));
    }

    public RequestContainer call(int code) {
        return call(HttpStatus.build().withCode(code));
    }

    public RequestContainer call(HttpStatus expectedStatus) {

        context.lastRequest = this;

        // Need to convert boolean strings into boolean objects for JSON
        Utility.stringToBoolean(bodyProps);
        bodyPropsList.forEach(Utility::stringToBoolean);

        response = switch (endpoint) {
            // Settlement API
            case GET_SETTLEMENT, GET_SETTLEMENTS, GET_SETTLEMENT_DETAILS, GET_SETTLEMENT_ITEM, GET_SETTLEMENT_ITEMS, GET_SETTLEMENT_ITEM_INTERVAL_SUMMARY,
                 GET_SETTLEMENT_ITEM_TIMEBOUND, GET_SETTLEMENT_ITEM_TIMEBOUNDS ->
                    queryParms.isEmpty() ? authorized().get(url) : authorized().with().queryParams(queryParms).get(url);
            case GET_SETTLEMENT_ITEM_INTERVALS -> authorized().with().header("Accept-Encoding","gzip").queryParams(queryParms).get(url);
            case POST_SETTLEMENT, POST_SETTLEMENT_ITEM, PUT_SETTLEMENT, PUT_SETTLEMENT_ITEM, PATCH_SETTLEMENT, PATCH_SETTLEMENT_ITEM -> authorizedWithJSON();
            case POST_SETTLEMENT_ITEM_INTERVALS, PUT_SETTLEMENT_ITEM_INTERVALS, PATCH_SETTLEMENT_ITEM_INTERVALS -> authorizedWithJSONList();
            case DELETE_SETTLEMENT, DELETE_SETTLEMENT_ITEM, DELETE_SETTLEMENT_ITEM_INTERVALS, DELETE_SETTLEMENT_ITEM_TIMEBOUND -> authorized().with().delete(url);
            case GET_SETTLEMENT_AUDIT_LOG, GET_SETTLEMENT_ITEM_AUDIT_LOG, GET_SETTLEMENT_ITEM_INTERVALS_AUDIT_LOG, GET_SETTLEMENT_ITEM_TIMEBOUND_AUDIT_LOG -> authorized().with().queryParams(queryParms).get(url);

            // Metadata API
            case GET_REGISTRATION, GET_FINANCIAL_POINT_MAPPING -> authorized().with().queryParams(queryParms).get(url);
            case POST_REGISTRATION, PUT_REGISTRATION -> authorizedWithJSON();
            case DELETE_REGISTRATION -> authorized().with().delete(url);
            case GET_REGISTRATION_HISTORY -> authorized().with().queryParams(queryParms).get(url);
            case GET_PIPELINE_STATE -> queryParms.isEmpty() ? authorized().get(url) : authorized().with().queryParams(queryParms).get(url);
            case POST_PIPELINE_STATE -> queryParms.isEmpty() ? authorized().post(url) : authorized().with().queryParams(queryParms).post(url);
            //Product rule parameters
            case GET_PRODUCT_RULE_PARAMETER, GET_PRODUCT_RULE_PARAMETERS ->
                    queryParms.isEmpty() ? authorized().get(url) : authorized().with().queryParams(queryParms).get(url);
            case POST_PRODUCT_RULE_PARAMETERS, PUT_PRODUCT_RULE_PARAMETERS -> authorizedWithJSON();
            case DELETE_PRODUCT_RULE_PARAMETER -> authorized().with().delete(url);
            //Product rule fragments
            case GET_PRODUCT_RULE_FRAGMENT, GET_PRODUCT_RULE_FRAGMENTS ->
                    queryParms.isEmpty() ? authorized().get(url) : authorized().with().queryParams(queryParms).get(url);
            case POST_PRODUCT_RULE_FRAGMENTS, PUT_PRODUCT_RULE_FRAGMENTS -> authorizedWithJSON();
            case PUT_PRODUCT_RULE_FRAGMENT_PARAMETERS -> authorizedWithJSONList();
            case DELETE_PRODUCT_RULE_FRAGMENT -> authorized().with().delete(url);
            //Product rules
            case GET_PRODUCT_RULE, GET_PRODUCT_RULES ->
                    queryParms.isEmpty() ? authorized().get(url) : authorized().with().queryParams(queryParms).get(url);
            case POST_PRODUCT_RULES, PUT_PRODUCT_RULES -> authorizedWithJSON();
            case DELETE_PRODUCT_RULE -> authorized().with().delete(url);
            //Product rule details
            case GET_PRODUCT_RULE_DETAIL, GET_PRODUCT_RULE_DETAILS ->
                    queryParms.isEmpty() ? authorized().get(url) : authorized().with().queryParams(queryParms).get(url);
            case POST_PRODUCT_RULE_DETAILS, PUT_PRODUCT_RULE_DETAILS -> authorizedWithJSON();
            case DELETE_PRODUCT_RULE_DETAIL -> authorized().with().delete(url);
            //Registration history overrides
            case GET_REGISTRATION_HISTORY_OVERRIDE, GET_REGISTRATION_HISTORY_OVERRIDES ->
                    queryParms.isEmpty() ? authorized().get(url) : authorized().with().queryParams(queryParms).get(url);
            case POST_REGISTRATION_HISTORY_OVERRIDES, PUT_REGISTRATION_HISTORY_OVERRIDES -> authorizedWithJSON();
            case DELETE_REGISTRATION_HISTORY_OVERRIDE -> authorized().with().delete(url);
            //Settlement creator ping
            case GET_SETTLEMENT_CREATOR_PING -> queryParms.isEmpty() ? authorized().get(url) : authorized().with().queryParams(queryParms).get(url);
            case POST_RUN_SETTLEMENT_PIPELINE ->
                    authorized().with().contentType(ContentType.JSON).body(bodyProps).post(url);
            //Product rule groups
            case GET_PRODUCT_RULE_GROUPS, GET_PRODUCT_RULE_GROUP ->
                    queryParms.isEmpty() ? authorized().get(url) : authorized().with().queryParams(queryParms).get(url);
            case POST_PRODUCT_RULE_GROUPS, PUT_PRODUCT_RULE_GROUPS -> authorizedWithJSON();
            case DELETE_PRODUCT_RULE_GROUP -> authorized().with().delete(url);

            // Eco Adhoc Financial Api
            case GET_ADHOC_FINANCIAL_API_LEVELS ->
                    queryParms.isEmpty() ? authorized().get(url) : authorized().with().queryParams(queryParms).get(url);
            case POST_ADHOC_FINANCIAL_API_SEARCH ->
                    authorized().contentType(ContentType.JSON).post(url);
            case POST_ADHOC_FINANCIAL -> rawJsonPayload != null
                    ? authorized().with().contentType(ContentType.JSON).body(rawJsonPayload).post(url)
                    : authorizedWithJSONList();
            case GET_ADHOC_FINANCIAL -> authorized().get(url);
            case PUT_ADHOC_FINANCIAL -> rawJsonPayload != null
                    ? authorized().with().contentType(ContentType.JSON).body(rawJsonPayload).put(url)
                    : authorizedWithJSON();
            case DELETE_ADHOC_FINANCIAL -> rawJsonPayload != null
                    ? authorized().with().contentType(ContentType.JSON).body(rawJsonPayload).delete(url)
                    : authorized().delete(url);

            // Fin Engine Api
            case GET_FIN_ENGINE_API_PING -> queryParms.isEmpty() ? authorized().get(url) : authorized().with().queryParams(queryParms).get(url);

            case POST_SETTLEMENT_ITEM_TIMEBOUND, PUT_SETTLEMENT_ITEM_TIMEBOUND, PATCH_SETTLEMENT_ITEM_TIMEBOUND -> authorizedWithJSONList();

            default -> fail("Invalid endpoint type: " + endpoint);
        };

        ValidatableResponse vr = context.logAllAPIResponses ? response.then().log().all(true) : response.then().log().ifValidationFails();
        vr = vr.assertThat().statusCode(expectedStatus.code);

        boolean isEco = endpoint != null && endpoint.api == API.ECO_API;

        if (expectedStatus.code != 204) {
            String actualContentType = response.getContentType();
            boolean isJson = actualContentType != null && actualContentType.contains("json");

            if (isJson) {
                try {
                    // Attempt to parse as JSON
                    responseMap = vr.contentType(ContentType.JSON).extract().as(new TypeRef<>() {});
                } catch (Exception e) {
                    // FALLBACK: Server claimed JSON but sent plain text (e.g., Tomcat/Spring default error pages)
                    LOG.warn("Failed to parse response as JSON despite Content-Type. Falling back to raw body. Error: {}", e.getMessage());
                    responseMap = new HashMap<>();
                    responseMap.put("code", expectedStatus.code);
                    responseMap.put("message", response.getBody().asString());
                }
            } else {
                // ECO returns HTML error pages (Tomcat) for 401/403 — store raw body
                LOG.info("Non-JSON response ({}): parsing as raw body", actualContentType);
                responseMap = new HashMap<>();
                responseMap.put("code", expectedStatus.code);
                responseMap.put("message", response.getBody().asString());
            }
            if (!isEco) {
                // Standard APIs always have code + message
                assertEquals(expectedStatus.code, (int) responseMap.get("code"), "Unexpected status code in response!");
                assertEquals(expectedStatus.message, responseMap.get("message").toString(), "Unexpected status message in response!");
                String expectedDetails = expectedStatus.details;
                if (!expectedDetails.isBlank()) {
                    String actualDetails = responseMap.get("detail").toString();
                    if (!actualDetails.contains(expectedDetails)) {
                        fail(String.format("Expected details: '%s'  Actual: '%s'", expectedDetails, actualDetails));
                    }
                }
            } else {
                // ECO has "code" but no "message" — only validate code
                Object ecoCode = responseMap.get("code");
                assertNotNull(ecoCode, "ECO response missing 'code' field!");
                assertEquals(expectedStatus.code, ((Number) ecoCode).intValue(), "Unexpected ECO status code!");
            }
        }

        if (expectedStatus.code == 200 || expectedStatus.code == 201) {
            switch (endpoint.responseType) {
                case MAP -> assertInstanceOf(HashMap.class, responseMap.get("data"));
                case LIST -> assertInstanceOf(ArrayList.class, responseMap.get("data"));
                case STRING -> assertInstanceOf(String.class, responseMap.get("detail"));
                case NONE -> {} // <--- Added this: Do nothing, no "data" field is expected
            }
        }

        statusVerified = true;
        return this;
    }

    public <T> T getResponseEntity(Class<T> entityClass) {
        return switch ((int) responseMap.get("code")) {
            case 200, 201 -> (T) response.then().extract().as(entityClass);
            default -> null;
        };
    }

    public HashMap<String, Object> getQueryParms() {
        return queryParms;
    }

    public HashMap<String, Object> getBodyProps() {
        return bodyProps;
    }

    public List<HashMap<String, Object>> getBodyPropsList() {
        return bodyPropsList;
    }

    public List<HashMap<String, Object>> getDataAsList() {
        Object result = switch (endpoint.responseType) {
            case LIST -> responseMap.get("data");
            case MAP -> new ArrayList<>() {{
                this.add(responseMap.get("data"));
            }};
            default -> fail("Response does not contain a map or array");
        };
        return (List<HashMap<String, Object>>) result;
    }

    public RequestContainer getWithEcoUrl(Endpoint ecoEndpoint, String pathSuffix) {
        if (pathSuffix == null || pathSuffix.isEmpty()) {
            url = Context.adHocFinancialLevels;
        } else {
            url = String.format("%s/%s", Context.adHocFinancialLevels, pathSuffix);
        }
        endpoint = ecoEndpoint;
        assertNotNull(endpoint, "ECO endpoint not supported!");
        return this;
    }

    public RequestContainer postWithEcoUrl(String path, String queryString) {
        this.url = Context.ecoUrl + path;
        if (queryString != null && !queryString.isEmpty()) {
            this.url += queryString; // queryString should already start with "?" if not empty
        }
        this.endpoint = Endpoint.POST_ADHOC_FINANCIAL_API_SEARCH;
        assertNotNull(this.endpoint, "ECO endpoint not supported!");
        return this;
    }

    public RequestContainer submitAdhocFinancial(List<HashMap<String, Object>> entityList) {
        endpoint = POST_ADHOC_FINANCIAL;
        assertNotNull(endpoint, "endpoint not supported!");
        url = endpoint.baseUrl;
        bodyPropsList.clear();
        bodyPropsList.addAll(entityList);
        return this;
    }

    public RequestContainer submitRawAdhocFinancial(String rawJson) {
        endpoint = POST_ADHOC_FINANCIAL;
        assertNotNull(endpoint, "endpoint not supported!");
        url = endpoint.baseUrl;
        this.rawJsonPayload = rawJson;
        return this;
    }

    public RequestContainer getAdhocFinancial(String id) {
        endpoint = Endpoint.GET_ADHOC_FINANCIAL;
        url = String.format("%s/%s", endpoint.baseUrl, id);
        return this;
    }

    public RequestContainer updateAdhocFinancial(String id, HashMap<String, Object> body) {
        endpoint = Endpoint.PUT_ADHOC_FINANCIAL;
        url = String.format("%s/%s", endpoint.baseUrl, id);
        bodyProps.clear();
        bodyProps.putAll(body);
        this.rawJsonPayload = null; // ensure a prior raw-payload call on this instance can't leak through
        return this;
    }

    /**
     * PUT with a raw JSON string body instead of a structured map - for
     * malformed-JSON, duplicate-key, and array-instead-of-object negative tests.
     */
    public RequestContainer updateAdhocFinancialRaw(String id, String rawJson) {
        endpoint = Endpoint.PUT_ADHOC_FINANCIAL;
        url = String.format("%s/%s", endpoint.baseUrl, id);
        this.rawJsonPayload = rawJson;
        return this;
    }

    public RequestContainer deleteAdhocFinancial(String id) {
        endpoint = Endpoint.DELETE_ADHOC_FINANCIAL;
        url = String.format("%s/%s", endpoint.baseUrl, id);
        return this;
    }

    /**
     * DELETE with a request body attached - for the "body should be ignored"
     * negative/edge test. Most servers ignore a DELETE body, but RestAssured
     * needs contentType+body set explicitly to send one.
     */
    public RequestContainer deleteAdhocFinancialWithBody(String id, String rawJson) {
        endpoint = Endpoint.DELETE_ADHOC_FINANCIAL;
        url = String.format("%s/%s", endpoint.baseUrl, id);
        this.rawJsonPayload = rawJson;
        return this;
    }

    public RequestContainer submitTimebounds(HttpOp verb, List<HashMap<String, Object>> entityList) {
        crudEpoch = ZonedDateTime.now().toEpochSecond();
        endpoint = switch (verb) {
            case POST -> Endpoint.POST_SETTLEMENT_ITEM_TIMEBOUND;
            case PUT -> Endpoint.PUT_SETTLEMENT_ITEM_TIMEBOUND;
            case PATCH -> Endpoint.PATCH_SETTLEMENT_ITEM_TIMEBOUND;
            default -> fail("Invalid verb!");
        };
        url = endpoint.baseUrl;
        bodyPropsList.clear();
        bodyPropsList.addAll(entityList);
        return this;
    }

    public RequestContainer callRaw(int expectedCode) {
        context.lastRequest = this;
        noContentDecoding = true;
        response = queryParms.isEmpty()
                ? authorized().get(url)
                : authorized().with().queryParams(queryParms).get(url);
        ValidatableResponse vr = context.logAllAPIResponses
                ? response.then().log().all(true)
                : response.then().log().ifValidationFails();
        vr.assertThat().statusCode(expectedCode);
        statusVerified = true;
        return this;
    }

}