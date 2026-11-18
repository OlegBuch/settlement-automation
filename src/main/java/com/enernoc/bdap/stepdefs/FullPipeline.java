package com.enernoc.bdap.stepdefs;

import com.enernoc.bdap.model.*;
import com.enernoc.bdap.shared.*;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.cucumber.datatable.DataTable;
import io.cucumber.java.en.And;
import io.cucumber.java.en.Given;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.time.*;
import java.util.*;
import java.util.stream.Collectors;

import static com.enernoc.bdap.model.EntityType.*;
import static com.enernoc.bdap.shared.Context.*;
import static com.enernoc.bdap.model.ECOcontainer.*;

import static com.enernoc.bdap.shared.Context.PROGRAM.FCAS;
import static org.junit.jupiter.api.Assertions.*;

public class FullPipeline {

    private static final Logger LOG = LoggerFactory.getLogger("FullPipeline");
    private final Context context = Context.getContext();
    private static final ObjectMapper JSON = new ObjectMapper();
    private Optional<ECOcontainer> parmsOpt = Optional.empty();
    private final PostgresClient metaClient = new PostgresClient(metadataSecretValues);
    private final PostgresClient settClient = new PostgresClient(settlementSecretValues);
    private Optional<ZoneId> timezoneOpt = Optional.empty();
    private final ZoneId UTC = ZoneId.of("UTC");

    private final EPSClient epsClient = new EPSClient(stmCreateSecretValues);

    public static class ArmedPeriod {
        public ZonedDateTime start_utc;
        public ZonedDateTime end_utc;

        public void log (Logger LOG) {
            LOG.info("  start_utc: {}, end_utc: {}", Utility.normalizeZonedDateTime(this.start_utc), Utility.normalizeZonedDateTime(this.end_utc));
        }
    }


    @Given("I set the settlement time zone to {string}")
    public void iSetSettTimeZone(String zoneStr) {
        timezoneOpt = Optional.of(ZoneId.of(zoneStr));
    }


    @Given("I set up an AESO E2E test with the following parameters:")
    public void iSetUpAESOTest(DataTable data) {

        var parms = new ECOcontainer();
        try {
            var parmMap = data.asMap(String.class, String.class);
            parms.month = Month.valueOf(parmMap.get("month").toUpperCase()).getValue();
            parms.year = Integer.parseInt(parmMap.get("year"));
            parms.timezone = timezoneOpt.orElseThrow(() -> new RuntimeException("You need the stepdef 'Given I set the settlement timezone to ...'"));
            parms.settlementId = parmMap.get("settlement id");
            parms.applyMonth = ZonedDateTime.of(parms.year, parms.month, 1, 0, 0, 0, 0, parms.timezone);
            var nextMonth = parms.applyMonth.plusMonths(1);
            parms.numExpectedIntervals = (int) (nextMonth.toEpochSecond() - parms.applyMonth.toEpochSecond()) / 3600;
            var eco = new ECOcontainer.ECOobject(); {
                eco.regId = parmMap.get("registration id");
                eco.settlementItemId = parmMap.get("settlement item id");
                eco.opportunity = parmMap.get("opportunity");
            }
            parms.ecoList.add(eco);
        } catch (Exception e) {
            fail(e.getMessage());
        }
        parmsOpt = Optional.of(parms);
    }


    @Given("I get the financial points for the settlement")
    public void iGetFinPointsForSettlement() throws Throwable {
        var parms = parmsOpt.orElseThrow(() -> new Exception("No test parameters supplied!"));
        assertFalse(parms.ecoList.isEmpty(), "No ECO objects defined!");

        parms.ecoList.stream()
                .filter(eco -> eco.regId != null)
                .forEach(eco -> {
                    var item = context.savedSettlementItems.get(eco.settlementItemId);
                    var apiParms = new HashMap<String, Object>();
                    {
                        apiParms.put("level_type", "registration");
                        apiParms.put("level_id", eco.regId);
                        apiParms.put("start_dttm_utc", Utility.normalizeDateTime(item.get("start_dttm_utc").toString()));
                        apiParms.put("end_dttm_utc", Utility.normalizeDateTime(item.get("end_dttm_utc").toString()));
                    }

                    var request = RequestContainer.build()
                            .getEntities(FINANCIAL_POINT)
                            .addQueryParms(apiParms);

                    Optional<APIResponses.GetFinancialPointResult> resultOpt = Optional.empty();
                    try {
                        resultOpt = Optional.of(
                                request.call(200).getResponseEntity(APIResponses.GetFinancialPointResult.class));
                    } catch (AssertionError error) {
                        eco.missingFinancialPoints = true;
                        LOG.info(String.format("Failed to retrieve financial points for the registration %s", eco.regId));
                    }

                    resultOpt.ifPresent(result -> {
                        result.data().forEach(finPoint -> {
                            // DEBUG: log what financial points we actually have
                            LOG.info("FINPOINT reg={} id={} type={} start={} end={}",
                                    eco.regId,
                                    finPoint.financial_point_id,
                                    finPoint.financial_point_type,
                                    finPoint.start_dttm_utc,
                                    finPoint.end_dttm_utc);
                            assertTrue(Utility.testStringNotNullOrBlank(finPoint.start_dttm_utc),
                                    "Financial point is lacking start time!");
                            assertTrue(Utility.testStringNotNullOrBlank(finPoint.end_dttm_utc),
                                    "Financial point is lacking end time!");

                            var priceType = PRICE_TYPES.valueOf(finPoint.financial_point_type.toUpperCase());
                            switch (priceType) {
                                case POOL_PRICE ->
                                        eco.poolPointList.add(finPoint);
                                case DAILY_DISCOUNT_PRICE ->
                                        eco.discountPointList.add(finPoint);
                                case MARKET_PRICE ->
                                        eco.marketPointList.add(finPoint);
                                case ACTUAL_RECEIVED_PRICE ->
                                        eco.actualReceivedPointList.add(finPoint);
                                default ->
                                        fail("Context program not set! You need the stepdef 'Given I set the Energy Markets program to <...>'");
                            }
                        });

                        switch (context.program) {
                            case FCAS -> {
                                // For FCAS we currently expect one MARKET_PRICE and one ACTUAL_RECEIVED_PRICE per registration
                                assertEquals(1, eco.marketPointList.size(),
                                        "Currently, automation only supports exactly one MARKET_PRICE point per registration!");
                                assertEquals(1, eco.actualReceivedPointList.size(),
                                        "Currently, automation only supports exactly one ACTUAL_RECEIVED_PRICE point per registration!");
                                LOG.info(String.format(
                                        "Settlement %s has MARKET_PRICE point id %s and ACTUAL_RECEIVED_PRICE point id %s",
                                        eco.regId,
                                        eco.marketPointList.getFirst().financial_point_id,
                                        eco.actualReceivedPointList.getFirst().financial_point_id));
                            }
                            case AESO -> {
                                assertEquals(1, eco.poolPointList.size(),
                                        "Currently, automation only supports exactly one pool_price point per registration!");
                                assertEquals(1, eco.discountPointList.size(),
                                        "Currently, automation only supports exactly one discount_price point per registration!");
                                LOG.info(String.format(
                                        "Settlement %s has pool_price id %s,  discount_price id %s",
                                        eco.regId,
                                        eco.poolPointList.getFirst().financial_point_id,
                                        eco.discountPointList.getFirst().financial_point_id));
                            }
                            default -> fail();
                        }
                    });
                });
    }



    @When("I get cleared offers from MOM")
    public void iGetClearedOffers() throws Throwable {

        var parms = parmsOpt.orElseThrow(() -> new Exception("No test parameters supplied!"));
        assertFalse(parms.ecoList.isEmpty(), "No ECO objects defined!");
        var start = ZonedDateTime.of(parms.year, parms.month, 1, 0, 0, 0, 0, parms.timezone);
        var end = start.plusMonths(1);
        MomClient client = new MomClient();

        parms.ecoList.stream()
                .filter(ECOobject::isValidForEcoCalc)
                .forEach(eco -> {
            eco.clearedOffers.clear();
            var request = new MomClient.GetClearedOffersRequest();
            request.startDttm = Utility.normalizeZonedDateTime(start);
            request.endDttm = Utility.normalizeZonedDateTime(end);
            request.clearedOfferType = "ACTUAL";

            if (eco.regId != null) {
                // Existing logic for Registrations
                request.recordType = "REGISTRATION";
                request.by = "registration";
                request.id = eco.regId;
            } else if (eco.portfolioId != null) {
                // NEW LOGIC for Portfolios
                request.recordType = "PORTFOLIO";
                request.by = "portfolio";
                request.id = eco.portfolioId;
            }

            var offers = client.getMomClearedOffers(request);
            eco.clearedOffers.putAll(offers);
//            { // debugging
//                var offerList = offers.values().stream().toList();
//                int limit = Math.min(offerList.size(), 72);
//                for (int i = 0; i < limit; i++) {
//                    var offer = offerList.get(i);
//                    var localDate = ZonedDateTime.parse(offer.offer_start_dttm_utc).withZoneSameInstant(AESOzone);
//                    LOG.info(String.format("%s %s %f", offer.offer_start_dttm_utc, Utility.epochToStringFull(localDate.toEpochSecond(), AESOzone), offer.cleared.quantities.capacity));
//                }
//            }
            if (eco.clearedOffers.isEmpty()) {
                LOG.info(String.format("No cleared offers returned for registration %s", eco.regId));
            } else {
                LOG.info(String.format("Cleared offers for registration %s: %d from %s to %s. Missing offers: %d", eco.regId, offers.size(),
                        Utility.epochToStringFull(offers.firstKey(), parms.timezone),
                        Utility.epochToStringFull(offers.lastKey(), parms.timezone), parms.numExpectedIntervals - offers.size()));
            }
        });

    }


    @Given("I get the {word} prices")
    public void iGetPoolOrDiscountPriceFromIds(String priceTypeStr)  throws Throwable {

        var parms = parmsOpt.orElseThrow(() -> new Exception("No test parameters supplied!"));
        SortedMap<Long, Double> priceList;
        var priceType = PRICE_TYPES.valueOf(priceTypeStr.toUpperCase());
        for (var eco : parms.ecoList) {
            if (!eco.isValidForEcoCalc()) {
                continue; // no point in getting the prices if ECO isn't going to calculate payments
            }
            if (eco.regId == null) {
                continue; // This object must be a portfolio. Only registrations have prices.
            }
            FinancialPoint finPoint = switch (priceType) {
                case POOL_PRICE -> {
                    priceList = eco.poolPrices;
                    assertEquals(1, eco.poolPointList.size(), "Currently, automation only supports exactly one pool point per registration!");
                    yield eco.poolPointList.getFirst();
                }
                case DAILY_DISCOUNT_PRICE -> {
                    priceList = eco.discountPrices;
                    assertEquals(1, eco.discountPointList.size(), "Currently, automation only supports exactly one discount point per registration!");
                    yield eco.discountPointList.getFirst();
                }
                case MARKET_PRICE -> {
                    priceList = eco.marketPrices;
                    assertEquals(1, eco.marketPointList.size(), "Currently, automation only supports exactly one market price point per registration!");
                    yield eco.marketPointList.getFirst();
                }
                case ACTUAL_RECEIVED_PRICE -> {
                    priceList = eco.actualReceivedPrices;
                    assertEquals(1, eco.actualReceivedPointList.size(),
                            "Currently, automation only supports exactly one actual received price point per registration!");
                    yield eco.actualReceivedPointList.getFirst();
                }
                default -> throw new Exception("Invalid price type!"); // compiler complains if we use fail()
            };
            priceList.clear();

            // First, get the time range that the financial point is valid
            var finPointStartDttm = ZonedDateTime.parse(finPoint.start_dttm_utc).withZoneSameInstant(parms.timezone);
            var finPointEndDttm = ZonedDateTime.parse(finPoint.end_dttm_utc).withZoneSameInstant(parms.timezone);
            var idsStart = ZonedDateTime.of(parms.year, parms.month, 1, 0, 0, 0, 0, parms.timezone);
            var idsEnd = idsStart.plusMonths(1);
            boolean pricesApply = (finPointStartDttm.isBefore(idsEnd) && finPointEndDttm.isAfter(idsStart));
            if (!pricesApply) {
                // no prices apply, return with empty price list
                return;
            }
            if (finPointStartDttm.isAfter(idsStart)) {
                idsStart = finPointStartDttm;
            }
            if (finPointEndDttm.isBefore(idsEnd)) {
                idsEnd = finPointEndDttm;
            }

            // Next, get the prices from IDS
            LOG.info(String.format("Getting prices from %s to %s", idsStart, idsEnd));
            var secretMap = new HashMap<String, String>();
            {
                String idsHost = System.getenv("IDS_DB_REPLICA_HOST");
                assertNotNull(idsHost, "Set env var IDS_DB_REPLICA_HOST (IDS replica DB host)");
                secretMap.put("DB_MASTER_HOST", idsHost);
                secretMap.put("DB_PORT", "5432");
                secretMap.put("DB_DATABASE", "ids");
                secretMap.put("DB_ADMIN_USER", "ids_read");
                secretMap.put("DB_ADMIN_PASSWORD", idsSecretValues.get("timeseriesPwd"));
            }
            var postgres = new PostgresClient(secretMap);
            priceList.putAll(postgres.getPrices(finPoint.financial_point_id, Utility.normalizeZonedDateTime(idsStart), Utility.normalizeZonedDateTime(idsEnd)));
            assertFalse(priceList.isEmpty(), String.format("No prices found for %s", finPoint.financial_point_id));

            LOG.info(String.format("%s prices: %d from %s to %s", priceType, priceList.size(),
                    Utility.epochToStringFull(priceList.firstKey(), parms.timezone),
                    Utility.epochToStringFull(priceList.lastKey(), parms.timezone)));
        }
    }

    HashMap<String, ECOobject> savedEcoObjects = new HashMap<>();


    @Given("I save the expected ECO objects for later use")
    public void iSaveExpectedEcoObjects() throws Throwable {
        var parms = parmsOpt.orElseThrow(() -> new Exception("No test parameters supplied!"));
        assertFalse(parms.ecoList.isEmpty(), "No ECO objects defined!");
        // Copy ecoList into savedEcoObjects, using settlementItemId as the key
        parms.ecoList.forEach(eco -> {
            savedEcoObjects.put(eco.settlementItemId, eco);
        });
        LOG.info("ECO objects saved for later use");
    }


    @Given("I load the expected ECO payments from the saved objects")
    public void iReloadExpectedEcoObjects() throws Throwable {
        var parms = parmsOpt.orElseThrow(() -> new Exception("No test parameters supplied!"));
        assertFalse(parms.ecoList.isEmpty(), "No ECO objects defined!");
        parms.ecoList.forEach(eco -> {
            assertTrue(savedEcoObjects.containsKey(eco.settlementItemId), String.format("Something's wrong! No saved ECO object for '%s'", eco.settlementItemId));
            var savedEco = savedEcoObjects.get(eco.settlementItemId);
            eco.expectedCOGSOpt = savedEco.expectedCOGSOpt;
            eco.expectedREVOpt = savedEco.expectedREVOpt;
            eco.clearedOffers.clear();
            eco.clearedOffers.putAll(savedEco.clearedOffers);
            eco.expectedIntervals.clear();
            eco.expectedIntervals.putAll(savedEco.expectedIntervals);
            eco.numExpectedIntervals = savedEco.numExpectedIntervals;
        });
    }


    @Given("I calculate the expected monthly ECO payments for the settlement")
    public void iCalcMonthEcoPayment() throws Throwable {
       switch (context.program) {
           case AESO -> calcAESOMonthlyECOPayments();
           case FCAS -> calcFCASMonthlyECOPayments();
           default -> fail(String.format("Unsupported program %s!", context.program.name()));
       }
    }


    private void calcAESOMonthlyECOPayments() throws Throwable {
        var parms = parmsOpt.orElseThrow(() -> new Exception("No test parameters supplied!"));
        assertFalse(parms.ecoList.isEmpty(), "No ECO objects defined!");

        // ECO sets transaction values to 0.0 for registrations which are not valid for calculation or do not have offers
        parms.ecoList.stream()
                .filter(eco -> !eco.isValidForEcoCalc() || eco.clearedOffers.isEmpty())
                .forEach(eco -> {
                    eco.expectedCOGSOpt = Optional.of(0.0);
                    eco.expectedREVOpt = Optional.of(0.0);
                    LOG.info(String.format("ECO will not calculate item %s for reg %s.  Expected REV: 0.0  Expected COGS: 0.0  %s", eco.settlementItemId, eco.regId, eco.isDeleted ? "DELETED" : ""));
                });

        // Process registrations which are valid for calculation and have at least one offer
        parms.ecoList.stream()
                .filter(ECOobject::isValidForEcoCalc)
                .filter(eco -> !eco.clearedOffers.isEmpty())
                .forEach(this::generateCalcsAESO);
    }


    private void generateCalcsAESO(ECOobject eco) {
        assertFalse(eco.poolPrices.isEmpty(), "No pool prices!");
        assertFalse(eco.discountPrices.isEmpty(), "No discount prices!");
        assertFalse(eco.clearedOffers.isEmpty(), "No cleared offers!");

        var item = context.savedSettlementItems.get(eco.settlementItemId);
        long itemStartEpoch = ZonedDateTime
                .parse(item.get("start_dttm_utc").toString().replace(" ", "T"))
                .toEpochSecond();
        long itemEndEpoch = ZonedDateTime
                .parse(item.get("end_dttm_utc").toString().replace(" ", "T"))
                .toEpochSecond();

        double revenue = 0.0;
        int i = 0;
        int numNetZeroes = 0, numPriceZeroes = 0, numOfferZeroes = 0;
        eco.numExpectedIntervals = (int) (itemEndEpoch - itemStartEpoch) / 3600;  // AESO is an hourly program

        for (var offer : eco.clearedOffers.entrySet()) {
            var epoch = offer.getKey();
            if (epoch <= itemStartEpoch || epoch > itemEndEpoch) {
                continue;  // this interval is not included in the item's range
            }

            // Get the corresponding interval row (SII) if we have it
            SettlementItemInterval sii = eco.expectedIntervals.get(epoch);

            double intervalRev;

            // 1) payment_value_override wins if present
            if (sii != null && sii.payment_value_override != null && !sii.payment_value_override.isBlank()) {
                try {
                    intervalRev = Double.parseDouble(sii.payment_value_override);
                } catch (NumberFormatException e) {
                    // If override is invalid, fall back to 0.0 for this interval
                    intervalRev = 0.0;
                }
            } else {
                // 2) Normal calculated revenue = max(0, pool + discount) * capacity

                // if a price isn't found, then the net is zero
                double net = 0.0;
                if (eco.poolPrices.containsKey(epoch) && eco.discountPrices.containsKey(epoch)) {
                    // Official formula is: revenue = Math.max(0.0, (pool - discount)) * capacity
                    // But note that discount prices in IDS are negative
                    net = Math.max(0.0, (eco.poolPrices.get(epoch) + eco.discountPrices.get(epoch)));
                    if (net == 0.0) {
                        numNetZeroes++;
                    }
                } else {
                    numPriceZeroes++;
                    continue;
                }

                var capacity = offer.getValue().cleared.quantities.capacity;
                if (capacity == 0.0) {
                    numOfferZeroes++;
                }

                intervalRev = net * capacity;

//            if (i < 72) { // debugging
//                LOG.info(String.format("%s %s Pool: %f  Disc: %f  Rev: %f  Net: %f  Offer: %f",
//                        Utility.epochToString(epoch), Utility.epochToStringFull(epoch, AESOzone),
//                        eco.poolPrices.get(epoch), eco.discountPrices.get(epoch),
//                        intervalRev, net, capacity));
//                i++;
//            }
            }

            revenue += intervalRev;

            // If we have an expectedIntervals row, write back the per-interval values for later DB comparison
            if (sii != null) {
                sii.payment_value = String.format("%.6f", intervalRev);
                sii.revenue_value = String.format("%.6f", intervalRev);
            }
        }

        var postgres = getEcoClient();
        var split = postgres.getEcoCustomerSplit(eco.opportunity);
        var cogs = revenue * split;
        eco.expectedCOGSOpt = Optional.of(cogs);
        eco.expectedREVOpt = Optional.of(revenue);

        LOG.info(String.format(
                "Registration item: %s  reg: %s  Opportunity: %s  Split: %f  REV: %f  COGS: %f  Price zeroes: %d  Net zeroes: %d  Offer zeroes: %d",
                eco.settlementItemId, eco.regId, eco.opportunity, split, revenue, cogs,
                numPriceZeroes, numNetZeroes, numOfferZeroes));
    }


    private void calcFCASMonthlyECOPayments() throws Throwable {
        var parms = parmsOpt.orElseThrow(() -> new Exception("No test parameters supplied!"));
        assertFalse(parms.ecoList.isEmpty(), "No ECO objects defined!");

        // 1) ECO rows are 0 when reg is not valid or no availability
        parms.ecoList.stream()
                .filter(eco -> eco.regId != null)  // registrations only
                .filter(ecoReg -> !ecoReg.isValidForEcoCalc() || ecoReg.expectedIntervals.isEmpty())
                .forEach(ecoReg -> {
                    ecoReg.expectedCOGSOpt = Optional.of(0.0);
                    ecoReg.expectedREVOpt = Optional.of(0.0);
                    LOG.info(String.format(
                            "ECO will not calculate item %s for reg %s. Expected REV: 0.0 Expected COGS: 0.0 %s",
                            ecoReg.settlementItemId,
                            ecoReg.regId,
                            ecoReg.isDeleted ? "DELETED" : ""));
                });

        // 2) Process registrations which are valid for calculation and have MOM availability
        parms.ecoList.stream()
                .filter(eco -> eco.regId != null)          // registrations only
                .filter(ECOobject::isValidForEcoCalc)
                .filter(ecoReg -> !ecoReg.expectedIntervals.isEmpty())
                .forEach(ecoReg -> {
                    // Find matching portfolio ECO by masterSettlementItemId
                    var ecoPortOpt = ecoReg.masterSettlementItemId == null
                            ? Optional.<ECOobject>empty()
                            : parms.ecoList.stream()
                            .filter(e -> e.portfolioId != null) // ensure it's a portfolio ECO
                            .filter(e -> e.settlementItemId.equals(ecoReg.masterSettlementItemId))
                            .findFirst();

                    assertTrue(ecoPortOpt.isPresent(),
                            String.format("Something's wrong! No master (portfolio) item found for reg item %s", ecoReg.settlementItemId));

                    ECOobject ecoPortfolio = ecoPortOpt.get();

                    try {
                        LOG.info("FCAS DEBUG: ecoPortfolio {} intervals={}",
                                ecoPortfolio.settlementItemId,
                                ecoPortfolio.expectedIntervals.size());

                        generateCalcsFCASReg(ecoReg, ecoPortfolio);
                    } catch (Exception e) {
                        throw new RuntimeException(e);
                    }
                });
    }


private void generateCalcsFCASReg(ECOobject ecoReg, ECOobject ecoPortfolio) throws Exception {
    var parms = parmsOpt.orElseThrow(() -> new Exception("No test parameters supplied!"));

    // Require at least one price source, based on mode
    if (parms.useActualReceivedPrice) {
        assertFalse(ecoReg.actualReceivedPrices.isEmpty(),
                "No actual received prices for final FCAS!");
    } else {
        assertFalse(ecoReg.marketPrices.isEmpty(),
                "No market prices for estimated FCAS!");
    }
    assertFalse(ecoReg.expectedIntervals.isEmpty(), "No registration expected intervals!");
    assertFalse(ecoPortfolio.expectedIntervals.isEmpty(), "No portfolio expected intervals!");

    var item = context.savedSettlementItems.get(ecoReg.settlementItemId);
    long itemStartEpoch = ZonedDateTime
            .parse(item.get("start_dttm_utc").toString().replace(" ", "T"))
            .toEpochSecond();
    long itemEndEpoch = ZonedDateTime
            .parse(item.get("end_dttm_utc").toString().replace(" ", "T"))
            .toEpochSecond();

    LOG.info("FCAS DEBUG: ecoPortfolio {} intervals={}",
            ecoPortfolio.settlementItemId,
            ecoPortfolio.expectedIntervals.size());

    // NOTE: revenueRaw = pre-split (this becomes REV).
    //       cogsTotal  = post-split / payable amount (this becomes COGS and payment_value).
    double revenueRaw = 0.0;
    double cogsTotal = 0.0;
    int numNetZeroes = 0;
    int numPriceZeroes = 0;
    int numExpectedIntervals = 0;
    int numChargedIntervals = 0;

    LOG.info("FCAS DEBUG: generateCalcsFCASReg for item {} reg {} range {} - {}",
            ecoReg.settlementItemId,
            ecoReg.regId,
            Utility.epochToString(itemStartEpoch),
            Utility.epochToString(itemEndEpoch));

    double split = getEcoClient().getEcoCustomerSplit(ecoReg.opportunity);

    for (var epoch : ecoReg.expectedIntervals.keySet()) {
        // Restrict to this settlement item's range
        if (epoch < itemStartEpoch || epoch >= itemEndEpoch) {
            continue; // outside this item's interval range
        }
        numExpectedIntervals++;

        var regRa = ecoReg.expectedIntervals.get(epoch);
        var portfolioRa = ecoPortfolio.expectedIntervals.get(epoch);

        // Sanity: portfolio should have the same epochs
        if (portfolioRa == null) {
            LOG.warn("FCAS DEBUG: No portfolio SII for epoch {} (reg item {})",
                    Utility.epochToString(epoch),
                    ecoReg.settlementItemId);
            numNetZeroes++;
            continue;
        }

        double intervalRevRaw;
        double intervalCogs;

        // 1) explicit payment_value_override wins -- FINAL mode only per doc
        //    (overrides are not applied during ESTIMATED calcs)
        if (parms.useActualReceivedPrice
                && regRa.payment_value_override != null
                && !regRa.payment_value_override.isBlank()) {
            double overrideValue;
            try {
                overrideValue = Double.parseDouble(regRa.payment_value_override);
            } catch (NumberFormatException e) {
                LOG.warn("FCAS DEBUG: Invalid payment_value_override '{}' at epoch {}, treating as 0",
                        regRa.payment_value_override,
                        Utility.epochToString(epoch));
                overrideValue = 0.0; // invalid override => 0 for this interval
            }

            // Override fully replaces the computed payment.
            // NOTE: doc does not explicitly define revenue_value behavior under override;
            // this assumes revenue_value mirrors the override too. Confirm with team if needed.
            intervalRevRaw = overrideValue;
            intervalCogs = overrideValue;

        } else {
            // 2) computed payment from availability, cleared offer, and price

            boolean hasRegOverride = parms.useActualReceivedPrice && regRa.realtime_availability_kw_override != null;
            boolean isEffectivelyArmed = hasRegOverride || (regRa.is_armed != null && regRa.is_armed);

            LOG.info(
                    "FCAS DEBUG eligibility epoch={} finalMode={} regArmed={} " +
                            "regBaseAvailability={} regOverride={} hasRegOverride={} isEffectivelyArmed={}",
                    ZonedDateTime.ofInstant(Instant.ofEpochSecond(epoch), UTC),
                    parms.useActualReceivedPrice,
                    regRa.is_armed,
                    regRa.realtime_availability_kw,
                    regRa.realtime_availability_kw_override,
                    hasRegOverride,
                    isEffectivelyArmed
            );

            if (!isEffectivelyArmed) {
                LOG.info("FCAS DEBUG SKIP not armed epoch {} (and no override present)",
                        ZonedDateTime.ofInstant(Instant.ofEpochSecond(epoch), UTC));
                numNetZeroes++;
                continue;
            }

            // Overrides only apply in FINAL mode; ESTIMATED always uses base availability.
            double regAvail = effectiveRealtimeAvailability(regRa, parms.useActualReceivedPrice);
            double portAvail = effectiveRealtimeAvailability(portfolioRa, parms.useActualReceivedPrice);

            if (regAvail == 0.0 && portAvail == 0.0) {
                numNetZeroes++;
                continue;
            }

            double priceKw5min;
            if (parms.useActualReceivedPrice) {
                // FINAL: actual received price in kW5min
                if (!ecoReg.actualReceivedPrices.containsKey(epoch)) {
                    LOG.info("FCAS DEBUG SKIP no actual received price epoch {}",
                            ZonedDateTime.ofInstant(Instant.ofEpochSecond(epoch), UTC));
                    numPriceZeroes++;
                    continue;
                }
                priceKw5min = ecoReg.actualReceivedPrices.get(epoch);
            } else {
                // ESTIMATED: market price in MWh, convert to kW5min
                // SII epoch is the interval start; IDS price uses interval end = start + granSeconds
                ZonedDateTime startUtc = ZonedDateTime.ofInstant(Instant.ofEpochSecond(epoch), UTC);
                ZonedDateTime startLocal = startUtc.withZoneSameInstant(parms.timezone); // e.g. Australia/Brisbane
                ZonedDateTime endLocal = startLocal.plusSeconds(parms.granSeconds); // 5-min end in local
                long idsEpoch = endLocal.toInstant().getEpochSecond(); // epoch key for IDS

                Double rawPrice = ecoReg.marketPrices.get(idsEpoch);
                if (rawPrice == null) {
                    LOG.info("FCAS DEBUG SKIP no market price for SII epoch {} (idsEpoch {})",
                            startUtc, endLocal);
                    numPriceZeroes++;
                    continue;
                }
                priceKw5min = rawPrice / 1000.0 / 12.0;
            }

            double ratio = 0.0;
            if (portAvail != 0.0) {
                ratio = regAvail / portAvail;
            }

            if (parms.useActualReceivedPrice) {
                // FINAL: REV is raw (pre-split); COGS/payment_value is post-split
                intervalRevRaw = ratio * priceKw5min;
                intervalCogs = intervalRevRaw * split;
            } else {
                // ESTIMATED formula: reg/port * portfolio offer * market_price;
                // split applied once at aggregate level below, so both are equal here.
                double portfolioOfferKw = portfolioRa.cleared_offer_kw != null
                        ? portfolioRa.cleared_offer_kw
                        : 0.0;

                LOG.info("FCAS DEBUG epoch {} armed={} regAvail={} portAvail={} portOfferKw={} regOfferKw={}",
                        ZonedDateTime.ofInstant(Instant.ofEpochSecond(epoch), UTC),
                        regRa.is_armed,
                        regAvail,
                        portAvail,
                        portfolioOfferKw,
                        regRa.cleared_offer_kw);

                if (portfolioOfferKw == 0.0) {
                    numNetZeroes++;
                    continue;
                }

                intervalRevRaw = priceKw5min * portfolioOfferKw * ratio;
                intervalCogs = intervalRevRaw; // split applied once later for ESTIMATED
            }
        }

        // Accumulate and write back to SII
        revenueRaw += intervalRevRaw;
        cogsTotal += intervalCogs;
        numChargedIntervals++;

        // revenue_value column = raw (pre-split); payment_value column = post-split (payable amount)
        regRa.revenue_value = String.format("%.6f", intervalRevRaw);
        regRa.payment_value = String.format("%.6f", intervalCogs);

        LOG.debug("FCAS DEBUG CHARGED epoch {} intervalRevRaw={} intervalCogs={}",
                ZonedDateTime.ofInstant(Instant.ofEpochSecond(epoch), UTC),
                intervalRevRaw,
                intervalCogs);
    }

    ecoReg.numExpectedIntervals = numExpectedIntervals;

    // COGS/REV aggregation
    double finalRev = revenueRaw;
    double finalCogs;

    if (parms.useActualReceivedPrice) {
        // FINAL: cogsTotal already has per-interval split applied
        finalCogs = cogsTotal;
    } else {
        // ESTIMATED: apply split once at aggregate level over raw revenue
        finalCogs = revenueRaw * split;
    }

    ecoReg.expectedCOGSOpt = Optional.of(finalCogs);
    ecoReg.expectedREVOpt = Optional.of(finalRev);

    LOG.info(String.format(
            "Registration item %s reg %s Opportunity %s Split %f REV %f COGS %f Price zeroes %d Net zeroes %d Charged intervals %d",
            ecoReg.settlementItemId,
            ecoReg.regId,
            ecoReg.opportunity,
            split,
            finalRev,
            finalCogs,
            numPriceZeroes,
            numNetZeroes,
            numChargedIntervals));
}


    /**
     * Returns the availability to use for ratio calculations.
     * Overrides (realtime_availability_kw_override) only take effect when useOverride is true
     * (i.e. FINAL mode / parms.useActualReceivedPrice). ESTIMATED mode always uses the base
     * realtime_availability_kw, per the FCAS spec.
     */
    private double effectiveRealtimeAvailability(SettlementItemInterval sii, boolean useOverride) {
        if (useOverride && sii.realtime_availability_kw_override != null) {
            return sii.realtime_availability_kw_override;
        }
        return sii.realtime_availability_kw != null ? sii.realtime_availability_kw : 0.0;
    }


    @Then("the ECO payments should (still )equal the expected payments")
    public void iCompareCalcPaymentsToEco() throws Throwable {
        var parms = parmsOpt.orElseThrow(() -> new Exception("No test parameters supplied!"));
        assertFalse(parms.ecoList.isEmpty(), "No ECO objects defined!");
        var postgres = getEcoClient();
        var errors = new ArrayList<String>();
        for (var eco : parms.ecoList) {
            if (eco.isDeleted) {
                LOG.info(String.format("Settlement item:  %s for registration %s DELETED, so we will not check it", eco.settlementItemId, eco.regId));
                continue;  // // ITAPPSIT-3558: Pipeline does not pass deleted items to ECO for re-calculation, so no point in validating any pre-existing ECO rows
            }
            if (FCAS.equals(context.program)) {
                if (eco.regId == null) {  // verify that no ECO rows were created for portfolio item
                    postgres.verifyNoEcoRowsForItem(eco);
                    LOG.info("Verified that no ECO rows were created for portfolio item {}", eco.settlementItemId);
                    continue;
                }
            }
            postgres.getEcoPayment(eco, parms.applyMonth.toLocalDate());
            var expectedREV = eco.expectedREVOpt.orElseThrow(() -> new Exception("No expected REV supplied!"));
            var expectedCOGS =  eco.expectedCOGSOpt.orElseThrow(() -> new Exception("No expected COGS supplied!"));
            var actualREV = eco.REVOpt.orElseThrow(() -> new Exception("No actual REV found!")).amount;
            var actualCOGS = eco.COGSOpt.orElseThrow(() -> new Exception("No actual COGS found!")).amount;
            if (!isEqualDollars(expectedREV, actualREV)) {
                errors.add(String.format("Item: %s  Reg: %s  Actual REV %.2f does not equal expected REV: %.2f", eco.settlementItemId, eco.regId, actualREV, expectedREV));
            } else {
                LOG.info(String.format("Item: %s  Reg: %s  Actual REV %.2f matches expected REV %.2f", eco.settlementItemId, eco.regId, actualREV, expectedREV));
            }
            if (!isEqualDollars(expectedCOGS, actualCOGS)) {
                errors.add(String.format("Item: %s  Reg: %s  Actual COGS %.2f does not equal expected COGS: %.2f", eco.settlementItemId, eco.regId, actualCOGS, expectedCOGS));
            } else {
                LOG.info(String.format("Item: %s  Reg: %s  Actual COGS %.2f matches expected COGS %.2f", eco.settlementItemId, eco.regId, actualCOGS, expectedCOGS));
            }
        }
        assertTrue(errors.isEmpty(), String.join("\n", errors));

    }


    @Given("I wait until {int} settlements have been processed by the pipeline")
    public void iGetLatestSettlementsFromPipeline(int numSettlementsExpected) throws Throwable {
        context.pipelineSettlementsProcessed.clear();
        var ids = new ArrayList<String>();
        // Wait up to 90 seconds for the job to complete
        for (int i = 0; i <= 18 && ids.size() < numSettlementsExpected; i++) {
            Thread.sleep(5000);
            ids.clear();
            ids.addAll(metaClient.getLatestSuccessfulPipelineHistorySettlementIds(testStartEpoch));
        }
        assertEquals(numSettlementsExpected, ids.size(), "Unexpected number of settlements processed!");
        ids.forEach(id -> {
            context.lastSettlementId = id;
            var request = RequestContainer.build().getLastEntity(SETTLEMENT).call();
            context.pipelineSettlementsProcessed.add(JSON.convertValue(request.getDataAsList().get(0), Settlement.class));
        });

    }


    @Given("I wait until {int} settlements have been skipped by the pipeline with the detail {string}")
    public void iGetLatestSkippedSettlementsFromPipeline(int numSettlementsExpected, String detail) throws Throwable {
        context.pipelineSettlementsSkipped.clear();
        var ids = new ArrayList<String>();
        // Wait up to 30 seconds for the job to complete
        for (int i = 0; i <= 6 && ids.size() < numSettlementsExpected; i++) {
            Thread.sleep(5000);
            ids.clear();
            ids.addAll(metaClient.getLatestSkippedPipelineHistorySettlementIds(testStartEpoch, detail));
        }
        assertEquals(numSettlementsExpected, ids.size(), "Unexpected number of settlements skipped!");
        ids.forEach(id -> {
            context.lastSettlementId = id;
            var request = RequestContainer.build().getLastEntity(SETTLEMENT).call();
            context.pipelineSettlementsSkipped.add(JSON.convertValue(request.getDataAsList().get(0), Settlement.class));
        });
    }


    @Then("I wait for the pipeline history row for the existing settlement with pipeline_step: {word} status: {word}")
    public void iWaitPSHExistingSettlement(String step, String status) throws Throwable {
        String id = context.savedSettlements.keySet().toArray(new String[1])[0];
        Optional<String> pipelineRunIdOpt = Optional.empty();
        for (int i = 1; i < 15; i++) {
            pipelineRunIdOpt = metaClient.getLatestPipelineHistoryForSettlementId(id, step, status, testStartEpoch);
            if (pipelineRunIdOpt.isPresent()) {
                break;
            }
            try {
                Thread.sleep(5000);
            } catch (Exception e) {
                fail(e.toString());
            }
        }
        assertTrue(pipelineRunIdOpt.isPresent(), String.format("Timeout waiting for pipeline history row. Settlement: %s  Step: %s  Status: %s", id, step, status));
        context.lastSettlementId = id;
        var request = RequestContainer.build().getLastEntity(SETTLEMENT).call();
        context.pipelineSettlementsProcessed.clear();
        context.pipelineSettlementsProcessed.add(JSON.convertValue(request.getDataAsList().getFirst(), Settlement.class));
        LOG.info(String.format("Pipeline history row found. Pipeline run id: %s", pipelineRunIdOpt.get()));
    }


    /**
     * Decides whether a settlement belongs to the requested calendar month.
     *
     * Settlements are created from the product rule using a FIXED UTC offset (e.g. PREVIOUS_1_FULL_MONTH
     * yields 2026-11-01T06:00:00Z - 2026-12-01T06:00:00Z, i.e. a constant UTC-6 boundary). But the configured
     * settlement timezone observes DST, so during MST (UTC-7) 2026-12-01T06:00:00Z is actually
     * 2026-11-30 23:00 local. A strict local-date equality would then fail to match December.
     *
     * To stay robust, we accept the settlement when its local start date is the first of the target month,
     * or when its local start date falls within a small tolerance window around the month boundary.
     */
    private boolean settlementMatchesMonth(Settlement settlement, ZonedDateTime applyMonth, ZoneId timezone) {
        if (settlement == null || settlement.start_dttm_utc == null || settlement.start_dttm_utc.isBlank()) {
            return false;
        }
        ZonedDateTime settlementStart;
        try {
            settlementStart = ZonedDateTime.parse(settlement.start_dttm_utc).withZoneSameInstant(timezone);
        } catch (Exception e) {
            LOG.warn("Could not parse settlement start_dttm_utc '{}' for settlement {}",
                    settlement.start_dttm_utc, settlement.settlement_id);
            return false;
        }

        // Exact match: local start is the 1st of the target month
        if (settlementStart.toLocalDate().isEqual(applyMonth.toLocalDate())) {
            return true;
        }

        // Tolerant match: allow a few hours of offset drift caused by the fixed-UTC product rule boundary
        // crossing a DST transition (e.g. 2026-12-01T06:00Z == 2026-11-30T23:00 MST).
        var monthStart = applyMonth.toLocalDate().atStartOfDay(timezone);
        var drift = Duration.between(monthStart, settlementStart).abs();
        if (drift.compareTo(Duration.ofHours(6)) <= 0) {
            LOG.info(String.format(
                    "Settlement %s start %s is %s from local month start %s; treating it as the %s %d settlement (DST offset drift)",
                    settlement.settlement_id, settlementStart, drift, monthStart,
                    applyMonth.getMonth(), applyMonth.getYear()));
            return true;
        }

        return false;
    }


    @Given("I set up an E2E test using the following parameters for the settlement(s) that was just {word}:")
    public void iSetUpE2ETestLastSettlement(String sugar, DataTable data) throws Throwable {

        assertFalse(context.expectedSettlementItems.isEmpty(), "Something's wrong! No expected items!");

        // Step 1: Create a new ECOcontainer object with the supplied scenario data
        var parms = new ECOcontainer();
        parmsOpt = Optional.of(parms);

        var parmMap = data.asMap(String.class, String.class);
        parms.month = Month.valueOf(parmMap.get("month").toUpperCase()).getValue();
        parms.year = Integer.parseInt(parmMap.get("year"));
        parms.timezone = timezoneOpt.orElseThrow(() -> new RuntimeException("You need the stepdef 'Given I set the settlement timezone to ...'"));
        parms.applyMonth = ZonedDateTime.of(parms.year, parms.month, 1, 0, 0, 0, 0, parms.timezone);
        parms.granSeconds = Integer.parseInt(parmMap.getOrDefault("granularity_seconds", "3600"));  // default to hour (AESO granularity)
        var nextMonth = parms.applyMonth.plusMonths(1);
        parms.numExpectedIntervals = (int) (nextMonth.toEpochSecond() - parms.applyMonth.toEpochSecond()) / parms.granSeconds;

        // Step 2: Get the settlement associated with the test month.
        var allPipelineSettlements = new ArrayList<Settlement>();
        {
            allPipelineSettlements.addAll(context.pipelineSettlementsProcessed);
            allPipelineSettlements.addAll(context.pipelineSettlementsSkipped);
            if (context.existingSettlement != null) {
                // if context.existingSettlement is not already in allPipelineSettlements, add it
                 if (allPipelineSettlements.stream().noneMatch(s -> s.settlement_id.equals(context.existingSettlement.settlement_id))) {
                     allPipelineSettlements.add(context.existingSettlement);
                 }
            }
            for (var sMap : context.savedSettlements.values()) {
                Settlement saved = JSON.convertValue(sMap, new TypeReference<>() {});
                // if saved settlement is not already in allPipelineSettlements, add it
                if (allPipelineSettlements.stream().noneMatch(s -> s.settlement_id.equals(saved.settlement_id))) {
                    allPipelineSettlements.add(saved);
                }
            }
        }
        var monthMatches = allPipelineSettlements.stream()
                .filter(s -> settlementMatchesMonth(s, parms.applyMonth, parms.timezone))
                .toList();
        assertEquals(1, monthMatches.size(), String.format(
                "Expected 1 settlement for %s %d (%s), got %d. Candidate settlements: %s",
                parms.applyMonth.getMonth(), parms.year, parms.applyMonth,
                monthMatches.size(),
                allPipelineSettlements.isEmpty()
                        ? "none"
                        : allPipelineSettlements.stream()
                        .map(s -> String.format("[%s start=%s local=%s]", s.settlement_id, s.start_dttm_utc,
                                ZonedDateTime.parse(s.start_dttm_utc).withZoneSameInstant(parms.timezone)))
                        .collect(Collectors.joining(", "))));
        parms.settlementId = monthMatches.get(0).settlement_id;
        context.lastSettlementId = parms.settlementId;
        if (!context.savedSettlements.containsKey(parms.settlementId)) {
            HashMap<String, Object> settMap = JSON.convertValue(monthMatches.get(0), new TypeReference<>() {});
            context.savedSettlements.put(parms.settlementId, settMap);
        }
        LOG.info(String.format("Found a settlement for the month: %s", parms.settlementId));

        // Step 3. Get the expected items associated with that settlement for later verification against the actual items retrieved.
        // Select by overlap with the settlement's own time window rather than by local calendar month. The product rule builds
        // the boundary from a FIXED UTC offset, so during MST the boundary lands on the previous day locally
        // (2026-12-01T06:00Z == 2026-11-30 23:00 MST), and a local-month filter would drop every December item.
        var matchedSettlement = monthMatches.get(0);
        var settlementStartUtc = ZonedDateTime.parse(matchedSettlement.start_dttm_utc).withZoneSameInstant(UTC);
        var settlementEndUtc = ZonedDateTime.parse(matchedSettlement.end_dttm_utc).withZoneSameInstant(UTC);
        var expectedItemsCheckoffList = new ArrayList<SettlementItem>();
        for (var item : context.expectedSettlementItems) {
            var itemStartUtc = ZonedDateTime.parse(item.start_dttm_utc).withZoneSameInstant(UTC);
            var itemEndUtc = ZonedDateTime.parse(item.end_dttm_utc).withZoneSameInstant(UTC);
            if (Utility.datesOverlap(itemStartUtc, itemEndUtc, settlementStartUtc, settlementEndUtc)) {
                expectedItemsCheckoffList.add(item);
            }
        }
        assertFalse(expectedItemsCheckoffList.isEmpty(), String.format(
                "Something's wrong! No expected items! Settlement %s covers %s - %s UTC (%s - %s local), "
                        + "but none of the %d expected item(s) overlap that window. Expected item starts: %s",
                matchedSettlement.settlement_id, settlementStartUtc, settlementEndUtc,
                settlementStartUtc.withZoneSameInstant(parms.timezone),
                settlementEndUtc.withZoneSameInstant(parms.timezone),
                context.expectedSettlementItems.size(),
                context.expectedSettlementItems.isEmpty()
                        ? "none"
                        : context.expectedSettlementItems.stream()
                        .map(i -> String.format("%s (%s)", i.start_dttm_utc, i.settlement_level))
                        .collect(Collectors.joining(", "))));
        int numExpectedItems = expectedItemsCheckoffList.size();
        LOG.info(String.format("Settlement %s covers %s - %s UTC; %d of %d expected item(s) fall in that window",
                matchedSettlement.settlement_id, settlementStartUtc, settlementEndUtc,
                numExpectedItems, context.expectedSettlementItems.size()));

        // Step 2: Get the list of actual settlement_items associated with that settlement and create corresponding ECO objects.
        // Note: there is some uncertainty about how to handle items which were previously calculated in ECO but subsequently deleted.
        // ITAPPSIT-3558 records the current behavior, but it may change in the future. Therefore, we go ahead and retrieve deleted items here,
        // and then deal with the implications in other stepdefs.
        context.savedSettlementItems.clear();
        var actualItems = settClient.getSettlementItemsForSettlementRows(parms.settlementId);
        actualItems.forEach(actual -> {
            context.savedSettlementItems.put(actual.get("settlement_item_id").toString(), actual);
            if ("PORTFOLIO".equals(actual.get("settlement_level"))) {
                var eco = new ECOcontainer.ECOobject();
                eco.settlementItemId = actual.get("settlement_item_id").toString();
                eco.opportunity = actual.get("opportunity") == null ? null : actual.get("opportunity").toString();
                eco.isFinalized = actual.get("settlement_item_status") != null && "FINALIZED".equalsIgnoreCase(actual.get("settlement_item_status").toString());
                eco.needsManualFix = actual.get("processing_status") != null && "MISSING_META".equalsIgnoreCase(actual.get("processing_status").toString());
                eco.isDeleted = actual.get("deleted") != null && Boolean.parseBoolean(actual.get("deleted").toString());
                eco.portfolioId = actual.get("atlas_settlement_level_id") == null ? null : actual.get("atlas_settlement_level_id").toString();
                var expectedOpt = expectedItemsCheckoffList.stream().filter(si -> si.atlas_settlement_level_id.equals(eco.portfolioId)).findAny();
                if (expectedOpt.isEmpty()) {
                    fail(String.format("Unexpected item %s found for portfolio %s", eco.settlementItemId, eco.portfolioId));
                }
                var expected = expectedOpt.get();
                expectedItemsCheckoffList.remove(expected);
                assertEquals(ZonedDateTime.parse(expected.start_dttm_utc).toEpochSecond(), ZonedDateTime.parse(actual.get("start_dttm_utc").toString().replace(" ", "T")).toEpochSecond(), String.format("actual start_dttm_utc %s is different from expected %s", actual.get("start_dttm_utc"), expected.start_dttm_utc));
                assertEquals(ZonedDateTime.parse(expected.end_dttm_utc).toEpochSecond(), ZonedDateTime.parse(actual.get("end_dttm_utc").toString().replace(" ", "T")).toEpochSecond(), String.format("actual end_dttm_utc %s is different from expected %s", actual.get("end_dttm_utc"), expected.end_dttm_utc));
                parms.ecoList.add(eco);
            } else {  // Item is for a registration
                var regId = actual.get("atlas_settlement_level_id").toString();
                // Note: there will be more than one settlement item for a registration if the reg history has a gap in the middle on the month
                boolean actualItemIsExpected = false;
                for (var item : context.expectedSettlementItems) {
                    if (item.atlas_settlement_level_id.equals(regId)
                            && Utility.areDatesEqual(item.start_dttm_utc, actual.get("start_dttm_utc").toString())
                            && Utility.areDatesEqual(item.end_dttm_utc, actual.get("end_dttm_utc").toString())) {
                        actualItemIsExpected = true;
                        expectedItemsCheckoffList.remove(item);
                        var eco = new ECOcontainer.ECOobject();
                        eco.settlementItemId = actual.get("settlement_item_id").toString();
                        eco.opportunity = actual.get("opportunity") == null ? null : actual.get("opportunity").toString();
                        eco.isFinalized = actual.get("settlement_item_status") != null && "FINALIZED".equalsIgnoreCase(actual.get("settlement_item_status").toString());
                        eco.needsManualFix = actual.get("processing_status") != null && "MISSING_META".equalsIgnoreCase(actual.get("processing_status").toString());
                        eco.isDeleted = actual.get("deleted") != null && Boolean.parseBoolean(actual.get("deleted").toString());
                        eco.regId = regId;
                        eco.regSetId = actual.get("registration_set_id") == null ? null : actual.get("registration_set_id").toString();
                        eco.masterSettlementItemId = actual.get("master_settlement_item_id") == null ? null : actual.get("master_settlement_item_id").toString();
                        if (item.master_settlement_item_id == null) {
                            assertNull(eco.masterSettlementItemId, String.format("Item %s for registration %s is unexpectedly linked to the master item %s", eco.settlementItemId, eco.regId, eco.masterSettlementItemId));
                        }
                        parms.ecoList.add(eco);
                    }
                }
                if (!actualItemIsExpected) {
                    fail(String.format("Unexpected item %s found for registration %s", actual.get("settlement_item_id").toString(), regId));
                }
            }
        });
        if (expectedItemsCheckoffList.isEmpty()) {
            LOG.info("All {} expected items found, and no unexpected items found", numExpectedItems);
        } else {
            fail("Not all expected items found");
        }

        // Link the registration items to their portfolio (if any)
        for (var eco : parms.ecoList) {
            if (eco.regId != null && eco.masterSettlementItemId != null) {  // this is a registration with a portfolio parent
                for (var cand : parms.ecoList) {
                    if (cand.settlementItemId.equals(eco.masterSettlementItemId)) {
                        eco.portfolioId = cand.portfolioId;
                        break;
                    }
                }
                assertNotNull(String.format("Something's wrong! No parent portfolio item found for registration %s", eco.regId));
            }
        }

        // Log the items
        for (var eco : parms.ecoList) {
            if (FCAS.equals(context.program) && eco.masterSettlementItemId == null) {
                LOG.info(String.format("Portfolio item: %s   portfolio: %s  %s", eco.settlementItemId, eco.portfolioId, eco.isDeleted ? "DELETED" : ""));
            } else {
                LOG.info(String.format("Registration item: %s   reg: %s  set: %s  port: %s  %s",
                        eco.settlementItemId, eco.regId, eco.regSetId, eco.portfolioId, eco.isDeleted ? "DELETED" : ""));
            }
        }
    }


    @Then("the settlement and items should have been updated by this scenario")
    public void settlementAndItemShouldHaveBeenCreated() throws Throwable {
        var parms = parmsOpt.orElseThrow(() -> new Exception("No test parameters supplied!"));
        assertFalse(parms.ecoList.isEmpty(), "No ECO objects defined!");
        var errors = new ArrayList<String>();
        {// verify that settlement was created
            context.lastSettlementId = parms.settlementId;
            var request = RequestContainer.build().getLastEntity(SETTLEMENT).call();
            var updated = request.getDataAsList().get(0).get("last_updated_dttm_utc").toString();
            var updatedEpoch = ZonedDateTime.parse(updated).toEpochSecond();
            LOG.info(String.format("Settlement %s last updated at %s", parms.settlementId, updated));
            if (updatedEpoch < testStartEpoch) {
                errors.add(String.format("Settlement %s was not updated by this scenario!", parms.settlementId));
            }
        }
        parms.ecoList.forEach(eco -> { // verify that items were not updated
            context.lastSettlementItemId = eco.settlementItemId;
            var request = RequestContainer.build().getLastEntity(SETTLEMENT_ITEM).addQueryParm("include_deleted", true).call();
            var updated = request.getDataAsList().get(0).get("last_updated_dttm_utc").toString();
            var updatedEpoch = ZonedDateTime.parse(updated).toEpochSecond();
            LOG.info(String.format("Settlement item %s last updated at %s", eco.settlementItemId, updated));
            if (updatedEpoch < testStartEpoch) {
                errors.add(String.format("Settlement item %s was not updated by this scenario!", eco.settlementItemId));
            }
        });
        assertTrue(errors.isEmpty(), String.join("\n", errors));
        LOG.info("Verified that settlement and items were updated by this scenario");
    }


    @Then("the settlement and items should not be updated")
    public void settlementAndItemShouldNotBeUpdated() throws Throwable {
        var parms = parmsOpt.orElseThrow(() -> new Exception("No test parameters supplied!"));
        assertFalse(parms.ecoList.isEmpty(), "No ECO objects defined!");
        var errors = new ArrayList<String>();
        {// verify that settlement was not updated
            context.lastSettlementId = parms.settlementId;
            var request = RequestContainer.build().getLastEntity(SETTLEMENT).call();
            var updated = request.getDataAsList().get(0).get("last_updated_dttm_utc").toString();
            var updatedEpoch = ZonedDateTime.parse(updated).toEpochSecond();
            LOG.info(String.format("Settlement %s last updated at %s", parms.settlementId, updated));
            if (updatedEpoch >= testStartEpoch) {
                errors.add(String.format("Settlement %s was updated by this scenario at %s", parms.settlementId, updated));
            }
        }
        parms.ecoList.forEach(eco -> { // verify that items were not updated
            context.lastSettlementItemId = eco.settlementItemId;
            var request = RequestContainer.build().getLastEntity(SETTLEMENT_ITEM).addQueryParm("include_deleted", true).call();
            var updated = request.getDataAsList().get(0).get("last_updated_dttm_utc").toString();
            var updatedEpoch = ZonedDateTime.parse(updated).toEpochSecond();
            LOG.info(String.format("Settlement item %s last updated at %s", eco.settlementItemId, updated));
            if (updatedEpoch >= testStartEpoch) {
                errors.add(String.format("Settlement item %s was updated by this scenario at %s", eco.settlementItemId, updated));
            }
        });
        assertTrue(errors.isEmpty(), String.join("\n", errors));
        LOG.info("Verified that settlement and items were not updated by this scenario");
    }


    @Then("all the settlement item intervals should be updated")
    public void itemIntervalsShouldBeUpdated() throws Throwable {
        var parms = parmsOpt.orElseThrow(() -> new Exception("No test parameters supplied!"));
        assertFalse(parms.ecoList.isEmpty(), "No ECO objects defined!");
        var errors = new ArrayList<String>();
        long grandTotal = 0;
        boolean anyItemShouldBeUpdated = false;

        for (var eco : parms.ecoList) {
            if (eco.isDeleted) {
                LOG.info(String.format("Settlement item:  %s for registration %s DELETED, so we will not check it", eco.settlementItemId, eco.regId));
                continue;  // // ITAPPSIT-3558: Pipeline does not pass deleted items to ECO for re-calculation, so no point in validating any pre-existing ECO rows
            }
            if (!eco.isValidForEcoCalc() || eco.clearedOffers.isEmpty()) {
                LOG.info(String.format("Settlement item '%s' not valid for ECO calcs  %s (no cleared offers or not valid), so its intervals are not expected to change",
                        eco.settlementItemId, eco.isDeleted ? "DELETED" : ""));
                continue;
            }
            anyItemShouldBeUpdated = true;
            settClient.countUpdatedSettlementItemIntervals(eco, testStartEpoch);
            long totalCount = eco.intervalSummaries.values().stream().mapToLong(summary -> summary.count).sum();
            grandTotal += totalCount;
            if (totalCount < eco.numExpectedIntervals) {
                errors.add(String.format("Unexpected number of intervals updated by this scenario for settlement item '%s'! Expected: %d  Actual: %d",
                        eco.settlementItemId, eco.numExpectedIntervals, totalCount));
            } else {
                LOG.info(String.format("Number of intervals for item %s updated by this scenario: %d, as expected", eco.settlementItemId, totalCount));
            }
        }

        assertTrue(errors.isEmpty(), String.join("\n", errors));
        // Only insist that something was updated if at least one item was actually eligible for ECO recalculation.
        // When every item has no cleared offers, ECO has nothing to write, so zero updated intervals is the correct outcome.
        if (anyItemShouldBeUpdated) {
            assertNotEquals(0, grandTotal, "Something's wrong! No updated intervals found!");
            LOG.info("Verified that all settlement item intervals were updated by this scenario");
        } else {
            LOG.info("No settlement items were eligible for ECO calculation (no cleared offers), so no interval updates were expected");
        }
    }


    @Then("none of the settlement item intervals should be updated")
    public void noItemIntervalsShouldBeUpdated() throws Throwable {
        var parms = parmsOpt.orElseThrow(() -> new Exception("No test parameters supplied!"));
        assertFalse(parms.ecoList.isEmpty(), "No ECO objects defined!");
        var errors = new ArrayList<String>();
        for (var eco : parms.ecoList) {
            if (eco.isDeleted) {
                LOG.info(String.format("Settlement item:  %s for registration %s DELETED, so we will not check it", eco.settlementItemId, eco.regId));
                continue;  // // ITAPPSIT-3558: Pipeline does not pass deleted items to ECO for re-calculation, so no point in validating any pre-existing ECO rows
            }
            settClient.countUpdatedSettlementItemIntervals(eco, testStartEpoch);
            long totalCount = eco.intervalSummaries.values().stream().mapToLong(summary -> summary.count).sum();
            if (totalCount != 0) {
                errors.add(String.format("Unexpected number of intervals updated by this scenario for settlement item '%s'! Expected: %d  Actual: %d",
                        eco.settlementItemId, eco.numExpectedIntervals, totalCount));
            } else {
                // May need to load up counts for following stepdefs
                settClient.countUpdatedSettlementItemIntervals(eco, 0L);
            }
            LOG.info(String.format("Number of intervals for item %s updated by this scenario: %d, as expected", eco.settlementItemId, totalCount));
        }
        assertTrue(errors.isEmpty(), String.join("\n", errors));
        LOG.info("Verified that no settlement item intervals were updated by this scenario");
    }


    @Then("only intervals for non-finalized undeleted settlement items should be updated")
    public void onlyNonFinalizedItemIntervalsShouldBeUpdated() throws Throwable {
        var parms = parmsOpt.orElseThrow(() -> new Exception("No test parameters supplied!"));
        assertFalse(parms.ecoList.isEmpty(), "No ECO objects defined!");
        var errors = new ArrayList<String>();
        for (var eco : parms.ecoList) {
            if (eco.isDeleted) {
                LOG.info(String.format("Settlement item:  %s for registration %s DELETED, so we will not check it", eco.settlementItemId, eco.regId));
                continue;  // // ITAPPSIT-3558: Pipeline does not pass deleted items to ECO for re-calculation, so no point in validating any pre-existing ECO rows
            }
            if (eco.REVOpt.get().amount == 0.0 && eco.COGSOpt.get().amount == 0.0) {
                continue;  // No ECO calculation was done
            }
            settClient.countUpdatedSettlementItemIntervals(eco, testStartEpoch);
            long totalCount = eco.intervalSummaries.values().stream().mapToLong(summary -> summary.count).sum();
            if (eco.isFinalized) {
                if (totalCount != 0) {  // ECO recalculates the intervals, but then the Settlement API does not allow ECO to save them, so none should be updated.
                    errors.add(String.format("Unexpected number of intervals updated for finalized settlement item '%s'! Expected: 0  Actual: %d",
                            eco.settlementItemId, totalCount));
                } else {
                    LOG.info(String.format("Item %s (isFinalized = %b, isDeleted = %b) actual intervals updated: %d, as expected",
                            eco.settlementItemId, eco.isFinalized, eco.isDeleted, totalCount));
                }
            } else {
                if (totalCount != eco.numExpectedIntervals) {
                    errors.add(String.format("Unexpected number of intervals updated for settlement item '%s'! Expected: %d  Actual: %d",
                            eco.settlementItemId, eco.numExpectedIntervals, totalCount));
                } else {
                    LOG.info(String.format("Item %s (isFinalized = %b, isDeleted = %b) actual intervals updated: %d, as expected",
                            eco.settlementItemId, eco.isFinalized, eco.isDeleted, totalCount));
                }
            }
        }
        assertTrue(errors.isEmpty(), String.join("\n", errors));
        LOG.info("Verified that settlement item intervals were updated as expected");
    }


    @And("the settlement interval stats should be correct")
    public void intervalSourceCountsShouldBeCorrect() throws Throwable {
        var parms = parmsOpt.orElseThrow(() -> new Exception("No test parameters supplied!"));
        assertFalse(parms.ecoList.isEmpty(), "No ECO objects defined!");
        var errors = new ArrayList<String>();
        for (var eco : parms.ecoList) {
            if (eco.isDeleted) {
                LOG.info(String.format("Settlement item:  %s for registration %s DELETED, so we will not check it", eco.settlementItemId, eco.regId));
                continue;  // // ITAPPSIT-3558: Pipeline does not pass deleted items to ECO for re-calculation, so no point in validating any pre-existing ECO rows
            }
            if (eco.intervalSummaries.isEmpty()) {
                if (!eco.isValidForEcoCalc() || eco.clearedOffers.isEmpty()) {
                    LOG.info(String.format("Settlement item '%s' not valid for ECO calcs  %s", eco.settlementItemId, eco.isDeleted ? "DELETED" : ""));
                } else {
                    errors.add(String.format("Settlement item '%s' does not have any intervals!", eco.settlementItemId));
                }
                continue;
            }
            var errorsTemp = new ArrayList<String>();
            var logMsg = String.format("Verified that settlement interval_sources, REV, and COGS are correct for settlement item %s.", eco.settlementItemId);

            { // Verify that expected number of OFFER intervals was returned
                long numExpectedOfferIntervals = eco.clearedOffers.size();
                long numOfferIntervals = eco.intervalSummaries.containsKey("OFFER") ? eco.intervalSummaries.get("OFFER").count : 0L;
                if (numOfferIntervals != numExpectedOfferIntervals) {
                    errorsTemp.add(String.format("Settlement item %s: Unexpected number of OFFER intervals returned. Expected: %d  Actual: %d",
                            eco.settlementItemId, numExpectedOfferIntervals, numOfferIntervals));
                } else {
                    logMsg += String.format(" OFFER: %d", numOfferIntervals);
                }
            }

            { // Verify that expected number of MISSING intervals was returned
                long numExpectedMissingIntervals = eco.numExpectedIntervals - eco.clearedOffers.size();
                long numMissingIntervals = eco.intervalSummaries.containsKey("MISSING") ? eco.intervalSummaries.get("MISSING").count : 0L;
                if (numMissingIntervals != numExpectedMissingIntervals) {
                    errorsTemp.add(String.format("Settlement item %s: Unexpected number of MISSING intervals returned. Expected: %d  Actual: %d",
                            eco.settlementItemId, numExpectedMissingIntervals, numMissingIntervals));
                } else {
                    logMsg += String.format(" MISSING: %d", numMissingIntervals);
                }
            }

            { // Verify that no unexpected interval_sources were returned
                eco.intervalSummaries.keySet().stream()
                        .filter(key -> !Arrays.asList("OFFER", "MISSING").contains(key))
                        .forEach(key -> errorsTemp.add(String.format("Settlement item %s: Unexpected interval_source returned. interval_source: '%s'  Count: %d",
                                eco.settlementItemId, key, eco.intervalSummaries.get(key).count)));
            }

            { // Verify that REV and COGS match the expected values
                var ecoRev = eco.expectedREVOpt.orElseThrow(() -> new Exception("eco.REVOpt is empty!"));
                var ecoCogs = eco.expectedCOGSOpt.orElseThrow(() -> new Exception("eco.COGSOpt is empty!"));
                var intervalRev = eco.intervalSummaries.values().stream().mapToDouble(summary -> summary.REV).sum();
                var intervalCogs = eco.intervalSummaries.values().stream().mapToDouble(summary -> summary.COGS).sum();
                if (!Utility.areDoublesEqualEnough(ecoRev, intervalRev)) {
                    errorsTemp.add(String.format("Interval REV %f does not match expected REV %f", intervalRev, ecoRev));
                }
                if (!Utility.areDoublesEqualEnough(ecoCogs, intervalCogs)) {
                    errorsTemp.add(String.format("Interval COGS %f does not match expected COGS %f", intervalCogs, ecoCogs));
                }
            }

            if (errorsTemp.isEmpty()) {
                LOG.info(logMsg);
            } else {
                errors.addAll(errorsTemp);
            }
        }
        assertTrue(errors.isEmpty(), String.join("\n", errors));
    }


    @And("the ECO transaction rows should be updated")
    public void ecoRowsShouldBeUpdated() throws Throwable {
        var parms = parmsOpt.orElseThrow(() -> new Exception("No test parameters supplied!"));
        assertFalse(parms.ecoList.isEmpty(), "No ECO objects defined!");
        var testDttm = Utility.epochToZonedDateTimeUTC(testStartEpoch);
        LOG.info(String.format("Scenario started at %s", Utility.normalizeZonedDateTime(testDttm)));
        var errors = new ArrayList<String>();
        for (var eco : parms.ecoList) {
            if (FCAS.equals(context.program) && eco.regId == null) {
                continue;   // No ECO rows are created for FCAS portfolio items
            }
            if (eco.isDeleted) {
                LOG.info(String.format("Item %s for registration %s was deleted, so we will not check it", eco.settlementItemId, eco.regId));
                continue; // ITAPPSIT-3558: Pipeline does not pass deleted items to ECO
            }
            checkEcoRowUpdatedAfterTestStart(eco.REVOpt, "REV", testDttm, errors);
            checkEcoRowUpdatedAfterTestStart(eco.COGSOpt, "COGS", testDttm, errors);
        }
        assertTrue(errors.isEmpty(), String.join("\n", errors));
        LOG.info("Verified that all relevant ECO transaction rows were updated by this scenario");
    }


    private void checkEcoRowUpdatedAfterTestStart(Optional<EcoTransactionRow> rowOpt, String rowType, ZonedDateTime testDttm, List<String> errors) throws Exception {
        var row = rowOpt.orElseThrow(() -> new Exception("No " + rowType + " row found!"));
        var updated = ZonedDateTime.parse(Utility.normalizeDateTime(row.updated));
        if (updated.isAfter(testDttm)) {
            LOG.info(String.format("%s row for %s was updated at %s, after the scenario start time as expected", rowType, row.settlementItemId, Utility.normalizeZonedDateTime(updated)));
        } else{
            errors.add(String.format("%s row for %s was updated at %s, BEFORE the scenario start time!", rowType, row.settlementItemId, Utility.normalizeZonedDateTime(updated)));
        }
    }


    private void checkEcoRowNotUpdatedAfterTestStart(Optional<EcoTransactionRow> rowOpt, String rowType, ZonedDateTime testDttm, List<String> errors) throws Exception {
        var row = rowOpt.orElseThrow(() -> new Exception("No " + rowType + " row in ECO object!"));
        var updated = ZonedDateTime.parse(Utility.normalizeDateTime(row.updated));
        if (updated.isAfter(testDttm)) {
            errors.add(String.format("%s row for %s was updated at %s, AFTER the scenario start time!", rowType, row.settlementItemId, Utility.normalizeZonedDateTime(updated)));
        } else{
            LOG.info(String.format("%s row for %s was last updated at %s, before the scenario start time as expected", rowType, row.settlementItemId, Utility.normalizeZonedDateTime(updated)));
        }
    }


    @And("the ECO transaction rows should not be updated")
    public void ecoRowsShouldNotBeUpdated() throws Throwable {
        var parms = parmsOpt.orElseThrow(() -> new Exception("No test parameters supplied!"));
        assertFalse(parms.ecoList.isEmpty(), "No ECO objects defined!");
        // We add one second to testStartEpoch because in the case where our code adds a placeholder ECO row,
        // the row updated date is set to testStartEpoch + 1 for verification by the stepdef "the ECO transaction rows should be updated"
        var testDttm = Utility.epochToZonedDateTimeUTC(testStartEpoch + 1);
        LOG.info(String.format("Scenario started at %s", Utility.normalizeZonedDateTime(testDttm)));
        var errors = new ArrayList<String>();
        for (var eco : parms.ecoList) {
            if (eco.isDeleted) {
                LOG.info(String.format("Settlement item:  %s for registration %s DELETED, so we will not check it", eco.settlementItemId, eco.regId));
                continue;  // // ITAPPSIT-3558: Pipeline does not pass deleted items to ECO for re-calculation, so no point in validating any pre-existing ECO rows
            }
            if (FCAS.equals(context.program) && eco.regId == null) {
                continue;   // No ECO rows are created for FCAS portfolio items
            }
            checkEcoRowNotUpdatedAfterTestStart(eco.REVOpt, "REV", testDttm, errors);
            checkEcoRowNotUpdatedAfterTestStart(eco.COGSOpt, "COGS", testDttm, errors);
        }
        assertTrue(errors.isEmpty(), String.join("\n", errors));
        LOG.info("Verified that no ECO transaction rows were updated by this scenario");
    }


    private PostgresClient getEcoClient() {
        var secretMap = new HashMap<String, String>();
        {
            secretMap.put("DB_MASTER_HOST", settlementSecretValues.get("ECO_HOST"));
            secretMap.put("DB_PORT", "5432");
            secretMap.put("DB_DATABASE", "eco");
            secretMap.put("DB_ADMIN_USER", settlementSecretValues.get("ECO_USER"));
            secretMap.put("DB_ADMIN_PASSWORD", settlementSecretValues.get("ECO_PASSWORD"));
        }
        return new PostgresClient(secretMap);
    }


    @When("I save one of the item ids with {int} expected intervals for later use")
    public void iSaveItemIdForLaterUse(int numExpectedIntervals) {
        context.lastSettlementItemId = savedEcoObjects.values().stream()
                .filter(eco -> eco.numExpectedIntervals == numExpectedIntervals)
                .map(eco -> eco.settlementItemId)
                .findFirst().orElseThrow(() -> new AssertionError(String.format("No eco object found with %d expected intervals!", numExpectedIntervals)));
        LOG.info(String.format("Item to be deleted: %s", context.lastSettlementItemId));
    }


    private void finalizeItem(ECOcontainer.ECOobject eco) {
        var params = new HashMap<String, Object>();
        params.put("settlement_item_id", eco.settlementItemId);
        params.put("settlement_item_status", "FINALIZED");
        params.put("change_comments", "Change to FINALIZE");
        RequestContainer.build()
                .submitEntity(HttpOp.PATCH, SETTLEMENT_ITEM, params)
                .call(200)
                .getResponseEntity(APIResponses.PatchResult.class);
        eco.isFinalized = true;
        LOG.info(String.format("Item %s finalized", eco.settlementItemId));
    }


    @When("I finalize all of the settlement items")
    public void iFinalizeAllItems() throws Throwable {
        var parms = parmsOpt.orElseThrow(() -> new Exception("No test parameters supplied!"));
        assertFalse(parms.ecoList.isEmpty(), "No ECO objects defined!");
        parms.ecoList.forEach(eco -> {
            if (eco.isDeleted) {
                LOG.info(String.format("Settlement item:  %s for registration %s DELETED, so we will not check it", eco.settlementItemId, eco.regId));
            } else {
                assertFalse(eco.isFinalized, String.format("Item %s already finalized", eco.settlementItemId));
                finalizeItem(eco);
            }
        });
    }


    @When("I finalize one of the settlement items")
    public void iPatchOneItem() throws Throwable {
        var parms = parmsOpt.orElseThrow(() -> new Exception("No test parameters supplied!"));
        // Choose the first item which has expected intervals and is not already finalized
        var candidateOpt = parms.ecoList.stream()
                .filter(eco -> !eco.isDeleted)
                .filter(eco -> !eco.isFinalized)
                .filter(eco -> eco.REVOpt.get().amount > 0.0).findFirst();
        assertTrue(candidateOpt.isPresent(), "No un-finalized item found!");
        finalizeItem(candidateOpt.get());
    }


    @When("I un-finalize any finalized settlement items")
    public void iUnfinalizeItems() throws Throwable {
        var parms = parmsOpt.orElseThrow(() -> new Exception("No test parameters supplied!"));
        assertFalse(parms.ecoList.isEmpty(), "No ECO objects defined!");
        parms.ecoList.stream().filter(eco -> eco.isFinalized).forEach(eco -> {
            var params = new HashMap<String, Object>();
            params.put("settlement_item_id", eco.settlementItemId);
            params.put("settlement_item_status", "PRELIMINARY");
            params.put("change_comments", "Change to PRELIMINARY");
            RequestContainer.build()
                    .submitEntity(HttpOp.PATCH, SETTLEMENT_ITEM, params)
                    .call(200)
                    .getResponseEntity(APIResponses.PatchResult.class);
            eco.isFinalized = false;
            LOG.info(String.format("Item %s un-finalized", eco.settlementItemId));
        });
    }


    @When("I un-finalize any finalized settlements")
    public void iUnfinalizeSettlements() throws Throwable {
        assertFalse(context.savedSettlements.isEmpty(), "No saved settlements!");
        for (var settlement : context.savedSettlements.values()) {
            if (settlement.get("settlement_status").toString().equals("FINALIZED")) {
                var params = new HashMap<String, Object>();
                var id = settlement.get("settlement_id").toString();
                params.put("settlement_id", id);
                params.put("settlement_status", "PRELIMINARY");
                params.put("change_comments", "Change to PRELIMINARY");
                RequestContainer.build()
                        .submitEntity(HttpOp.PATCH, SETTLEMENT, params)
                        .call(200)
                        .getResponseEntity(APIResponses.PostSettlementResult.class);
                LOG.info("Settlement {} un-finalized", id);
            }
        }
    }


    private boolean isEqualDollars(double a, double b) {
        var aRound = Math.round(a * 100.0);
        var bRound = Math.round(b * 100.0);
        return aRound == bRound;
    }


    int totalIntervalsPassed = 0, totalIntervalsFailed = 0, grandTotal = 0;
    long totalExpectedArmed = 0, totalActualArmed = 0;
    ZonedDateTime firstUpdatedOfAll, lastUpdatedOfAll;

    @Given("the {word} FCAS intervals should match the expected intervals for each settlement item")
    public void iCompareActualExpectedFCASIntervals(String adj) throws Throwable {

        var parms = parmsOpt.orElseThrow(() -> new Exception("No test parameters supplied!"));
        assertFalse(parms.ecoList.isEmpty(), "No ECO objects defined!");
        var errors = new ArrayList<String>();

        totalIntervalsPassed = 0;
        totalIntervalsFailed = 0;
        grandTotal = 0;
        firstUpdatedOfAll = ZonedDateTime.parse("9000-01-01T00:00:00Z");
        lastUpdatedOfAll = ZonedDateTime.ofInstant(Instant.ofEpochSecond(0), UTC);

        MomClient client = new MomClient();

        // Split the list of eco objects into registrations and portfolios
        var ecoRegistrations = new ArrayList<ECOobject>();
        var ecoPortfolios = new ArrayList<ECOobject>();
        for (var eco : parms.ecoList) {
            if (eco.regId == null) {
                ecoPortfolios.add(eco);
            } else {
                ecoRegistrations.add(eco);
            }
        }

        // Make sure portfolio mapping is consistent
        var ecoRegTemp = ecoRegistrations.stream().collect(Collectors.toMap(r -> r.regId, r -> r));
        for (var port : ecoPortfolios) {
            int numRegs = 0;
            for (var reg : ecoRegistrations) {
                if (port.portfolioId.equals(reg.portfolioId)) {
                    numRegs++;
                    ecoRegTemp.remove(reg.regId);
                }
            }
            LOG.info("Portfolio {} has {} registrations", port.portfolioId, numRegs);
        }
        for (var reg : ecoRegistrations) {
            if (reg.portfolioId == null) {
                LOG.info("Item {} for registration {} is not a child of a portfolio", reg.settlementItemId, reg.regId);
                ecoRegTemp.remove(reg.regId);
            }
        }
        assertTrue(ecoRegTemp.isEmpty(), "There are some registrations which are not in a known portfolio!");

        // Uncomment if you only want to validate a specific portfolio
        //var specificPortfolioId = "751cbc6b-b11e-44f7-93b9-b4a5fdf4f43f";
        //ecoRegistrations = ecoRegistrations.stream().filter(p -> specificPortfolioId.equals(p.portfolioId)).collect(Collectors.toCollection(ArrayList::new));
        //ecoPortfolios = ecoPortfolios.stream().filter(r -> specificPortfolioId.equals(r.portfolioId)).collect(Collectors.toCollection(ArrayList::new));

        // Generate expected intervals for registration items
        for (var eco : ecoRegistrations) {
            LOG.info(String.format("-------------------- Generating expected intervals for item: %s  reg: %s", eco.settlementItemId, eco.regId));
            var item = context.savedSettlementItems.get(eco.settlementItemId);
            long itemStartEpoch = ZonedDateTime.parse(item.get("start_dttm_utc").toString().replace(" ", "T")).toEpochSecond();
            long itemEndEpoch = ZonedDateTime.parse(item.get("end_dttm_utc").toString().replace(" ", "T")).toEpochSecond();

            // Step 1. Create the expected intervals, initialized to MISSING
            for (long epoch = itemStartEpoch + parms.granSeconds; epoch <= itemEndEpoch; epoch += parms.granSeconds) {
                var interval = new SettlementItemInterval();
                interval.interval_dttm_utc = ZonedDateTime.ofInstant(Instant.ofEpochSecond(epoch), UTC).toString();
                interval.is_armed = false;
                interval.realtime_availability_kw = null;
                interval.interval_source = "MISSING";
                eco.expectedIntervals.put(epoch, interval);
            }
            eco.numExpectedIntervals = eco.expectedIntervals.size();

            // Step 2. Flag the armed intervals
            var armedPeriods = getArmedPeriods(eco.regSetId, eco.regId);
            if (!armedPeriods.isEmpty()) {  // if empty, leave
                for (long epoch = itemStartEpoch + parms.granSeconds; epoch <= itemEndEpoch; epoch += parms.granSeconds) {
                    if (isEpochArmed(epoch, armedPeriods)) {
                        eco.expectedIntervals.get(epoch).is_armed = true;
                    }
                }
            }

            // Step 3. Get the MOM realtime availability
            eco.realtimeAvailabilityMap.clear();
            var request = new MomClient.GetRealtimeAvailabilityRequest();
            request.start_dttm_utc = Utility.normalizeZonedDateTime(ZonedDateTime.ofInstant(Instant.ofEpochSecond(itemStartEpoch), UTC));
            request.end_dttm_utc = Utility.normalizeZonedDateTime(ZonedDateTime.ofInstant(Instant.ofEpochSecond(itemEndEpoch), UTC));
            request.granularity = switch (parms.granSeconds) {
                case 300 -> "fivemin";
                case 3600 -> "hour";
                default -> fail("Unsupported granualarity");
            };
            request.id_type = "REGISTRATION";
            request.id = eco.regId;
            request.page = 1;
            request.per_page = 4000;
            var ras = client.getMomRealtimeAvailability(request);
            eco.realtimeAvailabilityMap.putAll(ras);
            if (eco.realtimeAvailabilityMap.isEmpty()) {
                LOG.info(String.format("No realtime availability returned for registration %s", eco.regId));
            } else {
                LOG.info(String.format("Realtime availability for registration %s: %d from %s to %s. Missing intervals: %d", eco.regId, ras.size(),
                        Utility.epochToStringFull(ras.firstKey(), parms.timezone),
                        Utility.epochToStringFull(ras.lastKey(), parms.timezone), eco.numExpectedIntervals - ras.size()));
            }
            for (long epoch = itemStartEpoch + parms.granSeconds; epoch <= itemEndEpoch; epoch += parms.granSeconds) {
                var interval = eco.expectedIntervals.get(epoch);
                if (ras.containsKey(epoch)) {
                    // MOM availability values are in MW
                    interval.realtime_availability_kw = ras.get(epoch).value * 1000.0;
                    interval.interval_source = "AVAILABILITY";
                } else {
                    // MOM API is currently filling out missing values with zeroes if you make a paged call, which the pipeline does.
                    // In order to test this, MomClient.getMomRealtimeAvailability() also makes a paged call.
                    // Therefore, right now this block of code should never be called.
                    fail("Whoa, the MOM availability API call behavior changed!");
                    interval.interval_source = "MISSING";
                    interval.realtime_availability_kw = null;
                    LOG.info(String.format("No MOM RA for %s", interval.interval_dttm_utc));
                }
            }

            // Step 4. Validate the actual intervals against the expected intervals
            var ecoErrors = new ArrayList<>(compareFCASIntervalsWrapper(eco, adj));
            if (!ecoErrors.isEmpty()) {
                LOG.info(String.join("\n", ecoErrors));
                errors.add(String.format("Item %s has errors, check log above", eco.settlementItemId));
            }
        }

        // Generate expected intervals for portfolio items
        for (var eco : ecoPortfolios) {
            assertNotNull(eco.portfolioId); // failsafe
            LOG.info(String.format("-------------------- Generating expected intervals for item: %s  portfolio: %s", eco.settlementItemId, eco.portfolioId));
            var item = context.savedSettlementItems.get(eco.settlementItemId);
            long itemStartEpoch = ZonedDateTime.parse(item.get("start_dttm_utc").toString().replace(" ", "T")).toEpochSecond();
            long itemEndEpoch = ZonedDateTime.parse(item.get("end_dttm_utc").toString().replace(" ", "T")).toEpochSecond();


            // Step 1. Find the registration items that should be aggregated for this portfolio
            var regItems = new ArrayList<>(ecoRegistrations.stream()
                    .filter(reg -> reg.portfolioId != null)
                    .filter( reg -> reg.portfolioId.equals(eco.portfolioId))
                    .toList());
            assertFalse(regItems.isEmpty(), String.format("Something's wrong! No registration items found for portfolio %s", eco.portfolioId));
            LOG.info("Portfolio {} has {} registration items", eco.portfolioId, regItems.size());

            /* Step 2. Aggregate the reg intervals according to ITAPPSIT-3765:
                - get all reg-level items related to this portfolio item
                - get settlement item intervals (SII) for each reg item
                - for each interval_dttm_utc, sum reg SII realtime availability kw where is_armed=true
                - is_armed=true if any reg was armed for that interval
                - interval_source = AVAILABILITY if all registration-level interval_source = AVAILABILITY, otherwise MISSING
                From chat with Nate:
                for a given interval timestamp and set of settlement items / registration histories, each item contributes the following amount to the portfolio aggregation for that timestamp:
                - 0 if the item interval does not exist for that timestamp
                - 0 if the item interval has is_armed=false or is_armed=null
                - 0 if the item interval has kw=0
                - item interval.realtime_availability_kw when is_armed=true
             */
            for (long epoch = itemStartEpoch + parms.granSeconds; epoch <= itemEndEpoch; epoch += parms.granSeconds) {
                var interval = new SettlementItemInterval();
                interval.interval_dttm_utc = ZonedDateTime.ofInstant(Instant.ofEpochSecond(epoch), UTC).toString();
                interval.is_armed = false;
                interval.realtime_availability_kw = 0.0;
                interval.interval_source = "AVAILABILITY";
                for (var reg : regItems) {
                    var regInterval = reg.expectedIntervals.get(epoch);
 // Uncomment to get details about a specific timestamp
//                    if (epoch == 1753971000L) {
//                        if (regInterval == null) {
//                            LOG.error("{} is null", reg.regId);
//                        } else {
//                            LOG.error("{}  {}  {}  {}", reg.regId, regInterval.interval_source, regInterval.is_armed, regInterval.realtime_availability_kw);
//                        }
//                    }
                    if (regInterval == null) {
                        continue;
                    }

                    // Per FCAS doc: override only applies for FINAL aggregation; ESTIMATED
                    // aggregation must ignore realtime_availability_kw_override entirely.
                    boolean hasOverride = parms.useActualReceivedPrice
                            && regInterval.realtime_availability_kw_override != null;
                    boolean isEffectivelyArmed = hasOverride || (regInterval.is_armed != null && regInterval.is_armed)  ;

//                    if (!"AVAILABILITY".equals(regInterval.interval_source)) {
//                        interval.interval_source = "MISSING";
//                        //break;
//                    } else if (regInterval.is_armed) {
//                        interval.is_armed = true;
//                        interval.realtime_availability_kw += regInterval.realtime_availability_kw;
//                    }
                    if (!"AVAILABILITY".equals(regInterval.interval_source) && !hasOverride) {
                        interval.interval_source = "MISSING";
                    } else if (isEffectivelyArmed) {
                        interval.is_armed = true;
                        if (hasOverride) {
                            interval.realtime_availability_kw += regInterval.realtime_availability_kw_override;
                        } else {
                            interval.realtime_availability_kw += regInterval.realtime_availability_kw;
                        }
                    }
                }

                // NEW: Populate cleared_offer_kw from the fetched offers
                if (eco.clearedOffers.containsKey(epoch)) {
                    interval.cleared_offer_kw = eco.clearedOffers.get(epoch).cleared.quantities.capacity;
                } else {
                    interval.cleared_offer_kw = 0.0;
                    // FIX: If there is no portfolio offer, the system cannot calculate the split,
                    // so the interval is correctly marked as MISSING in the DB.
                    interval.interval_source = "MISSING";
                }

                eco.expectedIntervals.put(epoch, interval);
            }
            eco.numExpectedIntervals = eco.expectedIntervals.size();

            // Step 4. Validate the actual intervals against the expected intervals
            var ecoErrors = new ArrayList<>(compareFCASIntervalsWrapper(eco, adj));
            if (!ecoErrors.isEmpty()) {
                LOG.info(String.join("\n", ecoErrors));
                errors.add(String.format("Item %s has errors, check log above", eco.settlementItemId));
            }
        }

        LOG.info(String.format("-------------------- Validation complete for all items.  Total intervals passed: %d  Total failed: %d  Expected armed: %d  Actual armed: %d  Earliest update: %s  Latest update: %s",
                totalIntervalsPassed, totalIntervalsFailed, totalExpectedArmed, totalExpectedArmed, firstUpdatedOfAll, lastUpdatedOfAll));
        assertNotEquals(0, grandTotal, "Something's wrong! No intervals retrieved!");
        assertTrue(errors.isEmpty(), String.join("\n", errors));
    }


    public List<String> compareFCASIntervalsWrapper(ECOobject eco, String adj) throws Throwable {
        var actuals = new TreeMap<>(settClient.getUpdatedFCASIntervals(eco.settlementItemId, adj.equals("latest") ? 0 : testStartEpoch));
        LOG.info(String.format("-------------------- Validating %d actual intervals for item: %s  registration: %s  portfolio: %s", actuals.size(), eco.settlementItemId, eco.regId, eco.portfolioId));
        grandTotal += actuals.size();
        var errors = new ArrayList<String>();
        if (actuals.size() != eco.expectedIntervals.size()) {
            errors.add(String.format("Unexpected number of intervals retrieved by this scenario for settlement item '%s'! Expected: %d  Actual: %d",
                    eco.settlementItemId, eco.expectedIntervals.size(), actuals.size()));
        } else {
            // Find the earliest and latest last_updated_dttm_utc in the actuals list
            var firstUpdated = actuals.values().stream().map(interval -> ZonedDateTime.parse(interval.last_updated_dttm_utc)).min(ZonedDateTime::compareTo).orElseThrow();
            var lastUpdated = actuals.values().stream().map(interval -> ZonedDateTime.parse(interval.last_updated_dttm_utc)).max(ZonedDateTime::compareTo).orElseThrow();
            LOG.info(String.format("Number of intervals for item %s retrieved by this scenario: %d, as expected. Earliest update: %s  Latest update: %s",
                    eco.settlementItemId, actuals.size(), firstUpdated, lastUpdated));
            if (firstUpdated.isBefore(firstUpdatedOfAll)) {
                firstUpdatedOfAll = firstUpdated;
            }
            if (lastUpdated.isAfter(lastUpdatedOfAll)) {
                lastUpdatedOfAll = lastUpdated;
            }
            errors.addAll(compareFCASIntervals(eco, actuals));
            // Uncomment the following line if you want to stop on the first reg with errors
            //assertTrue(errors.isEmpty(), String.join("\n", errors));
        }
        return errors;
    }


    public List<String> compareFCASIntervals(ECOobject eco, SortedMap<Long, SettlementItemInterval> actuals) throws Throwable {

        long numExpectedArmed = eco.expectedIntervals.values().stream().filter(ivl -> ivl.is_armed).count();
        long numActualArmed = actuals.values().stream().filter(ivl -> ivl.is_armed).count();

        double expectedArmedTotalKw = eco.expectedIntervals.values().stream().filter(ivl -> ivl.is_armed).mapToDouble(ivl -> ivl.realtime_availability_kw).sum();
        double actualArmedTotalKw = actuals.values().stream().filter(ivl -> ivl.is_armed).mapToDouble(ivl -> ivl.realtime_availability_kw).sum();

        LOG.info(String.format("Expected armed: %d  Actual armed: %d  Expected armed kW:  %f  Actual armed kW: %f",
                numExpectedArmed, numActualArmed, expectedArmedTotalKw, actualArmedTotalKw));

        var errors = new ArrayList<String>();
        int numPassed = 0, numFailed = 0;
        for (var epoch : eco.expectedIntervals.keySet()) {
            var expected = eco.expectedIntervals.get(epoch);
            if (!actuals.containsKey(epoch)) {
                errors.add(String.format("No actual interval found for: %s", expected.interval_dttm_utc));
                continue;
            }
            var actual = actuals.get(epoch);
            if (expected.is_armed != actual.is_armed || !Objects.equals(expected.interval_source, actual.interval_source) || !Objects.equals(expected.realtime_availability_kw, actual.realtime_availability_kw)) {
                numFailed++;
                if (errors.size() < 10) {
                    errors.add(String.format("Expected/Actual intervals not equal. Item: %s  dttm: %s (%d)  is_armed: %b/%b  interval_source: %s/%s  availability: %f/%f",
                            eco.settlementItemId, expected.interval_dttm_utc, ZonedDateTime.parse(expected.interval_dttm_utc).toEpochSecond(), expected.is_armed, actual.is_armed, expected.interval_source, actual.interval_source, expected.realtime_availability_kw, actual.realtime_availability_kw));
                } else if (errors.size() < 11) {
                    errors.add("....truncated....");
                }
            } else {
                numPassed++;
            }
        }
        assertEquals(actuals.size(), numPassed + numFailed, "Failsafe to ensure all actuals are verified has FAILED!");
        totalIntervalsPassed += numPassed;
        totalIntervalsFailed += numFailed;
        totalExpectedArmed += numExpectedArmed;
        totalActualArmed += numActualArmed;
        LOG.info(String.format("Intervals PASS: %d  FAIL: %d", numPassed, numFailed));
        return errors;
    }


    public boolean isEpochArmed(long epoch, ArrayList<ArmedPeriod> armedPeriods) {
        // <CONFLUENCE_URL>/pages/viewpage.action?pageId=844210121&spaceKey=XP&title=FCAS%2BArmed%2BStatus
        // settlement_item_intervals.is_armed=true if interval-ending datetime is > EPS armed period start and <= EPS armed period end
        var epochDttm = Utility.epochToZonedDateTimeUTC(epoch);
        return armedPeriods.stream()
                .anyMatch(period -> epochDttm.isAfter(period.start_utc) && !epochDttm.isAfter(period.end_utc));
    }


    public ArrayList<ArmedPeriod> getArmedPeriods(String regSetId, String regId) throws Throwable {

        // First attempt to get armed rows by registration set id, if supplied. If that fails, then try registration id.
        var workflowRows = new ArrayList<EventWorkflowRow>();
        if (regSetId != null) {
            LOG.info(String.format("Attempting to get EPS workflow rows for registration set %s ...", regSetId));
            workflowRows.addAll(epsClient.getEpsWorkflowRows("registration_set_id", regSetId));
        } else {
            LOG.info("Registration set is null, will not attempt to get EPS workflow rows by registration set");
        }
        if (workflowRows.isEmpty()) {
            LOG.info(String.format("Attempting to get EPS workflow rows for registration %s ...", regId));
            workflowRows.addAll(epsClient.getEpsWorkflowRows("registration_id", regId));
        }
        if (workflowRows.isEmpty()) {
            LOG.info(String.format("No EPS workflow rows found for set %s or reg: %s", regSetId, regId));
            return new ArrayList<>();
        }

        var armedPeriods = new ArrayList<ArmedPeriod>();
        var armedRows = new ArrayList<EventWorkflowRow>();
        var unarmedRows = new ArrayList<EventWorkflowRow>();

        for (var row : workflowRows) {
            Optional<ArmedPeriod> periodOpt = getArmedPeriod(row);
            periodOpt.ifPresentOrElse((period) -> {
                armedPeriods.add(period);
                armedRows.add(row);
            }, () -> unarmedRows.add(row));
        }

        if (armedPeriods.isEmpty()) {
            LOG.info("No armed periods for registration set");
        } else {
            LOG.info(String.format("Registration set has %d armed periods:", armedPeriods.size()));
            armedPeriods.forEach((p) -> p.log(LOG));
        }

//        if (armedRows.isEmpty()) {
//            LOG.info("No armed rows");
//        } else {
//            LOG.info("Armed rows details:");
//            armedRows.forEach((row) -> row.log(LOG));
//        }
//
//        if (unarmedRows.isEmpty()) {
//            LOG.info("No unarmed rows");
//        } else {
//            LOG.info("Unarmed rows details:");
//            unarmedRows.forEach((row) -> row.log(LOG));
//        }

        return armedPeriods;
    }


    Optional<ArmedPeriod> getArmedPeriod(EventWorkflowRow row) {
        ArmedPeriod period = null;

        /*
         * if workflow_status=CURTAIL_EXCEPTION_DETECTED, there is no armed period for this row (tried to arm and failed)
         */
        if ("CURTAIL_EXCEPTION_DETECTED".equals(row.workflow_status)) {
            return Optional.empty();
        }

        /*
         * if event_node_start_time and cancelled are both not null,
         * armed period is (LATER_OF(curtail_complete, curtail_exception_resolved), cancelled)
         * if curtail_complete and curtail_exception_resolved are both null, fall back to use event_node_start_time
         */
        if (row.event_node_start_time != null && row.cancelled != null) {
            period = new ArmedPeriod();
            period.start_utc = getEventRowStartTime(row);
            period.end_utc = row.cancelled;
            return Optional.of(period);
        }

        /*
         * else if event_node_start_time and event_node_end_time are both not null,
         * armed period is (LATER_OF(curtail_complete, curtail_exception_resolved), event_node_end_time)
         */
        if (row.event_node_start_time != null && row.event_node_end_time != null) {
            period = new ArmedPeriod();
            period.start_utc = getEventRowStartTime(row);
            period.end_utc = row.event_node_end_time;
            return Optional.of(period);
        }

        /*
         * else if event_node_start_time is not null and event_node_end_time is null and workflow_status=CURTAIL_COMPLETE,
         * armed period is (LATER_OF(curtail_complete, curtail_exception_resolved), +infinity)
         */
        if (row.event_node_start_time != null && "CURTAIL_COMPLETE".equals(row.workflow_status)) {
            period = new ArmedPeriod();
            period.start_utc = getEventRowStartTime(row);
            period.end_utc = ZonedDateTime.of(9999, 1, 1,0,0,0,0, UTC);
            return Optional.of(period);
        }

        return Optional.empty();
    }


    ZonedDateTime getEventRowStartTime(EventWorkflowRow row) {
        /*
         * Define ARMED_START_TIME for an event_node_workflow rule:
         * if curtail_complete != null and curtail_exception_resolved != null, LATER_OF(curtail_complete, curtail_exception_resolved)
         * else if curtail_complete != null and curtail_exception_resolved == null, curtail_complete
         * else if curtail_complete == null and curtail_exception_resolved != null, curtail_exception_resolved
         * else event_node_start_time
         */
        var start = row.event_node_start_time;
        if (row.curtail_complete != null && row.curtail_complete.isAfter(start)) {
            start = row.curtail_complete;
        }
        if (row.curtail_exception_resolved != null && row.curtail_exception_resolved.isAfter(start)) {
            start = row.curtail_exception_resolved;
        }
        return start;
    }

    @When("I retrieve all of the pipeline history rows for the last run")
    public void iGetPipelineHistoryForPreviousFullQuarter() throws Throwable {
        String createdAfter = Utility.epochToString(Context.testStartEpoch);
        String condition = String.format(
                "created_dttm_utc > TIMESTAMP WITH TIME ZONE '%s'",
                createdAfter
        );

        List<HashMap<String, Object>> rows =
                metaClient.selectRecordsTable("pipeline_state_history", condition, "created_dttm_utc");

        assertFalse(rows.isEmpty(), "No pipeline history rows found since testStartEpoch!");

        context.pipelineHistoryForLastRun.clear();
        context.pipelineHistoryForLastRun.addAll(rows);
    }

    @Then("the pipeline history mode should be {string}")
    public void pipelineModeShouldBe(String expectedMode) throws Throwable {
        List<HashMap<String, Object>> rows = context.pipelineHistoryForLastRun;
        assertFalse(rows.isEmpty(), "No pipeline history rows stored in context!");

        boolean anyMatch = rows.stream()
                .anyMatch(r -> {
                    Object modeObj = r.get("mode");
                    return modeObj != null && expectedMode.equalsIgnoreCase(modeObj.toString());
                });

        if (!anyMatch) {
            var distinctModes = rows.stream()
                    .map(r -> {
                        Object modeObj = r.get("mode");
                        return modeObj == null ? "NULL" : modeObj.toString();
                    })
                    .distinct()
                    .toList();

            fail("No pipeline history rows have mode " + expectedMode
                    + ". Actual modes: " + distinctModes);
        }
    }

    @Then("the settlement items should all be {word}")
    public void itemsShouldAllHaveStatus(String expectedStatus) throws Throwable {
        var parms = parmsOpt.orElseThrow(() -> new Exception("No test parameters supplied!"));
        assertFalse(parms.ecoList.isEmpty(), "No ECO objects defined!");

        for (var eco : parms.ecoList) {
            if (eco.isDeleted) {
                LOG.info("Settlement item {} for registration {} DELETED, skipping status check",
                        eco.settlementItemId, eco.regId);
                continue;
            }

            context.lastSettlementItemId = eco.settlementItemId;
            var request = RequestContainer.build()
                    .getLastEntity(SETTLEMENT_ITEM)
                    .addQueryParm("includedeleted", true)
                    .call();

            var status = request.getDataAsList()
                    .get(0)
                    .get("settlement_item_status")
                    .toString();

            assertEquals(expectedStatus.toUpperCase(), status.toUpperCase(),
                    String.format("Item %s expected %s but was %s",
                            eco.settlementItemId, expectedStatus, status));
        }
    }

    @Given("I set up a recalc-only E2E test for {word} {int}")
    public void iSetUpRecalcOnlyE2E(String monthName, int year) throws Throwable {

        var parms = new ECOcontainer();
        parmsOpt = Optional.of(parms);

        // Month / year / timezone
        parms.month = Month.valueOf(monthName.toUpperCase()).getValue();
        parms.year  = year;
        parms.timezone = timezoneOpt.orElseThrow(
                () -> new RuntimeException("You need the stepdef 'Given I set the settlement timezone to ...'")
        );
        parms.applyMonth = ZonedDateTime.of(parms.year, parms.month, 1, 0, 0, 0, 0, parms.timezone);
        parms.granSeconds = 300;

        // FINAL mode only: always use actual_received_price
        parms.useActualReceivedPrice = true;

        var nextMonth = parms.applyMonth.plusMonths(1);
        parms.numExpectedIntervals =
                (int) ((nextMonth.toEpochSecond() - parms.applyMonth.toEpochSecond()) / parms.granSeconds);

        // Find the single settlement for this month
        var allPipelineSettlements = new ArrayList<Settlement>();
        allPipelineSettlements.addAll(context.pipelineSettlementsProcessed);
        allPipelineSettlements.addAll(context.pipelineSettlementsSkipped);

        if (context.existingSettlement != null) {
            if (allPipelineSettlements.stream()
                    .noneMatch(s -> s.settlement_id.equals(context.existingSettlement.settlement_id))) {
                allPipelineSettlements.add(context.existingSettlement);
            }
        }

        for (var sMap : context.savedSettlements.values()) {
            Settlement saved = JSON.convertValue(sMap, new TypeReference<>() {});
            if (allPipelineSettlements.stream()
                    .noneMatch(s -> s.settlement_id.equals(saved.settlement_id))) {
                allPipelineSettlements.add(saved);
            }
        }

        var monthMatches = allPipelineSettlements.stream()
                .filter(s -> settlementMatchesMonth(s, parms.applyMonth, parms.timezone))
                .toList();

        assertEquals(1, monthMatches.size(),
                String.format("Expected 1 settlement for the month, got %d", monthMatches.size()));

        parms.settlementId = monthMatches.get(0).settlement_id;
        context.lastSettlementId = parms.settlementId;

        if (!context.savedSettlements.containsKey(parms.settlementId)) {
            HashMap<String, Object> settMap =
                    JSON.convertValue(monthMatches.get(0), new TypeReference<>() {});
            context.savedSettlements.put(parms.settlementId, settMap);
        }

        LOG.info(String.format("Found a settlement for the month: %s", parms.settlementId));

        // Load actual settlement items and build ECO objects
        context.savedSettlementItems.clear();
        parms.ecoList.clear();

        var actualItems = settClient.getSettlementItemsForSettlementRows(parms.settlementId);
        actualItems.forEach(actual -> {
            context.savedSettlementItems.put(actual.get("settlement_item_id").toString(), actual);

            var eco = new ECOcontainer.ECOobject();
            eco.settlementItemId = actual.get("settlement_item_id").toString();
            eco.opportunity      = actual.get("opportunity") == null
                    ? null : actual.get("opportunity").toString();
            eco.isFinalized      = actual.get("settlement_item_status") != null
                    && "FINALIZED".equalsIgnoreCase(actual.get("settlement_item_status").toString());
            eco.needsManualFix   = actual.get("processing_status") != null
                    && "MISSING_META".equalsIgnoreCase(actual.get("processing_status").toString());
            eco.isDeleted        = actual.get("deleted") != null
                    && Boolean.parseBoolean(actual.get("deleted").toString());

            if ("PORTFOLIO".equals(actual.get("settlement_level"))) {
                eco.portfolioId = actual.get("atlas_settlement_level_id") == null
                        ? null : actual.get("atlas_settlement_level_id").toString();
            } else {
                var regId = actual.get("atlas_settlement_level_id").toString();
                eco.regId        = regId;
                eco.regSetId     = actual.get("registration_set_id") == null
                        ? null : actual.get("registration_set_id").toString();
                eco.masterSettlementItemId =
                        actual.get("master_settlement_item_id") == null
                                ? null : actual.get("master_settlement_item_id").toString();
            }

            parms.ecoList.add(eco);
        });

        // Link registration ECOs to their portfolio parent
        for (var eco : parms.ecoList) {
            if (eco.regId != null && eco.masterSettlementItemId != null) {
                for (var cand : parms.ecoList) {
                    if (cand.settlementItemId.equals(eco.masterSettlementItemId)) {
                        eco.portfolioId = cand.portfolioId;
                        break;
                    }
                }
                assertNotNull(eco.portfolioId,
                        String.format("No parent portfolio item found for registration %s", eco.regId));
            }
        }

        // Load expected intervals for registration items and their portfolios
        for (var eco : parms.ecoList) {
            if (eco.regId == null) {
                continue;
            }

            loadExpectedIntervalsForEcoObject(eco);

            if (eco.masterSettlementItemId != null) {
                var portOpt = parms.ecoList.stream()
                        .filter(e -> e.settlementItemId.equals(eco.masterSettlementItemId))
                        .findFirst();
                if (portOpt.isPresent()) {
                    loadExpectedIntervalsForEcoObject(portOpt.get());
                } else {
                    LOG.warn("No portfolio ECOobject found for master item {}", eco.masterSettlementItemId);
                }
            }
        }

        // Logging
        for (var eco : parms.ecoList) {
            if (FCAS.equals(context.program) && eco.masterSettlementItemId == null) {
                LOG.info(String.format("Portfolio item: %s   portfolio: %s  %s",
                        eco.settlementItemId, eco.portfolioId, eco.isDeleted ? "DELETED" : ""));
            } else {
                LOG.info(String.format("Registration item: %s   reg: %s  set: %s  port: %s  %s",
                        eco.settlementItemId, eco.regId, eco.regSetId, eco.portfolioId,
                        eco.isDeleted ? "DELETED" : ""));
            }
        }
    }


    private void loadExpectedIntervalsForEcoObject(ECOcontainer.ECOobject ecoReg) throws Exception {
        ecoReg.expectedIntervals.clear();

        List<SettlementItemInterval> intervals =
                settClient.getIntervalsForSettlementItem(ecoReg.settlementItemId);

        for (SettlementItemInterval dbInterval : intervals) {
            String ts = dbInterval.interval_dttm_utc;  // already normalized like "YYYY-MM-DDTHH:MM:SSZ"
            long epoch = ZonedDateTime.parse(ts).toEpochSecond();
            ecoReg.expectedIntervals.put(epoch, dbInterval);
        }

        LOG.info("Loaded {} expected intervals for item {}", ecoReg.expectedIntervals.size(), ecoReg.settlementItemId);
    }

//    @And("I choose a registration item with MOM availability and a portfolio parent")
//    public void iChooseRegWithMomAndPortfolio() throws Throwable {
//        var parms = parmsOpt.orElseThrow(() -> new Exception("No test parameters supplied!"));
//        assertFalse(parms.ecoList.isEmpty(), "No ECO objects defined!");
//
//        // 1) Pick the first registration with a master item and at least one cleared offer
//        var ecoOpt = parms.ecoList.stream()
//                .filter(eco -> eco.regId != null)
//                .filter(eco -> eco.masterSettlementItemId != null)
//                .filter(eco -> !eco.clearedOffers.isEmpty())
//                .findFirst();
//
//        assertTrue(ecoOpt.isPresent(), "No registration with MOM availability and portfolio parent found!");
//        var ecoReg = ecoOpt.get();
//
//        // 2) Load REGISTRATION intervals (including overrides) from DB into this ECOobject
//        context.lastSettlementItemId = ecoReg.settlementItemId;
//        loadExpectedIntervalsForEcoObject(ecoReg);
//
//        // 3) Build a matching PORTFOLIO ECOobject for the same settlement
//        // masterSettlementItemId on the reg ECO is the portfolio item's settlement_item_id
//        String portfolioItemId = ecoReg.masterSettlementItemId;
//
//        ECOobject ecoPortfolio = new ECOobject();
//        ecoPortfolio.settlementItemId = portfolioItemId;
//        ecoPortfolio.portfolioId = ecoReg.portfolioId;   // if you track portfolioId on the reg ECO
//
//        // Load portfolio SII from DB into ecoPortfolio.expectedIntervals
//        loadExpectedIntervalsForEcoObject(ecoPortfolio);
//
//        // 4) Add portfolio ECO to parms.ecoList so FCAS calc can find it
//        parms.ecoList.add(ecoPortfolio);
//
//        LOG.info(String.format(
//                "Chosen registration for override test: item=%s reg=%s masterItem=%s offers=%d; " +
//                        "portfolio item=%s intervals=%d",
//                ecoReg.settlementItemId,
//                ecoReg.regId,
//                ecoReg.masterSettlementItemId,
//                ecoReg.clearedOffers.size(),
//                ecoPortfolio.settlementItemId,
//                ecoPortfolio.expectedIntervals.size()));
//    }

    @And("I choose a registration item with MOM availability and a portfolio parent")
    public void iChooseRegWithMomAndPortfolio() throws Throwable {
        var parms = parmsOpt.orElseThrow(() -> new Exception("No test parameters supplied!"));
        assertFalse(parms.ecoList.isEmpty(), "No ECO objects defined!");

        // 1) Pick the first registration with a master item and at least one cleared offer
        var ecoOpt = parms.ecoList.stream()
                .filter(eco -> eco.regId != null)
                .filter(eco -> eco.masterSettlementItemId != null)
                .filter(eco -> !eco.clearedOffers.isEmpty())
                .findFirst();
        assertTrue(ecoOpt.isPresent(), "No registration with MOM availability and portfolio parent found!");
        var ecoReg = ecoOpt.get();

        // 2) Load REGISTRATION intervals (including overrides) from DB into this ECOobject
        context.lastSettlementItemId = ecoReg.settlementItemId;
        loadExpectedIntervalsForEcoObject(ecoReg);

        // 3) Find the EXISTING PORTFOLIO ECOobject in parms.ecoList (do not create a new duplicate)
        String portfolioItemId = ecoReg.masterSettlementItemId;
        var ecoPortfolioOpt = parms.ecoList.stream()
                .filter(e -> e.settlementItemId.equals(portfolioItemId))
                .findFirst();

        assertTrue(ecoPortfolioOpt.isPresent(),
                String.format("No existing portfolio ECOobject found for master item %s", portfolioItemId));

        ECOobject ecoPortfolio = ecoPortfolioOpt.get();

        // 4) GENERATE portfolio expected intervals by aggregating registration intervals in-memory
        // (Portfolio intervals are NOT stored in the DB, they are aggregated on the fly)
        ecoPortfolio.expectedIntervals.clear();

        // Find all registration items that belong to this portfolio
        var regItems = parms.ecoList.stream()
                .filter(e -> e.regId != null)
                .filter(e -> portfolioItemId.equals(e.masterSettlementItemId))
                .toList();

        assertFalse(regItems.isEmpty(), String.format("No registration items found for portfolio %s", portfolioItemId));

        // We need the start and end epochs for the portfolio item to bound the aggregation
        var item = context.savedSettlementItems.get(ecoPortfolio.settlementItemId);
        long itemStartEpoch = ZonedDateTime.parse(item.get("start_dttm_utc").toString().replace(" ", "T")).toEpochSecond();
        long itemEndEpoch = ZonedDateTime.parse(item.get("end_dttm_utc").toString().replace(" ", "T")).toEpochSecond();

        for (long epoch = itemStartEpoch + parms.granSeconds; epoch <= itemEndEpoch; epoch += parms.granSeconds) {
            var interval = new SettlementItemInterval();
            interval.interval_dttm_utc = ZonedDateTime.ofInstant(Instant.ofEpochSecond(epoch), UTC).toString();
            interval.is_armed = false;
            interval.realtime_availability_kw = 0.0;
            interval.interval_source = "AVAILABILITY";

            for (var reg : regItems) {
                // Ensure this specific reg's intervals are loaded from DB
                if (reg.expectedIntervals.isEmpty()) {
                    loadExpectedIntervalsForEcoObject(reg);
                }
                var regInterval = reg.expectedIntervals.get(epoch);
                if (regInterval == null) {
                    continue;
                }

                // Per FCAS doc: override only applies for FINAL aggregation; ESTIMATED
                // aggregation must ignore realtime_availability_kw_override entirely.
                boolean hasOverride = parms.useActualReceivedPrice
                        && regInterval.realtime_availability_kw_override != null;
                boolean isEffectivelyArmed = hasOverride || (regInterval.is_armed != null && regInterval.is_armed);

                if (!"AVAILABILITY".equals(regInterval.interval_source) && !hasOverride) {
                    interval.interval_source = "MISSING";
                } else if (isEffectivelyArmed) {
                    interval.is_armed = true;
                    if (hasOverride) {
                        interval.realtime_availability_kw += regInterval.realtime_availability_kw_override;
                    } else {
                        interval.realtime_availability_kw += regInterval.realtime_availability_kw;
                    }
                }
            }

            // Populate cleared_offer_kw from the fetched portfolio offers if available
            if (ecoPortfolio.clearedOffers.containsKey(epoch)) {
                interval.cleared_offer_kw = ecoPortfolio.clearedOffers.get(epoch).cleared.quantities.capacity;
            } else {
                interval.cleared_offer_kw = 0.0;
                interval.interval_source = "MISSING";
            }

            ecoPortfolio.expectedIntervals.put(epoch, interval);
        }

        LOG.info(String.format(
                "Chosen registration for override test: item=%s reg=%s masterItem=%s offers=%d; " +
                        "portfolio item=%s generated intervals=%d",
                ecoReg.settlementItemId,
                ecoReg.regId,
                ecoReg.masterSettlementItemId,
                ecoReg.clearedOffers.size(),
                ecoPortfolio.settlementItemId,
                ecoPortfolio.expectedIntervals.size()));
    }

    @And("the expected total REV for that registration should be {double}")
    public void expectedTotalRevShouldBe(double expectedTotalRev) throws Throwable {
        var parms = parmsOpt.orElseThrow(() -> new Exception("No test parameters supplied!"));
        assertNotNull(context.lastSettlementItemId, "No chosen registration item id in context!");

        String settlementItemId = context.lastSettlementItemId;

        var ecoOpt = parms.ecoList.stream()
                .filter(eco -> settlementItemId.equals(eco.settlementItemId))
                .findFirst();
        assertTrue(ecoOpt.isPresent(), "Chosen ECO object not found in ecoList!");
        var eco = ecoOpt.get();

        double actualRev = eco.expectedREVOpt.orElseThrow(() ->
                new Exception("No expected REV computed for chosen registration!"));
        assertEquals(expectedTotalRev, actualRev, 0.000001,
                String.format("Total expected REV is %f, expected %.2f", actualRev, expectedTotalRev));
    }


    @And("I choose a registration item with at least one cleared offer")
    public void iChooseRegistrationWithAtLeastOneClearedOffer() throws Throwable {
        var parms = parmsOpt.orElseThrow(() -> new Exception("No test parameters supplied!"));
        assertFalse(parms.ecoList.isEmpty(), "No ECO objects defined!");

        // Pick the first registration ECO that is valid and has at least one cleared offer
        var ecoOpt = parms.ecoList.stream()
                .filter(eco -> eco.regId != null)                    // registrations only
                .filter(ECOcontainer.ECOobject::isValidForEcoCalc)   // same validity rule as other calcs
                .filter(eco -> !eco.clearedOffers.isEmpty())         // at least one offer
                .findFirst();

        assertTrue(ecoOpt.isPresent(), "No registration item with at least one cleared offer found!");
        var eco = ecoOpt.get();

        // Remember this ECO so the AESO override step can find it
        savedEcoObjects.put(eco.settlementItemId, eco);

        // Also keep the id in context if that’s your pattern
        context.lastSettlementItemId = eco.settlementItemId;

        LOG.info(String.format(
                "Chosen AESO registration for override test: item=%s reg=%s offers=%d",
                eco.settlementItemId, eco.regId, eco.clearedOffers.size()));
    }

    @And("I set a fixed payment_value override of {double} for the first {int} existing intervals of that registration")
    public void iSetFixedFcasOverrideFirstExisting(double overrideValue, int numIntervals) throws Throwable {
        var parms = parmsOpt.orElseThrow(() -> new Exception("No test parameters supplied!"));
        assertNotNull(context.lastSettlementItemId, "No chosen registration item id in context!");

        ECOobject ecoReg = parms.ecoList.stream()
                .filter(e -> e.regId != null)
                .filter(e -> e.settlementItemId.equals(context.lastSettlementItemId))
                .findFirst()
                .orElseThrow(() -> new Exception("No ECO registration object for chosen item!"));

        // Get first N existing intervals for this item, ordered by time
        String condition = String.format("settlement_item_id = '%s'", ecoReg.settlementItemId);
        var rows = settClient.selectRecordsTable(
                "settlement_item_intervals",
                condition,
                "interval_dttm_utc"
        );
        assertTrue(rows.size() >= numIntervals,
                String.format("Only %d intervals found, need %d", rows.size(), numIntervals));

        // Build IN-list of normalized timestamps
        List<String> tsList = new ArrayList<>();
        for (int i = 0; i < numIntervals; i++) {
            // normalize to match DB format exactly
            String raw = rows.get(i).get("interval_dttm_utc").toString();
            // if needed, normalize via Utility:
            // String norm = Utility.normalizeDateTime(raw);
            tsList.add(raw);
        }

        String inList = tsList.stream()
                .map(ts -> String.format("TIMESTAMP WITH TIME ZONE '%s'", ts))
                .collect(Collectors.joining(", "));

        String query = String.format(
                "update public.settlement_item_intervals " +
                        "set payment_value_override = %.6f " +
                        "where settlement_item_id = '%s' " +
                        "and interval_dttm_utc in (%s)",
                overrideValue,
                ecoReg.settlementItemId,
                inList
        );

        int count = settClient.runUpdateQuery(query);
        assertEquals(numIntervals, count,
                String.format("Expected to update %d intervals, but updated %d", numIntervals, count));

        LOG.info("Set FCAS payment_value_override={} for first {} intervals of item {}",
                overrideValue, numIntervals, ecoReg.settlementItemId);
    }


    @And("I set a fixed realtime_availability_kw override of {double} for the first {int} existing intervals of that registration")
    public void iSetFixedFcasRealtimeOverrideFirstExisting(double overrideValue, int numIntervals) throws Throwable {
        var parms = parmsOpt.orElseThrow(() -> new Exception("No test parameters supplied!"));
        assertNotNull(context.lastSettlementItemId, "No chosen registration item id in context!");

        ECOobject ecoReg = parms.ecoList.stream()
                .filter(e -> e.regId != null)
                .filter(e -> e.settlementItemId.equals(context.lastSettlementItemId))
                .findFirst()
                .orElseThrow(() -> new Exception("No ECO registration object for chosen item!"));

        // Get first N existing intervals for this item, ordered by time
        String condition = String.format("settlement_item_id = '%s'", ecoReg.settlementItemId);
        var rows = settClient.selectRecordsTable(
                "settlement_item_intervals",
                condition,
                "interval_dttm_utc"
        );
        assertTrue(rows.size() >= numIntervals,
                String.format("Only %d intervals found, need %d", rows.size(), numIntervals));

        // Collect timestamps for the first N intervals
        List<String> tsList = new ArrayList<>();
        for (int i = 0; i < numIntervals; i++) {
            tsList.add(rows.get(i).get("interval_dttm_utc").toString());
        }

        // Build IN (...) list
        String inList = tsList.stream()
                .map(ts -> String.format("TIMESTAMP WITH TIME ZONE '%s'", ts))
                .collect(Collectors.joining(", "));

        String query = String.format(
                "update public.settlement_item_intervals " +
                        "set realtime_availability_kw_override = %.6f " +
                        "where settlement_item_id = '%s' " +
                        "and interval_dttm_utc in (%s)",
                overrideValue,
                ecoReg.settlementItemId,
                inList
        );

        int count = settClient.runUpdateQuery(query);
        assertEquals(numIntervals, count,
                String.format("Expected to update %d intervals, but updated %d", numIntervals, count));

        LOG.info("Set FCAS realtime_availability_kw_override={} for first {} intervals of item {}",
                overrideValue, numIntervals, ecoReg.settlementItemId);
    }

    @Then("the payment for the first {int} existing intervals should be {double}")
    public void assertPaymentFirstExistingIntervals(int numIntervals, double expected) throws Exception {
        assertPaymentInternal(numIntervals, expected, true);
    }

    @Then("the payment_value for the first {int} existing intervals should be {double}")
    public void assertPaymentValueFirstExistingIntervals(int numIntervals, double expected) throws Exception {
        assertPaymentInternal(numIntervals, expected, false);
    }

    private void assertPaymentInternal(int numIntervals, double expected, boolean checkOverride) throws Exception {
        var parms = parmsOpt.orElseThrow(() -> new Exception("No test parameters supplied!"));
        var ecoReg = parms.ecoList.stream()
                .filter(e -> e.regId != null)
                .filter(e -> e.settlementItemId.equals(context.lastSettlementItemId))
                .findFirst()
                .orElseThrow(() -> new Exception("No ECO reg object for chosen item"));

        String baseCondition = String.format("settlement_item_id = '%s'", ecoReg.settlementItemId);
        String condition = checkOverride
                ? baseCondition + String.format(" and payment_value_override = %.6f", expected)
                : baseCondition;

        Thread.sleep(20000L);

        int maxAttempts = 15;
        long sleepMs = 20000L;

        List<HashMap<String, Object>> rows = null;

        for (int attempt = 1; attempt <= maxAttempts; attempt++) {
            rows = settClient.selectRecordsTable(
                    "settlement_item_intervals",
                    condition,
                    "interval_dttm_utc"
            );

            boolean enoughRows = checkOverride
                    ? rows.size() == numIntervals
                    : rows.size() >= numIntervals;

            boolean allPaymentsNonNull = !rows.isEmpty() && (checkOverride
                    ? rows.stream().allMatch(r -> r.get("payment_value") != null)
                    : rows.subList(0, Math.min(numIntervals, rows.size()))
                    .stream().allMatch(r -> r.get("payment_value") != null));

            if (enoughRows && allPaymentsNonNull) {
                break;
            }

            if (attempt == maxAttempts) {
                break;
            }

            Thread.sleep(sleepMs);
        }

        if (checkOverride) {
            assertEquals(numIntervals, rows.size(),
                    String.format("Expected %d overridden intervals, found %d", numIntervals, rows.size()));
        } else {
            assertTrue(rows.size() >= numIntervals,
                    String.format("Only %d intervals found, need %d", rows.size(), numIntervals));
        }

        int limit = checkOverride ? rows.size() : numIntervals;

        for (int i = 0; i < limit; i++) {
            var row = rows.get(i);
            String ts = row.get("interval_dttm_utc").toString();

            Double paymentVal = row.get("payment_value") == null
                    ? null
                    : Double.valueOf(row.get("payment_value").toString());
            assertNotNull(paymentVal, "payment_value is null at interval " + ts);
            assertEquals(expected, paymentVal, 1e-6,
                    "payment_value mismatch at interval " + ts);

            if (checkOverride) {
                Double overrideVal = row.get("payment_value_override") == null
                        ? null
                        : Double.valueOf(row.get("payment_value_override").toString());
                assertNotNull(overrideVal, "payment_value_override is null at interval " + ts);
                assertEquals(expected, overrideVal, 1e-6,
                        "payment_value_override mismatch at interval " + ts);
            }
        }
    }

    @Then("the ECO payments should equal the expected final payments")
    public void iCompareFinalFcasPaymentsToEco() throws Throwable {
        var parms = parmsOpt.orElseThrow(() -> new Exception("No test parameters supplied!"));
        assertFalse(parms.ecoList.isEmpty(), "No ECO objects defined!");
        assertEquals(Context.PROGRAM.FCAS, context.program, "This step is only for final FCAS calculations!");

        var postgres = getEcoClient();
        var errors = new ArrayList<String>();

        for (var eco : parms.ecoList) {
            if (eco.isDeleted) {
                LOG.info(String.format(
                        "Settlement item: %s for registration %s DELETED, skipping",
                        eco.settlementItemId, eco.regId));
                continue;
            }

            // For FCAS, only registration items should have ECO rows
            if (eco.regId == null) {
                postgres.verifyNoEcoRowsForItem(eco);
                LOG.info("Verified that no ECO rows were created for portfolio item {}", eco.settlementItemId);
                continue;
            }

            // Load actual REV/COGS (and check FCAS final COGS prebilled=false inside)
            postgres.getFinalFcasEcoPayment(eco, parms.applyMonth.toLocalDate());

            var expectedREV = eco.expectedREVOpt.orElseThrow(
                    () -> new Exception("No expected REV supplied for final FCAS!"));
            var expectedCOGS = eco.expectedCOGSOpt.orElseThrow(
                    () -> new Exception("No expected COGS supplied for final FCAS!"));

            var actualREV = eco.REVOpt.orElseThrow(
                    () -> new Exception("No actual REV found for final FCAS!")).amount;
            var actualCOGS = eco.COGSOpt.orElseThrow(
                    () -> new Exception("No actual COGS found for final FCAS!")).amount;

            if (!isEqualDollars(expectedREV, actualREV)) {
                errors.add(String.format(
                        "Final FCAS: Item %s Reg %s Actual REV %.2f != expected REV %.2f",
                        eco.settlementItemId, eco.regId, actualREV, expectedREV));
            } else {
                LOG.info(String.format(
                        "Final FCAS: Item %s Reg %s Actual REV %.2f matches expected REV %.2f",
                        eco.settlementItemId, eco.regId, actualREV, expectedREV));
            }

            if (!isEqualDollars(expectedCOGS, actualCOGS)) {
                errors.add(String.format(
                        "Final FCAS: Item %s Reg %s Actual COGS %.2f != expected COGS %.2f",
                        eco.settlementItemId, eco.regId, actualCOGS, expectedCOGS));
            } else {
                LOG.info(String.format(
                        "Final FCAS: Item %s Reg %s Actual COGS %.2f matches expected COGS %.2f",
                        eco.settlementItemId, eco.regId, actualCOGS, expectedCOGS));
            }
        }

        assertTrue(errors.isEmpty(), String.join("\n", errors));
    }

    @Given("I expect {int} quarterly settlements - the same pipeline_run_id - have been processed by the pipeline")
    public void iGetLatestQuarterlySettlementsFromPipeline(int numSettlementsExpected) throws Throwable {
        context.pipelineSettlementsProcessed.clear();

        // savedSettlements keys are settlement IDs saved progressively throughout the scenario
        // Do NOT assert the size here — just take whatever IDs are stored and pass them to the query
        var expectedIds = new ArrayList<>(context.savedSettlements.keySet());

        var ids = new ArrayList<String>();
        // Wait up to 90 seconds for all settlements to complete
        for (int i = 0; i <= 18 && ids.size() < numSettlementsExpected; i++) {
            Thread.sleep(5000);
            ids.clear();
            ids.addAll(metaClient.getLatestSuccessfulPipelineHistorySettlementIdsForQuarterly(
                    testStartEpoch, expectedIds));
        }

        assertEquals(numSettlementsExpected, ids.size(),
                "Unexpected number of quarterly settlements processed!");

        ids.forEach(id -> {
            context.lastSettlementId = id;
            var request = RequestContainer.build().getLastEntity(SETTLEMENT).call();
            context.pipelineSettlementsProcessed.add(
                    JSON.convertValue(request.getDataAsList().get(0), Settlement.class));
        });
    }


    // In RunSettlementPipeline — add after executePost or as a separate step
    @Then("I save the pipeline_run_id from the response")
    public void iSavePipelineRunId() {
        assertFalse(context.lastApiResponseData.isEmpty(), "No response data saved — did the POST step run?");

        Object runId = context.lastApiResponseData.get("pipeline_run_id");
        assertNotNull(runId, "pipeline_run_id not found in response data");

        context.lastPipelineRunId = runId.toString();
        LOG.info("Saved pipeline_run_id: {}", context.lastPipelineRunId);
    }

    @Then("I retrieve all pipeline history rows for the current pipeline_run_id up to pipeline_step: {word} status: {word}")
    public void iRetrievePipelineHistoryByRunId(String step, String status) throws Throwable {
        String runId = context.lastPipelineRunId;
        assertNotNull(runId, "No pipeline_run_id saved — did the POST step succeed?");
        assertFalse(runId.isBlank(), "pipeline_run_id is blank");

        context.pipelineHistoryForLastRun.clear();
        boolean foundTerminalRow = false;

        for (int attempt = 1; attempt <= 20; attempt++) {
            String condition = String.format("pipeline_run_id = '%s'", runId);

            // Match the exact return type that iGetPipelineHistoryForPreviousFullQuarter uses
            List<HashMap<String, Object>> rows = metaClient.selectRecordsTable(
                    "pipeline_state_history", condition, "created_dttm_utc");

            LOG.info("Attempt {}/20 — {} rows for pipeline_run_id={}", attempt, rows.size(), runId);

            boolean found = rows.stream().anyMatch(r -> {
                Object ps = r.get("pipeline_step");
                Object st = r.get("status");
                return ps != null && st != null
                        && step.equals(ps.toString())
                        && status.equals(st.toString());
            });

            if (found) {
                foundTerminalRow = true;
                context.pipelineHistoryForLastRun.addAll(rows);
                break;
            }

            try {
                Thread.sleep(5_000);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                fail("Interrupted while waiting for pipeline history: " + e.getMessage());
            }
        }

        assertTrue(foundTerminalRow,
                String.format("Timeout waiting for pipeline_run_id=%s to reach step=%s status=%s",
                        runId, step, status));

        LOG.info("{} pipeline history rows stored for pipeline_run_id={}",
                context.pipelineHistoryForLastRun.size(), runId);
    }

    @Then("the pipeline history should contain settlement item ids for the current pipeline_run_id")
    public void iPipelineHistoryShouldHaveSettlementItemIds() throws Exception {
        assertNotNull(context.lastPipelineRunId, "No pipeline_run_id saved — did the POST step succeed?");

        String query = String.format(
                "pipeline_run_id = '%s' AND settlement_item_id IS NOT NULL",
                context.lastPipelineRunId
        );

        List<HashMap<String, Object>> rows = metaClient.selectRecordsTable(
                "pipeline_state_history", query, "settlement_item_id"
        );

        // Collect the distinct settlement_item_ids
        List<Object> distinctIds = rows.stream()
                .map(r -> r.get("settlement_item_id"))
                .distinct()
                .toList();

        assertFalse(distinctIds.isEmpty(),
                String.format("No pipeline_state_history rows with settlement_item_id found for pipeline_run_id=%s",
                        context.lastPipelineRunId));

        LOG.info("Found {} distinct settlement_item_id(s) for pipeline_run_id={}: {}",
                distinctIds.size(), context.lastPipelineRunId, distinctIds);
    }

    @Then("the pipeline history should contain 3 CREATOR_FIRST SUCCESS rows for the quarterly settlements")
    public void iPipelineHistoryShouldHave3CreatorFirstRowsForQuarter() throws Exception {
        assertNotNull(context.lastPipelineRunId, "No pipeline_run_id saved — did the POST step succeed?");

        // Step 1: get the settlement_ids created by this pipeline run
        String settlementCondition = String.format(
                "pipeline_run_id = '%s'", context.lastPipelineRunId
        );
        List<HashMap<String, Object>> pipelineRows = metaClient.selectRecordsTable(
                "pipeline_state_history", settlementCondition, "settlement_id"
        );

        List<String> settlementIds = pipelineRows.stream()
                .map(r -> r.get("settlement_id"))
                .filter(Objects::nonNull)
                .map(Object::toString)
                .distinct()
                .toList();

        assertFalse(settlementIds.isEmpty(),
                String.format("No settlement_ids found in pipeline_state_history for pipeline_run_id=%s",
                        context.lastPipelineRunId));

        LOG.info("Found {} distinct settlement_id(s) for pipeline_run_id={}: {}",
                settlementIds.size(), context.lastPipelineRunId, settlementIds);

        // Step 2: check each settlement covers a distinct month (3 for a quarter)
        String idList = settlementIds.stream()
                .map(id -> "'" + id + "'")
                .collect(Collectors.joining(", "));

        List<HashMap<String, Object>> settlementRows = settClient.selectRecordsTable(
                "settlements",
                String.format("settlement_id IN (%s)", idList),
                "start_dttm_utc"
        );

        LOG.info("Settlement date ranges:");
        settlementRows.forEach(r -> LOG.info("  settlement_id={} start={} end={}",
                r.get("settlement_id"), r.get("start_dttm_utc"), r.get("end_dttm_utc")));

        // Step 3: verify CREATOR_FIRST / SUCCESS rows — expect exactly 3 (one per month)
        String historyCondition = String.format(
                "settlement_id IN (%s) AND pipeline_step = 'CREATOR_FIRST' AND status = 'SUCCESS' AND pipeline_run_id = '%s'",
                idList, context.lastPipelineRunId
        );

        List<HashMap<String, Object>> creatorFirstRows = metaClient.selectRecordsTable(
                "pipeline_state_history", historyCondition, "settlement_id"
        );

        List<Object> distinctSettlementIdsWithSuccess = creatorFirstRows.stream()
                .map(r -> r.get("settlement_id"))
                .distinct()
                .toList();

        assertEquals(3, distinctSettlementIdsWithSuccess.size(),
                String.format("Expected 3 distinct settlements with CREATOR_FIRST/SUCCESS for pipeline_run_id=%s, found %d: %s",
                        context.lastPipelineRunId, distinctSettlementIdsWithSuccess.size(), distinctSettlementIdsWithSuccess));

        LOG.info("Confirmed 3 CREATOR_FIRST/SUCCESS rows for quarterly pipeline_run_id={}", context.lastPipelineRunId);
    }

    @And("no new settlements should have been created since the pipeline was triggered")
    public void noNewSettlementsShouldHaveBeenCreated() throws Exception {
        assertTrue(context.pipelineInvokeEpoch > 0, "No pipeline invoke time recorded — did the POST step run?");

        String invokeTime = Utility.epochToString(context.pipelineInvokeEpoch);

        List<HashMap<String, Object>> rows = settClient.selectRecordsTable(
                "settlements",
                String.format("last_updated_dttm_utc > TIMESTAMP WITH TIME ZONE '%s' AND deleted = false", invokeTime),
                "last_updated_dttm_utc"
        );

        List<String> errors = rows.stream()
                .map(r -> String.format("Unexpected settlement created: settlement_id='%s' product_id='%s' settlement_type='%s' start_dttm_utc='%s'",
                        r.get("settlement_id"), r.get("product_id"), r.get("settlement_type"), r.get("start_dttm_utc")))
                .toList();

        assertTrue(errors.isEmpty(), String.join("\n", errors));
        LOG.info("Confirmed no new settlements were created since pipeline was triggered at {}", invokeTime);
    }

    @And("I force is_armed to false for the first {int} existing intervals of that registration")
    public void iForceIsArmedToFalseFirstExisting(int numIntervals) throws Throwable {
        var parms = parmsOpt.orElseThrow(() -> new Exception("No test parameters supplied!"));
        assertNotNull(context.lastSettlementItemId, "No chosen registration item id in context!");

        ECOobject ecoReg = parms.ecoList.stream()
                .filter(e -> e.regId != null)
                .filter(e -> e.settlementItemId.equals(context.lastSettlementItemId))
                .findFirst()
                .orElseThrow(() -> new Exception("No ECO registration object for chosen item!"));

        String condition = String.format("settlement_item_id = '%s'", ecoReg.settlementItemId);
        var rows = settClient.selectRecordsTable(
                "settlement_item_intervals",
                condition,
                "interval_dttm_utc"
        );
        assertTrue(rows.size() >= numIntervals,
                String.format("Only %d intervals found, need %d", rows.size(), numIntervals));

        List<String> tsList = new ArrayList<>();
        for (int i = 0; i < numIntervals; i++) {
            tsList.add(rows.get(i).get("interval_dttm_utc").toString());
        }

        String inList = tsList.stream()
                .map(ts -> String.format("TIMESTAMP WITH TIME ZONE '%s'", ts))
                .collect(Collectors.joining(", "));

        String query = String.format(
                "update public.settlement_item_intervals " +
                        "set is_armed = false " +
                        "where settlement_item_id = '%s' " +
                        "and interval_dttm_utc in (%s)",
                ecoReg.settlementItemId,
                inList
        );
        int count = settClient.runUpdateQuery(query);
        assertEquals(numIntervals, count,
                String.format("Expected to update %d intervals, but updated %d", numIntervals, count));
        LOG.info("Forced is_armed=false for first {} intervals of item {}", numIntervals, ecoReg.settlementItemId);
    }

    @Then("the payment_value for the first {int} existing intervals should be calculated using the override despite is_armed being false")
    public void thePaymentValueShouldBeCalculatedDespiteIsArmedFalse(int numIntervals) throws Throwable {
        var parms = parmsOpt.orElseThrow(() -> new Exception("No test parameters supplied!"));
        assertNotNull(context.lastSettlementItemId, "No chosen registration item id in context!");

        ECOobject ecoReg = parms.ecoList.stream()
                .filter(e -> e.regId != null)
                .filter(e -> e.settlementItemId.equals(context.lastSettlementItemId))
                .findFirst()
                .orElseThrow(() -> new Exception("No ECO registration object for chosen item!"));

        String condition = String.format("settlement_item_id = '%s'", ecoReg.settlementItemId);

        // Wait for ECO to finish updating the intervals
        Thread.sleep(20000L);
        int maxAttempts = 15;
        long sleepMs = 20000L;
        List<HashMap<String, Object>> rows = null;

        for (int attempt = 1; attempt <= maxAttempts; attempt++) {
            rows = settClient.selectRecordsTable("settlement_item_intervals", condition, "interval_dttm_utc");
            boolean enoughRows = rows.size() >= numIntervals;
            boolean allPaymentsNonNull = !rows.isEmpty() && rows.subList(0, Math.min(numIntervals, rows.size()))
                    .stream().allMatch(r -> r.get("payment_value") != null);

            if (enoughRows && allPaymentsNonNull) {
                break;
            }
            if (attempt == maxAttempts) {
                break;
            }
            Thread.sleep(sleepMs);
        }

        assertTrue(rows.size() >= numIntervals,
                String.format("Only %d intervals found, need %d", rows.size(), numIntervals));

        List<String> errors = new ArrayList<>();
        for (int i = 0; i < numIntervals; i++) {
            var row = rows.get(i);
            String ts = row.get("interval_dttm_utc").toString();

            // 1. Verify is_armed is indeed false (proving the precondition)
            Object isArmedObj = row.get("is_armed");
            boolean isArmed = isArmedObj != null && Boolean.parseBoolean(isArmedObj.toString());
            if (isArmed) {
                errors.add(String.format("Interval %s: Expected is_armed=false, but was true", ts));
            }

            // 2. Verify the override is populated
            Object overrideObj = row.get("realtime_availability_kw_override");
            if (overrideObj == null) {
                errors.add(String.format("Interval %s: Expected realtime_availability_kw_override to be populated, but was null", ts));
            }

            // 3. Verify payment_value is calculated (i.e., not null and > 0.0, since the override was 500.0)
            Object paymentObj = row.get("payment_value");
            if (paymentObj == null) {
                errors.add(String.format("Interval %s: payment_value is null", ts));
            } else {
                double paymentVal = Double.parseDouble(paymentObj.toString());
                if (paymentVal <= 0.0) {
                    errors.add(String.format("Interval %s: Expected payment_value > 0 (calculated via override), but was %f", ts, paymentVal));
                }
            }
        }

        assertTrue(errors.isEmpty(),
                "Verification of override calculation despite is_armed=false failed:\n" + String.join("\n", errors));
        LOG.info("Successfully verified that payment_value was calculated using the override despite is_armed=false for {} intervals", numIntervals);
    }

    @And("I set a fixed realtime_availability_kw override of {double} for all armed intervals of that registration")
    public void iSetFixedFcasRealtimeOverrideAllArmed(double overrideValue) throws Throwable {
        var parms = parmsOpt.orElseThrow(() -> new Exception("No test parameters supplied!"));
        assertNotNull(context.lastSettlementItemId, "No chosen registration item id in context!");

        ECOobject ecoReg = parms.ecoList.stream()
                .filter(e -> e.regId != null)
                .filter(e -> e.settlementItemId.equals(context.lastSettlementItemId))
                .findFirst()
                .orElseThrow(() -> new Exception("No ECO registration object for chosen item!"));

        String query = String.format(
                "update public.settlement_item_intervals " +
                        "set realtime_availability_kw_override = %.6f " +
                        "where settlement_item_id = '%s' " +
                        "and is_armed = true",
                overrideValue,
                ecoReg.settlementItemId
        );

        int count = settClient.runUpdateQuery(query);
        assertTrue(count > 0,
                "Expected to update at least one armed interval, but updated 0. " +
                        "Confirm this item has EPS-armed intervals before calling this step.");

        LOG.info("Set FCAS realtime_availability_kw_override={} for all {} ARMED intervals of item {}",
                overrideValue, count, ecoReg.settlementItemId);
    }

}


