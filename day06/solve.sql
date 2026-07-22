CREATE TABLE input (line TEXT);

INSERT INTO
    input
SELECT
    value
FROM
    json_each('["' || replace(trim(readfile('./input'), char(10)), char(10), '","') || '"]')
;

CREATE TABLE grid (
    char TEXT,
    row INTEGER,
    col INTEGER,
    PRIMARY KEY (row, col)
);

WITH parse_lines (leftover, char, row, col) AS (
    SELECT
        line,
        '',
        row_number() OVER (ORDER BY rowid),
        0
    FROM
        input
    UNION ALL
    SELECT
        substr(leftover, 2),
        substr(leftover, 1, 1),
        row,
        col + 1
    FROM
        parse_lines
    WHERE
        leftover != ''
)
INSERT INTO
    grid
SELECT
    char,
    row,
    col
FROM
    parse_lines
WHERE
    col > 0
;


.header off
.mode column


-- part 1
WITH
    counts AS (
        SELECT
            char,
            col,
            COUNT(*) AS count
        FROM
            grid
        GROUP BY
            col,
            char
    ),
    highest AS (
        SELECT
            col,
            MAX(count) AS count
        FROM
            counts
        GROUP BY
            col
    )
SELECT
    group_concat(char, '') AS result
FROM
    highest
JOIN
    counts USING (col, count)
ORDER BY
    col
;

-- part 2 (MIN instead of MAX)
WITH
    counts AS (
        SELECT
            char,
            col,
            COUNT(*) AS count
        FROM
            grid
        GROUP BY
            col,
            char
    ),
    lowest AS (
        SELECT
            col,
            MIN(count) AS count
        FROM
            counts
        GROUP BY
            col
    )
SELECT
    group_concat(char, '') AS result
FROM
    lowest
JOIN
    counts USING (col, count)
ORDER BY
    col
;
