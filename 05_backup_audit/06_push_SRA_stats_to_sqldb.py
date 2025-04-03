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


# File containing stats from aws for draft genome files
aws_stats = f"aws_stats/SRA_stats.tsv"  # if your file structure is different this might not work.

# Import draft aws stats
print(f"Importing data from {aws_stats}")

# Define transform_data
def transform_data(aws_df):
    # Pivot the data to get the desired format
    aws_df_pivot = aws_df.pivot(index=["og_id","seq_date"], columns="r", values=["base", "size"]) 
    
    # Rename the MultiIndex columns based on your custom logic
    new_columns = []
    for val, read in aws_df_pivot.columns:
        if val == "base":
            new_col = f"sra_{read.lower()}"  # e.g., sra_r1
        elif val == "size":
            new_col = f"sra_{read.lower()}_size"  # e.g., sra_r1_size
        else:
            new_col = f"{val}_{read}"  # fallback just in case
        new_columns.append(new_col)

    aws_df_pivot.columns = new_columns
    
    # Optional: reset index so 'og_id' and 'seq_date' become columns
    aws_df_pivot = aws_df_pivot.reset_index()

    # Reorder columns
    desired_order = ["og_id", "seq_date", "sra_r1", "sra_r1_size", "sra_r2", "sra_r2_size"]
    aws_df_pivot = aws_df_pivot[desired_order]
    
    return aws_df_pivot

# Define the read_and_transform variable
def read_and_transform(aws_stats):
    aws_df = pd.read_csv(aws_stats, sep="\t")  # Assuming tab-separated values
    aws_transformed_df = transform_data(aws_df) 
    return aws_transformed_df

# Run the definied data transformations
aws_df_transformed = read_and_transform(aws_stats)
# Display transformed DataFrame
print(aws_df_transformed)

try:
    # Connect to PostgreSQL
    conn = psycopg2.connect(**db_params)
    cursor = conn.cursor()

    row_count = 0  # Track number of processed rows

    for index, row in aws_df_transformed.iterrows():
        values = tuple(row.values)

        # Extract primary key values
        og_id, seq_date = row["og_id"], row["seq_date"]

        # UPSERT: Insert if not exists, otherwise update
        upsert_query = """
        INSERT INTO draft_genomes (
            og_id, seq_date, sra_r1, sra_r1_size, sra_r2, sra_r2_size
        )
        VALUES (%s, %s, %s, %s, %s, %s)
        ON CONFLICT (og_id, seq_date) DO UPDATE SET
            sra_r1 = EXCLUDED.sra_r1,
            sra_r1_size = EXCLUDED.sra_r1_size,
            sra_r2 = EXCLUDED.sra_r2,
            sra_r2_size = EXCLUDED.sra_r2_size;
        """
        params = (
            row["og_id"],  # TEXT / VARCHAR
            str(row["seq_date"]) if row["seq_date"] else None,  # TEXT or DATE
            str(row["sra_r1"]) if row["sra_r1"] else None,  # TEXT       
            int(row["sra_r1_size"]) if row["sra_r1_size"] else None,  # INTEGER
            str(row["sra_r2"]) if row["sra_r2"] else None,  # TEXT
            int(row["sra_r2_size"]) if row["sra_r2_size"] else None,  # INTEGER       
        )

        # Debugging Check
        print(f"Number of columns in query: {upsert_query.count('%s')}")
        print(f"Number of values being passed: {len(values)}")
        print(f"Column names in DataFrame: {aws_df_transformed.columns.tolist()}")
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
