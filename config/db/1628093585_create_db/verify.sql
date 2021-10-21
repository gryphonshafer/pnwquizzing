SELECT CASE WHEN
    ( SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = 'org'     ) +
    ( SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = 'user'    ) +
    ( SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = 'meet'    ) +
    ( SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = 'entry'   )
    = 4
THEN 1 ELSE 0 END;
