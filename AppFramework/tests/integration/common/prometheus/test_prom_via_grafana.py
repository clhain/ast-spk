import pytest
import json
import time

from grafana_client.model import DatasourceIdentifier


PROMETHEUS_DATASOURCE_NAME="Prometheus"

@pytest.mark.metrics_prometheus
def test_grafana_prometheus_datasource_connection(grafana_client):
    """
    Test to ensure Prometheus is reachable via Grafana.
    """
    try:
        grafana_client.connect()
        try:
            datasource = grafana_client.datasource.find_datasource(PROMETHEUS_DATASOURCE_NAME)
        except Exception as e:
            pytest.fail(f"Failed to fetch Prometheus datasource: '{PROMETHEUS_DATASOURCE_NAME}': {e}")
        prometheus_uid = datasource.get('uid')
        healthinfo = grafana_client.datasource.health_inquiry(datasource_uid=prometheus_uid)
        assert healthinfo.success, f"Expected DatasourceHealthresponse.success to be True for Datasource.name={PROMETHEUS_DATASOURCE_NAME}, got {healthinfo.success}. Message: {healthinfo.message}"
    except Exception as e:
        pytest.fail(f"Failed to connect to Grafana: {e}")


@pytest.mark.metrics_prometheus
def test_grafana_prometheus_otel_metrics(grafana_client):
    """
    Test to ensure Prometheus has Otel Metrics entries (accessible via grafana)
    """
    # Sometimes there's a delay before the metric is queryable
    max_retries = 4
    attempt = 0
    success = False
    result = None
    try:
        grafana_client.connect()
        try:
            datasource = grafana_client.datasource.find_datasource(PROMETHEUS_DATASOURCE_NAME)
        except Exception as e:
            pytest.fail(f"Failed to fetch Prometheus datasource: '{PROMETHEUS_DATASOURCE_NAME}': {e}")
        clickhouse_uid = datasource.get('uid')

        while attempt < max_retries and not success:
            result = grafana_client.datasource.smartquery(DatasourceIdentifier(uid=clickhouse_uid), "gen", attrs={}, request=None)
            print(json.dumps(result, indent=2))
            assert result["results"]["test"]["status"]==200, f"Failed to query Datasource.name={PROMETHEUS_DATASOURCE_NAME}, got status={result['results']['test']['status']}."
            try:
                assert len(result["results"]["test"]["frames"][0]["data"]["values"])>0, f"Failed to fetch OTEL metrics entries in Datasource.name={PROMETHEUS_DATASOURCE_NAME} from telemetrygen"
                success = True
            except Exception as e:
                time.sleep(2 ** attempt)
                attempt += 1
                print(f"Retrying {attempt}/{max_retries} after error: {e}")
                
    except Exception as e:
        pytest.fail(f"Failed to connect to Grafana: {e}")
