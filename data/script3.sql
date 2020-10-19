DROP TABLE IF EXISTS public.table;
CREATE TABLE public.table (Prov char(2), GDP numeric, Year smallint);
COPY public.table FROM '/var/lib/postgresql/data/data/df.csv' WITH CSV HEADER NULL 'NA';
-- Sum GDP by Year and Prov, AVG can also  be used
CREATE VIEW three
AS
SELECT
 Year,
 SUM(GDP) FILTER (WHERE Prov='ON') AS "ON",
 SUM(GDP) FILTER (WHERE Prov='AB') AS "AB"
FROM public.table
GROUP BY Year
ORDER BY Year;