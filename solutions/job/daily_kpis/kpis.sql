-- SOLUTION (Challenge 2)
INSERT INTO `lab.daily_kpis`
  (execution, computed_at, order_date, country, product, orders, units, revenue)
SELECT
  @execution,
  CURRENT_TIMESTAMP(),
  order_date,
  country,
  product,
  COUNT(DISTINCT order_id) AS orders,
  SUM(quantity) AS units,
  ROUND(SUM(quantity * unit_price), 2) AS revenue
FROM `lab.orders_raw`
WHERE MOD(ABS(FARM_FINGERPRINT(country)), @task_count) = @task_index
GROUP BY order_date, country, product
