# -*- coding: utf-8 -*-
"""
Created on Sun Feb  5 14:21:25 2017
Data integrity check
@author: jasonhuang
"""

import pandas as pd
import timeit
from fuzzywuzzy import utils

pkl_name = 'nyc_inspection.pkl'
start = timeit.default_timer()
pkl_path = '../../Data/Pickles/'
df = pd.read_pickle(pkl_path + pkl_name)
df['CASE_DECISION_DATE'] = df['CASE_DECISION_DATE'].apply(lambda x: \
    pd.datetime(1900,1,1) if pd.isnull(x) else x)

df = df[df['PROGRAM'].apply(lambda x: x == 'FS' or x == 'PP')]
read = timeit.default_timer()
print read - start

min_max = ['min','max']

agg_dict = {}
for var in ['SCORE','InspectorID','PROGRAM','INSPDATE','INSPTYPE',
            'CASE_DECISION_DATE','CAMIS','MOD_TOTALSCORE']:
    agg_dict[var] = min_max

agg_dict['VIOLSCORE'] = 'sum'

df_id = df.groupby('inspectionID').agg({'SCORE':min_max,
        'InspectorID':min_max,'VIOLSCORE':'sum','PROGRAM':min_max,
        'INSPDATE':min_max,'INSPTYPE':min_max,
        'CASE_DECISION_DATE':min_max,'CAMIS':min_max,
        'MOD_TOTALSCORE':min_max,'ACTION':min_max}).reset_index()
df_id.columns = ['_'.join(col).strip() for col in df_id.columns.values]
df_id.rename(columns = {'inspectionID_':'inspectionID'},inplace = True)

df_des = df[df['cuisine'].notnull()].groupby('CAMIS').agg({'cuisine':'min',
                            'DBA':'min','ZIPCODE':'min','venuecode':'min',
                            'servicecode':'min','venue':'min','ADDRESS':'min',
                            'ServiceDescription':'min','BORO':'min',
                            'chain_restaurant':'min'}).reset_index()

def standardize_cuisine(x):
    x = utils.asciidammit(x)
    if 'italian' in x.lower() or 'pizza' in x.lower():
        return 'Pizza/Italian'
    if 'latin' in x.lower():
        return 'Latin'
    if 'cafe' in x.lower() or 'tea' in x.lower() or 'coffee' in x.lower():
        return 'Cafe/Coffee/Tea'
    return x
df_des['DBA'] = df_des['DBA'].apply(utils.asciidammit)
df_des['cuisine'] = df_des['cuisine'].apply(standardize_cuisine)

group = timeit.default_timer()
print group - read

columns = ['INSPDATE','SCORE','INSPTYPE','CASE_DECISION_DATE',
           'InspectorID','CAMIS','MOD_TOTALSCORE','PROGRAM','ACTION']

for var in columns:
    print var
    disp = df_id[(df_id[var + '_min'] != df_id[var + '_max']) & 
    (df_id[var + '_min'].notnull()) & (df_id[var + '_max'].notnull())].shape
    print disp
    if disp > 0:
        df_id = df_id[df_id[var + '_min'] == df_id[var + '_max']]
        
rename_dict = {}
for c in columns:
    del df_id[c+'_min']
    rename_dict[c+'_max'] = c

df_id.rename(columns = rename_dict,inplace = True) 
df_id = df_id.merge(df_des,on = 'CAMIS', how = 'left')


def replace_score(x):
    if pd.isnull(x['SCORE']) and pd.notnull(x['VIOLSCORE_sum']) \
    and x['VIOLSCORE_sum'] == 0.0:
        return 0.0
    else:
        return x['SCORE']

def replace_vio(x):
    if pd.isnull(x['VIOLSCORE_sum']) and pd.notnull(x['SCORE']) \
    and x['SCORE'] == 0.0:
        return 0.0
    else:
        return x['VIOLSCORE_sum']

df_id['year'] = df_id['INSPDATE'].apply(lambda x: x.year)

def change_name(x):
    try:
        return utils.asciidammit(x)
    except:
        print x
        return x

df_id['venue'] = df_id['venue'].apply(utils.asciidammit)
df_id['ServiceDescription'] = \
df_id['ServiceDescription'].apply(utils.asciidammit)

df_id.to_pickle(pkl_path + 'nyc_ind_inspect.pkl')
df_id.to_csv('nyc_ind_inspect.csv',index = False)
df_id.to_stata('nyc_ind_inspect.dta',
               convert_dates = {'INSPDATE':'td',
                                'CASE_DECISION_DATE':'td'},
               write_index = False)

df_inspect = df.groupby('InspectorID')['inspectionID'].nunique().reset_index()