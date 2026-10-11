FROM zero-trust-observability-audit-gateway:0.1.0 AS application

FROM python:3.12-alpine@sha256:1b668429b3511ab407d8e00648891631b0b1a4d7e15e3ca70f38ab5b91ad4ab4 AS release
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1 PYTHONPATH=/app/mcp:/app
WORKDIR /app
COPY 04-mcp-constrained-tools/code/requirements.lock /runtime-requirements.lock
RUN python -m pip install --no-cache-dir -r /runtime-requirements.lock opentelemetry-sdk==1.45.1 opentelemetry-exporter-otlp-proto-http==1.45.1
COPY --from=application /app /app
COPY --from=application /telemetry-scripts /telemetry-scripts
COPY --from=application /identity-scripts /identity-scripts
USER 10001:10001
EXPOSE 8000
CMD ["python", "-m", "uvicorn", "app.observability.runtime:create_app", "--factory", "--host", "0.0.0.0", "--port", "8000", "--no-access-log"]

FROM zero-trust-observability-audit-checks:0.1.0 AS checks
USER 10001:10001
COPY 09-supply-chain-and-ci/code/scripts /supply-scripts
COPY 09-supply-chain-and-ci/code/tests /supply-tests
ENV MYPY_CACHE_DIR=/dev/null
CMD ["python", "-m", "pytest", "-p", "no:cacheprovider", "/supply-tests", "-q"]