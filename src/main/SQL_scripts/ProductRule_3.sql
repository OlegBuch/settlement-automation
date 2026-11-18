insert into "settlement_metadata"."PRODUCT_RULE" (product_id, name, last_updated_dttm_utc, last_updated_by)
values ('bd035624-4ca9-4211-867d-ab52fa47c693', 'John test product rule 3', now(),
        cast('0000c6b8-aaaa-bbbb-cccc-f5ebae531111' as uuid));

insert into "settlement_metadata"."PR_FRAGMENT" (name, validator, description, last_updated_dttm_utc, last_updated_by)
values ('John test fragment 3', '{}', 'description', now(), cast('0000c6b8-aaaa-bbbb-cccc-f5ebae531111' as uuid));

insert into "settlement_metadata"."PRODUCT_RULE_PR_FRAGMENT" (pr_fragment_id, product_rule_id, last_updated_dttm_utc,
                                                              last_updated_by)
values ((select id from "settlement_metadata"."PR_FRAGMENT" where name = 'John test fragment 3'),
        (select id from "settlement_metadata"."PRODUCT_RULE" where product_id = 'bd035624-4ca9-4211-867d-ab52fa47c693'),
        now(), cast('0000c6b8-aaaa-bbbb-cccc-f5ebae531111' as uuid));

insert into settlement_metadata."PR_FRAGMENT_PARAMETER" (pr_fragment_id, pr_parameter_def_id, required,last_updated_dttm_utc, last_updated_by)
values ((select id from "settlement_metadata"."PR_FRAGMENT" where name = 'John test fragment 3'),
        (select id from "settlement_metadata"."PR_PARAMETER_DEF" where name = 'SCHEDULED_SETTLEMENT_CREATION_SCHEDULE'),
        true, now(), cast('0000c6b8-aaaa-bbbb-cccc-f5ebae531111' as uuid));
insert into settlement_metadata."PR_FRAGMENT_PARAMETER" (pr_fragment_id, pr_parameter_def_id, required,last_updated_dttm_utc, last_updated_by)
values ((select id from "settlement_metadata"."PR_FRAGMENT" where name = 'John test fragment 3'),
        (select id from "settlement_metadata"."PR_PARAMETER_DEF" where name = 'SCHEDULED_SETTLEMENT_CREATION_PERIOD'),
        true, now(), cast('0000c6b8-aaaa-bbbb-cccc-f5ebae531111' as uuid));
insert into settlement_metadata."PR_FRAGMENT_PARAMETER" (pr_fragment_id, pr_parameter_def_id, required,last_updated_dttm_utc, last_updated_by)
values ((select id from "settlement_metadata"."PR_FRAGMENT" where name = 'John test fragment 3'),
        (select id from "settlement_metadata"."PR_PARAMETER_DEF" where name = 'SCHEDULED_SETTLEMENT_CREATION_TYPE'),
        true, now(), cast('0000c6b8-aaaa-bbbb-cccc-f5ebae531111' as uuid));
insert into settlement_metadata."PR_FRAGMENT_PARAMETER" (pr_fragment_id, pr_parameter_def_id, required,last_updated_dttm_utc, last_updated_by)
values ((select id from "settlement_metadata"."PR_FRAGMENT" where name = 'John test fragment 3'),
        (select id from "settlement_metadata"."PR_PARAMETER_DEF" where name = 'SCHEDULED_SETTLEMENT_CREATION_TIMEZONE'),
        true, now(), cast('0000c6b8-aaaa-bbbb-cccc-f5ebae531111' as uuid));

insert into settlement_metadata."PRODUCT_RULE_DETAIL" (product_rule_id, pr_parameter_def_id, value, start_dttm_utc,
                                                       end_dttm_utc, last_updated_dttm_utc, last_updated_by)
values ((select id from "settlement_metadata"."PRODUCT_RULE" where product_id = cast('bd035624-4ca9-4211-867d-ab52fa47c693' as uuid)),
        (select id from "settlement_metadata"."PR_PARAMETER_DEF" where name = 'SCHEDULED_SETTLEMENT_CREATION_SCHEDULE'),
        '0125,0425,0725,1025', '1970-01-01', '9999-12-31', now(), cast('0000c6b8-aaaa-bbbb-cccc-f5ebae531111' as uuid));
insert into settlement_metadata."PRODUCT_RULE_DETAIL" (product_rule_id, pr_parameter_def_id, value, start_dttm_utc,
                                                       end_dttm_utc, last_updated_dttm_utc, last_updated_by)
values ((select id from "settlement_metadata"."PRODUCT_RULE" where product_id = cast('bd035624-4ca9-4211-867d-ab52fa47c693' as uuid)),
        (select id from "settlement_metadata"."PR_PARAMETER_DEF" where name = 'SCHEDULED_SETTLEMENT_CREATION_PERIOD'),
        'PREVIOUS_3_FULL_MONTHS', '1970-01-01', '9999-12-31', now(),cast('0000c6b8-aaaa-bbbb-cccc-f5ebae531111' as uuid));
insert into settlement_metadata."PRODUCT_RULE_DETAIL" (product_rule_id, pr_parameter_def_id, value, start_dttm_utc,
                                                       end_dttm_utc, last_updated_dttm_utc, last_updated_by)
values ((select id from "settlement_metadata"."PRODUCT_RULE" where product_id = cast('bd035624-4ca9-4211-867d-ab52fa47c693' as uuid)),
        (select id from "settlement_metadata"."PR_PARAMETER_DEF" where name = 'SCHEDULED_SETTLEMENT_CREATION_TYPE'),
        'ANCILLARY', '1970-01-01', '9999-12-31', now(), cast('0000c6b8-aaaa-bbbb-cccc-f5ebae531111' as uuid));
insert into settlement_metadata."PRODUCT_RULE_DETAIL" (product_rule_id, pr_parameter_def_id, value, start_dttm_utc,
                                                       end_dttm_utc, last_updated_dttm_utc, last_updated_by)
values ((select id from "settlement_metadata"."PRODUCT_RULE" where product_id = cast('bd035624-4ca9-4211-867d-ab52fa47c693' as uuid)),
        (select id from "settlement_metadata"."PR_PARAMETER_DEF" where name = 'SCHEDULED_SETTLEMENT_CREATION_TIMEZONE'),
        'Asia/Taipei', '1970-01-01', '9999-12-31', now(), cast('0000c6b8-aaaa-bbbb-cccc-f5ebae531111' as uuid));

