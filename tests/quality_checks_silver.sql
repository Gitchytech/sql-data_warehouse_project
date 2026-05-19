/*
==========================================================================================
Quality Checks
==========================================================================================
Script Purpose:
  This script performs various quality checks for data consistency, accuracy, and
  standardization across the 'silver' schema.
  It includes checks for:
    - Null or duplicate primary keys.
    - Unwanted spaces in string fields.
    - Data standardization and consistency.
    - Invalid date ranges and orders.
    - Data consistency between related fields.

Usage Notes:
  - Run these checks after loading data in the Silver Layer
  - Investigate and resolve any discrepancies found during the checks.
==========================================================================================
*/
==========================================================================================
-- Checking 'silver.crm_cust_info'
==========================================================================================
-- Checking for Nulls or Duplicates in the Primary Key
-- Expectation: No Result
SELECT
cst_id,
COUNT(*)
FROM bronze.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL;

-- Rank using create date and pick the most recent entry

SELECT
*
FROM (
SELECT 
*,
ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last 
FROM bronze.crm_cust_info
) t WHERE flag_last = 1;

-- Data Standardization & Consistency
SELECT DISTINCT cst_gndr
FROM bronze.crm_cust_info

SELECT
cst_firstname
FROM silver.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname);


==========================================================================================
-- Checking 'silver.crm_prd_info'
==========================================================================================
-- Quality Checks
-- Check for Nulls or Duplicates in primary key
-- Expectation: No Result

SELECT prd_id,
COUNT(*)
FROM silver.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) >1 OR prd_id IS NULL

-- CHECK FOR UNWANTED SPACES
-- EXPECTATION: No Result
SELECT prd_nm
FROM silver.crm_prd_info
WHERE prd_nm != TRIM(prd_nm)

-- Check for NULLS or Negative Numbers
-- Expectation: No Results
SELECT prd_nm
FROM silver.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL

-- Data Standardization & Consistency
SELECT DISTINCT prd_line
FROM silver.crm_prd_info

-- Check for Invalid Date Orders
SELECT *
FROM silver.crm_prd_info
WHERE prd_end_dt < prd_start_dt

==========================================================================================
-- Checking 'silver.crm_sls_details'
==========================================================================================

-- Check for Invalid Dates
SELECT
NULLIF(sls_order_dt, 0) sls_order_dt
FROM bronze.crm_sales_details
WHERE sls_order_dt <= 0 
OR lEN(sls_order_dt) !=8 
OR sls_order_dt > 20500101
OR sls_order_dt < 19000101

SELECT
NULLIF(sls_ship_dt, 0) sls_order_dt
FROM bronze.crm_sales_details
WHERE sls_ship_dt <= 0 
OR lEN(sls_ship_dt) !=8 
OR sls_ship_dt > 20500101
OR sls_ship_dt < 19000101

SELECT
NULLIF(sls_due_dt, 0) sls_due_dt
FROM bronze.crm_sales_details
WHERE sls_due_dt <= 0 
OR lEN(sls_due_dt) !=8 
OR sls_due_dt > 20500101
OR sls_due_dt < 19000101  

SELECT
*
FROM bronze.crm_sales_details
WHERE sls_order_dt > sls_ship_dt OR sls_order_dt > sls_due_dt 

-- CHECK DATA CONSISTENCY: Between Sales, Quantity, and Price
-- >> Sales = Quantity * Price
-- >> Values must not be Null, zero or negative.



SELECT DISTINCT
sls_sales,
sls_quantity,
sls_price
FROM bronze.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price <= 0
ORDER BY sls_sales, sls_quantity, sls_price;


-- Rules: 
	--> If sales is negative, zero or null, derive it using quantity and price
	--> If price is zero or null, calcualate using sales and quantity
	--> If price is negative, convert it to a positive value
SELECT DISTINCT
sls_sales AS old_sls_sales,
sls_quantity,
sls_price AS old_sls_price,
CASE WHEN sls_sales IS NULL OR sls_sales <=0 OR sls_sales !=sls_quantity * ABS(sls_price)
		THEN sls_quantity *  ABS(sls_price)
	ELSE sls_sales
END AS sls_sales,

CASE WHEN sls_price IS NULL OR sls_price <=0
		THEN sls_sales / NULLIF(sls_quantity, 0)
	ELSE sls_price
END AS sls_price

FROM bronze.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price <= 0
ORDER BY sls_sales, sls_quantity, sls_price;

==========================================================================================
-- Checking 'silver.erp_cust_info'
==========================================================================================
SELECT 
CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
	ELSE cid
END cid, -- Remove 'NAS' prefix if present

CASE WHEN bdate > GETDATE() THEN NULL
	ELSE bdate
END AS bdate, -- Set future birthdates to NULL

CASE WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
	 WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
	 ELSE 'n/a'
END AS gen -- Normalize gender values and handle unknown cases
FROM bronze.erp_cust_az12

-- Data Standardization & Consistency
SELECT DISTINCT 
gen,
CASE WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
	 WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
	 ELSE 'n/a'
END AS gen
from bronze.erp_cust_az12


-- Quality check
SELECT DISTINCT
bdate
FROM silver.erp_cust_az12
WHERE bdate < '1924-01-01' OR bdate > GETDATE()

==========================================================================================
-- Checking 'silver.erp_loc_a101'
==========================================================================================
-- Normalize and handle missing or blank country codes
  SELECT 
REPLACE(cid, '-', '') AS cid,
CASE WHEN cntry = 'DE' THEN 'Germany'
	 WHEN cntry IN ('US', 'USA') THEN 'United States'
	 WHEN cntry IS NULL THEN 'n/a'
	 WHEN cntry = '' OR cntry IS NULL THEN 'n/a'
	 ELSE cntry 
END AS cntry 
FROM bronze.erp_loc_a101

-- Data Standardization & Consistency
SELECT DISTINCT cntry
FROM silver.erp_loc_a101
ORDER BY cntry

==========================================================================================
-- Checking 'silver.erp_px_cat_g1v2'
==========================================================================================


-- CHECK FOR UNWANTED SPACES
SELECT * FROM bronze.erp_px_cat_glv2
WHERE cat != TRIM(cat) OR subcat != TRIM(subcat) OR maintenance != TRIM(maintenance)

-- DATA STANDARDIZATION AND CONSISTENCY
SELECT DISTINCT
cat
FROM bronze.erp_px_cat_glv2

SELECT DISTINCT
subcat
FROM bronze.erp_px_cat_glv2

SELECT DISTINCT
maintenance
FROM bronze.erp_px_cat_glv2


-- Silver Table
-- CHECK FOR UNWANTED SPACES
SELECT * FROM silver.erp_px_cat_glv2
WHERE cat != TRIM(cat) OR subcat != TRIM(subcat) OR maintenance != TRIM(maintenance)

-- DATA STANDARDIZATION AND CONSISTENCY
SELECT DISTINCT
cat
FROM silver.erp_px_cat_glv2

SELECT DISTINCT
subcat
FROM silver.erp_px_cat_glv2

SELECT DISTINCT
maintenance
FROM silver.erp_px_cat_glv2

















