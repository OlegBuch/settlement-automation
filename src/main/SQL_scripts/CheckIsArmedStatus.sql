/*
  Setup script for CheckIsArmedStatus.feature
  This script creates the necessary registration and registration history records
  to test the isArmed status values for settlement_item_intervals when we run creator settlement lambda.
*/

--
-- Clean up previous test data to make this script re-runnable
-- Delete only registration_history test data inserted by this script
DELETE FROM settlement_metadata."REGISTRATION_HISTORY"
WHERE registration_id IN (
          'bb51891a-3853-4131-ac46-3a5fb5ea18bd',
          '61eacbe0-d853-4fd1-a50c-e32375475a70'
      )
  AND product_id = '1ef635c7-65b2-4945-bdcb-aa2606956cfd'
  AND effective_start_dttm_utc >= '2024-01-01'::timestamptz
  AND effective_end_dttm_utc <= '9999-12-31'::timestamptz;

-- Delete only registration test data inserted by this script
DELETE FROM settlement_metadata."REGISTRATION"
WHERE registration_id IN (
          'bb51891a-3853-4131-ac46-3a5fb5ea18bd',
          '61eacbe0-d853-4fd1-a50c-e32375475a70'
      )
  AND product_id = '1ef635c7-65b2-4945-bdcb-aa2606956cfd';
--


--
-- INSERT the base registration records from
-- The registration_history table will be populated separately
--
INSERT INTO settlement_metadata."REGISTRATION"
    (registration_id,
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
     last_updated_by)
VALUES
    -- Row 1 from CSV
    (CAST('bb51891a-3853-4131-ac46-3a5fb5ea18bd' AS uuid),
     'ACTIVE',
     CAST('1ef635c7-65b2-4945-bdcb-aa2606956cfd' AS uuid),
     CAST('87351300-7b06-4810-9583-c760839934d5' AS uuid),
     NULL,
     CAST('ebbc7eaf-ff13-4b2c-95e8-053cfaf1a865' AS uuid),
     CAST('23d0be6f-962b-4bb9-a081-75cd70e0b785' AS uuid),
     NULL,
     NULL,
     NULL,
     TRUE,
     TRUE,
     '2025-09-01 05:12:16.505166+00',
     'qa.user@example.com'),

    -- Row 2 from CSV
    (CAST('61eacbe0-d853-4fd1-a50c-e32375475a70' AS uuid),
     'ACTIVE',
     CAST('1ef635c7-65b2-4945-bdcb-aa2606956cfd' AS uuid),
     CAST('202463e3-996b-4d45-9a9a-50762400a1b3' AS uuid),
     NULL,
     CAST('3480cc3a-f1e2-4efc-b4c8-c8f9f4207068' AS uuid),
     CAST('11a33679-7210-4603-8cc2-ae759ec7af4a' AS uuid),
     'value1',
     'a0330000004KAwAAAW',
     '0063000000DE70wAAD',
     FALSE,
     FALSE,
     '2025-10-22 13:47:40.099937+00',
     '640323ce-7379-4eac-af8e-c19d39d4b4a3');


--
-- Clean up previous test data to make this script re-runnable
-- Delete only registration_history test data inserted by this script
DELETE FROM settlement_metadata."REGISTRATION_HISTORY"
WHERE registration_id IN (
          '6841cf09-0bca-449f-932c-ca3d759ef997',
          '77921141-91f0-4ff6-81c7-06798f1b9b25',
          '40e8a8b8-3416-4fae-a300-9193ef803868',
          'aa1d6815-b764-49fd-a21b-7933f29d095f',
          '102358d6-61a3-4af3-bd39-46ce2483f8fc'
      )
  AND product_id = 'eb073537-0e40-4178-aaca-bea9fae106cf'
  AND effective_start_dttm_utc >= '2025-01-01'::timestamptz
  AND effective_end_dttm_utc <= '9999-12-31'::timestamptz;

-- Delete only registration test data inserted by this script
DELETE FROM settlement_metadata."REGISTRATION"
WHERE registration_id IN (
          '6841cf09-0bca-449f-932c-ca3d759ef997',
          '77921141-91f0-4ff6-81c7-06798f1b9b25',
          '40e8a8b8-3416-4fae-a300-9193ef803868',
          'aa1d6815-b764-49fd-a21b-7933f29d095f',
          '102358d6-61a3-4af3-bd39-46ce2483f8fc'
      )
  AND product_id = 'eb073537-0e40-4178-aaca-bea9fae106cf';
--


--
-- INSERT the base registration records for FCAS Raise 5 Min
-- The registration_history table will be populated separately per scenario.
--
INSERT INTO settlement_metadata."REGISTRATION"
    (registration_id,
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
     last_updated_by)
VALUES
    -- 1
    (CAST('6841cf09-0bca-449f-932c-ca3d759ef997' AS uuid),
     'ACTIVE',
     CAST('eb073537-0e40-4178-aaca-bea9fae106cf' AS uuid),
     CAST('f334d38c-539a-4a14-877e-2c66e04ff8c5' AS uuid),
     NULL,
     CAST('ebbc7eaf-ff13-4b2c-95e8-053cfaf1a865' AS uuid),
     CAST('11a33679-7210-4603-8cc2-ae759ec7af4a' AS uuid),
     NULL,
     NULL,
     NULL,
     FALSE,
     TRUE,
     '2025-04-15 19:39:00.35716+00',
     'qa.user@example.com'),

    -- 2
    (CAST('77921141-91f0-4ff6-81c7-06798f1b9b25' AS uuid),
     'ACTIVE',
     CAST('eb073537-0e40-4178-aaca-bea9fae106cf' AS uuid),
     CAST('326e2cf0-2e7d-480b-b21b-fbc330d69548' AS uuid),
     NULL,
     CAST('0418d88f-c15f-4d23-b83f-6aff92e3b8ea' AS uuid),
     CAST('1711d2df-8bb9-4fc6-bdaa-16fca317c16f' AS uuid),
     NULL,
     NULL,
     NULL,
     FALSE,
     TRUE,
     '2025-05-12 20:47:13.854737+00',
     'qa.user@example.com'),

    -- 3
    (CAST('40e8a8b8-3416-4fae-a300-9193ef803868' AS uuid),
     'ACTIVE',
     CAST('eb073537-0e40-4178-aaca-bea9fae106cf' AS uuid),
     CAST('b65dad8a-82bb-4d1d-a2b0-bab31bcfc803' AS uuid),
     NULL,
     CAST('0418d88f-c15f-4d23-b83f-6aff92e3b8ea' AS uuid),
     CAST('1711d2df-8bb9-4fc6-bdaa-16fca317c16f' AS uuid),
     NULL,
     NULL,
     NULL,
     FALSE,
     TRUE,
     '2025-05-29 09:15:56.699862+00',
     'qa.user@example.com'),

    -- 4
    (CAST('aa1d6815-b764-49fd-a21b-7933f29d095f' AS uuid),
     'ACTIVE',
     CAST('eb073537-0e40-4178-aaca-bea9fae106cf' AS uuid),
     CAST('d9f0e6b3-daf3-4382-8910-0d1d5872a18a' AS uuid),
     NULL,
     CAST('0418d88f-c15f-4d23-b83f-6aff92e3b8ea' AS uuid),
     CAST('1711d2df-8bb9-4fc6-bdaa-16fca317c16f' AS uuid),
     NULL,
     NULL,
     NULL,
     FALSE,
     TRUE,
     '2025-05-29 09:15:56.148559+00',
     'qa.user@example.com'),

    -- 5
    (CAST('102358d6-61a3-4af3-bd39-46ce2483f8fc' AS uuid),
     'ACTIVE',
     CAST('eb073537-0e40-4178-aaca-bea9fae106cf' AS uuid),
     CAST('87351300-7b06-4810-9583-c760839934d5' AS uuid),
     NULL,
     CAST('ebbc7eaf-ff13-4b2c-95e8-053cfaf1a865' AS uuid),
     CAST('23d0be6f-962b-4bb9-a081-75cd70e0b785' AS uuid),
     NULL,
     NULL,
     NULL,
     FALSE,
     TRUE,
     '2025-09-01 05:10:49.211102+00',
     'qa.user@example.com');


--
-- Clean up previous test data to make this script re-runnable
-- Delete only registration_history test data inserted by this script
DELETE FROM settlement_metadata."REGISTRATION_HISTORY"
WHERE registration_id IN (
          'bb51891a-3853-4131-ac46-3a5fb5ea18bd',
          '61eacbe0-d853-4fd1-a50c-e32375475a70'
      )
  AND product_id = '1ef635c7-65b2-4945-bdcb-aa2606956cfd'
  AND effective_start_dttm_utc >= '2024-01-01'::timestamptz
  AND effective_end_dttm_utc <= '9999-12-31'::timestamptz;
--


--
-- INSERT registration history rows for 1-second rule
--
INSERT INTO settlement_metadata."REGISTRATION_HISTORY"
    (id,
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
     effective_start_dttm_utc,
     effective_end_dttm_utc,
     last_updated_by,
     last_updated_dttm_utc,
     portfolio_id,
     registration_set_id)
VALUES
    -- Row 19984: registration A, open-ended, deleted + needs_manual_fix
    (19984,
     CAST('bb51891a-3853-4131-ac46-3a5fb5ea18bd' AS uuid),
     'ACTIVE',
     CAST('1ef635c7-65b2-4945-bdcb-aa2606956cfd' AS uuid),
     CAST('87351300-7b06-4810-9583-c760839934d5' AS uuid),
     NULL,
     CAST('ebbc7eaf-ff13-4b2c-95e8-053cfaf1a865' AS uuid),
     CAST('23d0be6f-962b-4bb9-a081-75cd70e0b785' AS uuid),
     NULL,
     NULL,
     NULL,
     TRUE,
     TRUE,
     '2025-09-01 05:12:16.505166+00',
     '9999-12-31 00:00:00+00',
     'qa.user@example.com',
     '2025-09-01 05:12:16.505166+00',
     NULL,
     NULL),

    -- Row 19981: registration A, bounded range
    (19981,
     CAST('bb51891a-3853-4131-ac46-3a5fb5ea18bd' AS uuid),
     'ACTIVE',
     CAST('1ef635c7-65b2-4945-bdcb-aa2606956cfd' AS uuid),
     CAST('87351300-7b06-4810-9583-c760839934d5' AS uuid),
     NULL,
     CAST('ebbc7eaf-ff13-4b2c-95e8-053cfaf1a865' AS uuid),
     CAST('23d0be6f-962b-4bb9-a081-75cd70e0b785' AS uuid),
     NULL,
     NULL,
     NULL,
     FALSE,
     TRUE,
     '2025-09-01 04:59:46.384686+00',
     '2025-09-01 05:12:16.505166+00',
     'dc629188-a8eb-471f-b64c-cff5215c3809',
     '2025-09-01 04:59:46.384686+00',
     NULL,
     NULL),

    -- Row 22849: registration B, armed registration_set_id
    (22849,
     CAST('61eacbe0-d853-4fd1-a50c-e32375475a70' AS uuid),
     'ACTIVE',
     CAST('1ef635c7-65b2-4945-bdcb-aa2606956cfd' AS uuid),
     CAST('202463e3-996b-4d45-9a9a-50762400a1b3' AS uuid),
     NULL,
     CAST('3480cc3a-f1e2-4efc-b4c8-c8f9f4207068' AS uuid),
     CAST('11a33679-7210-4603-8cc2-ae759ec7af4a' AS uuid),
     '0013000000rUYRXAA4',
     'a033000000AzZxGAAV',
     '0064v000024bcy2AAA',
     FALSE,
     FALSE,
     '2024-01-01 00:00:00+00',
     '2025-10-22 13:47:40.099937+00',
     '640323ce-7379-4eac-af8e-c19d39d4b4a3',
     '2025-10-22 13:47:40.099937+00',
     CAST('5160ecb3-56ae-4705-ad53-e6f5bcb72d22' AS uuid),
     CAST('19d667cc-9c8b-466d-88b4-478604714380' AS uuid)),

    -- Row 23117: registration B, non-armed registration_set_id
    (23117,
     CAST('61eacbe0-d853-4fd1-a50c-e32375475a70' AS uuid),
     'ACTIVE',
     CAST('1ef635c7-65b2-4945-bdcb-aa2606956cfd' AS uuid),
     CAST('202463e3-996b-4d45-9a9a-50762400a1b3' AS uuid),
     NULL,
     CAST('3480cc3a-f1e2-4efc-b4c8-c8f9f4207068' AS uuid),
     CAST('11a33679-7210-4603-8cc2-ae759ec7af4a' AS uuid),
     '0013000000rUYRXAA4',
     'a033000000AzZxGAAV',
     '0064v000024bcy2AAA',
     FALSE,
     FALSE,
     '2025-10-22 13:47:40.099937+00',
     '9999-12-31 00:00:00+00',
     '640323ce-7379-4eac-af8e-c19d39d4b4a3',
     '2025-11-12 13:09:13.809023+00',
     CAST('4bbbaa16-bd16-4803-b1f5-1788a5a56e74' AS uuid),
     CAST('9999ecb3-56ae-4705-ad53-e6f5bcb72d22' AS uuid));

--
-- Clean up previous test data to make this script re-runnable
-- Delete only registration_history test data inserted by this script
DELETE FROM settlement_metadata."REGISTRATION_HISTORY"
WHERE registration_id IN (
          '6841cf09-0bca-449f-932c-ca3d759ef997',
          '77921141-91f0-4ff6-81c7-06798f1b9b25',
          '40e8a8b8-3416-4fae-a300-9193ef803868',
          'aa1d6815-b764-49fd-a21b-7933f29d095f',
          '102358d6-61a3-4af3-bd39-46ce2483f8fc'
      )
  AND product_id = 'eb073537-0e40-4178-aaca-bea9fae106cf'
  AND effective_start_dttm_utc >= '2024-01-01'::timestamptz
  AND effective_end_dttm_utc <= '9999-12-31'::timestamptz;
--


--
-- INSERT registration history rows for FCAS Raise 5 Min rule
--
INSERT INTO settlement_metadata."REGISTRATION_HISTORY"
    (id,
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
     effective_start_dttm_utc,
     effective_end_dttm_utc,
     last_updated_by,
     last_updated_dttm_utc,
     portfolio_id,
     registration_set_id)
VALUES
    -- 2400: reg 6841..., ON_HOLD with armed registration_set_id on alt asset
    (2400,
     CAST('6841cf09-0bca-449f-932c-ca3d759ef997' AS uuid),
     'ON_HOLD',
     CAST('eb073537-0e40-4178-aaca-bea9fae106cf' AS uuid),
     CAST('202463e3-996b-4d45-9a9a-50762400a1b3' AS uuid),
     NULL,
     CAST('ebbc7eaf-ff13-4b2c-95e8-053cfaf1a865' AS uuid),
     CAST('11a33679-7210-4603-8cc2-ae759ec7af4a' AS uuid),
     NULL,
     NULL,
     NULL,
     FALSE,
     TRUE,
     '2025-04-14 06:01:20.514813+00',
     '2025-04-14 06:03:31.663339+00',
     'qa.user@example.com',
     '2025-04-14 06:01:20.514813+00',
     NULL,
     CAST('19d667cc-9c8b-466d-88b4-478604714380' AS uuid)),

    -- 2531: reg 7792..., ACTIVE, no registration_set_id
    (2531,
     CAST('77921141-91f0-4ff6-81c7-06798f1b9b25' AS uuid),
     'ACTIVE',
     CAST('eb073537-0e40-4178-aaca-bea9fae106cf' AS uuid),
     CAST('326e2cf0-2e7d-480b-b21b-fbc330d69548' AS uuid),
     NULL,
     CAST('0418d88f-c15f-4d23-b83f-6aff92e3b8ea' AS uuid),
     CAST('1711d2df-8bb9-4fc6-bdaa-16fca317c16f' AS uuid),
     NULL,
     NULL,
     NULL,
     FALSE,
     TRUE,
     '2025-05-12 05:03:23.637556+00',
     '9999-12-31 00:00:00+00',
     'dc629188-a8eb-471f-b64c-cff5215c3809',
     '2025-05-12 05:03:23.637556+00',
     NULL,
     NULL),

    -- 14241: reg 40e8..., ACTIVE, armed registration_set_id
    (14241,
     CAST('40e8a8b8-3416-4fae-a300-9193ef803868' AS uuid),
     'ACTIVE',
     CAST('eb073537-0e40-4178-aaca-bea9fae106cf' AS uuid),
     CAST('b65dad8a-82bb-4d1d-a2b0-bab31bcfc803' AS uuid),
     NULL,
     CAST('0418d88f-c15f-4d23-b83f-6aff92e3b8ea' AS uuid),
     CAST('1711d2df-8bb9-4fc6-bdaa-16fca317c16f' AS uuid),
     NULL,
     NULL,
     NULL,
     FALSE,
     TRUE,
     '2025-05-29 09:14:09.598628+00',
     '9999-12-31 00:00:00+00',
     'dc629188-a8eb-471f-b64c-cff5215c3809',
     '2025-05-29 09:14:09.598628+00',
     NULL,
     CAST('19d667cc-9c8b-466d-88b4-478604714380' AS uuid)),

    -- 14242: reg aa1d..., ACTIVE, armed registration_set_id
    (14242,
     CAST('aa1d6815-b764-49fd-a21b-7933f29d095f' AS uuid),
     'ACTIVE',
     CAST('eb073537-0e40-4178-aaca-bea9fae106cf' AS uuid),
     CAST('d9f0e6b3-daf3-4382-8910-0d1d5872a18a' AS uuid),
     NULL,
     CAST('0418d88f-c15f-4d23-b83f-6aff92e3b8ea' AS uuid),
     CAST('1711d2df-8bb9-4fc6-bdaa-16fca317c16f' AS uuid),
     NULL,
     NULL,
     NULL,
     FALSE,
     TRUE,
     '2025-05-29 09:15:12.155057+00',
     '9999-12-31 00:00:00+00',
     'dc629188-a8eb-471f-b64c-cff5215c3809',
     '2025-05-29 09:15:12.155057+00',
     NULL,
     CAST('19d667cc-9c8b-466d-88b4-478604714380' AS uuid)),

    -- 667: reg 6841..., long ACTIVE armed range with portfolio
    (667,
     CAST('6841cf09-0bca-449f-932c-ca3d759ef997' AS uuid),
     'ACTIVE',
     CAST('eb073537-0e40-4178-aaca-bea9fae106cf' AS uuid),
     CAST('f334d38c-539a-4a14-877e-2c66e04ff8c5' AS uuid),
     NULL,
     CAST('ebbc7eaf-ff13-4b2c-95e8-053cfaf1a865' AS uuid),
     CAST('11a33679-7210-4603-8cc2-ae759ec7af4a' AS uuid),
     NULL,
     NULL,
     NULL,
     FALSE,
     FALSE,
     '2024-01-01 05:00:00+00',
     '2025-04-07 23:12:11.501208+00',
     '00000000-0000-0000-0000-000000000000',
     '2025-03-27 23:22:32.643191+00',
     CAST('5160ecb3-56ae-4705-ad53-e6f5bcb72d22' AS uuid),
     CAST('19d667cc-9c8b-466d-88b4-478604714380' AS uuid)),

    -- 19982: reg 1023..., ACTIVE armed range with portfolio
    (19982,
     CAST('102358d6-61a3-4af3-bd39-46ce2483f8fc' AS uuid),
     'ACTIVE',
     CAST('eb073537-0e40-4178-aaca-bea9fae106cf' AS uuid),
     CAST('87351300-7b06-4810-9583-c760839934d5' AS uuid),
     NULL,
     CAST('ebbc7eaf-ff13-4b2c-95e8-053cfaf1a865' AS uuid),
     CAST('23d0be6f-962b-4bb9-a081-75cd70e0b785' AS uuid),
     NULL,
     NULL,
     NULL,
     FALSE,
     TRUE,
     '2024-12-01 05:09:46.155426+00',
     '9999-12-31 00:00:00+00',
     'dc629188-a8eb-471f-b64c-cff5215c3809',
     '2025-09-01 05:09:46.155426+00',
     CAST('5160ecb3-56ae-4705-ad53-e6f5bcb72d22' AS uuid),
     CAST('19d667cc-9c8b-466d-88b4-478604714380' AS uuid)),

    -- 2401: reg 6841..., ON_HOLD armed window on main asset
    (2401,
     CAST('6841cf09-0bca-449f-932c-ca3d759ef997' AS uuid),
     'ON_HOLD',
     CAST('eb073537-0e40-4178-aaca-bea9fae106cf' AS uuid),
     CAST('f334d38c-539a-4a14-877e-2c66e04ff8c5' AS uuid),
     NULL,
     CAST('ebbc7eaf-ff13-4b2c-95e8-053cfaf1a865' AS uuid),
     CAST('11a33679-7210-4603-8cc2-ae759ec7af4a' AS uuid),
     NULL,
     NULL,
     NULL,
     FALSE,
     TRUE,
     '2025-04-14 06:03:31.663339+00',
     '2025-04-15 19:39:00.35716+00',
     'qa.user@example.com',
     '2025-04-14 06:03:31.663339+00',
     NULL,
     CAST('19d667cc-9c8b-466d-88b4-478604714380' AS uuid)),

    -- 2403: reg 6841..., ACTIVE armed open-ended
    (2403,
     CAST('6841cf09-0bca-449f-932c-ca3d759ef997' AS uuid),
     'ACTIVE',
     CAST('eb073537-0e40-4178-aaca-bea9fae106cf' AS uuid),
     CAST('f334d38c-539a-4a14-877e-2c66e04ff8c5' AS uuid),
     NULL,
     CAST('ebbc7eaf-ff13-4b2c-95e8-053cfaf1a865' AS uuid),
     CAST('11a33679-7210-4603-8cc2-ae759ec7af4a' AS uuid),
     NULL,
     NULL,
     NULL,
     FALSE,
     TRUE,
     '2025-04-15 19:39:00.35716+00',
     '9999-12-31 00:00:00+00',
     'qa.user@example.com',
     '2025-04-15 19:39:00.35716+00',
     NULL,
     CAST('19d667cc-9c8b-466d-88b4-478604714380' AS uuid));


--
--Insert into EPS db - event_node_workflow table
--
INSERT INTO event_node_workflow (
    event_node_id,
    event_id,
    alt_id,
    workflow_status,
    event_node_start_time,
    event_node_end_time,
    confirmed,
    opted_out,
    activation_time,
    initial_notif_time,
    follow_up_notif_time,
    curtail_time,
    restore_notif_time,
    restore_time,
    initial_notif_included,
    follow_up_notif_included,
    curtail_included,
    restore_notif_included,
    restore_included,
    curtail_complete,
    curtail_exception_detected,
    curtail_exception_resolved,
    restore_complete,
    restore_exception_detected,
    restore_exception_resolved,
    remove_from_workflow,
    cancelled,
    created_dttm,
    last_updated_dttm,
    cancelled_no_restore,
    cancelled_with_restore,
    trip_restore_offset,
    ufr_workflow,
    manual_trip_time,
    trip_exception_detected,
    trip_exception_resolved,
    trip_complete,
    tripped_notif_time,
    restore_trip_notif_time,
    restore_trip_time,
    tripped_notif_included,
    restore_trip_notif_included,
    registration_id,
    last_notification_sent,
    last_notification_sent_dttm,
    product_id,
    registration_display_labels,
    preauthorized,
    control_timeout,
    curtail_timeout,
    restore_timeout,
    manual_trip_timeout,
    initiated_curtail,
    initiated_restore,
    initiated_manual_trip,
    workflow_id,
    expected_capacity,
    expected_capacity_uom,
    control_type,
    curtail_exception_code,
    restore_exception_code,
    trip_exception_code,
    control_offset_override,
    initial_notif_automated,
    follow_up_notif_automated,
    curtail_automated,
    restore_notif_automated,
    restore_automated,
    initial_notif_fire_approved,
    follow_up_notif_fire_approved,
    curtail_fire_approved,
    restore_notif_fire_approved,
    restore_fire_approved,
    assignee,
    registration_set_id,
    registration_set_display_labels,
    registration_type,
    flexible_asset_id,
    restore_offset_override,
    initial_notif_time_override,
    restore_notif_time_override,
    declared_availability_value,
    control_type_override_reason
) VALUES (
    '68d51570-86f5-11f0-96d3-9d1ff10a48ac',
    '68622f60-86f5-11f0-baee-a9c1ecf5ff6d',
    NULL,
    'WORKFLOW_COMPLETE',
    '2025-09-01 05:34:59.104',
    '2025-10-28 19:27:25.498',
    NULL,
    NULL,
    '2025-09-01 05:35:03.505',
    NULL,
    NULL,
    '2025-09-01 05:34:59.104',
    '2025-10-28 19:27:25.498',
    '2025-10-28 19:27:25.498',
    FALSE,
    FALSE,
    TRUE,
    FALSE,
    TRUE,
    '2025-09-01 05:35:14.447',
    NULL,
    NULL,
    '2025-10-28 19:27:42.403',
    NULL,
    NULL,
    NULL,
    NULL,
    '2025-09-01 05:35:03.504',
    '2025-10-28 19:27:59.855',
    NULL,
    NULL,
    NULL,
    TRUE,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    '2025-10-28 19:27:25.498',
    '2025-10-28 19:27:25.498',
    TRUE,
    TRUE,
    '102358d6-61a3-4af3-bd39-46ce2483f8fc',
    '',
    NULL,
    'eb073537-0e40-4178-aaca-bea9fae106cf',
    '{"en_AU": "New Zealand Steel - Nominated Bids (NZSD - GLN0331)"}',
    TRUE,
    300000,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    5183,
    '177658.67',
    'kW',
    'MANUAL',
    NULL,
    NULL,
    NULL,
    NULL,
    FALSE,
    FALSE,
    TRUE,
    FALSE,
    TRUE,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    '19d667cc-9c8b-466d-88b4-478604714380',
    '{"en_AU": "New Zealand Steel - Nominated Bids (NZSD - GLN0331)"}',
    'LOAD',
    '87351300-7b06-4810-9583-c760839934d5',
    NULL,
    NULL,
    NULL,
    NULL,
    NULL
);

