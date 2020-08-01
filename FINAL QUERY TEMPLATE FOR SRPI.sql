			
	DECLARE @PeriodFrom as Date = '2020-07-24'
	DECLARE @PeriodTo as Date = '2020-07-27'
	
	SELECT
		DocType,	DocNumber,	DocName,
		DocDate,	ItemGroup,	ItemCode,
		ItemName,	UomCode,	QtySold,
		Price,		TotalSales,	Cost,
		TotalSales - Cost as GrossProfit,
		Reference,	ReferenceDate, RemainingBalance
	FROM (
		--- STANDARD AR INVOICE
		SELECT 
			1 as Groupings,
			'AR Invoice' as DocType,
			T0.DocNum as DocNumber,
			CONCAT('IN ' , T0.Docnum) as DocName,
			T0.TaxDate as DocDate,
			T3.ItmsGrpNam AS ItemGroup,
			T2.ItemCode,
			T2.ItemName,
			T1.UomCode,
			T1.Quantity as QtySold,
			T1.Price as Price,
			T1.StockSum as TotalSales,
			T1.StockValue as Cost,
			'' as Reference,
			'' as ReferenceDate,
			'N/A' as RemainingBalance

		FROM OINV T0
		INNER JOIN INV1 T1 ON T0.DOCNUM = T1.DocEntry
		INNER JOIN OITM T2 ON T1.ItemCode = T2.ItemCode
		INNER JOIN OITB T3 ON T2.ItmsGrpCod = T3.ItmsGrpCod
		WHERE T0.U_BO_DRS <> 'Y' AND T0.isIns = 'N' AND T0.CANCELED = 'N'
		AND T0.TaxDate BETWEEN @PeriodFrom AND @PeriodTo

	UNION ALL
		-- AR RESERVE
		SELECT 
			2 as Groupings,
			'AR Reserve' as DocType,
			T0.DocNum as DocNumber,
			CONCAT('IN ' , T0.Docnum) as DocName,
			T0.TaxDate as DocDate,
			T3.ItmsGrpNam AS ItemGroup,
			T2.ItemCode,
			T2.ItemName,
			T1.UomCode,
			--T1.OpenQty as QtySold,
			--T1.Quantity as QtySold,
			--CASE WHEN TargetType = 14 THEN T1.Quantity
			--ELSE T1.OpenQty END AS QtySold,
			--T1.Price as Price,

			--T1.OpenQty as QtySold,
			T1.Quantity AS QtySold,
			T1.Price as Price,
			T1.Quantity * T1.Price as TotalSales,
			--T1.OpenQty * T1.PRICE as TotalSales,

			--CASE WHEN TargetType = 14 THEN T1.Quantity * T1.PRICE
			--ELSE T1.OpenQty * T1.PRICE END AS TotalSales,


			--T1.OpenQty * T1.PRICE AS TotalSales,
			--0 as Price,
			--0 AS TotalSales,
			0 as Cost,
			'' as Reference,
			'' as ReferenceDate,
			'N/A' as RemainingBalance

		FROM OINV T0
		INNER JOIN INV1 T1 ON T0.DOCNUM = T1.DocEntry
		INNER JOIN OITM T2 ON T1.ItemCode = T2.ItemCode
		INNER JOIN OITB T3 ON T2.ItmsGrpCod = T3.ItmsGrpCod
		WHERE T0.U_BO_DRS <> 'Y' AND T0.isIns = 'Y' AND T0.CANCELED = 'N'
		AND T0.TaxDate BETWEEN @PeriodFrom AND @PeriodTo
		AND T0.DOCNUM NOT IN (SELECT BaseDocNum FROM DLN1 WHERE BASETYPE = 13)

	UNION ALL 

		--- DELIVERY
		SELECT 
			3 as Groupings,
			'Delivery' as DocType,
			T1.BaseDocNum as DocNumber,
			CONCAT('IN ' , T1.BaseDocNum) as DocName,
			(SELECT TA.TAXDATE FROM OINV TA WHERE TA.DOCNUM = T1.BaseDocNum) as DocDate,
			T3.ItmsGrpNam AS ItemGroup,
			T2.ItemCode,
			T2.ItemName,
			T1.UomCode,
			T1.Quantity AS QtySold,
			(SELECT TA.PRICE FROM INV1 TA WHERE TA.DOCENTRY = T1.BaseDocNum AND TA.ItemCode = T2.ItemCode AND T1.BASETYPE = 13 AND TA.UomCode = T1.UomCode
			AND T1.LineNum = TA.LineNum) as Price,
			T1.StockSum AS TotalSales,
			T1.StockValue as Cost,
			CONCAT('DN ' , T0.DocNum) as Reference,
			--CONVERT(varchar, (SELECT TA.TAXDATE FROM OINV TA WHERE TA.DOCNUM = T1.BaseDocNum), 107) as ReferenceDate,
			CONVERT(varchar, (SELECT T0.TaxDate FROM OINV TA WHERE TA.DOCNUM = T1.BaseDocNum), 107) as ReferenceDate,
			CONVERT(varchar(MAX), QtyToShip) as RemainingBalance

		FROM ODLN T0
		INNER JOIN DLN1 T1 ON T0.DOCNUM = T1.DocEntry
		INNER JOIN OITM T2 ON T1.ItemCode = T2.ItemCode
		INNER JOIN OITB T3 ON T2.ItmsGrpCod = T3.ItmsGrpCod
		WHERE T0.CANCELED = 'N'
		AND (SELECT TA.TAXDATE FROM OINV TA WHERE TA.DOCNUM = T1.BaseDocNum) BETWEEN @PeriodFrom AND @PeriodTo

	UNION ALL 

		--- A/R CM / W REFERENCE
		SELECT 
			4 as Groupings,
			'A/R CM' as DocType,
			T1.BaseDocNum as DocNumber,
			CONCAT('CM ' , T0.DocNum) as DocName,
			T0.TaxDate as DocDate,
			T3.ItmsGrpNam AS ItemGroup,
			T2.ItemCode,
			T2.ItemName,
			T1.UomCode,
			T1.Quantity * -1  as QtySold,
			--(SELECT TA.PRICE FROM INV1 TA WHERE TA.DOCENTRY = T1.BaseDocNum AND TA.ItemCode = T2.ItemCode AND T1.LineNum = TA.LineNum AND TA.UomCode = T1.UomCode AND T1.BASETYPE = 13)  * -1 as Price,
			(T1.LineTotal / T1.Quantity) * -1 as Price,
			T1.LineTotal * -1 AS TotalSales,
			--ISNULL((SELECT TA.StockValue FROM DLN1 TA WHERE TA.BaseDocNum = T1.BaseDocNum AND TA.ItemCode = T2.ItemCode AND T1.LineNum = TA.LineNum), 0) * -1 as Cost,
			CASE WHEN EXISTS(SELECT TB.DOCENTRY FROM OINV TB WHERE T1.BaseDocNum = TB.DocNum AND TB.ISINS = 'Y') THEN
				CASE WHEN NOT EXISTS(SELECT TA.DOCENTRY FROM DLN1 TA WHERE T1.BaseDocNum =TA.BaseDocNum ) THEN 
					0
				ELSE 
					T1.StockValue * -1 
				END
			ELSE
				T1.STOCKVALUE * -1 
			END AS Cost,
			CONCAT('IN ' , T1.BaseDocNum) as Reference,
			'' as ReferenceDate,
			'N/A' as RemainingBalance

		FROM ORIN T0
		INNER JOIN RIN1 T1 ON T0.DOCNUM = T1.DocEntry
		INNER JOIN OITM T2 ON T1.ItemCode = T2.ItemCode
		INNER JOIN OITB T3 ON T2.ItmsGrpCod = T3.ItmsGrpCod
		WHERE T0.CANCELED = 'N'
		AND (SELECT TA.TAXDATE FROM OINV TA WHERE TA.DOCNUM = T1.BaseDocNum) BETWEEN @PeriodFrom AND @PeriodTo

	--UNION ALL 

	--	--- A/R CM / STANDALONE
	--	SELECT 
	--		5 as Groupings,
	--		'A/R CM - Standalone' as DocType,
	--		T0.DocNum as DocNumber,
	--		CONCAT('CM ' , T0.DocNum) as DocName,
	--		T0.TaxDate as DocDate,
	--		T3.ItmsGrpNam AS ItemGroup,
	--		T2.ItemCode,
	--		T2.ItemName,
	--		T1.UomCode,
	--		T1.Quantity * -1  as QtySold,
	--		CASE WHEN T1.LineTotal = 0 THEN 
	--			0
	--		ELSE 
	--			(T1.LineTotal / T1.Quantity) * -1
	--		END as Price,
	--		CASE WHEN T1.LineTotal = 0 THEN 
	--			0
	--		ELSE 
	--			T1.LineTotal * -1
	--		END as TotalSales,
	--		CASE WHEN EXISTS(SELECT TB.DOCENTRY FROM OINV TB WHERE T1.BaseDocNum = TB.DocNum AND TB.ISINS = 'Y') THEN
	--			CASE WHEN NOT EXISTS(SELECT TA.DOCENTRY FROM DLN1 TA WHERE T1.BaseDocNum =TA.BaseDocNum ) THEN 
	--				0
	--			ELSE 
	--				T1.StockValue * -1 
	--			END
	--		ELSE
	--			T1.STOCKVALUE * -1 
	--		END AS Cost,
	--		CONCAT('IN ' , T1.BaseDocNum) as Reference,
	--		'' as ReferenceDate,
	--		'N/A' as RemainingBalance

	--	FROM ORIN T0
	--	INNER JOIN RIN1 T1 ON T0.DOCNUM = T1.DocEntry
	--	INNER JOIN OITM T2 ON T1.ItemCode = T2.ItemCode
	--	INNER JOIN OITB T3 ON T2.ItmsGrpCod = T3.ItmsGrpCod
	--	WHERE T0.CANCELED = 'N' AND T1.BASETYPE = -1
	--	AND T0.TaxDate BETWEEN @PeriodFrom AND @PeriodTo


	) AS StanARInv

	
	ORDER BY DocNumber, DocDate, Groupings ASC
