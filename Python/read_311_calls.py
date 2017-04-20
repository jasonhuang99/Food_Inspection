# -*- coding: utf-8 -*-
"""
Created on Tue Mar 28 20:02:41 2017

@author: jasonhuang
"""

import pandas as pd

pkl_name = 'nyc_inspection.pkl'
pkl_path = '../../Data/Pickles/'
dta_path = '../../Data/DTA/'
csv_path = '../../Data/CSV/'
calls_311_path = '../../Data/311Calls/'

df_calls = pd.read_csv(calls_311_path + '311_3_07_rest.csv',
                       low_memory = False)
                       
df_calls['Created Date'] = df_calls['Created Date'].apply(pd.to_datetime)
df_calls['Closed Date'] = df_calls['Closed Date'].apply(pd.to_datetime)

df_calls.to_pickle(pkl_path + 'calls.pkl')