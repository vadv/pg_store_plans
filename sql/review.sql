SET client_min_messages = 'error';
CREATE EXTENSION IF NOT EXISTS pg_store_plans;
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

SELECT pg_stat_statements_reset() IS NOT NULL AS previous_shmem_startup_hook_chained;

COPY (
  WITH plans(absent, disabled_false, disabled_true) AS (
    VALUES (
      $${
        "Plan": {
          "Node Type": "Seq Scan",
          "Relation Name": "t1",
          "Alias": "t1"
        }
      }$$,
      $${
        "Plan": {
          "Node Type": "Seq Scan",
          "Disabled": false,
          "Relation Name": "t1",
          "Alias": "t1"
        }
      }$$,
      $${
        "Plan": {
          "Node Type": "Seq Scan",
          "Disabled": true,
          "Relation Name": "t1",
          "Alias": "t1"
        }
      }$$
    )
  )
  SELECT pg_store_plans_normalize(absent)::jsonb =
           pg_store_plans_normalize(disabled_false)::jsonb
           AS disabled_false_ignored_by_normalize,
         pg_store_plans_normalize(absent)::jsonb =
           pg_store_plans_normalize(disabled_true)::jsonb
           AS disabled_true_ignored_by_normalize
  FROM plans
) TO STDOUT WITH CSV HEADER;

SET track_io_timing = on;
SET work_mem = '64kB';
SET pg_store_plans.log_analyze = on;
SET pg_store_plans.log_buffers = on;

SELECT pg_store_plans_reset();

DO $$
BEGIN
  IF current_setting('server_version_num')::int >= 170000 THEN
    PERFORM percentile_disc(0.5) WITHIN GROUP (ORDER BY g)
    FROM generate_series(1, 750000) AS g;
  END IF;
END
$$;

COPY (
  SELECT current_setting('server_version_num')::int < 170000 OR
         EXISTS (
           SELECT 1
           FROM pg_store_plans(false)
           WHERE temp_blks_written > 0
             AND blk_write_time > 0
         ) AS temp_write_time_recorded,
         current_setting('server_version_num')::int < 170000 OR
         EXISTS (
           SELECT 1
           FROM pg_store_plans(false)
           WHERE temp_blks_read > 0
             AND blk_read_time > 0
         ) AS temp_read_time_recorded
) TO STDOUT WITH CSV HEADER;

RESET pg_store_plans.log_buffers;
RESET pg_store_plans.log_analyze;
RESET work_mem;
RESET track_io_timing;

ALTER EXTENSION pg_store_plans UPDATE TO '2.0';
COPY (
  SELECT extversion = '2.0' AS downgraded_to_2_0
  FROM pg_extension
  WHERE extname = 'pg_store_plans'
) TO STDOUT WITH CSV HEADER;

ALTER EXTENSION pg_store_plans UPDATE TO '2.1';
COPY (
  SELECT extversion = '2.1' AS upgraded_to_2_1
  FROM pg_extension
  WHERE extname = 'pg_store_plans'
) TO STDOUT WITH CSV HEADER;
