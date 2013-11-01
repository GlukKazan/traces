create sequence ae_platform_model_seq start with 100;

create table ae_platform_model (
  id             number                              not null,
  name           varchar2(30)                        not null,
  description    varchar2(300)
);

comment on table ae_platform_model is 'Модель оборудования';

create unique index ae_platform_model_pk on ae_platform_model(id);

alter table ae_platform_model add
  constraint pk_ae_platform_model primary key(id);

create sequence ae_device_seq cache 100;

create table ae_device (
  id             number                              not null,
  model_id       number                              not null,
  start_date     date        default sysdate         not null,
  end_date       date        default null  
);

comment on table ae_device is 'Оборудование';

create unique index ae_device_pk on ae_device(id);

create index ae_device_fk on ae_device(device_id);

create index ae_device_model_fk on ae_device(model_id);

create index ae_device_zone_fk on ae_device(zone_id);

alter table ae_device add
  constraint pk_ae_device primary key(id);

alter table ae_device add
  constraint fk_ae_device_model foreign key (model_id) 
    references ae_platform_model(id);

create sequence ae_resource_class_seq start with 100;

create table ae_resource_class (
  id             number                              not null,
  owner_id       number,
  is_logical     number(1)                           not null,
  name           varchar2(30)                        not null,
  description    varchar2(300)
);

comment on table ae_resource_class is 'Класс ресурса';

comment on column ae_resource_class.is_logical is 'Признак логического ресурса';

create unique index ae_resource_class_pk on ae_resource_class(id);

create index ae_resource_class_fk on ae_resource_class(owner_id);

alter table ae_resource_class
  add constraint ae_resource_class_ck check (is_logical in (0, 1));

alter table ae_resource_class add
  constraint pk_ae_resource_class primary key(id);

create sequence ae_resource_type_seq start with 100;

create table ae_resource_type (
  id             number                              not null,
  owner_id       number,
  parent_id      number,
  class_id       number                              not null,
  name           varchar2(30)                        not null,
  description    varchar2(300)
);

comment on table ae_resource_type is 'Тип ресурса';

create unique index ae_resource_type_pk on ae_resource_type(id);

create index ae_resource_type_owner_fk on ae_resource_type(owner_id);

create index ae_resource_type_parent_fk on ae_resource_type(parent_id);

alter table ae_resource_type add
  constraint pk_ae_resource_type primary key(id);

alter table ae_resource_type add
  constraint fk_ae_resource_type foreign key (class_id) 
    references ae_resource_class(id);

alter table ae_resource_type add
  constraint fk_ae_resource_type_owner foreign key (owner_id) 
    references ae_resource_type(id);

alter table ae_resource_type add
  constraint fk_ae_resource_type_parent foreign key (parent_id) 
    references ae_resource_type(id);

create sequence ae_resource_seq cache 100;

create table ae_resource (
  id             number                              not null,
  device_id      number                              not null,
  owner_id       number           default null,            
  type_id        number                              not null,
  name           varchar2(1000)                      not null,
  res_num        varchar2(300)                       not null,
  res_id         number,
  tmp_id         number,
  start_date     date        default sysdate         not null,
  end_date       date        default null  
);

create unique index ae_resource_pk on ae_resource(id);

create index ae_res_dev_fk on ae_resource(device_id);

create index ae_res_dev_type_fk on ae_resource(type_id);

create index ae_res_dev_res_fk on ae_resource(res_id);

create index ae_res_dev_res_tmp_fk on ae_resource(tmp_id);

alter table ae_resource add
  constraint pk_ae_resource primary key(id);

alter table ae_resource add
  constraint fk_ae_res_device foreign key (device_id) 
    references ae_device(id);

alter table ae_resource add
  constraint fk_ae_res_dev_parent foreign key (owner_id) 
    references ae_resource(id);

alter table ae_resource add
  constraint fk_ae_res_dev_type foreign key (type_id) 
    references ae_resource_type(id);

create table ae_policy_type (
  id                 number                           not null,
  name               varchar2(30)                     not null,
  description        varchar2(100)
);

comment on table ae_policy_type is 'Список поддерживаемых платформ';

create unique index ae_policy_type_pk on ae_policy_type(id);

create unique index ae_policy_type_uk on ae_policy_type(name);

alter table ae_policy_type add
  constraint pk_ae_policy_type primary key(id);

create table ae_state_policy (
  id                 number                           not null,
  type_id            number                           not null,
  name               varchar2(30)                     not null,
  description        varchar2(100)
);

comment on table ae_state_policy is 'Список поддерживаемых платформ';

create unique index ae_state_policy_pk on ae_state_policy(id);

create index ae_state_policy_fk on ae_state_policy(type_id);

alter table ae_state_policy add
  constraint pk_ae_state_policy primary key(id);

alter table ae_state_policy add
  constraint fk_ae_state_policy foreign key (type_id) 
    references ae_policy_type(id);

create table ae_threshold_type (
  id             number                              not null,
  name           varchar2(30)                        not null,
  description    varchar2(300)
);

create unique index ae_threshold_type_pk on ae_threshold_type(id);

alter table ae_threshold_type add
  constraint pk_ae_threshold_type primary key(id);

create sequence ae_threshold_seq start with 100;

create table ae_threshold (
  id             number                              not null,
  type_id        number                              not null,
  policy_id      number                              not null,
  value          varchar2(100)                       not null
);

create unique index ae_threshold_pk on ae_threshold(id);

create index ae_threshold_direction_fk on ae_threshold(type_id);

create index ae_threshold_profile_fk on ae_threshold(policy_id);

alter table ae_threshold add
  constraint pk_ae_threshold primary key(id);

alter table ae_threshold add
  constraint fk_ae_threshold_type foreign key (type_id) 
    references ae_threshold_type(id);

alter table ae_threshold add
  constraint fk_ae_threshold_policy foreign key (policy_id) 
    references ae_state_policy(id);

create sequence ae_domain_convert_seq start with 100;

create table ae_domain (
  id             number                              not null,
  policy_id      number            default null,
  regexp         varchar2(100),
  is_case_sens   number(1)         default 0         not null,
  description    varchar2(100)
);

create unique index ae_domain_pk on ae_domain(id);

create index ae_domain_fk on ae_domain(policy_id);

alter table ae_domain
  add constraint ae_domain_ck check (is_case_sens in (0, 1));

alter table ae_domain add
  constraint pk_ae_domain primary key(id);

alter table ae_domain add
  constraint fk_ae_domain foreign key (policy_id) 
    references ae_state_policy(id);

create sequence ae_parameter_seq start with 1000;

create table ae_parameter (
  id             number                              not null,
  domain_id      number                              not null,
  parent_id      number,
  name           varchar2(30)                        not null,  
  description    varchar2(100)
);

create unique index ae_parameter_pk on ae_parameter(id);

create unique index ae_parameter_uk on ae_parameter(name);

create index ae_parameter_domain_fk on ae_parameter(domain_id);

create index ae_parameter_parent_fk on ae_parameter(parent_id);

alter table ae_parameter add
  constraint pk_ae_parameter primary key(id);

alter table ae_parameter add
  constraint fk_ae_parameter_domain foreign key (domain_id) 
    references ae_domain(id);

alter table ae_parameter add
  constraint fk_ae_parameter foreign key (parent_id) 
    references ae_parameter(id);

create sequence ae_state_seq cache 100;

create table ae_state (
  id             number                              not null,
  res_id         number                              not null,
  param_id       number                              not null,
  value          varchar2(300),
  datetime       timestamp default current_timestamp not null
);

comment on table ae_state is 'Состояние параметра';

comment on column ae_state.datetime is 'Дата и время последнего изменения';

create unique index ae_state_pk on ae_state(id);

create index ae_state_res_fk on ae_state(res_id);

create index ae_state_param_fk on ae_state(param_id);

alter table ae_state add
  constraint pk_ae_state primary key(id);

alter table ae_state add
  constraint fk_ae_state_res foreign key (res_id) 
    references ae_resource(id);

alter table ae_state add
  constraint fk_ae_state_param foreign key (param_id) 
    references ae_parameter(id);

create sequence ae_state_log_seq cache 100;

create table ae_state_log (
  id             number                              not null,
  res_id         number                              not null,
  param_id       number                              not null,
  value          varchar2(300),
  datetime       timestamp default current_timestamp not null
) pctfree 0
  partition by range (datetime)
( partition ae_state_log_p1 values less than (maxvalue)
);
  
comment on table ae_state_log is 'Хронология изменения состояния параметра';

create unique index ae_state_log_pk on ae_state_log(datetime, id) local;

alter table ae_state_log add
  constraint pk_ae_state_log primary key(datetime, id);

create sequence ae_profile_type_seq;

create table ae_profile_type (
  id             number                              not null,
  name           varchar2(30)                        not null,
  description    varchar2(100)
);

create unique index ae_profile_type_pk on ae_profile_type(id);

create unique index ae_profile_type_uk on ae_profile_type(name);

alter table ae_profile_type add
  constraint pk_ae_profile_type primary key(id);

create sequence ae_profile_seq;

create table ae_profile (
  id             number                              not null,
  type_id        number                              not null,
  is_default     number(1)         default 0         not null,
  model_id       number                              not null,
  script_id      number            default null,
  name           varchar2(30)                        not null,
  description    varchar2(100)
);

create unique index ae_profile_pk on ae_profile(id);

create index ae_profile_type_fk on ae_profile(type_id);

create index ae_profile_model_fk on ae_profile(model_id);

create index ae_profile_script_fk on ae_profile(script_id);

alter table ae_profile
  add constraint ae_profile_ck check (is_default in (0, 1));

alter table ae_profile add
  constraint pk_ae_profile primary key(id);

alter table ae_profile add
  constraint fk_ae_profile_type foreign key (type_id) 
    references ae_profile_type(id);

create sequence ae_profile_detail_seq;

create table ae_profile_detail (
  id             number                              not null,
  type_id        number                              not null,
  profile_id     number                              not null,
  model_id       number                              not null,
  param_id       number                              not null
);

create unique index ae_profile_detail_pk on ae_profile_detail(id);

create index ae_profile_detail_fk on ae_profile_detail(profile_id);

create index ae_profile_detail_type_fk on ae_profile_detail(type_id);

create index ae_profile_detail_model_fk on ae_profile_detail(model_id);

create index ae_profile_detail_param_fk on ae_profile_detail(param_id);

alter table ae_profile_detail add
  constraint pk_ae_profile_detail primary key(id);

alter table ae_profile_detail add
  constraint fk_ae_profile_detail foreign key (profile_id) 
    references ae_profile(id);

alter table ae_profile_detail add
  constraint fk_ae_profile_detail_type foreign key (type_id) 
    references ae_resource_type(id);

alter table ae_profile_detail add
  constraint fk_ae_profile_detail_model foreign key (model_id) 
    references ae_platform_model(id);

create global temporary table ae_state_tmp (
  id             number                              not null,
  device_id      number                              not null,
  profile_id     number                              not null,
  param_id       number                              not null,
  num            varchar2(300),
  value          varchar2(300),
  datetime       timestamp default current_timestamp not null
) on commit delete rows;

create index ae_state_tmp_ix on ae_state_tmp(device_id, profile_id, param_id, num);
