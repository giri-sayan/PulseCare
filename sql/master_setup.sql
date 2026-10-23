-- master_setup.sql
-- Executes all PulseCare schema, data, and PL/SQL scripts in sequence and exits
SET DEFINE OFF;
SET ECHO OFF;
SET FEEDBACK ON;

PROMPT =======================================================
PROMPT [1/7] Deploying Schema Tables and Constraints...
PROMPT =======================================================
@@01_schema_ddl.sql

PROMPT =======================================================
PROMPT [2/7] Inserting Seed Data...
PROMPT =======================================================
@@02_seed_data.sql

PROMPT =======================================================
PROMPT [3/7] Compiling Functions...
PROMPT =======================================================
@@03_functions.sql

PROMPT =======================================================
PROMPT [4/7] Compiling Stored Procedures...
PROMPT =======================================================
@@04_procedures.sql

PROMPT =======================================================
PROMPT [5/7] Compiling Packages...
PROMPT =======================================================
@@05_packages.sql

PROMPT =======================================================
PROMPT [6/7] Compiling Triggers...
PROMPT =======================================================
@@06_triggers.sql

PROMPT =======================================================
PROMPT [7/7] Compiling Cursors...
PROMPT =======================================================
@@07_cursors.sql

COMMIT;

PROMPT =======================================================
PROMPT PulseCare Database Setup Completed Successfully!
PROMPT =======================================================
EXIT;
