import json
import pytest
from grafana_client.model import DatasourceIdentifier


CLICKHOUSE_DATASOURCE_NAME="ClickHouse"


@pytest.mark.metrics_clickhouse
@pytest.mark.logs_clickhouse
@pytest.mark.traces_clickhouse
@pytest.mark.all_clickhouse
def test_grafana_clickhouse_datasource_connection(grafana_client):
    """
    Test to ensure Clickhouse is reachable via Grafana.
    """
    try:
        grafana_client.connect()
        try:
            datasource = grafana_client.datasource.find_datasource(CLICKHOUSE_DATASOURCE_NAME)
        except Exception as e:
            pytest.fail(f"Failed to fetch Clickhouse datasource: '{CLICKHOUSE_DATASOURCE_NAME}': {e}")
        clickhouse_uid = datasource.get('uid')
        healthinfo = grafana_client.datasource.health_inquiry(datasource_uid=clickhouse_uid)
        assert healthinfo.success, f"Expected DatasourceHealthresponse.success to be True for Datasource.name={CLICKHOUSE_DATASOURCE_NAME}, got {healthinfo.success}. Message: {healthinfo.message}"
    except Exception as e:
        pytest.fail(f"Failed to connect to Grafana: {e}")


@pytest.mark.logs_clickhouse
@pytest.mark.all_clickhouse
def test_grafana_clickhouse_otel_logs(grafana_client):
    """
    Test to ensure Clickhouse has Otel Log entries (accessible via grafana)
    """
    try:
        grafana_client.connect()
        try:
            datasource = grafana_client.datasource.find_datasource(CLICKHOUSE_DATASOURCE_NAME)
        except Exception as e:
            pytest.fail(f"Failed to fetch Clickhouse datasource: '{CLICKHOUSE_DATASOURCE_NAME}': {e}")
        clickhouse_uid = datasource.get('uid')
        request = {
            #"url": "api/ds/query?ds_type=grafana-clickhouse-datasource&requestId=explore_kuu",
            "method": "POST",
            "data": {
                "queries": [
                    {
                    "datasource": {
                        "type": "grafana-clickhouse-datasource",
                        "uid": clickhouse_uid
                    },
                    "editorType": "sql",
                    "rawSql": "SELECT Timestamp as \"timestamp\", Body as \"body\" FROM \"otel\".\"otel_logs\" WHERE ( timestamp >= $__fromTime ) AND (body LIKE '%the message%') ORDER BY timestamp DESC LIMIT 10",
                    }
                ]
            }
        }
        result = grafana_client.datasource.smartquery(DatasourceIdentifier(uid=clickhouse_uid), None, attrs={}, request=request)
        assert result["results"]["A"]["status"]==200, f"Failed to query Datasource.name={CLICKHOUSE_DATASOURCE_NAME}, got status={result['results']['A']['status']}."
        assert len(result["results"]["A"]["frames"][0]["data"]["values"])>0, f"Failed to fetch OTEL Log messages in Datasource.name={CLICKHOUSE_DATASOURCE_NAME} from telemetrygen matching \"the message\""
    except Exception as e:
        pytest.fail(f"Failed to connect to Grafana: {e}")


@pytest.mark.traces_clickhouse
@pytest.mark.all_clickhouse
def test_grafana_clickhouse_otel_traces(grafana_client):
    """
    Test to ensure Clickhouse has Otel Trace entries (accessible via grafana)
    """
    try:
        grafana_client.connect()
        try:
            datasource = grafana_client.datasource.find_datasource(CLICKHOUSE_DATASOURCE_NAME)
        except Exception as e:
            pytest.fail(f"Failed to fetch Clickhouse datasource: '{CLICKHOUSE_DATASOURCE_NAME}': {e}")
        clickhouse_uid = datasource.get('uid')
        request = {
            "method": "POST",
            "data": {
                "queries": [
                    {
                    "datasource": {
                        "type": "grafana-clickhouse-datasource",
                        "uid": clickhouse_uid
                    },
                    "pluginVersion": "4.5.1",
                    "editorType": "builder",
                    "rawSql": "SELECT \"TraceId\" as traceID FROM \"otel\".\"otel_traces\" WHERE ( Timestamp >= $__fromTime ) AND ( ParentSpanId = '' ) AND ( Duration > 0 ) AND (ServiceName LIKE '%telemetrygen%') ORDER BY Timestamp DESC LIMIT 10",
                    "format": 1,
                    "queryType": "traces",
                    }
                ]
            }
        }
        result = grafana_client.datasource.smartquery(DatasourceIdentifier(uid=clickhouse_uid), None, attrs={}, request=request)
        assert result["results"]["A"]["status"]==200, f"Failed to query Datasource.name={CLICKHOUSE_DATASOURCE_NAME}, got status={result['results']['A']['status']}."
        assert len(result["results"]["A"]["frames"][0]["data"]["values"])>0, f"Failed to fetch OTEL Trace entries in Datasource.name={CLICKHOUSE_DATASOURCE_NAME} from telemetrygen"
    except Exception as e:
        pytest.fail(f"Failed to connect to Grafana: {e}")


@pytest.mark.metrics_clickhouse
@pytest.mark.all_clickhouse
def test_grafana_clickhouse_otel_metrics(grafana_client):
    """
    Test to ensure Clickhouse has Otel Metrics entries (accessible via grafana)
    """
    try:
        grafana_client.connect()
        try:
            datasource = grafana_client.datasource.find_datasource(CLICKHOUSE_DATASOURCE_NAME)
        except Exception as e:
            pytest.fail(f"Failed to fetch Clickhouse datasource: '{CLICKHOUSE_DATASOURCE_NAME}': {e}")
        clickhouse_uid = datasource.get('uid')
        request = {
            "method": "POST",
            "data": {
                "queries": [
                    {
                    "datasource": {
                        "type": "grafana-clickhouse-datasource",
                        "uid": clickhouse_uid
                    },
                    "pluginVersion": "4.5.1",
                    "editorType": "builder",
                    "rawSql": "SELECT TimeUnix as \"time\", Value FROM \"otel\".\"otel_metrics_gauge\" WHERE ( time >= $__fromTime) ORDER BY time ASC LIMIT 10",
                    "format": 1,
                    "queryType": "timeseries",
                    }
                ]
            }
        }
        result = grafana_client.datasource.smartquery(DatasourceIdentifier(uid=clickhouse_uid), None, attrs={}, request=request)
        assert result["results"]["A"]["status"]==200, f"Failed to query Datasource.name={CLICKHOUSE_DATASOURCE_NAME}, got status={result['results']['A']['status']}."
        assert len(result["results"]["A"]["frames"][0]["data"]["values"])>0, f"Failed to fetch OTEL Trace entries in Datasource.name={CLICKHOUSE_DATASOURCE_NAME} from telemetrygen"
    except Exception as e:
        pytest.fail(f"Failed to connect to Grafana: {e}")
