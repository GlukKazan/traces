create or replace type ae_state_rec as object (
  device_id      number,
  profile_id     number,
  param_id       number,
  num            varchar2(300),
  value          varchar2(300)
)
/

show errors;

create or replace type ae_state_tab as table of ae_state_rec;
/

show errors;

create or replace package ae_monitoring as
    procedure    addValue( p_device    in  number
                         , p_profile   in  number
                         , p_param     in  number
                         , p_num       in  varchar2
                         , p_val       in  varchar2 );
    procedure   addValues( p_tab       in  ae_state_tab );                       
    procedure  saveValues;
    procedure  saveValuesDistinct;
    procedure  saveValues( p_tab       in  ae_state_tab );                       
end ae_monitoring;
/

show errors;

create or replace package body ae_monitoring as

    g_ifName_parameter    constant number default 103;
    g_default_policy      constant number default 1;
    g_uptime_policy       constant number default 2;
    g_threshold_policy    constant number default 3;
    g_increase_type       constant number default 1;
    g_decrease_type       constant number default 2;
    g_delta_type          constant number default 3;
    
    procedure addValue( p_device    in  number
                      , p_profile   in  number
                      , p_param     in  number
                      , p_num       in  varchar2
                      , p_val       in  varchar2 ) as
    cursor    c_res(p_type number) is
    select    r.id, r.name
    from      ae_resource r
    where     r.device_id = p_device
    and       r.res_num = p_num
    and       r.type_id = p_type
    and       r.start_date <= sysdate and sysdate <= nvl(r.end_date, sysdate + 1);
    cursor    c_state(p_resid number) is
    select    s.value
    from      ae_state s
    where     s.res_id = p_resid
    and       s.param_id = p_param; 
    l_resid   ae_resource.id%type            default null;
    l_resname ae_resource.name%type          default null;
    l_oldval  ae_state.value%type            default null;   
    l_restype ae_profile_detail.type_id%type default null;
    l_owntype ae_resource_type.owner_id%type default null;
    l_owner   ae_resource.id%type            default null;
    l_policy  ae_state_policy.type_id%type   default null;
    l_polid   ae_state_policy.id%type        default null;
    l_count   number                         default 0;
    begin
    
      -- Получить тип ресурса
      select d.type_id, r.owner_id
      into   l_restype, l_owntype
      from   ae_profile_detail d
      inner  join ae_resource_type r on (r.id = d.type_id)
      where  d.profile_id = p_profile
      and    d.param_id = p_param;
      
      -- Получить ID владельца
      if not l_owntype is null then
         select r.id into l_owner
         from   ae_resource r
         where  r.device_id = p_device
         and    r.type_id = l_owntype;
      end if;
      
      -- Обработать имя интерфейса
      if p_param = g_ifName_parameter then
         open c_res(l_restype);
         fetch c_res into l_resid, l_resname;
         if c_res%notfound or l_resname <> p_val then
         
            -- Закрыть старый ресурс интерфейса
            update ae_resource set end_date = sysdate
            where id = l_resid;
            
            -- Создать новый ресурс интерфейса
            insert into ae_resource(id, device_id, owner_id, type_id, res_num, name)
            values (ae_resource_seq.nextval, p_device, l_owner, l_restype, p_num, p_val);
            
         end if;
         close c_res;
         return;
      end if;
      
      -- Получить ID ресурса
      open c_res(l_restype);
      fetch c_res into l_resid, l_resname;
      if c_res%notfound then
         -- Если ресурс не найден, создать новый ресурс интерфейса
         insert into ae_resource(id, device_id, owner_id, type_id, res_num, name)
         values (ae_resource_seq.nextval, p_device, l_owner, l_restype, p_num, p_val)
         returning id into l_resid;
      end if;
      
      -- Получить старое значение параметра
      open c_state(l_resid);
      fetch c_state into l_oldval;
      if c_state%notfound then
         l_oldval := null;
      end if;
      close c_state;
         
      -- Получить политику сохранения значений
      select l.type_id, l.id
      into   l_policy, l_polid
      from   ae_parameter p
      inner  join ae_domain d on (d.id = p.domain_id)
      inner  join ae_state_policy l on (l.id = d.policy_id)
      where  p.id = p_param;
         
      -- Получить количество пересеченных порогов
      select count(*)
      into   l_count
      from   ae_threshold t
      where  t.policy_id = l_polid
      and (( t.type_id = g_increase_type and l_oldval <= t.value and p_val >= t.value ) or
           ( t.type_id = g_decrease_type and l_oldval >= t.value and p_val <= t.value ) or
           ( t.type_id = g_delta_type and abs(p_val - l_oldval) >= t.value ));
              
      -- Сохранить запись в ae_state_log в соответствии с политикой
      if l_oldval is null or l_count > 0 or
         ( l_policy = g_uptime_policy and p_val < l_oldval) or
         ( l_policy = g_default_policy and p_val <> l_oldval) then
         insert into ae_state_log(id, res_id, param_id, value)
         values (ae_state_log_seq.nextval, l_resid, p_param, decode(l_policy, g_uptime_policy, nvl(l_oldval, p_val), p_val));            
      end if;
      
      -- Обновить ae_state
      update ae_state set value = p_val
                      ,   datetime = current_timestamp
      where  res_id = l_resid and param_id = p_param;
      if sql%rowcount = 0 then
         insert into ae_state(id, param_id, res_id, value)
         values (ae_state_seq.nextval, p_param, l_resid, p_val);                          
      end if;
         
      close c_res;
    exception
      when others then
        if c_res%isopen then close c_res; end if;
        if c_state%isopen then close c_state; end if;
        raise;
    end;
    
    procedure addValues( p_tab in ae_state_tab ) as
    begin
      for i in 1 .. p_tab.count loop
          addValue( p_device  => p_tab(i).device_id
                  , p_profile => p_tab(i).profile_id
                  , p_param   => p_tab(i).param_id
                  , p_num     => p_tab(i).num
                  , p_val     => p_tab(i).value );
      end loop;
      commit write nowait;
    end;
    
    procedure saveValues as
    begin
      
      -- Создать ресурс, если он отсутствует
      merge into ae_resource d
      using ( select t.id, t.device_id, t.num, t.value name, p.type_id, o.id owner_id
              from   ae_state_tmp t
              inner  join ae_profile_detail p on (p.profile_id = t.profile_id and p.param_id = t.param_id)
              inner  join ae_resource_type r on (r.id = p.type_id)
              left   join ae_resource o on (o.device_id = t.device_id and o.type_id = r.owner_id)
              where  t.param_id = g_ifName_parameter
            ) s
      on ( d.device_id = s.device_id and d.res_num = s.num and d.type_id = s.type_id and
           d.start_date <= sysdate and sysdate <= nvl(d.end_date, sysdate + 1) )
      when matched then
        update set d.tmp_id = s.id  
        where  d.name <> s.name
      when not matched then
        insert (id, device_id, owner_id, type_id, res_num, name)
        values (ae_resource_seq.nextval, s.device_id, s.owner_id, s.type_id, s.num, s.name);
        
      -- Добавить недостающие ae_resource
      insert into ae_resource(id, device_id, owner_id, type_id, res_num, name)
      select ae_resource_seq.nextval, t.device_id, o.id, p.type_id, t.num, t.value
      from   ae_state_tmp t
      inner  join ae_resource c on (c.tmp_id = t.id)
      inner  join ae_profile_detail p on (p.profile_id = t.profile_id and p.param_id = t.param_id)
      inner  join ae_resource_type r on (r.id = p.type_id)
      left   join ae_resource o on (o.device_id = t.device_id and o.type_id = r.owner_id);
      
      -- Закрыть устаревшие интерфейсы
      update ae_resource set end_date = sysdate
                         ,   tmp_id   = null
      where  tmp_id > 0;
      
      -- Сохранить записи в ae_state_log
      insert into ae_state_log(id, res_id, param_id, value)
      select ae_state_log_seq.nextval, id, param_id, value
      from ( select distinct r.id, t.param_id, 
                    decode(l.type_id, g_uptime_policy, nvl(s.value, t.value), t.value) value
             from   ae_state_tmp t
             inner  join ae_profile_detail p on (p.profile_id = t.profile_id and p.param_id = t.param_id)
             inner  join ae_resource r on ( r.device_id = t.device_id and r.res_num = t.num and r.type_id = p.type_id and
                                            r.start_date <= sysdate and sysdate <= nvl(r.end_date, sysdate + 1))
             left   join ae_state s on (s.res_id = r.id and s.param_id = t.param_id)
             inner  join ae_parameter a on (a.id = p.param_id)
             inner  join ae_domain d on (d.id = a.domain_id)
             inner  join ae_state_policy l on (l.id = d.policy_id)
             left   join ae_threshold h on (
                    h.policy_id = l.id and
                 (( h.type_id = g_increase_type and s.value <= h.value and t.value >= h.value ) or
                  ( h.type_id = g_decrease_type and s.value >= h.value and t.value <= h.value ) or
                  ( h.type_id = g_delta_type and abs(t.value - s.value) >= h.value )))
             where  ( s.id is null or not h.id is null
             or   ( l.type_id = g_uptime_policy and t.value < s.value )
             or   ( l.type_id = g_default_policy and t.value <> s.value ) )
             and    t.param_id <> g_ifName_parameter );                       
    
      -- Обновить ae_state
      merge into ae_state d
      using ( select t.param_id, t.value, r.id res_id
              from   ae_state_tmp t
              inner  join ae_profile_detail p on (p.profile_id = t.profile_id and p.param_id = t.param_id)
              inner  join ae_resource r on ( r.device_id = t.device_id and r.res_num = t.num and r.type_id = p.type_id and
                                             r.start_date <= sysdate and sysdate <= nvl(r.end_date, sysdate + 1))
              where  t.param_id <> g_ifName_parameter                       
            ) s
      on (d.res_id = s.res_id and d.param_id = s.param_id)
      when matched then
        update set d.value = s.value
               ,   d.datetime = current_timestamp
      when not matched then
        insert (id, param_id, res_id, value)
        values (ae_state_seq.nextval, s.param_id, s.res_id, s.value);
    
      -- Сохранить изменения
      commit write nowait;
    end;
    
    procedure saveValuesDistinct as
    begin
      
      -- Создать ресурс, если он отсутствует
      merge into ae_resource d
      using ( select t.id, t.device_id, t.num, t.value name, p.type_id, o.id owner_id
              from   ( select device_id, profile_id, param_id, num
                       ,      max(id) keep (dense_rank last order by datetime) id 
                       ,      max(value) keep (dense_rank last order by datetime) value
                       ,      max(datetime) datetime 
                       from   ae_state_tmp
                       group  by device_id, profile_id, param_id, num
                     ) t
              inner  join ae_profile_detail p on (p.profile_id = t.profile_id and p.param_id = t.param_id)
              inner  join ae_resource_type r on (r.id = p.type_id)
              left   join ae_resource o on (o.device_id = t.device_id and o.type_id = r.owner_id)
              where  t.param_id = g_ifName_parameter
            ) s
      on ( d.device_id = s.device_id and d.res_num = s.num and d.type_id = s.type_id and
           d.start_date <= sysdate and sysdate <= nvl(d.end_date, sysdate + 1) )
      when matched then
        update set d.tmp_id = s.id  
        where  d.name <> s.name
      when not matched then
        insert (id, device_id, owner_id, type_id, res_num, name)
        values (ae_resource_seq.nextval, s.device_id, s.owner_id, s.type_id, s.num, s.name);
        
      -- Добавить недостающие ae_resource
      insert into ae_resource(id, device_id, owner_id, type_id, res_num, name)
      select ae_resource_seq.nextval, t.device_id, o.id, p.type_id, t.num, t.value
      from   ( select device_id, profile_id, param_id, num
               ,      max(id) keep (dense_rank last order by datetime) id 
               ,      max(value) keep (dense_rank last order by datetime) value
               ,      max(datetime) datetime 
               from   ae_state_tmp
               group  by device_id, profile_id, param_id, num
             ) t
      inner  join ae_resource c on (c.tmp_id = t.id)
      inner  join ae_profile_detail p on (p.profile_id = t.profile_id and p.param_id = t.param_id)
      inner  join ae_resource_type r on (r.id = p.type_id)
      left   join ae_resource o on (o.device_id = t.device_id and o.type_id = r.owner_id);
      
      -- Закрыть устаревшие интерфейсы
      update ae_resource set end_date = sysdate
                         ,   tmp_id   = null
      where  tmp_id > 0;
      
      -- Сохранить записи в ae_state_log
      insert into ae_state_log(id, res_id, param_id, value)
      select ae_state_log_seq.nextval, id, param_id, value
      from ( select distinct r.id, t.param_id, 
                    decode(l.type_id, g_uptime_policy, nvl(s.value, t.value), t.value) value
             from   ( select device_id, profile_id, param_id, num
                      ,      max(id) keep (dense_rank last order by datetime) id 
                      ,      max(value) keep (dense_rank last order by datetime) value
                      ,      max(datetime) datetime 
                      from   ae_state_tmp
                      group  by device_id, profile_id, param_id, num
                    ) t
             inner  join ae_profile_detail p on (p.profile_id = t.profile_id and p.param_id = t.param_id)
             inner  join ae_resource r on ( r.device_id = t.device_id and r.res_num = t.num and r.type_id = p.type_id and
                                            r.start_date <= sysdate and sysdate <= nvl(r.end_date, sysdate + 1))
             left   join ae_state s on (s.res_id = r.id and s.param_id = t.param_id)
             inner  join ae_parameter a on (a.id = p.param_id)
             inner  join ae_domain d on (d.id = a.domain_id)
             inner  join ae_state_policy l on (l.id = d.policy_id)
             left   join ae_threshold h on (
                    h.policy_id = l.id and
                 (( h.type_id = g_increase_type and s.value <= h.value and t.value >= h.value ) or
                  ( h.type_id = g_decrease_type and s.value >= h.value and t.value <= h.value ) or
                  ( h.type_id = g_delta_type and abs(t.value - s.value) >= h.value )))
             where  ( s.id is null or not h.id is null
             or   ( l.type_id = g_uptime_policy and t.value < s.value )
             or   ( l.type_id = g_default_policy and t.value <> s.value ) )
             and    t.param_id <> g_ifName_parameter );                       
    
      -- Обновить ae_state
      merge into ae_state d
      using ( select t.param_id, t.value, r.id res_id
              from   ( select device_id, profile_id, param_id, num
                      ,      max(id) keep (dense_rank last order by datetime) id 
                      ,      max(value) keep (dense_rank last order by datetime) value
                      ,      max(datetime) datetime 
                      from   ae_state_tmp
                      group  by device_id, profile_id, param_id, num
                    ) t
              inner  join ae_profile_detail p on (p.profile_id = t.profile_id and p.param_id = t.param_id)
              inner  join ae_resource r on ( r.device_id = t.device_id and r.res_num = t.num and r.type_id = p.type_id and
                                             r.start_date <= sysdate and sysdate <= nvl(r.end_date, sysdate + 1))
              where  t.param_id <> g_ifName_parameter                       
            ) s
      on (d.res_id = s.res_id and d.param_id = s.param_id)
      when matched then
        update set d.value = s.value
               ,   d.datetime = current_timestamp
      when not matched then
        insert (id, param_id, res_id, value)
        values (ae_state_seq.nextval, s.param_id, s.res_id, s.value);
    
      -- Сохранить изменения
      commit write nowait;
    end;
    
    procedure  saveValues( p_tab in  ae_state_tab ) as
    begin

      -- Создать ресурс, если он отсутствует
      merge into ae_resource d
      using ( select t.device_id, t.num, t.value name, p.type_id, o.id owner_id
              from   ( select device_id, profile_id, param_id, num
                       ,      max(value) value
                       from   table( p_tab )
                       group  by device_id, profile_id, param_id, num
                     ) t
              inner  join ae_profile_detail p on (p.profile_id = t.profile_id and p.param_id = t.param_id)
              inner  join ae_resource_type r on (r.id = p.type_id)
              left   join ae_resource o on (o.device_id = t.device_id and o.type_id = r.owner_id)
              where  t.param_id = g_ifName_parameter
            ) s
      on ( d.device_id = s.device_id and d.res_num = s.num and d.type_id = s.type_id and
           d.start_date <= sysdate and sysdate <= nvl(d.end_date, sysdate + 1) )
      when not matched then
        insert (id, device_id, owner_id, type_id, res_num, name)
        values (ae_resource_seq.nextval, s.device_id, s.owner_id, s.type_id, s.num, s.name);

      -- Сохранить записи в ae_state_log
      insert into ae_state_log(id, res_id, param_id, value)
      select ae_state_log_seq.nextval, id, param_id, value
      from ( select distinct r.id, t.param_id, 
                    decode(l.type_id, g_uptime_policy, nvl(s.value, t.value), t.value) value
             from   ( select device_id, profile_id, param_id, num
                       ,      max(value) value
                       from   table( p_tab )
                       group  by device_id, profile_id, param_id, num
                     ) t
             inner  join ae_profile_detail p on (p.profile_id = t.profile_id and p.param_id = t.param_id)
             inner  join ae_resource r on ( r.device_id = t.device_id and r.res_num = t.num and r.type_id = p.type_id and
                                            r.start_date <= sysdate and sysdate <= nvl(r.end_date, sysdate + 1))
             left   join ae_state s on (s.res_id = r.id and s.param_id = t.param_id)
             inner  join ae_parameter a on (a.id = p.param_id)
             inner  join ae_domain d on (d.id = a.domain_id)
             inner  join ae_state_policy l on (l.id = d.policy_id)
             left   join ae_threshold h on (
                    h.policy_id = l.id and
                 (( h.type_id = g_increase_type and s.value <= h.value and t.value >= h.value ) or
                  ( h.type_id = g_decrease_type and s.value >= h.value and t.value <= h.value ) or
                  ( h.type_id = g_delta_type and abs(t.value - s.value) >= h.value )))
             where  ( s.id is null or not h.id is null
             or   ( l.type_id = g_uptime_policy and t.value < s.value )
             or   ( l.type_id = g_default_policy and t.value <> s.value ) )
             and    t.param_id <> g_ifName_parameter );
                                    
      -- Обновить ae_state
      merge into ae_state d
      using ( select t.param_id, t.value, r.id res_id
              from   ( select device_id, profile_id, param_id, num
                       ,      max(value) value
                       from   table( p_tab )
                       group  by device_id, profile_id, param_id, num
                     ) t
              inner  join ae_profile_detail p on (p.profile_id = t.profile_id and p.param_id = t.param_id)
              inner  join ae_resource r on ( r.device_id = t.device_id and r.res_num = t.num and r.type_id = p.type_id and
                                             r.start_date <= sysdate and sysdate <= nvl(r.end_date, sysdate + 1))
              where  t.param_id <> g_ifName_parameter                       
            ) s
      on (d.res_id = s.res_id and d.param_id = s.param_id)
      when matched then
        update set d.value = s.value
               ,   d.datetime = current_timestamp
      when not matched then
        insert (id, param_id, res_id, value)
        values (ae_state_seq.nextval, s.param_id, s.res_id, s.value);
        
      -- Сохранить изменения
      commit write nowait;
    end;                       

end ae_monitoring;
/

show errors;
