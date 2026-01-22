SET SERVEROUTPUT ON
DECLARE
  v_xml XMLTYPE;
BEGIN
  SELECT XMLTYPE(bfilename('XML_DIR','china_credit_dashboard.xml'), 1)
  INTO v_xml
  FROM dual;

  DBMS_OUTPUT.PUT_LINE('Deploying China Credit Dashboard');

  -- Schema objects
  @@schema/dim/dim_tenor.sql
  @@schema/fact/fact_china_zero_curve.sql
  @@schema/fact/fact_china_credit_spread.sql
  @@schema/fact/fact_china_credit_curve.sql

  -- Procedures
  @@procedures/load_china_rate.sql
  @@procedures/build_china_credit_curve.sql
  @@procedures/pboc_shock_generator.sql

  -- Views / MVs
  @@views/vw_china_yield_curve.sql
  @@schema/mv/mv_china_credit_dashboard.sql

  DBMS_OUTPUT.PUT_LINE('Deployment completed successfully');
END;
/

