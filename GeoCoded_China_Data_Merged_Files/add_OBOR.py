from OBOR_country_list import OBOR_country_list_str
import country_converter
import pandas as pd
import  numpy as np

def str_to_list(OBOR_country_list_str: str):
    OBOR_country_list = [country.strip() for country in OBOR_country_list_str.split(',')]
    return OBOR_country_list

def list_to_iso3(OBOR_country_list: list):

    OBOR_country_iso3 = country_converter.convert(names=OBOR_country_list, to= 'ISO3')
    if len(OBOR_country_iso3)==len(OBOR_country_list):
        return OBOR_country_iso3
    else:
        return None

def add_to_stata(OBOR_country_iso3):
    df = pd.read_stata('all_flow_unique_projects.dta')
    df['OBOR'] = np.where(df['recipient_iso3'].isin(OBOR_country_iso3), 1,0)
    df['OBOR'] = df['OBOR'].astype('int64')
    df.to_stata('all_flow_unique_projects_OBOR.dta',version=117)
    print('OBOR written in Stata')

if __name__== '__main__':
    OBOR_country_list = str_to_list(OBOR_country_list_str)
    OBOR_country_iso3 = list_to_iso3(OBOR_country_list)
    add_to_stata(OBOR_country_iso3)