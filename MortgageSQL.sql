SELECT * 
FROM case_study.mortgage;

-- REMOVE DUPLICATE COLUMNS

ALTER TABLE case_study.mortgage
DROP COLUMN rate;

-- RENAME COLUMNS

ALTER TABLE case_study.mortgage
RENAME COLUMN `State[5]` TO State;
ALTER TABLE case_study.mortgage
RENAME COLUMN `Median home listing price` TO Median_home_listing_price;
ALTER TABLE case_study.mortgage
RENAME COLUMN `30-year fixed mortgage rate` TO 30_year_fixed_mortgage_rate;
ALTER TABLE case_study.mortgage
RENAME COLUMN `Monthly mortgage payment` TO Monthly_mortgage_payment;
ALTER TABLE case_study.mortgage
RENAME COLUMN `median household income` TO Median_household_income;
ALTER TABLE case_study.mortgage
RENAME COLUMN `Number of hours per Month to afford a home` TO Number_of_hours_per_Month_to_afford_a_home;

-- ALTER COLUMN DATA TYPE

ALTER TABLE case_study.mortgage
MODIFY COLUMN Number_of_hours_per_Month_to_afford_a_home INT;

-- DATA CLEANING
-- REMOVE SPECIAL CHARACTER ($)

UPDATE case_study.mortgage
SET Median_home_listing_price = REPLACE(Median_home_listing_price, '$', ' ');
UPDATE case_study.mortgage
SET Monthly_mortgage_payment = REPLACE(Monthly_mortgage_payment, '$', ' ');
UPDATE case_study.mortgage
SET Median_household_income = REPLACE(Median_household_income, '$', ' ');
UPDATE case_study.mortgage
SET pv = REPLACE(pv, '$', ' ');

-- REMOVE SPECIAL CHARACTER (%) AND CONVERT TO DECIMAL

ALTER TABLE case_study.mortgage
ADD COLUMN converted_30_year_fixed_mortgage_rate DECIMAL(5,4) AFTER 30_year_fixed_mortgage_rate;
UPDATE case_study.mortgage
SET converted_30_year_fixed_mortgage_rate = CAST(REPLACE(30_year_fixed_mortgage_rate, '%', '') AS DECIMAL(5, 4)) / 100;

-- REMOVE SPECIAL CHARACTERS (COMMA)

UPDATE case_study.mortgage
SET Median_home_listing_price = REPLACE(Median_home_listing_price, ',', '');
UPDATE case_study.mortgage
SET Monthly_mortgage_payment = REPLACE(Monthly_mortgage_payment, ',', '');
UPDATE case_study.mortgage
SET Median_household_income = REPLACE(Median_household_income, ',', '');
UPDATE case_study.mortgage
SET pv = REPLACE(pv, ',', '');

-- TOP 10 CITIES WITH THE HIGHEST MORTGAGE AFFORDABILITY (BASED ON HOURS WORKED)

SELECT City, State, Number_of_hours_per_Month_to_afford_a_home
FROM case_study.mortgage
ORDER BY Number_of_hours_per_Month_to_afford_a_home DESC
LIMIT 10;

-- TOP 10 CITIES WITH THE LOWEST MORTGAGE AFFORDABILITY (BASED ON HOURS WORKED)

SELECT City, State, Number_of_hours_per_Month_to_afford_a_home
FROM case_study.mortgage
ORDER BY Number_of_hours_per_Month_to_afford_a_home
LIMIT 10;

-- MEDIAN HOUSEHOLD INCOME CORRELATION WITH MORTGAGE PAYMENT
-- FIND THE NUMERATOR

SELECT
SUM((Median_household_income - avg_income)*(Monthly_mortgage_payment - avg_mortgage)) AS NUMERATOR
FROM case_study.mortgage,
(SELECT 
AVG(Median_household_income) AS avg_income,
AVG(Monthly_mortgage_payment) AS avg_mortgage
FROM case_study.mortgage) AS averages; 

-- FIND THE DENOMINATOR

SELECT 
SQRT(SUM(POW((Median_household_income - avg_income),2)))*SQRT(SUM(POW((Monthly_mortgage_payment - avg_mortgage),2))) AS DENOMINATOR
FROM case_study.mortgage, 
(SELECT 
AVG(Median_household_income) AS avg_income,
AVG(Monthly_mortgage_payment) AS avg_mortgage
FROM case_study.mortgage) AS averages; 

-- CALCULATE THE CORRELATION COEFFICIENT

SELECT 
ROUND((NUMERATOR / DENOMINATOR),2) AS CORRELATION
FROM
(SELECT 
SUM((Median_household_income - avg_income)*(Monthly_mortgage_payment - avg_mortgage)) AS NUMERATOR,
SQRT(SUM(POW((Median_household_income - avg_income),2)))*SQRT(SUM(POW((Monthly_mortgage_payment - avg_mortgage),2))) AS DENOMINATOR
FROM case_study.mortgage, 
(SELECT 
AVG(Median_household_income) AS avg_income,
AVG(Monthly_mortgage_payment) AS avg_mortgage
FROM case_study.mortgage) AS averages) AS final;

-- CALCULATE THE VARIANCE OF STATES THAT HAVE MORE THAN 3 BIG CITIES

SELECT 
COUNT(city) AS total_city, State,
ROUND(VARIANCE(Number_of_hours_per_Month_to_afford_a_home),2) AS Variance_of_hours
FROM case_study.mortgage
WHERE state IN (
	SELECT state
	FROM case_study.mortgage
	GROUP BY state
	HAVING count(city) > 3
    ) 
GROUP BY State
ORDER BY variance_of_hours DESC;

-- CALCULATE THE RANGE OF STATES THAT HAVE MORE THAN 2 BIG CITIES

SELECT 
State, 
MIN(Number_of_hours_per_Month_to_afford_a_home) AS MIN_HOURS,
MAX(Number_of_hours_per_Month_to_afford_a_home) AS MAX_HOURS,
MAX(Number_of_hours_per_Month_to_afford_a_home)-MIN(Number_of_hours_per_Month_to_afford_a_home) AS HOURS_RANGE
FROM case_study.mortgage
WHERE State IN 
	(SELECT STATE
	FROM case_study.mortgage
	GROUP BY State
	HAVING COUNT(CITY) > 2)
GROUP BY State
ORDER BY HOURS_RANGE DESC;

-- TOP 10 CITIES WITH THE HIGHEST MORTGAGE-TO-INCOME RATIO

SELECT 
City, 
State, 
Median_household_income, 
Monthly_mortgage_payment,
ROUND((((Monthly_mortgage_payment * 12)/Median_household_income)*100),2) AS Mortgage_to_income_ratio
FROM case_study.mortgage
ORDER BY Mortgage_to_income_ratio DESC
LIMIT 10;

-- TOP 10 CITIES WITH THE LOWEST INCOME HOUSING GAP 

SELECT 
City, 
State, 
Median_household_income, 
Monthly_mortgage_payment,
(Median_household_income - (Monthly_mortgage_payment * 12)) AS Income_housing_gap,
ROUND((((Monthly_mortgage_payment * 12)/Median_household_income)*100),2) AS Mortgage_to_income_ratio
FROM case_study.mortgage
ORDER BY Income_housing_gap
LIMIT 10;

