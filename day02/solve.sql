CREATE TABLE input (
    instruction TEXT
);

INSERT INTO
    input
SELECT
    value
FROM
    json_each('["' || replace(trim(readfile('./input'), char(10)), char(10), '", "') || '"]');


.header off
.mode column

-- part 1
WITH
    moves(rowid, instruction, x, y) AS (
        SELECT
            rowid,
            instruction,
            1,
            1
        FROM
            input

        UNION ALL

        SELECT
            rowid,
            substr(instruction, 2),

            CASE substr(instruction, 1, 1)
                WHEN 'L' THEN MAX(0, x - 1)
                WHEN 'R' THEN MIN(2, x + 1)
                ELSE x
            END,

            CASE substr(instruction, 1, 1)
                WHEN 'U' THEN MAX(0, y - 1)
                WHEN 'D' THEN MIN(2, y + 1)
                ELSE y
            END
        FROM
            moves
        WHERE
            instruction != ''
    )
SELECT
    GROUP_CONCAT(digit, '') AS result
FROM (
    SELECT
        3*y + x + 1 AS digit
    FROM
        moves
    WHERE
        instruction = ''
    ORDER BY
        rowid
);

-- part 2
CREATE TABLE keypad (
    digit TEXT,
    x INTEGER,
    y INTEGER
);

INSERT INTO
    keypad
VALUES
    ('1',  0, -2),
    ('2', -1, -1),
    ('3',  0, -1),
    ('4',  1, -1),
    ('5', -2,  0),
    ('6', -1,  0),
    ('7',  0,  0),
    ('8',  1,  0),
    ('9',  2,  0),
    ('A', -1,  1),
    ('B',  0,  1),
    ('C',  1,  1),
    ('D',  0,  2);


WITH
    moves(rowid, instruction, x, y) AS (
        SELECT
            rowid,
            instruction,
            1,
            1
        FROM
            input

        UNION ALL

        SELECT
            moves.rowid,
            substr(moves.instruction, 2),
            ifnull(keypad.x, moves.x),
            ifnull(keypad.y, moves.y)
        FROM
            moves
        LEFT JOIN
            keypad ON
                keypad.x = CASE substr(instruction, 1, 1)
                    WHEN 'L' THEN moves.x - 1
                    WHEN 'R' THEN moves.x + 1
                    ELSE moves.x
                END
            AND
                keypad.y = CASE substr(instruction, 1, 1)
                    WHEN 'U' THEN moves.y - 1
                    WHEN 'D' THEN moves.y + 1
                    ELSE moves.y
                END
        WHERE
            instruction != ''
    )
SELECT
    GROUP_CONCAT(digit, '') AS result
FROM (
    SELECT
        keypad.digit
    FROM
        moves
    JOIN
        keypad ON (keypad.x, keypad.y) = (moves.x, moves.y)
    WHERE
        moves.instruction = ''
    ORDER BY
        moves.rowid
);
