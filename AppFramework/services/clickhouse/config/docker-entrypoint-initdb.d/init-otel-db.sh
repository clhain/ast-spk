#!/bin/bash
set -e

# This initializes the Otel Database. The otel collector exporter is responsible
# for creating the associated tables for each signal type.
clickhouse client <<-EOSQL
    CREATE DATABASE IF NOT EXISTS otel;
EOSQL
