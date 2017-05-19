# -*- coding: utf-8 -*-
"""
Created on Mon May  1 14:14:57 2017

Append together geocoded address csv files
@author: jasonhuang
"""

import pandas as pd
import os

batch_matched_path = "../../Data/CSV/Batch_Matched/"
pkl_path = '../../Data/Pickles/'
dta_path = '../../Data/DTA/'

df_nyc_rest = pd.read_pickle(pkl_path + 'NYC_rest.pkl')
df_nyc_rest = df_nyc_rest[df_nyc_rest['ZIPCODE'].notnull()]
def comb_add(x):
    add = x['address'] + ', ' + x['boro'] \
    + ', New York, ' + str(int(x['ZIPCODE']))
    if '27' in add and 'MORTON' in add and '10014' in add:
        return '27 12 MORTON ST, Manhattan, New York, 10014'
    if '176' in add and 'MULBERRY ST' in add and '10013' in add:
        return '176 12 MULBERRY ST, Manhattan, New York, 10013'
    return add
df_nyc_rest['address_orig'] = df_nyc_rest.apply(comb_add,1)
columns = ['index','address_orig','match','status','address_match','longlat',
           'tigerline','Letter','ST','County','tract','block']


files = os.listdir(batch_matched_path)

df_list = []
for f in files:

    df = pd.read_csv(batch_matched_path + f, header =None,
                     names = columns)
    df_list.append(df.copy())

df = pd.DataFrame().append(df_list, ignore_index = True)
df = df[df['address_orig'].notnull()]

df_merge = df.merge(df_nyc_rest, on = 'address_orig', how = 'left')
print "Check every geocoded address found in original data", \
df_merge[df_merge['CAMIS'].isnull()].shape

minmax = ['min','max']
agg_dict = {}
info_col = ['ST','County','tract','block','CAMIS']
for c in info_col:
    agg_dict[c] = minmax
df_add = df_merge.groupby('address_orig').agg(agg_dict).reset_index()

for c in info_col:
    print c
    print df_add[(df_add[c]['min'] != df_add[c]['max']) & \
                 (df_add[c]['min'].notnull()) \
                 & (df_add[c]['max'].notnull())][c][minmax]
    df_add = df_add[(df_add[c]['min'] == df_add[c]['max']) & \
                 (df_add[c]['min'].notnull()) \
                 & (df_add[c]['max'].notnull())]
    del df_add[(c,'min')]

df_add.columns = [i[0] for i in df_add.columns.values]
df_add.sort_values('CAMIS', inplace = True)
df_add.to_stata(dta_path + 'geocoded_camis.dta', write_index = False)