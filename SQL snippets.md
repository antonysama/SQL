Server: EIPDB99S 
**Info on columns for each view, table or sp**

sp_columns ufxeadOSMonthlyRevenueForecastTVF 

**Who's reaching payout based on accruals?**

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

USE EAD_PROD
IF OBJECT_ID('tempdb..#Master', 'U') IS NOT NULL
    DROP TABLE #Master
SELECT a.ProductionMonth, SUM(a.TotalCrudeBitumenProduction * 6.29234 / DATEPART(day, EOMONTH(a.ProductionMonth))) AS bpd, SUM(a.OperatingCosts) AS Opex, 
SUM(a.CapitalCosts) AS CAPEX, SUM(a.GrossRevenue) AS Revenue, SUM(a.GrossRevenue)/SUM(a.TotalCrudeBitumenProduction * 6.29234) AS RealizedPrCDN,
SUM(a.CalculatedRoyalty) AS Royalty,  MAX(a.Region) AS Region, AVG(b.WTI_USDBBL) AS WTI, AVG(b.WCSPriceUSDbbl) AS WCS_USD, AVG(b.FXCADUSD) AS FX, 
AVG(b.WCSPriceUSDbbl)/AVG(b.FXCADUSD) AS WCS_CAD, AVG((b.ARPC1_CADGJ) AS ARP_CADGJ,
AVG(b.WCSPriceUSDbbl)/AVG(b.FXCADUSD) WCS_CDN, AVG(b.ARPC1_CADGJ) AS ARP, AVG(b.NPR_CAD) AS NPR, AVG(c.NetRemittance000CAD) AS NetRemittance, 
AVG(c.CondensateRoyalty_Amount) AS CondensateRoyalty, AVG(c.LTotalProd+c.MTotalProd+c.HTotalProd+c.UTotalProd) * 6.29234 / DATEPART(day, EOMONTH(a.ProductionMonth)) AS CrudeBPD, 
AVG(d.NetGasRoyalty)AS GasRoyalty, AVG(d.SulphurDefaultPrice_CADperTON) AS Sulphur_CDN_T , AVG(e.GAS_RoyaltyLiableHeatContent_000GJ) AS Gas_000GJ AVG(e.PNGBonus_Total+e.OSBonus_Total) AS PNGOS_Bonus, AVG(e.PNGPricePerHectare_Total) AS PNG_Pr_Ha, AVG(f.PNGRentAndFees+ f.CoalRentAndFees+ f.OilSandsRentAndFees+ f.OtherRentAndFees)*-1 AS RentalAndFees --, MAX(a.FormType) AS PayoutStatus
INTO #Master
FROM
ufxeadOSMonthlyRevenueForecastTVF (getutcdate()) a 
LEFT JOIN ufxeadOSMonthlyViewTVF (getutcdate()) b ON a.ProductionMonth = b.ProductionPeriod
LEFT JOIN ufxeadOilProductionTVF (getUTCdate()) c ON a.ProductionMonth = c.ProductionPeriod
LEFT JOIN ufxeadGasTVF (getUTCdate()) d ON a.ProductionMonth = d.ProductionPeriod
LEFT JOIN ufxeadLandSaleTVF(getUTCdate()) e  ON a.ProductionMonth  = e.YearMonth
LEFT JOIN ufxeadRentalDataTVF (getutcdate()) f  on a.ProductionMonth=f.ProductionPeriod
WHERE ProductionMonth = '2022-12-01' --discretion
GROUP BY a.ProductionMonth;
--SELECT * FROM #Master

**Qarter v Quarter comparision w. sub query & case**

SELECT TY.MONTH, TY.Acid AS TY_Acid, LY.Acid AS LY_Acid 
FROM
    (SELECT DATENAME(month, ProductionMonth) AS MONTH, AVG(Actl_AcidGas_000CAD) as Acid
    FROM #Master
    WHERE ProductionMonth BETWEEN '2021-04-01' AND '2021-06-01'
    GROUP BY DATENAME(month, ProductionMonth)) AS LY
INNER JOIN 
    (SELECT DATENAME(month, ProductionMonth) AS MONTH, AVG(Actl_AcidGas_000CAD) as Acid
    FROM  #Master
    WHERE ProductionMonth BETWEEN '2022-04-01' AND '2022-06-01'
    GROUP BY DATENAME(month, ProductionMonth)) AS TY
ON LY.MONTH = TY.MONTH
GROUP BY TY.MONTH, TY.Acid, LY.Acid
ORDER BY CASE TY.MONTH
    WHEN 'April' THEN 1
    WHEN 'May' THEN 2
    WHEN 'June' THEN 3
    END;

**or**

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

**or**

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


**Strategic v Sustaining OS Capital Costs**
SELECT Year_Submitted, ROUND(SUM(TotalStrategicCapitalCosts),0) AS TotalStrategicCapitalCosts, ROUND(SUM(TotalSustainingCapitalCosts),0) AS TotalSustainingCapitalCosts
FROM ufxeadOSOperatorForecastSummaryTVF (getUTCdate())
WHERE Year_Submitted=Forecast_Year
GROUP BY Year_Submitted
ORDER BY Year_Submitted;

**Realized bitumen price of top 10 based on production**
SELECT ProductionMonth,  (SUM(u.GrossRevenue)/(SUM(u.TotalCrudeBitumenProduction)* 6.29234)) AS RealizedPrice
FROM
    (SELECT ProjName, TotalCrudeBitumenProduction , GrossRevenue, ProductionMonth,
        ROW_NUMBER() OVER (PARTITION BY ProductionMonth ORDER BY TotalCrudeBitumenProduction DESC) AS rn
    FROM ufxeadOSMonthlyRevenueForecastTVF (getUTCdate())
    WHERE ProductionMonth BETWEEN'2023-01-01' AND '2023-12-01') AS u
GROUP BY  ProductionMonth
ORDER BY ProductionMonthh

**Wells spud b/w 2020-2021**
USE EAD_PROD
FROM eadWellEventView
WHERE [Spud Date] >= '2020-01-01' 
AND [Well Status Mode Desc] NOT IN ('ABANDONED', 'ABANDONED & WHIPSTOCKED')
 AND [Well Location Top Latitude] IS NOT NULL

--Total & Null Counts Among The Lat & Lon, are all in 2022
SELECT YEAR([Spud Date]) AS YEAR, COUNT(DISTINCT [Well Event ID] ) AS TotCount,
    SUM(CASE WHEN [Well Location Top Longitude] IS NULL THEN 1 ELSE 0 END) AS Longitude_Null_Count,
    SUM(CASE WHEN [Well Location Top Latitude] IS NULL THEN 1 ELSE 0 END) AS Latitude_Null_Count,
    CAST(SUM(CASE WHEN [Well Location Top Latitude] IS NULL THEN 1 ELSE 0 END) AS decimal)/ COUNT(DISTINCT [Well Event ID] )  AS Ratio
FROM eadWellEventView
WHERE [Spud Date] >= '2019-01-01'  AND [Spud Date] <= '2021-12-01'
GROUP BY YEAR([Spud Date])

**declaring parameters**
USE RFM_PROD

DECLARE @priceScenarioID AS Int;
--DECLARE @OSPDEYearSubmitted AS DATETIME = '2023-01-01' ;
DECLARE @AsOfDate AS DATETIME2 = '2023-01-1';

SELECT *
FROM dbo.tvfPayoutStatus (@AsOfDate, @priceScenarioID)

----Another Example -----

USE RFM_PROD
DECLARE @priceScenarioID AS Int; DECLARE @OSPDEYearSubmitted AS DATETIME = '2023-01-01' ; DECLARE @asOfDate AS DATETIME2 = '2023-01-1';
SELECT Top (10) *
FROM tvfCStar (@asOfDate, @priceScenarioID)
--WHERE CStar IS NOT NULL;


**overcome the division by 0 error**
SELECT *
FROM ufxeadCoalBITProductionSummaryTVF (GETUTCDATE())
WHERE CASE
         WHEN ISNULL(MarketableSales, 0) = 0 THEN 0 -- Handle zero divisor for Column1
         WHEN ISNULL(ProductRevenue, 0) = 0 THEN 0 -- Handle zero divisor for Column2
         WHEN ISNULL(Price, 0) = 0 THEN 0 -- Handle zero divisor for Column3
         -- Add more columns as needed
         ELSE 1 -- Non-zero divisor
      END = 1

      
**Crown Gas, NGLs, Sulphur & Oil fiscal**
--Server: EIPDB99S
USE EAD_PROD 
SELECT DATEPART(YEAR, DATEADD(MONTH, -3, a.ProductionPeriod)) AS FiscalYear, 
SUM(a.ARPC1_CADGJ * b.GAS_CrownInterestHeatContent_000GJ) AS GasValue, 
SUM (a.ARPC1_CADGJ * (b.C2SP_CrownInterestHeatContent_000GJ + b.C2MX_CrownInterestHeatContent_000GJ)) AS C2Value,   
SUM (b.C3MXReferencePrice_CADperM3 * b.C3MX_CrownInterestQuantity_000M3 + b.C3SPReferencePrice_CADperM3 * b.C3SP_CrownInterestQuantity_000M3) AS C3Value,
SUM (b.C4MXReferencePrice_CADperM3 * b.C4MX_CrownInterestQuantity_000M3 + b.C4SPReferencePrice_CADperM3 * b.C4SP_CrownInterestQuantity_000M3) AS C4Value,
SUM (b.C5MXReferencePrice_CADperM3 * b.C5MX_CrownInterestQuantity_000M3 + b.C5SPReferencePrice_CADperM3 * b.C5SP_CrownInterestQuantity_000M3) AS C5Value, 
SUM (b.SUL_CrownInterestQuantityl_000t * b.SulphurDefaultPrice_CADperTON) AS SUL_Value,
SUM (c.LTotalCrownProd) AS LOILPrdn, SUM (c.MTotalCrownProd) AS MOILPrdn, SUM (c.HTotalCrownProd) AS HOILPrdn, SUM (c.UTotalCrownProd) AS UOILPrdnrice 
FROM ufxeadOSMonthlyViewTVF (getUTCdate()) a LEFT JOIN ufxeadGasTVF (getUTCdate()) b ON a.ProductionPeriod=b.ProductionPeriod  LEFT JOIN ufxeadOilProductionTVF (getUTCdate()) c ON a.ProductionPeriod=c.ProductionPeriod
WHERE YEAR(a.ProductionPeriod)>2020 AND YEAR(a.ProductionPeriod)<2023
GROUP BY DATEPART(YEAR, DATEADD(MONTH, -3, a.ProductionPeriod)) 

**Total Gas (ARF+MRF) Production**
--Server: EIPDB99S
USE EAD_PROD 
SELECT a.ProductionPeriod, GAS_RoyaltyLiableHeatContent_000GJ/1050 AS GAS_BCf, (GAS_RoyaltyLiableHeatContent_ARF_000GJ+GAS_RoyaltyLiableHeatContent_MRF_000GJ)/1050 AS GAS_BCf2 --DATEPART(YEAR, DATEADD(MONTH, -3, a.ProductionPeriod)) AS FiscalYear, SUM(GAS_RoyaltyLiableHeatContent_000GJ)/1050 AS GAS_BCf
FROM ufxeadGasTVF (getUTCdate()) a
WHERE YEAR(a.ProductionPeriod)>2019 AND YEAR(a.ProductionPeriod) <2021
--GROUP BY a.ProductionPeriod --DATEPART(YEAR, DATEADD(MONTH, -3, a.ProductionPeriod)) 
ORDER BY a.ProductionPeriod
