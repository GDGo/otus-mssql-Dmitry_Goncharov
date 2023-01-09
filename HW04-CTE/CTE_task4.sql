USE [WideWorldImporters];
GO

;WITH Top_Item_Price_CTE
	AS
	(
	SELECT top(3) [StockItemID]
	FROM [WideWorldImporters].[Warehouse].[StockItems]
	ORDER BY [UnitPrice] DESC
	),
Sales_Invoices_CTE
	AS
	(
		SELECT [CustomerID]
			  ,[PackedByPersonID]
		  FROM [WideWorldImporters].[Sales].[Invoices]
		  where InvoiceID in (SELECT [InvoiceID]
								FROM [WideWorldImporters].[Sales].[InvoiceLines]
								where StockItemID in (SELECT * FROM Top_Item_Price_CTE))
	)
SELECT [DeliveryCityID]
	  ,Cities.CityName
	  ,[PackedByPersonID]
	  ,People.FullName
  FROM Sales_Invoices_CTE AS Sales
  JOIN [Sales].[Customers] AS Customers
  ON Sales.[CustomerID] = Customers.CustomerID
  JOIN [Application].[Cities] AS Cities
  ON Customers.DeliveryCityID = Cities.CityID
  JOIN [Application].[People] AS People
  ON Sales.PackedByPersonID = People.PersonID