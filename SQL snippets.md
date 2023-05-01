**info on columns for each view, table or sp**
sp_columns ufxeadOSMonthlyRevenueForecastTVF 

**who's reaching payout based on accruals?**
SELECT  *  
FROM ufxeadOSProjectTVF (getUTCdate())
WHERE ActualPayoutDate BETWEEN'2021' AND '2025'

**Rp & Rq based on accruals**
SELECT ProductionPeriod,  ARFRpL, ARFRpM, ARFRpH, ARFRpU, MRFRpL, MRFRpM, MRFRpH, MRFRpU, RqL, RqM, RqH, RqU, MRFRq  
FROM ufxeadOilProductionTVF(getutcdate())
WHERE ProductionPeriod BETWEEN '2021-12-01' AND '2024-12-01'

**EORP  but assuming its units are m3?**
SELECT  ProductionPeriod, SUM(EORP * 6.29234 / DATEPART(day, EOMONTH(ProductionPeriod))) as barrels_per_daY 
FROM  ufxeadOilProductionTVF(getUTCdate())
WHERE ProductionPeriod BETWEEN'2020-12-01' AND '2022-11-01'
GROUP BY  ProductionPeriod;

 **Until when do we have actuals?**
SELECT ProductionMonth, Max(ActualEstimate) AS OS_ACTL_EST,
    --SUM(TotalCrudeBitumenProduction * 6.29234 / DATEPART(day, EOMONTH(ProductionMonth))) as barrels_per_daY,
    SUM (LTotalProd + MTotalProd + HTotalProd +  UTotalProd)* 6.29234 / DATEPART(day, EOMONTH(ProductionMonth)) AS CrudeBpd
FROM ufxeadOSMonthlyRevenueForecastTVF (getUTCdate())
LEFT JOIN ufxeadOilProductionTVF (getUTCdate())
ON ProductionMonth=ProductionPeriod
WHERE ProductionMonth BETWEEN'2022-01-01' AND '2023-04-01'
GROUP BY  ProductionMonth
ORDER BY ProductionMonth;

**Create Master table**
IF OBJECT_ID('tempdb..#Master', 'U') IS NOT NULL
    DROP TABLE #Master

SELECT a.ProductionMonth, b.FXCADUSD, c.AgencyFees000CAD, d.Actl_AcidGas_000CAD --, e., f.* --Master table
INTO #Master
FROM
ufxeadOSMonthlyRevenueForecastTVF (getutcdate()) a 
LEFT JOIN ufxeadOSMonthlyViewTVF (getutcdate()) b ON a.ProductionMonth = b.ProductionPeriod
LEFT JOIN ufxeadOilProductionTVF (getUTCdate()) c ON a.ProductionMonth = c.ProductionPeriod
LEFT JOIN ufxeadGasTVF (getUTCdate()) d ON a.ProductionMonth = d.ProductionPeriod
LEFT JOIN ufxeadLandSaleTVF(getUTCdate()) e  ON a.ProductionMonth  = e.YearMonth
LEFT JOIN ufxeadRentalDataTVF (getutcdate()) f  on a.ProductionMonth=b.ProductionPeriod;
SELECT * FROM #Master

**qarter v Quarter comparision w. sub query & case**
SELECT u.FiscalYear, u.FX
FROM (
    SELECT 
        CASE
            WHEN a.ProductionMonth >= '2021-04-01' AND a.ProductionMonth < '2022-04-01' THEN 2021 
            WHEN a.ProductionMonth >= '2022-04-01' AND a.ProductionMonth < '2023-04-01' THEN 2022 
        END AS FiscalYear, 
        AVG(a.FXCADUSD) AS FX 
    FROM #Master AS a
    WHERE a.ProductionMonth BETWEEN '2021-04-01' AND '2023-04-01'
    GROUP BY CASE
            WHEN a.ProductionMonth >= '2021-04-01' AND a.ProductionMonth < '2022-04-01' THEN 2021 
            WHEN a.ProductionMonth >= '2022-04-01' AND a.ProductionMonth < '2023-04-01' THEN 2022 
        END
) AS u;

**OR**
SELECT TY.MONTH, TY.BPD AS TY_BPD, LY.BPD AS LY_BPD 
FROM
    (SELECT DATENAME(month, ProductionPeriod) AS MONTH, SUM(EORP * 6.29234 / DATEPART(day, EOMONTH(ProductionPeriod))) as BPD
    FROM  ufxeadOilProductionTVF(getUTCdate())
    WHERE ProductionPeriod BETWEEN '2021-04-01' AND '2021-06-01'
    GROUP BY DATENAME(month, ProductionPeriod)) AS LY
INNER JOIN 
    (SELECT DATENAME(month, ProductionPeriod) AS MONTH, SUM(EORP * 6.29234 / DATEPART(day, EOMONTH(ProductionPeriod))) as BPD
    FROM  ufxeadOilProductionTVF(getUTCdate())
    WHERE ProductionPeriod BETWEEN '2022-04-01' AND '2022-06-01' 
    GROUP BY DATENAME(month, ProductionPeriod)) AS TY
ON LY.MONTH = TY.MONTH
GROUP BY TY.MONTH, TY.BPD, LY.BPD
ORDER BY CASE TY.MONTH
    WHEN 'April' THEN 1
    WHEN 'May' THEN 2
    WHEN 'June' THEN 3
    END;

**Year v Year comparision w. sub query & case**
SELECT FiscalYear, SUM(BPD) AS SUM_BPD 
FROM 
    (SELECT
        CASE 
            WHEN ProductionPeriod >= '2021-04-01' AND ProductionPeriod < '2022-04-01' THEN  2021
            WHEN ProductionPeriod >= '2022-04-01' AND ProductionPeriod < '2023-04-01' THEN  2022
        END AS FiscalYear,
        EORP * 6.29234 / DATEPART(day, EOMONTH(ProductionPeriod)) as BPD
    FROM ufxeadOilProductionTVF (getUTCdate()) 
    WHERE ProductionPeriod BETWEEN '2021-04-01' AND '2023-03-01') AS u
GROUP BY FiscalYear;


