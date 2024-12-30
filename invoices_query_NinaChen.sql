USE test1;

-- creating an example table to test the query
CREATE TABLE invoice_books (
    id SERIAL PRIMARY KEY,
    track VARCHAR(2),
    begin_number INT,
    end_number INT,
    year INT,
    month VARCHAR(2),
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);

CREATE TABLE invoices (
    id SERIAL PRIMARY KEY,
    invoice_number VARCHAR(12),
    invoice_date DATE,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);

DROP TABLE IF EXISTS invoice_books;
INSERT INTO invoice_books (id, track, begin_number, end_number, year, month, created_at, updated_at) VALUES
(1, 'AA', 12345600, 12345649, 113, '03', '2024-03-01 00:00:00', '2024-03-10 12:00:00'),
(2, 'AB', 98765400, 98765449, 113, '03', '2024-03-01 00:00:00', '2024-03-15 12:00:00'),
(3, 'AC', 45678900, 45678999, 113, '03', '2024-03-01 00:00:00', '2024-03-20 12:00:00');

INSERT INTO invoices (id, invoice_number, invoice_date, created_at, updated_at) VALUES
(1, 'AA-12345600', '2024-03-01', '2024-03-01 09:00:00', '2024-03-01 09:00:00'),
(2, 'AA-12345601', '2024-03-01', '2024-03-01 09:01:00', '2024-03-01 09:01:00'),
(3, 'AA-12345603', '2024-03-01', '2024-03-01 09:02:00', '2024-03-01 09:02:00'), 
(5, 'AB-98765402', '2024-03-02', '2024-03-02 10:01:00', '2024-03-02 10:01:00'), 
(6, 'AC-45678900', '2024-03-03', '2024-03-03 11:00:00', '2024-03-03 11:00:00'),
(7, 'AC-45678988', '2024-03-31', '2024-03-31 22:10:30', '2024-03-31 22:10:30'); 


select * from invoice_books;
select * from invoices;

WITH all_numbers AS (
    SELECT 
        b.id, b.track, b.year,
        b.month, n AS invoice_number
    FROM invoice_books b
    JOIN (
        SELECT @row := @row + 1 AS n
        FROM (SELECT 0 UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a,
             (SELECT 0 UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b,
             (SELECT 0 UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) c,
             (SELECT @row := -1) r
    ) t
    WHERE b.begin_number + t.n <= b.end_number
),
expanded_numbers AS (
    SELECT
        id, track, year,
        month, begin_number, end_number,
        CONCAT(track, '-', LPAD(invoice_number, 8, '0')) AS full_invoice_number
    FROM (
        SELECT 
            b.id, b.track,
            b.year, b.month, b.begin_number,
            b.end_number, b.begin_number + t.n AS invoice_number
        FROM invoice_books b
        CROSS JOIN (
            SELECT @row := @row + 1 AS n
            FROM (SELECT 0 UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a,
                 (SELECT 0 UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b,
                 (SELECT 0 UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) c,
                 (SELECT @row := -1) r
        ) t
        WHERE b.begin_number + t.n <= b.end_number
    ) num
),
missing_invoices AS (
    SELECT 
        e.id,
        e.full_invoice_number AS invoice_number,
        e.track, e.year,
        e.month, e.begin_number, e.end_number
    FROM expanded_numbers e
    LEFT JOIN invoices i
    ON e.full_invoice_number = i.invoice_number
    WHERE i.invoice_number IS NULL
)
SELECT 
    id, invoice_number, track,
    year, month, begin_number, end_number
FROM missing_invoices
ORDER BY track, begin_number, invoice_number;





-- Postgre SQL
WITH all_numbers AS (
    SELECT 
        b.id,
        b.track,
        b.year,
        b.month,
        n AS invoice_number
    FROM invoice_books b
    CROSS JOIN LATERAL generate_series(b.begin_number, b.end_number) AS n
),
existing_invoices AS (
    SELECT 
        CAST(SUBSTRING(invoice_number, 4) AS INT) AS invoice_number,
        SUBSTRING(invoice_number, 1, 2) AS track
    FROM invoices
),
missing_invoices AS (
    SELECT 
        a.id,
        a.track,
        a.year,
        a.month,
        a.invoice_number AS missing_number,
        b.begin_number,
        b.end_number
    FROM all_numbers a
    JOIN invoice_books b ON a.id = b.id
    LEFT JOIN existing_invoices e
    ON a.invoice_number = e.invoice_number AND a.track = e.track
    WHERE e.invoice_number IS NULL
)
SELECT 
    id,
    track,
    CONCAT(track, '-', LPAD(missing_number::TEXT, 8, '0')) AS invoice_number,
    year,
    month,
    begin_number,
    end_number
FROM missing_invoices
ORDER BY track, missing_number;


