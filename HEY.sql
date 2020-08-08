



	DECLARE @PeriodFrom as Date = '2020-06-1'
	DECLARE @PeriodTo as Date = '2020-06-2'

SELECT 
t0.number as JEEntry,
t0.taxdate,
CASE WHEN T0.TRANSTYPE = 69 THEN CONCAT(T0.Transtype, ' - Landed Costs')
WHEN T0.TransType = 15 THEN  CONCAT(T0.Transtype, ' - Delivery')
WHEN T0.TransType = 310000001 then  CONCAT(T0.Transtype, ' - Inventory Opening Balance')
WHEN T0.TransType = 67 then CONCAT(T0.Transtype, ' - Inventory Transfer')
WHEN T0.TransType = 21 then CONCAT(T0.Transtype, ' - Goods Return')
WHEN T0.TransType = 18 then CONCAT(T0.Transtype, ' - A/P Invoice')
WHEN T0.TransType = 19 then CONCAT(T0.Transtype, ' - A/P Credit Memo')
WHEN T0.TransType = 13 then CONCAT(T0.Transtype, ' - A/R Invoice')
WHEN T0.TransType = 162 then CONCAT(T0.Transtype, ' - Inventory Reevaluation')
WHEN T0.TransType = 59 then CONCAT(T0.Transtype, ' - Goods Receipt')
WHEN T0.TransType = 60 then CONCAT(T0.Transtype, ' - Goods Issue')
WHEN T0.TransType = 20 then CONCAT(T0.Transtype, ' - GRPO')
WHEN T0.TransType = 14 then CONCAT(T0.Transtype, ' - A/R Credit Memo')
WHEN T0.TransType = 30 then CONCAT(T0.Transtype, ' - Journal Entry')
WHEN T0.TransType = 24 then CONCAT(T0.Transtype, ' - Incoming Payment')
WHEN T0.TransType = 25 then CONCAT(T0.Transtype, ' - Deposit')
WHEN T0.TransType = 46 then CONCAT(T0.Transtype, ' - Outgoing Payments')
WHEN T0.TransType = 203 then CONCAT(T0.Transtype, ' - A/R Downpayment')
WHEN T0.TransType = 204 then CONCAT(T0.Transtype, ' - A/P Downpayment')
WHEN T0.TransType = -2 then CONCAT(T0.Transtype, ' - Opening Balance')
WHEN T0.TransType = 1470000090 then CONCAT(T0.Transtype, ' - Asset Transfer')
WHEN T0.TransType = 321 then CONCAT(T0.Transtype, ' - Internal Reconciliation')
WHEN T0.TransType = 1470000049 then CONCAT(T0.Transtype, ' - Capitalization')
WHEN T0.TransType = 1470000071 then CONCAT(T0.Transtype, ' - Depreciation Run')
WHEN T0.TransType = 1470000075 then CONCAT(T0.Transtype, ' - Manual Depreciation')
WHEN T0.TransType = -4 then CONCAT(T0.Transtype, ' - BN')
END AS TransactionType,
'----------------------------',
CONCAT(
CASE WHEN T0.TRANSTYPE = 69 THEN 'IF '
WHEN T0.TransType = 15 THEN 'DN '
WHEN T0.TransType = 310000001 then 'OB '
WHEN T0.TransType = 67 then 'IM '
WHEN T0.TransType = 21 then 'PR '
WHEN T0.TransType = 18 then 'PU '
WHEN T0.TransType = 19 then 'PC '
WHEN T0.TransType = 13 then 'IN '
WHEN T0.TransType = 162 then 'MR '
WHEN T0.TransType = 59 then 'SI '
WHEN T0.TransType = 60 then 'SO '
WHEN T0.TransType = 20 then 'PD '
WHEN T0.TransType = 14 then 'CN '
WHEN T0.TransType = 30 then 'JE '
WHEN T0.TransType = 24 then 'RC '
WHEN T0.TransType = 25 then 'DP '
WHEN T0.TransType = 46 then 'PS '
WHEN T0.TransType = 203 then 'DT '
WHEN T0.TransType = 204 then 'DT '
WHEN T0.TransType = -2 then 'OB '
WHEN T0.TransType = 1470000090 then 'FT '
WHEN T0.TransType = 321 then 'JR '
WHEN T0.TransType = 1470000049 then 'AC '
WHEN T0.TransType = 1470000071 then 'DR '
WHEN T0.TransType = 1470000075 then 'MD '
WHEN T0.TransType = -4 then 'BN '
END,+ CAST(T0.BaseRef AS varchar)  ) as 'Base Reference',

CASE WHEN T0.MEMO <> T1.LINEMEMO THEN
concat(t0.Memo,' : ', T1.LineMemo)
ELSE t0.Memo
END as 'Brief Description',
T1.ACCOUNT,
T1.Credit as Credit,
T1.Debit as Debit

FROM OJDT t0 
INNER JOIN JDT1 T1 ON T0.NUMBER = T1.TRANSID 
LEFT OUTER JOIN OACT T2 ON T1.ACCOUNT = T2.AcctCode
WHERE (T1.Account = 'SA010000' OR T1.Account = 'RE010000')
AND T0.TaxDate BETWEEN @PeriodFrom AND @PeriodTo
ORDER BY T0.taxdate, T1.BaseRef ASC

--select * from jdt1 
