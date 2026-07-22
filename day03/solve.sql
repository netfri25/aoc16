CREATE TABLE input (line TEXT);

INSERT INTO
    input
SELECT
    value
FROM
    json_each('["' || replace(rtrim(readfile('./input'), char(10)), char(10), '", "') || '"]');



CREATE TABLE sides (
    value INTEGER,
    row INTEGER,
    col INTEGER
);

INSERT INTO
    sides
SELECT
    CAST(substr(line, 1,  5) AS INTEGER) AS side,
    rowid AS row,
    1 AS col
FROM
    input
UNION ALL
SELECT
    CAST(substr(line, 6,  5) AS INTEGER) AS side,
    rowid AS row,
    2 AS col
FROM
    input
UNION ALL
SELECT
    CAST(substr(line, 11, 5) AS INTEGER) AS side,
    rowid AS row,
    3 AS col
FROM
    input;



.header off
.mode column

-- part 1
SELECT
    COUNT(1) AS result
FROM (
    SELECT
        1
    FROM
        sides
    GROUP BY
        row
    HAVING
        SUM(value) - MAX(value) > MAX(value)
);

-- part 2
SELECT
    COUNT(1) AS result
FROM (
    SELECT
        1
    FROM
        sides
    GROUP BY
        col, (row - 1) / 3  -- `row - 1` because of 1-based indexing
    HAVING
        SUM(value) - MAX(value) > MAX(value)
);

