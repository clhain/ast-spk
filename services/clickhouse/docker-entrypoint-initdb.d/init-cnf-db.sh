
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
        action String,
        bigip_mgmt_ip IPv4,
        context_name String,
        context_type String,
        dest_ip IPv4,
        dest_port UInt16,
        ip_protocol String,
        source_ip IPv4,
        source_port UInt16,
        vlan String,
        device_product String,
        device_vendor String,
        device_version String,
        flow_id String,
        errdefs_msg_name String,
        hostname String
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
        parsed['action'] AS action,
        IPv4StringToNum(parsed['bigip_mgmt_ip']) AS bigip_mgmt_ip,
        parsed['context_name'] AS context_name,
        parsed['context_type'] AS context_type,
        IPv4StringToNum(parsed['dest_ip']) AS dest_ip,
        toUInt16OrZero(parsed['dest_port']) AS dest_port,
        parsed['ip_protocol'] AS ip_protocol,
        IPv4StringToNum(parsed['source_ip']) AS source_ip,
        toUInt16OrZero(parsed['source_port']) AS source_port,
        parsed['vlan'] AS vlan,
        parsed['device_product'] AS device_product,
        parsed['device_vendor'] AS device_vendor,
        parsed['device_version'] AS device_version,
        parsed['flow_id'] AS flow_id,
        parsed['errdefs_msg_name'] AS errdefs_msg_name,
        parsed['hostname'] AS hostname

    FROM (
        SELECT
            *,
            JSONExtract(LogAttributes['structured_data'], 'F5@12276', 'Map(String, String)') AS parsed
        FROM otel.otel_logs
        WHERE isNotNull(LogAttributes['structured_data']) AND LogAttributes['structured_data'] != ''
    );
EOSQL