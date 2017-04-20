# -*- coding: utf-8 -*-
"""
Created on Thu Mar 30 16:03:38 2017

@author: jasonhuang
"""

import pandas as pd
import timeit
from fuzzywuzzy import process
from manual import add_standardize, boro, add_number, get_top
import ast

pkl_name = 'nyc_ind_inspect.pkl'
pkl_path = '../../Data/Pickles/'
dta_path = '../../Data/DTA/'
csv_path = '../../Data/CSV/'
single_name = 'single_add_camis.pkl'
calls_name = 'calls_matched.pkl'
df_inspect = pd.read_pickle(pkl_path + pkl_name)
df_deduped = pd.read_pickle(pkl_path + single_name)
df_calls = pd.read_pickle(pkl_path + calls_name)

df_inspect = df_deduped.merge(df_inspect,on = 'CAMIS',how = 'left')
df_inspect = df_inspect[df_inspect['INSPDATE'] > pd.datetime(2010,10,1)]

print "Relevant Inspections", df_inspect.shape

## Choose left since some calls are matched to ambiguous address 
## Must be JFK
df_inspect = df_inspect.merge(df_calls, on = 'CAMIS', how = 'left')

df_inspect = df_inspect[(df_inspect['Created Date'].isnull()) | \
(df_inspect['INSPDATE'] <= df_inspect['Created Date'])]

df_inspect.to_csv(csv_path + 'calls_merged.csv', index = False)
