# Start the Docker Compose deployment
Start the Docker containers, and check their status:

```bash
# Create the Docker Compose deployment
docker compose up -d
docker compose ps
docker logs pg1
docker logs pg2
docker logs pg3
docker logs pg4

# Start an existing Docker Compose deployment
docker compose start

# Check the Replication Slots
docker exec -it pg1 psql -U postgres -d appdb -c "SELECT slot_name, active, synced FROM pg_replication_slots;"
```

# Installation of the nano text editor
This installs nano, so that we can edit the configuration files of PostgreSQL later:
```bash
# Installs nano
for c in pg1 pg2 pg3 pg4; do
    docker exec -u root -it $c apt-get update
    docker exec -u root -it $c apt-get install nano
done
```

# PostgreSQL Usage
Insert some rows at the current primary replica (`pg1`), and check if the inserted data is synchronized across all replicas (`pg1`, `pg2`, `pg3`, `pg4`):

```bash
# Some PostgreSQL workload...
docker exec -it pg1 psql -U postgres -d appdb -c "INSERT INTO testdata (msg) VALUES ('Streaming Replication works!');"

# Check if the inserted data was synchronized
for c in pg1 pg2 pg3 pg4; do
    echo "Replica: $c"
    docker exec -it $c psql -U postgres -d appdb -c "SELECT COUNT(*) AS row_count FROM testdata;" 2>/dev/null
done

# Replica Monitoring
docker exec -it pg1 psql -U postgres -d appdb -c "SELECT * FROM pg_stat_replication;"
```

# Set the property "application_name"
```bash
# Add the property "application_name" to the config file "/var/lib/postgresql/data/postgresql.auto.conf"

# docker exec -it pg2 bin/bash
#   => cd $PGDATA
#   => nano postgresql.auto.conf
#   => Add "application_name=pg2"
#   => exit

# docker exec -it pg3 bin/bash
#   => cd $PGDATA
#   => nano postgresql.auto.conf
#   => Add "application_name=pg3"
#   => exit

# docker exec -it pg4 bin/bash
#   => cd $PGDATA
#   => nano postgresql.auto.conf
#   => Add "application_name=pg4"
#   => exit

# Reload the configuration for each secondary replica
for c in pg2 pg3 pg4; do
    echo "Replica: $c"
    docker exec -u postgres -it $c  pg_ctl reload -D /var/lib/postgresql/data 2>/dev/null
done

# Check, if the application_name is there
docker exec -it pg1 psql -U postgres -d appdb -c "SELECT application_name, sync_state FROM pg_stat_replication;"
```

# Enable Synchronous Commit - single Replica
```bash
# Enable Synchronous Commit on the Primary Replica with one additional synchronous Secondary Replica
docker exec -it pg1 sed -i "s/^#\?synchronous_commit.*/synchronous_commit = on/" /var/lib/postgresql/data/postgresql.conf
docker exec -it pg1 sed -i "s/^#\?synchronous_standby_names.*/synchronous_standby_names = '\"pg2\"'/" /var/lib/postgresql/data/postgresql.conf
docker exec -it pg1 grep "synchronous_commit" /var/lib/postgresql/data/postgresql.conf
docker exec -it pg1 grep "synchronous_standby_names" /var/lib/postgresql/data/postgresql.conf
docker exec -u postgres -it pg1 pg_ctl reload -D /var/lib/postgresql/data

# Check, if the replica is running in sync mode
docker exec -it pg1 psql -U postgres -d appdb -c "SELECT application_name, sync_state FROM pg_stat_replication;"
```

# Enable Synchronous Commit - multiple Replicas
```bash
# Multiple synchronous Secondary Replicas
docker exec -it pg1 sed -i "s/^#\?synchronous_standby_names.*/synchronous_standby_names = 'ANY 1 (\"pg2\",\"pg3\")'/" /var/lib/postgresql/data/postgresql.conf
docker exec -it pg1 grep "synchronous_standby_names" /var/lib/postgresql/data/postgresql.conf
docker exec -u postgres -it pg1 pg_ctl reload -D /var/lib/postgresql/data

# Check, if both replicas are running in quorum mode
docker exec -it pg1 psql -U postgres -d appdb -c "SELECT application_name, sync_state FROM pg_stat_replication;"
```

# Stop the Docker Compose deployment
Stop/Remove the Docker containers:

```bash
# Stop the Docker Compose deployment
docker compose stop

# Remove the Docker Compose deployment (including the Docker Volumes)
docker compose down -v
```