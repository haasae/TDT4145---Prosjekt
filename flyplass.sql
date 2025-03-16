BEGIN TRANSACTION;

-- Oppretting av tabeller

CREATE TABLE IF NOT EXISTS "bagasje" (
	"bagasje_id"	INTEGER,
	"billett_id"	INTEGER NOT NULL,
	"vekt"	DECIMAL(5, 2) NOT NULL,
	"innlevert_tidspunkt"	DATETIME NOT NULL,
	PRIMARY KEY("bagasje_id" AUTOINCREMENT),
	CONSTRAINT "fk_bagasje_billett_id" FOREIGN KEY("billett_id") REFERENCES "billett"("billett_id")
);
CREATE TABLE IF NOT EXISTS "billett" (
	"billett_id"	INTEGER,
	"referansenummer"	INTEGER NOT NULL,
	"flyvning_id"	INTEGER NOT NULL,
	"reise_segment"	varchar(20),
	"billettkategori"	varchar(20) NOT NULL CHECK("billettkategori" IN ('premium', 'økonomi', 'budsjett')),
	"betalt_pris"	INTEGER NOT NULL,
	"flytype_navn"	varchar(100) NOT NULL,
	"radnummer"	INTEGER NOT NULL,
	"setebokstav"	varchar(1) NOT NULL,
	"innsjekk_tidspunkt"	DATETIME,
	PRIMARY KEY("billett_id" AUTOINCREMENT),
	CONSTRAINT "uq_billett_seat_flyvning" UNIQUE("flyvning_id","flytype_navn","radnummer","setebokstav"),
	CONSTRAINT "fk_billett_sete" FOREIGN KEY("flytype_navn","radnummer","setebokstav") REFERENCES "sete"("flytype_navn","radnummer","setebokstav"),
	CONSTRAINT "fk_billett_flyvning" FOREIGN KEY("flyvning_id") REFERENCES "flyvning"("flyvning_id"),
	CONSTRAINT "fk_billett_billettkjop" FOREIGN KEY("referansenummer") REFERENCES "billettkjop"("referansenr")
);
CREATE TABLE IF NOT EXISTS "billettkjop" (
	"referansenummer"	INTEGER,
	"kundenummer"	INTEGER NOT NULL,
	"kjopstidspunkt"	DATETIME NOT NULL,
	"totalpris"	INTEGER NOT NULL,
	PRIMARY KEY("referansenummer"),
	CONSTRAINT "fk_billettkjop_kundenummer" FOREIGN KEY("kundenummer") REFERENCES "kunde"("kundenummer")
);
CREATE TABLE IF NOT EXISTS "flaate" (
	"flyselskap_kode"	varchar(2),
	"flytype_navn"	varchar(255),
	PRIMARY KEY("flyselskap_kode","flytype_navn"),
	CONSTRAINT "fk_flaate_flyselskap_kode" FOREIGN KEY("flyselskap_kode") REFERENCES "flyselskap"("kode"),
	CONSTRAINT "fk_flaate_flytype_navn" FOREIGN KEY("flytype_navn") REFERENCES "flytype"("navn")
);
CREATE TABLE IF NOT EXISTS "fly" (
	"registreringsnummer"	varchar(255),
	"flytype_navn"	varchar(255) NOT NULL,
	"flyselskap_kode"	varchar(2) NOT NULL,
	"produsent_navn"	varchar(255) NOT NULL,
	"serienummer"	INTEGER NOT NULL,
	"kallenavn"	varchar(255),
	"aar_tatt_i_bruk"	INTEGER,
	PRIMARY KEY("registreringsnummer"),
	UNIQUE("serienummer","produsent_navn"),
	CONSTRAINT "fk_fly_flyselskap_kode" FOREIGN KEY("flyselskap_kode") REFERENCES "flyselskap"("kode"),
	CONSTRAINT "fk_fly_fly_navn" FOREIGN KEY("flytype_navn") REFERENCES "flytype"("navn"),
	CONSTRAINT "fk_fly_produsent_navn" FOREIGN KEY("produsent_navn") REFERENCES "produsent"("navn")
);
CREATE TABLE IF NOT EXISTS "flyplass" (
	"kode"	char(3),
	"navn"	varchar(255) NOT NULL,
	PRIMARY KEY("kode"),
	UNIQUE("navn")
);
CREATE TABLE IF NOT EXISTS "flyrute" (
	"rutenummer"	varchar(255),
	"flyselskap_kode"	varchar(2) NOT NULL,
	"flytype_navn"	varchar(255) NOT NULL,
	"ukedager"	varchar(7) NOT NULL,
	"startdato"	DATE NOT NULL,
	"sluttdato"	DATE,
	PRIMARY KEY("rutenummer"),
	CONSTRAINT "fk_flyrute_flyselskap_kode" FOREIGN KEY("flyselskap_kode") REFERENCES "flyselskap"("kode"),
	CONSTRAINT "fk_flyrute_flytype_navn" FOREIGN KEY("flytype_navn") REFERENCES "flytype"("navn")
);
CREATE TABLE IF NOT EXISTS "flyselskap" (
	"kode"	varchar(2),
	"navn"	varchar(255) NOT NULL,
	PRIMARY KEY("kode")
);
CREATE TABLE IF NOT EXISTS "flytype" (
	"navn"	varchar(255),
	"produsent_navn"	varchar(255) NOT NULL,
	"forste_produksjons_aar"	INTEGER,
	"siste_produksjons_aar"	INTEGER,
	PRIMARY KEY("navn"),
	CONSTRAINT "fk_flytype_produsent_navn" FOREIGN KEY("produsent_navn") REFERENCES "produsent"("navn")
);
CREATE TABLE IF NOT EXISTS "flyvning" (
	"flyvning_id"	INTEGER,
	"rutenummer"	varchar(10) NOT NULL,
	"dato"	DATE NOT NULL,
	"status"	varchar(10) NOT NULL CHECK("status" IN ('planned', 'active', 'completed', 'cancelled')),
	"registreringsnummer"	varchar(20) NOT NULL,
	PRIMARY KEY("flyvning_id" AUTOINCREMENT),
	CONSTRAINT "fk_flyvning_registreringsnummer" FOREIGN KEY("registreringsnummer") REFERENCES "fly"("registreringsnummer"),
	CONSTRAINT "fk_flyvning_rutenummer" FOREIGN KEY("rutenummer") REFERENCES "flyrute"("rutenummer")
);
CREATE TABLE IF NOT EXISTS "flyvningetappe" (
	"flyvning_id"	INTEGER,
	"rekkefolge"	INTEGER,
	"faktisk_avgang"	DATETIME NOT NULL,
	"faktisk_ankomst"	DATETIME NOT NULL,
	PRIMARY KEY("flyvning_id","rekkefolge"),
	CONSTRAINT "fk_flyvningetappe_flyvning_id" FOREIGN KEY("flyvning_id") REFERENCES "flyvning"("flyvning_id")
);
CREATE TABLE IF NOT EXISTS "kunde" (
	"kundenummer"	INTEGER,
	"navn"	varchar(255) NOT NULL,
	"telefon"	varchar(255) NOT NULL,
	"epost"	varchar(255) NOT NULL,
	"nasjonalitet"	varchar(255) NOT NULL,
	PRIMARY KEY("kundenummer")
);
CREATE TABLE IF NOT EXISTS "kundefordelsprogram" (
	"kundenummer"	INTEGER,
	"flyselskap_kode"	varchar(2),
	"medlemsnummer"	varchar(50) NOT NULL,
	PRIMARY KEY("kundenummer","flyselskap_kode"),
	CONSTRAINT "fk_kundefordelsprogram_flyselskap_kode" FOREIGN KEY("flyselskap_kode") REFERENCES "flyselskap"("kode"),
	CONSTRAINT "fk_kundefordelsprogram_kundenummer" FOREIGN KEY("kundenummer") REFERENCES "kunde"("kundenummer")
);
CREATE TABLE IF NOT EXISTS "produsent" (
	"navn"	varchar(255),
	"nasjonalitet"	varchar(255) NOT NULL,
	"stiftelsesaar"	INTEGER NOT NULL,
	PRIMARY KEY("navn")
);
CREATE TABLE IF NOT EXISTS "ruteetappe" (
	"rutenummer"	varchar(10),
	"rekkefolge"	INTEGER,
	"fra_flyplasskode"	char(3) NOT NULL,
	"til_flyplasskode"	char(3) NOT NULL,
	"planlagt_avgang"	TIME NOT NULL,
	"planlagt_ankomst"	TIME NOT NULL,
	PRIMARY KEY("rutenummer","rekkefolge"),
	CONSTRAINT "fk_ruteetappe_fra_flyplass" FOREIGN KEY("fra_flyplasskode") REFERENCES "flyplass"("kode"),
	CONSTRAINT "fk_ruteetappe_rutenummer" FOREIGN KEY("rutenummer") REFERENCES "flyrute"("rutenummer"),
	CONSTRAINT "fk_ruteetappe_til_flyplass" FOREIGN KEY("til_flyplasskode") REFERENCES "flyplass"("kode")
);
CREATE TABLE IF NOT EXISTS "rutepris" (
	"rutenummer"	varchar(10),
	"reise"	varchar(20),
	"billettkategori"	varchar(20) CHECK("billettkategori" IN ('premium', 'økonomi', 'budsjett')),
	"gyldig_fra"	DATE,
	"pris"	DECIMAL(10, 2) NOT NULL,
	PRIMARY KEY("rutenummer","reise","billettkategori","gyldig_fra"),
	CONSTRAINT "fk_rutepris_rutenummer" FOREIGN KEY("rutenummer") REFERENCES "flyrute"("rutenummer")
);
CREATE TABLE IF NOT EXISTS "sete" (
	"flytype_navn"	varchar(100),
	"radnummer"	INTEGER,
	"setebokstav"	varchar(1),
	"er_nodutgang"	INTEGER NOT NULL CHECK("er_nodutgang" IN (0, 1)),
	"er_forste_rad"	INTEGER NOT NULL CHECK("er_forste_rad" IN (0, 1)),
	PRIMARY KEY("flytype_navn","radnummer","setebokstav"),
	CONSTRAINT "fk_sete_flytype_navn" FOREIGN KEY("flytype_navn") REFERENCES "flytype"("navn")
);

-- Populering av data

-- Flyplasser (Vedlegg 1)
INSERT INTO "flyplass" (kode, navn) VALUES
('BOO', 'Bodø Lufthavn'),
('BGO', 'Bergen lufthavn, Flesland'),
('OSL', 'Oslo lufthavn, Gardermoen'),
('SVG', 'Stavanger lufthavn, Sola'),
('TRD', 'Trondheim lufthavn, Værnes');

-- Flyselskaper (Vedlegg 2)
INSERT INTO "flyselskap" (kode, navn) VALUES
('DY', 'Norwegian'),
('SK', 'SAS'),
('WF', 'Widerøe');

-- Produsenter
INSERT INTO "produsent" (navn, nasjonalitet, stiftelsesaar) VALUES
('The Boeing Company', 'USA', 1916),
('Airbus Group', 'Europe', 1970),
('De Havilland Canada', 'Canada', 1928);

-- Flytyper (Vedlegg 2)
INSERT INTO "flytype" (navn, produsent_navn, forste_produksjons_aar, siste_produksjons_aar) VALUES
('Boeing 737 800', 'The Boeing Company', 1997, 2020),
('Airbus a320neo', 'Airbus Group', 2016, NULL),
('Dash-8 100', 'De Havilland Canada', 1984, 2005);

-- Flaate (flyselskapenes flytyper)
INSERT INTO "flaate" (flyselskap_kode, flytype_navn) VALUES
('DY', 'Boeing 737 800'),
('SK', 'Airbus a320neo'),
('WF', 'Dash-8 100');

-- Norwegian med Boeing 737 800
INSERT INTO "fly" (registreringsnummer, flytype_navn, flyselskap_kode, produsent_navn, serienummer, kallenavn, aar_tatt_i_bruk) VALUES
('LN-ENU', 'Boeing 737 800', 'DY', 'The Boeing Company', 42069, NULL, 2015),
('LN-ENR', 'Boeing 737 800', 'DY', 'The Boeing Company', 42093, 'Jan Bålsrud', 2018),
('LN-NIQ', 'Boeing 737 800', 'DY', 'The Boeing Company', 39403, 'Max Manus', 2011),
('LN-ENS', 'Boeing 737 800', 'DY', 'The Boeing Company', 42281, NULL, 2017);
-- SAS med Airbus a320neo
INSERT INTO "fly" (registreringsnummer, flytype_navn, flyselskap_kode, produsent_navn, serienummer, kallenavn, aar_tatt_i_bruk) VALUES
('SE-RUB', 'Airbus a320neo', 'SK', 'Airbus Group', 9518, 'Birger Viking', 2020),
('SE-DIR', 'Airbus a320neo', 'SK', 'Airbus Group', 11421, 'Nora Viking', 2023),
('SE-RUP', 'Airbus a320neo', 'SK', 'Airbus Group', 12066, 'Ragnhild Viking', 2024),
('SE-RZE', 'Airbus a320neo', 'SK', 'Airbus Group', 12166, 'Ebbe Viking', 2024);
-- Widerøe med Dash-8 100
INSERT INTO "fly" (registreringsnummer, flytype_navn, flyselskap_kode, produsent_navn, serienummer, kallenavn, aar_tatt_i_bruk) VALUES
('LN-WIH', 'Dash-8 100', 'WF', 'De Havilland Canada', 383, 'Oslo', 1994),
('LN-WIA', 'Dash-8 100', 'WF', 'De Havilland Canada', 359, 'Nordland', 1993),
('LN-WIL', 'Dash-8 100', 'WF', 'De Havilland Canada', 298, 'Narvik', 1995);

-- Flyruter (Vedlegg 3)
-- WF1311: TRD-BOO, 15:15-16:20, ukedager: 12345
INSERT INTO "flyrute" (rutenummer, flyselskap_kode, flytype_navn, ukedager, startdato, sluttdato) VALUES
('WF1311', 'WF', 'Dash-8 100', '12345', '2025-01-01', NULL);
-- WF1302: BOO-TRD, 07:35-08:40, ukedager: 12345
INSERT INTO "flyrute" (rutenummer, flyselskap_kode, flytype_navn, ukedager, startdato, sluttdato) VALUES
('WF1302', 'WF', 'Dash-8 100', '12345', '2025-01-01', NULL);
-- DY753: TRD-OSL, 10:20-11:15, ukedager: 1234567
INSERT INTO "flyrute" (rutenummer, flyselskap_kode, flytype_navn, ukedager, startdato, sluttdato) VALUES
('DY753', 'DY', 'Boeing 737 800', '1234567', '2025-01-01', NULL);
-- SK332: OSL-TRD, 08:00-09:05, ukedager: 1234567
INSERT INTO "flyrute" (rutenummer, flyselskap_kode, flytype_navn, ukedager, startdato, sluttdato) VALUES
('SK332', 'SK', 'Airbus a320neo', '1234567', '2025-01-01', NULL);
-- SK888: TRD-BGO-SVG, ukedager: 12345
INSERT INTO "flyrute" (rutenummer, flyselskap_kode, flytype_navn, ukedager, startdato, sluttdato) VALUES
('SK888', 'SK', 'Airbus a320neo', '12345', '2025-01-01', NULL);

-- Ruteetapper
-- WF1311: En etappe TRD -> BOO, 15:15-16:20
INSERT INTO "ruteetappe" (rutenummer, rekkefolge, fra_flyplasskode, til_flyplasskode, planlagt_avgang, planlagt_ankomst)
VALUES ('WF1311', 1, 'TRD', 'BOO', '15:15', '16:20');
-- WF1302: En etappe BOO -> TRD, 07:35-08:40
INSERT INTO "ruteetappe" (rutenummer, rekkefolge, fra_flyplasskode, til_flyplasskode, planlagt_avgang, planlagt_ankomst)
VALUES ('WF1302', 1, 'BOO', 'TRD', '07:35', '08:40');
-- DY753: En etappe TRD -> OSL, 10:20-11:15
INSERT INTO "ruteetappe" (rutenummer, rekkefolge, fra_flyplasskode, til_flyplasskode, planlagt_avgang, planlagt_ankomst)
VALUES ('DY753', 1, 'TRD', 'OSL', '10:20', '11:15');
-- SK332: En etappe OSL -> TRD, 08:00-09:05
INSERT INTO "ruteetappe" (rutenummer, rekkefolge, fra_flyplasskode, til_flyplasskode, planlagt_avgang, planlagt_ankomst)
VALUES ('SK332', 1, 'OSL', 'TRD', '08:00', '09:05');
-- SK888: Flere etapper
-- Etappe 1: TRD -> BGO, 10:00-11:10
INSERT INTO "ruteetappe" (rutenummer, rekkefolge, fra_flyplasskode, til_flyplasskode, planlagt_avgang, planlagt_ankomst)
VALUES ('SK888', 1, 'TRD', 'BGO', '10:00', '11:10');
-- Etappe 2: BGO -> SVG, 11:40-12:10
INSERT INTO "ruteetappe" (rutenummer, rekkefolge, fra_flyplasskode, til_flyplasskode, planlagt_avgang, planlagt_ankomst)
VALUES ('SK888', 2, 'BGO', 'SVG', '11:40', '12:10');

-- Rutepriser
-- WF1311: TRD-BOO
INSERT INTO "rutepris" (rutenummer, reise, billettkategori, gyldig_fra, pris) VALUES
('WF1311', 'TRD-BOO', 'premium', '2025-01-01', 2018),
('WF1311', 'TRD-BOO', 'økonomi', '2025-01-01', 899),
('WF1311', 'TRD-BOO', 'budsjett', '2025-01-01', 599);
-- WF1302: BOO-TRD
INSERT INTO "rutepris" (rutenummer, reise, billettkategori, gyldig_fra, pris) VALUES
('WF1302', 'BOO-TRD', 'premium', '2025-01-01', 2018),
('WF1302', 'BOO-TRD', 'økonomi', '2025-01-01', 899),
('WF1302', 'BOO-TRD', 'budsjett', '2025-01-01', 599);
-- DY753: TRD-OSL
INSERT INTO "rutepris" (rutenummer, reise, billettkategori, gyldig_fra, pris) VALUES
('DY753', 'TRD-OSL', 'premium', '2025-01-01', 1500),
('DY753', 'TRD-OSL', 'økonomi', '2025-01-01', 1000),
('DY753', 'TRD-OSL', 'budsjett', '2025-01-01', 500);
-- SK332: OSL-TRD
INSERT INTO "rutepris" (rutenummer, reise, billettkategori, gyldig_fra, pris) VALUES
('SK332', 'OSL-TRD', 'premium', '2025-01-01', 1500),
('SK332', 'OSL-TRD', 'økonomi', '2025-01-01', 1000),
('SK332', 'OSL-TRD', 'budsjett', '2025-01-01', 500);
-- SK888:
-- For etappe 1: TRD-BGO
INSERT INTO "rutepris" (rutenummer, reise, billettkategori, gyldig_fra, pris) VALUES
('SK888', 'TRD-BGO', 'premium', '2025-01-01', 2000),
('SK888', 'TRD-BGO', 'økonomi', '2025-01-01', 1500),
('SK888', 'TRD-BGO', 'budsjett', '2025-01-01', 800);
-- For etappe 2: BGO-SVG
INSERT INTO "rutepris" (rutenummer, reise, billettkategori, gyldig_fra, pris) VALUES
('SK888', 'BGO-SVG', 'premium', '2025-01-01', 1000),
('SK888', 'BGO-SVG', 'økonomi', '2025-01-01', 700),
('SK888', 'BGO-SVG', 'budsjett', '2025-01-01', 350);
-- For etappe 3: TRD-SVG
INSERT INTO "rutepris" (rutenummer, reise, billettkategori, gyldig_fra, pris) VALUES
('SK888', 'TRD-SVG', 'premium', '2025-01-01', 2200),
('SK888', 'TRD-SVG', 'økonomi', '2025-01-01', 1700),
('SK888', 'TRD-SVG', 'budsjett', '2025-01-01', 1000);

-- Brukstilfelle 7)
INSERT INTO flyvning (rutenummer, dato, status, registreringsnummer)
VALUES ('WF1302', '2025-04-01', 'planned', 'LN-WIH');

INSERT INTO flyvning (rutenummer, dato, status, registreringsnummer)
VALUES ('DY753', '2025-03-01', 'planned', 'LN-ENU');

INSERT INTO flyvning (rutenummer, dato, status, registreringsnummer)
VALUES ('SK888', '2025-02-01', 'planned', 'SE-RUB');

INSERT INTO kunde (kundenummer, navn, telefon, epost, nasjonalitet)
VALUES (100, 'Ola Nordmann', '12345678', 'ola@example.com', 'Norsk');

-- Velger å ha ett billetkjøp med 10 billetter
INSERT INTO billettkjop (referansenummer, kundenummer, kjopstidspunkt, totalpris)
VALUES (1, 100, '2025-03-01 10:00:00', 5990);

INSERT INTO billett 
  (referansenummer, flyvning_id, reise_segment, billettkategori, betalt_pris, flytype_navn, radnummer, setebokstav, innsjekk_tidspunkt)
VALUES
  (1, 1, 'BOO-TRD', 'økonomi', 599, 'Dash-8 100', 1, 'C', NULL),
  (1, 1, 'BOO-TRD', 'økonomi', 599, 'Dash-8 100', 1, 'D', NULL),
  (1, 1, 'BOO-TRD', 'økonomi', 599, 'Dash-8 100', 2, 'A', NULL),
  (1, 1, 'BOO-TRD', 'økonomi', 599, 'Dash-8 100', 2, 'B', NULL),
  (1, 1, 'BOO-TRD', 'økonomi', 599, 'Dash-8 100', 3, 'A', NULL),
  (1, 1, 'BOO-TRD', 'økonomi', 599, 'Dash-8 100', 3, 'B', NULL),
  (1, 1, 'BOO-TRD', 'økonomi', 599, 'Dash-8 100', 4, 'A', NULL),
  (1, 1, 'BOO-TRD', 'økonomi', 599, 'Dash-8 100', 4, 'B', NULL),
  (1, 1, 'BOO-TRD', 'økonomi', 599, 'Dash-8 100', 5, 'A', NULL),
  (1, 1, 'BOO-TRD', 'økonomi', 599, 'Dash-8 100', 5, 'B', NULL);

-- SETER FOR BOEING 737 800
INSERT INTO sete (flytype_navn, radnummer, setebokstav, er_nodutgang, er_forste_rad)
VALUES
  ('Boeing 737 800', 1, 'A', 0, 1),
  ('Boeing 737 800', 1, 'B', 0, 1),
  ('Boeing 737 800', 1, 'C', 0, 1),
  ('Boeing 737 800', 1, 'D', 0, 1),
  ('Boeing 737 800', 1, 'E', 0, 1),
  ('Boeing 737 800', 1, 'F', 0, 1),
  ('Boeing 737 800', 2, 'A', 0, 0),
  ('Boeing 737 800', 2, 'B', 0, 0),
  ('Boeing 737 800', 2, 'C', 0, 0),
  ('Boeing 737 800', 2, 'D', 0, 0),
  ('Boeing 737 800', 2, 'E', 0, 0),
  ('Boeing 737 800', 2, 'F', 0, 0),
  ('Boeing 737 800', 3, 'A', 0, 0),
  ('Boeing 737 800', 3, 'B', 0, 0),
  ('Boeing 737 800', 3, 'C', 0, 0),
  ('Boeing 737 800', 3, 'D', 0, 0),
  ('Boeing 737 800', 3, 'E', 0, 0),
  ('Boeing 737 800', 3, 'F', 0, 0),
  ('Boeing 737 800', 4, 'A', 0, 0),
  ('Boeing 737 800', 4, 'B', 0, 0),
  ('Boeing 737 800', 4, 'C', 0, 0),
  ('Boeing 737 800', 4, 'D', 0, 0),
  ('Boeing 737 800', 4, 'E', 0, 0),
  ('Boeing 737 800', 4, 'F', 0, 0),
  ('Boeing 737 800', 5, 'A', 0, 0),
  ('Boeing 737 800', 5, 'B', 0, 0),
  ('Boeing 737 800', 5, 'C', 0, 0),
  ('Boeing 737 800', 5, 'D', 0, 0),
  ('Boeing 737 800', 5, 'E', 0, 0),
  ('Boeing 737 800', 5, 'F', 0, 0),
  ('Boeing 737 800', 6, 'A', 0, 0),
  ('Boeing 737 800', 6, 'B', 0, 0),
  ('Boeing 737 800', 6, 'C', 0, 0),
  ('Boeing 737 800', 6, 'D', 0, 0),
  ('Boeing 737 800', 6, 'E', 0, 0),
  ('Boeing 737 800', 6, 'F', 0, 0),
  ('Boeing 737 800', 7, 'A', 0, 0),
  ('Boeing 737 800', 7, 'B', 0, 0),
  ('Boeing 737 800', 7, 'C', 0, 0),
  ('Boeing 737 800', 7, 'D', 0, 0),
  ('Boeing 737 800', 7, 'E', 0, 0),
  ('Boeing 737 800', 7, 'F', 0, 0),
  ('Boeing 737 800', 8, 'A', 0, 0),
  ('Boeing 737 800', 8, 'B', 0, 0),
  ('Boeing 737 800', 8, 'C', 0, 0),
  ('Boeing 737 800', 8, 'D', 0, 0),
  ('Boeing 737 800', 8, 'E', 0, 0),
  ('Boeing 737 800', 8, 'F', 0, 0),
  ('Boeing 737 800', 9, 'A', 0, 0),
  ('Boeing 737 800', 9, 'B', 0, 0),
  ('Boeing 737 800', 9, 'C', 0, 0),
  ('Boeing 737 800', 9, 'D', 0, 0),
  ('Boeing 737 800', 9, 'E', 0, 0),
  ('Boeing 737 800', 9, 'F', 0, 0),
  ('Boeing 737 800', 10, 'A', 0, 0),
  ('Boeing 737 800', 10, 'B', 0, 0),
  ('Boeing 737 800', 10, 'C', 0, 0),
  ('Boeing 737 800', 10, 'D', 0, 0),
  ('Boeing 737 800', 10, 'E', 0, 0),
  ('Boeing 737 800', 10, 'F', 0, 0),
  ('Boeing 737 800', 11, 'A', 0, 0),
  ('Boeing 737 800', 11, 'B', 0, 0),
  ('Boeing 737 800', 11, 'C', 0, 0),
  ('Boeing 737 800', 11, 'D', 0, 0),
  ('Boeing 737 800', 11, 'E', 0, 0),
  ('Boeing 737 800', 11, 'F', 0, 0),
  ('Boeing 737 800', 12, 'A', 0, 0),
  ('Boeing 737 800', 12, 'B', 0, 0),
  ('Boeing 737 800', 12, 'C', 0, 0),
  ('Boeing 737 800', 12, 'D', 0, 0),
  ('Boeing 737 800', 12, 'E', 0, 0),
  ('Boeing 737 800', 12, 'F', 0, 0),
  ('Boeing 737 800', 13, 'A', 1, 0),
  ('Boeing 737 800', 13, 'B', 1, 0),
  ('Boeing 737 800', 13, 'C', 1, 0),
  ('Boeing 737 800', 13, 'D', 1, 0),
  ('Boeing 737 800', 13, 'E', 1, 0),
  ('Boeing 737 800', 13, 'F', 1, 0),
  ('Boeing 737 800', 14, 'A', 0, 0),
  ('Boeing 737 800', 14, 'B', 0, 0),
  ('Boeing 737 800', 14, 'C', 0, 0),
  ('Boeing 737 800', 14, 'D', 0, 0),
  ('Boeing 737 800', 14, 'E', 0, 0),
  ('Boeing 737 800', 14, 'F', 0, 0),
  ('Boeing 737 800', 15, 'A', 0, 0),
  ('Boeing 737 800', 15, 'B', 0, 0),
  ('Boeing 737 800', 15, 'C', 0, 0),
  ('Boeing 737 800', 15, 'D', 0, 0),
  ('Boeing 737 800', 15, 'E', 0, 0),
  ('Boeing 737 800', 15, 'F', 0, 0),
  ('Boeing 737 800', 16, 'A', 0, 0),
  ('Boeing 737 800', 16, 'B', 0, 0),
  ('Boeing 737 800', 16, 'C', 0, 0),
  ('Boeing 737 800', 16, 'D', 0, 0),
  ('Boeing 737 800', 16, 'E', 0, 0),
  ('Boeing 737 800', 16, 'F', 0, 0),
  ('Boeing 737 800', 17, 'A', 0, 0),
  ('Boeing 737 800', 17, 'B', 0, 0),
  ('Boeing 737 800', 17, 'C', 0, 0),
  ('Boeing 737 800', 17, 'D', 0, 0),
  ('Boeing 737 800', 17, 'E', 0, 0),
  ('Boeing 737 800', 17, 'F', 0, 0),
  ('Boeing 737 800', 18, 'A', 0, 0),
  ('Boeing 737 800', 18, 'B', 0, 0),
  ('Boeing 737 800', 18, 'C', 0, 0),
  ('Boeing 737 800', 18, 'D', 0, 0),
  ('Boeing 737 800', 18, 'E', 0, 0),
  ('Boeing 737 800', 18, 'F', 0, 0),
  ('Boeing 737 800', 19, 'A', 0, 0),
  ('Boeing 737 800', 19, 'B', 0, 0),
  ('Boeing 737 800', 19, 'C', 0, 0),
  ('Boeing 737 800', 19, 'D', 0, 0),
  ('Boeing 737 800', 19, 'E', 0, 0),
  ('Boeing 737 800', 19, 'F', 0, 0),
  ('Boeing 737 800', 20, 'A', 0, 0),
  ('Boeing 737 800', 20, 'B', 0, 0),
  ('Boeing 737 800', 20, 'C', 0, 0),
  ('Boeing 737 800', 20, 'D', 0, 0),
  ('Boeing 737 800', 20, 'E', 0, 0),
  ('Boeing 737 800', 20, 'F', 0, 0),
  ('Boeing 737 800', 21, 'A', 0, 0),
  ('Boeing 737 800', 21, 'B', 0, 0),
  ('Boeing 737 800', 21, 'C', 0, 0),
  ('Boeing 737 800', 21, 'D', 0, 0),
  ('Boeing 737 800', 21, 'E', 0, 0),
  ('Boeing 737 800', 21, 'F', 0, 0),
  ('Boeing 737 800', 22, 'A', 0, 0),
  ('Boeing 737 800', 22, 'B', 0, 0),
  ('Boeing 737 800', 22, 'C', 0, 0),
  ('Boeing 737 800', 22, 'D', 0, 0),
  ('Boeing 737 800', 22, 'E', 0, 0),
  ('Boeing 737 800', 22, 'F', 0, 0),
  ('Boeing 737 800', 23, 'A', 0, 0),
  ('Boeing 737 800', 23, 'B', 0, 0),
  ('Boeing 737 800', 23, 'C', 0, 0),
  ('Boeing 737 800', 23, 'D', 0, 0),
  ('Boeing 737 800', 23, 'E', 0, 0),
  ('Boeing 737 800', 23, 'F', 0, 0),
  ('Boeing 737 800', 24, 'A', 0, 0),
  ('Boeing 737 800', 24, 'B', 0, 0),
  ('Boeing 737 800', 24, 'C', 0, 0),
  ('Boeing 737 800', 24, 'D', 0, 0),
  ('Boeing 737 800', 24, 'E', 0, 0),
  ('Boeing 737 800', 24, 'F', 0, 0),
  ('Boeing 737 800', 25, 'A', 0, 0),
  ('Boeing 737 800', 25, 'B', 0, 0),
  ('Boeing 737 800', 25, 'C', 0, 0),
  ('Boeing 737 800', 25, 'D', 0, 0),
  ('Boeing 737 800', 25, 'E', 0, 0),
  ('Boeing 737 800', 25, 'F', 0, 0),
  ('Boeing 737 800', 26, 'A', 0, 0),
  ('Boeing 737 800', 26, 'B', 0, 0),
  ('Boeing 737 800', 26, 'C', 0, 0),
  ('Boeing 737 800', 26, 'D', 0, 0),
  ('Boeing 737 800', 26, 'E', 0, 0),
  ('Boeing 737 800', 26, 'F', 0, 0),
  ('Boeing 737 800', 27, 'A', 0, 0),
  ('Boeing 737 800', 27, 'B', 0, 0),
  ('Boeing 737 800', 27, 'C', 0, 0),
  ('Boeing 737 800', 27, 'D', 0, 0),
  ('Boeing 737 800', 27, 'E', 0, 0),
  ('Boeing 737 800', 27, 'F', 0, 0),
  ('Boeing 737 800', 28, 'A', 0, 0),
  ('Boeing 737 800', 28, 'B', 0, 0),
  ('Boeing 737 800', 28, 'C', 0, 0),
  ('Boeing 737 800', 28, 'D', 0, 0),
  ('Boeing 737 800', 28, 'E', 0, 0),
  ('Boeing 737 800', 28, 'F', 0, 0),
  ('Boeing 737 800', 29, 'A', 0, 0),
  ('Boeing 737 800', 29, 'B', 0, 0),
  ('Boeing 737 800', 29, 'C', 0, 0),
  ('Boeing 737 800', 29, 'D', 0, 0),
  ('Boeing 737 800', 29, 'E', 0, 0),
  ('Boeing 737 800', 29, 'F', 0, 0),
  ('Boeing 737 800', 30, 'A', 0, 0),
  ('Boeing 737 800', 30, 'B', 0, 0),
  ('Boeing 737 800', 30, 'C', 0, 0),
  ('Boeing 737 800', 30, 'D', 0, 0),
  ('Boeing 737 800', 30, 'E', 0, 0),
  ('Boeing 737 800', 30, 'F', 0, 0),
  ('Boeing 737 800', 31, 'A', 0, 0),
  ('Boeing 737 800', 31, 'B', 0, 0),
  ('Boeing 737 800', 31, 'C', 0, 0),
  ('Boeing 737 800', 31, 'D', 0, 0),
  ('Boeing 737 800', 31, 'E', 0, 0),
  ('Boeing 737 800', 31, 'F', 0, 0);

-- SETER FOR AIRBUS a320neo
INSERT INTO sete (flytype_navn, radnummer, setebokstav, er_nodutgang, er_forste_rad)
VALUES
  ('Airbus a320neo', 1, 'A', 0, 1),
  ('Airbus a320neo', 1, 'B', 0, 1),
  ('Airbus a320neo', 1, 'C', 0, 1),
  ('Airbus a320neo', 1, 'D', 0, 1),
  ('Airbus a320neo', 1, 'E', 0, 1),
  ('Airbus a320neo', 1, 'F', 0, 1),
  ('Airbus a320neo', 2, 'A', 0, 0),
  ('Airbus a320neo', 2, 'B', 0, 0),
  ('Airbus a320neo', 2, 'C', 0, 0),
  ('Airbus a320neo', 2, 'D', 0, 0),
  ('Airbus a320neo', 2, 'E', 0, 0),
  ('Airbus a320neo', 2, 'F', 0, 0),
  ('Airbus a320neo', 3, 'A', 0, 0),
  ('Airbus a320neo', 3, 'B', 0, 0),
  ('Airbus a320neo', 3, 'C', 0, 0),
  ('Airbus a320neo', 3, 'D', 0, 0),
  ('Airbus a320neo', 3, 'E', 0, 0),
  ('Airbus a320neo', 3, 'F', 0, 0),
  ('Airbus a320neo', 4, 'A', 0, 0),
  ('Airbus a320neo', 4, 'B', 0, 0),
  ('Airbus a320neo', 4, 'C', 0, 0),
  ('Airbus a320neo', 4, 'D', 0, 0),
  ('Airbus a320neo', 4, 'E', 0, 0),
  ('Airbus a320neo', 4, 'F', 0, 0),
  ('Airbus a320neo', 5, 'A', 0, 0),
  ('Airbus a320neo', 5, 'B', 0, 0),
  ('Airbus a320neo', 5, 'C', 0, 0),
  ('Airbus a320neo', 5, 'D', 0, 0),
  ('Airbus a320neo', 5, 'E', 0, 0),
  ('Airbus a320neo', 5, 'F', 0, 0),
  ('Airbus a320neo', 6, 'A', 0, 0),
  ('Airbus a320neo', 6, 'B', 0, 0),
  ('Airbus a320neo', 6, 'C', 0, 0),
  ('Airbus a320neo', 6, 'D', 0, 0),
  ('Airbus a320neo', 6, 'E', 0, 0),
  ('Airbus a320neo', 6, 'F', 0, 0),
  ('Airbus a320neo', 7, 'A', 0, 0),
  ('Airbus a320neo', 7, 'B', 0, 0),
  ('Airbus a320neo', 7, 'C', 0, 0),
  ('Airbus a320neo', 7, 'D', 0, 0),
  ('Airbus a320neo', 7, 'E', 0, 0),
  ('Airbus a320neo', 7, 'F', 0, 0),
  ('Airbus a320neo', 8, 'A', 0, 0),
  ('Airbus a320neo', 8, 'B', 0, 0),
  ('Airbus a320neo', 8, 'C', 0, 0),
  ('Airbus a320neo', 8, 'D', 0, 0),
  ('Airbus a320neo', 8, 'E', 0, 0),
  ('Airbus a320neo', 8, 'F', 0, 0),
  ('Airbus a320neo', 9, 'A', 0, 0),
  ('Airbus a320neo', 9, 'B', 0, 0),
  ('Airbus a320neo', 9, 'C', 0, 0),
  ('Airbus a320neo', 9, 'D', 0, 0),
  ('Airbus a320neo', 9, 'E', 0, 0),
  ('Airbus a320neo', 9, 'F', 0, 0),
  ('Airbus a320neo', 10, 'A', 0, 0),
  ('Airbus a320neo', 10, 'B', 0, 0),
  ('Airbus a320neo', 10, 'C', 0, 0),
  ('Airbus a320neo', 10, 'D', 0, 0),
  ('Airbus a320neo', 10, 'E', 0, 0),
  ('Airbus a320neo', 10, 'F', 0, 0),
  ('Airbus a320neo', 11, 'A', 1, 0),
  ('Airbus a320neo', 11, 'B', 1, 0),
  ('Airbus a320neo', 11, 'C', 1, 0),
  ('Airbus a320neo', 11, 'D', 1, 0),
  ('Airbus a320neo', 11, 'E', 1, 0),
  ('Airbus a320neo', 11, 'F', 1, 0),
  ('Airbus a320neo', 12, 'A', 1, 0),
  ('Airbus a320neo', 12, 'B', 1, 0),
  ('Airbus a320neo', 12, 'C', 1, 0),
  ('Airbus a320neo', 12, 'D', 1, 0),
  ('Airbus a320neo', 12, 'E', 1, 0),
  ('Airbus a320neo', 12, 'F', 1, 0),
  ('Airbus a320neo', 13, 'A', 0, 0),
  ('Airbus a320neo', 13, 'B', 0, 0),
  ('Airbus a320neo', 13, 'C', 0, 0),
  ('Airbus a320neo', 13, 'D', 0, 0),
  ('Airbus a320neo', 13, 'E', 0, 0),
  ('Airbus a320neo', 13, 'F', 0, 0),
  ('Airbus a320neo', 14, 'A', 0, 0),
  ('Airbus a320neo', 14, 'B', 0, 0),
  ('Airbus a320neo', 14, 'C', 0, 0),
  ('Airbus a320neo', 14, 'D', 0, 0),
  ('Airbus a320neo', 14, 'E', 0, 0),
  ('Airbus a320neo', 14, 'F', 0, 0),
  ('Airbus a320neo', 15, 'A', 0, 0),
  ('Airbus a320neo', 15, 'B', 0, 0),
  ('Airbus a320neo', 15, 'C', 0, 0),
  ('Airbus a320neo', 15, 'D', 0, 0),
  ('Airbus a320neo', 15, 'E', 0, 0),
  ('Airbus a320neo', 15, 'F', 0, 0),
  ('Airbus a320neo', 16, 'A', 0, 0),
  ('Airbus a320neo', 16, 'B', 0, 0),
  ('Airbus a320neo', 16, 'C', 0, 0),
  ('Airbus a320neo', 16, 'D', 0, 0),
  ('Airbus a320neo', 16, 'E', 0, 0),
  ('Airbus a320neo', 16, 'F', 0, 0),
  ('Airbus a320neo', 17, 'A', 0, 0),
  ('Airbus a320neo', 17, 'B', 0, 0),
  ('Airbus a320neo', 17, 'C', 0, 0),
  ('Airbus a320neo', 17, 'D', 0, 0),
  ('Airbus a320neo', 17, 'E', 0, 0),
  ('Airbus a320neo', 17, 'F', 0, 0),
  ('Airbus a320neo', 18, 'A', 0, 0),
  ('Airbus a320neo', 18, 'B', 0, 0),
  ('Airbus a320neo', 18, 'C', 0, 0),
  ('Airbus a320neo', 18, 'D', 0, 0),
  ('Airbus a320neo', 18, 'E', 0, 0),
  ('Airbus a320neo', 18, 'F', 0, 0),
  ('Airbus a320neo', 19, 'A', 0, 0),
  ('Airbus a320neo', 19, 'B', 0, 0),
  ('Airbus a320neo', 19, 'C', 0, 0),
  ('Airbus a320neo', 19, 'D', 0, 0),
  ('Airbus a320neo', 19, 'E', 0, 0),
  ('Airbus a320neo', 19, 'F', 0, 0),
  ('Airbus a320neo', 20, 'A', 0, 0),
  ('Airbus a320neo', 20, 'B', 0, 0),
  ('Airbus a320neo', 20, 'C', 0, 0),
  ('Airbus a320neo', 20, 'D', 0, 0),
  ('Airbus a320neo', 20, 'E', 0, 0),
  ('Airbus a320neo', 20, 'F', 0, 0),
  ('Airbus a320neo', 21, 'A', 0, 0),
  ('Airbus a320neo', 21, 'B', 0, 0),
  ('Airbus a320neo', 21, 'C', 0, 0),
  ('Airbus a320neo', 21, 'D', 0, 0),
  ('Airbus a320neo', 21, 'E', 0, 0),
  ('Airbus a320neo', 21, 'F', 0, 0),
  ('Airbus a320neo', 22, 'A', 0, 0),
  ('Airbus a320neo', 22, 'B', 0, 0),
  ('Airbus a320neo', 22, 'C', 0, 0),
  ('Airbus a320neo', 22, 'D', 0, 0),
  ('Airbus a320neo', 22, 'E', 0, 0),
  ('Airbus a320neo', 22, 'F', 0, 0),
  ('Airbus a320neo', 23, 'A', 0, 0),
  ('Airbus a320neo', 23, 'B', 0, 0),
  ('Airbus a320neo', 23, 'C', 0, 0),
  ('Airbus a320neo', 23, 'D', 0, 0),
  ('Airbus a320neo', 23, 'E', 0, 0),
  ('Airbus a320neo', 23, 'F', 0, 0),
  ('Airbus a320neo', 24, 'A', 0, 0),
  ('Airbus a320neo', 24, 'B', 0, 0),
  ('Airbus a320neo', 24, 'C', 0, 0),
  ('Airbus a320neo', 24, 'D', 0, 0),
  ('Airbus a320neo', 24, 'E', 0, 0),
  ('Airbus a320neo', 24, 'F', 0, 0),
  ('Airbus a320neo', 25, 'A', 0, 0),
  ('Airbus a320neo', 25, 'B', 0, 0),
  ('Airbus a320neo', 25, 'C', 0, 0),
  ('Airbus a320neo', 25, 'D', 0, 0),
  ('Airbus a320neo', 25, 'E', 0, 0),
  ('Airbus a320neo', 25, 'F', 0, 0),
  ('Airbus a320neo', 26, 'A', 0, 0),
  ('Airbus a320neo', 26, 'B', 0, 0),
  ('Airbus a320neo', 26, 'C', 0, 0),
  ('Airbus a320neo', 26, 'D', 0, 0),
  ('Airbus a320neo', 26, 'E', 0, 0),
  ('Airbus a320neo', 26, 'F', 0, 0),
  ('Airbus a320neo', 27, 'A', 0, 0),
  ('Airbus a320neo', 27, 'B', 0, 0),
  ('Airbus a320neo', 27, 'C', 0, 0),
  ('Airbus a320neo', 27, 'D', 0, 0),
  ('Airbus a320neo', 27, 'E', 0, 0),
  ('Airbus a320neo', 27, 'F', 0, 0),
  ('Airbus a320neo', 28, 'A', 0, 0),
  ('Airbus a320neo', 28, 'B', 0, 0),
  ('Airbus a320neo', 28, 'C', 0, 0),
  ('Airbus a320neo', 28, 'D', 0, 0),
  ('Airbus a320neo', 28, 'E', 0, 0),
  ('Airbus a320neo', 28, 'F', 0, 0),
  ('Airbus a320neo', 29, 'A', 0, 0),
  ('Airbus a320neo', 29, 'B', 0, 0),
  ('Airbus a320neo', 29, 'C', 0, 0),
  ('Airbus a320neo', 29, 'D', 0, 0),
  ('Airbus a320neo', 29, 'E', 0, 0),
  ('Airbus a320neo', 29, 'F', 0, 0),
  ('Airbus a320neo', 30, 'A', 0, 0),
  ('Airbus a320neo', 30, 'B', 0, 0),
  ('Airbus a320neo', 30, 'C', 0, 0),
  ('Airbus a320neo', 30, 'D', 0, 0),
  ('Airbus a320neo', 30, 'E', 0, 0),
  ('Airbus a320neo', 30, 'F', 0, 0);

-- SETER FOR DASH-8 100
INSERT INTO sete (flytype_navn, radnummer, setebokstav, er_nodutgang, er_forste_rad)
VALUES
  ('Dash-8 100', 1, 'C', 0, 1),
  ('Dash-8 100', 1, 'D', 0, 1),
  ('Dash-8 100', 2, 'A', 0, 0),
  ('Dash-8 100', 2, 'B', 0, 0),
  ('Dash-8 100', 2, 'C', 0, 0),
  ('Dash-8 100', 2, 'D', 0, 0),
  ('Dash-8 100', 3, 'A', 0, 0),
  ('Dash-8 100', 3, 'B', 0, 0),
  ('Dash-8 100', 3, 'C', 0, 0),
  ('Dash-8 100', 3, 'D', 0, 0),
  ('Dash-8 100', 4, 'A', 0, 0),
  ('Dash-8 100', 4, 'B', 0, 0),
  ('Dash-8 100', 4, 'C', 0, 0),
  ('Dash-8 100', 4, 'D', 0, 0),
  ('Dash-8 100', 5, 'A', 1, 0),
  ('Dash-8 100', 5, 'B', 1, 0),
  ('Dash-8 100', 5, 'C', 1, 0),
  ('Dash-8 100', 5, 'D', 1, 0),
  ('Dash-8 100', 6, 'A', 0, 0),
  ('Dash-8 100', 6, 'B', 0, 0),
  ('Dash-8 100', 6, 'C', 0, 0),
  ('Dash-8 100', 6, 'D', 0, 0),
  ('Dash-8 100', 7, 'A', 0, 0),
  ('Dash-8 100', 7, 'B', 0, 0),
  ('Dash-8 100', 7, 'C', 0, 0),
  ('Dash-8 100', 7, 'D', 0, 0),
  ('Dash-8 100', 8, 'A', 0, 0),
  ('Dash-8 100', 8, 'B', 0, 0),
  ('Dash-8 100', 8, 'C', 0, 0),
  ('Dash-8 100', 8, 'D', 0, 0),
  ('Dash-8 100', 9, 'A', 0, 0),
  ('Dash-8 100', 9, 'B', 0, 0),
  ('Dash-8 100', 9, 'C', 0, 0),
  ('Dash-8 100', 9, 'D', 0, 0),
  ('Dash-8 100', 10, 'A', 0, 0),
  ('Dash-8 100', 10, 'B', 0, 0),
  ('Dash-8 100', 10, 'C', 0, 0),
  ('Dash-8 100', 10, 'D', 0, 0);

COMMIT;
