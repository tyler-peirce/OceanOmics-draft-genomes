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

# File containing draft genome data
tiara_filter_report = f"../../{DATE}_results/{DATE}_tiara_filter_report.tsv"  # if your file structure is different this might not work.

# Import draft genome data
print(f"Importing data from {tiara_filter_report}")

# Load data
tiara_df = pd.read_csv(tiara_filter_report, sep="\t")

# Define transform_data
def transform_data(tiara_df):
    # Pivot the data to get the desired format
    tiara_df_pivot = tiara_df.pivot(index="sample", columns="category", values=["num_contigs", "bp"])
    
    # Flatten the column names
    tiara_df_pivot.columns = [f"{col[0]}_{col[1].lower()}" for col in tiara_df_pivot.columns]
    tiara_df_pivot.reset_index(inplace=True)
    
    return tiara_df_pivot

# Define the read_and_transform variable
def read_and_transform(tiara_filter_report):
    tiara_df = pd.read_csv(tiara_filter_report, sep="\t")  # Assuming tab-separated values
    tiara_transformed_df = transform_data(tiara_df)
    return tiara_transformed_df

# Run the definied data transformations
tiara_df_transformed = read_and_transform(tiara_filter_report)
# Display transformed DataFrame
print(tiara_df_transformed)















