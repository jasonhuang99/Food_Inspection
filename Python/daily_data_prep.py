# -*- coding: utf-8 -*-
"""
Created on Tue Apr 18 16:47:15 2017

@author: jasonhuang
"""

import pandas as pd
import timeit
import numpy as np
#import numpy as np

pkl_name = 'nyc_inspection.pkl'
pkl_path = '../../Data/Pickles/'
dta_path = '../../Data/DTA/'
pkl_path = '../../Data/Pickles/'
calls_name = 'calls_matched.pkl'
start = timeit.default_timer()


def days(x):
    return pd.datetime(x.year, x.month, x.day)

def modify_week(x):
    if x['week'] == 53 and x['month'] == 1:
        return 1
    if x['week'] == 52 and x['month'] == 1:
        return 1
    if x['week'] == 1 and x['month'] == 12:
        return 52
    else:
        return x['week']

df_calls = pd.read_pickle(pkl_path + calls_name)
inspect_file = 'nyc_ind_inspect.pkl'
df = pd.read_pickle(pkl_path + inspect_file)
df = df[df['INSPDATE'] > pd.datetime(2010,10,1)]
df['INSPDATE'] = df['INSPDATE'].apply(days)
df['last_date'] = df.groupby('CAMIS')['INSPDATE'].transform(max)
df['CASE_DECISION_DATE'] = df['CASE_DECISION_DATE'].apply(days)
df['same_day_inspect'] = df.groupby(['CAMIS','INSPDATE'])\
['inspectionID'].transform('nunique')

df = df[df['same_day_inspect'] == 1]
del df['same_day_inspect']

camis_list = df['CAMIS'].unique()[:500]
df = df[df['CAMIS'].apply(lambda x: x in camis_list)]
df['prev_event'] = df['INSPDATE']
'''
df_camis_start_end = df.groupby('CAMIS')\
.agg({'INSPDATE':['min','max']}).reset_index()
'''
df_list = []
df_wk_list = []
for name, df_g in df.groupby('CAMIS'):
    start = df_g['INSPDATE'].min()
    end = df_g['INSPDATE'].max()
    df_temp = pd.DataFrame(pd.date_range(start, end))
    df_temp.columns = ['INSPDATE']
    df_temp['CAMIS'] = name
    df_list.append(df_temp.copy())

    df_temp_wk = pd.DataFrame(pd.date_range(start, 
                                            end + pd.Timedelta('7 days'), 
                                            freq = '1W'))
    df_temp_wk.columns = ['INSPDATE']
    df_temp_wk['CAMIS'] = name
    df_wk_list.append(df_temp_wk.copy())

merge_key = ['CAMIS','year','week']
df_wks = pd.DataFrame().append(df_wk_list, ignore_index = True)    
df_wks['year'] = df_wks['INSPDATE'].apply(lambda x: x.year)
df_wks['week'] = df_wks['INSPDATE'].apply(lambda x: x.week)
df_wks['month'] = df_wks['INSPDATE'].apply(lambda x: x.month)
df_wks['week'] = df_wks.apply(modify_week,1)
del df_wks['INSPDATE']
df_wks = df_wks.groupby(merge_key)['month'].mean().reset_index()

df['year'] = df['INSPDATE'].apply(lambda x: x.year)
df['month'] = df['INSPDATE'].apply(lambda x: x.month)
df['week'] = df['INSPDATE'].apply(lambda x: x.week)
df['week'] = df.apply(modify_week,1)
del df['month']

df_wks_new = df_wks.merge(df, on = merge_key, how = 'outer')



## Modified Score Dataframe
df_mod = df[(df['INSPDATE'] <= df['CASE_DECISION_DATE']) & \
(df['CASE_DECISION_DATE'] <= df['last_date']) & \
(df['INSPTYPE'] == 'B')]\
[['CAMIS','CASE_DECISION_DATE','MOD_TOTALSCORE']]
df_mod.columns = ['CAMIS','INSPDATE_mod','Modified_Score']

df_mod['year'] = df_mod['INSPDATE_mod'].apply(lambda x: x.year)
df_mod['month'] = df_mod['INSPDATE_mod'].apply(lambda x: x.month)
df_mod['week'] = df_mod['INSPDATE_mod'].apply(lambda x: x.week)
df_mod['week'] = df_mod.apply(modify_week,1)
del df_mod['month']


#del df_mod['INSPDATE']
df_wks_new = df_wks_new.merge(df_mod, on = merge_key, how = 'outer')
df_wks_new['check'] = 1
df_wks_new['num_events'] = df_wks_new.groupby(merge_key)['check']\
.transform('count')


## Note: data in df not in df_wks because of last week of year got cut off
 

'''
df_days = pd.DataFrame().append(df_list, ignore_index = True)
df_days = df_days[['CAMIS','INSPDATE']]
last_date = df['INSPDATE'].max()


## Testing 
print df_days.shape
keep_col = ['CAMIS','INSPDATE','SCORE','prev_event',
'InspectorID','PROGRAM','INSPTYPE','ACTION']
df_days_new = df_days.merge(df[keep_col], 
                            on = ['CAMIS','INSPDATE'], how = 'outer')

if df_days_new.shape[0] == df_days.shape[0]:
    print "same length!"
    df_days = df_days_new
    del df_days_new
df_days_new = df_days.merge(df_mod, on = ['CAMIS','INSPDATE'], 
                                how = 'outer')
if df_days_new.shape[0] == df_days.shape[0]:
    print "same length!"
    df_days = df_days_new
    del df_days_new                              

#df_days['prev_event'] = df_days['prev_event'].fillna(method = 'ffill')
df_days['week'] = df_days['INSPDATE'].apply(lambda x: x.week)
df_days['year'] = df_days['INSPDATE'].apply(lambda x: x.year)

weeks = ['CAMIS','year','week']
for c in keep_col:
    if c not in weeks and c not in ['INSPDATE']:
        print c
        df_days[c+'_fill'] = df_days.groupby(weeks)[c]\
        .transform(lambda x: x.fillna(method = 'ffill'))
df_days['recent_in_week'] = df_days.groupby(weeks)['prev_event_fill']\
.transform('last')





def count_zero(x):
    ## Count number of inspections within a week
    return len([i for i in x if i == 0])

def reopen(x):
    return len([i for i in x if i == 'J']) > 0
  
def relevant_score(x):
    if x['SCORE'] > 13 and x['INSPTYPE'] == 'A':
        return np.NaN
    return x['SCORE']
df_days['relevant_score'] = df_days.apply(relevant_score, 1)

for c in keep_col:
    if c not in weeks and c not in ['INSPDATE','last_inspect_date']:
        print c
        df_days[c+'_fill'] = df_days.groupby(weeks)[c]\
        .transform(lambda x: x.fillna(method = 'ffill'))

df_days['re_opened'] = \
df_days.groupby(['CAMIS','year','week'])['INSPTYPE_fill']\
.transform(reopen)

df_days['first_week_SCORE'] = \
df_days.groupby(['CAMIS','year','week'])['SCORE_fill'].transform('first')

df_days['last_week_SCORE'] = \
df_days.groupby(['CAMIS','year','week'])['SCORE_fill'].transform('last')

df_days['earlier_event'] = \
df_days.groupby(['CAMIS','year','week'])\
['last_inspect_date_fill'].transform('first')

df_days['recent_event'] = \
df_days.groupby(['CAMIS','year','week'])\
['last_inspect_date_fill'].transform('last')



df_days_filled = df_days.fillna(method = 'ffill')

df_days_filled['since_last_event'] = \
df_days_filled['INSPDATE'] - df_days_filled['last_inspect_date']
df_days_filled['since_last_event'] = df_days_filled['since_last_event']\
.apply(lambda x: int(x.days))

#df_days_filled['week'] = df_days_filled['INSPDATE'].apply(lambda x: x.week)
#df_days_filled['year'] = df_days_filled['INSPDATE'].apply(lambda x: x.year)

df_days_filled.sort_values(['CAMIS','INSPDATE'], inplace = True)
df_days_filled['max_week_SCORE'] = \
df_days_filled.groupby(['CAMIS','year','week'])['SCORE'].transform('max')

df_days_filled['first_week_SCORE'] = \
df_days_filled.groupby(['CAMIS','year','week'])['SCORE'].transform('first')

df_days_filled['min_week_SCORE'] = \
df_days_filled.groupby(['CAMIS','year','week'])['SCORE'].transform('min')

df_days_filled['last_week_SCORE'] = \
df_days_filled.groupby(['CAMIS','year','week'])['SCORE'].transform('last')
  
weeks = ['CAMIS','year','week']
 
df_weeks = df_days_filled.groupby(weeks).agg()
df_days_filled['num_events'] = \
df_days_filled.groupby(['CAMIS','year','week'])['since_last_event']\
.transform(count_zero)

df_days_filled['re_opened'] = \
df_days_filled.groupby(['CAMIS','year','week'])['INSPTYPE']\
.transform(reopen)


####
df_days_filled.to_stata('check.dta', convert_dates = {'INSPDATE':'td',
                                'CASE_DECISION_DATE':'td',
                                'first_event':'td',
                                'last_date':'td'},
               write_index = False)
'''
