"""
sort_tasks.py ensures marker CSV rows are ordered by task number so downstream scripts
that expect task-ordered rows operate correctly. The function preserves
all timestamps and other columns; it only reorders rows.


Author:
Mario Lobo (UPM)
mario.lobo.alonso@alumnos.upm.es
Version:
28-10-2025
"""




import pandas as pd

def sort_tasks(input_path: str, output_path: str):
    """
    Sort marker CSV rows by numeric task index extracted from the 'Task' column so other scripts can process them correctly.

    Args:
        input_path (str): Path to the input CSV file. Must contain a 'Task' column
                        whose entries include a numeric portion (e.g., 'Task-3').
        output_path (str): Path where the sorted CSV will be written.

    Returns:
        None (writes the sorted CSV to output_path).

    Details:
        - Loads the CSV with pandas.read_csv.
        - Uses df.sort_values with a key that extracts digits from the 'Task' column
        (regex r'(\d+)') and converts them to int for numeric sort order.
        - Writes the sorted DataFrame with df.to_csv(index=False).
        - This function keeps all other columns intact (timestamps, markers, etc.).
    """
    
    # Load CSV
    df = pd.read_csv(input_path, sep=",")

    # Order Rows by Task Column
    df = df.sort_values(by="Task", key=lambda x: x.str.extract(r'(\d+)').iloc[:,0].astype(int))

    # Save the CSV
    df.to_csv(output_path, index=False)

    print(f"{input_path} sorted and saved in {output_path}")