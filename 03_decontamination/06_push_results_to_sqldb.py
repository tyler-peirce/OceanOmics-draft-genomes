import psycopg2
import pandas as pd
import numpy as np  # Required for handling infinity values

# run using: singularity run $SING/psycopg2:0.1.sif python 06_push_results_to_sqldb.py

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

# File containing tiara results
tiara_filter_report = f"../../{DATE}_results/{DATE}_tiara_filter_report.tsv"  # if your file structure is different this might not work.

# Import tiara results
print(f"Importing data from {tiara_filter_report}")

# Load data
tiara_df = pd.read_csv(tiara_filter_report, sep="\t")

# Define transform_data
def transform_data(tiara_df):
    # Pivot the data to get the desired format
    tiara_df_pivot = tiara_df.pivot(index="sample", columns="category", values=["num_contigs", "bp"])

    # Fill missing values with 0 to prevent NaN
    tiara_df_pivot = tiara_df_pivot.fillna(0)
    
    # Flatten the column names
    tiara_df_pivot.columns = [f"{col[0]}_{col[1].lower()}" for col in tiara_df_pivot.columns]
    tiara_df_pivot.reset_index(inplace=True)
    
    return tiara_df_pivot

# Define the read_and_transform variable
def read_and_transform(tiara_filter_report):
    tiara_df = pd.read_csv(tiara_filter_report, sep="\t")  # Assuming tab-separated values
    tiara_transformed_df = transform_data(tiara_df) 
    if 'sample' in tiara_transformed_df.columns:
        # Split 'sample' into three new columns
        tiara_transformed_df[['og_id', 'tech', 'seq_date']] = tiara_transformed_df['sample'].str.split('.', expand=True)
            
        print("File successfully processed! New columns added.")
    else:
        print("Error: 'sample' column not found in the input file.")
    return tiara_transformed_df
# Run the definied data transformations
tiara_df_transformed = read_and_transform(tiara_filter_report)
# Display transformed DataFrame
print(tiara_df_transformed)

try:
    # Connect to PostgreSQL
    conn = psycopg2.connect(**db_params)
    cursor = conn.cursor()

    row_count = 0  # Track number of processed rows

    for index, row in tiara_df_transformed.iterrows():
        row_dict = row.to_dict()

        # Extract primary key values
        og_id, seq_date = row_dict["og_id"], row_dict["seq_date"]

        # UPSERT: Insert if not exists, otherwise update
        upsert_query = """
        INSERT INTO draft_genomes (
            og_id, seq_date, num_contigs_mitochondrion, num_contigs_plastid, num_contigs_prokarya, bp_mitochondrion,
            bp_plastid, bp_prokarya
        )
        VALUES (
            %(og_id)s, %(seq_date)s, %(num_contigs_mitochondrion)s, %(num_contigs_plastid)s, %(num_contigs_prokarya)s, %(bp_mitochondrion)s,
            %(bp_plastid)s, %(bp_prokarya)s
        )   
        ON CONFLICT (og_id, seq_date)
        DO UPDATE SET
            num_contigs_mitochondrion = EXCLUDED.num_contigs_mitochondrion,
            num_contigs_plastid = EXCLUDED.num_contigs_plastid,
            num_contigs_prokarya = EXCLUDED.num_contigs_prokarya,
            bp_mitochondrion = EXCLUDED.bp_mitochondrion,
            bp_plastid = EXCLUDED.bp_plastid,
            bp_prokarya = EXCLUDED.bp_prokarya;
        """
        
        # Params as a dictionary as the columns arent in the right order
        params = {
            "og_id": row_dict["og_id"],
            "seq_date": row_dict["seq_date"],
            "num_contigs_mitochondrion": row_dict["num_contigs_mitochondrion"] if row_dict["num_contigs_mitochondrion"] is not None else None,
            "num_contigs_plastid": row_dict["num_contigs_plastid"] if row_dict["num_contigs_plastid"] is not None else None,
            "num_contigs_prokarya": row_dict["num_contigs_prokarya"] if row_dict["num_contigs_prokarya"] is not None else None,
            "bp_mitochondrion": row_dict["bp_mitochondrion"] if row_dict["bp_mitochondrion"] is not None else None,
            "bp_plastid": row_dict["bp_plastid"] if row_dict["bp_plastid"] is not None else None,
            "bp_prokarya": row_dict["bp_prokarya"] if row_dict["bp_prokarya"] is not None else None,
        }

        # Debugging Check
        #print(f"Number of columns in query: {upsert_query.count('%s')}")
        print(f"Number of rows being passed: {len(row)}")
        print(f"Column names in DataFrame: {tiara_df_transformed.columns.tolist()}")
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

print("Connection Closed")


# NCBI contig count
# File containing draft genome data
ncbi = f"../../{DATE}_results/{DATE}_NCBI_contig_count_500bp.tsv"  # if your file structure is different this might not work.

# Import draft genome data
print(f"Importing data from {ncbi}")

# Load data
ncbi_df = pd.read_csv(ncbi, sep="\t")

# Check and split 'sample' column
if 'sample' in ncbi_df.columns:
    # Split 'sample' into three new columns
    ncbi_df[['og_id', 'tech', 'seq_date']] = ncbi_df['sample'].str.split('.', expand=True)
    print("File successfully processed! New columns added.")
else:
    print("Error: 'sample' column not found in the input file.")

# Display transformed DataFrame
print(ncbi_df)


try:
    # Connect to PostgreSQL
    conn = psycopg2.connect(**db_params)
    cursor = conn.cursor()

    row_count = 0  # Track number of processed rows

    for index, row in ncbi_df.iterrows():
        row_dict = row.to_dict()

        # Extract primary key values
        og_id, seq_date = row_dict["og_id"], row_dict["seq_date"]

        # UPSERT: Insert if not exists, otherwise update
        upsert_query = """
        INSERT INTO draft_genomes (
            og_id, seq_date, num_contigs
        )
        VALUES (
            %(og_id)s, %(seq_date)s, %(num_contigs)s
        )   
        ON CONFLICT (og_id, seq_date)
        DO UPDATE SET
            num_contigs = EXCLUDED.num_contigs;
        """
        
        # Params as a dictionary as the columns arent in the right order
        params = {
            "og_id": row_dict["og_id"],
            "seq_date": row_dict["seq_date"],
            "num_contigs": row_dict["num_contigs"],
        }

        # Debugging Check
        #print(f"Number of columns in query: {upsert_query.count('%s')}")
        print(f"Number of rows being passed: {len(row)}")
        print(f"Column names in DataFrame: {ncbi_df.columns.tolist()}")
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

print("Connection Closed")

















# # NCBI - currently not including in db but if we do this is the num_contigs_mitochondrion to transform the data
# # File containing draft genome data
# ncbi_filter_report = f"../../{DATE}_results/{DATE}_NCBI_filter_report.tsv"  # if your file structure is different this might not work.

# # Import draft genome data
# print(f"Importing data from {ncbi_filter_report}")

# # Load data
# ncbi_df = pd.read_csv(ncbi_filter_report, sep="\t")

# # Define transform_data
# def transform_data(ncbi_df):
#     # Pivot the data to get the desired format
#     ncbi_df_pivot = ncbi_df.pivot(index="sample", columns="category", values=["num_contigs", "bp"])
    
#     # Flatten the column names
#     ncbi_df_pivot.columns = [f"{col[0]}_{col[1].lower()}" for col in ncbi_df_pivot.columns]
#     ncbi_df_pivot.reset_index(inplace=True)
    
#     return ncbi_df_pivot

# # Define the read_and_transform variable
# def read_and_transform(ncbi_filter_report):
#     ncbi_df = pd.read_csv(ncbi_filter_report, sep="\t")  # Assuming tab-separated values
#     ncbi_transformed_df = transform_data(ncbi_df)
#     return ncbi_transformed_df

# # Run the definied data transformations
# ncbi_df_transformed = read_and_transform(ncbi_filter_report)
# # Display transformed DataFrame
# print(ncbi_df_transformed)
















