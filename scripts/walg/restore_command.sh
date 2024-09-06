#!/bin/bash

export PGHOST=localhost
export PGPORT=6000
export AWS_REGION=us-east-2
export WALE_S3_PREFIX=s3://walshipping-bucket-test

wal-g wal-fetch $1 $2
