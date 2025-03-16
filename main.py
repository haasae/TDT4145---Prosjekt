import os
import sqlite3

# Initialiserer databasen ved å kjøre SQL-skriptet dersom databasen ikke finnes
def init_db(db_path, sql_script_path):
    if not os.path.exists(db_path):
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        with open(sql_script_path, 'r', encoding='utf-8') as f:
            sql_script = f.read()
        cursor.executescript(sql_script)
        conn.commit()
        conn.close()

# ---------------------------
# Funksjonalitet for brukstilfelle 6)
# ---------------------------

# Henter alle flyplasser fra databasen
def get_flyplasser(cursor):
    cursor.execute("SELECT kode, navn FROM flyplass")
    return cursor.fetchall()

# Lar brukeren velge en flyplass fra en list
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
    
# Henter brukerens preferanser for ukedag og retning (avganger eller ankomster)
def get_user_preferences():
    ukedag_input = input("Hvilken dag ønsker du å fly (f.eks. 'mandag'): ")
    day_digit = map_ukedag(ukedag_input)
    if day_digit is None:
        print("Ugyldig ukedag.")
    retning = input("Er du interessert i avgangstider eller ankomsttider? (skriv 'avganger' eller 'ankomster'): ")
    return day_digit, retning

# Oversetting for interaksjon med databasen
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

# Henter avganger for en gitt flyplass og ukedag
def query_avganger(cursor, flyplass_kode, day_digit):
    query = """
    SELECT fr.rutenummer,
           (
            SELECT re2.planlagt_avgang
            FROM ruteetappe re2
            WHERE re2.rutenummer = fr.rutenummer
            ORDER BY re2.rekkefolge ASC
            LIMIT 1
           ) AS planlagt_avgang_forste_etappe,
           GROUP_CONCAT(
            fromfp.navn || ' -> ' || tofp.navn, ' | '
           ) AS full_strekning
    FROM flyrute fr
    JOIN ruteetappe re ON fr.rutenummer = re.rutenummer
    JOIN flyplass fromfp ON re.fra_flyplasskode = fromfp.kode
    JOIN flyplass tofp   ON re.til_flyplasskode = tofp.kode
    WHERE fr.ukedager LIKE '%' || ? || '%'
    GROUP BY fr.rutenummer
    HAVING SUM(CASE WHEN re.fra_flyplasskode = ? THEN 1 ELSE 0 END) > 0
    ORDER BY fr.rutenummer;
    """
    cursor.execute(query, (day_digit, flyplass_kode))
    return cursor.fetchall()

# Henter ankomster for en gitt flyplass og ukedag
def query_ankomster(cursor, flyplass_kode, day_digit):
    query = """
    SELECT fr.rutenummer,
           (
            SELECT re2.planlagt_ankomst
            FROM ruteetappe re2
            WHERE re2.rutenummer = fr.rutenummer
            ORDER BY re2.rekkefolge DESC
            LIMIT 1
           ) AS planlagt_ankomst_siste_etappe,
           GROUP_CONCAT(
            fromfp.navn || ' -> ' || tofp.navn, ' | '
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

# Skriver ut resultatene for avganger eller ankomster
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

# ---------------------------
# Funksjonalitet for brukstilfelle 8)
# ---------------------------

# Henter detaljer om en spesifikk flyvning basert på flyvning_id
def query_flight_instance(cursor, flight_id):
    cursor.execute("""
        SELECT flyvning_id, rutenummer, registreringsnummer, dato, status 
        FROM flyvning 
        WHERE flyvning_id = ?
    """, (flight_id,))
    return cursor.fetchone()

# Henter alle delflyvninger (etapper) for en gitt rute, sortert etter rekkefølge
def get_flight_legs(cursor, rutenummer):
    query = """
    SELECT re.rekkefolge, re.fra_flyplasskode, re.til_flyplasskode, 
           re.planlagt_avgang, re.planlagt_ankomst,
           f1.navn AS fra_navn, f2.navn AS til_navn
    FROM ruteetappe re
    JOIN flyplass f1 ON re.fra_flyplasskode = f1.kode
    JOIN flyplass f2 ON re.til_flyplasskode = f2.kode
    WHERE re.rutenummer = ?
    ORDER BY re.rekkefolge ASC;
    """
    cursor.execute(query, (rutenummer,))
    return cursor.fetchall()

# Henter ledige seter for en bestemt flyvning og reise-segment
def get_available_seats(cursor, flyvning_id, segment_str):
    # Finn flytypen for flyvningen
    cursor.execute("""
        SELECT f.flytype_navn 
        FROM flyvning v 
        JOIN fly f ON v.registreringsnummer = f.registreringsnummer 
        WHERE v.flyvning_id = ?
    """, (flyvning_id,))
    row = cursor.fetchone()
    print(row)
    if row is None:
        return []
    flytype = row[0]
    
    # Henter alle seter for flytypen
    cursor.execute("""
        SELECT radnummer, setebokstav 
        FROM sete 
        WHERE flytype_navn = ?
        ORDER BY radnummer, setebokstav
    """, (flytype,))
    all_seats = set(cursor.fetchall())
    
    # Henter de setene som allerede er reservert for denne flyvningen og reise-segmentet
    cursor.execute("""
        SELECT radnummer, setebokstav 
        FROM billett 
        WHERE flyvning_id = ? AND reise_segment = ?
    """, (flyvning_id, segment_str))
    reserved_seats = set(cursor.fetchall())
    
    available_seats = sorted(list(all_seats - reserved_seats))
    return available_seats

# Kombinerer etappeinformasjon med ledige seter for en bestemt flyvning
def query_available_seats_for_flight(cursor, flight_id):
    flight = query_flight_instance(cursor, flight_id)
    if flight is None:
        print("Flyvningen ble ikke funnet.")
        return []
    flyvning_id, rutenummer, registreringsnummer, dato, status = flight
    legs = get_flight_legs(cursor, rutenummer)
    result = []
    for leg in legs:
        rekkefolge, fra_code, til_code, planlagt_avgang, planlagt_ankomst, fra_navn, til_navn = leg
       # Definer reise-segmentet for etappen
        segment_str = f"{fra_code}-{til_code}"
        available = get_available_seats(cursor, flyvning_id, segment_str)
        result.append({
            'rekkefolge': rekkefolge,
            'segment': segment_str,
            'fra_flyplass': fra_navn,
            'til_flyplass': til_navn,
            'planlagt_avgang': planlagt_avgang,
            'planlagt_ankomst': planlagt_ankomst,
            'ledige_seter': available
        })
    return result

# Skriver ut oversikten over ledige seter for hver etappe
def display_available_seats(legs_info):
    if not legs_info:
        print("Ingen data å vise.")
        return
    for leg in legs_info:
        print(f"\nEtappe {leg['rekkefolge']}: {leg['fra_flyplass']} -> {leg['til_flyplass']}")
        print(f"Planlagt avgang: {leg['planlagt_avgang']}, planlagt ankomst: {leg['planlagt_ankomst']}")
        print("Ledige seter:")
        if leg['ledige_seter']:
            for seat in leg['ledige_seter']:
                print(f"  Rad {seat[0]} {seat[1]}")
        else:
            print("  Ingen ledige seter.")

# Lar brukeren søke etter og velge en flyvning basert på dato og/eller rutenummer
def query_flights(cursor, dato=None, rutenummer=None):
    
    query = "SELECT flyvning_id, rutenummer, dato, status, registreringsnummer FROM flyvning WHERE status = 'planned'"
    params = []
    if dato:
        query += " AND dato = ?"
        params.append(dato)
    if rutenummer:
        query += " AND rutenummer = ?"
        params.append(rutenummer)
    query += " ORDER BY dato, rutenummer;"
    cursor.execute(query, tuple(params))
    return cursor.fetchall()

# Lar brukeren velge en flyvning fra en liste basert på filtreringskriterier
def select_flight(cursor):
    dato = input("Skriv inn dato for flyvningen (YYYY-MM-DD) eller trykk enter for alle: ").strip()
    if dato == "":
        dato = None
    rutenummer = input("Skriv inn rutenummer for flyvningen (f.eks. WF1302) eller trykk enter for alle: ").strip()
    if rutenummer == "":
        rutenummer = None

    flights = query_flights(cursor, dato, rutenummer)
    if not flights:
        print("Ingen flyvninger funnet med de kriteriene.")
        return None

    print("Tilgjengelige flyvninger:")
    for idx, flight in enumerate(flights, start=1):
        flyvning_id, rutenummer, dato, status, regnr = flight
        print(f"{idx}. Rutenummer: {rutenummer}, Dato: {dato}, Registreringsnummer: {regnr}")

    valg = int(input("Velg en flyvning ved å skrive inn nummeret: "))
    if 1 <= valg <= len(flights):
        selected = flights[valg - 1]
        return selected[0]  # Returnerer flyvning_id
    else:
        print("Ugyldig valg.")
        return None

# Hovedfunksjon for brukstilfelle 8: Søker etter en flyvning og viser ledige seter
def find_available_seats(cursor):

    flight_id = select_flight(cursor)
    if flight_id is None:
        return
    legs_info = query_available_seats_for_flight(cursor, flight_id)
    display_available_seats(legs_info)
    

# ---------------------------
# Hovedprogram med meny
# ---------------------------

def main():
    db_path = 'flyplass.db'
    sql_script_path = 'flyplass.sql'
    
    # Initialiser databasen dersom den ikke finnes
    init_db(db_path, sql_script_path)
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    print("Velg funksjonalitet:")
    print("1. Søk avganger/ankomster fra flyplass")
    print("2. Sjekk ledige seter for en flyvning")
    valg = input("Skriv 1 eller 2: ")
    
    if valg == "1":
        flyplasser = get_flyplasser(cursor)
        valgt_flyplass = select_flyplass(flyplasser)
        if valgt_flyplass is None:
            conn.close()
            return
        flyplass_kode = valgt_flyplass[0]
        day_digit, retning = get_user_preferences()
        if retning.lower() == "avganger":
            resultater = query_avganger(cursor, flyplass_kode, day_digit)
        elif retning.lower() == "ankomster":
            resultater = query_ankomster(cursor, flyplass_kode, day_digit)
        else:
            print("Ugyldig valg for retning.")
            conn.close()
            return
        display_results(resultater, retning)
    
    elif valg == "2":
        find_available_seats(cursor)
    else:
        print("Ugyldig valg.")
    
    conn.close()

if __name__ == "__main__":
    main()

