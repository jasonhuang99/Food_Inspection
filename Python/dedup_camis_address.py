# -*- coding: utf-8 -*-
"""
Created on Wed Mar 29 19:40:56 2017
This file eliminate restaurants that sit on the same address, and the
inspection span overlap each other
@author: jasonhuang
"""

import pandas as pd
import timeit
from fuzzywuzzy import process
from manual import add_standardize, boro, add_number, get_top
import ast


pkl_name = 'nyc_inspection.pkl'
pkl_path = '../../Data/Pickles/'
dta_path = '../../Data/DTA/'
csv_path = '../../Data/CSV/'
calls_311_path = '../../Data/311Calls/'
start = timeit.default_timer()

### Create Restaurant Level Data ############################
inspect_file = 'nyc_ind_inspect.pkl'

df_inspect = pd.read_pickle(pkl_path + inspect_file)

df_des = df_inspect.groupby('CAMIS').agg({'ADDRESS':min,
                                'ZIPCODE':min,'DBA':min,
                                'BORO':min,
                                'INSPDATE':['min','max']}).reset_index()
df_des.columns = [' '.join(col).strip() for col in df_des.columns.values]
rename_dict = {'DBA min':'DBA','BORO min':'BORO',
               'ZIPCODE min': 'ZIPCODE', 'ADDRESS min': 'ADDRESS'}
df_des.rename(columns = rename_dict, inplace = True)

df_des['address'] = df_des['ADDRESS'].apply(add_standardize)
df_des['boro'] = df_des['BORO'].apply(boro)
df_des = df_des[df_des['address']\
            .apply(lambda x: pd.notnull(x) and '&' not in x)]
df_des = df_des[df_des['address']\
            .apply(lambda x:  'JFK' not in x and 'AIRPORT' not in x \
            and 'CENTRAL TERMINAL' not in x and 'AMTRAK LEVEL' not in x )]

df_des.sort_values(['address','ZIPCODE','BORO','INSPDATE min'],inplace = True)

group_var = ['address','ZIPCODE','boro']
df_des['camis_cnt'] = df_des.groupby(group_var)\
                    ['CAMIS'].transform('nunique')

df_des_dup = df_des[df_des['camis_cnt'] > 1]

df_des_dup['prev_end'] = df_des_dup.groupby(group_var)['INSPDATE max']\
.transform(lambda x: x.shift(1))

df_des_dedup = df_des_dup[(df_des_dup['prev_end'].apply(pd.isnull)) | \
        (df_des_dup['INSPDATE min'] >= df_des_dup['prev_end'])]
del df_des_dedup['prev_end']

df_des_dedup = df_des_dedup.append(df_des[df_des['camis_cnt'] == 1],
                                   ignore_index = True)

df_des_dedup.sort_values('CAMIS',inplace = True)
df_des_dedup[['CAMIS']].to_pickle(pkl_path + 'single_add_camis.pkl')
df_des_dedup[['CAMIS']].to_stata(dta_path + 'single_add_camis.dta',
        write_index = False)
