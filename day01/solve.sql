CREATE TABLE input (
    value INTEGER,
    rotation INTEGER
);


INSERT INTO
    input
SELECT
    CAST(SUBSTR(value, 2) AS INTEGER) AS value,

    CASE SUBSTR(value, 1, 1)
        WHEN 'R' THEN 1
        WHEN 'L' THEN 3
    END AS rotation
FROM
    json_each('["' || replace(replace(trim(readfile('./input')), char(10), ''), ', ', '", "') || '"]');


CREATE VIEW deltas
AS
SELECT
    rowid,

    CASE direction
        WHEN 0 THEN -value
        WHEN 2 THEN value
        ELSE 0
    END AS dx,

    CASE direction
        WHEN 1 THEN -value
        WHEN 3 THEN value
        ELSE 0
    END AS dy
FROM (
    SELECT
        rowid,
        value,
        SUM(rotation) OVER (ORDER BY rowid) % 4 AS direction
    FROM
        input
);


CREATE VIEW positions
AS
SELECT
    rowid,
    SUM(dx) OVER (ORDER BY rowid) AS x,
    SUM(dy) OVER (ORDER BY rowid) AS y
FROM
    deltas;


CREATE TABLE all_positions (
    x INTEGER,
    y INTEGER
);

INSERT INTO
    all_positions
SELECT
    p.x - d.dx + i.value * sign(d.dx) AS x,
    p.y - d.dy + i.value * sign(d.dy) AS y
FROM
    positions AS p
INNER JOIN
    deltas AS d USING (rowid)
CROSS JOIN
    generate_series(
        1,
        abs(d.dx) + abs(d.dy)
    ) AS i;


.mode column
.header off

-- part 1
SELECT
    abs(x) + abs(y) AS result
FROM
    all_positions
ORDER BY rowid DESC
LIMIT 1;

-- part 2
SELECT
    abs(x) + abs(y) AS result
FROM (
    SELECT
        rowid,
        x,
        y,
        row_number() OVER (
            PARTITION BY x, y
            ORDER BY rowid DESC
        ) AS visit
    FROM
        all_positions
)
WHERE visit = 2
ORDER BY rowid ASC
LIMIT 1
