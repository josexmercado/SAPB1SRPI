

DECLARE @PeriodFrom as Date = '2020-07-24'
DECLARE @PeriodTo as Date = '2020-07-24'

SELECT
	'Delivery' as TransType,
	CASE WHEN T1.BaseType = 13 THEN
		CONCAT('IN ' , T1.BaseDocNum)
	ELSE
		CONCAT('DOC ' , T1.BaseDocNum)
	END AS DocNum,
	t0.taxdate as DocDate,
	T3.ItmsGrpNam as ItemType,
	T2.ItemCode as ItemCode,
	T2.ItemName as ItemName,

	T1.Quantity,

		--( SELECT T1.Quantity * Price
		--	FROM OINV TB
		--	INNER JOIN INV1 TA ON TB.DOCNUM = TA.DOCENTRY WHERE 
		--	TA.DocEntry = T1.BaseDocNum AND TA.ITEMCODE = T1.ITEMCODE
		--	AND TB.TaxDate BETWEEN @PeriodFrom AND @PeriodTo 
		--	AND T1.LineNum = TA.LineNum
		--	AND TB.CANCELED = 'N') as Sales,
	T4.PRICE,
	T1.Quantity * T4.PRICE AS TotalSales,
	T1.StockValue as Cost,

	(T1.Quantity * T4.PRICE) - T1.StockValue  as GrossProfit,

	t1.OcrCode,

	CONCAT('DN ' , t0.DocNum) as ReferenceNumber
	


FROM ODLN T0
INNER JOIN DLN1 T1 ON T1.Docentry = T0.Docnum
INNER JOIN OITM T2 ON T1.ItemCode = T2.Itemcode
INNER JOIN OITB T3 ON T2.ITMSGRPCOD = T3.ItmsGrpCod
INNER JOIN INV1 T4 ON T4.DocEntry = T1.BaseDocNum AND T1.ITEMCODE = T4.ItemCode
INNER JOIN OINV T5 ON T5.DOCNUM = T4.DocEntry
WHERE T0.CANCELED = 'N' AND T1.BASETYPE	= 13
AND (T0.TaxDate BETWEEN @PeriodFrom AND @PeriodTo
OR T5.TaxDate BETWEEN @PeriodFrom AND @PeriodTo)
--AND T5.DOCNUM = 18666
AND T5.DOCNUM = 16669
GROUP BY T1.BASETYPE, T1.BaseDocNum, T0.TAXDATE, T3.ItmsGrpNam, T2.ItemCode, T2.ItemName, T1.Quantity, T4.Price, T1.StockValue, T1.OcrCode, T0.DocNum, T5.DocNum
ORDER BY t5.docnum ASC




--select stockprice, price, linetotal, * from inv1 where DocEntry = 12250