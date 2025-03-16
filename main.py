import os
import sqlite3

# Init-funksjon: Sjekker om databasen finnes, og oppretter den ved å kjøre SQL-scriptet dersom den ikke gjør det.
    # NB: Dersom du gjør endringer i SQL-koden, må du fjerne den nåværende databasen først for å lage en oppdatert versjon
def init_db(db_path, sql_script_path):
    if not os.path.exists(db_path):
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        with open(sql_script_path, 'r', encoding='utf-8') as f:
            sql_script = f.read()
        cursor.executescript(sql_script)
        conn.commit()
        conn.close()

# Hovedprogrammet
def main():
    db_path = 'flyplass.db'
    sql_script_path = 'flyplass.sql'
    
    # Initialiser databasen dersom den ikke finnes
    init_db(db_path, sql_script_path)

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    flyplasser = get_flyplasser(cursor)
    valgt_flyplass = select_flyplass(flyplasser)
    if valgt_flyplass is None:
        conn.close()
        return

    flyplass_kode = valgt_flyplass[0]
    day_digit, retning = get_user_preferences()

    # Utfør riktig spørring basert på retning
    if retning.lower() == "avganger":
        resultater = query_avganger(cursor, flyplass_kode, day_digit)
    elif retning.lower() == "ankomster":
        resultater = query_ankomster(cursor, flyplass_kode, day_digit)
    else:
        print("Ugyldig valg for retning.")
        conn.close()
        return

    display_results(resultater, retning)
    conn.close()

# Henter flyplasser fra databasen
def get_flyplasser(cursor):
    cursor.execute("SELECT kode, navn FROM flyplass")
    return cursor.fetchall()

# Henter ukedag og retning (avganger/ankomster) fra brukeren, og konverterer ukedag til et siffer (day_digit)
def get_user_preferences():
    ukedag_input = input("Hvilken dag ønsker du å fly (f.eks. 'mandag'): ")
    day_digit = map_ukedag(ukedag_input)
    if day_digit is None:
        print("Ugyldig ukedag.")
    retning = input("Er du interessert i avgangstider eller ankomsttider? (skriv 'avganger' eller 'ankomster'): ")
    return day_digit, retning

# Lar brukeren velge en flyplass fra listen
def select_flyplass(flyplasser):
    if len(flyplasser) == 0:
        print("Beklager, ingen flyplasser funnet.")
        return None
    print("Velg en flyplass:")
    for i, (kode, navn) in enumerate(flyplasser, start=1):
        print(f"{i}. {navn} ({kode})")
    valg = int(input("Skriv inn nummeret til ønsket flyplass: "))
    if 1 <= valg <= len(flyplasser):
        return flyplasser[valg - 1]
    else:
        print("Ugyldig valg.")
        return None

# SQL-spørring som finner ankomster fra valgt ukedag og flyplass
def query_ankomster(cursor, flyplass_kode, day_digit):
   
    query = """
    SELECT fr.rutenummer,

      -- Underforespørsel for å hente ankomsttiden fra den siste etappen
      (
            SELECT re2.planlagt_ankomst
            FROM ruteetappe re2
            WHERE re2.rutenummer = fr.rutenummer
            ORDER BY re2.rekkefolge DESC
            LIMIT 1
      ) AS planlagt_ankomst_siste_etappe,
      
      -- Slår sammen alle etappene i ruten, i stigende rekkefølge
      GROUP_CONCAT(
        fromfp.navn || '->' || tofp.navn,
        ' | '
      ) AS full_strekning

    FROM flyrute fr
    JOIN ruteetappe re ON fr.rutenummer = re.rutenummer
    JOIN flyplass fromfp ON re.fra_flyplasskode = fromfp.kode
    JOIN flyplass tofp   ON re.til_flyplasskode = tofp.kode

    WHERE fr.ukedager LIKE '%' || ? || '%'
    GROUP BY fr.rutenummer
    HAVING SUM(CASE WHEN re.til_flyplasskode = ? THEN 1 ELSE 0 END) > 0
    ORDER BY fr.rutenummer;
    """

    cursor.execute(query, (day_digit, flyplass_kode))
    return cursor.fetchall()

# SQL-spørring som finner avganger fra valgt ukedag og flyplass
def query_avganger(cursor, flyplass_kode, day_digit):

    query = """
    SELECT fr.rutenummer,

        -- Underforespørsel for å hente avgangstiden fra første etappe
        (
            SELECT re2.planlagt_avgang
            FROM ruteetappe re2
            WHERE re2.rutenummer = fr.rutenummer
            ORDER BY re2.rekkefolge ASC
            LIMIT 1
        ) AS planlagt_avgang_forste_etappe,
        
        -- Slår sammen alle etappene i ruten, i stigende rekkefølge
        GROUP_CONCAT(
            fromfp.navn || '->' || tofp.navn, 
            ' | '
        ) AS full_strekning

        FROM flyrute fr
        JOIN ruteetappe re ON fr.rutenummer = re.rutenummer
        JOIN flyplass fromfp ON re.fra_flyplasskode = fromfp.kode
        JOIN flyplass tofp   ON re.til_flyplasskode = tofp.kode

        WHERE fr.ukedager LIKE '%' || ? || '%'  -- day_digit
        GROUP BY fr.rutenummer
        HAVING SUM(CASE WHEN re.fra_flyplasskode = ? THEN 1 ELSE 0 END) > 0  -- flyplass_kode

        ORDER BY fr.rutenummer;

    """
    cursor.execute(query, (day_digit, flyplass_kode))
    return cursor.fetchall()

# Konverterer ukedagstekst til et siffer (slik at det er på samme format som i databasen)
def map_ukedag(ukedag_str):
    mapping = {
        'mandag': '1',
        'tirsdag': '2',
        'onsdag': '3',
        'torsdag': '4',
        'fredag': '5',
        'lørdag': '6',
        'søndag': '7'
    }
    return mapping.get(ukedag_str.lower(), None)

# Viser resultatene
def display_results(resultater, retning):
    if not resultater:
        print("Ingen resultater funnet.")
        return
    if retning.lower() == "avganger":
        print("\nAvganger:")
        for rute in resultater:
            print(f"Rutenummer: {rute[0]}, Planlagt avgang: {rute[1]}, Flyrute: {rute[2]}")
    elif retning.lower() == "ankomster":
        print("\nAnkomster:")
        for rute in resultater:
            print(f"Rutenummer: {rute[0]}, Planlagt ankomst: {rute[1]}, Flyrute: {rute[2]}")


if __name__ == "__main__":
    main()
