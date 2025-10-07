import pandas as pd

def sort_tasks(input_path: str, output_path: str):
    '''
    This function sorts a tasks marker CSV regarding its task number. It is mandatory due to the functioning of the rest of the code and functions.
    However, the asociated timestamps are kept to the taks, so no there is no information lost
    Args:
        input_path (str): Path to the not sorted csv
        output_path (str): Path to the sorted csv
    
    Returns:
        None
    '''
    
    #Load CSV
    df = pd.read_csv(input_path, sep=",")

    # Order Rows by Task Column
    df = df.sort_values(by="Task", key=lambda x: x.str.extract(r'(\d+)').iloc[:,0].astype(int))

    # Save the CSV
    df.to_csv(output_path, index=False)

    print(f"{input_path} sorted and saved in {output_path}")