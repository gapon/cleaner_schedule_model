-- только уборки
-- только Москва
with master_dow_orders as (
	select
		m.id as master_id,
		extract(dow from o.checked_out_at) as dow,
		count(o.id) as dow_orders,
		count(distinct date(o.checked_out_at)) as dow_worked,
		current_date - max(date(o.checked_out_at)) as days_since_last_dow_order -- поменять дату
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
		and o.checked_out_at < current_date -- поменять дату
	group by 1,2
	order by 1,2
), master_all_orders as (
	select
		m.id as master_id,
		min(o.checked_out_at) as first_order_at,
		count(o.id) as all_orders,
		current_date - max(date(o.checked_out_at)) as days_since_last_order -- поменять дату
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
		and o.checked_out_at < current_date -- поменять дату
	group by 1
	order by 1
), manual_cleaner_schedules as (
	select
		cleaner_id as master_id,
		date,
		busy_morning,
		busy_afternoon
	from cleaner_schedules
	where date between current_date and current_date+6
), week_days as (
	select
		d as dow
	from generate_series(0, 6, 1) d
), pivot as (
	select
		ma.master_id,
		wd.dow as dow_key,
		ma.all_orders,
		--md.dow_orders/ma.all_orders::float as dow_orders_prc,
		md.days_since_last_dow_order,
		
		wd.dow,
		md.dow_worked,
		(select count(d) from generate_series(date(ma.first_order_at), current_date, interval '1 day') as d where extract(dow from d) = wd.dow) as total_dow -- поменять дату
			
	from master_all_orders ma
		left join week_days wd on (1 = 1)
		left join master_dow_orders md on (md.master_id = ma.master_id and wd.dow = md.dow)
	where md.dow_orders is not null
		and all_orders > 10
), master_order_dist as (
	select
		m.id as master_id,
		avg(|/(((a1.lat - a2.lat)*111.3)^2 + ((a1.lng - a2.lng)*63)^2)) as avg_dist,
		avg(rooms) as avg_rooms,
		avg(total_time) as avg_time,
		avg(extract(hour from checked_out_at - checked_in_at)) as avg_real_time
	from masters m
		left join performers p on (m.id = p.cleaner_id)
		left join orders o on (p.order_id = o.id)
		left join addresses a1 on (m.user_id = a1.user_id)
		left join addresses a2 on (o.address_id = a2.id)
	where m.region_id = 1 -- msk
		and m.block_reason_id is null
		and m.new_skill !='lead'
		and m.id not in (72192,12438,53705,48852)
		and m.cleaner_type != 'windows' -- только уборки
		and o.workflow_state = 'paid'
		--and o.deal_id is null
		and o.checked_out_at < current_date -- поменять дату
	group by 1
	order by 1
), hr_info as (
	select distinct on (r.master_id)
		r.master_id,
		ra.created_at,
		reason,
		source,
		campaign,
		r.type,
		ra.scheduled_at,
		ra.state,
		ra.user_id,
		masters.region_id
	from recruitment_actions ra
		left outer join recruitments r on (ra.recruitment_id=r.id)
	 	left outer join masters on (r.master_id=masters.id)
	where r.type = 'Recruitment::Lead'
	order by 1,2
)

select 
	p.*,
	dow_worked/total_dow::float as dow_worked_prc,
	extract(year from current_date) - extract(year from birthday) as age,
	m.rating,
	
	
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
	d.avg_dist,
	d.avg_rooms,
	d.avg_time,
	d.avg_real_time,
	
	case
		when m.new_skill = 'newbie' then 1
		else 0
	end as new_flg,
	case
		when m.new_skill = 'specialist' then 1
		else 0
	end as spe_flg,
	case
		when m.new_skill = 'professional' then 1
		else 0
	end as pro_flg,
	
	
	case
		when reason ilike '%crm%' then 1
		else 0
	end as crm_hire,
	case
		when reason ilike '%site%' then 1
		else 0
	end as site_hire,
	
	case
		when source like 'targetmail%' then 1
		else 0
	end as targetmail,
	case
		when source = 'ydirect' then 1
		else 0
	end as ydirect,
	case
		when source = 'cpaexchange' then 1
		else 0
	end as cpaexchange,
	case
		when source = 'mytarget' then 1
		else 0
	end as mytarget,
	case
		when source = 'tradeleads' then 1
		else 0
	end as tradeleads,
	case
		when source ilike 'google' then 1
		else 0
	end as google,
	case
		when source = 'internet' then 1
		else 0
	end as internet,
	case
		when source = 'cityads' then 1
		else 0
	end as cityads,
	case
		when source = 'rabota_i_zarplata' then 1
		else 0
	end as rabota_i_zarplata,
	case
		when source = 'admitad' then 1
		else 0
	end as admitad,
	case
		when source = 'vk_cpc' then 1
		else 0
	end as vk_cpc,
	case
		when source ilike 'yandex' then 1
		else 0
	end as yandex,
	case
		when source = 'rabota_ucheba_service' then 1
		else 0
	end as rabota_ucheba_service,
	case
		when source = 'iz_ruk_v_ruki' then 1
		else 0
	end as iz_ruk_v_ruki,
	case
		when source = 'Hi_brother' then 1
		else 0
	end as hi_brother,
	case
		when source = 'rabota_dlya_vas' then 1
		else 0
	end as rabota_dlya_vas,
	case
		when source = 'actionpay' then 1
		else 0
	end as actionpay,
	case when s.busy_morning then 1 else 0 end as busy_morning,
	case when s.busy_afternoon then 1 else 0 end as busy_afternoon,
	case when s.date is null then 1 else 0 end as no_schedule
from pivot p
	left join masters m on (p.master_id = m.id)
	left join addresses a on (m.user_id = a.user_id)
	left join master_order_dist d on (p.master_id = d.master_id)
	left join hr_info hr on (m.id = hr.master_id)
	left join manual_cleaner_schedules s on (p.master_id = s.master_id and p.dow = extract(dow from s.date));
	