FROM postgres:16.2-bullseye

# https://stackoverflow.com/questions/77979910/docker-postgresql-pg-cron-unrecognized-configuration-parameter-cron-databa
# NOTE: You'd need to set shared_preload_libraries
#
RUN apt-get update \
      && apt-get -y --no-install-recommends install \
    postgresql-16-cron \
    postgresql-16-pgvector \
    && rm -rf /var/lib/apt/lists/*

# NOTE: test if the extension is working by running this then execing into the
#       container and running psql
# docker run --rm --name some-postgres
# -e POSTGRES_PASSWORD=mysecretpassword geekodour/postgres_w_pg_cron:latest_amd64
#
# psql -h localhost -U postgres
# Then try CREATE EXT..
