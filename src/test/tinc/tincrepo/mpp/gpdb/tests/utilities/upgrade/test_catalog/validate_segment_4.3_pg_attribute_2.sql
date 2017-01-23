select p.relname, a.attname , a.attstattarget , a.attlen , a.attnum , a.attndims , a.attcacheoff , a.atttypmod , a.attbyval , a.attstorage , a.attalign , a.attnotnull , a.atthasdef , a.attisdropped , a.attislocal , a.attinhcount from gp_dist_random('pg_attribute') a, gp_dist_random('pg_class') p where p.relfilenode = a.attrelid  and p.relname not like 'pg_toast%' order by p.relname, a.attname, a.attnum, a.attlen ;