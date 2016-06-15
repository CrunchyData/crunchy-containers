SELECT current_database(), now(), sum(heap_blks_read) as reads, sum(heap_blks_hit) as hits, sum(heap_blks_read)/sum(heap_blks_hit)::float as hit_ratio FROM pg_statio_user_tables;
