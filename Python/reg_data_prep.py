# -*- coding: utf-8 -*-
"""
Created on Thu Feb 16 11:33:49 2017

@author: jasonhuang
"""

import pandas as pd
import timeit
#import numpy as np
from functions import group, status, LO, LO_score

pkl_name = 'nyc_inspection.pkl'
pkl_path = '../../Data/Pickles/'
dta_path = '../../Data/DTA/'
start = timeit.default_timer()
df = pd.read_pickle(pkl_path + pkl_name)

inspect_file = 'nyc_ind_inspect.pkl'
df_inspect = pd.read_pickle(pkl_path + inspect_file)
df_inspect.sort_values(['CAMIS','INSPDATE'],inplace = True)
df['CASE_DECISION_DATE'] = df['CASE_DECISION_DATE'].apply(lambda x: \
    pd.datetime(1900,1,1) if pd.isnull(x) else x)

df = df[df['PROGRAM'].apply(lambda x: x == 'FS' or x == 'PP')]
read = timeit.default_timer()
print read - start

df['group'] = df['VIOLCODE'].apply(group)
groups = df[df['group'].notnull()]['group'].unique()
codes = df[df['VIOLCODE'].notnull()]['VIOLCODE'].unique()

for g in groups:
    print g
    df_code = df[df['group'] == g]\
    .groupby(['inspectionID'])['SCORE']\
    .count().reset_index()
    df_code.rename(columns = {'SCORE':'FOUND'},inplace = True)
    df_inspect = df_inspect.merge(df_code,
                              on = 'inspectionID',
                              how = 'left')
    df_inspect[g] = df_inspect['FOUND'].apply(pd.notnull)
    df_inspect[g+'_cnt'] = df_inspect['FOUND']\
    .apply(lambda x: 0 if pd.isnull(x) else x)
    del df_inspect['FOUND']
    '''
    df_inspect['inspect_sum'] = \
    df_inspect.groupby('InspectorID')[g].transform(sum)
    
    df_inspect['inspect_cnt'] = \
    df_inspect.groupby('InspectorID')['SCORE'].transform(len)
    
    df_inspect['inspect_rest_sum'] = \
    df_inspect.groupby(['InspectorID','CAMIS'])[g].transform(sum)
    
    df_inspect['inspect_rest_cnt'] = \
    df_inspect.groupby(['InspectorID','CAMIS'])['SCORE'].transform(len)
    df_inspect[g + 'LO'] = df_inspect.apply(LO_score,1)
    '''

'''
for c in ['02G','10B','06C','06D','04L','02B','04M','04N','10G',
          '06E','10F','10G']:
    print c
    df_code = df[df['VIOLCODE'] == c]\
    .groupby(['inspectionID'])['SCORE']\
    .count().reset_index()
    df_code.rename(columns = {'SCORE':'FOUND'},inplace = True)
    df_inspect = df_inspect.merge(df_code,
                              on = 'inspectionID',
                              how = 'left')
    df_inspect[c] = df_inspect['FOUND'].apply(pd.notnull)
    del df_inspect['FOUND']
    
    df_inspect['inspect_sum'] = \
    df_inspect.groupby('InspectorID')[c].transform(sum)
    
    df_inspect['inspect_cnt'] = \
    df_inspect.groupby('InspectorID')['SCORE'].transform(len)
    
    df_inspect['inspect_rest_sum'] = \
    df_inspect.groupby(['InspectorID','CAMIS'])[c].transform(sum)
    
    df_inspect['inspect_rest_cnt'] = \
    df_inspect.groupby(['InspectorID','CAMIS'])['SCORE'].transform(len)
    df_inspect[c + 'LO'] = df_inspect.apply(LO_score,1)
'''

rename = {}
for c in codes:
    rename[c] = '_' + c
    rename[c + 'LO'] = 'LO_' + c

for g in groups:
    rename[g] = g.replace(' ','_').replace('/','_')
    #rename[g + 'LO'] = 'LO_' + g.replace(' ','_').replace('/','_')
    rename[g + '_cnt'] = rename[g] + '_cnt'
df_inspect.rename(columns = rename, inplace = True)

df_inspect['next'] = df_inspect.groupby('CAMIS')['INSPDATE']\
.transform(lambda x: x.shift(-1))

df_inspect['next_type'] = \
df_inspect.groupby('CAMIS')['INSPTYPE'].transform(lambda x: x.shift(-1))

df['next_inspector'] = \
df.groupby('CAMIS')['InspectorID'].transform(lambda x: x.shift(-1))

df_inspect['last'] = df_inspect.groupby('CAMIS')['INSPDATE']\
.transform(lambda x: x.shift(1))

df_inspect['last_type'] = df_inspect.groupby('CAMIS')['INSPTYPE']\
.transform(lambda x: x.shift(1))

df_inspect['last_score'] = df_inspect.groupby('CAMIS')['SCORE']\
.transform(lambda x: x.shift(1))

df_inspect['first'] = df_inspect.groupby('CAMIS')['INSPDATE']\
.transform('min')

df_inspect['first_program'] = df_inspect.groupby('CAMIS')['PROGRAM']\
.transform('first')

df_inspect['LO_avg_score'] = \
df_inspect.groupby('InspectorID')['SCORE'].transform(LO)

df_inspect['next_score'] = \
df_inspect.groupby('CAMIS')['SCORE'].transform(lambda x: x.shift(-1))

df_inspect['next_inspector'] = \
df_inspect.groupby('CAMIS')['InspectorID'].transform(lambda x: x.shift(-1))

df_inspect['inspect_sum'] = \
df_inspect.groupby('InspectorID')['SCORE'].transform(sum)

df_inspect['inspect_cnt'] = \
df_inspect.groupby('InspectorID')['SCORE'].transform(len)

df_inspect['inspect_rest_sum'] = \
df_inspect.groupby(['InspectorID','CAMIS'])['SCORE'].transform(sum)

df_inspect['inspect_rest_cnt'] = \
df_inspect.groupby(['InspectorID','CAMIS'])['SCORE'].transform(len)

df_inspect['LO_SCORE'] = df_inspect.apply(LO_score,1)

df_inspect['LO_SCORE_last'] = \
df_inspect.groupby('CAMIS')['LO_SCORE'].transform(lambda x: x.shift(1))

df_inspector = df_inspect.groupby('InspectorID')\
.agg({'SCORE':['mean','median']})

df_inspect['open'] = df_inspect.apply(status,1)

df_inspect.to_stata(dta_path + 'code.dta',
               convert_dates = {'INSPDATE':'td',
                                'CASE_DECISION_DATE':'td',
                                'next':'td','last':'td','first':'td'},
               write_index = False)
