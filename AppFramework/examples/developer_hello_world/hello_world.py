"""
This module sends OpenTelemetry with OTLP GRPC export for traces, metrics, and logs.

The script initializes the OpenTelemetry SDK for tracing, metrics, and logging,
and exports the data using the OTLP protocol (gRPC) to a local OTLP endpoint
(`http://localhost:4317`).

The application runs indefinitely, generating the following signals every second:

1. **Traces**: A new trace span is created every second with a simple log entry for each trace.
2. **Logs**: Log messages are emitted every second, including both info and debug-level logs.
3. **Metrics**: A counter metric is incremented by one every second.

The OTLP exporters for traces, logs, and metrics are configured to send data to a local endpoint
 (the AppFramework Development Stack).

Key components:
- **TracerProvider**: Configures the trace provider and exports traces using `OTLPSpanExporter`.
- **MeterProvider**: Configures the metric provider and exports metrics using `OTLPMetricExporter`.
- **LoggerProvider**: Configures the logger provider and exports logs using `OTLPLogExporter`.
- **PeriodicExportingMetricReader**: Ensures metrics are exported at regular intervals (1 second).
- **BatchSpanProcessor & BatchLogRecordProcessor**: Used to batch and export spans and log records.

The application continuously runs, generating and exporting telemetry data to the configured OTLP
endpoint.
"""

import time
import logging
from opentelemetry import trace
from opentelemetry._logs import set_logger_provider
from opentelemetry.metrics import get_meter_provider, set_meter_provider
from opentelemetry.sdk.metrics import MeterProvider
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk._logs import LoggerProvider, LoggingHandler
from opentelemetry.exporter.otlp.proto.grpc._log_exporter import OTLPLogExporter
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.exporter.otlp.proto.grpc.metric_exporter import OTLPMetricExporter
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.sdk._logs.export import BatchLogRecordProcessor
from opentelemetry.sdk.metrics.export import PeriodicExportingMetricReader

logging.basicConfig(level=logging.DEBUG)

# Configure OTLP exporters
otlp_log_exporter = OTLPLogExporter(endpoint="http://localhost:4317", insecure=True)
otlp_trace_exporter = OTLPSpanExporter(endpoint="http://localhost:4317", insecure=True)
otlp_metric_exporter = OTLPMetricExporter(endpoint="http://localhost:4317", insecure=True)

resource=Resource.create({"service.name": "hello-world"})

# Set up the Tracer provider and OTLP export for traces
trace.set_tracer_provider(TracerProvider(resource=resource))
tracer = trace.get_tracer(__name__)
trace.get_tracer_provider().add_span_processor(BatchSpanProcessor(otlp_trace_exporter))

metric_reader = PeriodicExportingMetricReader(otlp_metric_exporter, export_interval_millis=1000)
provider = MeterProvider(resource=resource, metric_readers=[metric_reader])
set_meter_provider(provider)
meter = get_meter_provider().get_meter("hello-world", "0.0.1")


# Set up Log exporter (OTLP) for logs
logger_provider = LoggerProvider(resource=resource)
set_logger_provider(logger_provider)
logger_provider.add_log_record_processor(BatchLogRecordProcessor(otlp_log_exporter))
handler = LoggingHandler(level=logging.DEBUG, logger_provider=logger_provider)

# Attach OTLP handler to root logger
logging.getLogger().addHandler(handler)

logger = logging.getLogger("myapp.hello")

counter = meter.create_counter("metric_counter",
                               description="An example metric that increments every second")

# Run forever, tracing, logging, and incrementing metrics every second
while True:
    # Create trace every second
    with tracer.start_as_current_span("hello-world-span") as span:
        span.set_attribute("custom.attribute1", "value1")
        span.set_attribute("custom.attribute2", 1234567)
        logger.info("Started a new trace at %d.", time.time_ns())

    logger.debug("Here's another message at %d.", time.time_ns())

    # Increment metric
    counter.add(1)

    # Sleep for 1 second
    time.sleep(1)
