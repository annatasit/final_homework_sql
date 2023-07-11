--1.Выведите название самолетов, которые имеют менее 50 посадочных мест.

select model
from aircrafts a
join seats s on a.aircraft_code = s.aircraft_code
group by  a.aircraft_code
having count(seat_no) < 50

--2.Выведите процентное изменение ежемесячной суммы бронирования билетов, округленной до сотых.

select to_char(date_trunc('month', book_date), 'month') as "month",
	round(
	(
	sum(total_amount) - lag(sum(total_amount), 1, null) over (order by date_trunc('month', book_date))
	)/
	lag(sum(total_amount), 1, null) over (order by date_trunc('month', book_date))
	*100.0, 2)
from bookings b 
group by date_trunc('month', book_date)
order by date_trunc('month', book_date)

--3.Выведите названия самолетов не имеющих бизнес - класс. Решение должно быть через функцию array_agg.

select model
from aircrafts a
join seats s on a.aircraft_code = s.aircraft_code
group by model
having not 'Business' = any(array_agg(fare_conditions))

--4.Найдите процентное соотношение перелетов по маршрутам от общего количества перелетов. 
--Выведите в результат названия аэропортов и процентное отношение.
--Решение должно быть через оконную функцию.

select a.airport_name as departure_name, a1.airport_name as arrival_name, 
	(sum(count(flight_id)) over(partition by a.airport_code, a1.airport_code)/
	sum(count(flight_id)) over())*100.0
from flights f
left join airports a on a.airport_code = departure_airport
left join airports a1 on a1.airport_code = arrival_airport
group by a.airport_code, a1.airport_code

--5.Выведите количество пассажиров по каждому коду сотового оператора, если учесть, 
--что код оператора - это три символа после +7

select count(passenger_id), substring((contact_data->'phone')::text from 4 for 3) as sota
from tickets
group by sota

--6.Классифицируйте финансовые обороты (сумма стоимости билетов) по маршрутам:
--До 50 млн - low
--От 50 млн включительно до 150 млн - middle
--От 150 млн включительно - high
--Выведите в результат количество маршрутов в каждом полученном классе.

select c, count(*)
from (
	select *,
		case  
			when sum < 50000000 then 'low'
			when sum >= 50000000 and sum < 150000000 then 'middle'
			when sum >= 150000000 then 'high'
		end c	
	from (
		select departure_airport, arrival_airport, sum(amount)
		from ticket_flights tf 
		left join flights f on tf.flight_id = f.flight_id
		group by departure_airport, arrival_airport		
	)t1
	)t
group by c
		
--7.Вычислите медиану стоимости билетов, медиану размера бронирования и 
--отношение медианы бронирования к медиане стоимости билетов, округленной до сотых.

select (select percentile_cont(0.5) within group (order by amount) from ticket_flights) as median_ticket,
	(select percentile_cont(0.5) within group (order by total_amount) from bookings) as median_bookings,
	round(((select percentile_cont(0.5) within group (order by total_amount) from bookings) / 
	(select percentile_cont(0.5) within group (order by amount) from ticket_flights))::numeric, 2) as relation

