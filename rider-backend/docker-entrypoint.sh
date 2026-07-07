#!/bin/sh
set -e

# Wait for database to be ready if DATABASE_URL is set
if [ -n "$DATABASE_URL" ]; then
  echo "Checking database connection..."
  # Extract host and port from DATABASE_URL if possible
  # Format typically: postgresql://user:password@host:port/dbname
  DB_HOST=$(echo $DATABASE_URL | sed -e 's|.*://.*@||' -e 's|/.*||' -e 's|:.*||')
  DB_PORT=$(echo $DATABASE_URL | sed -e 's|.*://.*@||' -e 's|/.*||' -e 's|.*:||')

  if [ -z "$DB_PORT" ] || [ "$DB_PORT" = "$DB_HOST" ]; then
    DB_PORT=5432
  fi

  echo "Waiting for database at $DB_HOST:$DB_PORT..."
  until pg_isready -h "$DB_HOST" -p "$DB_PORT" -U "${DB_USER:-postgres}"; do
    echo "Database is unavailable - sleeping"
    sleep 2
  done
  echo "Database is up - running migrations"
fi

# Run pending migrations
npx prisma migrate deploy

# Start the application
exec "$@"
