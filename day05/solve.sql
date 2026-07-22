.load ./sqlite-md5/libsqlitemd5.so

CREATE TABLE door_id (door_id TEXT);

INSERT INTO
    door_id
SELECT
    trim(readfile('./input'), char(10))
;

.header off
.mode column

-- part 1
WITH RECURSIVE hashes (i, hash) AS (
    SELECT
        0,
        ''
    FROM
        door_id
    UNION ALL
    SELECT
        i + 1,
        hex(md5(door_id || i))
    FROM
        hashes
    JOIN
        door_id
)
SELECT
    group_concat(substr(hash, 6, 1), '') AS result
FROM (
    SELECT
        hash
    FROM
        hashes
    WHERE
        hash LIKE '00000%'
    LIMIT
        8
);

-- part 2
WITH RECURSIVE password (i, old_hash, hash, position, character, password) AS (
    SELECT
        0,
        '',
        '',
        '',
        '',
        '--------'
    UNION ALL
    SELECT
        i + 1,
        hash AS old_hash,
        hex(md5(door_id || i)) AS hash,
        substr(hash, 6, 1) AS position,
        substr(hash, 7, 1) AS character,

        CASE
            WHEN old_hash LIKE '00000%'
                AND position BETWEEN '0' AND '7'
                AND substr(password, position + 1, 1) = '-'
            THEN substr(password, 1, position) || character || substr(password, position + 2)
            ELSE password
        END AS password
    FROM
        password
    CROSS JOIN
        door_id
    WHERE
        password LIKE '%-%'
)
SELECT
    password
FROM
    password
WHERE
    password NOT LIKE '%-%'
