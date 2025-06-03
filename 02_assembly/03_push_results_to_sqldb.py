import psycopg2
import pandas as pd
import numpy as np  # Required for handling infinity values

# run using: singularity run $SING/psycopg2:0.1.sif python 04_push_results_to_sqldb.py

# PostgreSQL connection parameters
db_params = {
    'dbname': 'oceanomics',
    'user': 'postgres',
    'password': 'oceanomics',
    'host': '203.101.227.69',
    'port': 5432
}

# Initialize an empty dictionary
config = {}

# Read the config.txt file
with open("../configfile.txt", "r") as file:
    for line in file:
        line = line.strip()  # Remove spaces and newlines

        # Ignore empty lines and comments
        if not line or line.startswith("#"):
            continue

        # Ensure the line contains an '=' before splitting
        if "=" in line:
            key, value = line.split("=", 1)  # Split on first '='
            config[key.strip()] = value.strip()  # Store key-value pair
        else:
            print(f"⚠ Warning: Skipping invalid line -> {line}")  # Debugging message

print("✅ Configuration Loaded:", config)

# Access file paths
RUN = DATE = config.get("RUN")

def extract_date(run_string):
    parts = run_string.split('_')
    return parts[1] if len(parts) > 1 else None

DATE = extract_date(RUN)
print(f"RUN = {RUN} and DATE = {DATE}")

# File containing draft genome data
genomescope_compile_path = f"../../{DATE}_results/{DATE}_genomescope_compiled_results.tsv"  # if your file structure is different this might not work.

# Import draft genome data
print(f"Importing data from {genomescope_compile_path}")

# Load data
draft_genomes_genomescope = pd.read_csv(genomescope_compile_path, sep="\t")

# Split the 'Sample' column up into 3 for the database
# Ensure 'Sample' column exists
if 'Sample' in draft_genomes_genomescope.columns:
    # Split 'Sample' into three new columns
    draft_genomes_genomescope[['og_id', 'tech', 'seq_date']] = draft_genomes_genomescope['Sample'].str.split('.', expand=True)
    
    # Drop the 'Sample' and 'tech' column as no longer needed
    draft_genomes_genomescope.drop(columns=['tech', 'Sample'], inplace=True)

    # Save the updated DataFrame back to a tab-delimited file
    output_file = f"{DATE}_genomescope_compiled_results_split.tsv"
    draft_genomes_genomescope.to_csv(output_file, sep="\t", index=False)
    
    print("File successfully processed! New columns added.")
else:
    print("Error: 'Sample' column not found in the input file.")

# Normalize column names (remove spaces & make lowercase)
draft_genomes_genomescope.columns = (
    draft_genomes_genomescope.columns
    .str.strip()  # Remove leading/trailing spaces
    .str.lower()  # Convert to lowercase
    .str.replace(r'[^a-z0-9_]', '_', regex=True)  # Replace non-alphanumeric characters with underscores
)

# Print column names to verify
print("✅ Columns in file:", draft_genomes_genomescope.columns.tolist())

# Print summary of changes
print("\n🔍 Final dataset summary:")
print(draft_genomes_genomescope.describe())

try:
    # Connect to PostgreSQL
    conn = psycopg2.connect(**db_params)
    cursor = conn.cursor()

    row_count = 0  # Track number of processed rows

    for index, row in draft_genomes_genomescope.iterrows():
        values = tuple(row.values)

        # Extract primary key values
        og_id, seq_date = row["og_id"], row["seq_date"]

        # UPSERT: Insert if not exists, otherwise update
        upsert_query = """
        INSERT INTO draft_genomes (
            og_id, seq_date, homozygosity, heterozygosity, genomesize, repeatsize, uniquesize, modelfit, errorrate
        )
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
        ON CONFLICT (og_id, seq_date) DO UPDATE SET
            homozygosity = EXCLUDED.homozygosity,
            heterozygosity = EXCLUDED.heterozygosity,
            genomesize = EXCLUDED.genomesize,
            repeatsize = EXCLUDED.repeatsize,
            uniquesize = EXCLUDED.uniquesize,
            modelfit = EXCLUDED.modelfit,
            errorrate = EXCLUDED.errorrate;
        """

        params = (
            row["og_id"],  # TEXT / VARCHAR
            str(row["seq_date"]) if row["seq_date"] else None,  # TEXT or DATE
            float(str(row["homozygosity"]).replace("%", "") if row["homozygosity"] and "%" in str(row["homozygosity"]) else float(row["homozygosity"])),  # FLOAT
            float(str(row["heterozygosity"]).replace("%", "") if row["heterozygosity"] and "%" in str(row["heterozygosity"]) else float(row["heterozygosity"])),  # FLOAT
            int(str(row["genomesize"]).replace(",", "") if row["genomesize"] and "," in str(row["genomesize"]) else int(row["genomesize"])),  # INTEGER
            int(str(row["repeatsize"]).replace(",", "") if row["repeatsize"] and "," in str(row["repeatsize"]) else int(row["repeatsize"])),  # INTEGER
            int(str(row["uniquesize"]).replace(",", "") if row["uniquesize"] and "," in str(row["uniquesize"]) else int(row["uniquesize"])),  # INTEGER
            float(str(row["modelfit"]).replace("%", "") if row["modelfit"] and "%" in str(row["modelfit"]) else float(row["modelfit"])),  # FLOAT
            float(str(row["errorrate"]).replace("%", "") if row["errorrate"] and "%" in str(row["errorrate"]) else float(row["errorrate"])),  # FLOAT
        )

        # Debugging Check
        print(f"Number of columns in query: {upsert_query.count('%s')}")
        print(f"Number of values being passed: {len(values)}")
        print(f"Column names in DataFrame: {draft_genomes_genomescope.columns.tolist()}")
        print("Values:", values)
        print("params:", params)

        cursor.execute(upsert_query, params)
        row_count += 1  

        conn.commit()
        print(f"✅ Successfully processed {row_count} rows!")

except Exception as e:
    conn.rollback()
    print(f"❌ Error: {e}")

finally:
    cursor.close()
    conn.close()
