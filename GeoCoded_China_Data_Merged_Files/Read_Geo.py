import numpy as np
import pandas as pd


def read_xlsx(excel_file: str):
    fin_geo = pd.read_excel(excel_file, sheet_name = 0)
    print(fin_geo.head())
    print(fin_geo.describe())
    print(fin_geo.dtypes)

def read_csv(csv_file: str):
    fin_geo = pd.read_csv(csv_file)
    print(fin_geo.head())
    print(fin_geo.dtypes)

if __name__== '__main__':
    fin_geo = read_csv('all_flow_classes.csv')