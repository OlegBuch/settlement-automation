insert into "settlement_metadata"."PRODUCT_RULE" (product_id, name, last_updated_dttm_utc, last_updated_by)
values ('a4f41ab7-87e3-4639-9702-ec51a50e7de7', 'John test product rule 1', now(),
        cast('0000c6b8-aaaa-bbbb-cccc-f5ebae531111' as uuid));

insert into "settlement_metadata"."PR_FRAGMENT" (name, validator, description, last_updated_dttm_utc, last_updated_by)
values ('John test fragment 1', '{}', 'description', now(), cast('0000c6b8-aaaa-bbbb-cccc-f5ebae531111' as uuid));

insert into "settlement_metadata"."PRODUCT_RULE_PR_FRAGMENT" (pr_fragment_id, product_rule_id, last_updated_dttm_utc,
                                                              last_updated_by)
values ((select id from "settlement_metadata"."PR_FRAGMENT" where name = 'John test fragment 1'),
        (select id from "settlement_metadata"."PRODUCT_RULE" where product_id = 'a4f41ab7-87e3-4639-9702-ec51a50e7de7'),
        now(), cast('0000c6b8-aaaa-bbbb-cccc-f5ebae531111' as uuid));

insert into settlement_metadata."PR_FRAGMENT_PARAMETER" (pr_fragment_id, pr_parameter_def_id, required,last_updated_dttm_utc, last_updated_by)
values ((select id from "settlement_metadata"."PR_FRAGMENT" where name = 'John test fragment 1'),
        (select id from "settlement_metadata"."PR_PARAMETER_DEF" where name = 'SCHEDULED_SETTLEMENT_CREATION_SCHEDULE'),
        true, now(), cast('0000c6b8-aaaa-bbbb-cccc-f5ebae531111' as uuid));
insert into settlement_metadata."PR_FRAGMENT_PARAMETER" (pr_fragment_id, pr_parameter_def_id, required,last_updated_dttm_utc, last_updated_by)
values ((select id from "settlement_metadata"."PR_FRAGMENT" where name = 'John test fragment 1'),
        (select id from "settlement_metadata"."PR_PARAMETER_DEF" where name = 'SCHEDULED_SETTLEMENT_CREATION_PERIOD'),
        true, now(), cast('0000c6b8-aaaa-bbbb-cccc-f5ebae531111' as uuid));
insert into settlement_metadata."PR_FRAGMENT_PARAMETER" (pr_fragment_id, pr_parameter_def_id, required,last_updated_dttm_utc, last_updated_by)
values ((select id from "settlement_metadata"."PR_FRAGMENT" where name = 'John test fragment 1'),
        (select id from "settlement_metadata"."PR_PARAMETER_DEF" where name = 'SCHEDULED_SETTLEMENT_CREATION_TYPE'),
        true, now(), cast('0000c6b8-aaaa-bbbb-cccc-f5ebae531111' as uuid));
insert into settlement_metadata."PR_FRAGMENT_PARAMETER" (pr_fragment_id, pr_parameter_def_id, required,last_updated_dttm_utc, last_updated_by)
values ((select id from "settlement_metadata"."PR_FRAGMENT" where name = 'John test fragment 1'),
        (select id from "settlement_metadata"."PR_PARAMETER_DEF" where name = 'SCHEDULED_SETTLEMENT_CREATION_TIMEZONE'),
        true, now(), cast('0000c6b8-aaaa-bbbb-cccc-f5ebae531111' as uuid));

insert into settlement_metadata."PRODUCT_RULE_DETAIL" (product_rule_id, pr_parameter_def_id, value, start_dttm_utc,
                                                       end_dttm_utc, last_updated_dttm_utc, last_updated_by)
values ((select id from "settlement_metadata"."PRODUCT_RULE" where product_id = cast('a4f41ab7-87e3-4639-9702-ec51a50e7de7' as uuid)),
        (select id from "settlement_metadata"."PR_PARAMETER_DEF" where name = 'SCHEDULED_SETTLEMENT_CREATION_SCHEDULE'),
        '0120,0420,0720,1020', '1970-01-01', '9999-12-31', now(), cast('0000c6b8-aaaa-bbbb-cccc-f5ebae531111' as uuid));
insert into settlement_metadata."PRODUCT_RULE_DETAIL" (product_rule_id, pr_parameter_def_id, value, start_dttm_utc,
                                                       end_dttm_utc, last_updated_dttm_utc, last_updated_by)
values ((select id from "settlement_metadata"."PRODUCT_RULE" where product_id = cast('a4f41ab7-87e3-4639-9702-ec51a50e7de7' as uuid)),
        (select id from "settlement_metadata"."PR_PARAMETER_DEF" where name = 'SCHEDULED_SETTLEMENT_CREATION_PERIOD'),
        'PREVIOUS_3_FULL_MONTHS', '1970-01-01', '9999-12-31', now(),cast('0000c6b8-aaaa-bbbb-cccc-f5ebae531111' as uuid));
insert into settlement_metadata."PRODUCT_RULE_DETAIL" (product_rule_id, pr_parameter_def_id, value, start_dttm_utc,
                                                       end_dttm_utc, last_updated_dttm_utc, last_updated_by)
values ((select id from "settlement_metadata"."PRODUCT_RULE" where product_id = cast('a4f41ab7-87e3-4639-9702-ec51a50e7de7' as uuid)),
        (select id from "settlement_metadata"."PR_PARAMETER_DEF" where name = 'SCHEDULED_SETTLEMENT_CREATION_TYPE'),
        'ANCILLARY', '1970-01-01', '9999-12-31', now(), cast('0000c6b8-aaaa-bbbb-cccc-f5ebae531111' as uuid));
insert into settlement_metadata."PRODUCT_RULE_DETAIL" (product_rule_id, pr_parameter_def_id, value, start_dttm_utc,
                                                       end_dttm_utc, last_updated_dttm_utc, last_updated_by)
values ((select id from "settlement_metadata"."PRODUCT_RULE" where product_id = cast('a4f41ab7-87e3-4639-9702-ec51a50e7de7' as uuid)),
        (select id from "settlement_metadata"."PR_PARAMETER_DEF" where name = 'SCHEDULED_SETTLEMENT_CREATION_TIMEZONE'),
        'America/Los_Angeles', '1970-01-01', '9999-12-31', now(), cast('0000c6b8-aaaa-bbbb-cccc-f5ebae531111' as uuid));

