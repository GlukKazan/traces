SET DEFINE OFF;
Insert into AE_POLICY_TYPE
   (ID, NAME, DESCRIPTION)
 Values
   (1, 'default', NULL);
Insert into AE_POLICY_TYPE
   (ID, NAME, DESCRIPTION)
 Values
   (2, 'uptime', NULL);
Insert into AE_POLICY_TYPE
   (ID, NAME, DESCRIPTION)
 Values
   (3, 'threshold', NULL);
COMMIT;

Insert into AE_STATE_POLICY
   (ID, NAME, DESCRIPTION, TYPE_ID)
 Values
   (1, 'default', NULL, 1);
Insert into AE_STATE_POLICY
   (ID, NAME, DESCRIPTION, TYPE_ID)
 Values
   (2, 'uptime', NULL, 2);
COMMIT;

Insert into AE_DOMAIN
   (ID, REGEXP, IS_CASE_SENS, DESCRIPTION, POLICY_ID)
 Values
   (10, '((\d+)\D*,\s*)?(\d+):(\d+):(\d+)(\.\d+)?', 0, 'SNMP uptime', 1);
Insert into AE_DOMAIN
   (ID, REGEXP, IS_CASE_SENS, DESCRIPTION, POLICY_ID)
 Values
   (11, '\d+', 0, 'SNMP число', 1);
Insert into AE_DOMAIN
   (ID, REGEXP, IS_CASE_SENS, DESCRIPTION, POLICY_ID)
 Values
   (12, '([a-fA-F\d])+', 0, 'SNMP строка', 1);
Insert into AE_DOMAIN
   (ID, REGEXP, IS_CASE_SENS, DESCRIPTION, POLICY_ID)
 Values
   (13, '.*', 0, 'SNMP Произвольная строка', 1);
Insert into AE_DOMAIN
   (ID, REGEXP, IS_CASE_SENS, DESCRIPTION, POLICY_ID)
 Values
   (14, '\d+', 0, 'SNMP uptime (числовая форма)', 2);
COMMIT;

Insert into AE_PARAMETER
   (ID, DOMAIN_ID, PARENT_ID, NAME, DESCRIPTION)
 Values
   (101, 14, NULL, 'uptime', 'SNMP Uptime');
Insert into AE_PARAMETER
   (ID, DOMAIN_ID, PARENT_ID, NAME, DESCRIPTION)
 Values
   (102, 11, NULL, 'ifIndex', 'Индекс интерфейса');
Insert into AE_PARAMETER
   (ID, DOMAIN_ID, PARENT_ID, NAME, DESCRIPTION)
 Values
   (103, 13, NULL, 'ifName', 'Имя интерфейса');
Insert into AE_PARAMETER
   (ID, DOMAIN_ID, PARENT_ID, NAME, DESCRIPTION)
 Values
   (104, 11, NULL, 'ifInOctets', 'Входящий трафик');
Insert into AE_PARAMETER
   (ID, DOMAIN_ID, PARENT_ID, NAME, DESCRIPTION)
 Values
   (105, 11, NULL, 'ifOutOctets', 'Исходящий трафик');
COMMIT;

Insert into AE_PLATFORM_MODEL
   (ID, NAME, DESCRIPTION)
 Values
   (1, 'test', NULL);
COMMIT;

Insert into AE_PROFILE_TYPE
   (ID, NAME, DESCRIPTION)
 Values
   (1, 'mon', 'Мониторинг');
COMMIT;

Insert into AE_PROFILE
   (ID, TYPE_ID, IS_DEFAULT, MODEL_ID, SCRIPT_ID, 
    NAME, DESCRIPTION)
 Values
   (1, 1, 1, 1, NULL, 
    'test', NULL);
COMMIT;

Insert into AE_RESOURCE_CLASS
   (ID, IS_LOGICAL, NAME, DESCRIPTION, OWNER_ID)
 Values
   (1, 0, 'Устройство', NULL, NULL);
Insert into AE_RESOURCE_CLASS
   (ID, IS_LOGICAL, NAME, DESCRIPTION, OWNER_ID)
 Values
   (2, 0, 'Интерфейс', NULL, 1);
COMMIT;

Insert into AE_RESOURCE_TYPE
   (ID, CLASS_ID, NAME, DESCRIPTION, OWNER_ID, 
    PARENT_ID)
 Values
   (1, 1, 'Host', NULL, NULL, 
    NULL);
Insert into AE_RESOURCE_TYPE
   (ID, CLASS_ID, NAME, DESCRIPTION, OWNER_ID, 
    PARENT_ID)
 Values
   (2, 2, 'Interface', NULL, 1, 
    NULL);
COMMIT;

Insert into AE_PROFILE_DETAIL
   (ID, TYPE_ID, PROFILE_ID, MODEL_ID, PARAM_ID)
 Values
   (4, 2, 1, 1, 104);
Insert into AE_PROFILE_DETAIL
   (ID, TYPE_ID, PROFILE_ID, MODEL_ID, PARAM_ID)
 Values
   (5, 2, 1, 1, 105);
Insert into AE_PROFILE_DETAIL
   (ID, TYPE_ID, PROFILE_ID, MODEL_ID, PARAM_ID)
 Values
   (6, 1, 1, 1, 1);
Insert into AE_PROFILE_DETAIL
   (ID, TYPE_ID, PROFILE_ID, MODEL_ID, PARAM_ID)
 Values
   (1, 1, 1, 1, 101);
Insert into AE_PROFILE_DETAIL
   (ID, TYPE_ID, PROFILE_ID, MODEL_ID, PARAM_ID)
 Values
   (2, 2, 1, 1, 102);
Insert into AE_PROFILE_DETAIL
   (ID, TYPE_ID, PROFILE_ID, MODEL_ID, PARAM_ID)
 Values
   (3, 2, 1, 1, 103);
COMMIT;

Insert into AE_DEVICE
   (ID, MODEL_ID, START_DATE, END_DATE)
 Values
   (0, 1, TO_DATE('10/30/2013 15:37:16', 'MM/DD/YYYY HH24:MI:SS'), NULL);
COMMIT;

Insert into AE_RESOURCE
   (ID, DEVICE_ID, OWNER_ID, TYPE_ID, NAME, 
    RES_NUM, RES_ID, START_DATE, END_DATE, TMP_ID)
 Values
   (1, 0, NULL, 1, '127.0.0.1', 
    '0', NULL, TO_DATE('10/30/2013 15:24:44', 'MM/DD/YYYY HH24:MI:SS'), NULL, NULL);
COMMIT;

Insert into AE_THRESHOLD_TYPE
   (ID, NAME, DESCRIPTION)
 Values
   (1, 'increase', 'Увеличение');
Insert into AE_THRESHOLD_TYPE
   (ID, NAME, DESCRIPTION)
 Values
   (2, 'decrease', 'Уменьшение');
Insert into AE_THRESHOLD_TYPE
   (ID, NAME, DESCRIPTION)
 Values
   (3, 'delta', 'Приращение');
COMMIT;

Insert into AE_THRESHOLD
   (ID, TYPE_ID, POLICY_ID, VALUE)
 Values
   (1, 3, 1, '100');
COMMIT;

insert into ae_platform_model(id, name)
select ae_platform_model_seq.nextval, rownum
from   all_objects;

insert into ae_device(id, model_id, start_date)
select ae_device_seq.nextval, 1, sysdate
from   all_objects;

commit;
