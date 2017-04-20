# -*- coding: utf-8 -*-
"""
Created on Tue Feb  7 13:32:59 2017

@author: jasonhuang
"""

import pandas as pd
import numpy as np
#import matplotlib.pyplot as plt

inspect_data = 'nyc_ind_inspect.pkl'
pkl_path = '../../Data/Pickles/'
df = pd.read_pickle(inspect_data)
#dta_path = 'Data/DTA/'
df.sort_values(['CAMIS','INSPDATE'],inplace = True)

df['next'] = df.groupby('CAMIS')['INSPDATE'].transform(lambda x: x.shift(-1))

df['next_type'] = \
df.groupby('CAMIS')['INSPTYPE'].transform(lambda x: x.shift(-1))

df['next_inspector'] = \
df.groupby('CAMIS')['InspectorID'].transform(lambda x: x.shift(-1))


def LO(x):
    return (sum(x) - x)/(len(x) - 1)
df['LO_avg_score'] = \
df.groupby('InspectorID')['SCORE'].transform(LO)
df['next_score'] = \
df.groupby('CAMIS')['SCORE'].transform(lambda x: x.shift(-1))

df['next_inspector'] = \
df.groupby('CAMIS')['InspectorID'].transform(lambda x: x.shift(-1))

df['inspect_sum'] = \
df.groupby('InspectorID')['SCORE'].transform(sum)

df['inspect_cnt'] = \
df.groupby('InspectorID')['SCORE'].transform(len)

df['inspect_rest_sum'] = \
df.groupby(['InspectorID','CAMIS'])['SCORE'].transform(sum)

df['inspect_rest_cnt'] = \
df.groupby(['InspectorID','CAMIS'])['SCORE'].transform(len)

def LO_score(x):
    n = (x['inspect_sum'] - x['inspect_rest_sum'])
    d = (x['inspect_cnt'] - x['inspect_rest_cnt'])
    if d == 0:
        return np.NaN
    else:
        return n/d
    
df['LO_SCORE'] = df.apply(LO_score,1)

df_inspector = df.groupby('InspectorID').agg({'SCORE':['mean','median']})
def status(x):
    if pd.isnull(x['next']) and x['INSPDATE'] <= pd.datetime(2015,10,1):
        return 0
    else:
        return 1

df['open'] = df.apply(status,1)

'''
df.to_stata(dta_path + 'nyc_inspect_shift.dta',
               convert_dates = {'INSPDATE':'td',
                                'CASE_DECISION_DATE':'td',
                                'next':'td'},
               write_index = False)
'''