SET client_min_messages = 'error';
CREATE EXTENSION IF NOT EXISTS pg_store_plans;

COPY (
  WITH plans(title, min_version, tag, lplan) AS (
    VALUES
      ('incremental sort', 130000, '"t":"C"', $${
        "Plan": {
          "Node Type": "Incremental Sort",
          "Async Capable": false,
          "Disabled": false,
          "Presorted Key": ["a"],
          "Sort Key": ["a", "b"],
          "Plans": [
            {
              "Node Type": "Seq Scan",
              "Relation Name": "t1",
              "Alias": "t1"
            }
          ]
        }
      }$$),
      ('memoize', 140000, '"t":"E"', $${
        "Plan": {
          "Node Type": "Memoize",
          "Async Capable": false,
          "Disabled": false,
          "Plans": [
            {
              "Node Type": "Index Scan",
              "Scan Direction": "Forward",
              "Index Name": "t1_a_idx",
              "Relation Name": "t1",
              "Alias": "t1"
            }
          ]
        }
      }$$),
      ('tid range scan', 140000, '"t":"D"', $${
        "Plan": {
          "Node Type": "Tid Range Scan",
          "Async Capable": false,
          "Disabled": false,
          "Relation Name": "t1",
          "Alias": "t1"
        }
      }$$)
  ),
  converted AS (
    SELECT title, min_version, tag, lplan, pg_store_plans_shorten(lplan) AS splan
    FROM plans
  )
  SELECT title,
         (splan LIKE '%' || tag || '%') =
           (current_setting('server_version_num')::int >= min_version)
           AS node_shortened_for_version,
         splan LIKE '%"ds":false%' AS disabled_shortened,
         pg_store_plans_jsonplan(splan)::jsonb = lplan::jsonb AS json_round_trip,
         pg_store_plans_textplan(splan) IS NOT NULL AS text_ok,
         pg_store_plans_yamlplan(splan) IS NOT NULL AS yaml_ok,
         pg_store_plans_xmlplan(splan) IS NOT NULL AS xml_ok
  FROM converted
  ORDER BY title
) TO STDOUT WITH CSV HEADER;

COPY (
  WITH plans(title, lplan) AS (
    VALUES
      ('disabled true', $${
        "Plan": {
          "Node Type": "Seq Scan",
          "Disabled": true,
          "Relation Name": "t1",
          "Alias": "t1"
        }
      }$$),
      ('disabled false', $${
        "Plan": {
          "Node Type": "Seq Scan",
          "Disabled": false,
          "Relation Name": "t1",
          "Alias": "t1"
        }
      }$$),
      ('disabled absent', $${
        "Plan": {
          "Node Type": "Seq Scan",
          "Relation Name": "t1",
          "Alias": "t1"
        }
      }$$),
      ('disabled invalid', $${
        "Plan": {
          "Node Type": "Seq Scan",
          "Disabled": "invalid",
          "Relation Name": "t1",
          "Alias": "t1"
        }
      }$$)
  ),
  converted AS (
    SELECT title,
           lplan,
           pg_store_plans_shorten(lplan) AS splan
    FROM plans
  )
  SELECT title,
         CASE title
           WHEN 'disabled true' THEN
             splan LIKE '%"ds":true%' AND
             pg_store_plans_jsonplan(splan)::jsonb = lplan::jsonb AND
             pg_store_plans_textplan(splan) LIKE '%Disabled: true%' AND
             pg_store_plans_yamlplan(splan) LIKE '%Disabled: true%' AND
             pg_store_plans_xmlplan(splan) LIKE '%<Disabled>true</Disabled>%'
           WHEN 'disabled false' THEN
             splan LIKE '%"ds":false%' AND
             pg_store_plans_textplan(splan) NOT LIKE '%Disabled:%'
           WHEN 'disabled absent' THEN
             splan NOT LIKE '%"ds"%' AND
             pg_store_plans_textplan(splan) NOT LIKE '%Disabled:%'
           ELSE
             splan LIKE '%"ds":"invalid"%' AND
             pg_store_plans_textplan(splan) NOT LIKE '%Disabled:%'
         END AS disabled_behavior_ok
  FROM converted
  ORDER BY title
) TO STDOUT WITH CSV HEADER;

CREATE OR REPLACE FUNCTION pgsp_explain_json(query text) RETURNS text AS $$
DECLARE
  line text;
  result text := '';
BEGIN
  FOR line IN EXECUTE 'EXPLAIN (FORMAT JSON) ' || query LOOP
    result := result || line;
  END LOOP;
  RETURN result;
END
$$ LANGUAGE plpgsql;

CREATE TEMP TABLE pgsp_disabled_t(a int);
SET enable_seqscan TO off;

COPY (
  WITH plan AS (
    SELECT (pgsp_explain_json('SELECT * FROM pgsp_disabled_t')::json->0)::text AS lplan
  ),
  converted AS (
    SELECT lplan, pg_store_plans_shorten(lplan) AS splan
    FROM plan
  )
  SELECT current_setting('server_version_num')::int < 180000 OR
         (
           lplan LIKE '%"Disabled": true%' AND
           splan LIKE '%"ds":true%' AND
           pg_store_plans_jsonplan(splan)::jsonb = lplan::jsonb AND
           pg_store_plans_textplan(splan) LIKE '%Disabled: true%' AND
           pg_store_plans_yamlplan(splan) LIKE '%Disabled: true%' AND
           pg_store_plans_xmlplan(splan) LIKE '%<Disabled>true</Disabled>%'
         ) AS real_disabled_true_ok
  FROM converted
) TO STDOUT WITH CSV HEADER;

RESET enable_seqscan;
DROP TABLE pgsp_disabled_t;
DROP FUNCTION pgsp_explain_json(text);

COPY (
  WITH normalized AS (
    SELECT pg_store_plans_normalize($${
      "Plan": {
        "Node Type": "Result",
        "Output": ["true", "false", "NULL", "LOCALTIME", "LOCALTIMESTAMP"]
      }
    }$$) AS plan
  )
  SELECT length(plan) - length(replace(plan, '?', '')) = 5 AND
         plan !~* '(true|false|null|localtime|localtimestamp)' AS const_tokens_normalized
  FROM normalized
) TO STDOUT WITH CSV HEADER;

SELECT pg_store_plans_textplan(pg_store_plans_shorten($${
  "Plan": {
    "Node Type": "ModifyTable",
    "Relation Name": "t_missing_operation",
    "Alias": "t_missing_operation"
  }
}$$)) IS NOT NULL AS modify_without_operation_text_ok;
