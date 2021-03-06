DROP TABLE IF EXISTS public.table;
CREATE TABLE public.table (id SERIAL, Category varchar(8), Product varchar(50), Sales numeric, Profit numeric, FirstName varchar (20), LastName varchar(20),date DATE, Currency char (3));
COPY public.table FROM '/var/lib/postgresql/data/data/car_parts.csv' WITH CSV HEADER NULL 'NA';
-- Sum sales by date and category, AVG can also  be used
SELECT
 Date,
 SUM(Sales) FILTER (WHERE Category='VAN') AS "VAN",
 SUM(Sales) FILTER (WHERE Category='SUV') AS "SUV",
 SUM(Sales) FILTER (WHERE Category='COMPACT') AS "COMPACT"
FROM public.table
GROUP BY Date;