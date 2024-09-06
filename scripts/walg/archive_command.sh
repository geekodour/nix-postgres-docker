#!/usr/bin/env bash

# NOTE:
# - This script is supposed to be run as "archive_command.sh %p", adjust postgreqsql.conf accordingly
# - Expected env vars:
#   - AWS_ACCESS_KEY_ID
#   - AWS_SECRET_ACCESS_KEY
#   - AWS_ENDPOINT
#   - WALG_S3_PREFIX
#   - PG?

wal-g wal-push $1
