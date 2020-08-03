	DECLARE @PeriodFrom as Date = '2020-07-24'
	DECLARE @PeriodTo as Date = '2020-08-3'

	SELECT
		JE,TransactionType,Docnum,DocumentDate,CustomerCode,CustomerName,CustomerRefNo,
		ItemGroup,ItemCode,ItemName,UomCode,Price,QtySold,TotalSales,Cost,
		TotalSales - Cost as GrossProfit,Reference,ReferenceDate,RemainingBalance
	FROM (
			--standard AR
		SELECT DISTINCT
			T0.NUMBER AS JE
			,1 as Groupings
			,T0.BaseRef AS BaseOrder
			,'AR Invoice' as TransactionType
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
			,T3.Quantity as QtySold
			,(T3.PriceAfVAT / (1 + (SELECT rate/100 FROM VTG1 Ta where T3.VATGROUP = Ta.CODE))) * T3.Quantity  as TotalSales
			,T3.StockValue as Cost
			,'' as Reference
			,'' as ReferenceDate
			,'N/A' as RemainingBalance

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
			WHERE (T1.Account = 'SA010000' OR T1.Account = 'RE010000') AND T2.ISINS = 'N' AND T2.U_BO_DRS = 'N'
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

			,T3.Quantity - (SELECT ISNULL(SUM(TA.Quantity), 0) FROM DLN1 TA WHERE T3.DocEntry = TA.BaseDocNum AND T3.ItemCode = TA.ItemCode)


			--,T3.OpenQty as QtySold

			,(T3.PriceAfVAT / (1 + (SELECT rate/100 FROM VTG1 Ta where T3.VATGROUP = Ta.CODE))) *  (T3.Quantity - (SELECT ISNULL(SUM(TA.Quantity), 0) FROM DLN1 TA WHERE T3.DocEntry = TA.BaseDocNum AND T3.ItemCode = TA.ItemCode)) as TotalSales
			,0 as Cost
			,'' as Reference
			,'' as ReferenceDate
			,'N/A' as RemainingBalance

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
			--AND T2.DOCNUM NOT IN (SELECT TA.BaseDocNum FROM DLN1 TA 
			--					  INNER JOIN ODLN TB ON TB.DOCNUM = TA.DOCENTRY WHERE TA.BASETYPE = 13 AND TB.CANCELED = 'N')
			--AND T3.DelivrdQty < T3.Quantity AND T3.OpenQty = 0
			AND T3.Quantity <> (SELECT ISNULL(SUM(TA.Quantity), 0) FROM DLN1 TA 
								INNER JOIN ODLN TB ON TB.DOCNUM = TA.DOCENTRY
								WHERE T3.DocEntry = TA.BaseDocNum AND T3.ItemCode = TA.ItemCode AND TB.CANCELED = 'N')

			UNION ALL

			---Delivery
		SELECT DISTINCT
			T0.NUMBER AS JE
			,2 as Groupings
			,T3.BASEDOCNUM AS BaseOrder
			,'Delivery' as TransactionType
			,CONCAT('IN ' , T3.BaseDocNum) as Docnum
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
			,T3.Quantity as QtySold
			,(T3.PriceAfVAT / (1 + (SELECT rate/100 FROM VTG1 Ta where T3.VATGROUP = Ta.CODE))) * T3.Quantity  as TotalSales
			,T3.StockValue as Cost
			,CONCAT('DN ' , T0.BaseRef) as Reference
			,CONVERT(varchar, (SELECT T0.TaxDate FROM OINV TA WHERE TA.DOCNUM = T3.BaseDocNum), 107) as ReferenceDate
			,CONVERT(varchar(MAX), QtyToShip) as RemainingBalance

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
			AND (SELECT TA.TAXDATE FROM OINV TA WHERE TA.DOCNUM = T3.BaseDocNum) BETWEEN @PeriodFrom AND @PeriodTo

			UNION ALL

			---AR CM // SALES
		SELECT DISTINCT
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
			,((T3.PriceAfVAT / (1 + (SELECT rate/100 FROM VTG1 Ta where T3.VATGROUP = Ta.CODE))) * T3.Quantity ) * -1 as TotalSales
			,CASE WHEN EXISTS(SELECT TA.DOCENTRY FROM OINV TA WHERE TA.DOCNUM = T3.BASEDOCNUM AND TA.isIns = 'Y') THEN
				CASE WHEN NOT EXISTS(SELECT TA.DOCENTRY FROM DLN1 TA WHERE T3.BaseDocNum = TA.BaseDocNum) THEN
					0
				ELSE
					T3.StockValue * -1 
				END
			ELSE
				T3.StockValue * -1 
			END AS COST
			,CONCAT('IN ' , T3.BASEDOCNUM) as Reference
			,'' as ReferenceDate
			,'N/A' as RemainingBalance

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
			AND (SELECT TA.TAXDATE FROM OINV TA WHERE TA.DOCNUM = T3.BaseDocNum) BETWEEN @PeriodFrom AND @PeriodTo


		) AS SRPI
	ORDER BY BaseOrder, DocumentDate, Groupings ASC
