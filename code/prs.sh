#!/bin/bash

cd /home/simon/Documents/import_geodata/ajpes_prs &&


#prenesi PRS iz ajpes spletne strani
wget -O /home/simon/Documents/import_geodata/ajpes_prs/prs.zip https://www.ajpes.si/Doc/Registri/PRS/Ponovna_uporaba/Prs.zip &&

#odzipaj
unzip /home/simon/Documents/import_geodata/ajpes_prs/prs.zip &&

DATABASE_NAME=javni_podatki
DATABASE_SCHEMA=slo_misc
DATABASE_USER=postgres


#ustvari začasno tabelo prs, kamor skopiraš xml
psql -h 127.0.0.1 -p 5432 -U $DATABASE_USER -d $DATABASE_NAME -c "CREATE TABLE IF NOT EXISTS $DATABASE_SCHEMA.prs(prs xml)";
psql -h 127.0.0.1 -p 5432 -U $DATABASE_USER -d $DATABASE_NAME -c "\COPY $DATABASE_SCHEMA.prs(prs) FROM '/home/simon/Documents/import_geodata/ajpes_prs/Prs.xml'";

psql -h 127.0.0.1 -p 5432 -U $DATABASE_USER -d $DATABASE_NAME -c "

DROP TABLE IF EXISTS slo_misc.ajpes_prs_temp;
CREATE TABLE slo_misc.ajpes_prs_temp AS
SELECT  unnest(xpath('//PS/@ma',prs))::text AS ma,
		unnest(xpath('//PS/PopolnoIme/text()',prs))::text AS naziv,
		unnest(xpath('//PS/Oblika/text()',prs))::text AS oblika,
		unnest(xpath('//PS/Organ/text()',prs))::text AS organ,
		unnest(xpath('//PS/N/@po',prs))::text AS po,
		unnest(xpath('//PS/N/@hs',prs))::text AS hs,
		unnest(xpath('//PS/N/@mid',prs))::text AS hs_mid,
		unnest(xpath('//PS/N/UpravnaEnota/text()',prs))::text AS UpravnaEnota,
		unnest(xpath('//PS/N/Regija/text()',prs))::text AS sr_uime,
		unnest(xpath('//PS/N/Obcina/text()',prs))::text AS ob_uime,
		unnest(xpath('//PS/N/Posta/text()',prs))::text AS pt_id,
		unnest(xpath('//PS/N/Naselje/text()',prs))::text AS na_uime,
		unnest(xpath('//PS/N/Ulica/text()',prs))::text AS ul_uime
FROM (SELECT unnest(xpath('//PS',prs)) AS prs FROM 
slo_misc.prs) prs;
CREATE INDEX ON slo_misc.ajpes_prs_temp (hs_mid);

DROP TABLE IF EXISTS slo_misc.ajpes_prs;
CREATE TABLE slo_misc.ajpes_prs AS
SELECT b.ma,
		b.naziv,
		b.oblika,
		b.organ,
		a.na_uime,
		a.pt_id,
		a.naslov,
		b.hs_mid,
		a.geom
FROM
urejeni_podatki.gurs_rpe_hs_naslovi a
join slo_misc.ajpes_prs_temp b ON a.hs_mid=b.hs_mid::int;
CREATE INDEX ON slo_misc.ajpes_prs (hs_mid);
CREATE INDEX ON slo_misc.ajpes_prs (naslov);
CREATE INDEX ON slo_misc.ajpes_prs (geom);
DROP TABLE IF EXISTS slo_misc.ajpes_prs_temp;
DROP TABLE IF EXISTS slo_misc.prs;
"
#delete files
rm -r /home/simon/Documents/import_geodata/ajpes_prs/*
