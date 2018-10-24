DROP TABLE IF EXISTS t_random;
CREATE TABLE t_random AS SELECT s, md5(random()::text) FROM generate_series(1,50) s;
