package com.enernoc.bdap.stepdefs;

import com.enernoc.bdap.model.APIResponses;
import com.enernoc.bdap.shared.Context;
import io.cucumber.java.en.Given;
import io.cucumber.java.en.Then;
import io.restassured.http.ContentType;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.Arrays;
import java.util.TreeSet;

import static io.restassured.RestAssured.given;
import static org.junit.jupiter.api.Assertions.fail;

public class Reference {

    private static final Logger LOG = LoggerFactory.getLogger("Reference");

    private APIResponses.GetReferenceDataResult refData;
    private String endpoint;

    @Given("I call the reference service endpoint {word}")
    public void iCallRefEndpoint(String endpointP) {

        endpoint = endpointP;
        refData = given().log().uri().with().header("x-api-key", Context.refDataApiKey).get(String.format("%s/%s", Context.targetRefUrl, endpointP))
                .then().assertThat().statusCode(200).contentType(ContentType.JSON).extract().as(APIResponses.GetReferenceDataResult.class);

    }

    @Then("the endpoint response should match the expected enumeration")
    public void validateEndpointResponse() {
        var expected = new TreeSet<>(Context.refEnums.get(endpoint));
        var actual = new TreeSet<>(Arrays.stream(refData.data()).map(r -> r.code).toList());
        if (actual.equals(expected)) {
            LOG.info(String.format("Reference endpoint '%s' passed validation", endpoint));
        } else {
            LOG.error(String.format("Reference endpoint '%s' failed validation!!", endpoint));
            LOG.error(String.format("Expected: [%s]", String.join(",", expected)));
            LOG.error(String.format("Actual: [%s]", String.join(",", actual)));
            fail();
        }

    }

}
