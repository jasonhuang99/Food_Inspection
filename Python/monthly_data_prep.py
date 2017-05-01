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
single_name = 'single_add_camis.pkl'
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

def modified(x):
    nxt = x['next']
    if pd.notnull(nxt):
        nxt = pd.datetime(nxt.year,nxt.month,1)
    else:
        #If next empty, do not count
        nxt = pd.datetime(1900,1,1)
    dcn = x['CASE_DECISION_DATE']
    dcn = pd.datetime(dcn.year,dcn.month,1)
    if (x['INSPDATE'] <= x['CASE_DECISION_DATE'] and \
    x['CASE_DECISION_DATE'] <= x['last_date'] and \
    x['INSPTYPE'] == 'B' and nxt > dcn):
        return 1
    else: 
        return 0
df_calls = pd.read_pickle(pkl_path + calls_name)
df_single_name = pd.read_pickle(pkl_path + single_name)
inspect_file = 'nyc_ind_inspect.pkl'
df = pd.read_pickle(pkl_path + inspect_file)
df = df[df['INSPDATE'] > pd.datetime(2010,10,1)]
df['INSPDATE'] = df['INSPDATE'].apply(days)
df['last_date'] = df.groupby('CAMIS')['INSPDATE'].transform(max)
df['CASE_DECISION_DATE'] = df['CASE_DECISION_DATE'].apply(days)

df['time2adj'] = df['CASE_DECISION_DATE'] - df['INSPDATE']
df['time2adj'] = df['time2adj'].apply(lambda x: int(x.days))
df.sort_values(['CAMIS','INSPDATE'], inplace = True)

# Calculate info about next inspection
df['next'] = df.groupby('CAMIS')['INSPDATE'].transform(lambda x: x.shift(-1))
df['modified'] = df.apply(modified,1)

'''
df['next_type'] = \
df.groupby('CAMIS')['INSPTYPE'].transform(lambda x: x.shift(-1))
'''
# Keep only establishments with unique address
df = df_single_name.merge(df, on = 'CAMIS',how = 'left')

# same_day_inspect: number of inspections on same day
df['same_day_inspect'] = df.groupby(['CAMIS','INSPDATE'])\
['inspectionID'].transform('nunique')
# Keep only dates that had at most a single inspection
df = df[df['same_day_inspect'] == 1]
del df['same_day_inspect']

camis_list = df['CAMIS'].unique()
df = df[df['CAMIS'].apply(lambda x: x in camis_list)]

df_list = []
for name, df_g in df.groupby('CAMIS'):
    start = df_g['INSPDATE'].min()
    start_month = pd.datetime(start.year,start.month,1)
    end = df_g['INSPDATE'].max()
    end = pd.datetime(end.year,end.month,28) + pd.Timedelta('30 days')

    df_temp = pd.DataFrame(pd.date_range(start,end,freq = '1M'))
    df_temp.columns = ['INSPDATE']
    df_temp['CAMIS'] = name
    df_list.append(df_temp.copy())

df_month = pd.DataFrame().append(df_list, ignore_index = True)
df_month['year'] = df_month['INSPDATE'].apply(lambda x: x.year)
df_month['month'] = df_month['INSPDATE'].apply(lambda x: x.month)
del df_month['INSPDATE']

merge_key = ['CAMIS','year','month']

df['year'] = df['INSPDATE'].apply(lambda x: x.year)
df['month'] = df['INSPDATE'].apply(lambda x: x.month)

print df_month.shape[0]
df_month = df_month.merge(df, on = merge_key, how = 'outer')

df_month.sort_values(['CAMIS','year','month','INSPDATE'])


df_calls['year'] = df_calls['Created Date'].apply(lambda x: x.year)
df_calls['month'] = df_calls['Created Date'].apply(lambda x: x.month)

agg_dict = {'InspectorID':'last','INSPDATE':['last','nunique'],
            'SCORE':'last','PROGRAM':'last','ACTION':'last',
            'INSPTYPE':'last','ZIPCODE':'last','modified':'last',
            'CASE_DECISION_DATE':'last'}
            
df_month_agg = df_month.groupby(merge_key).agg(agg_dict).reset_index()
df_month_agg.columns = \
[''.join(x).replace('last','') for x in df_month_agg.columns.values]

df_month_agg.rename(columns = {'INSPDATEnunique':'num_inspect'}, 
                    inplace = True)
df_month_agg = df_month_agg.fillna(method = 'ffill')

df_mod = df[df['modified'] == 1]\
[['CAMIS','CASE_DECISION_DATE','MOD_TOTALSCORE','INSPDATE','SCORE']]
df_mod.columns = ['CAMIS','INSPDATE_mod','Modified_Score','INSPDATE_i','SCORE_X']
df_mod['year'] = df_mod['INSPDATE_mod'].apply(lambda x: x.year)
df_mod['month'] = df_mod['INSPDATE_mod'].apply(lambda x: x.month)

df_month_agg_mod = df_month_agg.merge(df_mod, on = merge_key,
                                      how = 'outer')
df_month_agg_mod['num_mod'] = \
df_month_agg_mod.groupby(merge_key)['SCORE'].transform('count')

df_month_agg_mod['time2adj'] = df_month_agg_mod['CASE_DECISION_DATE'] - \
df_month_agg_mod['INSPDATE']
df_month_agg_mod['time2adj'] = \
df_month_agg_mod['time2adj'].apply(lambda x: int(x.days))

def visible_score(x):
    if pd.notnull(x['INSPDATE_mod']):
        return x['Modified_Score'] 
    if x['INSPTYPE'] == "B" and x['num_inspect'] > 0:
        if x['modified'] == 0:
        ## Not pursue Adjudication
            return x['SCORE']
        else:
            ## Grade Pending
            return -1
    if x['INSPTYPE'] == "A" and x['SCORE'] <= 13:
        return x['SCORE']
    return np.NaN

def visible_event(x):
    if x['num_inspect'] > 0:
        if (x['INSPTYPE'] == 'B') or \
        (x['INSPTYPE'] == 'A' and x['visible_score'] <= 13):
        ## Had an non-modified re-inspection inspection
            if pd.isnull(x['INSPDATE_vis']):
                ## Do not override current modified date
                return x['INSPDATE']
            else:
                return x['INSPDATE_vis']
    else:
        return x['INSPDATE_vis']

df_month_agg_mod['visible_score'] = df_month_agg_mod.apply(visible_score,1)
df_month_agg_mod['visible_score'] = \
df_month_agg_mod['visible_score'].fillna(method = 'ffill')
df_month_agg_mod['INSPDATE_vis'] = df_month_agg_mod['INSPDATE_mod']
df_month_agg_mod['INSPDATE_vis'] = df_month_agg_mod.apply(visible_event,1)

print "number of obs with more than one modified event per month", \
df_month_agg_mod[df_month_agg_mod['num_mod'] > 1].shape

## df_month_temp: stores calls data
df_month_temp = df_month_agg_mod[merge_key + ['INSPDATE','INSPDATE_vis']]\
.merge(df_calls[merge_key + ['Unique Key','Created Date']],
       on = merge_key, how = 'left')
## Calculate Counted Calls (only after inspect_date)
df_month_temp['INSPDATE_vis'] = df_month_temp['INSPDATE_vis']\
.fillna(method = 'ffill')
df_month_temp['Counted Calls'] = df_month_temp.apply(lambda x: 1 if \
        x['INSPDATE'] <= x['Created Date'] and pd.notnull(x['Created Date']) \
        else 0,1)
df_month_temp['Counted Calls_vis'] = df_month_temp.apply(lambda x: 1 if \
        x['INSPDATE_vis'] <= x['Created Date'] and pd.notnull(x['Created Date']) \
        else 0,1)
df_month_calls = df_month_temp.groupby(merge_key).agg({'Counted Calls':'sum',
'Unique Key':'nunique','Counted Calls_vis':'sum'}).reset_index()

print df_month_agg_mod.shape
df_month_agg_mod = df_month_agg_mod.merge(df_month_calls, on = merge_key,
                                          how = 'outer')
print df_month_agg_mod.shape

df_month_agg.columns = [x.replace(' ','_') for x in df_month_agg.columns]

df_month_agg_mod.columns = \
[x.replace(' ','_') for x in df_month_agg_mod.columns]

df_month_agg_mod.to_stata(dta_path + 'calls_month.dta',
                        convert_dates = {'INSPDATE':'td',
                        'CASE_DECISION_DATE':'td','INSPDATE_i':'td',
                        'INSPDATE_mod':'td','INSPDATE_vis':'td'},
                        write_index = False)
'''
## Modified Score Dataframe

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
