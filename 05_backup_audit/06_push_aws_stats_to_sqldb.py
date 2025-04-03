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
aws_stats = f"aws_stats/aws_stats.tsv"  # if your file structure is different this might not work.

# Import draft aws stats
print(f"Importing data from {aws_stats}")

# Load data
aws_df = pd.read_csv(aws_stats, sep="\t")

try:
    # Connect to PostgreSQL
    conn = psycopg2.connect(**db_params)
    cursor = conn.cursor()

    row_count = 0  # Track number of processed rows

    for index, row in aws_df.iterrows():
        values = tuple(row.values)

        # Extract primary key values
        og_id, seq_date = row["og_id"], row["seq_date"]

        # UPSERT: Insert if not exists, otherwise update
        upsert_query = """
        INSERT INTO draft_genomes (
            og_id, seq_date, aws_r1, aws_r1_size, aws_r2, aws_r2_size, aws_assm, aws_assm_size
        )
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
        ON CONFLICT (og_id, seq_date) DO UPDATE SET
            aws_r1 = EXCLUDED.aws_r1,
            aws_r1_size = EXCLUDED.aws_r1_size,
            aws_r2 = EXCLUDED.aws_r2,
            aws_r2_size = EXCLUDED.aws_r2_size,
            aws_assm = EXCLUDED.aws_assm,
            aws_assm_size = EXCLUDED.aws_assm_size;
        """
        params = (
            row["og_id"],  # TEXT / VARCHAR
            str(row["seq_date"]) if row["seq_date"] else None,  # TEXT or DATE
            str(row["aws_r1"]) if row["aws_r1"] else None,  # TEXT       
            int(row["aws_r1_size"]) if row["aws_r1_size"] else None,  # INTEGER
            str(row["aws_r2"]) if row["aws_r2"] else None,  # TEXT
            int(row["aws_r2_size"]) if row["aws_r2_size"] else None,  # INTEGER
            str(row["aws_assm"]) if row["aws_assm"] else None,  # TEXT
            int(row["aws_assm_size"]) if row["aws_assm_size"] else None,  # INTEGER        
        )

        # Debugging Check
        print(f"Number of columns in query: {upsert_query.count('%s')}")
        print(f"Number of values being passed: {len(values)}")
        print(f"Column names in DataFrame: {aws_df.columns.tolist()}")
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
