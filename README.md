Результат на отложенной выборке
-----------
* Лучший результат на отложенной выборке (модель с информацией о клинере): AUC-ROC = 0.888613453454
* Лучший результат на отложенной выборке (модель с ручными расписаниями): AUC-ROC = 0.823130170457


ToDo
------------
* Как учесть то, что клинер может и хочет работать, но нет заказов?
* Поиграться с гиперпараметрами
** потестить случайный лес / углубить деревья в gb
* Добавить переменныу orders_1d-6d - кол-во заказов за последние N дней
* orders_dow_1w_ago, 2w_ago etc
* флаг выходного/праздничного дня
* погода в данный день
* добавить оконщиков
* Придумать зонирование областей: нанести на карту клинеров
* Разбивка на утренние/вечерние уборки
* Добавить dow_total
** (select count(d) from generate_series(date(ma.first_order_at), (select end_date from constants), interval '1 day') as d where extract(dow from d) = wd.dow) as total_dow



Как использовать?
----------
* Добавить в Распределение заказов


Значимость фичей из старой модели
-------
                    features  importance
29                    new_flg    0.000000
26                    mol_flg    0.000000
27                        msk    0.000000
28                   mytarget    0.000000
42                        spb    0.000000
40                    rus_flg    0.000000
4                    asia_flg    0.000000
1                     admitad    0.000000
19                        ekb    0.000000
47                    ukr_flg    0.000385
15                   crm_hire    0.000393
23              iz_ruk_v_ruki    0.000514
37          rabota_i_zarplata    0.000531
22                   internet    0.000748
46                 tradeleads    0.000864
20                     google    0.001048
48                     vk_cpc    0.001120
56                       dow4    0.001120
44                 targetmail    0.001229
0                   actionpay    0.001325
38      rabota_ucheba_service    0.001498
14                cpaexchange    0.001532
51                    ydirect    0.001639
13                    cityads    0.001864
50                     yandex    0.001960
21                 hi_brother    0.002342
54                       dow2    0.002636
43                    spe_flg    0.002722
10                    blr_flg    0.002737
35                    pro_flg    0.002925
41                  site_hire    0.003532
57                       dow5    0.003588
53                       dow1    0.003596
36            rabota_dlya_vas    0.004523
58                       dow6    0.004528
52                       dow0    0.004894
55                       dow3    0.008216
11             busy_afternoon    0.009288
9            blacklists_count    0.014652
30                no_schedule    0.015417
32                  orders_2w    0.017737
2                         age    0.019846
49           whitelists_count    0.022675
12               busy_morning    0.024324
31                  orders_1w    0.024929
33                  orders_3w    0.025108
34                  orders_4w    0.029248
39                     rating    0.040802
6               avg_real_time    0.044606
7                   avg_rooms    0.045194
8                    avg_time    0.046580
25                        lng    0.048190
24                        lat    0.048541
17                 dow_worked    0.052867
3                  all_orders    0.058155
45                  total_dow    0.066147
5                    avg_dist    0.070015
18             dow_worked_prc    0.101104
16  days_since_last_dow_order    0.110569