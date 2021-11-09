BEGIN TRANSACTION;

CREATE TEMPORARY TABLE _tmp(
    user_id,
    org_id,
    username,
    passwd,
    first_name,
    last_name,
    email,
    roles,
    last_login,
    active
);

INSERT INTO _tmp SELECT
    user_id,
    org_id,
    username,
    passwd,
    first_name,
    last_name,
    email,
    roles,
    last_login,
    active
FROM user;

DROP TABLE user;

CREATE TABLE IF NOT EXISTS user (
    user_id    INTEGER PRIMARY KEY AUTOINCREMENT,
    org_id     INTEGER,
    username   TEXT CHECK( LENGTH(username)   > 0  ) NOT NULL UNIQUE,
    passwd     TEXT CHECK( LENGTH(passwd)     > 0  ) NOT NULL,
    first_name TEXT CHECK( LENGTH(first_name) > 0  ) NOT NULL,
    last_name  TEXT CHECK( LENGTH(last_name)  > 0  ) NOT NULL,
    email      TEXT CHECK( email LIKE '%_@__%.__%' ) NOT NULL UNIQUE,
    roles      TEXT,
    last_login TEXT,
    active     INTEGER CHECK( active  = 1 OR active  = 0 ) NOT NULL DEFAULT 1,
    FOREIGN KEY (org_id) REFERENCES org(org_id) ON UPDATE CASCADE ON DELETE SET NULL
);

INSERT INTO user SELECT
    user_id,
    org_id,
    username,
    passwd,
    first_name,
    last_name,
    email,
    roles,
    last_login,
    active
FROM _tmp;

DROP TABLE _tmp;

COMMIT;
