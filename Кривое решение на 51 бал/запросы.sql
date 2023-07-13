--1. При выборе вида городского общественного транспорта, выводится информация о всех маршрутах этого вида транспорта в порядке возрастания номера маршрута;

SELECT 

tt.title as transport_type,
r.*

FROM transport_in_route tir
inner join transport t on t.id_transport = tir.id_transport_in_route
inner join transport_type tt on tt.id_type  = t.id_type
inner join route r on r.id_route  = tir.id_route 
where lower(tt.title) like lower('%автобус%') 
order by r.number_route DESC

--2. Вывод подробных характеристик маршрутов и типа транспорта, проходящего через выбранную остановку;

select dop.*
from transport_stop ts
inner join route_in_stop ris on ris.id_transport_stop = ts.id_transport_stop

-- Таблица с типами и их маршрутами (задание 1)
inner join(
SELECT 
tt.title as transport_type,
r.*
FROM transport_in_route tir
inner join transport t on t.id_transport = tir.id_transport_in_route
inner join transport_type tt on tt.id_type  = t.id_type
inner join route r on r.id_route  = tir.id_route
) dop ON dop.id_route = ris.id_route

where ts.id_transport_stop = 1

--3. Вывод  информации о расписании движения заданного маршрута транспорта маршрута (время прибытия и отправления, дни следования);
	--Вывод информации о расписании по number_route расписание заполненно только на понедельник, поэтому вывод именно за этот день
	select *
	from timetable t
	where 
	number_route = 737 and
	day = 'Sunday' and
	id_transport_stop = 1

	-- для поиска id остановки по названию можно использовать запрос:
	select *
	from transport_stop ts
	where lower(ts.title) like '%савицко%' 

--4. Вывод полной информации о маршруте (путь следования, остановки);

	--Выводит всю информацию о маршруте по его id. Так же создает два новых поля:
	-- 1. Текстовое с расписанием остановок в виде: остановка 1 - остановка 2 - остановка 3
	-- 2. Генерирует polyline линию по POINT остоновок
	select r.*,string_agg(ts.title ::character varying, ' - ') as line_stop,ST_MakeLine(ts.point) polyline_route
	from route r

	left join (SELECT * FROM public.route_in_stop order by  id_route, number_stop)
	ris ON ris.id_route = r.id_route
	inner join transport_stop ts on ris.id_transport_stop  = ts.id_transport_stop

	where r.id_route = 2

	group by r.id_route;


--5. Вывод  количества маршрутов, проходящих через заданную остановку, и информации о наличии на остановке павильона.
select

ris.id_transport_stop id_transport_stop,
ts.title title_transport_stop, 
case 
	WHEN ts.pavilion then 'Имеет павильон'
	else 'Не имеет павильона'
end is_paviliom,
count(ris.id_route) count_transport_stop

from route_in_stop ris
left join transport_stop ts on ts.id_transport_stop = ris.id_transport_stop
where ts.id_transport_stop = 8  -- или по названию lower(ts.title) like '%Захарьино%'
group by ris.id_transport_stop,ts.id_transport_stop



--6. Вывод информации о выбранном рейсе – остановку, время прибытия и отправления, время движения и пройденную длину от начальной остановки.
	select
	r.number_route,
	r.code_route,
	r.title,
	string_agg(ts.title ::character varying, ' - ') as line_stop,
	ST_Length(ST_MakeLine(ts.point)) as length_route,
	ST_MakeLine(ts.point) polyline_route
	from route r
	left join (SELECT * FROM public.route_in_stop order by  id_route, number_stop)
	ris ON ris.id_route = r.id_route
	inner join transport_stop ts on ris.id_transport_stop  = ts.id_transport_stop
	where r.id_route = 2
	group by r.id_route;


--7. Вывод информации о маршруте (перевозчик и вид транспорта);
select

dop.id_route,
dop.title_carrier,
tt.title transport_type
 
from transport t
inner join(
select 
tir.id_route id_route,
tir.id_transport id_transport,
c.id_carrier,
c.title title_carrier

from transport_in_route tir
left join exit_transport_schedule ets on ets.id_transport_in_route = tir.id_transport_in_route 
left join carrier_staff cs on cs.id_carrier_staff = ets.responsible_carrier_staff_id
left join carrier c  on c.id_carrier = cs.id_carrier

group by tir.id_transport,cs.id_carrier,c.id_carrier,tir.id_route 
) dop on dop.id_transport = t.id_transport
inner join transport_type tt on tt.id_type = t.id_type

--8. Вывод полной информации о маршрутах, принадлежащих выбранному перевозчику;

	-- 4 задание с подзапросом в where из 7 задания
	
	select *
	from (
	select r.*,string_agg(ts.title ::character varying, ' - ') as line_stop,ST_MakeLine(ts.point) polyline_route
	from route r

	left join (SELECT * FROM public.route_in_stop order by  id_route, number_stop)
	ris ON ris.id_route = r.id_route
	inner join transport_stop ts on ris.id_transport_stop  = ts.id_transport_stop
	group by r.id_route
	) dop
	where dop.id_route in
	(select 
	tir.id_route id_route
	
	from transport_in_route tir
	left join exit_transport_schedule ets on ets.id_transport_in_route = tir.id_transport_in_route 
	left join carrier_staff cs on cs.id_carrier_staff = ets.responsible_carrier_staff_id
	left join carrier c  on c.id_carrier = cs.id_carrier
	
	group by tir.id_transport,cs.id_carrier,c.id_carrier,tir.id_route 
	)



--9. Добавление нового пользователя;

	-- В бэкап скорее всего не попадет, поэтому оставлю тут DDL создания ролей
	-- DROP ROLE "admin";

		CREATE ROLE "admin" WITH 
			NOSUPERUSER
			NOCREATEDB
			NOCREATEROLE
			INHERIT
			NOLOGIN
			NOREPLICATION
			NOBYPASSRLS
			CONNECTION LIMIT -1;

		-- DROP ROLE admins2;

		CREATE ROLE admins2 WITH 
			NOSUPERUSER
			NOCREATEDB
			NOCREATEROLE
			INHERIT
			LOGIN
			NOREPLICATION
			NOBYPASSRLS
			CONNECTION LIMIT -1;

		-- DROP ROLE client;

		CREATE ROLE client WITH 
			NOSUPERUSER
			NOCREATEDB
			NOCREATEROLE
			INHERIT
			LOGIN
			NOREPLICATION
			NOBYPASSRLS
			CONNECTION LIMIT -1;

		-- DROP ROLE super_admins;

		CREATE ROLE super_admins WITH 
			SUPERUSER
			NOCREATEDB
			NOCREATEROLE
			INHERIT
			LOGIN
			NOREPLICATION
			NOBYPASSRLS
			CONNECTION LIMIT -1;


	--РОЛИ
	--1. operators - операторы (операторы имеют доступ только к схемы view)
	--2. admin - админы
	--3. SUPERUSER - супер админ (внутреняя роль PostgreSQL)

	--добавить оператора
	create user client WITH  password '123456' 
	IN role operator;
	
	-- добавить админа
	create user admins2 password '123456';
	GRANT admin TO admins2 WITH ADMIN OPTION
	
	-- добавить супер админа
	CREATE USER super_admins WITH SUPERUSER PASSWORD '123456';
	
--10. Изменение статуса пользователей своей группы ;
	-- из под учетки админа только можно )
	grant USER_NAME to GROUP_NAME; 

--11. Создание новой группы пользователей;
	create role ROLE_NAME;

--12. Добавление рейса к заданному маршруту для выбранного перевозчика;

	INSERT INTO public.exit_transport_schedule (id_transport_in_route,start_date_time,responsible_carrier_staff_id)
	VALUES (2,'2022-11-18 10:00:00.000',3);

--13. Вывод маршрутов, которые не вышли в рейс по расписанию, с указанием причины;

		
	select 
	dop.description,
	ets.start_date_time start_date_time,
	r.*
	from exit_transport_schedule ets
	right join
	(
	select id_exit_transport_shedule id_exit_transport_shedule,max(description) description -- На тот случай, если два человека написали комментарий
	from edit_exit_transport_schedule eets
	group by eets.id_exit_transport_shedule 
	) dop on dop.id_exit_transport_shedule = ets.id_exit_transport_shedule

	left join route r on r.id_route = ets.id_transport_in_route
	group by ets.start_date_time,ets.id_transport_in_route,r.id_route,dop.description

--14. Вычислить сколько за месяц совершенно рейсов по определённому маршруту;
	
	select 
	count(id_route),
	dop.mont_number
	
	from transport_in_route tir
	left join 
	(
	select ss.id_transport_in_route,extract(month from ss.date_time) mont_number
	from staff_shedule ss 
	group by ss.id_transport_in_route,extract(month from ss.date_time)

	) dop on dop.id_transport_in_route = tir.id_transport_in_route
	where tir.id_route = 2
	group by tir.id_route,dop.mont_number



--15. Сформировать в отдельную таблицу о рейсах, не вышедших вовремя в рейс, с указанием даты и причины;
	-- Запрос из 13 задания добавлен в представление fail_shedule

	CREATE OR REPLACE VIEW public.fail_shedule
	AS 
	select 
	dop.description,
	ets.start_date_time start_date_time,
	r.*
	from exit_transport_schedule ets
	right join
	(
	select id_exit_transport_shedule id_exit_transport_shedule,max(description) description -- На тот случай, если два человека написали комментарий
	from edit_exit_transport_schedule eets
	group by eets.id_exit_transport_shedule 
	) dop on dop.id_exit_transport_shedule = ets.id_exit_transport_shedule

	left join route r on r.id_route = ets.id_transport_in_route
	group by ets.start_date_time,ets.id_transport_in_route,r.id_route,dop.description;

--16. На определенную дату для всех номеров маршрутов выдать информацию о количестве автобусов, обслуживающих каждый маршрут;

	
	select count(id_transport),dop.mont_number
	from transport_in_route tir
	left join 
	(
	select ss.id_transport_in_route,extract(month from ss.date_time) mont_number
	from staff_shedule ss 
	group by ss.id_transport_in_route,extract(month from ss.date_time)

	) dop on dop.id_transport_in_route = tir.id_transport_in_route

	group by tir.id_transport,dop.mont_number


--17. По итогам работы за месяц посчитать количество смен, отработанных каждым водителем и кондуктором.
	--Кол-во отработаных смен по месяцам для внутренних сотрудников из таблицы staff(водитель,кондуктор,стажер-ученик,охраник,сотрудник службы безопастности) 
	select 
	extract(month from ss.date_time) number_mount,
	count(s.id_staff) count_job_in_mount,
	concat(s.last_name,' ',s.first_name) name_staff,
	s.id_staff id_staff,
	st.title type_staff

	from staff s
	left join staff_shedule ss ON ss.id_staff_shedule = s.id_staff
	left join staff_type st on st.id_type_staff = s.id_type_staff
	group by s.id_staff,st.id_type_staff,extract(month from ss.date_time)


	-- Кол-во отработаных смен для сотрудников перевозчика (по месяцам)
	select 
	extract(month from ets.start_date_time) number_mount,
	count(cs.id_carrier_staff) count_mount,
	concat(cs.last_name,' ',cs.first_name) name_staff,
	cs.id_carrier_staff id_carrier_staff,
	cst.title type_staff_carrier

	from carrier_staff cs
	left join exit_transport_schedule ets on ets.responsible_carrier_staff_id = cs.id_carrier_staff 
	left join carrier_staff_type cst on cst.id_carrier_staff_type = cs.id_carrier_staff_type
	group by cs.id_carrier_staff,extract(month from ets.start_date_time),cst.id_carrier_staff_type
