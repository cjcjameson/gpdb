SELECT relname , b.relid, visimaprelid, visimapidxid
FROM pg_class a , pg_appendonly b
WHERE a.oid = b.relid AND a.relname = 'aoco_4_3';