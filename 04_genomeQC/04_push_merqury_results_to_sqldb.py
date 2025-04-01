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


# File containing MERQURY QV draft genome data
merqury_qv_path = f"../../{DATE}_results/{DATE}_merqury.qv.stats.tsv"  # if your file structure is different this might not work.

# Import MERQURY QV draft genome data
print(f"Importing data from {merqury_qv_path}")

# Load data
draft_genomes_merquryqv = pd.read_csv(merqury_qv_path, sep="\t")

# Split the 'sample' column up so we have og_id and seq_date
# Ensure 'sample' column exists
if 'sample' in draft_genomes_merquryqv.columns:
    # Split 'sample' into three new columns
    draft_genomes_merquryqv['og_id'] = draft_genomes_merquryqv['sample'].str.split('.').str[0]
    draft_genomes_merquryqv['seq_date'] = draft_genomes_merquryqv['sample'].str.split('.').str[2]


    # Save the updated DataFrame back to a tab-delimited file
    output_file = f"{DATE}_merquryqv_split.tsv"
    draft_genomes_merquryqv.to_csv(output_file, sep="\t", index=False)
    
    print("File successfully processed! New columns added.")
else:
    print("Error: 'sample' column not found in the input file.")


# Print summary of changes
print("\n🔍 Final dataset summary:")
print(draft_genomes_merquryqv.describe())

try:
    # Connect to PostgreSQL
    conn = psycopg2.connect(**db_params)
    cursor = conn.cursor()

    row_count = 0  # Track number of processed rows

    for index, row in draft_genomes_merquryqv.iterrows():
        row_dict = row.to_dict()

        # Extract primary key values
        og_id, seq_date = row["og_id"], row["seq_date"]

        # UPSERT: Insert if not exists, otherwise update
        upsert_query = """
        INSERT INTO draft_genomes (
            og_id, seq_date, unique_k_mers_assembly, k_mers_total, qv, error
        )
        VALUES (
            %(og_id)s, %(seq_date)s, %(unique_k_mers_assembly)s, %(k_mers_total)s, %(qv)s, %(error)s
        )
        ON CONFLICT (og_id, seq_date) DO UPDATE SET
            unique_k_mers_assembly = EXCLUDED.unique_k_mers_assembly,
            k_mers_total = EXCLUDED.k_mers_total,
            qv = EXCLUDED.qv,
            error = EXCLUDED.error;
        """
        params = {
            "og_id": row_dict["og_id"],  # TEXT / VARCHAR
            "seq_date": str(row_dict["seq_date"]) if row_dict["seq_date"] else None,  # TEXT or DATE
            "unique_k_mers_assembly": int(row_dict["unique_k_mers_assembly"]) if row_dict["unique_k_mers_assembly"] else None,  # BIGINT
            "k_mers_total": int(row_dict["k_mers_total"]) if row_dict["k_mers_total"] else None,  # BIGINT
            "qv": float(row_dict["qv"]) if row_dict["qv"] else None,  # FLOAT
            "error": float(row_dict["error"]) if row_dict["error"] else None,  # FLOAT                   
        }

        # Debugging Check
        print(f"Number of columns in query: {upsert_query.count('%s')}")
        print(f"Column names in DataFrame: {draft_genomes_merquryqv.columns.tolist()}")
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



#################################################
# File containing MERQURY COMPLETENESS draft genome data
merqury_comp_path = f"../../{DATE}_results/{DATE}_merqury.completeness.stats.tsv"  # if your file structure is different this might not work.

# Import MERQURY COMPLETENESS draft genome data
print(f"Importing data from {merqury_comp_path}")

# Load data
draft_genomes_merqurycomp = pd.read_csv(merqury_comp_path, sep="\t")

# Split the 'sample' column up so we have og_id and seq_date
# Ensure 'sample' column exists
if 'sample' in draft_genomes_merqurycomp.columns:
    # Split 'sample' into three new columns
    draft_genomes_merqurycomp['og_id'] = draft_genomes_merqurycomp['sample'].str.split('.').str[0]
    draft_genomes_merqurycomp['seq_date'] = draft_genomes_merqurycomp['sample'].str.split('.').str[2]


    # Save the updated DataFrame back to a tab-delimited file
    output_file = f"{DATE}_merqurycomp_split.tsv"
    draft_genomes_merqurycomp.to_csv(output_file, sep="\t", index=False)
    
    print("File successfully processed! New columns added.")
else:
    print("Error: 'sample' column not found in the input file.")


# Print summary of changes
print("\n🔍 Final dataset summary:")
print(draft_genomes_merqurycomp.describe())

try:
    # Connect to PostgreSQL
    conn = psycopg2.connect(**db_params)
    cursor = conn.cursor()

    row_count = 0  # Track number of processed rows

    for index, row in draft_genomes_merqurycomp.iterrows():
        row_dict = row.to_dict()

        # Extract primary key values
        og_id, seq_date = row["og_id"], row["seq_date"]

        # UPSERT: Insert if not exists, otherwise update
        upsert_query = """
        INSERT INTO draft_genomes (
            og_id, seq_date, k_mer_set, solid_k_mers, total_k_mers, completeness
        )
        VALUES (
            %(og_id)s, %(seq_date)s, %(k_mer_set)s, %(solid_k_mers)s, %(total_k_mers)s, %(completeness)s
        )
        ON CONFLICT (og_id, seq_date) DO UPDATE SET
            k_mer_set = EXCLUDED.k_mer_set,
            solid_k_mers = EXCLUDED.solid_k_mers,
            total_k_mers = EXCLUDED.total_k_mers,
            completeness = EXCLUDED.completeness;
        """
        params = {
            "og_id": row_dict["og_id"],  # TEXT / VARCHAR
            "seq_date": str(row_dict["seq_date"]) if row_dict["seq_date"] else None,  # TEXT or DATE
            "k_mer_set": str(row_dict["k_mer_set"]) if row_dict["k_mer_set"] else None,  # TEXT
            "solid_k_mers": int(row_dict["solid_k_mers"]) if row_dict["solid_k_mers"] else None,  # BIGINT
            "total_k_mers": int(row_dict["total_k_mers"]) if row_dict["total_k_mers"] else None,  # BIGINT
            "completeness": float(row_dict["completeness"]) if row_dict["completeness"] else None,  # FLOAT                   
        }

        # Debugging Check
        print(f"Number of columns in query: {upsert_query.count('%s')}")
        print(f"Column names in DataFrame: {draft_genomes_merqurycomp.columns.tolist()}")
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