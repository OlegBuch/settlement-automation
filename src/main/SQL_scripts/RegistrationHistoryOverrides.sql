/*
  Setup script for PortfolioLevelItemCreators.feature
  This script creates the necessary registration and registration history records
  to test the creation of portfolio-level settlement items.
*/

-- Run insert query for each env(devtest/dev/preprod) for specified registration_id
INSERT INTO settlement_metadata."REGISTRATION" (
    registration_id,
    status,
    product_id,
    flexible_asset_id,
    service_delivery_point_id,
    org_id,
    site_id,
    ecrm_account_id,
    ecrm_site_id,
    ecrm_opportunity_id,
    deleted,
    needs_manual_fix,
    last_updated_dttm_utc,
    last_updated_by,
    portfolio_id,
    registration_set_id
)
VALUES (
    '4f961f28-2e83-4817-8e1e-0857099fe8e1',   -- registration_id
    'ACTIVE',                                 -- status
    '02c963aa-06f9-4413-be5e-5e6a16722f00',   -- product_id
    '47f79c5d-ca39-4f21-85f2-8591a6cec6ae',   -- flexible_asset_id
    '47f79c5d-ca39-4f21-85f2-8591a6cec6ae',   -- service_delivery_point_id
    NULL,                                     -- org_id
    'fd03f034-45c5-4ccf-897c-8624cdd663d8',   -- site_id
    NULL,                                     -- ecrm_account_id
    NULL,                                     -- ecrm_site_id
    'a03a000000E40NdAAJ',                     -- ecrm_opportunity_id
    false,                                    -- deleted
    true,                                     -- needs_manual_fix
    TIMESTAMPTZ '2026-04-08 07:18:20.239635+00', -- last_updated_dttm_utc
    '00000000-0000-0000-0000-000000000000',   -- last_updated_by
    NULL,                                     -- portfolio_id
    NULL                                      -- registration_set_id
);