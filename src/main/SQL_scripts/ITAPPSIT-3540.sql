
-- ITAPPSIT-3540: settlement MVP test: COM offers includes opt-outs

/*
For this test, we need to:
1. hard-delete the existing settlement, items, and intervals for AESO June 2025
2. create the COM opt-outs
3. trigger the monthly job for June 2025
4. verify the results
*/

-- Step 1. Delete intervals, items, and settlement. Use the existing settlement_id.

begin;
delete from settlement_item_intervals where settlement_item_id IN (select settlement_item_id from settlement_items where settlement_id = 'c7ad4af6-b287-4182-be81-5db76640870b');
delete from settlement_items where settlement_item_id IN (select settlement_item_id from settlement_items where settlement_id = 'c7ad4af6-b287-4182-be81-5db76640870b');
delete from settlements where settlement_id = 'c7ad4af6-b287-4182-be81-5db76640870b';
commit;
end;

-- Step 4: Verify results. Use the settlement id created by the pipeline job.

select * from settlements where settlement_id = '4dded4f8-d7f2-4064-ba8a-a6041e066aa1';

select settlement_item_status, processing_status, last_updated_dttm_utc, * from settlement_items where settlement_id = '4dded4f8-d7f2-4064-ba8a-a6041e066aa1';

select count(*), settlement_item_id from settlement_item_intervals where settlement_item_id IN
                                                                         (select settlement_item_id from settlement_items where settlement_id = '4dded4f8-d7f2-4064-ba8a-a6041e066aa1') group by settlement_item_id;
