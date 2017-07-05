-- только уборки
-- только Москва
with master_dow_orders as (
	select
		m.id as master_id,
		extract(dow from o.checked_out_at) as dow,
		count(o.id) as dow_orders,
		count(distinct date(o.checked_out_at)) as dow_worked,
		'2017-04-24' - max(date(o.checked_out_at)) as days_since_last_dow_order -- поменять дату
	from masters m
		left join performers p on (m.id = p.cleaner_id)
		left join orders o on (p.order_id = o.id)
	where m.region_id = 1 -- msk
		and m.block_reason_id is null
		and m.new_skill !='lead'
		and m.id not in (72192,12438,53705,48852)
		and m.cleaner_type != 'windows' -- только уборки
		and o.workflow_state = 'paid'
		and o.deal_id is null
		and o.checked_out_at < '2017-04-24' -- поменять дату
	group by 1,2
	order by 1,2
), master_all_orders as (
	select
		m.id as master_id,
		min(o.checked_out_at) as first_order_at,
		count(o.id) as all_orders,
		'2017-04-24' - max(date(o.checked_out_at)) as days_since_last_order -- поменять дату
	from masters m
		left join performers p on (m.id = p.cleaner_id)
		left join orders o on (p.order_id = o.id)
	where m.region_id = 1 -- msk
		and m.block_reason_id is null
		and m.new_skill !='lead'
		and m.id not in (72192,12438,53705,48852)
		and m.cleaner_type != 'windows' -- только уборки
		and o.workflow_state = 'paid'
		and o.deal_id is null
		and o.checked_out_at < '2017-04-24' -- поменять дату
	group by 1
	order by 1
), cleanings_next_week as (
	select
		m.id as master_id,
		extract(dow from checked_out_at) as dow,
		1 as worked
	from masters m
		left join performers p on (m.id = p.cleaner_id)
		left join orders o on (p.order_id = o.id)
	where m.region_id = 1 -- msk
		and m.block_reason_id is null
		and m.new_skill !='lead'
		and m.id not in (72192,12438,53705,48852)
		and m.cleaner_type != 'windows' -- только уборки
		and o.workflow_state = 'paid'
		and o.deal_id is null
		and o.checked_out_at >= '2017-04-24' -- поменять дату
		and o.checked_out_at < '2017-05-01' -- поменять дату
	order by 1
), week_days as (
	select
		d as dow
	from generate_series(0, 6, 1) d
), pivot as (
	select
		ma.*,
		--md.dow_orders/ma.all_orders::float as dow_orders_prc,
		md.days_since_last_dow_order,
		
		wd.dow,
		md.dow_worked,
		(select count(d) from generate_series(date(ma.first_order_at), '2017-05-01', interval '1 day') as d where extract(dow from d) = wd.dow) as total_dow, -- поменять дату
			
		case
			when nw.worked is not null then 1
			else 0
		end as worked
	from master_all_orders ma
		left join week_days wd on (1 = 1)
		left join master_dow_orders md on (md.master_id = ma.master_id and wd.dow = md.dow)
		left join cleanings_next_week nw on (md.master_id = nw.master_id and wd.dow = nw.dow)
	where md.dow_orders is not null
		and all_orders > 10
)

select 
	*,
	dow_worked/total_dow::float as dow_worked_prc
from pivot;