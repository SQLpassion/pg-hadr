-- User for Replication
CREATE ROLE replicator WITH REPLICATION LOGIN PASSWORD 'passw0rd1!';

-- Create the Replication Slots for each replica
SELECT * FROM pg_create_physical_replication_slot('pg2');
SELECT * FROM pg_create_physical_replication_slot('pg3');
SELECT * FROM pg_create_physical_replication_slot('pg4');

-- Create a simple table with some data
CREATE TABLE testdata (id serial PRIMARY KEY, msg text);
INSERT INTO testdata (msg) VALUES ('Hello from primary!');