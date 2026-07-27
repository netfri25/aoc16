CREATE TABLE input (
    part INTEGER CHECK (part BETWEEN 1 AND 2),
    floor INTEGER NOT NULL,
    value INTEGER NOT NULL,

    PRIMARY KEY (part, floor)
);

-- hardcoded input :(
INSERT INTO
    input
VALUES
    (1, 1, 8),
    (1, 2, 2),
    (1, 3, 0),
    (1, 4, 0),
    (2, 1, 12),
    (2, 2, 2),
    (2, 3, 0),
    (2, 4, 0)
;

.header off
.mode column

SELECT
    SUM(2 * value - 3)
FROM (
    SELECT
        part,
        SUM(value) OVER (
            PARTITION BY part
            ORDER BY floor
            RANGE
                BETWEEN UNBOUNDED PRECEDING
                    AND 1 PRECEDING
        ) AS value
    FROM
        input
)
GROUP BY
    part
;
