SET client_min_messages = 'error';
CREATE EXTENSION IF NOT EXISTS pg_store_plans;

WITH plans(title, tag, lplan) AS (
  VALUES
    ('incremental sort', '"t":"C"', $${
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
    ('memoize', '"t":"E"', $${
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
    ('tid range scan', '"t":"D"', $${
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
  SELECT title, tag, lplan, pg_store_plans_shorten(lplan) AS splan
  FROM plans
)
SELECT title,
       splan LIKE '%' || tag || '%' AS node_shortened,
       splan LIKE '%"ds":false%' AS disabled_shortened,
       pg_store_plans_jsonplan(splan)::jsonb = lplan::jsonb AS json_round_trip,
       pg_store_plans_textplan(splan) IS NOT NULL AS text_ok,
       pg_store_plans_yamlplan(splan) IS NOT NULL AS yaml_ok,
       pg_store_plans_xmlplan(splan) IS NOT NULL AS xml_ok
FROM converted
ORDER BY title;

SELECT pg_store_plans_textplan(pg_store_plans_shorten($${
  "Plan": {
    "Node Type": "ModifyTable",
    "Relation Name": "t_missing_operation",
    "Alias": "t_missing_operation"
  }
}$$)) IS NOT NULL AS modify_without_operation_text_ok;
