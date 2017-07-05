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
	a.lng,
	
	-- sq 1
	case
		when (a.lat >= 52 and a.lat < 53) and (a.lng >= 35 and a.lng < 36) then 1
		else 0
	end as sq_11,
	case
		when (a.lat >= 52 and a.lat < 53) and (a.lng >= 36 and a.lng < 37) then 1
		else 0
	end as sq_12,
	case
		when (a.lat >= 52 and a.lat < 53) and (a.lng >= 37 and a.lng < 38) then 1
		else 0
	end as sq_13,
	case
		when (a.lat >= 52 and a.lat < 53) and (a.lng >= 38 and a.lng < 39) then 1
		else 0
	end as sq_14,
	case
		when (a.lat >= 52 and a.lat < 53) and (a.lng >= 39 and a.lng < 40) then 1
		else 0
	end as sq_15,
	case
		when (a.lat >= 52 and a.lat < 53) and (a.lng >= 40 and a.lng < 41) then 1
		else 0
	end as sq_16,
	case
		when (a.lat >= 52 and a.lat < 53) and (a.lng >= 41 and a.lng < 42) then 1
		else 0
	end as sq_17,
	case
		when (a.lat >= 52 and a.lat < 53) and (a.lng >= 42 and a.lng < 43) then 1
		else 0
	end as sq_18,
	case
		when (a.lat >= 52 and a.lat < 53) and (a.lng >= 43 and a.lng < 44) then 1
		else 0
	end as sq_19,
	
	-- sq2
	case
		when (a.lat >= 53 and a.lat < 54) and (a.lng >= 35 and a.lng < 36) then 1
		else 0
	end as sq_21,
	case
		when (a.lat >= 53 and a.lat < 54) and (a.lng >= 36 and a.lng < 37) then 1
		else 0
	end as sq_22,
	case
		when (a.lat >= 53 and a.lat < 54) and (a.lng >= 37 and a.lng < 38) then 1
		else 0
	end as sq_23,
	case
		when (a.lat >= 53 and a.lat < 54) and (a.lng >= 38 and a.lng < 39) then 1
		else 0
	end as sq_24,
	case
		when (a.lat >= 53 and a.lat < 54) and (a.lng >= 39 and a.lng < 40) then 1
		else 0
	end as sq_25,
	case
		when (a.lat >= 53 and a.lat < 54) and (a.lng >= 40 and a.lng < 41) then 1
		else 0
	end as sq_26,
	case
		when (a.lat >= 53 and a.lat < 54) and (a.lng >= 41 and a.lng < 42) then 1
		else 0
	end as sq_27,
	case
		when (a.lat >= 53 and a.lat < 54) and (a.lng >= 42 and a.lng < 43) then 1
		else 0
	end as sq_28,
	case
		when (a.lat >= 53 and a.lat < 54) and (a.lng >= 43 and a.lng < 44) then 1
		else 0
	end as sq_29,
	
	-- sq3
	case
		when (a.lat >= 54 and a.lat < 55) and (a.lng >= 35 and a.lng < 36) then 1
		else 0
	end as sq_31,
	case
		when (a.lat >= 54 and a.lat < 55) and (a.lng >= 36 and a.lng < 37) then 1
		else 0
	end as sq_32,
	case
		when (a.lat >= 54 and a.lat < 55) and (a.lng >= 37 and a.lng < 38) then 1
		else 0
	end as sq_33,
	case
		when (a.lat >= 54 and a.lat < 55) and (a.lng >= 38 and a.lng < 39) then 1
		else 0
	end as sq_34,
	case
		when (a.lat >= 54 and a.lat < 55) and (a.lng >= 39 and a.lng < 40) then 1
		else 0
	end as sq_35,
	case
		when (a.lat >= 54 and a.lat < 55) and (a.lng >= 40 and a.lng < 41) then 1
		else 0
	end as sq_36,
	case
		when (a.lat >= 54 and a.lat < 55) and (a.lng >= 41 and a.lng < 42) then 1
		else 0
	end as sq_37,
	case
		when (a.lat >= 54 and a.lat < 55) and (a.lng >= 42 and a.lng < 43) then 1
		else 0
	end as sq_38,
	case
		when (a.lat >= 54 and a.lat < 55) and (a.lng >= 43 and a.lng < 44) then 1
		else 0
	end as sq_39,
	
	-- sq4
	case
		when (a.lat >= 55 and a.lat < 56) and (a.lng >= 35 and a.lng < 36) then 1
		else 0
	end as sq_41,
	case
		when (a.lat >= 55 and a.lat < 56) and (a.lng >= 36 and a.lng < 37) then 1
		else 0
	end as sq_42,
	case
		when (a.lat >= 55 and a.lat < 56) and (a.lng >= 37 and a.lng < 38) then 1
		else 0
	end as sq_43,
	case
		when (a.lat >= 55 and a.lat < 56) and (a.lng >= 38 and a.lng < 39) then 1
		else 0
	end as sq_44,
	case
		when (a.lat >= 55 and a.lat < 56) and (a.lng >= 39 and a.lng < 40) then 1
		else 0
	end as sq_45,
	case
		when (a.lat >= 55 and a.lat < 56) and (a.lng >= 40 and a.lng < 41) then 1
		else 0
	end as sq_46,
	case
		when (a.lat >= 55 and a.lat < 56) and (a.lng >= 41 and a.lng < 42) then 1
		else 0
	end as sq_47,
	case
		when (a.lat >= 55 and a.lat < 56) and (a.lng >= 42 and a.lng < 43) then 1
		else 0
	end as sq_48,
	case
		when (a.lat >= 55 and a.lat < 56) and (a.lng >= 43 and a.lng < 44) then 1
		else 0
	end as sq_49,
	
	-- sq5
	case
		when (a.lat >= 56 and a.lat < 57) and (a.lng >= 35 and a.lng < 36) then 1
		else 0
	end as sq_51,
	case
		when (a.lat >= 56 and a.lat < 57) and (a.lng >= 36 and a.lng < 37) then 1
		else 0
	end as sq_52,
	case
		when (a.lat >= 56 and a.lat < 57) and (a.lng >= 37 and a.lng < 38) then 1
		else 0
	end as sq_53,
	case
		when (a.lat >= 56 and a.lat < 57) and (a.lng >= 38 and a.lng < 39) then 1
		else 0
	end as sq_54,
	case
		when (a.lat >= 56 and a.lat < 57) and (a.lng >= 39 and a.lng < 40) then 1
		else 0
	end as sq_55,
	case
		when (a.lat >= 56 and a.lat < 57) and (a.lng >= 40 and a.lng < 41) then 1
		else 0
	end as sq_56,
	case
		when (a.lat >= 56 and a.lat < 57) and (a.lng >= 41 and a.lng < 42) then 1
		else 0
	end as sq_57,
	case
		when (a.lat >= 56 and a.lat < 57) and (a.lng >= 42 and a.lng < 43) then 1
		else 0
	end as sq_58,
	case
		when (a.lat >= 56 and a.lat < 57) and (a.lng >= 43 and a.lng < 44) then 1
		else 0
	end as sq_59
	
from pivot p
	left join masters m on (p.master_id = m.id)
	left join addresses a on (m.user_id = a.user_id)
	left join cleaner_experiments e on (p.master_id = e.cleaner_id);