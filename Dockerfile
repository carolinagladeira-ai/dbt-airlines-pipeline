FROM python:3.11-slim

WORKDIR /app

RUN pip install --no-cache-dir dbt-duckdb sqlfluff

COPY . .

ENV DBT_PROFILES_DIR=/app

RUN dbt deps && dbt seed && dbt run && dbt test
