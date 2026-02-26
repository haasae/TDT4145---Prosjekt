# Airport Project

A small command-line airport system built with **Python** and **SQLite**.

This repository is a learning project focused on combining Python application logic with SQL queries for realistic airport-related workflows.

## What you can do

After starting the app, you can:

1. **Search departures or arrivals** for a chosen airport and weekday.
2. **Check available seats** for a selected planned flight.
3. **View airline fleet summary** (airline → aircraft type → number of aircraft).

## Tech stack

- **Python 3**
- **SQLite** (via Python's built-in `sqlite3` module)
- SQL schema + seed data in `flyplass.sql`

No external Python packages are required.

## Project structure

```text
.
├── main.py        # CLI program and query logic
├── flyplass.sql   # Database schema and seed data
└── README.md
