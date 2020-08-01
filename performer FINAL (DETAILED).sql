

DECLARE @PeriodFrom as Date = '2019-01-01'
DECLARE @PeriodTo as Date = '2020-07-30'
DECLARE @TOP AS Integer = 20
select TRANSTYPE,
TYPE as DocNumber,
taxDate as 'Document Date',
ItemType, Itemcode, ItemName,
Quantity,
Sales  AS 'Total Sales',
Cost  AS Cost,
Sales - Cost as 'Gross Profit',
CAST ( ( nullif( Sales, 0 ) -  nullif(Cost, 0 )) / nullif( Sales, 0 ) * 100 as MONEY ) as 'Gross Profit Percentage',
OCRCODE as Whse,
CASE WHEN BaseType = -1 THEN 'StandAlone'
WHEN BaseType = 13 THEN CONCAT('IN ', BaseDocNum) 
WHEN BaseType = 17 THEN 'Sales Order'
WHEN BaseType = 20 THEN 'GRPO'
WHEN BaseType = 22 THEN 'Purchase Order'
END AS 'Base Document'

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
	ELSE 'AR Invoice'
	END AS TransType,
	
	T1.Quantity,
	CASE WHEN t0.discsum > 0 THEN T1.StockSum
	else	T1.LineTotal
	END AS Sales,

	CASE WHEN T0.ISINS = 'Y' THEN	0
	WHEN t0.U_BO_DRS = 'Y' THEN	0
	ELSE	T1.STOCKVALUE
	END AS Cost,

	CASE WHEN t0.discsum > 0 THEN T1.StockSum 	-
							 CASE WHEN T0.ISINS = 'Y' THEN	0
							 WHEN t0.U_BO_DRS = 'Y' THEN	0
							 ELSE	T1.STOCKVALUE END
	ELSE					 T1.LineTotal	-
							 CASE WHEN T0.ISINS = 'Y' THEN	0
							 WHEN t0.U_BO_DRS = 'Y' THEN	0
							 ELSE	T1.STOCKVALUE END
	END AS GrossProfit,
	t1.OcrCode,
	t0.taxdate,
	T1.BaseDocNum,
	T1.BaseType,
	T3.ItmsGrpNam as ItemType

FROM OINV T0
INNER JOIN INV1 T1 ON T0.DOCNUM = T1.DOCENTRY
INNER JOIN OITM T2 ON T1.ITEMCODE = T2.ITEMCODE
INNER JOIN OITB T3 ON T2.ITMSGRPCOD = T3.ItmsGrpCod
WHERE T0.DOCTYPE = 'I' AND T0.CANCELED = 'N'
AND  T0.TaxDate BETWEEN @PeriodFrom AND @PeriodTo

UNION ALL

SELECT 
	CONCAT('DN ' , t0.DocNum) as Type,
	T2.ItemCode as ItemCode,
	T2.ItemName as ItemName,
	'Delivery' as TransType,
	T1.Quantity,
	0 as Sales,
	T1.StockValue as Cost,
	0 - T1.StockValue  as GrossProfit,
	t1.OcrCode,
	t0.taxdate,
	T1.BaseDocNum,
	T1.BaseType,
	T3.ItmsGrpNam as ItemType

FROM ODLN T0
INNER JOIN DLN1 T1 ON T1.Docentry = T0.Docnum
INNER JOIN OITM T2 ON T1.ItemCode = T2.Itemcode
INNER JOIN OITB T3 ON T2.ITMSGRPCOD = T3.ItmsGrpCod
WHERE T0.CANCELED = 'N'
AND T0.TaxDate BETWEEN @PeriodFrom AND @PeriodTo

UNION ALL

SELECT 
	CONCAT('CN ' , t0.DocNum) as Type,
	T2.ItemCode,
	T2.ItemName,
	'AR Credit Memo' as TransType,
	T1.Quantity,
	T1.LineTotal * -1 AS Sales,
	T1.StockValue * -1  AS Cost,
	(T1.LineTotal - T1.StockValue) * -1 as GrossProfit,
	t1.OcrCode,
	t0.taxdate,
	T1.BaseDocNum,
	T1.BaseType,
	T3.ItmsGrpNam as ItemType

FROM ORIN T0
INNER JOIN RIN1 T1 ON T1.Docentry = T0.Docnum
INNER JOIN OITM T2 ON T1.ItemCode = T2.Itemcode
INNER JOIN OITB T3 ON T2.ITMSGRPCOD = T3.ItmsGrpCod
WHERE T0.CANCELED = 'N' AND T1.BASETYPE <> 203
AND T0.TaxDate BETWEEN @PeriodFrom AND @PeriodTo

UNION ALL 

SELECT 
	CONCAT('PO ' , t0.DocNum) as Type,
	T2.ItemCode,
	T2.ItemName,
	'AP Invoice' as TransType,
	T1.Quantity,
	0 AS Sales,
	T1.LineTotal AS Cost,
	(T1.LineTotal - T1.StockValue) as GrossProfit,
	t1.OcrCode,
	t0.taxdate,
	T1.BaseDocNum,
	T1.BaseType,
	T3.ItmsGrpNam as ItemType

FROM OPCH T0
INNER JOIN PCH1 T1 ON T1.Docentry = T0.Docnum
INNER JOIN OITM T2 ON T1.ItemCode = T2.Itemcode
INNER JOIN OITB T3 ON T2.ITMSGRPCOD = T3.ItmsGrpCod
WHERE T0.CANCELED = 'N' AND T1.WhsCode LIKE '%DS%'
AND T0.TaxDate BETWEEN @PeriodFrom AND @PeriodTo


) as TP
--where  DocNumber = 'IN 11747' or 'Base Document' = 'IN 11747'

ORDER BY TaxDate, DocNumber ASC


------------			

