-- только уборки
-- только Москва
with master_dow_orders as (
	select
		m.id as master_id,
		extract(dow from o.checked_out_at) as dow,
		count(o.id) as dow_orders,
		count(distinct date(o.checked_out_at)) as dow_worked,
		'2017-04-17' - max(date(o.checked_out_at)) as days_since_last_dow_order -- поменять дату
	from masters m
		left join performers p on (m.id = p.cleaner_id)
		left join orders o on (p.order_id = o.id)
	where m.region_id = 1 -- msk
		and m.block_reason_id is null
		and m.new_skill !='lead'
		and m.id not in (72192,12438,53705,48852)
		and m.cleaner_type != 'windows' -- только уборки
		and o.workflow_state = 'paid'
		--and o.deal_id is null
		and o.checked_out_at < '2017-04-17' -- поменять дату
	group by 1,2
	order by 1,2
), master_all_orders as (
	select
		m.id as master_id,
		min(o.checked_out_at) as first_order_at,
		count(o.id) as all_orders,
		'2017-04-17' - max(date(o.checked_out_at)) as days_since_last_order -- поменять дату
	from masters m
		left join performers p on (m.id = p.cleaner_id)
		left join orders o on (p.order_id = o.id)
	where m.region_id = 1 -- msk
		and m.block_reason_id is null
		and m.new_skill !='lead'
		and m.id not in (72192,12438,53705,48852)
		and m.cleaner_type != 'windows' -- только уборки
		and o.workflow_state = 'paid'
		--and o.deal_id is null
		and o.checked_out_at < '2017-04-17' -- поменять дату
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
		--and o.deal_id is null
		and o.checked_out_at >= '2017-04-17' -- поменять дату
		and o.checked_out_at < '2017-04-24' -- поменять дату
	order by 1
), week_days as (
	select
		d as dow
	from generate_series(0, 6, 1) d
), pivot as (
	select
		ma.master_id,
		ma.all_orders,
		--md.dow_orders/ma.all_orders::float as dow_orders_prc,
		md.days_since_last_dow_order,
		
		wd.dow,
		md.dow_worked,
		(select count(d) from generate_series(date(ma.first_order_at), '2017-04-24', interval '1 day') as d where extract(dow from d) = wd.dow) as total_dow, -- поменять дату
			
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
	p.*,
	dow_worked/total_dow::float as dow_worked_prc,
	extract(year from current_date) - extract(year from birthday) as age,
	m.rating,
	
	case
		when e.experiment_id is not null then 1
		else 0
	end as exp_flg,
	
	
	whitelists_count,
	blacklists_count,
	
	case
		when citizenship ilike '%рф%' then 1
		when citizenship ilike '%россия%' then 1
		when citizenship ilike '%федерац%' then 1
		when citizenship = 'russia' then 1
		else 0
	end as rus_flg,
	case
		when citizenship ilike '%украи%' then 1
		when citizenship ilike '%ukra%' then 1
		else 0
	end as ukr_flg,
	case
		when citizenship ilike '%бела%' then 1
		when citizenship = 'belarus' then 1
		else 0
	end as blr_flg,
	case
		when citizenship ilike '%молд%' then 1
		when citizenship = 'moldova' then 1
		else 0
	end as mol_flg,
	case
		when citizenship ilike '%узбек%' then 1
		when citizenship = 'kyrgyzia' then 1
		else 0
	end as asia_flg,
	a.lat,
	a.lng
from pivot p
	left join masters m on (p.master_id = m.id)
	left join addresses a on (m.user_id = a.user_id)
	left join cleaner_experiments e on (p.master_id = e.cleaner_id)