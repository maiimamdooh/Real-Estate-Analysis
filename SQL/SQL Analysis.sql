--🏠 Property Analytics
--● Number of listed properties by type and location
SELECT 
    PropertyType, 
    Location, 
    COUNT(*) AS NumberOfProperties
From  
      Properties
Group By 
      PropertyType, 
	  Location

ORDER BY 
      PropertyType, 
	  Location;

--● Average price per square meter per city
SELECT 
    Location AS City, 
    Round(AVG(PriceUSD / NULLIF(Size_sqm, 0)),2) AS AvgPricePerSqm
FROM 
    Properties
GROUP BY 
    Location
ORDER BY 
    AvgPricePerSqm DESC;

--● Distribution of property types (Apartment, Villa, etc.)
SELECT 
    PropertyType, 
    COUNT(*) AS NumberOfProperties
FROM 
    Properties
GROUP BY 
    PropertyType
ORDER BY 
    NumberOfProperties DESC;

--● Top 10 most expensive or most visited properties
--Most expensive
SELECT 
    TOP 10
    PropertyID, 
    PropertyType,
	PriceUSD
FROM 
    Properties
ORDER BY 
    PriceUSD DESC;
--Most visited
SELECT 
    TOP 10
    v.PropertyID, 
    p.PropertyType, 
    COUNT(*) AS NumberOfVisits
FROM 
    Visits AS v
Inner JOIN 
    Properties AS p 
	ON v.PropertyID = p.PropertyID
GROUP BY 
    v.PropertyID, p.PropertyType, p.Location
ORDER BY 
    NumberOfVisits DESC;

--💵 Sales Performance
--● Total sales value over time (monthly, quarterly, yearly)
--Monthly
SELECT
    MONTH(SaleDate) AS MonthNum,
    CAST(SUM(SalePrice) AS INT) AS TotalSales
FROM
    Sales
GROUP BY
    MONTH(SaleDate)
ORDER BY
    MonthNum;

--Quarterly
SELECT 
    DATEPART(QUARTER, SaleDate) AS QrtNum,
    CAST(SUM(SalePrice) AS INT) AS TotalSales
FROM 
    Sales
GROUP BY 
     DATEPART(QUARTER, SaleDate)
ORDER BY 
     QrtNum;

--Yearly
SELECT 
    YEAR(SaleDate) AS Year,
    CAST(SUM(SalePrice) AS INT) AS TotalSales
FROM 
    Sales
GROUP BY 
    YEAR(SaleDate)
ORDER BY 
    Year;

--● Average sale value per property type
SELECT 
    p.PropertyType,
    CAST(ROUND(AVG(s.SalePrice), 2) AS DECIMAL(18,2)) AS AvgSaleValue
FROM 
    Sales s
Inner JOIN 
    Properties p 
	ON s.PropertyID = p.PropertyID
GROUP BY 
    p.PropertyType
ORDER BY 
    AvgSaleValue DESC;

--● Conversion rate = (sales / visits) per property or agent

--per property
-- Step 1: Get visit count and sale status per property
WITH PropertyStats AS (
    SELECT
        p.PropertyID,
        p.PropertyType,
        COUNT(DISTINCT v.VisitID) AS VisitCount,
        CASE WHEN 
		        COUNT(DISTINCT s.SaleID) > 0 THEN 1 
		        ELSE 0 
		END AS WasSold
    FROM
        Properties AS p
        LEFT JOIN Visits AS v 
		ON p.PropertyID = v.PropertyID
        LEFT JOIN Sales AS s 
		ON p.PropertyID = s.PropertyID
    GROUP BY
        p.PropertyID, p.PropertyType
)
-- Step 2: Compute conversion rate as 1 sale per number of visits
SELECT
    PropertyID,
    PropertyType,
    VisitCount,
    WasSold,
    CASE WHEN
             VisitCount = 0 THEN 0
             WHEN WasSold = 1 THEN CAST(ROUND(100.0 / VisitCount, 2) AS DECIMAL(5,2))
             ELSE 0
    END AS ConversionRatePercent
FROM
    PropertyStats
ORDER BY
    ConversionRatePercent DESC;

--Per Agent
SELECT
    a.AgentID,
    CONCAT(a.FirstName, ' ', a.LastName) AS AgentName,
    COUNT(DISTINCT s.SaleID) AS NumberOfSales,
    COUNT(DISTINCT v.VisitID) AS NumberOfVisits,
    CAST(ROUND((COUNT(DISTINCT s.SaleID) * 100.0) / NULLIF(COUNT(DISTINCT v.VisitID), 0),2) AS DECIMAL(5,2)) AS ConversionRatePercentage
	
FROM
    Agents AS a
LEFT JOIN
    Sales AS s 
	ON a.AgentID = s.AgentID
LEFT JOIN
    Visits AS v 
	ON a.AgentID = v.AgentID
GROUP BY
    a.AgentID, a.FirstName, a.LastName
ORDER BY
    ConversionRatePercentage DESC;

--● Time on market before sale
SELECT 
    s.PropertyID,
    p.PropertyType,
    MIN(v.VisitDate) AS FirstVisitDate,
    s.SaleDate,
    DATEDIFF(DAY, MIN(v.VisitDate), s.SaleDate) AS DaysOnMarket
FROM 
    Sales AS s
Inner JOIN 
    Properties AS p 
	ON s.PropertyID = p.PropertyID
Inner JOIN 
    Visits AS v 
	ON s.PropertyID = v.PropertyID
GROUP BY 
    s.PropertyID, p.PropertyType, s.SaleDate
ORDER BY 
    DaysOnMarket DESC;



--󰞴 Agent Performance
--● Number of sales per agent
SELECT
    a.AgentID,
    CONCAT(a.FirstName, ' ', a.LastName) AS AgentName,
    COUNT(s.SaleID) AS NumberOfSales
FROM
    Agents AS a
LEFT JOIN
    Sales AS s 
	ON a.AgentID = s.AgentID
GROUP BY
    a.AgentID, a.FirstName, a.LastName
ORDER BY
    NumberOfSales DESC;

--● Number of client visits per agent
SELECT
    a.AgentID,
    CONCAT(a.FirstName, ' ', a.LastName) AS AgentName,
    COUNT(v.VisitID) AS NumberOfClientVisits
FROM
    Agents AS a
LEFT JOIN
    Visits AS v 
	ON a.AgentID = v.AgentID
GROUP BY
    a.AgentID, a.FirstName, a.LastName
ORDER BY
    NumberOfClientVisits DESC;

--● Conversion rate per agent (visits → sales)
SELECT
    a.AgentID,
    CONCAT(a.FirstName, ' ', a.LastName) AS AgentName,
    COUNT(DISTINCT s.SaleID) AS NumberOfSales,
    COUNT(DISTINCT v.VisitID) AS NumberOfVisits,
    CAST(ROUND((COUNT(DISTINCT s.SaleID) * 100.0) / NULLIF(COUNT(DISTINCT v.VisitID), 0),2) AS DECIMAL(5,2)) AS ConversionRatePercentage
	
FROM
    Agents AS a
LEFT JOIN
    Sales AS s 
	ON a.AgentID = s.AgentID
LEFT JOIN
    Visits AS v 
	ON a.AgentID = v.AgentID
GROUP BY
    a.AgentID, a.FirstName, a.LastName
ORDER BY
    ConversionRatePercentage DESC;

--● Avg sale value handled by each agent
SELECT
    a.AgentID,
    CONCAT(a.FirstName, ' ', a.LastName) AS AgentName,
    CAST(ROUND(AVG(s.SalePrice), 2) AS DECIMAL(15,2)) AS AverageSaleValue
FROM
    Agents AS a
LEFT JOIN
    Sales AS s 
	ON a.AgentID = s.AgentID
GROUP BY
    a.AgentID, a.FirstName, a.LastName
ORDER BY
    AverageSaleValue DESC;


--🙋 Client Engagement
--● Number of properties visited per client
SELECT
    c.ClientID,
    CONCAT(c.FirstName, ' ', c.LastName) AS ClientName,
    COUNT(DISTINCT v.PropertyID) AS NumberOfPropertiesVisited
FROM
    Clients AS c
LEFT JOIN
    Visits AS v 
	ON c.ClientID = v.ClientID
GROUP BY
    c.ClientID, c.FirstName, c.LastName
ORDER BY
    NumberOfPropertiesVisited DESC;

--● Top clients by sale value
SELECT TOP 10
    c.ClientID,
    CONCAT(c.FirstName, ' ', c.LastName) AS ClientName,
    CAST(SUM(s.SalePrice) AS FLOAT) AS SaleValue
FROM
    Clients c
Inner JOIN
    Sales s ON c.ClientID = s.ClientID
GROUP BY
    c.ClientID, c.FirstName, c.LastName
ORDER BY
    SaleValue DESC;

--● First-time vs repeat buyers
WITH ClientSaleCounts AS (
    SELECT
        ClientID,
        COUNT(SaleID) AS NumberOfSales
    FROM
        Sales
    GROUP BY
        ClientID
)
SELECT
    c.ClientID,
    CONCAT(c.FirstName, ' ', c.LastName) AS ClientName,
	ISNULL(csc.NumberOfSales, 0) AS TotalSalesMade,
    CASE WHEN
        csc.NumberOfSales = 1 THEN 'First-Time Buyer'
        WHEN csc.NumberOfSales > 1 THEN 'Repeat Buyer'
        ELSE 'Not a Buyer' 
    END AS BuyerType
FROM
    Clients AS c
LEFT JOIN
    ClientSaleCounts AS csc 
	ON c.ClientID = csc.ClientID
ORDER BY
    c.LastName, c.FirstName;

--● Region-based client interest (visits by city)
SELECT
    c.ClientID,
    CONCAT(c.FirstName, ' ', c.LastName) AS ClientName,
    p.Location AS City,
    COUNT(v.VisitID) AS NumberOfVisitsInCity
FROM
    Clients AS c
Inner JOIN
    Visits AS v ON 
	c.ClientID = v.ClientID
Inner JOIN
    Properties AS p 
	ON v.PropertyID = p.PropertyID
GROUP BY
    c.ClientID, c.FirstName, c.LastName, p.Location
ORDER BY
    NumberOfVisitsInCity DESC;


--📍 Location-Based Insights
--● Sales heatmap by city or region
-- Number of Sales per Location (Volume)
SELECT
    p.Location,
    COUNT(s.SaleID) AS SalesNum
FROM
    Properties AS p
INNER JOIN
    Sales AS s 
	ON p.PropertyID = s.PropertyID
GROUP BY
    p.Location
ORDER BY
    SalesNum DESC;

--Total Sales Value per Location (Value)
SELECT
    p.Location,
	CAST(SUM(s.SalePrice) AS FLOAT) AS SaleValue
FROM
    Properties p
Inner JOIN
    Sales AS s 
	ON p.PropertyID = s.PropertyID
GROUP BY
    p.Location
ORDER BY
    SaleValue DESC;

--● High-performing areas (most sold or highest priced)
--Areas with Most Properties Sold
SELECT
    p.Location,
    COUNT(s.SaleID) AS SalesNum
FROM
    Properties AS p
INNER JOIN
    Sales AS s 
	ON p.PropertyID = s.PropertyID
GROUP BY
    p.Location
ORDER BY
    SalesNum DESC;

--● Average visit-to-sale ratio per location

-- 1. For every sold property, calculate its number of visits.
WITH SoldProperties AS (
    SELECT
        p.PropertyID,
        p.Location
    FROM
        Properties p
        INNER JOIN Sales AS s 
		           ON p.PropertyID = s.PropertyID
),
VisitsPerSoldProperty AS (
    SELECT
        sp.PropertyID,
        sp.Location,
        COUNT(v.VisitID) AS VisitsNum
    FROM
        SoldProperties AS sp
        LEFT JOIN Visits AS v 
		ON sp.PropertyID = v.PropertyID
    GROUP BY
        sp.PropertyID, sp.Location
)
-- 2. Now calculate the average number of visits for sold properties by location.
SELECT
    Location,
    AVG(VisitsNum * 1.0) AS AvgVisitToSaleRatio
FROM
    VisitsPerSoldProperty
GROUP BY
    Location
ORDER BY
    AvgVisitToSaleRatio DESC;


--Milestone
--Sent emails to the potential customers
WITH ClientSaleCounts AS (
    SELECT
        ClientID,
        COUNT(SaleID) AS NumberOfSales
    FROM
        Sales
    GROUP BY
        ClientID
)
SELECT
    c.ClientID,
    CONCAT(c.FirstName, ' ', c.LastName) AS ClientName,
    c.Email,
    ISNULL(csc.NumberOfSales, 0) AS TotalSalesMade
FROM
    Clients AS c
LEFT JOIN 
	ClientSaleCounts AS csc 
	ON c.ClientID = csc.ClientID
WHERE
    csc.NumberOfSales = 1 
	OR 
	csc.NumberOfSales IS NULL
ORDER BY
    c.LastName, c.FirstName;

--Not Visited Properties to Focus On on our campains and offers
SELECT 
    p.PropertyID, 
	p.PropertyType, 
	p.Location
FROM 
    Properties AS p 
LEFT JOIN 
    Visits AS v
    ON p.PropertyID= v.PropertyID
WHERE 
    v.VisitID IS NULL

--MOM% in Sales
SELECT
    YEAR(SaleDate) As Year,
    MONTH(SaleDate) AS Month,
    SUM(SalePrice) AS Total_Sales,
    ROUND( 
	     (SUM(SalePrice) - 
                               LAG(SUM(SalePrice)) OVER (ORDER BY YEAR(SaleDate), MONTH(SaleDate)) ) * 100.0 /               
                               NULLIF(LAG(SUM(SalePrice)) OVER (ORDER BY YEAR(SaleDate), MONTH(SaleDate)), 0)
         , 2) AS MOM_per
FROM 
    Sales

GROUP BY 
    YEAR(SaleDate),
    MONTH(SaleDate)
ORDER BY 
    YEAR(SaleDate),
    MONTH(SaleDate);

--YOY% in Sales
SELECT
    YEAR(SaleDate) AS Year,
    SUM(SalePrice) AS Total_Sales,
    ROUND( 
         (SUM(SalePrice) - 
                             LAG(SUM(SalePrice)) OVER (ORDER BY YEAR(SaleDate))) * 100.0 /
                             NULLIF(LAG(SUM(SalePrice)) OVER (ORDER BY YEAR(SaleDate)), 0)
        , 2) AS YOY_per 
FROM
    Sales   
GROUP BY
    YEAR(SaleDate)
ORDER BY
    YEAR(SaleDate)