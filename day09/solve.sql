CREATE TABLE input (line TEXT);

INSERT INTO
    input
SELECT
    trim(readfile('./input'), char(10))
;

.header off
.mode column

-- part 1
WITH RECURSIVE lengths (leftover, length, count) AS (
    SELECT
        line,
        0,
        0
    FROM
        input

    UNION ALL

    SELECT
        CASE instr(leftover, '(')
            WHEN 1 THEN
                substr(
                    leftover,
                    instr(leftover, ')')
                        + CAST(
                            substr(
                                leftover,
                                2,
                                instr(leftover, 'x') - 2
                            ) AS INTEGER
                        )
                        + 1
                )
            WHEN 0 THEN '' -- not found
            ELSE substr(leftover, instr(leftover, '('))
        END,

        CASE instr(leftover, '(')
            WHEN 1 THEN
                CAST(substr(leftover, 2, instr(leftover, 'x') - 2) AS INTEGER)
            WHEN 0 THEN length(leftover)
            ELSE instr(leftover, '(') - 1
        END,

        CASE instr(leftover, '(')
            WHEN 1 THEN
                CAST(
                    substr(
                        leftover,
                        instr(leftover, 'x') + 1,
                        instr(leftover, ')') - instr(leftover, 'x') - 1
                    ) AS INTEGER
                )
            ELSE 1
        END
    FROM
        lengths
    WHERE
        leftover != ''
)
SELECT
    SUM(length * count) AS result
FROM
    lengths
;

-- part 2
CREATE TABLE ranges (
    start INTEGER,
    payload_start INTEGER,
    length INTEGER,
    count INTEGER
);

INSERT INTO
    ranges
SELECT
    pos.value AS start,

    pos.value + instr(substr(line, pos.value), ')') AS payload_start,

    substr(
        line,
        pos.value + 1,
        instr(substr(line, pos.value), 'x') - 2
    ) AS length,

    substr(
        line,
        pos.value + instr(substr(line, pos.value), 'x'),
        instr(substr(line, pos.value), ')')
            - instr(substr(line, pos.value), 'x')
            - 1
    ) AS count
FROM
    input
JOIN
    generate_series(1, length(line)) AS pos
WHERE
    substr(line, pos.value, 1) = '('
ORDER BY
    pos.value ASC
;

CREATE TEMP TABLE tree
AS
SELECT
    ranges.rowid AS rowid,
    ranges.*,

    (
        SELECT
            parent.rowid
        FROM
            ranges AS parent
        WHERE
            parent.payload_start <= ranges.start
            AND ranges.start < parent.payload_start + parent.length
        ORDER BY
            parent.start DESC
        LIMIT 1
    ) AS parent_id
FROM
    ranges
;

WITH RECURSIVE
    products (rowid, product) AS (
        SELECT
            rowid,
            count
        FROM
            tree
        WHERE
            parent_id IS NULL

        UNION ALL

        SELECT
            child.rowid,
            product * count
        FROM
            products AS parent
        JOIN
            tree AS child
                ON child.parent_id = parent.rowid
    )
SELECT
    SUM(product * length)
FROM
    products
JOIN
    tree USING (rowid)
WHERE
    NOT EXISTS (
        SELECT
            1
        FROM
            tree
        WHERE
            parent_id = products.rowid
    )
;
