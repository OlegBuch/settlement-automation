
delete from settlement_metadata."financial_point_mapping" where level_id IN (cast('9999588e-6224-41b6-953d-72864e7d52eb' as uuid), cast('8888588e-6224-41b6-953d-72864e7d52eb' as uuid));

/* minimum supported start_dttm_utc */

INSERT INTO settlement_metadata."financial_point_mapping" (level_id,level_type,financial_point_id,channel_id,financial_point_type,zone_id,start_dttm_utc,end_dttm_utc,last_updated_dttm_utc,last_updated_by)
VALUES
    (cast('9999588e-6224-41b6-953d-72864e7d52eb' as uuid),'registration',cast('5555588e-6224-41b6-953d-72864e7d52e0' as uuid),1,'measured_point',
     cast('000023ce-7379-4eac-af8e-c19d39d4b4a3' as uuid),(TIMESTAMP WITH TIME ZONE '1970-01-01 00:00:00 UTC'),(TIMESTAMP WITH TIME ZONE '1971-12-31 00:00:00 UTC'),now(),cast('640323ce-7379-4eac-af8e-c19d39d4b4a3' as uuid));

/* typical use case */

INSERT INTO settlement_metadata."financial_point_mapping" (level_id,level_type,financial_point_id,channel_id,financial_point_type,zone_id,start_dttm_utc,end_dttm_utc,last_updated_dttm_utc,last_updated_by)
VALUES
    (cast('9999588e-6224-41b6-953d-72864e7d52eb' as uuid),'registration',cast('5555588e-6224-41b6-953d-72864e7d52e1' as uuid),4010,'financial_point',
     cast('111123ce-7379-4eac-af8e-c19d39d4b4a3' as uuid),(TIMESTAMP WITH TIME ZONE '2024-08-01 00:00:00 UTC'),(TIMESTAMP WITH TIME ZONE '2025-01-02 00:00:00 UTC'),now(),cast('640323ce-7379-4eac-af8e-c19d39d4b4a3' as uuid));

/* start_dttm_utc far in the future */

INSERT INTO settlement_metadata."financial_point_mapping" (level_id,level_type,financial_point_id,channel_id,financial_point_type,zone_id,start_dttm_utc,end_dttm_utc,last_updated_dttm_utc,last_updated_by)
VALUES
    (cast('9999588e-6224-41b6-953d-72864e7d52eb' as uuid),'registration',cast('5555588e-6224-41b6-953d-72864e7d52e2' as uuid),4015,'external_point',
     cast('222223ce-7379-4eac-af8e-c19d39d4b4a3' as uuid),(TIMESTAMP WITH TIME ZONE '3000-01-01 00:00:00 UTC'),(TIMESTAMP WITH TIME ZONE '3002-01-02 00:00:00 UTC'),now(),cast('640323ce-7379-4eac-af8e-c19d39d4b4a3' as uuid));

/* deleted = true */

INSERT INTO settlement_metadata."financial_point_mapping" (deleted,level_id,level_type,financial_point_id,channel_id,financial_point_type,zone_id,start_dttm_utc,end_dttm_utc,last_updated_dttm_utc,last_updated_by)
VALUES
    (true,cast('9999588e-6224-41b6-953d-72864e7d52eb' as uuid),'registration',cast('5555588e-6224-41b6-953d-72864e7d52e3' as uuid),1,'measured_point',
     cast('333323ce-7379-4eac-af8e-c19d39d4b4a3' as uuid),(TIMESTAMP WITH TIME ZONE '2000-01-01 00:00:00 UTC'),(TIMESTAMP WITH TIME ZONE '3000-01-02 00:00:00 UTC'),now(),cast('640323ce-7379-4eac-af8e-c19d39d4b4a3' as uuid));

/* second registration, typical use case */

INSERT INTO settlement_metadata."financial_point_mapping" (level_id,level_type,financial_point_id,channel_id,financial_point_type,zone_id,start_dttm_utc,end_dttm_utc,last_updated_dttm_utc,last_updated_by)
VALUES
    (cast('8888588e-6224-41b6-953d-72864e7d52eb' as uuid),'registration',cast('7777588e-6224-41b6-953d-72864e7d52e1' as uuid),4016,'financial_point',
     cast('111123ce-7379-4eac-af8e-c19d39d4b4a3' as uuid),(TIMESTAMP WITH TIME ZONE '2024-08-01 00:00:00 UTC'),(TIMESTAMP WITH TIME ZONE '2025-01-02 00:00:00 UTC'),now(),cast('640323ce-7379-4eac-af8e-c19d39d4b4a3' as uuid));


commit;

select * from settlement_metadata."financial_point_mapping" where level_id IN (cast('9999588e-6224-41b6-953d-72864e7d52eb' as uuid), cast('8888588e-6224-41b6-953d-72864e7d52eb' as uuid));
