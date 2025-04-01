import psycopg2
import pandas as pd
import numpy as np  # Required for handling infinity values

# PostgreSQL connection parameters
db_params = {
    'dbname': 'oceanomics',
    'user': 'postgres',
    'password': 'oceanomics',
    'host': '115.146.85.41',
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
DATE = config.get("DATE")
#DATE = '250131'

# File containing depthsizer draft genome data
depthsizer_compiled_path = f"../../{DATE}_results/{DATE}_depthsizer_results.tsv"  # if your file structure is different this might not work.

# Import depthsizer draft genome data
print(f"Importing data from {depthsizer_compiled_path}")

# Load data
draft_genomes_depthsizer = pd.read_csv(depthsizer_compiled_path, sep="\t")

# Split the 'seqfile' column up so we have og_id and seq_date
# Ensure 'seqfile' column exists
if 'seqfile' in draft_genomes_depthsizer.columns:
    # Split 'seqfile' into three new columns
    draft_genomes_depthsizer['og_id'] = draft_genomes_depthsizer['seqfile'].str.split('.').str[0]
    draft_genomes_depthsizer['seq_date'] = draft_genomes_depthsizer['seqfile'].str.split('.').str[2]


    # Save the updated DataFrame back to a tab-delimited file
    output_file = f"{DATE}_depthsizer_results_split.tsv"
    draft_genomes_depthsizer.to_csv(output_file, sep="\t", index=False)
    
    print("File successfully processed! New columns added.")
else:
    print("Error: 'seqfile' column not found in the input file.")


# Print summary of changes
print("\n🔍 Final dataset summary:")
print(draft_genomes_depthsizer.describe())

try:
    # Connect to PostgreSQL
    conn = psycopg2.connect(**db_params)
    cursor = conn.cursor()

    row_count = 0  # Track number of processed rows

    for index, row in draft_genomes_depthsizer.iterrows():
        row_dict = row.to_dict()

        # Extract primary key values
        og_id, seq_date = row["og_id"], row["seq_date"]

        # UPSERT: Insert if not exists, otherwise update
        upsert_query = """
        INSERT INTO draft_genomes (
            og_id, seq_date, depmethod, adjust, readbp, mapadjust,
            scdepth, estgenomesize
        )
        VALUES (
            %(og_id)s, %(seq_date)s, %(depmethod)s, %(adjust)s, %(readbp)s, %(mapadjust)s,
            %(scdepth)s, %(estgenomesize)s
        )
        ON CONFLICT (og_id, seq_date) DO UPDATE SET
            depmethod = EXCLUDED.depmethod,
            adjust = EXCLUDED.adjust,
            readbp = EXCLUDED.readbp,
            mapadjust = EXCLUDED.mapadjust,
            scdepth = EXCLUDED.scdepth,
            estgenomesize = EXCLUDED.estgenomesize;
        """
        params = {
            "og_id": row_dict["og_id"],  # TEXT / VARCHAR
            "seq_date": str(row_dict["seq_date"]) if row_dict["seq_date"] else None,  # TEXT or DATE
            "depmethod": str(row_dict["depmethod"]) if row_dict["depmethod"] else None,  # TEXT
            "adjust": str(row_dict["adjust"]) if row_dict["adjust"] else None,  # TEXT
            "readbp": int(row_dict["readbp"]) if row_dict["readbp"] else None,  # INT
            "mapadjust": float(row_dict["mapadjust"]) if row_dict["mapadjust"] else None,  # FLOAT        
            "scdepth": float(row_dict["scdepth"]) if row_dict["scdepth"] else None,  # FLOAT
            "estgenomesize": int(row_dict["estgenomesize"]) if row_dict["estgenomesize"] else None,  # BIGINT            
        }

        # Debugging Check
        print(f"Number of columns in query: {upsert_query.count('%s')}")
        print(f"Column names in DataFrame: {draft_genomes_depthsizer.columns.tolist()}")
        print("row:", row_dict)
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
