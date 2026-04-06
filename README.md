# dbt Airlines CI Exercise

A hands-on exercise for learning CI/CD concepts with dbt and GitHub Actions.

## What This Repo Contains

A dbt project modeling US airline flight data with:

- **3 staging models**: `stg_airports`, `stg_airlines`, `stg_flights`
- **2 dimension models**: `dim_airport`, `dim_airline`
- **1 fact model**: `fact_flights`
- **Schema tests**: `not_null`, `unique`, `relationships`
- **Custom tests**: revenue validation, flight count range checks
- **GitHub Actions CI pipeline** with 4 validation gates

## The Four Gates

Data pipelines are protected by four validation gates. Three of them validate **code** and run on every pull request. The fourth validates **data** and runs on a schedule in the orchestration layer.

### CI Gates (run on every PR)

| Gate | What It Does | Tool |
|------|-------------|------|
| Gate 1 | **Lint SQL** -- enforces lowercase keywords, consistent formatting | SQLFluff |
| Gate 2 | **Build models** -- seeds data, compiles and runs all models | dbt + DuckDB |
| Gate 3 | **Run tests** -- executes schema tests and custom business logic tests | dbt |

### Orchestration Gate (runs on a schedule, before production builds)

| Gate | What It Does | Tool |
|------|-------------|------|
| Gate 4 | **Source freshness** -- checks that source tables have been loaded recently | dbt |

Gate 4 does not run in CI because it validates the state of data in the warehouse, not the quality of a code change. In production, it runs before `dbt build` via Airflow, dbt Cloud, or a cron job. If the most recent data is older than the configured threshold, the pipeline stops before building models on stale data. See `models/sources.yml` for the threshold configuration.

---

## Running Locally

### Option A: Docker (no Python setup needed)

```bash
docker build -t dbt-airlines-pipeline .
```

The build runs the full pipeline -- seeds, models, and tests. If the image builds successfully, everything works.

### Option B: Python

Requires Python 3.11+.

```bash
pip install dbt-duckdb sqlfluff
dbt deps                           # install dbt_utils
dbt seed                           # load CSV data into DuckDB
dbt run                            # build all 6 models
dbt test                           # run all 22 tests
sqlfluff lint models/ tests/       # lint all SQL files
```

Expected output:

- `dbt seed` -- 3 seeds loaded (15 airlines, 49 airports, 1030 flights)
- `dbt run` -- 6 models built (3 views, 3 tables)
- `dbt test` -- 22 tests passed
- `sqlfluff lint` -- "All Finished!" with no violations

No database server required. DuckDB runs in-process and creates a local `dbt_airlines.duckdb` file (gitignored).

---

## Exercise Instructions

Everything below can be done entirely from the GitHub web UI -- no local setup required.

### Phase 1: Setup

1. **Fork this repository**
   - Click **"Fork"** in the top right of this page
   - Keep all defaults, click **"Create fork"**

2. **Enable Actions on your fork**
   - Go to your fork's **Settings > Actions > General**
   - Select **"Allow all actions and reusable workflows"**
   - Click **Save**

### Phase 2: Happy Path (make a change, see CI pass)

3. **Create a branch and edit a file**
   - Navigate to `models/dimensions/dim_airport.sql`
   - Click the **pencil icon** (Edit this file)
   - GitHub will prompt you to create a branch -- name it `feature/add-country-code`
   - Add `country` after `state` so the file looks like:
     ```sql
     select
         iata_code,
         airport_name,
         city,
         state,
         country
     from airports
     ```
   - Click **"Commit changes"**

4. **Open a Pull Request**
   - GitHub will show a banner to create a PR from your new branch -- click **"Compare & pull request"**
   - **Important**: Make sure the base repository is **your fork**, not the upstream repo
   - Click **"Create pull request"**

5. **Watch CI run** -- go to the **"Checks"** tab on the PR and watch all three gates pass.

### Phase 3: Deliberate Failure (break the lint gate)

6. **Edit the file again from the PR branch**
   - On the PR page, go to **"Files changed"** > click the **three dots (...)** on `dim_airport.sql` > **"Edit file"**
   - Change `select` to `SELECT` (uppercase):
     ```sql
     SELECT
         iata_code,
         airport_name,
         city,
         state,
         country
     from airports
     ```
   - Click **"Commit changes"** (make sure you are committing to the `feature/add-country-code` branch)

7. **Watch it fail** -- the commit updates your open PR. Gate 1 (Lint) will fail with a red X. Click the failed check to see SQLFluff's error message.

8. **Fix and verify** -- edit the file again, change `SELECT` back to `select`, and commit. Watch CI go green again.

### Phase 4: Run the pipeline manually

9. **Trigger the workflow without a PR**
   - Go to the **"Actions"** tab in your fork
   - Select the **"dbt CI"** workflow on the left
   - Click **"Run workflow"**, pick a branch, and click the green **"Run workflow"** button
   - Watch the run complete

### Phase 5: Bonus (if time permits)

10. Try editing `dim_airport.sql` to add a column that does not exist in `stg_airports.sql`. What happens when you push?

---

## Troubleshooting

### Actions not triggering on my fork
GitHub Actions are disabled by default on forks. Go to **Settings > Actions > General > "Allow all actions and reusable workflows"** and save.

### PR targets the upstream repo instead of my fork
When creating the PR, change the **base repository** dropdown to your own fork.

### SQLFluff not finding violations
Make sure the `SELECT` keyword is in actual SQL code (not a comment), and that you saved the file before committing.

---

## Project Structure

```
dbt-airlines-pipeline/
|-- .github/workflows/dbt-ci.yml   # CI pipeline (4 gates)
|-- models/
|   |-- staging/                    # Raw data cleaning
|   |-- dimensions/                 # Dimension tables
|   |-- facts/                      # Fact tables
|   |-- schema.yml                  # Schema tests
|   `-- sources.yml                 # Source definitions
|-- tests/                          # Custom business logic tests
|-- .sqlfluff                       # Lint configuration
|-- dbt_project.yml                 # dbt project config
|-- profiles.yml                    # Connection profiles
`-- packages.yml                    # dbt package dependencies
```
