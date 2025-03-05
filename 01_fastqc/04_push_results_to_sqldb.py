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
        values = tuple(row.values)

        # Extract primary key values
        og_id, seq_date = row["og_id"], row["seq_date"]

        # UPSERT: Insert if not exists, otherwise update
        upsert_query = """
        INSERT INTO draft_genomes (
            og_id, passed_filter_reads, low_quality_reads, too_many_n_reads, too_short_reads, too_long_reads,
            raw_total_reads, raw_total_bases, raw_q20_bases, raw_q30_bases, raw_q20_rate, raw_q30_rate, raw_read1_mean_length, raw_read2_mean_length,
            raw_gc_content, total_reads, total_bases, q20_bases, q30_bases, q20_rate, q30_rate, read1_mean_length, read2_mean_length, gc_content, mach, seq_date, initial
        )
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
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
        params = (
            row["og_id"],  # TEXT / VARCHAR
            str(row["mach"]) if row["mach"] else None,  # TEXT (Ensure it's a string)
            str(row["seq_date"]) if row["seq_date"] else None,  # TEXT or DATE
            str(row["initial"]) if row["initial"] else None,  # TEXT       
            int(row["passed_filter_reads"]) if row["passed_filter_reads"] else 0,  # INTEGER
            int(row["low_quality_reads"]) if row["low_quality_reads"] else 0,  # INTEGER
            int(row["too_many_n_reads"]) if row["too_many_n_reads"] else 0,  # INTEGER
            int(row["too_short_reads"]) if row["too_short_reads"] else 0,  # INTEGER
            int(row["too_long_reads"]) if row["too_long_reads"] else 0,  # INTEGER        
            int(row["raw_total_reads"]) if row["raw_total_reads"] else 0,  # INTEGER
            int(row["raw_total_bases"]) if row["raw_total_bases"] else 0,  # BIGINT
            int(row["raw_q20_bases"]) if row["raw_q20_bases"] else 0,  # BIGINT
            int(row["raw_q30_bases"]) if row["raw_q30_bases"] else 0,  # BIGINT        
            float(row["raw_q20_rate"]) if row["raw_q20_rate"] else 0.0,  # FLOAT
            float(row["raw_q30_rate"]) if row["raw_q30_rate"] else 0.0,  # FLOAT        
            int(row["raw_read1_mean_length"]) if row["raw_read1_mean_length"] else 0,  # INTEGER
            int(row["raw_read2_mean_length"]) if row["raw_read2_mean_length"] else 0,  # INTEGER        
            float(row["raw_gc_content"]) if row["raw_gc_content"] else 0.0,  # FLOAT        
            int(row["total_reads"]) if row["total_reads"] else 0,  # INTEGER
            int(row["total_bases"]) if row["total_bases"] else 0,  # BIGINT
            int(row["q20_bases"]) if row["q20_bases"] else 0,  # BIGINT
            int(row["q30_bases"]) if row["q30_bases"] else 0,  # BIGINT       
            float(row["q20_rate"]) if row["q20_rate"] else 0.0,  # FLOAT
            float(row["q30_rate"]) if row["q30_rate"] else 0.0,  # FLOAT        
            int(row["read1_mean_length"]) if row["read1_mean_length"] else 0,  # INTEGER
            int(row["read2_mean_length"]) if row["read2_mean_length"] else 0,  # INTEGER        
            float(row["gc_content"]) if row["gc_content"] else 0.0,  # FLOAT
        )

        # Debugging Check
        print(f"Number of columns in query: {upsert_query.count('%s')}")
        print(f"Number of values being passed: {len(values)}")
        print(f"Column names in DataFrame: {draft_genomes_fastp.columns.tolist()}")
        print("Values:", values)

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
