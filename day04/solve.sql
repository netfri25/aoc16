CREATE TABLE input (line TEXT);

INSERT INTO
    input
SELECT
    trim(value)
FROM
    json_each('["' || replace(trim(readfile('./input'), char(10)), char(10), '","') || '"]')
;


CREATE TABLE room (
    room_id INTEGER PRIMARY KEY,
    name TEXT,
    sector_id INTEGER,
    checksum TEXT
);

INSERT INTO
    room
SELECT
    rowid AS room_id,
    replace(substr(line, 1, length(line) - 11), '-', '') AS name,
    CAST(substr(line, -10, 3) AS INTEGER) AS sector_id,
    substr(line, -6, 5) AS checksum
FROM
    input
;


CREATE TABLE letter (
    letter TEXT,
    room_id INTEGER NOT NULL,

    FOREIGN KEY (room_id)
        REFERENCES room (room_id)
        ON UPDATE RESTRICT
        ON DELETE RESTRICT
);

WITH RECURSIVE name_letters (leftover, letter, room_id) AS (
    SELECT
        substr(name, 2),
        substr(name, 1, 1),
        room_id
    FROM
        room
    UNION ALL
    SELECT
        substr(leftover, 2),
        substr(leftover, 1, 1),
        room_id
    FROM
        name_letters
    WHERE
        leftover != ''
)
INSERT INTO
    letter
SELECT
    letter,
    room_id
FROM
    name_letters
;

.header off
.mode column

-- part 1
WITH
    counts AS (
        SELECT
            room_id,
            letter,
            COUNT(1) AS count
        FROM
            letter
        GROUP BY
            room_id,
            letter
        ORDER BY
            room_id ASC,
            count DESC,
            letter ASC
    ),
    ranks AS (
        SELECT
            room_id,
            letter,
            row_number() OVER (
                PARTITION BY room_id
                ORDER BY count DESC, letter ASC
            ) AS rank
        FROM
            counts
    ),
    expected AS (
        SELECT
            room_id,
            group_concat(letter, '') AS checksum
        FROM
            ranks
        WHERE
            rank <= 5
        GROUP BY
            room_id
    )
SELECT
    SUM(sector_id) AS result
FROM
    room
JOIN
    expected USING (room_id)
WHERE
    expected.checksum = room.checksum
;

-- part 2
SELECT
    sector_id
FROM (
    SELECT
        sector_id,
        group_concat(
            char(
                (unicode(letter) - unicode('a') + sector_id)
                    % (unicode('z') - unicode('a') + 1)
                    + unicode('a')
            ),
            ''
        ) AS name
    FROM
        letter
    JOIN
        room USING (room_id)
    GROUP BY
        room_id
)
WHERE
    name LIKE '%north%'
;
