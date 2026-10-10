# Football League Database

A PostgreSQL database for a six-a-side football league, covering teams, players, groups, venues, fixtures, results, goals and cards. There are two documents attached to this project. The first is a complete overview of the data modelling part of the project, while the second includes implementation steps, the entity relationship diagram and a data dictionary. The data itself that we used throughout this project is contained within the CSV file attached (which itself was obtained from raw, uncleaned data). 

## Files

- `01_schema_ddl.sql` — creates the domains, tables, keys, constraints and triggers.
- `02_data_dml.sql` — populates every table with the season's data.
- `03_test_queries.sql` — the seven test queries used to verify the database.
- `Technical_Documentation.docx` — implementation notes, design updates, data dictionary, ER diagram and test results.

## Prerequisites

- PostgreSQL running on a local server.
- pgAdmin (or another PostgreSQL client).

## Rebuilding the database

Run the scripts in the order below; each relies on the previous one having run.

1. Create a database named `football_league` and open a Query Tool on it.
2. Run `01_schema_ddl.sql` to build the structure.
3. Run `02_data_dml.sql` to load the data.
4. Run `03_test_queries.sql` to confirm the results (optional).
