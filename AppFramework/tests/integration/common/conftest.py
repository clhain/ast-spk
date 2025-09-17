import pytest
import os
from grafana_client import GrafanaApi

@pytest.fixture(scope="module")
def grafana_client():
    """
    Fixture to create a Grafana client connected to the instance.
    """
    client = GrafanaApi.from_env()
    return client
