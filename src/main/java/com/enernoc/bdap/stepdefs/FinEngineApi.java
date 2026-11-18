package com.enernoc.bdap.stepdefs;

import com.enernoc.bdap.model.EntityType;
import com.enernoc.bdap.shared.Context;
import com.enernoc.bdap.model.RequestContainer;
import io.cucumber.java.en.When;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class FinEngineApi {

    private static final Logger LOG = LoggerFactory.getLogger("FinEnginePingStepDefs");
    private final Context context = Context.getContext();
    private RequestContainer request;

    @When("I call GET finEngine ping")
    public void iCallGetFinenginePing() {
        RequestContainer request = RequestContainer.build()
                .getEntity(EntityType.FIN_ENGINE_PING, "not specified");
        request.call(context.popExpectedStatus(200));
    }
}