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
#DATE = '250131'

# File containing draft genome data
fastp_compiled_path = f"../../{DATE}_results/{DATE}_fastp_compiled_results.tsv"  # if your file structure is different this might not work.

# Import draft genome data
print(f"Importing data from {fastp_compiled_path}")

# Load data
draft_genomes_fastp = pd.read_csv(fastp_compiled_path, sep="\t")

# Split the 'run' column up into 3 for the database
# Ensure 'run' column exists
if 'run' in draft_genomes_fastp.columns:
    # Split 'run' into three new columns
    draft_genomes_fastp[['mach', 'seq_date', 'initial']] = draft_genomes_fastp['run'].str.split('_', expand=True)
    
    # Drop the original 'run' column if no longer needed
    draft_genomes_fastp.drop(columns=['run'], inplace=True)

    # Save the updated DataFrame back to a tab-delimited file
    output_file = f"{DATE}_fastp_compiled_results_split.tsv"
    draft_genomes_fastp.to_csv(output_file, sep="\t", index=False)
    
    print("File successfully processed! New columns added.")
else:
    print("Error: 'run' column not found in the input file.")

# Normalize column names (remove spaces & make lowercase)
draft_genomes_fastp.columns = (
    draft_genomes_fastp.columns
    .str.strip()  # Remove leading/trailing spaces
    .str.lower()  # Convert to lowercase
    .str.replace(r'[^a-z0-9_]', '_', regex=True)  # Replace non-alphanumeric characters with underscores
)


# Rename columns to match SQL table naming conventions
column_mapping = {"sample": "og_id"}
draft_genomes_fastp.rename(columns=column_mapping, inplace=True)

# Print column names to verify
print("✅ Columns in file:", draft_genomes_fastp.columns.tolist())

# Print summary of changes
print("\n🔍 Final dataset summary:")
print(draft_genomes_fastp.describe())

try:
    # Connect to PostgreSQL
    conn = psycopg2.connect(**db_params)
    cursor = conn.cursor()

    row_count = 0  # Track number of processed rows

    for index, row in draft_genomes_fastp.iterrows():
        row_dict = row.to_dict()

        # Extract primary key values
        og_id, seq_date = row["og_id"], row["seq_date"]

        # UPSERT: Insert if not exists, otherwise update
        upsert_query = """
        INSERT INTO draft_genomes (
            og_id, passed_filter_reads, low_quality_reads, too_many_n_reads, too_short_reads, too_long_reads,
            raw_total_reads, raw_total_bases, raw_q20_bases, raw_q30_bases, raw_q20_rate, raw_q30_rate, raw_read1_mean_length, raw_read2_mean_length,
            raw_gc_content, total_reads, total_bases, q20_bases, q30_bases, q20_rate, q30_rate, read1_mean_length, read2_mean_length, gc_content, mach, seq_date, initial
        )
        VALUES (
            %(og_id)s, %(passed_filter_reads)s, %(low_quality_reads)s, %(too_many_n_reads)s, %(too_short_reads)s, %(too_long_reads)s,
            %(raw_total_reads)s, %(raw_total_bases)s, %(raw_q20_bases)s, %(raw_q30_bases)s, %(raw_q20_rate)s, %(raw_q30_rate)s, %(raw_read1_mean_length)s, %(raw_read2_mean_length)s,
            %(raw_gc_content)s, %(total_reads)s, %(total_bases)s, %(q20_bases)s, %(q30_bases)s, %(q20_rate)s, %(q30_rate)s, %(read1_mean_length)s, %(read2_mean_length)s, %(gc_content)s, %(mach)s, %(seq_date)s, %(initial)s
        )
        ON CONFLICT (og_id, seq_date) DO UPDATE SET
            mach = EXCLUDED.mach,
            initial = EXCLUDED.initial,
            passed_filter_reads = EXCLUDED.passed_filter_reads,
            low_quality_reads = EXCLUDED.low_quality_reads,
            too_many_n_reads = EXCLUDED.too_many_n_reads,
            too_short_reads = EXCLUDED.too_short_reads,
            too_long_reads = EXCLUDED.too_long_reads,
            raw_total_reads = EXCLUDED.raw_total_reads,
            raw_total_bases = EXCLUDED.raw_total_bases,
            raw_q20_bases = EXCLUDED.raw_q20_bases,
            raw_q30_bases = EXCLUDED.raw_q30_bases,
            raw_q20_rate = EXCLUDED.raw_q20_rate,
            raw_q30_rate = EXCLUDED.raw_q30_rate,
            raw_read1_mean_length = EXCLUDED.raw_read1_mean_length,
            raw_read2_mean_length = EXCLUDED.raw_read2_mean_length,
            raw_gc_content = EXCLUDED.raw_gc_content,
            total_reads = EXCLUDED.total_reads,
            total_bases = EXCLUDED.total_bases,
            q20_bases = EXCLUDED.q20_bases,
            q30_bases = EXCLUDED.q30_bases,
            q20_rate = EXCLUDED.q20_rate,
            q30_rate = EXCLUDED.q30_rate,
            read1_mean_length = EXCLUDED.read1_mean_length,
            read2_mean_length = EXCLUDED.read2_mean_length,
            gc_content = EXCLUDED.gc_content;
        """
        params = {
            "og_id": row_dict["og_id"],  # TEXT / VARCHAR
            "mach": str(row_dict["mach"]) if row_dict["mach"] else None,  # TEXT (Ensure it's a string)
            "seq_date": str(row_dict["seq_date"]) if row_dict["seq_date"] else None,  # TEXT or DATE
            "initial": str(row_dict["initial"]) if row_dict["initial"] else None,  # TEXT       
            "passed_filter_reads": int(row_dict["passed_filter_reads"]) if row_dict["passed_filter_reads"] else 0,  # INTEGER
            "low_quality_reads": int(row_dict["low_quality_reads"]) if row_dict["low_quality_reads"] else 0,  # INTEGER
            "too_many_n_reads": int(row_dict["too_many_n_reads"]) if row_dict["too_many_n_reads"] else 0,  # INTEGER
            "too_short_reads": int(row_dict["too_short_reads"]) if row_dict["too_short_reads"] else 0,  # INTEGER
            "too_long_reads": int(row_dict["too_long_reads"]) if row_dict["too_long_reads"] else 0,  # INTEGER        
            "raw_total_reads": int(row_dict["raw_total_reads"]) if row_dict["raw_total_reads"] else 0,  # INTEGER
            "raw_total_bases": int(row_dict["raw_total_bases"]) if row_dict["raw_total_bases"] else 0,  # BIGINT
            "raw_q20_bases": int(row_dict["raw_q20_bases"]) if row_dict["raw_q20_bases"] else 0,  # BIGINT
            "raw_q30_bases": int(row_dict["raw_q30_bases"]) if row_dict["raw_q30_bases"] else 0,  # BIGINT        
            "raw_q20_rate": float(row_dict["raw_q20_rate"]) if row_dict["raw_q20_rate"] else 0.0,  # FLOAT
            "raw_q30_rate": float(row_dict["raw_q30_rate"]) if row_dict["raw_q30_rate"] else 0.0,  # FLOAT        
            "raw_read1_mean_length": int(row_dict["raw_read1_mean_length"]) if row_dict["raw_read1_mean_length"] else 0,  # INTEGER
            "raw_read2_mean_length": int(row_dict["raw_read2_mean_length"]) if row_dict["raw_read2_mean_length"] else 0,  # INTEGER        
            "raw_gc_content": float(row_dict["raw_gc_content"]) if row_dict["raw_gc_content"] else 0.0,  # FLOAT        
            "total_reads": int(row_dict["total_reads"]) if row_dict["total_reads"] else 0,  # INTEGER
            "total_bases": int(row_dict["total_bases"]) if row_dict["total_bases"] else 0,  # BIGINT
            "q20_bases": int(row_dict["q20_bases"]) if row_dict["q20_bases"] else 0,  # BIGINT
            "q30_bases": int(row_dict["q30_bases"]) if row_dict["q30_bases"] else 0,  # BIGINT       
            "q20_rate": float(row_dict["q20_rate"]) if row_dict["q20_rate"] else 0.0,  # FLOAT
            "q30_rate": float(row_dict["q30_rate"]) if row_dict["q30_rate"] else 0.0,  # FLOAT        
            "read1_mean_length": int(row_dict["read1_mean_length"]) if row_dict["read1_mean_length"] else 0,  # INTEGER
            "read2_mean_length": int(row_dict["read2_mean_length"]) if row_dict["read2_mean_length"] else 0,  # INTEGER        
            "gc_content": float(row_dict["gc_content"]) if row_dict["gc_content"] else 0.0,  # FLOAT
        }

        # Debugging Check
        print(f"Number of columns in query: {upsert_query.count('%s')}")
        print(f"Column names in DataFrame: {draft_genomes_fastp.columns.tolist()}")
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
