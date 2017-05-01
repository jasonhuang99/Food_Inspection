# -*- coding: utf-8 -*-
"""
Created on Sat Mar 11 07:36:44 2017
Read in and merge 311 calls with nyc inspection data
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

df_des_add = \
df_des[(df_des['address'].notnull()) & (df_des['ZIPCODE'].notnull())]

df_des_add['State'] = 'New York'
df_des_add['ZIPCODE'] = df_des_add['ZIPCODE'].apply(int)
df_des_add['address_formatted'] = df_des_add\
.apply(lambda x: x['address'] + ', ' + x['boro'] + \
', New York, ' + str(int(x['ZIPCODE'])) ,1)

for s in range(df_des_add.shape[0]/1000+1):    
    start = 1000*s
    df_des_add[['address','boro','State','ZIPCODE']][start:start+1000]\
    .to_csv(csv_path + "Batch/" + str(s) + 'batch.csv',
            header = False)


df_des[df_des['ADDRESS'].notnull()]\
[['CAMIS','ADDRESS','ZIPCODE','boro']]\
.to_csv(dta_path + 'NYC_rest.csv', index = False)

df_des[df_des['ADDRESS'].notnull()]\
[['CAMIS','ADDRESS','ZIPCODE','boro']]\
.to_pickle(pkl_path + 'NYC_rest.pkl')

### Create call data ######################################
df_calls = pd.read_pickle(pkl_path + 'calls.pkl')

df_calls['Orig_Add'] = df_calls['Incident Address']
df_calls['add_number'] = df_calls['Incident Address'].apply(add_number)

df_calls['Incident Address'] = df_calls['Incident Address']\
                                .apply(add_standardize)

df_calls['street_address'] = df_calls['Incident Address']\
                                .apply(add_standardize)
df_calls['add_num'] = df_calls['Incident Address']\
                                .apply(add_number)
df_calls = df_calls[df_calls['Incident Address'].notnull()]
print "distinct addresses", df_calls['Incident Address'].nunique()

df_calls = df_calls.merge(df_des,left_on = 'Incident Address',
                          right_on = 'address', how = 'left')

df_calls_matched = df_calls[df_calls['CAMIS'].notnull()]
print "Found", \
df_calls_matched['Incident Address'].nunique()

df_calls_matched = df_calls_matched[\
(df_calls_matched['Created Date'] >= df_calls_matched['INSPDATE min']) & \
(df_calls_matched['Created Date'] <= df_calls_matched['INSPDATE max'])]

df_calls_matched['dist_camis'] = \
df_calls_matched.groupby('Unique Key')['CAMIS'].transform('nunique')

df_calls_matched.sort_values(['address','DBA'],inplace = True)
df_calls_matched[df_calls_matched['dist_camis'] > 1]\
[['Incident Address','ADDRESS','address','Incident Zip','CAMIS',
  'INSPDATE min','Cross Street 1','Cross Street 2',
  'INSPDATE max','DBA']].to_csv(csv_path + 'dup.csv',index = False)

df_calls_matched[df_calls_matched['dist_camis'] == 1]\
[['Unique Key','Created Date','Closed Date','Complaint Type',
  'Descriptor','Location Type','CAMIS']]\
  .to_pickle(pkl_path + 'calls_matched.pkl')

dta = df_calls_matched[df_calls_matched['dist_camis'] == 1]\
[['Created Date','Unique Key','Complaint Type',
  'Descriptor','CAMIS']]

dta.rename(columns = {'Unique Key': 'Unique_Key',
                      'Complaint Type': 'Complaint_Type'}, inplace = True)
dta\
  .to_stata(dta_path + 'calls_matched.dta',
            convert_dates = {'Created Date':'td'},
            write_index = False)

'''
df_calls_missing = \
df_calls_missing.groupby(['Incident Address',
                          'Incident Zip',
                          'Cross Street 1',
                          'Cross Street 2',
                          'City'])['Unique Key'].min().reset_index()
df_calls_missing.to_csv(dta_path + 'calls_address.csv', index = False)
'''