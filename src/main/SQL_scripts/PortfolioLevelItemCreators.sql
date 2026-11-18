/*
  Setup script for PortfolioLevelItemCreators.feature
  This script creates the necessary registration and registration history records
  to test the creation of portfolio-level settlement items.
*/

--
-- (Optional) Manual Debugging Helper Commands
-- These are not required for the test automation but are useful for developers.
--
-- SET time zone 'UTC';
-- SELECT * FROM settlement_metadata."REGISTRATION" WHERE product_id = cast('69c35eab-4ecd-4a34-b692-25396f88c878' as uuid);
-- SELECT * FROM settlement_metadata."REGISTRATION_HISTORY" WHERE product_id = cast('69c35eab-4ecd-4a34-b692-25396f88c878' as uuid);


--
-- Clean up previous test data to make this script re-runnable
-- Delete only registration_history test data inserted by this script
DELETE FROM settlement_metadata."REGISTRATION_HISTORY" WHERE registration_id IN ('b228e12d-7d5d-420b-8348-6e222f800f68', '7472d905-f4b5-4dfe-a87a-628bcca1c16b', '3a533440-2d4c-4d84-a9b3-7ae2d5362fd3') AND product_id = '69c35eab-4ecd-4a34-b692-25396f88c878' AND (effective_start_dttm_utc >= '2025-10-01' AND effective_end_dttm_utc <= '2026-03-01');
-- Delete only registration test data inserted by this script
DELETE FROM settlement_metadata."REGISTRATION" WHERE registration_id IN ('b228e12d-7d5d-420b-8348-6e222f800f68', '7472d905-f4b5-4dfe-a87a-628bcca1c16b', '3a533440-2d4c-4d84-a9b3-7ae2d5362fd3') AND product_id = '69c35eab-4ecd-4a34-b692-25396f88c878';
--


--
-- INSERT the base registration records.
-- The history table will be populated specifically for each scenario below.
--
INSERT INTO settlement_metadata."REGISTRATION" (registration_id, status, product_id, flexible_asset_id, site_id, org_id, ecrm_account_id, ecrm_site_id, ecrm_opportunity_id, deleted, needs_manual_fix, last_updated_dttm_utc, last_updated_by)
VALUES
    -- Registration 1 (initially in Portfolio 1)
    (cast('b228e12d-7d5d-420b-8348-6e222f800f68' as uuid), 'ACTIVE', cast('69c35eab-4ecd-4a34-b692-25396f88c878' as uuid), cast('8af39812-3fd2-4812-ad84-80c432d6ca20' as uuid), cast('8a19a91f-01ba-44c1-b64b-26de6728c7f7' as uuid), cast('c24b9ead-8ad4-4673-8bf7-42c3b5534401' as uuid), 'fake_ecrm_1', 'fake_ecrm_1', 'fake_ecrm_1', false, false, now(), cast('a65986d6-a0f4-4967-8129-4512e78ed39f' as uuid)),
    -- Registration 2 (in Portfolio 2)
    (cast('7472d905-f4b5-4dfe-a87a-628bcca1c16b' as uuid), 'ACTIVE', cast('69c35eab-4ecd-4a34-b692-25396f88c878' as uuid), cast('e9e7a836-add3-4184-9a36-a538451c0607' as uuid), cast('6a215381-4400-4c7e-9352-591e3cc9504a' as uuid), cast('c24b9ead-8ad4-4673-8bf7-42c3b5534401' as uuid), 'fake_ecrm_2', 'fake_ecrm_2', 'fake_ecrm_2', false, false, now(), cast('a65986d6-a0f4-4967-8129-4512e78ed39f' as uuid)),
    -- Registration 3 (in Portfolio 2)
    (cast('3a533440-2d4c-4d84-a9b3-7ae2d5362fd3' as uuid), 'ACTIVE', cast('69c35eab-4ecd-4a34-b692-25396f88c878' as uuid), cast('e9e37dff-6d25-443f-8b76-bacdce84ad5e' as uuid), cast('f3a6f4aa-bd51-4c33-8886-35e33878322e' as uuid), cast('c24b9ead-8ad4-4673-8bf7-42c3b5534401' as uuid), 'fake_ecrm_3', 'fake_ecrm_3', 'fake_ecrm_3', false, false, now(), cast('a65986d6-a0f4-4967-8129-4512e78ed39f' as uuid));


--
-- Scenario: Two registrations in one portfolio for the entire settlement period
-- Settlement Period: Oct 2025 (2025-10-01 to 2025-11-01)
--
INSERT INTO settlement_metadata."REGISTRATION_HISTORY" (registration_id, status, product_id, portfolio_id, effective_start_dttm_utc, effective_end_dttm_utc, deleted, needs_manual_fix, last_updated_dttm_utc, last_updated_by)
VALUES
    -- Registration 2 is ACTIVE in Portfolio 2 for the whole period
    (cast('7472d905-f4b5-4dfe-a87a-628bcca1c16b' as uuid), 'ACTIVE', cast('69c35eab-4ecd-4a34-b692-25396f88c878' as uuid), cast('d299fbe1-16e3-4780-b8e8-6b8cd5978873' as uuid), '2025-10-01 00:00:00', '2025-10-31 00:00:00', false, false, now(), cast('a65986d6-a0f4-4967-8129-4512e78ed39f' as uuid)),
    -- Registration 3 is ACTIVE in Portfolio 2 for the whole period
    (cast('3a533440-2d4c-4d84-a9b3-7ae2d5362fd3' as uuid), 'ACTIVE', cast('69c35eab-4ecd-4a34-b692-25396f88c878' as uuid), cast('d299fbe1-16e3-4780-b8e8-6b8cd5978873' as uuid), '2025-10-01 00:00:00', '2025-10-31 00:00:00', false, false, now(), cast('a65986d6-a0f4-4967-8129-4512e78ed39f' as uuid));


--
-- Scenario: A registration that is not part of a portfolio
-- Settlement Period: Nov 2025 (2025-11-01 to 2025-12-01)
--
INSERT INTO settlement_metadata."REGISTRATION_HISTORY" (registration_id, status, product_id, portfolio_id, effective_start_dttm_utc, effective_end_dttm_utc, deleted, needs_manual_fix, last_updated_dttm_utc, last_updated_by)
VALUES
    -- Registration 1 is ACTIVE but has no portfolio
    (cast('b228e12d-7d5d-420b-8348-6e222f800f68' as uuid), 'ACTIVE', cast('69c35eab-4ecd-4a34-b692-25396f88c878' as uuid), NULL, '2025-11-01 00:00:00', '2025-11-30 00:00:00', false, false, now(), cast('a65986d6-a0f4-4967-8129-4512e78ed39f' as uuid));


--
-- Scenario: A registration that changes portfolio in the middle of a settlement period
-- Settlement Period: Dec 2025 (2025-12-01 to 2026-01-01)
--
INSERT INTO settlement_metadata."REGISTRATION_HISTORY" (registration_id, status, product_id, portfolio_id, effective_start_dttm_utc, effective_end_dttm_utc, deleted, needs_manual_fix, last_updated_dttm_utc, last_updated_by)
VALUES
    -- Registration 1 is in Portfolio 1 for the first half of the month
    (cast('b228e12d-7d5d-420b-8348-6e222f800f68' as uuid), 'ACTIVE', cast('69c35eab-4ecd-4a34-b692-25396f88c878' as uuid), cast('979ad522-3468-45d0-9d97-00d83a83c555' as uuid), '2025-12-01 00:00:00', '2025-12-15 00:00:00', false, false, now(), cast('a65986d6-a0f4-4967-8129-4512e78ed39f' as uuid)),
    -- Registration 1 moves to Portfolio 2 for the second half of the month
    (cast('b228e12d-7d5d-420b-8348-6e222f800f68' as uuid), 'ACTIVE', cast('69c35eab-4ecd-4a34-b692-25396f88c878' as uuid), cast('d299fbe1-16e3-4780-b8e8-6b8cd5978873' as uuid), '2025-12-15 00:00:00', '2025-12-31 00:00:00', false, false, now(), cast('a65986d6-a0f4-4967-8129-4512e78ed39f' as uuid));


--
-- Scenario: Portfolio contains multiple registrations with all active during settlement period
-- Settlement Period: Jan 2026 (2026-01-01 to 2026-02-01)
--
INSERT INTO settlement_metadata."REGISTRATION_HISTORY" (registration_id, status, product_id, portfolio_id, effective_start_dttm_utc, effective_end_dttm_utc, deleted, needs_manual_fix, last_updated_dttm_utc, last_updated_by)
VALUES
    -- Registration 1 is ACTIVE in Portfolio
    (cast('b228e12d-7d5d-420b-8348-6e222f800f68' as uuid), 'ACTIVE', cast('69c35eab-4ecd-4a34-b692-25396f88c878' as uuid), cast('979ad522-3468-45d0-9d97-00d83a83c555' as uuid), '2026-01-01 00:00:00', '2026-01-31 00:00:00', false, false, now(), cast('a65986d6-a0f4-4967-8129-4512e78ed39f' as uuid)),
    -- Registration 2 is ACTIVE in Portfolio
    (cast('b228e12d-7d5d-420b-8348-6e222f800f68' as uuid), 'ACTIVE', cast('69c35eab-4ecd-4a34-b692-25396f88c878' as uuid), cast('979ad522-3468-45d0-9d97-00d83a83c555' as uuid), '2026-01-01 00:00:00', '2026-01-31 00:00:00', false, false, now(), cast('a65986d6-a0f4-4967-8129-4512e78ed39f' as uuid));
     -- Registration 3 is ACTIVE in Portfolio
    (cast('b228e12d-7d5d-420b-8348-6e222f800f68' as uuid), 'ACTIVE', cast('69c35eab-4ecd-4a34-b692-25396f88c878' as uuid), cast('979ad522-3468-45d0-9d97-00d83a83c555' as uuid), '2026-01-01 00:00:00', '2026-01-31 00:00:00', false, false, now(), cast('a65986d6-a0f4-4967-8129-4512e78ed39f' as uuid));


--
-- Scenario: Portfolio contains multiple registrations with only some active during settlement period
-- Settlement Period: Feb 2026 (2026-02-01 to 2026-03-01)
--
INSERT INTO settlement_metadata."REGISTRATION_HISTORY" (registration_id, status, product_id, portfolio_id, effective_start_dttm_utc, effective_end_dttm_utc, deleted, needs_manual_fix, last_updated_dttm_utc, last_updated_by)
VALUES
    -- This registration ended before the settlement period began
    (cast('b228e12d-7d5d-420b-8348-6e222f800f68' as uuid), 'ACTIVE', cast('69c35eab-4ecd-4a34-b692-25396f88c878' as uuid), cast('979ad522-3468-45d0-9d97-00d83a83c555' as uuid), '2026-02-01 00:00:00', '2026-02-15 00:00:00', false, false, now(), cast('a65986d6-a0f4-4967-8129-4512e78ed39f' as uuid));
    (cast('b228e12d-7d5d-420b-8348-6e222f800f68' as uuid), 'ACTIVE', cast('69c35eab-4ecd-4a34-b692-25396f88c878' as uuid), cast('979ad522-3468-45d0-9d97-00d83a83c555' as uuid), '2026-02-15 00:00:00', '2026-03-01 00:00:00', false, false, now(), cast('a65986d6-a0f4-4967-8129-4512e78ed39f' as uuid));
    (cast('b228e12d-7d5d-420b-8348-6e222f800f68' as uuid), 'INACTIVE', cast('69c35eab-4ecd-4a34-b692-25396f88c878' as uuid), cast('979ad522-3468-45d0-9d97-00d83a83c555' as uuid), '2026-02-01 00:00:00', '2026-02-28 00:00:00', false, false, now(), cast('a65986d6-a0f4-4967-8129-4512e78ed39f' as uuid));

