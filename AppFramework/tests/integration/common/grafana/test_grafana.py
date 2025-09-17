import pytest


@pytest.mark.grafana
def test_grafana_connection(grafana_client):
    """
    Test to ensure Grafana is reachable and its server info is valid.
    """
    try:
        grafana_client.connect()
        health = grafana_client.health.check()
        # Assert the health is 'ok' (Grafana instance is healthy)
        assert health.get('database') == 'ok', f"Expected health['database'] status to be 'ok', got {health.get('database')}"
    except Exception as e:
        pytest.fail(f"Failed to connect to Grafana: {e}")


@pytest.mark.grafana
def test_grafana_configured_datasources(grafana_client):
    """
    Test to ensure all configured Grafana Datasources are reachable.
    """
    try:
        grafana_client.connect()
        datasources = grafana_client.datasource.list_datasources()
        for datasource in datasources:
            datasource_name = datasource.get('name')
            datasource_uid = datasource.get('uid')

            # Invoke the health check.
            healthinfo = grafana_client.datasource.health_inquiry(datasource_uid=datasource_uid)
            # DatasourceHealthResponse(uid='PDEE91DDB90597936', type='grafana-clickhouse-datasource', success=True, status='OK', message='Data source is working', duration=0.0126, response={'message': 'Data source is working', 'status': 'OK'})
            assert healthinfo.success, f"Expected DatasourceHealthresponse.success to be True for Datasource.name={datasource_name}, got {healthinfo.success}. Message: {healthinfo.message}"
    except Exception as e:
        pytest.fail(f"Failed to connect to Grafana: {e}")