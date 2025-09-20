#!/bin/bash
set -e

# Create the otel db if its not there yet.
clickhouse client <<-EOSQL
    CREATE DATABASE IF NOT EXISTS otel;
EOSQL

# Create the null log table for incoming otel data
clickhouse client <<-EOSQL
    CREATE TABLE IF NOT EXISTS otel.otel_logs
    (
        Timestamp DateTime64(9) CODEC(Delta(8), ZSTD(1)),
        TraceId String CODEC(ZSTD(1)),
        SpanId String CODEC(ZSTD(1)),
        TraceFlags UInt8,
        SeverityText LowCardinality(String) CODEC(ZSTD(1)),
        SeverityNumber UInt8,
        ServiceName LowCardinality(String) CODEC(ZSTD(1)),
        Body String CODEC(ZSTD(1)),
        ResourceSchemaUrl LowCardinality(String) CODEC(ZSTD(1)),
        ResourceAttributes Map(LowCardinality(String), String) CODEC(ZSTD(1)),
        ScopeSchemaUrl LowCardinality(String) CODEC(ZSTD(1)),
        ScopeName String CODEC(ZSTD(1)),
        ScopeVersion LowCardinality(String) CODEC(ZSTD(1)),
        ScopeAttributes Map(LowCardinality(String), String) CODEC(ZSTD(1)),
        LogAttributes Map(LowCardinality(String), String) CODEC(ZSTD(1)),
    )
    ENGINE = MergeTree
    ORDER BY Timestamp;
EOSQL

# Create the table for the extracted fields.
clickhouse client <<-EOSQL
    CREATE TABLE  IF NOT EXISTS otel.otel_logs_f5_12276
    (
        Timestamp DateTime64(9),
        SeverityText String,
        SeverityNumber UInt8,
            
    
        -- Extracted fields from structured_data["F5@12276"]
        acl_policy_name String,
        acl_policy_type String,
        acl_rule_name String,
        acl_rule_uuid String,
        action String,
        bigip_mgmt_ip String,
        context_name String,
        context_type String,
        dest_fqdn String,
        dest_ip String,
        dest_ipint_categories String,
        dest_port UInt16,
        dest_vlan String,
        dest_zone String,
        ip_protocol String,
        source_ip String,
        source_port UInt16,
        vlan String,
        device_product String,
        device_vendor String,
        device_version String,
        flow_id String,
        errdefs_msg_name String,
        hostname String,
        drop_reason String,
        dst_geo String,
        errdefs_msgno String,
        partition_name String,
        route_domain UInt16,
        sa_translation_pool String,
        sa_translation_type String,
        send_to_vs String,
        severity String,
        source_fqdn String,
        source_ipint_categories String,
        source_user String,
        source_user_group String,
        src_geo String,
        src_zone String,
        translated_dest_ip String,
        translated_dest_port String,
        translated_ip_protocol String,
        translated_route_domain String,
        translated_source_ip String,
        translated_source_port String,
        translated_vlan String
    )
    ENGINE = MergeTree
    ORDER BY Timestamp;
EOSQL


# Create the Materialized View that populates the access log table from incoming
# otel logs.
clickhouse client <<-EOSQL
    CREATE MATERIALIZED VIEW  IF NOT EXISTS otel.otel_logs_f5_mv
    TO otel.otel_logs_f5_12276
    AS
    SELECT
        Timestamp,
        SeverityText,
        SeverityNumber,

        parsed['acl_policy_name'] AS acl_policy_name,
        parsed['acl_policy_type'] AS acl_policy_type,
        parsed['acl_rule_name'] AS acl_rule_name,
        parsed['acl_rule_uuid'] AS acl_rule_uuid,
        parsed['action'] AS action,
        parsed['bigip_mgmt_ip'] AS bigip_mgmt_ip,
        parsed['context_name'] AS context_name,
        parsed['context_type'] AS context_type,
        parsed['dest_fqdn'] AS dest_fqdn,
        parsed['dest_ip'] AS dest_ip,
        parsed['dest_ipint_categories'] AS dest_ipint_categories,
        toUInt16(parsed['dest_port']) AS dest_port,
        parsed['dest_vlan'] AS dest_vlan,
        parsed['dest_zone'] AS dest_zone,
        parsed['ip_protocol'] AS ip_protocol,
        parsed['source_ip'] AS source_ip,
        toUInt16(parsed['source_port']) AS source_port,
        parsed['vlan'] AS vlan,
        parsed['device_product'] AS device_product,
        parsed['device_vendor'] AS device_vendor,
        parsed['device_version'] AS device_version,
        parsed['flow_id'] AS flow_id,
        parsed['errdefs_msg_name'] AS errdefs_msg_name,
        parsed['hostname'] AS hostname,
        parsed['drop_reason'] AS drop_reason,
        parsed['dst_geo'] AS dst_geo,
        parsed['errdefs_msgno'] AS errdefs_msgno,
        parsed['partition_name'] AS partition_name,
        toUInt16(parsed['route_domain']) AS route_domain,
        parsed['sa_translation_pool'] AS sa_translation_pool,
        parsed['sa_translation_type'] AS sa_translation_type,
        parsed['send_to_vs'] AS send_to_vs,
        parsed['severity'] AS severity,
        parsed['source_fqdn'] AS source_fqdn,
        parsed['source_ipint_categories'] AS source_ipint_categories,
        parsed['source_user'] AS source_user,
        parsed['source_user_group'] AS source_user_group,
        parsed['src_geo'] AS src_geo,
        parsed['src_zone'] AS src_zone,
        parsed['translated_dest_ip'] AS translated_dest_ip,
        parsed['translated_dest_port'] AS translated_dest_port,
        parsed['translated_ip_protocol'] AS translated_ip_protocol,
        parsed['translated_route_domain'] AS translated_route_domain,
        parsed['translated_source_ip'] AS translated_source_ip,
        parsed['translated_source_port'] AS translated_source_port,
        parsed['translated_vlan'] AS translated_vlan

    FROM (
        SELECT
            *,
            JSONExtract(LogAttributes['structured_data'], 'F5@12276', 'Map(String, String)') AS parsed
        FROM otel.otel_logs
        WHERE isNotNull(LogAttributes['structured_data']) AND LogAttributes['structured_data'] != ''
    );
EOSQL
