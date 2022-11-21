SET client_min_messages = 'error';
CREATE EXTENSION IF NOT EXISTS pg_store_plans;
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
SELECT pg_stat_statements_reset();
SELECT pg_store_plans_reset(); -- collision with plan id
SELECT 'sleep' as regress, pg_sleep(0.1);
SELECT sum(p.calls) FROM pg_stat_statements s JOIN pg_store_plans p ON (s.queryid = p.queryid_stat_statements) JOIN pg_database d ON (d.oid = s.dbid) WHERE  s.query = 'SELECT $1 as regress, pg_sleep($2)';
SET pg_store_plans.min_duration TO '1s';
SELECT 'sleep' as regress, pg_sleep(0.1);
SELECT sum(p.calls) FROM pg_stat_statements s JOIN pg_store_plans p ON (s.queryid = p.queryid_stat_statements) JOIN pg_database d ON (d.oid = s.dbid) WHERE s.query = 'SELECT $1 as regress, pg_sleep($2)';
SET pg_store_plans.slow_statement_duration TO '1ms';
SELECT 'sleep' as regress, pg_sleep(0.1);
SELECT sum(p.calls) FROM pg_stat_statements s JOIN pg_store_plans p ON (s.queryid = p.queryid_stat_statements) JOIN pg_database d ON (d.oid = s.dbid) WHERE s.query = 'SELECT $1 as regress, pg_sleep($2)';
