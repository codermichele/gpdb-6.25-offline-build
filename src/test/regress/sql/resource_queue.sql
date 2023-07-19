-- SQL coverage of RESOURCE QUEUE

CREATE RESOURCE QUEUE regressq ACTIVE THRESHOLD 1;
SELECT * FROM pg_resqueue WHERE rsqname='regressq';
ALTER RESOURCE QUEUE regressq ACTIVE THRESHOLD 2 COST THRESHOLD 2000.00;
SELECT * FROM pg_resqueue WHERE rsqname='regressq';
ALTER RESOURCE QUEUE regressq COST THRESHOLD 3000.00 OVERCOMMIT;
SELECT * FROM pg_resqueue WHERE rsqname='regressq';
ALTER RESOURCE QUEUE regressq COST THRESHOLD 4e+3 NOOVERCOMMIT;
SELECT * FROM pg_resqueue WHERE rsqname='regressq';
COMMENT ON RESOURCE QUEUE regressq IS 'regressq comment';
DROP RESOURCE QUEUE regressq;
SELECT * FROM pg_resqueue WHERE rsqname='regressq';


-- more coverage
CREATE RESOURCE QUEUE regressq ACTIVE THRESHOLD 1 WITH (max_cost=2000);
SELECT * FROM pg_resqueue WHERE rsqname='regressq';
ALTER RESOURCE QUEUE regressq ACTIVE THRESHOLD 1 WITHOUT (max_cost);
SELECT * FROM pg_resqueue WHERE rsqname='regressq';
ALTER RESOURCE QUEUE regressq ACTIVE THRESHOLD 1 WITH (max_cost=2000)
WITHOUT (overcommit); -- negative
ALTER RESOURCE QUEUE regressq ACTIVE THRESHOLD 1 WITH (max_cost=2000)
WITHOUT (cost_overcommit); -- works
SELECT * FROM pg_resqueue WHERE rsqname='regressq';
ALTER RESOURCE QUEUE regressq OVERCOMMIT WITH (max_cost=2000);
SELECT * FROM pg_resqueue WHERE rsqname='regressq';
ALTER RESOURCE QUEUE regressq IGNORE THRESHOLD 1 WITHOUT (max_cost);
SELECT * FROM pg_resqueue WHERE rsqname='regressq';
ALTER RESOURCE QUEUE regressq WITH (priority=high);
SELECT * FROM pg_resqueue_attributes WHERE rsqname='regressq';
ALTER RESOURCE QUEUE regressq WITH (priority='MeDiUm');
SELECT * FROM pg_resqueue_attributes WHERE rsqname='regressq';
ALTER RESOURCE QUEUE regressq;
DROP RESOURCE QUEUE regressq;
SELECT * FROM pg_resqueue WHERE rsqname='regressq';

-- negative

CREATE RESOURCE QUEUE regressq2;
CREATE RESOURCE QUEUE none ACTIVE THRESHOLD 2;
;
CREATE RESOURCE QUEUE regressq2 ACTIVE THRESHOLD 2;
ALTER RESOURCE QUEUE regressq2 ACTIVE THRESHOLD -10;
ALTER RESOURCE QUEUE regressq2 COST THRESHOLD -1000.00;
ALTER RESOURCE QUEUE regressq2 WITH(max_cost=20,max_cost=21);
ALTER RESOURCE QUEUE regressq2 WITH(PRIORITY=funky);
ALTER RESOURCE QUEUE regressq2 WITHOUT(PRIORITY);
DROP RESOURCE QUEUE regressq2;

CREATE RESOURCE QUEUE regressq2 ACTIVE THRESHOLD -10;
CREATE RESOURCE QUEUE regressq2 COST THRESHOLD -1000.00;
CREATE RESOURCE QUEUE regressq2 IGNORE THRESHOLD -10;

CREATE RESOURCE QUEUE regressq2 ACTIVE THRESHOLD 2 ACTIVE THRESHOLD 2;
CREATE RESOURCE QUEUE regressq2 COST THRESHOLD 2 COST THRESHOLD 2;
CREATE RESOURCE QUEUE regressq2 OVERCOMMIT OVERCOMMIT;
CREATE RESOURCE QUEUE regressq2 OVERCOMMIT NOOVERCOMMIT;
CREATE RESOURCE QUEUE regressq2 IGNORE THRESHOLD 1 IGNORE THRESHOLD 1 ;

CREATE RESOURCE QUEUE regressq2 WITH (WITHLISTSTART=funky);

CREATE RESOURCE QUEUE regressq2 ACTIVE THRESHOLD 2;
ALTER RESOURCE QUEUE regressq2 ACTIVE THRESHOLD 2 ACTIVE THRESHOLD 2;
ALTER RESOURCE QUEUE regressq2 COST THRESHOLD 2 COST THRESHOLD 2;
ALTER RESOURCE QUEUE regressq2 OVERCOMMIT OVERCOMMIT;
ALTER RESOURCE QUEUE regressq2 OVERCOMMIT NOOVERCOMMIT;
ALTER RESOURCE QUEUE regressq2 IGNORE THRESHOLD 1 IGNORE THRESHOLD 1 ;

ALTER RESOURCE QUEUE none IGNORE THRESHOLD 1 ;
DROP RESOURCE QUEUE regressq2;

-- Create resource queue with cost_overcommit=true
create resource queue t3_test_q with (active_statements = 6,max_cost=5e+06 ,cost_overcommit=true, min_cost=50000);
select * from pg_resqueue where rsqname='t3_test_q';
drop resource queue t3_test_q;


-- Resource Queue should not be created inside Transaction block the error is the expected behavior
begin;
CREATE RESOURCE QUEUE db_resque_new1 ACTIVE THRESHOLD 2 COST THRESHOLD 2000.00;
end;

--
-- memory quota feature
--

-- negative

create resource queue test_rq with (max_cost=2000000, memory_limit='1gB'); -- should error out
create resource queue test_rq with (max_cost=2000000, memory_limit='0'); -- should error out

-- Creates and drops

create resource queue test_rq with (active_statements=2);
drop resource queue test_rq;
create resource queue test_rq with (active_statements=2, memory_limit='1024MB');

--
-- CPU priority feature
--
create resource queue test_rq_cpu with (active_statements=2, priority='HIGH');
create user test_rp_user with login;
alter role test_rp_user resource queue test_rq_cpu;
SET ROLE test_rp_user;
-- query priority and weight on master
select rqppriority, rqpweight from gp_toolkit.gp_resq_priority_backend where rqpsession in (select sess_id from pg_stat_activity where pid  = pg_backend_pid());
-- query priority and weight on segments
select rqppriority, rqpweight from gp_dist_random('gp_toolkit.gp_resq_priority_backend') where rqpsession in (select sess_id from pg_stat_activity where pid  = pg_backend_pid());
RESET ROLE;
drop user test_rp_user;
drop resource queue test_rq_cpu;

-- Alters

alter resource queue test_rq with (memory_limit='1024mb');
alter resource queue test_rq with (memory_limit='1024Kb');
alter resource queue test_rq with (memory_limit='2GB');
alter resource queue test_rq without (memory_limit);

drop resource queue test_rq;

-- SQL coverage of ROLE -> RESOURCE QUEUE

CREATE RESOURCE QUEUE reg_activeq ACTIVE THRESHOLD 2;
CREATE RESOURCE QUEUE reg_costq COST THRESHOLD 30000.00;
CREATE USER reg_u1 RESOURCE QUEUE reg_costq;
GRANT SELECT ON tenk1 TO reg_u1;
SELECT u.rolname, u.rolsuper, r.rsqname FROM pg_roles as u, pg_resqueue as r WHERE u.rolresqueue=r.oid and rolname='reg_u1';
ALTER USER reg_u1 RESOURCE QUEUE reg_activeq;
SELECT u.rolname, u.rolsuper, r.rsqname FROM pg_roles as u, pg_resqueue as r WHERE u.rolresqueue=r.oid and rolname='reg_u1';
CREATE USER reg_u2 RESOURCE QUEUE reg_activeq;
GRANT SELECT ON tenk1 TO reg_u2;
SELECT u.rolname, u.rolsuper, r.rsqname FROM pg_roles as u, pg_resqueue as r WHERE u.rolresqueue=r.oid and r.rsqname='reg_activeq';

-- negative

CREATE USER reg_u3 RESOURCE QUEUE bogusq;

-- feature must be on for tests to be valid
show resource_scheduler;

-- switch to a non privileged user for next tests
SET SESSION AUTHORIZATION reg_u1;

-- self deadlock (active queue threshold 2)
BEGIN;
DECLARE c1 CURSOR FOR SELECT 1 FROM tenk1;
DECLARE c2 CURSOR FOR SELECT 2 FROM tenk1;
DECLARE c3 CURSOR FOR SELECT 3 FROM tenk1; -- should detect deadlock
END;

-- track cursor open/close count (should not deadlock)
BEGIN;
DECLARE c1 CURSOR FOR SELECT 1 FROM tenk1;
CLOSE c1;
DECLARE c2 CURSOR FOR SELECT 2 FROM tenk1;
DECLARE c3 CURSOR FOR SELECT 3 FROM tenk1;
CLOSE c3;
DECLARE c4 CURSOR FOR SELECT 4 FROM tenk1;
FETCH c4;
END;

-- switch to a cost-limited queue
RESET SESSION AUTHORIZATION;
ALTER USER reg_u2 RESOURCE QUEUE reg_costq;
SET SESSION AUTHORIZATION reg_u2;
BEGIN;
DECLARE c1 CURSOR FOR SELECT * FROM tenk1;
SELECT rsqname, rsqholders FROM pg_resqueue_status WHERE rsqcostvalue > 0;
DECLARE c2 CURSOR FOR SELECT * FROM tenk1 a NATURAL JOIN tenk1 b;
SELECT rsqname, rsqholders FROM pg_resqueue_status WHERE rsqcostvalue > 0;
CLOSE c1;
CLOSE c2;
END;

-- rsqcostvalue should go back to 0 when queue is empty (MPP-3578)
SELECT rsqname, rsqholders FROM pg_resqueue_status where rsqcostvalue != 0 or rsqcountvalue != 0 or rsqholders != 0;

-- MPP-3796.  When a cursor exceeds the cost limit and the transaction is
-- aborted, resources which had already been granted to other cursors should
-- be released.  Here there are no other concurrent transactions sharing the
-- queue, so rsqcostvalue should go back to 0.
BEGIN;
DECLARE c1 CURSOR FOR SELECT * FROM tenk1;
SELECT rsqname, rsqcostlimit, rsqwaiters, rsqholders FROM pg_resqueue_status WHERE rsqcostvalue > 0;
DECLARE c2 CURSOR FOR SELECT * FROM tenk1;
SELECT rsqname, rsqcostlimit, rsqwaiters, rsqholders FROM pg_resqueue_status WHERE rsqcostvalue > 0;
DECLARE c3 CURSOR FOR SELECT * FROM tenk1 a, tenk1 b;
SELECT rsqname, rsqcostlimit, rsqwaiters, rsqholders FROM pg_resqueue_status WHERE rsqcostvalue > 0;
DECLARE c4 CURSOR FOR SELECT * FROM tenk1 a, tenk1 b, tenk1 c;
SELECT rsqname, rsqcostlimit, rsqwaiters, rsqholders FROM pg_resqueue_status WHERE rsqcostvalue > 0;
END;
SELECT rsqname, rsqholders FROM pg_resqueue_status where rsqcostvalue != 0 or rsqcountvalue != 0 or rsqholders != 0; -- 1 row expected

-- return to the super user
RESET SESSION AUTHORIZATION;

-- reset session to super user. make sure no longer queued
BEGIN;
DECLARE c1 CURSOR FOR SELECT 1 FROM tenk1;
DECLARE c2 CURSOR FOR SELECT 2 FROM tenk1;
DECLARE c3 CURSOR FOR SELECT 3 FROM tenk1; -- should not deadlock, we are SU.
END;

-- cleanup

DROP OWNED BY reg_u1, reg_u2 CASCADE;
DROP USER reg_u1;
DROP USER reg_u2;
DROP RESOURCE QUEUE reg_activeq;
DROP RESOURCE QUEUE reg_costq;


-- Followup additional tests.
-- MPP-7474
CREATE RESOURCE QUEUE rq_test_q ACTIVE THRESHOLD 1;
CREATE USER rq_test_u RESOURCE QUEUE rq_test_q;

create table rq_product (
	pn int not null,
	pname text not null,
	pcolor text,
	primary key (pn)
) distributed by (pn);

-- Products
insert into rq_product values 
  ( 100, 'Sword', 'Black'),
  ( 200, 'Dream', 'Black'),
  ( 300, 'Castle', 'Grey'),
  ( 400, 'Justice', 'Clear'),
  ( 500, 'Donuts', 'Plain'),
  ( 600, 'Donuts', 'Chocolate'),
  ( 700, 'Hamburger', 'Grey'),
  ( 800, 'Fries', 'Grey');

GRANT SELECT ON rq_product TO rq_test_u;

set session authorization rq_test_u;

begin;
declare c0 cursor for select pcolor, pname, pn from rq_product order by 1,2,3;

fetch c0;
fetch c0;
fetch c0;
select * from rq_product;

fetch c0;
abort;

begin;
declare c0 cursor for select pcolor, pname, pn from rq_product order by 1,2,3;

fetch c0;
fetch c0;
fetch c0;
fetch c0;
select * from rq_product;

fetch c0;
abort;

begin;
declare c0 cursor for
select pcolor, pname, pn,
    row_number() over (w) as n,
    lag(pn+0) over (w) as l0,
    lag(pn+1) over (w) as l1,
    lag(pn+2) over (w) as l2,
    lag(pn+3) over (w) as l3,
    lag(pn+4) over (w) as l4,
    lag(pn+5) over (w) as l5,
    lag(pn+6) over (w) as l6,
    lag(pn+7) over (w) as l7,
    lag(pn+8) over (w) as l8,
    lag(pn+9) over (w) as l9,
    lag(pn+10) over (w) as l10,
    lag(pn+11) over (w) as l11,
    lag(pn+12) over (w) as l12,
    lag(pn+13) over (w) as l13,
    lag(pn+14) over (w) as l14,
    lag(pn+15) over (w) as l15,
    lag(pn+16) over (w) as l16,
    lag(pn+17) over (w) as l17,
    lag(pn+18) over (w) as l18,
    lag(pn+19) over (w) as l19,
    lag(pn+20) over (w) as l20,
    lag(pn+21) over (w) as l21,
    lag(pn+22) over (w) as l22,
    lag(pn+23) over (w) as l23,
    lag(pn+24) over (w) as l24,
    lag(pn+25) over (w) as l25,
    lag(pn+26) over (w) as l26,
    lag(pn+27) over (w) as l27,
    lag(pn+28) over (w) as l28,
    lag(pn+29) over (w) as l29,
    lag(pn+30) over (w) as l30,
    lag(pn+31) over (w) as l31,
    lag(pn+32) over (w) as l32
from rq_product
window w as (partition by pcolor order by pname) order by 1,2,3;

fetch c0;
select * from rq_product;

fetch c0;
abort;

begin;
create view window_view as
select pcolor, pname, pn,
    row_number() over (w) as n,
    lag(pn+0) over (w) as l0,
    lag(pn+1) over (w) as l1,
    lag(pn+2) over (w) as l2,
    lag(pn+3) over (w) as l3,
    lag(pn+4) over (w) as l4,
    lag(pn+5) over (w) as l5,
    lag(pn+6) over (w) as l6,
    lag(pn+7) over (w) as l7,
    lag(pn+8) over (w) as l8,
    lag(pn+9) over (w) as l9,
    lag(pn+10) over (w) as l10,
    lag(pn+11) over (w) as l11,
    lag(pn+12) over (w) as l12,
    lag(pn+13) over (w) as l13,
    lag(pn+14) over (w) as l14,
    lag(pn+15) over (w) as l15,
    lag(pn+16) over (w) as l16,
    lag(pn+17) over (w) as l17,
    lag(pn+18) over (w) as l18,
    lag(pn+19) over (w) as l19,
    lag(pn+20) over (w) as l20,
    lag(pn+21) over (w) as l21,
    lag(pn+22) over (w) as l22,
    lag(pn+23) over (w) as l23,
    lag(pn+24) over (w) as l24,
    lag(pn+25) over (w) as l25,
    lag(pn+26) over (w) as l26,
    lag(pn+27) over (w) as l27,
    lag(pn+28) over (w) as l28,
    lag(pn+29) over (w) as l29,
    lag(pn+30) over (w) as l30,
    lag(pn+31) over (w) as l31,
    lag(pn+32) over (w) as l32
from rq_product
window w as (partition by pcolor order by pname);

DECLARE c0 cursor for select * from window_view order by 1,2,3;
fetch c0;
select * from rq_product;

fetch c0;
abort;

RESET SESSION_AUTHORIZATION;

DROP OWNED BY rq_test_u CASCADE;
DROP USER rq_test_u;
DROP RESOURCE QUEUE rq_test_q;
DROP TABLE rq_product;

-- Coverage for resource queue error conditions
CREATE ROLE rq_test_oosm_role;
SET ROLE rq_test_oosm_role;
CREATE TABLE rq_test_oosm_table(i int);
INSERT INTO rq_test_oosm_table VALUES(1);
-- Simulate an out-of-shared-memory condition during the course of grabbing a
-- resource queue lock (in ResLockAcquire()).
SELECT gp_inject_fault('res_increment_add_oosm', 'skip', 1);
-- Queries should error out indicating that we have no shared memory left.
SELECT * FROM rq_test_oosm_table;
SELECT gp_inject_fault('res_increment_add_oosm', 'reset', 1);
-- Queries should succeed now.
SELECT * FROM rq_test_oosm_table;
DROP TABLE rq_test_oosm_table;
RESET ROLE;
DROP ROLE rq_test_oosm_role;
