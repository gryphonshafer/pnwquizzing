CREATE TABLE IF NOT EXISTS org (
    org_id  INTEGER PRIMARY KEY AUTOINCREMENT,
    name    TEXT NOT NULL UNIQUE,
    acronym TEXT NOT NULL UNIQUE,
    address TEXT,
    active  INTEGER CHECK( active = 1 OR active = 0 ) NOT NULL DEFAULT 1
);

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
    active     INTEGER CHECK( active = 1 OR active = 0 ) NOT NULL DEFAULT 1,
    FOREIGN KEY (org_id) REFERENCES org(org_id) ON UPDATE CASCADE ON DELETE SET NULL
);

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

CREATE TABLE IF NOT EXISTS entry (
    entry_id     INTEGER PRIMARY KEY AUTOINCREMENT,
    meet_id      INTEGER NOT NULL,
    user_id      INTEGER NOT NULL,
    org_id       INTEGER,
    registration TEXT,
    created      TEXT NOT NULL DEFAULT ( STRFTIME( '%Y-%m-%dT%H:%M:%fZ', 'NOW' ) ),
    FOREIGN KEY (meet_id) REFERENCES meet(meet_id) ON UPDATE CASCADE ON DELETE SET NULL,
    FOREIGN KEY (user_id) REFERENCES user(user_id) ON UPDATE CASCADE ON DELETE SET NULL,
    FOREIGN KEY (org_id)  REFERENCES org(org_id)   ON UPDATE CASCADE ON DELETE SET NULL
);
