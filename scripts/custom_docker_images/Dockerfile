FROM postgres:16.2-bullseye

# https://stackoverflow.com/questions/77979910/docker-postgresql-pg-cron-unrecognized-configuration-parameter-cron-databa
# NOTE: You'd need to set shared_preload_libraries
RUN apt-get update \
      && apt-get -y --no-install-recommends install \
    postgresql-16-cron \
    postgresql-15-pgvector \
    && rm -rf /var/lib/apt/lists/*
