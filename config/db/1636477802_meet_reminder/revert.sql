BEGIN TRANSACTION;

CREATE TEMPORARY TABLE _tmp(
    meet_id,
    org_id,
    name,
    org_override,
    address_override,
    start,
    days,
    deadline,
    house,
    lunch
);

INSERT INTO _tmp SELECT
    meet_id,
    org_id,
    name,
    org_override,
    address_override,
    start,
    days,
    deadline,
    house,
    lunch
FROM meet;

DROP TABLE meet;

CREATE TABLE IF NOT EXISTS meet (
    meet_id          INTEGER PRIMARY KEY AUTOINCREMENT,
    org_id           INTEGER,
    name             TEXT NOT NULL,
    org_override     TEXT,
    address_override TEXT,
    start            TEXT NOT NULL,
    days             INTEGER NOT NULL DEFAULT 2,
    deadline         INTEGER NOT NULL DEFAULT 14,
    house            INTEGER CHECK( house = 1 OR house = 0 ) NOT NULL DEFAULT 0,
    lunch            INTEGER CHECK( lunch = 1 OR lunch = 0 ) NOT NULL DEFAULT 0,
    FOREIGN KEY (org_id) REFERENCES org(org_id) ON UPDATE CASCADE ON DELETE SET NULL
);

INSERT INTO meet SELECT
    meet_id,
    org_id,
    name,
    org_override,
    address_override,
    start,
    days,
    deadline,
    house,
    lunch
FROM _tmp;

DROP TABLE _tmp;

COMMIT;
