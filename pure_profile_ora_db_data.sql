REM Simple Script to collect some basic information on database size and content 
REM Author - Danny Higgins

set linesize 200 pagesize 0
set echo off
set heading off
set termout off
set feed off
set verify off

col tacd noprint new_value tacd
col tact noprint new_value tact
col rfs noprint new_value rfs
col uds noprint new_value uds
col ld noprint new_value ld
col comp noprint new_value comp
col enc noprint new_value enc


select to_char(sum(bytes)/1024/1024/1024,'999,999.99') as tacd
from v$datafile;

select to_char(sum(bytes)/1024/1024/1024,'999,999.99') as tact
from v$tempfile;

select to_char(sum(bytes)/1024/1024/1024,'999,999.99') as rfs
from dba_free_space;

select to_char(sum(bytes)/1024/1024/1024,'999,999.99') as uds 
from dba_segments;

select to_char(sum(bytes)/1024/1024/1024,'999,999.99') as ld
from dba_segments
where SEGMENT_TYPE like 'LOB%'; 

select count(*) as comp
from dba_tablespaces t, dba_data_files d
where t.TABLESPACE_NAME=d.TABLESPACE_NAME
and t.DEF_TAB_COMPRESSION like 'ENC%';

select count(*) as enc
from dba_tablespaces t, dba_data_files d
where t.TABLESPACE_NAME=d.TABLESPACE_NAME
and t.ENCRYPTED != 'NO';


set termout on

prompt
prompt SUMMARY Data
prompt ____________
prompt
prompt Total Allocated Datafile Capacity (GB): &tacd
prompt Total Allocated Tempfile Capacity (GB : &tact
prompt Reported Free Space (GB)		     : &rfs
prompt Used Data Segments (GB)		     : &uds
prompt Used LOB Segments (GB)		     : &ld
prompt Number of Compressed Datafiles      : &comp
prompt Number of Encrypted Datafiles 	     : &enc




set feed on 
set heading on 
set verify on
set linesize 200 pagesize 160
set termout on



column SEGMENT_TYPE heading 'Segment Type'
column NAME heading 'Datafile Name' form a90
column SIZE_MB heading 'SIZE_MB' format 99,999.99
column VALUE form a50
column GB format 99,999.99
column Total_Size_GB format 99,999.99

PROMPT
PROMPT
PROMPT DETAILED DATA
PROMPT _____________
PROMPT
PROMPT
PROMPT Total capacity allocated to temp and datafiles
PROMPT ==============================================
PROMPT

select name, bytes/1024/1024/1024 GB
from v$datafile;


column NAME heading 'Tempfile Name' form a90

select name, bytes/1024/1024/1024 GB
from v$tempfile;




PROMPT
PROMPT Reported Free Space
PROMPT ===================
PROMPT

select tablespace_name, sum(bytes/1024/1024/1024) GB
from dba_free_space
group by tablespace_name;




PROMPT
PROMPT Breakdown of Used Data Segments (LOB Data is unlikely to reduce well)
PROMPT =====================================================================
PROMPT

select SEGMENT_TYPE, sum(bytes/1024/1024/1024) GB
from dba_segments
group by SEGMENT_TYPE 
order by 1;



PROMPT
PROMPT Storage Related Parameters
PROMPT ==========================
PROMPT

column NAME heading 'Parameter Name' form a50
column VALUE heading 'VALUE' form a70

select name, value
from v$parameter
where name in ('db_recovery_file_dest', 'db_recovery_file_dest_size', 'db_block_size', 'db_create_file_dest', 'spfile');


PROMPT
PROMPT Control File Locations
PROMPT ======================
PROMPT


select name from v$controlfile;

PROMPT
PROMPT Online Redo Log Locations and Sizes
PROMPT ===================================
PROMPT

column MEMBER heading 'Logfile Name' form a70
column SIZE_MB format 99,999.99

select lf.MEMBER, l.bytes/1024/1024 as SIZE_MB 
from v$logfile lf, v$log l
where lf.GROUP#=l.GROUP#;


PROMPT
PROMPT Check for encryption and compression
PROMPT ====================================
PROMPT

select t.TABLESPACE_NAME, t.DEF_TAB_COMPRESSION, t.ENCRYPTED, t.COMPRESS_FOR, (d.BYTES/1024/1024/1024) GB
from dba_tablespaces t, dba_data_files d
where t.TABLESPACE_NAME=d.TABLESPACE_NAME
order by 1;


PROMPT
PROMPT Backup History
PROMPT ==============
PROMPT

column DURATION_MINS form 9,999.9
column OUTPUT_GB form  999,999
column INPUT_GB form  999,999
column WRITE_SPEED_MB_S form  999,999
column COMPRESSION_RATIO form 99.9

select TO_CHAR(START_TIME, 'DD-MM-YY HH24:MI:SS') AS START_TIME, 
      TO_CHAR(END_TIME, 'DD-MM-YY HH24:MI:SS') AS END_TIME, 
      ELAPSED_SECONDS/60 AS DURATION_MINS, 
      INPUT_BYTES/1024/1024/1024 AS INPUT_GB, 
      OUTPUT_BYTES/1024/1024/1024 AS OUTPUT_GB, 
      OUTPUT_BYTES_PER_SEC/1024/1024 AS WRITE_SPEED_MB_S,
      COMPRESSION_RATIO
from V$RMAN_BACKUP_JOB_DETAILS;
 


PROMPT DataGuard Details
PROMPT ==============================================
PROMPT

set serveroutput on
declare
  feature_boolean number;
  aux_count number;
  feature_info clob;
begin
  dbms_feature_data_guard(feature_boolean, aux_count, feature_info);
  dbms_output.put_line(feature_boolean);
  dbms_output.put_line(feature_info);
end;
/


PROMPT
PROMPT initora Parameters
PROMPT ==================
PROMPT

col NAME form a45
col VALUE form a55
col ISDEFAULT form a10

select NAME, VALUE, ISDEFAULT from v$parameter order by ISDEFAULT, NAME;

