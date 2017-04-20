# -*- coding: utf-8 -*-
"""
Created on Sun Feb  5 13:51:05 2017

@author: jasonhuang
"""

import pandas as pd
from fuzzywuzzy import utils

f_name = "NYC_restaurant_inspections_0707_0916.txt"
header = "NYC_Restaurant_data_column_headings.txt"
pkl_name = 'nyc_inspection.pkl'

df = pd.read_table(f_name,header = None,low_memory = False)

df_header = pd.read_table(header)

df.columns = df_header.columns

df['INSPDATE'] = df['INSPDATE'].apply(pd.to_datetime)
df['CASE_DECISION_DATE'] = df['CASE_DECISION_DATE'].apply(pd.to_datetime)
df['CAMIS'] = df['CAMIS'].apply(utils.asciidammit)
df['CAMIS'] = df['CAMIS'].apply(int)
def convert_int(x):
    if x == '1OO36':
        return 10036
    if pd.notnull(x):
        return int(x)
    else:
        -1
    
df['ZIPCODE'] = df['ZIPCODE'].apply(convert_int)
df.to_pickle(pkl_name)
'''
df_id = df.groupby(['CAMIS','INSPDATE']).agg({'InspectorID':['min','max'],
            'SCORE'}).reset_index()
'''