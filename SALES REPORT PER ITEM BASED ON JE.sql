	DECLARE @PeriodFrom as Date = '2020-06-1'
	DECLARE @PeriodTo as Date = '2020-06-2'

	SELECT
		TransactionType,Docnum,DocumentDate,CustomerCode,CustomerName,CustomerRefNo,
		ItemGroup,ItemCode,ItemName,UomCode,Price,QtySold, Store, JE,TotalSales,Cost,
		TotalSales - Cost as GrossProfit,Reference,ReferenceDate,RemainingBalance
	FROM (
			--standard AR
		SELECT
			--(SELECT JA.NUMBER FROM JDT1 JE
			--				  INNER JOIN OJDT JA ON JA.Number = JE.TransId
			--				  WHERE JA.TransType = 13 AND JA.BaseRef = T2.DOCNUM) AS JE
			0 AS JE
			,1 as Groupings
			,T2.Docnum AS BaseOrder
			,'AR Invoice' as TransactionType
			,CONCAT('IN ' , T2.docnum) as Docnum
			,T2.TaxDate as DocumentDate
			,T5.CardCode as CustomerCode
			,T5.CardName as CustomerName
			,T2.NumAtCard as CustomerRefNo
			,T6.ItmsGrpNam AS ItemGroup
			,T4.ItemCode as ItemCode
			,T4.ItemName as ItemName
			,T3.UomCode as UomCode
			--,ROUND((T3.PriceAfVAT / 1.12) , 2 ) as Price
			,T3.PRICE as Price
			,CASE WHEN T2.CANCELED = 'N' OR T2.CANCELED = 'Y' THEN
				T3.Quantity
			ELSE
				T3.Quantity * -1 END as QtySold
			,CASE WHEN T2.CANCELED = 'N' OR T2.CANCELED = 'Y' THEN
				ROUND((T3.PriceAfVAT / (1 + (SELECT rate/100 FROM VTG1 Ta where T3.VATGROUP = Ta.CODE))) * T3.Quantity  , 2 )
			ELSE 
				ROUND(((T3.PriceAfVAT / (1 + (SELECT rate/100 FROM VTG1 Ta where T3.VATGROUP = Ta.CODE))) * T3.Quantity) * -1  , 2 ) END AS TotalSales
			,CASE WHEN T2.CANCELED = 'N' OR T2.CANCELED = 'Y' THEN
				ROUND(T3.StockValue,2 )
			ELSE
				ROUND(T3.StockValue * -1 ,2 ) END as Cost
			,'' as Reference
			,'' as ReferenceDate
			,'N/A' as RemainingBalance
			,T3.OcrCode AS Store

			-- JE Table
			FROM OINV T2
			INNER JOIN INV1 T3 ON T2.DocNum = T3.DocEntry
			-- Item Table
			INNER JOIN OITM T4 ON T4.ItemCode = T3.ItemCode
			-- Business Partner Table
			INNER JOIN OCRD T5 ON T2.CardCode = T5.CardCode
			-- Item Group Name
			INNER JOIN OITB T6 ON T4.ItmsGrpCod = T6.ItmsGrpCod
			WHERE T2.ISINS = 'N' AND T2.U_BO_DRS = 'N'
			AND T2.TaxDate BETWEEN @PeriodFrom AND @PeriodTo

		UNION ALL
			-- AR RESERVE
		SELECT DISTINCT
			T0.NUMBER AS JE
			,1 as Groupings
			,T0.BaseRef AS BaseOrder
			,'AR Reserve' as TransactionType
			,CONCAT('IN ' , T0.BaseRef) as Docnum
			,T0.TaxDate as DocumentDate
			,T5.CardCode as CustomerCode
			,T5.CardName as CustomerName
			,T2.NumAtCard as CustomerRefNo
			,T6.ItmsGrpNam AS ItemGroup
			,T4.ItemCode as ItemCode
			,T4.ItemName as ItemName
			,T3.UomCode as UomCode
			--,ROUND((T3.PriceAfVAT / 1.12) , 2 ) as Price
			,T3.PRICE as Price
			,T3.Quantity - (SELECT ISNULL(SUM(TA.Quantity), 0) FROM DLN1 TA WHERE T3.DocEntry = TA.BaseDocNum AND T3.ItemCode = TA.ItemCode) as QtySold
			,ROUND((T3.PriceAfVAT / (1 + (SELECT TA.rate/100 FROM VTG1 Ta where T3.VATGROUP = Ta.CODE))) *  (T3.Quantity - (SELECT ISNULL(SUM(TA.Quantity), 0) FROM DLN1 TA WHERE T3.DocEntry = TA.BaseDocNum AND T3.ItemCode = TA.ItemCode))  , 2 ) as TotalSales
			,0 as Cost
			,'' as Reference
			,'' as ReferenceDate
			,'N/A' as RemainingBalance
			,T3.OcrCode AS Store

			-- JE Table
			FROM OJDT T0
			INNER JOIN JDT1 T1 ON T0.Number = T1.TransId
			-- Table for AR Invoice
			INNER JOIN OINV T2 ON T0.BaseRef = T2.DocNum
			INNER JOIN INV1 T3 ON T2.DocNum = T3.DocEntry
			-- Item Table
			INNER JOIN OITM T4 ON T4.ItemCode = T3.ItemCode
			-- Business Partner Table
			INNER JOIN OCRD T5 ON T2.CardCode = T5.CardCode
			-- Item Group Name
			INNER JOIN OITB T6 ON T4.ItmsGrpCod = T6.ItmsGrpCod
			WHERE (T1.Account = 'SA010000' OR T1.Account = 'RE010000') AND T2.ISINS = 'Y' AND T2.U_BO_DRS = 'N'	AND T2.TaxDate BETWEEN @PeriodFrom AND @PeriodTo
			AND T3.Quantity > (SELECT ISNULL(SUM(TA.Quantity), 0) FROM DLN1 TA 
								INNER JOIN ODLN TB ON TB.DOCNUM = TA.DOCENTRY
								WHERE T3.DocEntry = TA.BaseDocNum AND T3.ItemCode = TA.ItemCode AND TB.CANCELED = 'N' AND T3.LineNum = TA.LineNum) AND T2.CANCELED = 'N'

			UNION ALL

			---Delivery
		SELECT
			T0.NUMBER AS JE
			,2 as Groupings
			,T3.BASEDOCNUM AS BaseOrder
			,'Delivery' as TransactionType
			,CONCAT('IN ' , T3.BaseDocNum) as Docnum
			,(SELECT TA.TAXDATE FROM OINV TA WHERE TA.DOCNUM = T3.BaseDocNum) as DocumentDate
			,T5.CardCode as CustomerCode
			,T5.CardName as CustomerName
			,T2.NumAtCard as CustomerRefNo
			,T6.ItmsGrpNam AS ItemGroup
			,T4.ItemCode as ItemCode
			,T4.ItemName as ItemName
			,T3.UomCode as UomCode
			--,ROUND((T3.PriceAfVAT / 1.12) , 2 ) as Price
			,T3.PRICE as Price
			,T3.Quantity as QtySold

			,CASE WHEN (SELECT TA.TAXDATE FROM OINV TA WHERE TA.DOCNUM = T3.BaseDocNum AND TA.CANCELED = 'N') BETWEEN @PeriodFrom AND @PeriodTo THEN
				ROUND((T3.PriceAfVAT / (1 + (SELECT rate/100 FROM VTG1 Ta where T3.VATGROUP = Ta.CODE))) * T3.Quantity  , 2 )
			ELSE 0 END as TotalSales

			,CASE WHEN T2.TaxDate BETWEEN @PeriodFrom AND @PeriodTo THEN
				ROUND(T3.StockValue,2 )
			ELSE 0 END as Cost

			,CONCAT('DN ' , T0.BaseRef) as Reference
			,CONVERT(varchar, (SELECT T0.TaxDate FROM OINV TA WHERE TA.DOCNUM = T3.BaseDocNum), 107) as ReferenceDate
			,CONVERT(varchar(MAX), QtyToShip) As RemainingBalance
			,T3.OcrCode AS Store

			-- JE Table
			FROM OJDT T0
			INNER JOIN JDT1 T1 ON T0.Number = T1.TransId
			-- Table for Deliveries
			INNER JOIN ODLN T2 ON T0.BaseRef = T2.DocNum
			INNER JOIN DLN1 T3 ON T2.DocNum = T3.DocEntry
			-- Item Table
			INNER JOIN OITM T4 ON T4.ItemCode = T3.ItemCode
			-- Business Partner Table
			INNER JOIN OCRD T5 ON T2.CardCode = T5.CardCode
			-- Item Group Name
			INNER JOIN OITB T6 ON T4.ItmsGrpCod = T6.ItmsGrpCod
			WHERE T0.TransType = 15 AND (T1.Account = 'SA010000' OR T1.Account = 'RE010000')
			AND T2.Canceled = 'N'
			AND ((SELECT TA.TAXDATE FROM OINV TA WHERE TA.DOCNUM = T3.BaseDocNum) BETWEEN @PeriodFrom AND @PeriodTo OR (T2.TaxDate  BETWEEN @PeriodFrom AND @PeriodTo))

			UNION ALL

			---AR CM // SALES
		SELECT
			T0.NUMBER AS JE
			,3 as Groupings
			,T3.BASEDOCNUM AS BaseOrder
			,'A/R CM' as TransactionType
			,CONCAT('CN ' , T0.BaseRef) as Docnum
			,T0.TaxDate as DocumentDate
			,T5.CardCode as CustomerCode
			,T5.CardName as CustomerName
			,T2.NumAtCard as CustomerRefNo
			,T6.ItmsGrpNam AS ItemGroup
			,T4.ItemCode as ItemCode
			,T4.ItemName as ItemName
			,T3.UomCode as UomCode
			--,ROUND((T3.PriceAfVAT / 1.12) , 2 ) * -1 as Price
			,T3.PRICE as Price
			,T3.Quantity * -1  as QtySold
			,ROUND(((T3.PriceAfVAT / (1 + (SELECT rate/100 FROM VTG1 Ta where T3.VATGROUP = Ta.CODE))) * T3.Quantity ) * -1, 2 ) as TotalSales
			,CASE WHEN EXISTS(SELECT TA.DOCENTRY FROM OINV TA WHERE TA.DOCNUM = T3.BASEDOCNUM AND TA.isIns = 'Y') THEN
				CASE WHEN NOT EXISTS(SELECT TA.DOCENTRY FROM DLN1 TA WHERE T3.BaseDocNum = TA.BaseDocNum) THEN
					0
				ELSE
					CASE WHEN  EXISTS(SELECT TB.ACCOUNT FROM OJDT TA INNER JOIN JDT1 TB ON TA.NUMBER = TB.TRANSID WHERE TA.BASEREF = T2.DOCNUM AND TA.TRANSTYPE = 14 AND TB.Account = 'SA010000') THEN
						ROUND(T3.StockValue * -1 ,2 )
					ELSE 
						0 
					END
				END
			ELSE
				ROUND (T3.StockValue * -1 ,2 )
			END AS COST
			,CONCAT('IN ' , T3.BASEDOCNUM) as Reference
			,'' as ReferenceDate
			,'N/A' as RemainingBalance
			,T3.OcrCode AS Store

			-- JE Table
			FROM OJDT T0
			INNER JOIN JDT1 T1 ON T0.Number = T1.TransId AND T1.Account = 'RE010000'
			-- Table for Deliveries
			INNER JOIN ORIN T2 ON T0.BaseRef = T2.DocNum
			INNER JOIN RIN1 T3 ON T2.DocNum = T3.DocEntry
			-- Item Table
			INNER JOIN OITM T4 ON T4.ItemCode = T3.ItemCode
			-- Business Partner Table
			INNER JOIN OCRD T5 ON T2.CardCode = T5.CardCode
			-- Item Group Name
			INNER JOIN OITB T6 ON T4.ItmsGrpCod = T6.ItmsGrpCod
			WHERE T0.TransType = 14 AND (T1.Account = 'RE010000')
			AND T2.Canceled = 'N'
			AND ((SELECT TA.TAXDATE FROM OINV TA WHERE TA.DOCNUM = T3.BaseDocNum) BETWEEN @PeriodFrom AND @PeriodTo OR (T2.TaxDate  BETWEEN @PeriodFrom AND @PeriodTo))

		UNION ALL

			-- DS
	SELECT
			T0.NUMBER AS JE
			,1 as Groupings
			,T0.BaseRef AS BaseOrder
			,'DropShip' as TransactionType
			,CONCAT('IN ' , T0.BaseRef) as Docnum
			,T0.TaxDate as DocumentDate
			,T5.CardCode as CustomerCode
			,T5.CardName as CustomerName
			,T2.NumAtCard as CustomerRefNo
			,T6.ItmsGrpNam AS ItemGroup
			,T4.ItemCode as ItemCode
			,T4.ItemName as ItemName
			,T3.UomCode as UomCode
			--,ROUND((T3.PriceAfVAT / 1.12) , 2 ) as Price
			,T3.PRICE as Price
			,CASE WHEN T2.CANCELED = 'N' OR T2.CANCELED = 'Y' THEN
				T3.Quantity
			ELSE
				T3.Quantity * -1 END as QtySold
			,CASE WHEN T2.CANCELED = 'N' OR T2.CANCELED = 'Y' THEN

				CASE WHEN T2.TaxDate  BETWEEN @PeriodFrom AND @PeriodTo THEN
				ROUND((T3.PriceAfVAT / (1 + (SELECT rate/100 FROM VTG1 Ta where T3.VATGROUP = Ta.CODE))) * T3.Quantity  , 2 )
				ELSE 0 END 
				
			ELSE 

				CASE WHEN T2.TaxDate  BETWEEN @PeriodFrom AND @PeriodTo THEN
				ROUND(((T3.PriceAfVAT / (1 + (SELECT rate/100 FROM VTG1 Ta where T3.VATGROUP = Ta.CODE))) * T3.Quantity) * -1, 2)
				END
			END AS TotalSales
			,CASE WHEN T2.CANCELED = 'N' OR T2.CANCELED = 'Y' THEN

				CASE WHEN (SELECT TOP 1 TA.TAXDATE FROM OPCH TA
							INNER JOIN PCH1 TB ON TA.DocNum = TB.DocEntry
							INNER JOIN POR1 PA ON TB.BaseRef = PA.DocEntry
							WHERE T3.BASEREF = PA.BASEREF AND TB.WhsCode LIKE '%DS%' AND TB.ItemCode = PA.ItemCode
							AND TB.BASETYPE = 22 AND PA.BASETYPE = 17) BETWEEN @PeriodFrom AND @PeriodTo  OR T2.TaxDate  BETWEEN @PeriodFrom AND @PeriodTo THEN
							isnull((SELECT TOP 1 Tb.LineTotal FROM OPCH TA
							INNER JOIN PCH1 TB ON TA.DocNum = TB.DocEntry
							INNER JOIN POR1 PA ON TB.BaseRef = PA.DocEntry
							WHERE T3.BASEREF = PA.BASEREF AND TB.WhsCode LIKE '%DS%' AND TB.ItemCode = PA.ItemCode
							AND TB.BASETYPE = 22 AND PA.BASETYPE = 17), 0 )
				ELSE 0 END 
				
			ELSE 

				CASE WHEN (SELECT TOP 1 TA.TAXDATE FROM OPCH TA
							INNER JOIN PCH1 TB ON TA.DocNum = TB.DocEntry
							INNER JOIN POR1 PA ON TB.BaseRef = PA.DocEntry
							WHERE T3.BASEREF = PA.BASEREF AND TB.WhsCode LIKE '%DS%' AND TB.ItemCode = PA.ItemCode
							AND TB.BASETYPE = 22 AND PA.BASETYPE = 17) BETWEEN @PeriodFrom AND @PeriodTo OR T2.TaxDate  BETWEEN @PeriodFrom AND @PeriodTo THEN
								isnull((SELECT TOP 1 Tb.LineTotal FROM OPCH TA
							INNER JOIN PCH1 TB ON TA.DocNum = TB.DocEntry
							INNER JOIN POR1 PA ON TB.BaseRef = PA.DocEntry
							WHERE T3.BASEREF = PA.BASEREF AND TB.WhsCode LIKE '%DS%' AND TB.ItemCode = PA.ItemCode
							AND TB.BASETYPE = 22 AND PA.BASETYPE = 17) * -1 , 0 )
				END
			END AS Cost
			,'' as Reference
			,'' as ReferenceDate
			,'N/A' as RemainingBalance
			,T3.OcrCode AS Store

			-- JE Table
			FROM OJDT T0
			INNER JOIN JDT1 T1 ON T0.Number = T1.TransId
			-- Table for AR Invoice
			INNER JOIN OINV T2 ON T0.BaseRef = T2.DocNum
			INNER JOIN INV1 T3 ON T2.DocNum = T3.DocEntry
			-- Item Table
			INNER JOIN OITM T4 ON T4.ItemCode = T3.ItemCode
			-- Business Partner Table
			INNER JOIN OCRD T5 ON T2.CardCode = T5.CardCode
			-- Item Group Name
			INNER JOIN OITB T6 ON T4.ItmsGrpCod = T6.ItmsGrpCod
			WHERE (T1.Account = 'RE010000') AND T2.ISINS = 'N' AND T2.U_BO_DRS = 'Y' AND 
			((SELECT TOP 1 TA.TAXDATE FROM OPCH TA
			INNER JOIN PCH1 TB ON TA.DocNum = TB.DocEntry
			INNER JOIN POR1 PA ON TB.BaseRef = PA.DocEntry
			WHERE T3.BASEREF = PA.BASEREF AND TB.WhsCode LIKE '%DS%' AND TB.ItemCode = PA.ItemCode
			AND TB.BASETYPE = 22 AND PA.BASETYPE = 17) BETWEEN @PeriodFrom AND @PeriodTo 
			OR T2.TaxDate  BETWEEN @PeriodFrom AND @PeriodTo)

		UNION ALL

		SELECT DISTINCT 
			T0.NUMBER AS JE
			,5 as Groupings
			,T0.BaseRef AS BaseOrder
			,'Goods Receipt' as TransactionType
			,CONCAT('SI ' , T0.BaseRef) as Docnum
			,T0.TaxDate as DocumentDate
			,'-' as CustomerCode
			,'-' as CustomerName
			,T2.NumAtCard as CustomerRefNo
			,T6.ItmsGrpNam AS ItemGroup
			,T4.ItemCode as ItemCode
			,T4.ItemName as ItemName
			,T3.UomCode as UomCode
			--,ROUND((T3.PriceAfVAT / 1.12) , 2 ) as Price
			,T3.PRICE as Price
			,CASE WHEN T2.CANCELED = 'N' OR T2.CANCELED = 'Y' THEN
				T3.Quantity
			ELSE
				T3.Quantity * -1 END as QtySold
			,0 AS TotalSales
			,T3.LineTotal * -1 as Cost
			,'' as Reference
			,'' as ReferenceDate
			,'N/A' as RemainingBalance
			,T3.OcrCode AS Store

			-- JE Table
			FROM OJDT T0
			INNER JOIN JDT1 T1 ON T0.Number = T1.TransId
			INNER JOIN OIGN T2 ON T0.BaseRef = T2.DocNum
			INNER JOIN IGN1 T3 ON T2.DocNum = T3.DocEntry
			-- Item Table
			INNER JOIN OITM T4 ON T4.ItemCode = T3.ItemCode
			-- Item Group Name
			INNER JOIN OITB T6 ON T4.ItmsGrpCod = T6.ItmsGrpCod
			WHERE T2.TaxDate BETWEEN @PeriodFrom AND @PeriodTo AND T0.TransType = 59 AND (T1.Account = 'SA010000')


		) AS SRPI
	ORDER BY  BaseOrder, DocumentDate,  Groupings ASC

