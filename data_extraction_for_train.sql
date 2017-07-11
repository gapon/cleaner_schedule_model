-- это для train
-- для predict можно выбрать (1) только активных клинеров (2) не оконщиков
drop table if exists master_orders;
create temp table master_orders as 
	select distinct
		p.cleaner_id as master_id,
		o.id as order_id,
		o.start_at,
		extract(dow from o.start_at) as dow
	from orders o
		left join performers p on (o.id = p.order_id)
	where o.deal_id is null -- тут учитываются только уборки
		and workflow_state = 'paid'
		and p.cleaner_id not in (72192,12438,53705,48852);	


with constants as (
	select
		--'2017-04-01'::date as start_date,
		--'2017-06-30'::date as end_date
		'2017-07-01'::date as start_date,
		'2017-07-10'::date as end_date
), dates as (
	select
		date(d) as date
	from generate_series((select start_date from constants),(select end_date from constants), interval '1 day') d
), logs as ( -- Этот механизм работает с 2016-09-14
	select 
		user_id,
		model_id as master_id,
		json_array_elements(object)->>'name' as field,
		json_array_elements(object)->>'object'  as new_value,
		created_at as blocked_at
	from deltas
	where model_type='Master'
), master_blockings as (
	select
		master_id,
		max(blocked_at) as blocked_at
	from logs
	where field='block_reason_id'
		and new_value is not null
	group by 1
), master_first_last_orders as (
	select 
		master_id,
		min(start_at) as first_order_at,
		max(start_at) as last_order_at
	from master_orders
	group by 1
), master_orders_info as (
	select 
		o.*,
		case
			when last_order_at < blocked_at then blocked_at
		end as blocked_at,
		greatest(date(first_order_at), (select start_date from constants)) as period_start_date,
		least((case when last_order_at < blocked_at then date(blocked_at) end), (select end_date from constants)) as period_end_date	
	from master_first_last_orders o
		left join master_blockings b on (o.master_id = b.master_id)
	--where o.master_id in (121794, 152851) -- DEBUG
), observations as (
	select
		master_id,
		date as obs_date
	from master_orders_info m
		left join dates d on (d.date >= m.period_start_date and d.date < m.period_end_date)
), master_dow_orders as (
	select 
		obs.master_id,
		obs.obs_date,
		extract(dow from obs.obs_date) as dow,
		case when o1.master_id is not null then 1 else 0 end as worked,
		count(distinct o2.order_id) as all_orders,
		count(distinct o2.order_id) filter (where date(o2.start_at) >= obs.obs_date - 7) as orders_1w,
		count(distinct o2.order_id) filter (where date(o2.start_at) >= obs.obs_date - 14) as orders_2w,
		count(distinct o2.order_id) filter (where date(o2.start_at) >= obs.obs_date - 21) as orders_3w,
		count(distinct o2.order_id) filter (where date(o2.start_at) >= obs.obs_date - 28) as orders_4w,
		count(distinct o2.order_id) filter (where date(o2.start_at) >= obs.obs_date - 60) as orders_2m,
		count(distinct o2.order_id) filter (where date(o2.start_at) >= obs.obs_date - 90) as orders_3m,
		obs.obs_date - max(date(o2.start_at)) as days_since_last_order, -- null, точно не 0, -999
		count(distinct o2.order_id) filter (where extract(dow from obs.obs_date) = o2.dow) as dow_orders,
		count(distinct date(o2.start_at)) filter (where extract(dow from obs.obs_date) = o2.dow) as dow_worked,
		obs.obs_date - max(date(o2.start_at)) filter (where extract(dow from obs.obs_date) = o2.dow) as days_since_last_dow_order -- null может -999, может и 0 подойдет
		-- это поле кратно 7, поэтому можно на 7 разделить
	from observations obs
		left join master_orders o1 on (obs.master_id = o1.master_id and obs.obs_date = date(o1.start_at))
		left join master_orders o2 on (obs.master_id = o2.master_id and date(o2.start_at) < date(obs.obs_date))
	where obs.obs_date is not null -- хз, как так
	group by 1 ,2, 3, 4
	order by 3, 2
), manual_schedules as (
	select
		cleaner_id as master_id,
		date,
		busy_morning,
		busy_afternoon
	from cleaner_schedules
	where date >= (select start_date from constants) 
		and date < (select end_date from constants)
)

select 
	o.*,
	case when s.busy_morning then 1 else 0 end as busy_morning,
	case when s.busy_afternoon then 1 else 0 end as busy_afternoon,
	case when s.date is null then 1 else 0 end as no_schedule
from master_dow_orders o
	left join manual_schedules s on (o.master_id = s.master_id and o.dow = extract(dow from s.date));