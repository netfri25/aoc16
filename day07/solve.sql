CREATE TABLE input (line TEXT);

INSERT INTO
    input
SELECT
    value
FROM
    json_each('["' || replace(trim(readfile('./input'), char(10)), char(10), '","') || '"]')
;

CREATE TABLE parts (
    part_value TEXT NOT NULL,
    part_index INTEGER NOT NULL,
    addr_id INTEGER NOT NULL,

    inside INTEGER AS (part_index & 1) VIRTUAL,

    FOREIGN KEY (addr_id)
        REFERENCES input (rowid)
        ON UPDATE RESTRICT
        ON DELETE RESTRICT
);


INSERT INTO
    parts
SELECT
    value AS part_value,
    key AS part_index,
    input.rowid AS addr_id
FROM
    input
JOIN
    json_each('["' || replace(replace(input.line, '[', '","'), ']', '","') || '"]')
;

CREATE VIEW allowed AS
WITH letters AS (
    SELECT
        char(value) AS letter
    FROM
        generate_series(unicode('a'), unicode('z'))
)
SELECT
    a.letter || b.letter || b.letter || a.letter AS abba
FROM
    letters AS a,
    letters AS b
WHERE
    a.letter != b.letter
;


.header off
.mode column

-- part 1
SELECT
    COUNT(*) AS result
FROM (
    SELECT
        1
    FROM
        parts
    CROSS JOIN -- abba
        generate_series(1, length(part_value) - 3) AS i
            ON substr(part_value, i.value + 0, 1) != substr(part_value, i.value + 1, 1)
            AND substr(part_value, i.value + 0, 1) = substr(part_value, i.value + 3, 1)
            AND substr(part_value, i.value + 1, 1) = substr(part_value, i.value + 2, 1)
    GROUP BY
        addr_id
    HAVING
        SUM(inside) = 0
);

-- part 2
SELECT
    COUNT(DISTINCT outside.addr_id) AS result
FROM
    parts AS outside
CROSS JOIN
    parts AS inside
        ON outside.inside = 0
        AND inside.inside = 1
        AND inside.addr_id = outside.addr_id
CROSS JOIN  -- aba
    generate_series(1, length(inside.part_value) - 2) AS inside_index
        ON substr(inside.part_value, inside_index.value, 1) != substr(inside.part_value, inside_index.value + 1, 1)
        AND substr(inside.part_value, inside_index.value, 1) = substr(inside.part_value, inside_index.value + 2, 1)
CROSS JOIN  -- bab
    generate_series(1, length(outside.part_value) - 2) AS outside_index
        ON substr(inside.part_value, inside_index.value, 1) = substr(outside.part_value, outside_index.value + 1, 1)
        AND substr(inside.part_value, inside_index.value + 1, 1) = substr(outside.part_value, outside_index.value + 0, 1)
        AND substr(inside.part_value, inside_index.value + 1, 1) = substr(outside.part_value, outside_index.value + 2, 1)
;
