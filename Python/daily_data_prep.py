# -*- coding: utf-8 -*-
"""
Created on Tue Apr 18 16:47:15 2017

@author: jasonhuang
"""

import pandas as pd
import timeit
#import numpy as np

pkl_name = 'nyc_inspection.pkl'
pkl_path = '../../Data/Pickles/'
dta_path = '../../Data/DTA/'
start = timeit.default_timer()

def days(x):
    return pd.datetime(x.year, x.month, x.day)
inspect_file = 'nyc_ind_inspect.pkl'
df = pd.read_pickle(pkl_path + inspect_file)
df = df[df['INSPDATE'] > pd.datetime(2010,10,1)]
df['INSPDATE'] = df['INSPDATE'].apply(days)
df['same_day_inspect'] = df.groupby(['CAMIS','INSPDATE'])\
['inspectionID'].transform('nunique')

df = df[df['same_day_inspect'] == 1]
del df['same_day_inspect']


camis_list = df['CAMIS'].unique()[:100]
df = df[df['CAMIS'].apply(lambda x: x in camis_list)]
df_camis_start_end = df.groupby('CAMIS').agg({'INSPDATE':['min','max']}).reset_index()

df_list = []

for name, df_g in df.groupby('CAMIS'):
    start = df_g['INSPDATE'].min()
    end = df_g['INSPDATE'].max()
    df_temp = pd.DataFrame(pd.date_range(start, end))
    df_temp.columns = ['INSPDATE']
    df_temp['CAMIS'] = name
    df_list.append(df_temp.copy())

df_days = pd.DataFrame().append(df_list, ignore_index = True)
df_days = df_days[['CAMIS','INSPDATE']]
print df_days.shape
df_days_new = df_days.merge(df, on = ['CAMIS','INSPDATE'], how = 'outer')
if df_days_new.shape[0] == df_days.shape[0]:
    print "same length!"
    df_days = df_days_new
    del df_days_new

df_days['first_event'] = df_days.groupby('CAMIS')['INSPDATE']\
.transform(lambda x: x.min())

df_days['since_last_event'] = df_days['INSPDATE'] - df_days['first_event']
df_days['since_last_event'] = df_days['since_last_event']\
.apply(lambda x: int(x.days))

df_days_filled = df_days.fillna(method = 'ffill')

df_days.to_stata('check.dta', convert_dates = {'INSPDATE':'td',
                                'CASE_DECISION_DATE':'td',
                                'first_event':'td'},
               write_index = False)
#df_days = df_days.merge(df, on = ['CAMIS',])
