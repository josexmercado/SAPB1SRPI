

DECLARE @PeriodFrom as Date = '2020-01-01'
DECLARE @PeriodTo as Date = '2020-07-15'
DECLARE @TOP AS Integer = 20
select 
TYPE,
Itemcode,
ItemName,
TRANSTYPE,
Sales  AS 'Total Sales',
Cost  AS Cost,
Sales - Cost as 'Gross Profit',
OCRCODE
FROM
(	SELECT	
	
	CASE WHEN T0.ISINS = 'Y' THEN CONCAT('RES ', T0.DOCNUM)
	WHEN t0.U_BO_DRS = 'Y' THEN CONCAT('IN ', T0.DOCNUM) 
	ELSE CONCAT('IN ', T0.DOCNUM) 
	END AS Type,

	T1.Itemcode as ItemCode,
	T1.Dscription as ItemName,
	CASE WHEN T0.ISINS = 'Y' THEN 'AR Reserve'
	WHEN t0.U_BO_DRS = 'Y' THEN 'Dropship' 
	ELSE 'Standard'
	END AS TransType,

	case when t0.discsum > 0 
	then	T1.StockSum
	else	T1.LineTotal
	END AS Sales,

	CASE WHEN T0.ISINS = 'Y' 
	THEN	0
	WHEN t0.U_BO_DRS = 'Y' 
	THEN	0
	ELSE	T1.STOCKVALUE
	END AS Cost,

	case when t0.discsum > 0 
	then	T1.StockSum 	-
						CASE WHEN T0.ISINS = 'Y' 
						THEN	0
						WHEN t0.U_BO_DRS = 'Y' 
						THEN	0
						ELSE	T1.STOCKVALUE END
	else	T1.LineTotal	-
						CASE WHEN T0.ISINS = 'Y' 
						THEN	0
						WHEN t0.U_BO_DRS = 'Y' 
						THEN	0
						ELSE	T1.STOCKVALUE END
	end as GrossProfit,
	t1.OcrCode

FROM OINV T0
INNER JOIN INV1 T1 ON T0.DOCNUM = T1.DOCENTRY
WHERE T0.DOCTYPE = 'I' AND T0.CANCELED = 'N'
AND  T0.TaxDate BETWEEN @PeriodFrom AND @PeriodTo

UNION ALL

SELECT 
	CONCAT('DN ' , t0.DocNum) as Type,
	T2.ItemCode as ItemCode,
	T2.ItemName as ItemName,
	'Delivery' as TransType,

	0 as Sales,
	T1.StockValue as Cost,
	0 - T1.StockValue  as GrossProfit,
	t1.OcrCode

FROM ODLN T0
INNER JOIN DLN1 T1 ON T1.Docentry = T0.Docnum
INNER JOIN OITM T2 ON T1.ItemCode = T2.Itemcode
WHERE T0.CANCELED = 'N'
AND T0.TaxDate BETWEEN @PeriodFrom AND @PeriodTo

UNION ALL

SELECT 
	CONCAT('CN ' , t0.DocNum) as Type,
	T2.ItemCode,
	T2.ItemName,
	'Credit Memo' as TransType,
	T1.LineTotal * -1 AS Sales,
	T1.StockValue * -1  AS Cost,
	(T1.LineTotal - T1.StockValue) * -1 as GrossProfit,
	t1.OcrCode

FROM ORIN T0
INNER JOIN RIN1 T1 ON T1.Docentry = T0.Docnum
INNER JOIN OITM T2 ON T1.ItemCode = T2.Itemcode
WHERE T0.CANCELED = 'N' AND T1.BASETYPE <> 203
AND T0.TaxDate BETWEEN @PeriodFrom AND @PeriodTo

UNION ALL 

SELECT 
	CONCAT('CN ' , t0.DocNum) as Type,
	T2.ItemCode,
	T2.ItemName,
	'AP Invoice' as TransType,
	0 AS Sales,
	T1.LineTotal AS Cost,
	(T1.LineTotal - T1.StockValue) as GrossProfit,
	t1.OcrCode

FROM OPCH T0
INNER JOIN PCH1 T1 ON T1.Docentry = T0.Docnum
INNER JOIN OITM T2 ON T1.ItemCode = T2.Itemcode
WHERE T0.CANCELED = 'N' AND T1.WhsCode LIKE '%DS%'
AND T0.TaxDate BETWEEN @PeriodFrom AND @PeriodTo


) as TP

ORDER BY ITEMNAME ASC


------------			

