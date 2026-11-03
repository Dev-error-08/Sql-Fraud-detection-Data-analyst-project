use bank;
select * from  transactions;

-- 1. Detecting Recursive Fraudulent Transactions

WITH RECURSIVE fraud_chain AS (
    SELECT nameOrig AS initial_account,
	nameDest AS next_account,
	step,
	amount,
    newbalanceOrig
	FROM transactions
	WHERE isFraud = 1 AND type = 'TRANSFER'
           
    UNION ALL
    
    SELECT fc.initial_account,
	t.nameDest,t.step,t.amount,t.newbalanceOrig
    FROM fraud_chain fc
    JOIN transactions t
    ON fc.next_account = t.nameOrig AND fc.step < t.step
    WHERE t.isFraud = 1 AND t.type = 'TRANSFER')
    
SELECT * FROM fraud_chain;




with rolling_fraud as (select nameOrig,step, sum(isfraud) over (partition by nameOrig order by STEP ROWS BETWEEN 4 preceding AND current row) as fraud_rolling
from transactions)

select * from rolling_fraud 
where fraud_rolling > 0 ;

-- question:
-- Use Multiple CTEs to indentify accounts with suspicious activity, including large transfers, conseutive transactions without balance change, and flagged transactions.

WITH large_transfers AS (
    SELECT nameOrig, step, amount 
    FROM transactions 
    WHERE type = 'TRANSFER' AND amount > 500000
),
no_balance_change AS (
    SELECT step, oldbalanceOrg, newbalanceOrig, nameOrig 
    FROM transactions 
    WHERE oldbalanceOrg = newbalanceOrig
),
flagged_transactions AS (
    SELECT nameOrig, step 
    FROM transactions 
    WHERE isFlaggedFraud = 1
)
SELECT lt.nameOrig 
FROM large_transfers lt
JOIN no_balance_change nbc 
  ON lt.nameOrig = nbc.nameOrig AND lt.step = nbc.step
JOIN flagged_transactions ft 
  ON lt.nameOrig = ft.nameOrig AND lt.step = ft.step;
  
  -- Question:
  -- Write me a query that checks if the computed new_updated_balance is the same as the actual newbalanceDest in the table. If they are equal, it returns the rows.
  
  WITH CTE AS (
    SELECT amount, nameorig, oldbalancedest, newbalancedest, (amount + oldbalancedest) AS new_updated_balance 
    FROM transactions
)
SELECT * FROM CTE WHERE new_updated_balance = newbalancedest;

-- Question:
-- Find transactions where the destination account had a zero balance before or after the transaction.

SELECT * 
FROM transactions 
WHERE oldbalanceDest = 0 OR newbalanceDest = 0;