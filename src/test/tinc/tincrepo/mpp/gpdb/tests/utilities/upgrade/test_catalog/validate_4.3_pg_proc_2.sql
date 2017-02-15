select proname, proowner, prolang, proisagg, prosecdef, proisstrict, proretset, provolatile, pronargs, prorettype, proiswin, proargtypes, proallargtypes, proargmodes, proargnames, prosrc, probin, proacl, prodataaccess from pg_proc where pronamespace<>(select oid from pg_namespace where nspname='gp_toolkit') order by 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,19; 