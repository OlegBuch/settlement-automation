/* StmItemCreator.feature */

set time zone 'UTC';

set time zone 'America/Edmonton';

select * from settlement_metadata."REGISTRATION_HISTORY" where product_id ='a1643547-425b-4856-8177-524371fa77e6' and status = 'ACTIVE';

/* Basic history */

INSERT INTO settlement_metadata."REGISTRATION_HISTORY" (registration_id,status,product_id,flexible_asset_id,service_delivery_point_id,org_id,site_id,ecrm_account_id,ecrm_site_id,ecrm_opportunity_id,deleted,needs_manual_fix,effective_start_dttm_utc,effective_end_dttm_utc,last_updated_by,last_updated_dttm_utc)
VALUES
    (cast('3a0cf195-c7bd-4080-bad5-27a8ead39088' as uuid),'ACTIVE',cast('a1643547-425b-4856-8177-524371fa77e6' as uuid),cast('93ebc99d-4db1-4eb8-851f-d735a4f7f2d5' as uuid),cast(NULL as uuid),cast('de0c933f-c600-49a0-894e-c8507da52521' as uuid),cast('efecfd01-4891-4143-b5f4-fc5d945cbee3' as uuid),'001a000001GffPOAAZ','a03a000000Ff6kQAAR','0064v000020lYZhAAM',false,false,'2024-07-01 06:00:00.000000 +0000'::timestamptz,'2025-01-01 00:00:00.000000 +0000'::timestamptz,'640323ce-7379-4eac-af8e-c19d39d4b4a3',now()),
    (cast('8b482904-ab52-4cc2-afff-914c59664b4b' as uuid),'ACTIVE',cast('a1643547-425b-4856-8177-524371fa77e6' as uuid),cast('befe58e2-baba-442e-ab9d-7597703637d2' as uuid),cast(NULL as uuid),cast('de0c933f-c600-49a0-894e-c8507da52521' as uuid),cast('7b36d040-4e47-4450-9b84-a97c0b55ec3f' as uuid),'001a000001GffPOAAZ','a03a000000Ff6kOAAR','0064v000020lYZhAAM',false,false,'2024-10-01 06:00:00.000000 +0000'::timestamptz,'2025-01-01 00:00:00.000000 +0000'::timestamptz,'640323ce-7379-4eac-af8e-c19d39d4b4a3',now());


/* Scenario: Registration has jitter in middle of settlement period */

select * from settlement_metadata."REGISTRATION_HISTORY" where registration_id = '492826a4-ed56-4aff-bf45-6eedaa93c918';

INSERT INTO settlement_metadata."REGISTRATION_HISTORY" (registration_id,status,product_id,flexible_asset_id,service_delivery_point_id,org_id,site_id,ecrm_account_id,ecrm_site_id,ecrm_opportunity_id,deleted,needs_manual_fix,effective_start_dttm_utc,effective_end_dttm_utc,last_updated_by,last_updated_dttm_utc)
VALUES
    (cast('492826a4-ed56-4aff-bf45-6eedaa93c918' as uuid),'ACTIVE',cast('a1643547-425b-4856-8177-524371fa77e6' as uuid),cast('93ebc99d-4db1-4eb8-851f-d735a4f7f2d5' as uuid),cast(NULL as uuid),cast('de0c933f-c600-49a0-894e-c8507da52521' as uuid),cast('efecfd01-4891-4143-b5f4-fc5d945cbee3' as uuid),'001a000001GffPOAAZ','a03a000000Ff6kQAAR','0064v000020lYZhAAM',false,false,'2024-03-01 07:00:00.000000 +0000'::timestamptz,'2024-03-10 02:01:00.000000 +0000'::timestamptz,'640323ce-7379-4eac-af8e-c19d39d4b4a3',now()),
    (cast('492826a4-ed56-4aff-bf45-6eedaa93c918' as uuid),'ACTIVE',cast('99943547-425b-4856-8177-524371fa77e6' as uuid),cast('999e58e2-baba-442e-ab9d-7597703637d2' as uuid),cast(NULL as uuid),cast('999c933f-c600-49a0-894e-c8507da52521' as uuid),cast('9996d040-4e47-4450-9b84-a97c0b55ec3f' as uuid),'999a000001GffPOAAZ','999a000000Ff6kOAAR','0064v000020lYZhAAM',false,true,'2024-03-10 02:01:00.000000 +0000'::timestamptz,'2024-03-10 02:59:00.000000 +0000'::timestamptz,'640323ce-7379-4eac-af8e-c19d39d4b4a3',now()),
    (cast('492826a4-ed56-4aff-bf45-6eedaa93c918' as uuid),'ACTIVE',cast('a1643547-425b-4856-8177-524371fa77e6' as uuid),cast('befe58e2-baba-442e-ab9d-7597703637d2' as uuid),cast(NULL as uuid),cast('de0c933f-c600-49a0-894e-c8507da52521' as uuid),cast('7b36d040-4e47-4450-9b84-a97c0b55ec3f' as uuid),'001a000001GffPOAAZ','a03a000000Ff6kOAAR','0064v000020lYZhAAM',false,false,'2024-03-10 02:59:00.000000 +0000'::timestamptz,'2024-04-01 07:00:00.000000 +0000'::timestamptz,'640323ce-7379-4eac-af8e-c19d39d4b4a3',now());

UPDATE settlement_metadata."REGISTRATION_HISTORY" SET product_id = 'a1643547-425b-4856-8177-524371fa77e6' where id = 420;