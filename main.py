import os
import sqlite3

# Init-funksjon: Sjekker om databasen finnes, og oppretter den ved å kjøre SQL-scriptet dersom den ikke gjør det.
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
        print(resultater)
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

# SQL-spørring for å hente ankomster fra valgt flyplass og ukedag

def query_ankomster(cursor, flyplass_kode, day_digit):
    query = """
    SELECT fr.rutenummer,
           (
             SELECT re.planlagt_ankomst
             FROM ruteetappe re
             WHERE re.rutenummer = fr.rutenummer
             ORDER BY re.rekkefolge DESC
             LIMIT 1
           ) AS ankomststid,
           (
             SELECT fp2.navn
             FROM ruteetappe re
             JOIN flyplass fp2 ON re.fra_flyplasskode = fp2.kode
             WHERE re.rutenummer = fr.rutenummer
             ORDER BY re.rekkefolge ASC
             LIMIT 1
           ) AS opprinnelse
    FROM flyrute fr
    WHERE fr.ukedager LIKE '%' || ? || '%'
      AND EXISTS (
          SELECT 1
          FROM ruteetappe re
          WHERE re.rutenummer = fr.rutenummer
            AND re.til_flyplasskode = ?
      )
    ORDER BY fr.rutenummer;
    """
    cursor.execute(query, (day_digit, flyplass_kode))
    return cursor.fetchall()

def query_avganger(cursor, flyplass_kode, day_digit):
    query = """
    SELECT fr.rutenummer,
           (SELECT re.planlagt_avgang
            FROM ruteetappe re
            WHERE re.rutenummer = fr.rutenummer
            ORDER BY re.rekkefolge ASC
            LIMIT 1) AS avgangstid,
           (SELECT fp2.navn
            FROM ruteetappe re
            JOIN flyplass fp2 ON re.til_flyplasskode = fp2.kode
            WHERE re.rutenummer = fr.rutenummer
            ORDER BY re.rekkefolge DESC
            LIMIT 1) AS destinasjon
    FROM flyrute fr
    WHERE fr.ukedager LIKE '%' || ? || '%'
      AND EXISTS (
          SELECT 1
          FROM ruteetappe re
          WHERE re.rutenummer = fr.rutenummer
            AND re.fra_flyplasskode = ?
      )
    ORDER BY fr.rutenummer;
    """
    cursor.execute(query, (day_digit, flyplass_kode))
    return cursor.fetchall()


# Konverterer ukedagstekst til et siffer (som i databasen)
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

# Viser spørringsresultatene
def display_results(resultater, retning):
    if not resultater:
        print("Ingen resultater funnet.")
        return
    if retning.lower() == "avganger":
        print("\nAvganger:")
        for rute in resultater:
            print(f"Rutenummer: {rute[0]}, Planlagt avgang: {rute[1]}, Flyr til: {rute[2]}")
    elif retning.lower() == "ankomster":
        print("\nAnkomster:")
        for rute in resultater:
            print(f"Rutenummer: {rute[0]}, Planlagt ankomst: {rute[1]}, Flyr fra: {rute[2]}")


if __name__ == "__main__":
    main()
