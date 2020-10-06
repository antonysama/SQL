DROP TABLE IF EXISTS public.table;
CREATE TABLE public.table (id SERIAL, Category varchar(8), Product varchar(50), Sales numeric, Profit numeric, FirstName varchar (20), LastName varchar(20),date DATE, Currency char (3));
COPY public.table FROM '/var/lib/postgresql/data/data/car_parts.csv' WITH CSV HEADER NULL 'NA';
-- AVG profit by category SUM can also be used
SELECT
 Category,
 AVG(Profit)
FROM public.table
GROUP BY Category;