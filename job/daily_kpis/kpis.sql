-- ------------------------------------------------------------------
-- TODO (Challenge 2): complete this query.
--
-- For each order_date, country and product, calculate:
--   orders   -> number of different orders     (hint: COUNT(DISTINCT ...))
--   units    -> total quantity sold            (hint: SUM(...))
--   revenue  -> quantity * unit_price, summed and rounded to 2 decimals
--
-- Each task must only process ITS countries. Keep this filter as it is:
--   MOD(ABS(FARM_FINGERPRINT(country)), @task_count) = @task_index
-- It gives every country to exactly one task.
--
-- You can test the SELECT part in the BigQuery console first
-- (replace @task_count with 1 and @task_index with 0).
-- ------------------------------------------------------------------
INSERT INTO `lab.daily_kpis`
  (execution, computed_at, order_date, country, product, orders, units, revenue)
SELECT
  @execution,
  CURRENT_TIMESTAMP(),
  order_date,
  country,
  product,
  0 AS orders,      -- TODO
  0 AS units,       -- TODO
  0.0 AS revenue    -- TODO
FROM `lab.orders_raw`
WHERE MOD(ABS(FARM_FINGERPRINT(country)), @task_count) = @task_index
GROUP BY order_date, country, product
