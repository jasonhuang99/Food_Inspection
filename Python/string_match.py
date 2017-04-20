# -*- coding: utf-8 -*-
"""
Created on Tue Mar 28 18:46:22 2017

@author: jasonhuang
"""
import pandas as pd
import timeit
from fuzzywuzzy import process
from manual import add_standardize, boro, add_number, get_top
import ast
import os, json

pkl_name = 'nyc_inspection.pkl'
pkl_path = '../../Data/Pickles/'
dta_path = '../../Data/DTA/'
csv_path = '../../Data/CSV/'
json_path = '../../Data/JSON/'
calls_311_path = '../../Data/311Calls/'
json_file = 'matched_dict.json'
start = timeit.default_timer()

if json_file in os.listdir(json_path):
    match_dict = json.load(open(json_path + json_file))
else:
    match_dict = {}

df_calls = pd.read_pickle(pkl_path + 'calls_merged.pkl')
df_des = pd.read_pickle(pkl_path + 'NYC_rest.pkl')
df_calls_missing = df_calls[df_calls['CAMIS'].isnull()]\
.groupby(['Orig_Add','Incident Zip','Incident Address'])\
['Unique Key'].min().reset_index()

df_list = []
for name, df in df_calls_missing.groupby('Incident Zip'):
    if name.isdigit():
        zip_list = df_des[df_des['ZIPCODE'] == float(name)]['ADDRESS'].tolist()
        zip_list = list(set(zip_list))        
        df['guess address'] = df['Incident Address'].apply(lambda x: 
            str(process.extractBests(x,zip_list)))
        df_list.append(df.copy())

df_calls_merge = pd.DataFrame().append(df_list, ignore_index = True)

df_calls_merge.sort_values('Incident Address', inplace = True)
df_calls_merge[['Orig_Add','Incident Address','Incident Zip','guess address']]\
.to_csv(csv_path + 'match_guess.csv',index = False)
        
df_calls_merge['add_num'] = df_calls_merge['Incident Address'].apply(add_number)
df_calls_merge['top guess']= df_calls_merge['guess address']\
.apply(get_top)

df_calls_merge['top guess add'] = df_calls_merge['top guess']\
                                  .apply(lambda x: x[0])
df_calls_merge['top guess score'] = df_calls_merge['top guess']\
                                  .apply(lambda x: x[1])
df_calls_merge['top guess num'] = df_calls_merge['top guess add']\
                               .apply(add_number)

df_calls_merge[df_calls_merge['top guess num'] == df_calls_merge['add_num']]\
.to_csv(csv_path + 'match_guess_same_num.csv', index = False)

for i, row in df_calls_merge[\
df_calls_merge['top guess num'] == df_calls_merge['add_num']].iterrows():
    if row['top guess score'] > 90:
        match_dict[row['Incident Address']] = row['top guess add']
        
with open(json_path + 'matched_dict.json', 'w') as fp:
    json.dump(match_dict,fp)
