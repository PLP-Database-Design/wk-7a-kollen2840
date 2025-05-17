-- ============================================
-- Step 1: Achieve 1NF - Split multi-valued Products into atomic rows
-- ============================================

-- Clear the target table before inserting (optional)
DELETE FROM ProductDetail_1NF;

-- Use recursive CTE to split comma-separated Products into multiple rows
WITH RECURSIVE SplitProducts AS (
    SELECT
        OrderID,
        CustomerName,
        TRIM(SUBSTRING(Products FROM 1 FOR 
            CASE 
                WHEN POSITION(',' IN Products) = 0 THEN CHAR_LENGTH(Products)
                ELSE POSITION(',' IN Products) - 1
            END)) AS Product,
        CASE 
            WHEN POSITION(',' IN Products) = 0 THEN NULL
            ELSE TRIM(SUBSTRING(Products FROM POSITION(',' IN Products) + 1))
        END AS RemainingProducts
    FROM ProductDetail

    UNION ALL

    SELECT
        OrderID,
        CustomerName,
        TRIM(SUBSTRING(RemainingProducts FROM 1 FOR 
            CASE 
                WHEN POSITION(',' IN RemainingProducts) = 0 THEN CHAR_LENGTH(RemainingProducts)
                ELSE POSITION(',' IN RemainingProducts) - 1
            END)) AS Product,
        CASE 
            WHEN POSITION(',' IN RemainingProducts) = 0 THEN NULL
            ELSE TRIM(SUBSTRING(RemainingProducts FROM POSITION(',' IN RemainingProducts) + 1))
        END AS RemainingProducts
    FROM SplitProducts
    WHERE RemainingProducts IS NOT NULL
)

INSERT INTO ProductDetail_1NF (OrderID, CustomerName, Product)
SELECT OrderID, CustomerName, Product
FROM SplitProducts
ORDER BY OrderID;

-- ============================================
-- Step 2: Achieve 2NF - Remove partial dependency from OrderDetails
-- ============================================

-- Clear Orders and OrderItems before inserting (optional)
DELETE FROM Orders;
DELETE FROM OrderItems;

-- Insert distinct orders into Orders table
INSERT INTO Orders (OrderID, CustomerName)
SELECT DISTINCT OrderID, CustomerName
FROM OrderDetails;

-- Insert order items into OrderItems table
INSERT INTO OrderItems (OrderID, Product, Quantity)
SELECT OrderID, Product, Quantity
FROM OrderDetails;
