import psycopg2
import pandas as pd
import numpy as np  # Required for handling infinity values
# Run using singularity run $SING/psycopg2:0.1.sif python

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
DATE = config.get("DATE")
#DATE = '250131'

# File containing BUSCO draft genome data
BUSCO_compiled_path = f"../../{DATE}_results/{DATE}_BUSCO_compiled_results.tsv"  # if your file structure is different this might not work.

# Import BUSCO draft genome data
print(f"Importing data from {BUSCO_compiled_path}")

# Load data
draft_genomes_busco = pd.read_csv(BUSCO_compiled_path, sep="\t")

# Split the 'sample' column up so we have og_id and seq_date
# Ensure 'sample' column exists
if 'sample' in draft_genomes_busco.columns:
    # Split 'sample' into three new columns
    draft_genomes_busco['og_id'] = draft_genomes_busco['sample'].str.split('.').str[0]
    draft_genomes_busco['seq_date'] = draft_genomes_busco['sample'].str.split('.').str[2]


    # Save the updated DataFrame back to a tab-delimited file
    output_file = f"{DATE}_BUSCO_compiled_results_split.tsv"
    draft_genomes_busco.to_csv(output_file, sep="\t", index=False)
    
    print("File successfully processed! New columns added.")
else:
    print("Error: 'sample' column not found in the input file.")


# Print summary of changes
print("\n🔍 Final dataset summary:")
print(draft_genomes_busco.describe())

try:
    # Connect to PostgreSQL
    conn = psycopg2.connect(**db_params)
    cursor = conn.cursor()

    row_count = 0  # Track number of processed rows

    for index, row in draft_genomes_busco.iterrows():
        row_dict = row.to_dict()

        # Extract primary key values
        og_id, seq_date = row["og_id"], row["seq_date"]

        # UPSERT: Insert if not exists, otherwise update
        upsert_query = """
        INSERT INTO draft_genomes (
            og_id, seq_date, complete, single_copy, multi_copy, fragmented,
            missing, n_markers, domain, number_of_scaffolds, number_of_contigs, total_length, percent_gaps, 
            scaffold_n50, contigs_n50
        )
        VALUES (
            %(og_id)s, %(seq_date)s, %(complete)s, %(single_copy)s, %(multi_copy)s, %(fragmented)s,
            %(missing)s, %(n_markers)s, %(domain)s, %(number_of_scaffolds)s, %(number_of_contigs)s, %(total_length)s,  
            %(percent_gaps)s, %(scaffold_n50)s, %(contigs_n50)s
        )
        ON CONFLICT (og_id, seq_date) DO UPDATE SET
            complete = EXCLUDED.complete,
            single_copy = EXCLUDED.single_copy,
            multi_copy = EXCLUDED.multi_copy,
            fragmented = EXCLUDED.fragmented,
            missing = EXCLUDED.missing,
            n_markers = EXCLUDED.n_markers,
            domain = EXCLUDED.domain,
            number_of_scaffolds = EXCLUDED.number_of_scaffolds,
            number_of_contigs = EXCLUDED.number_of_contigs,
            total_length = EXCLUDED.total_length,
            percent_gaps = EXCLUDED.percent_gaps,
            scaffold_n50 = EXCLUDED.scaffold_n50,
            contigs_n50 = EXCLUDED.contigs_n50;
        """
        params = {
            "og_id": row_dict["og_id"],  # TEXT / VARCHAR
            "seq_date": str(row_dict["seq_date"]) if row_dict["seq_date"] else None,  # TEXT or DATE
            "complete": float(row_dict["complete"]) if row_dict["complete"] else None,  # FLOAT
            "single_copy": float(row_dict["single_copy"]) if row_dict["single_copy"] else None,  # FLOAT
            "multi_copy": float(row_dict["multi_copy"]) if row_dict["multi_copy"] else None,  # FLOAT
            "fragmented": float(row_dict["fragmented"]) if row_dict["fragmented"] else None,  # FLOAT        
            "missing": float(row_dict["missing"]) if row_dict["missing"] else None,  # FLOAT
            "n_markers": int(row_dict["n_markers"]) if row_dict["n_markers"] else None,  # INT
            "domain": str(row_dict["domain"]) if row_dict["domain"] else None,  # TEXT
            "number_of_scaffolds": int(row_dict["number_of_scaffolds"]) if row_dict["number_of_scaffolds"] else None,  # INTEGER        
            "number_of_contigs": int(row_dict["number_of_contigs"]) if row_dict["number_of_contigs"] else None,  # INTEGER
            "total_length": int(row_dict["total_length"]) if row_dict["total_length"] else None,  # BIGINT        
            "percent_gaps": float(str(row_dict["percent_gaps"]).rstrip('%')) if row_dict["percent_gaps"] not in [None, ""] else None,       
            "scaffold_n50": float(row_dict["scaffold_n50"]) if row_dict["scaffold_n50"] else None,  # FLOAT        
            "contigs_n50": int(row_dict["contigs_n50"]) if row_dict["contigs_n50"] else None,  # INTEGER
        }

        # Debugging Check
        print(f"Number of columns in query: {upsert_query.count('%s')}")
        print(f"Column names in DataFrame: {draft_genomes_busco.columns.tolist()}")
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
