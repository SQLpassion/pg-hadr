#!/bin/bash
set -e

# Make sure that PostgreSQL doesn't run
pg_ctl -D "$PGDATA" -m fast -w stop || true

# Delete the old PGDATA directory
echo "SQLpassion: Remove existing data in $PGDATA..."
rm -rf $PGDATA/*

# Create a new base backup, and initialize the secondary replica (option -R)
echo "SQLpassion: Initialize replica from Primary through pg_basebackup..."
pg_basebackup -h pg1 -D "$PGDATA" -U replicator --slot="$SLOT_NAME" -Fp -Xs -P -R -w

# Start PostgreSQL in Stand-by mode
echo "SQLpassion: Starting PostgreSQL in Stand-by mode..."
pg_ctl -D "$PGDATA" -l "$PGDATA/postgres.log" -w start

# The Secondary replica was successfully configured and started
echo "SQLpassion: PostgreSQL replica was successfully started."