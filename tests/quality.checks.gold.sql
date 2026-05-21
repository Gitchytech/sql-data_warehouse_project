/*
===========================================================================================
Quality Checks
===========================================================================================
Script Purpose:
  The script performs quality checks to validate the integrity, consistency, and 
  accuracy of the Gold Layer. The checks ensure:
    - Uniqueness of surrogate keys in dimension tables.
    - Referential integrity between fact and dimension tables.
    - Validation of relationships in the data model for analytical purposes.

Usage Notes:
  - Run these checks after data loading the Silver Layer
  - Investigate and resolve any discrepancies found during the checks.
==========================================================================================
*/

-- =======================================================================================
-- Checking 'gold.dim_customers'
-- =======================================================================================
-- Check for uniqueness of customers in gold.dim_customers
SELECT
  customer_key,
  COUNT(*) AS duplicate_count
FROM gold.dim_customers
GROUP BY customer_key
HAVING COUNT(*) > 1;

-- Check for uniqueness of gender 
SELECT DISTINCT 
  gender 
FROM gold.dim_customers;

-- =====================================================================================
-- Checking 'gold.dim_products
-- =====================================================================================
-- Checking for the uniqueness of the product key
SELECT 
  prduct_key, 
  COUNT(*) AS duplicate_count
FROM gold.dim_products
 GROUP BY product_key
HAVING COUNT(*) > 1

-- =====================================================================================
-- Checking 'gold.fact_sales'
-- =====================================================================================
-- Check the data model connectivity between fact and dimensions
SELECT * 
FROM gold.fact_sales f
LEFT JOIN gold.dim_customers c
ON c.customer_key = f.customer_key
LEFT JOIN gold.dim_products p
ON p.product_key = f.product_key
WHERE p.product_key IS NULL OR c.customer_key IS NULL  


