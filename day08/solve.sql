CREATE VIEW dim (w, h) AS VALUES (50, 6);

CREATE TABLE input (line TEXT);

INSERT INTO
    input
SELECT
    value
FROM
    json_each('["' || replace(trim(readfile('./input'), char(10)), char(10), '","') || '"]')
;

UPDATE
    input
SET
    line = replace(replace(replace(replace(replace(line, 'rotate row ', ''), 'rotate column ', ''), ' by ', ','), '=', ' '), 'rect', 'r')
;

UPDATE
    input
SET
    line = replace(line, 'x', ',')
WHERE
    line LIKE 'r%'
;

UPDATE
    input
SET
    line = '["' || replace(line, ' ', '",') || ']'
;

CREATE TABLE instruction (
    instruction_id INTEGER PRIMARY KEY,
    opcode TEXT NOT NULL,
    a INTEGER NOT NULL,
    b INTEGER NOT NULL,

    CHECK (opcode IN ('x', 'y', 'r'))
);


INSERT INTO
    instruction
SELECT
    rowid AS instruction_id,
    line ->> 0 AS opcode,
    line ->> 1 AS a,
    line ->> 2 AS b
FROM
    input
;


CREATE TABLE pixel (
    instruction_id INTEGER NOT NULL,
    x INTEGER NOT NULL,
    y INTEGER NOT NULL,
    orig_x INTEGER NOT NULL,
    orig_y INTEGER NOT NULL,

    UNIQUE (instruction_id, x, y),
    UNIQUE (instruction_id, orig_x, orig_y),

    FOREIGN KEY (instruction_id)
        REFERENCES instruction (instruction_id)
        ON UPDATE RESTRICT
        ON DELETE RESTRICT
);

WITH screen (instruction_id, x, y, orig_x, orig_y) AS (
    SELECT
        1,
        x.value,
        y.value,
        x.value,
        y.value
    FROM
        dim
    CROSS JOIN
        generate_series(0, dim.w - 1) AS x
    CROSS JOIN
        generate_series(0, dim.h - 1) AS y

    UNION ALL

    SELECT
        screen.instruction_id + 1,

        CASE
            WHEN instruction.opcode = 'y' AND screen.y = instruction.a
            THEN (screen.x + instruction.b) % dim.w
            ELSE screen.x
        END,

        CASE
            WHEN instruction.opcode = 'x' AND screen.x = instruction.a
            THEN (screen.y + instruction.b) % dim.h
            ELSE screen.y
        END,

        orig_x,
        orig_y
    FROM
        screen
    JOIN
        dim
    JOIN
        instruction USING (instruction_id)
)
INSERT INTO
    pixel
SELECT
    instruction_id - 1,
    x,
    y,
    orig_x,
    orig_y
FROM
    screen
;

CREATE VIEW orig_lit AS
SELECT DISTINCT
    orig_x,
    orig_y
FROM
    pixel
JOIN
    instruction USING (instruction_id)
WHERE
    instruction.opcode = 'r' AND x < a AND y < b
;

.header off
.mode column

-- part 1
SELECT
    COUNT(*) AS result
FROM
    orig_lit
;

-- part 2
CREATE VIEW lit AS
SELECT
    x,
    y
FROM
    pixel
INNER JOIN
    orig_lit
        ON pixel.orig_x = orig_lit.orig_x
        AND pixel.orig_y = orig_lit.orig_y
WHERE
    pixel.instruction_id = (SELECT MAX(instruction_id) FROM pixel)
;

CREATE VIEW display AS
SELECT
    x.value AS x,
    y.value AS y,
    CASE WHEN lit.x IS NOT NULL THEN '#' ELSE ' ' END AS lit
FROM
    dim
CROSS JOIN
    generate_series(0, dim.w - 1) AS x
CROSS JOIN
    generate_series(0, dim.h - 1) AS y
LEFT JOIN
    lit
        ON x.value = lit.x
        AND y.value = lit.y
ORDER BY
    y ASC,
    x ASC
;

SELECT
    group_concat(lit, '')
FROM (
    SELECT *
    FROM display
    ORDER BY y, x
)
GROUP BY y
ORDER BY y;

