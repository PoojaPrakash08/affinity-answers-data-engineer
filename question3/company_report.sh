
#!/usr/bin/env bash

set -euo pipefail

# Check that the CSV URL is provided
if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <CSV_URL>" >&2
    exit 1
fi

URL="$1"

# Check required commands
command -v curl >/dev/null 2>&1 || {
    echo "Error: curl is required." >&2
    exit 1
}

command -v python >/dev/null 2>&1 || {
    echo "Error: python3 is required." >&2
    exit 1
}

# Download the CSV to a temporary file
TEMP_FILE=$(mktemp)
trap 'rm -f "$TEMP_FILE"' EXIT

echo "Downloading company data..." >&2
curl -fsSL "$URL" -o "$TEMP_FILE"

# Parse CSV safely and sort companies by founding year
python - "$TEMP_FILE" <<'PY'
import csv
import re
import sys

csv_file = sys.argv[1]

with open(csv_file, newline="", encoding="utf-8-sig") as file:
    reader = csv.DictReader(file)

    required = {"Security", "Headquarters Location", "Founded"}
    if not reader.fieldnames or not required.issubset(reader.fieldnames):
        sys.exit("Error: CSV is missing required columns.")

    companies = []

    for row in reader:
        name = (row.get("Security") or "").strip()
        location = (row.get("Headquarters Location") or "").strip()
        founded = (row.get("Founded") or "").strip()

        # Extract the first four-digit year, e.g. 2013 from "2013 (1888)"
        match = re.search(r"\d{4}", founded)
        year = int(match.group()) if match else None

        if name:
            companies.append((year, name, location))

# Sort oldest to newest; missing founding years appear last
companies.sort(
    key=lambda item: (
        item[0] is None,
        item[0] if item[0] is not None else 0,
        item[1].casefold()
    )
)

writer = csv.writer(sys.stdout, delimiter="\t", lineterminator="\n")
writer.writerow(["Company Name", "Location", "Founding Year"])

for year, name, location in companies:
    writer.writerow([name, location, year if year is not None else "Unknown"])
PY
