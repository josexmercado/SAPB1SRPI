

DECLARE @PeriodFrom as Date = '2020-01-01'
DECLARE @PeriodTo as Date = '2020-07-15'

select ItemCode, ItemName,
	sum(Total) as TotalSales,
	sum(TotalCost) as TotalCost,
	sum(GrossProfit) as GrossProfit
	FROM
--Standard Invoice
(SELECT 
	T2.ItemCode,
	T2.ItemName,
	--SUM(T1.LineTotal) AS total,
	--SUM(T1.StockValue) AS TotalCost,
	--SUM(T1.LineTotal) - SUM(T1.StockValue)  as GrossProfit
	T1.LineTotal AS total,
	T1.StockValue AS TotalCost,
	T1.LineTotal - T1.StockValue  as GrossProfit,
	t0.TaxDate,
	CONCAT('IN ' , t0.DocNum) AS Docnum,
	'Standard' as types,
	T0.Docnum AS BaseDoc
	
FROM OINV T0
INNER JOIN INV1 T1 ON T1.Docentry = T0.Docnum
INNER JOIN OITM T2 ON T1.ItemCode = T2.Itemcode
WHERE T0.U_BO_DRS <> 'Y'
AND T0.isIns <> 'Y'  AND T0.CANCELED = 'N'
--GROUP BY T2.ItemCode, T2.ItemName
AND  T0.TaxDate BETWEEN @PeriodFrom AND @PeriodTo
UNION ALL 

SELECT
	T2.ItemCode,
	T2.ItemName,
	T1.LINETOTAL as TotalSales,
	--(SELECT DISTINCT T3.DOCENTRY 
	--FROM POR1 T3
	--INNER JOIN OPOR T4 ON T3.DOCENTRY = T4.DOCNUM
	--WHERE T3.BaseRef = T0.Docnum and T3.BaseType = 17
	--AND T0.U_BO_DRS = 'Y') as PurchaseOrder,
	(SELECT DISTINCT SUM(T3.LineTotal) FROM PCH1 T3
	WHERE T3.BASETYPE = 22 AND T3.BaseEntry = 	
	(SELECT DISTINCT T4.DOCENTRY 
	FROM POR1 T4
	INNER JOIN OPOR T5 ON T4.DOCENTRY = T5.DOCNUM
	WHERE T4.BaseRef = T0.DOCNUM and T4.BaseType = 17
	AND T0.U_BO_DRS = 'Y')
	AND T2.ItemCode = T3.ItemCode) AS Cost,

	T1.LINETOTAL -	(SELECT sum(T3.LineTotal) FROM PCH1 T3
	WHERE T3.BASETYPE = 22 AND T3.BaseEntry = 	
	(SELECT DISTINCT T4.DOCENTRY 
	FROM POR1 T4
	INNER JOIN OPOR T5 ON T4.DOCENTRY = T5.DOCNUM
	WHERE T4.BaseRef = T0.DOCNUM and T4.BaseType = 17
	AND T0.U_BO_DRS = 'Y')
	AND T2.ItemCode = T3.ItemCode) AS GrossProfit,

	t0.TaxDate,
	CONCAT('DS ' , t0.DocNum) as Docnum,
	'DropShip' as types,
	T1.DOCENTRY AS BaseDoc

FROM ORDR T0
INNER JOIN RDR1 T1 ON T1.Docentry = T0.Docnum
INNER JOIN OITM T2 ON T1.ItemCode = T2.Itemcode
WHERE T0.U_BO_DRS = 'Y' AND T0.CANCELED = 'N'
AND  T0.TaxDate BETWEEN @PeriodFrom AND @PeriodTo
UNION ALL

SELECT 
	T2.ItemCode,
	T2.ItemName,
	T1.LineTotal as TotalSales,
	T1.StockValue as Cost,
	T1.LineTotal - T1.StockValue  as GrossProfit,
	t0.TaxDate,
	CONCAT('DN ' , t0.DocNum) as Docnum,
	'Deliveries' as types,
	T1.BaseRef AS BaseDoc

FROM ODLN T0
INNER JOIN DLN1 T1 ON T1.Docentry = T0.Docnum
INNER JOIN OITM T2 ON T1.ItemCode = T2.Itemcode
WHERE T0.CANCELED = 'N'
AND T0.TaxDate BETWEEN @PeriodFrom AND @PeriodTo

UNION ALL

SELECT 
	T2.ItemCode,
	T2.ItemName,
	--SUM(T1.LineTotal) AS total,
	--SUM(T1.StockValue) AS TotalCost,
	--SUM(T1.LineTotal) - SUM(T1.StockValue)  as GrossProfit
	T1.LineTotal * -1 AS total,
	T1.StockValue * -1  AS TotalCost,
	(T1.LineTotal - T1.StockValue) * -1 as GrossProfit,
	t0.TaxDate,
	CONCAT('CN ' , t0.DocNum) AS Docnum,
	'AR CM' as types,
	T1.DOCENTRY AS BaseDoc

	
FROM ORIN T0
INNER JOIN RIN1 T1 ON T1.Docentry = T0.Docnum
INNER JOIN OITM T2 ON T1.ItemCode = T2.Itemcode
WHERE T0.U_BO_DRS <> 'Y'
AND T0.isIns <> 'Y'  AND T0.CANCELED = 'N'
AND  T0.TaxDate BETWEEN @PeriodFrom AND @PeriodTo

) AS TP
GROUP BY ITEMCODE, ITEMNAME
ORDER BY ItemCode ASC
------------------------


DECLARE @PeriodFrom as Date = '2020-01-01'
DECLARE @PeriodTo as Date = '2020-07-15'

select  ItemCode, ItemName,
	Total as TotalSales,
	TotalCost as TotalCost,
	GrossProfit as GrossProfit,
	docnum,
	types,
	BaseDoc
	FROM
--Standard Invoice
(SELECT 
	T2.ItemCode,
	T2.ItemName,
	--SUM(T1.LineTotal) AS total,
	--SUM(T1.StockValue) AS TotalCost,
	--SUM(T1.LineTotal) - SUM(T1.StockValue)  as GrossProfit
	T1.LineTotal AS total,
	T1.StockValue AS TotalCost,
	T1.LineTotal - T1.StockValue  as GrossProfit,
	t0.TaxDate,
	CONCAT('IN ' , t0.DocNum) AS Docnum,
	'Standard' as types,
	T0.Docnum AS BaseDoc
	
FROM OINV T0
INNER JOIN INV1 T1 ON T1.Docentry = T0.Docnum
INNER JOIN OITM T2 ON T1.ItemCode = T2.Itemcode
WHERE T0.U_BO_DRS <> 'Y'
AND T0.isIns <> 'Y'  AND T0.CANCELED = 'N'
--GROUP BY T2.ItemCode, T2.ItemName
AND  T0.TaxDate BETWEEN @PeriodFrom AND @PeriodTo
UNION ALL 

SELECT
	T2.ItemCode,
	T2.ItemName,
	T1.LINETOTAL as TotalSales,
	--(SELECT DISTINCT T3.DOCENTRY 
	--FROM POR1 T3
	--INNER JOIN OPOR T4 ON T3.DOCENTRY = T4.DOCNUM
	--WHERE T3.BaseRef = T0.Docnum and T3.BaseType = 17
	--AND T0.U_BO_DRS = 'Y') as PurchaseOrder,
	(SELECT DISTINCT SUM(T3.LineTotal) FROM PCH1 T3
	WHERE T3.BASETYPE = 22 AND T3.BaseEntry = 	
	(SELECT DISTINCT T4.DOCENTRY 
	FROM POR1 T4
	INNER JOIN OPOR T5 ON T4.DOCENTRY = T5.DOCNUM
	WHERE T4.BaseRef = T0.DOCNUM and T4.BaseType = 17
	AND T0.U_BO_DRS = 'Y')
	AND T2.ItemCode = T3.ItemCode) AS Cost,

	T1.LINETOTAL -	(SELECT sum(T3.LineTotal) FROM PCH1 T3
	WHERE T3.BASETYPE = 22 AND T3.BaseEntry = 	
	(SELECT DISTINCT T4.DOCENTRY 
	FROM POR1 T4
	INNER JOIN OPOR T5 ON T4.DOCENTRY = T5.DOCNUM
	WHERE T4.BaseRef = T0.DOCNUM and T4.BaseType = 17
	AND T0.U_BO_DRS = 'Y')
	AND T2.ItemCode = T3.ItemCode) AS GrossProfit,

	t0.TaxDate,
	CONCAT('DS ' , t0.DocNum) as Docnum,
	'DropShip' as types,
	T1.DOCENTRY AS BaseDoc

FROM ORDR T0
INNER JOIN RDR1 T1 ON T1.Docentry = T0.Docnum
INNER JOIN OITM T2 ON T1.ItemCode = T2.Itemcode
WHERE T0.U_BO_DRS = 'Y' AND T0.CANCELED = 'N'
AND  T0.TaxDate BETWEEN @PeriodFrom AND @PeriodTo
UNION ALL

SELECT 
	T2.ItemCode,
	T2.ItemName,
	T1.LineTotal as TotalSales,
	T1.StockValue as Cost,
	T1.LineTotal - T1.StockValue  as GrossProfit,
	t0.TaxDate,
	CONCAT('DN ' , t0.DocNum) as Docnum,
	'Deliveries' as types,
	T1.BaseRef AS BaseDoc

FROM ODLN T0
INNER JOIN DLN1 T1 ON T1.Docentry = T0.Docnum
INNER JOIN OITM T2 ON T1.ItemCode = T2.Itemcode
WHERE T0.CANCELED = 'N'
AND T0.TaxDate BETWEEN @PeriodFrom AND @PeriodTo

UNION ALL

SELECT 
	T2.ItemCode,
	T2.ItemName,
	--SUM(T1.LineTotal) AS total,
	--SUM(T1.StockValue) AS TotalCost,
	--SUM(T1.LineTotal) - SUM(T1.StockValue)  as GrossProfit
	T1.LineTotal * -1 AS total,
	T1.StockValue * -1  AS TotalCost,
	(T1.LineTotal - T1.StockValue) * -1 as GrossProfit,
	t0.TaxDate,
	CONCAT('CN ' , t0.DocNum) AS Docnum,
	'AR CM' as types,
	T1.DOCENTRY AS BaseDoc

	
FROM ORIN T0
INNER JOIN RIN1 T1 ON T1.Docentry = T0.Docnum
INNER JOIN OITM T2 ON T1.ItemCode = T2.Itemcode
WHERE T0.U_BO_DRS <> 'Y'
AND T0.isIns <> 'Y'  AND T0.CANCELED = 'N'
AND  T0.TaxDate BETWEEN @PeriodFrom AND @PeriodTo

) AS TP
ORDER BY docnum ASC
-------------------------------------------------------------------------------------------------