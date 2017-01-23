-- Test validity of relcache descriptor for pg_class indexes during REINDEX
set gp_validate_pt_info_relcache = on;
reindex index pg_class_oid_index;
reindex index pg_class_relname_nsp_index;
set gp_validate_pt_info_relcache = off;

-- Try updating the indexes after the REINDEX
create table validate_pt_info_relcache(a int) distributed by (a);
drop table validate_pt_info_relcache;