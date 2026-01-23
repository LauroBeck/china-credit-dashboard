
# China Credit Dashboard

High-performance China credit curve analytics system built on **Oracle AI Database 26ai** with **parallel execution**, **shock scenarios**, and **intraday stress dashboards**.

---

## **Repository Structure**

china-credit-dashboard/
│
├── README.md
├── china_schema.sql # Dimensional & fact table creation
├── credit_curve_insert.sql # Inserts for credit curve & shocks
├── mv_build.sql # Materialized views for intraday analytics
├── deploy/ # Deployment scripts (Docker / SQL)
├── xml/ # Optional XML exports of tables/MVs
└── .github/
└── workflows/
└── oracle-sql-ci.yml # GitHub Actions: validate SQL


---

## **1. Environment Setup**

- **Database:** Oracle AI Database 26ai Free (v23.26.0.0.0)  
- **Docker Container:** `oracle23ai`  
- **Users:** `SYS`, `BLOOMBERG`  
- **PDB:** `JPMORGAN`  

**Example Commands:**
```sql
SHOW PDBS;
ALTER SYSTEM SET parallel_max_servers = 32 SCOPE=BOTH;
ALTER SESSION SET CONTAINER = JPMORGAN;

2. Resource Manager & Parallelism

    Created PDB-specific Resource Manager Plan: JPMORGAN_PLAN

    Parallelism configured for analytics & PX:

SHOW PARAMETER parallel_degree_policy;       -- MANUAL
SHOW PARAMETER parallel_max_servers;         -- 32
SHOW PARAMETER parallel_servers_target;      -- 32

3. Schema Creation

Dimensional Table:

CREATE TABLE dim_china_tenor (
  tenor_code VARCHAR2(10) PRIMARY KEY,
  tenor_name VARCHAR2(30) NOT NULL,
  days_count NUMBER NOT NULL
);

Fact Tables:

    fact_china_zero_curve – zero rates

    fact_china_credit_spread – credit spreads

    fact_china_credit_curve – computed credit curves

    fact_china_zero_curve_shock – ±50bps PBoC stress scenarios

    fact_china_credit_curve_shock – credit curves under shocks

Constraints: PKs, FKs, and parallel insert hints.
4. Data Inserts & Shock Scenarios

INSERT /*+ PARALLEL(8) */ INTO fact_china_credit_curve_shock
SELECT
    z.curve_date,
    z.shock_scn,
    s.credit_type_code,
    z.tenor_code,
    z.days_count,
    z.zero_rate + (s.spread_bps / 100) AS credit_rate,
    POWER(
        1 / (1 + (z.zero_rate + (s.spread_bps / 100)) / 100),
        z.days_count / 365
    ) AS discount_factor
FROM fact_china_zero_curve_shock z
JOIN fact_china_credit_spread s
  ON TRUNC(s.spread_date) = TRUNC(z.curve_date)
 AND TRIM(UPPER(s.tenor_code)) = TRIM(UPPER(z.tenor_code));

    Ensured unique constraint compliance on (CURVE_DATE, SHOCK_SCN, TENOR_CODE)

    Handled duplicates with DELETE ... WHERE before insert.

5. PL/SQL Procedures

    build_china_credit_curve(p_curve_date DATE) computes daily credit curves for all tenors & credit types.

DELETE FROM fact_china_credit_curve
WHERE curve_date = p_curve_date;

INSERT INTO fact_china_credit_curve ...

Validation:

SELECT COUNT(*) FROM bloomberg.fact_china_credit_curve
WHERE curve_date = DATE '2026-01-21';

6. Materialized Views & Intraday Stress Dashboards

    Materialized View: mv_china_credit_intraday – FAST / ON DEMAND

    Views:

        vw_china_credit_intraday_delta – intraday delta / changes

        vw_china_credit_intraday_stress – cumulative 5-period widening

Example View:

CREATE OR REPLACE VIEW vw_china_credit_intraday_delta AS
SELECT
    curve_date,
    credit_type_code,
    tenor_code,
    spread_bps - LAG(spread_bps) OVER (PARTITION BY credit_type_code, tenor_code ORDER BY curve_date) AS spread_change_bps
FROM mv_china_credit_intraday;

7. Validation / Debugging

    Row counts & join checks:

SELECT COUNT(*) FROM fact_china_zero_curve;
SELECT COUNT(*)
FROM fact_china_zero_curve_shock z
JOIN fact_china_credit_spread s
  ON TRUNC(s.spread_date) = TRUNC(z.curve_date)
 AND TRIM(UPPER(s.tenor_code)) = TRIM(UPPER(z.tenor_code));

8. GitHub CI/CD

    GitHub Actions: .github/workflows/oracle-sql-ci.yml

    Validates SQL syntax & runs checks on all scripts before push

    Requires workflow scope on Personal Access Token to commit MVs

9. Execution Example

Inside the Docker container:

sudo docker exec -it oracle23ai sqlplus / as sysdba

Run scripts in sequence:

-- Create schema
@/opt/oracle/china_schema.sql

-- Insert credit curves and shocks
@/opt/oracle/credit_curve_insert.sql

-- Build materialized views
@/opt/oracle/mv_build.sql

10. Next Steps

    Enable PARALLEL on fact tables

    Generate PBoC ±50bps intraday dashboards

    Implement FAST-refresh MV for live intraday updates

    Extend GitHub Actions CI to automatically validate inserts & views
