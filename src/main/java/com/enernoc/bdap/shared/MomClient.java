package com.enernoc.bdap.shared;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.PropertyNamingStrategy;
import io.restassured.common.mapper.TypeRef;
import io.restassured.http.ContentType;
import io.restassured.specification.RequestSpecification;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.time.ZonedDateTime;
import java.util.*;

import static com.enernoc.bdap.shared.Context.*;
import static io.restassured.RestAssured.given;
import static org.junit.jupiter.api.Assertions.*;

public class MomClient {

    public static class GetClearedOffersRequest {
        public String id;
        public String by; // PROGRAM, PORTFOLIO, PRODUCT
        public String recordType; // PORTFOLIO, REGISTRATION
        public String clearedOfferType;
        public String startDttm;
        public String endDttm;
    }

    public static class ClearedOffer {
        public String id;
        public String record_type;
        public String product_id;
        public String program_id;
        public String registration_id;
        public String offer_start_dttm_utc;
        public String offer_end_dttm_utc;
        public String created_dttm;
        public String updated_dttm;
        public boolean notify_contacts;
        public boolean rollover_offer;
        public Cleared cleared;

        public static class Cleared {
            public String cleared_offer_type; // "A" for actual, "F" for forecast
            public String clearance_dttm;
            public Prices prices;
            public Quantities quantities;

            public static class Prices {
                public double capacity;
                public double energy;
            }

            public static class Quantities {
                public double capacity;
            }
        }
    }


    public static class GetRealtimeAvailabilityRequest {
        public String id;
        public String id_type;
        public String start_dttm_utc;
        public String end_dttm_utc;
        public String granularity;
        public Integer page;
        public Integer per_page;
    }


    public static class RealtimeAvailability {
        public String start_time;
        public String end_time;
        public Double value;
    }

    public record MomResponseMeta(Integer per_page, Integer total_pages, Integer page) {}

    public record MomBaseResponse (int code, String message, ArrayList<ClearedOffer> data, MomResponseMeta meta) {}

    public record MomBaseResponseRealtimeAvailability (int code, String message, ArrayList<RealtimeAvailability> data, MomResponseMeta meta) {}

    private static final ObjectMapper JSON = new ObjectMapper().setPropertyNamingStrategy(PropertyNamingStrategy.SNAKE_CASE);
    private static final Logger LOG = LoggerFactory.getLogger("MomClient");
    private final Context context = Context.getContext();

    private RequestSpecification authorized() {

        var spec = given();
        //spec.relaxedHTTPSValidation();

        // Include enoc_session if enabled

        assertFalse(Context.enocSession.isBlank(), "No user session! Maybe you forgot the stepdef 'Given I log in as a settlement API admin/user'");
        spec = spec.header("enoc_session", Context.enocSession);
        // Always include trace id
        var traceid = UUID.randomUUID();
        spec = spec.header("x-enelx-trace-id", traceid);
        if (!context.logAllAPIRequests) {
            LOG.info("x-enelx-trace-id: " + traceid);
        }

        // Add appropriate log level
        spec = context.logAllAPIRequests ? spec.log().all(true) : spec.log().method().log().uri();

        return spec;
    }


    public SortedMap<Long, ClearedOffer> getMomClearedOffers(GetClearedOffersRequest params) {

        var allOffers = new TreeMap<Long, ClearedOffer>();

        MomBaseResponse responseObj = authorized()
                .with().queryParams(JSON.convertValue(params, new TypeReference<>() {}))
                .get(momUrl + "/offers/cleared")
                .then().assertThat().statusCode(200)
                .contentType(ContentType.JSON).extract().as(new TypeRef<>() {});
        var errors = new ArrayList<String>();


        // Fix for NullPointerException: check if data is null before iterating
        if (responseObj.data != null) {
            responseObj.data.forEach(offer -> {
                var key = ZonedDateTime.parse(offer.offer_end_dttm_utc).toEpochSecond();
                if (allOffers.containsKey(key) /*&& (allOffers.get(key).cleared.quantities.capacity != offer.cleared.quantities.capacity) */) {
                    errors.add(String.format("Duplicate offers at %s have different capacities! ", offer.offer_end_dttm_utc));
                }
                allOffers.put(key, offer);
            });
        } else {
            LOG.warn("MOM API returned null data for cleared offers request.");
        }


        assertTrue(errors.isEmpty(), String.join("\n", errors));
        int dataSize = responseObj.data != null ? responseObj.data.size() : 0;
        LOG.info(String.format("Total number of cleared offers returned for %s: %d  Total unique timestamps: %d", params.id, dataSize, allOffers.size()));
        return allOffers;
    }


    public SortedMap<Long, RealtimeAvailability> getMomRealtimeAvailability(GetRealtimeAvailabilityRequest params) {

        var allRAs = new TreeMap<Long, RealtimeAvailability>();
        var errors = new ArrayList<String>();

        while (true) {
            MomBaseResponseRealtimeAvailability responseObj = authorized()
                    .with().queryParams(JSON.convertValue(params, new TypeReference<>() {
                    }))
                    .get(momUrl + "/realtime-availability").then()
                    .contentType(ContentType.JSON).extract().as(new TypeRef<>() {
                    });
            if (responseObj.code != 200) {
                fail(String.format("MOM: error %d %s", responseObj.code, responseObj.message));
                //return allRAs;  // will be empty
            }
            //assertEquals(1, responseObj.meta.total_pages, String.format("MOM /realtime-availability call indicates there are %d pages!", responseObj.meta.total_pages));

            responseObj.data.forEach(offer -> {
                var key = ZonedDateTime.parse(offer.end_time).toEpochSecond();
                if (allRAs.containsKey(key)) {
                    errors.add(String.format("Duplicate availability at %s ! ", offer.end_time));
                }
                allRAs.put(key, offer);
            });
            if (responseObj.meta.page == responseObj.meta.total_pages) {
                break;
            }
            params.page++;
        }
        assertTrue(errors.isEmpty(), String.join("\n", errors));
        LOG.info(String.format("MOM: total number of RAs returned for %s: %d", params.id, allRAs.size()));
        return allRAs;
    }




}
