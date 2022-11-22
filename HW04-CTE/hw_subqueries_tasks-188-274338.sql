/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "03 - Подзапросы, CTE, временные таблицы".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- Для всех заданий, где возможно, сделайте два варианта запросов:
--  1) через вложенный запрос
--  2) через WITH (для производных таблиц)
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Выберите сотрудников (Application.People), которые являются продажниками (IsSalesPerson), 
и не сделали ни одной продажи 04 июля 2015 года. 
Вывести ИД сотрудника и его полное имя. 
Продажи смотреть в таблице Sales.Invoices.
*/


USE [WideWorldImporters];
GO

SELECT [PersonID]
      ,[FullName]
  FROM [Application].[People] AS People
  WHERE 1=1
	AND [IsSalesperson] = 1
	AND [PersonID] NOT IN (SELECT [SalespersonPersonID]
							FROM [Sales].[Invoices]
							WHERE 1=1
								AND [InvoiceDate] = '2015-07-04');
GO


USE [WideWorldImporters];
GO

;WITH Sales_Invoices_CTE
	AS
	(
			SELECT DISTINCT [SalespersonPersonID]
				FROM [Sales].[Invoices]
				WHERE 1=1
					AND [InvoiceDate] = '2015-07-04'
	)
SELECT [PersonID]
      ,[FullName]
  FROM [Application].[People] AS People
  WHERE 1=1
	AND [IsSalesperson] = 1
	AND [PersonID] NOT IN (SELECT [SalespersonPersonID]
							FROM Sales_Invoices_CTE);
GO


USE [WideWorldImporters];
GO

;WITH Sales_Invoices_CTE
	AS
	(
			SELECT DISTINCT [SalespersonPersonID]
				FROM [Sales].[Invoices]
				WHERE 1=1
					AND [InvoiceDate] = '2015-07-04'
	)
SELECT [PersonID]
      ,[FullName]
  FROM [Application].[People] AS People
  LEFT JOIN Sales_Invoices_CTE
	ON People.PersonID = Sales_Invoices_CTE.SalespersonPersonID
  WHERE 1=1
	AND [IsSalesperson] = 1
	AND Sales_Invoices_CTE.SalespersonPersonID IS NULL;
GO

/*
2. Выберите товары с минимальной ценой (подзапросом). Сделайте два варианта подзапроса. 
Вывести: ИД товара, наименование товара, цена.
*/

USE [WideWorldImporters];
GO

SELECT [StockItemID]
      ,[StockItemName]
	  ,[UnitPrice]
  FROM [Warehouse].[StockItems]
  WHERE 1=1
	AND [UnitPrice] IN (SELECT MIN([UnitPrice]) FROM [Warehouse].[StockItems]);


USE [WideWorldImporters];
GO

SELECT [StockItemID]
      ,[StockItemName]
	  ,[UnitPrice]
  FROM [Warehouse].[StockItems] AS StockItems
  JOIN (SELECT MIN([UnitPrice]) AS MINUNIT
		FROM [Warehouse].[StockItems]) AS SUBQUERY
	ON StockItems.UnitPrice = SUBQUERY.MINUNIT;


USE [WideWorldImporters];
GO

;WITH MinUnitPrice_CTE
	AS
	(
			SELECT  MIN([UnitPrice]) AS MINUNIT
			FROM [Warehouse].[StockItems]
	)
SELECT [StockItemID]
      ,[StockItemName]
	  ,[UnitPrice]
FROM [Warehouse].[StockItems]
  WHERE 1=1
	AND [UnitPrice] IN (SELECT MINUNIT FROM MinUnitPrice_CTE);


/*
3. Выберите информацию по клиентам, которые перевели компании пять максимальных платежей 
из Sales.CustomerTransactions. 
Представьте несколько способов (в том числе с CTE). 
*/

USE [WideWorldImporters];
GO

SELECT TOP(5)
	   CustomerTransactions.[CustomerID]
	  ,Customers.CustomerName
      ,[TransactionAmount]
  FROM [Sales].[CustomerTransactions] AS CustomerTransactions
  JOIN [Sales].[Customers] AS Customers
	ON CustomerTransactions.CustomerID = Customers.CustomerID
  ORDER BY [TransactionAmount] DESC;


USE [WideWorldImporters];
GO

;WITH TransactionAmount_CTE (CustomerID, CustomerName, TransactionAmount)
	AS
	(
			SELECT CustomerTransactions.[CustomerID]
			,Customers.CustomerName
			,[TransactionAmount]
			FROM [Sales].[CustomerTransactions] AS CustomerTransactions
			JOIN [Sales].[Customers] AS Customers
				ON CustomerTransactions.CustomerID = Customers.CustomerID
	)
SELECT TOP(5)
	CustomerID,
	CustomerName,
	TransactionAmount
FROM TransactionAmount_CTE
ORDER BY [TransactionAmount] DESC

/*
4. Выберите города (ид и название), в которые были доставлены товары, 
входящие в тройку самых дорогих товаров, а также имя сотрудника, 
который осуществлял упаковку заказов (PackedByPersonID).
*/

TODO: напишите здесь свое решение

-- ---------------------------------------------------------------------------
-- Опциональное задание
-- ---------------------------------------------------------------------------
-- Можно двигаться как в сторону улучшения читабельности запроса, 
-- так и в сторону упрощения плана\ускорения. 
-- Сравнить производительность запросов можно через SET STATISTICS IO, TIME ON. 
-- Если знакомы с планами запросов, то используйте их (тогда к решению также приложите планы). 
-- Напишите ваши рассуждения по поводу оптимизации. 

-- 5. Объясните, что делает и оптимизируйте запрос

SELECT 
	Invoices.InvoiceID, 
	Invoices.InvoiceDate,
	(SELECT People.FullName
		FROM Application.People
		WHERE People.PersonID = Invoices.SalespersonPersonID
	) AS SalesPersonName,
	SalesTotals.TotalSumm AS TotalSummByInvoice, 
	(SELECT SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice)
		FROM Sales.OrderLines
		WHERE OrderLines.OrderId = (SELECT Orders.OrderId 
			FROM Sales.Orders
			WHERE Orders.PickingCompletedWhen IS NOT NULL	
				AND Orders.OrderId = Invoices.OrderId)	
	) AS TotalSummForPickedItems
FROM Sales.Invoices 
	JOIN
	(SELECT InvoiceId, SUM(Quantity*UnitPrice) AS TotalSumm
	FROM Sales.InvoiceLines
	GROUP BY InvoiceId
	HAVING SUM(Quantity*UnitPrice) > 27000) AS SalesTotals
		ON Invoices.InvoiceID = SalesTotals.InvoiceID
ORDER BY TotalSumm DESC

-- --

TODO: напишите здесь свое решение
