# China Credit Dashboard (Oracle)

Institutional-grade China fixed income & credit analytics
built on Oracle Database.

## Features
- SHIBOR / PBoC / Gov yield curves
- Bootstrapped term structure
- SOE vs LGFV credit spread curves
- PBoC ±50bps shock scenarios
- Materialized views for Bloomberg-style dashboards

## Stack
- Oracle 23c / 19c
- PL/SQL
- Materialized Views
- XML-driven deployment

## Deploy
```bash
sqlplus bloomberg@DB @deploy/deploy_from_xml.sql

