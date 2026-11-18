package com.enernoc.bdap.model;

import com.enernoc.bdap.shared.MomClient;

import java.time.*;
import java.util.*;

public class ECOcontainer {
    public int month;
    public int year;
    public ZoneId timezone;
    public ZonedDateTime applyMonth;
    public int granSeconds;
    public int numExpectedIntervals;
    public String settlementId;
    public List<ECOobject> ecoList = new ArrayList<>();
    public boolean useActualReceivedPrice;

    public enum PRICE_TYPES {POOL_PRICE, DAILY_DISCOUNT_PRICE, MARKET_PRICE, ACTUAL_RECEIVED_PRICE};

    public static class ECOobject {
        public String settlementItemId;
        public String masterSettlementItemId;
        public String regId;
        public String regSetId;
        public String portfolioId;
        public String opportunity;
        public boolean isFinalized = false;
        public boolean isDeleted = false;
        public boolean needsManualFix = false;
        public boolean missingFinancialPoints = false;
        public int numExpectedIntervals = 0;
        public final SortedMap<Long, SettlementItemInterval> expectedIntervals =  new TreeMap<>();
        public List<FinancialPoint> poolPointList = new ArrayList<>();
        public List<FinancialPoint> discountPointList = new ArrayList<>();
        public List<FinancialPoint> marketPointList = new ArrayList<>();
        public final SortedMap<Long, Double> poolPrices =  new TreeMap<>();
        public final SortedMap<Long, Double> discountPrices =  new TreeMap<>();
        public final SortedMap<Long, Double> marketPrices =  new TreeMap<>();
        public final SortedMap<Long, Double> actualReceivedPrices =  new TreeMap<>();
        public List<FinancialPoint> actualReceivedPointList = new ArrayList<>();
        public final SortedMap<Long, MomClient.ClearedOffer> clearedOffers = new TreeMap<>();
        public final SortedMap<Long, MomClient.RealtimeAvailability> realtimeAvailabilityMap = new TreeMap<>();
        public final HashMap<String, intervalSummary> intervalSummaries = new HashMap<>();
        public Optional<Double> expectedREVOpt = Optional.empty();
        public Optional<Double> expectedCOGSOpt = Optional.empty();
        public Optional<EcoTransactionRow> REVOpt = Optional.empty();
        public Optional<EcoTransactionRow> COGSOpt = Optional.empty();
        public boolean useActualReceivedPrice = false;  // default: estimated, use market_price


        public boolean isValidForEcoCalc() {
            return !(this.needsManualFix || this.isDeleted || this.missingFinancialPoints);
        }

        public boolean isValidForMomAvailability() {
            return !(this.isDeleted || this.regId == null);
        }
    }

    public static class intervalSummary {
        public Long count;
        public Double REV;
        public Double COGS;
    }
}
