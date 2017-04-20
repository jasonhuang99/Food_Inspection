# -*- coding: utf-8 -*-
"""
Created on Thu Feb 16 11:33:49 2017
Inspector Level Analysis
@author: jasonhuang
"""

import pandas as pd
import timeit
import numpy as np
from functions import group
import matplotlib.pyplot as plt
from sklearn.decomposition import PCA

pkl_name = 'nyc_inspection.pkl'
pkl_path = '../../Data/Pickles/'
dta_path = '../../Data/DTA/'
start = timeit.default_timer()
df = pd.read_pickle(pkl_path + pkl_name)

df_inspect = pd.read_pickle(pkl_path + 'nyc_ind_inspect.pkl')

df['CASE_DECISION_DATE'] = df['CASE_DECISION_DATE'].apply(lambda x: \
    pd.datetime(1900,1,1) if pd.isnull(x) else x)

df = df[df['PROGRAM'].apply(lambda x: x == 'FS' or x == 'PP')]
read = timeit.default_timer()
print read - start

df['group'] = df['VIOLCODE'].apply(group)
groups = df[df['group'].notnull()]['group'].unique()
codes = df[df['VIOLCODE'].notnull()]['VIOLCODE'].unique()

def LO_score(x):
    n = (x['inspect_sum'] - x['inspect_rest_sum'])
    d = (x['inspect_cnt'] - x['inspect_rest_cnt'])
    if d == 0:
        return np.NaN
    else:
        return n/d


zip_sum = df_inspect.groupby('ZIPCODE')['INSPDATE']\
            .count().reset_index()['INSPDATE']\
            .apply(lambda x: (1.0*x/df_inspect.shape[0])**2).sum()

inspect_sum = df_inspect.groupby('InspectorID')['INSPDATE']\
                .count().reset_index()['INSPDATE']\
                .apply(lambda x: (1.0*x/df_inspect.shape[0])**2).sum()
print "zipcode baseline", zip_sum, "inspector baseline", inspect_sum
df_inspect_zip = df_inspect.groupby(['InspectorID','ZIPCODE'])\
['INSPDATE'].count().reset_index()

df_inspect_zip['inspect_herf'] = df_inspect_zip.groupby('InspectorID')\
['INSPDATE'].transform(lambda x: (100.0*x/sum(x))**2)

df_inspect_zip['zip_herf'] = df_inspect_zip.groupby('ZIPCODE')\
['INSPDATE'].transform(lambda x: (100.0*x/sum(x))**2)

df_inspector_herf = df_inspect_zip.groupby('InspectorID')\
.agg({'INSPDATE':'sum','inspect_herf':'sum'})

df_zip_herf = df_inspect_zip.groupby('ZIPCODE')\
.agg({'INSPDATE':'sum','zip_herf':'sum'})


f, axarr = plt.subplots(2,1,figsize = (8,6))

df_inspector_herf[df_inspector_herf['INSPDATE'] > 50]['inspect_herf']\
.hist(bins = 50, ax = axarr[0], grid = False)
axarr[0].axvline(10000*zip_sum, linewidth = 2,
            color = 'r', linestyle = '--')
axarr[0].set_ylim([0,60])
axarr[0].set_xlim([0,1100])
axarr[0].set_xlabel('HHIs of Zipcodes Inspectors See', fontsize = 14)
axarr[0].set_ylabel('Number of Inspectors', fontsize = 14)
axarr[0].set_title('Distribution of HHI of Zipcodes Across Inspectors',
          fontsize = 16)

df_zip_herf[df_zip_herf['INSPDATE'] > 50]['zip_herf']\
.hist(bins = 50, ax = axarr[1], grid = False)
plt.axvline(10000*inspect_sum, linewidth = 2,
            color = 'r', linestyle = '--')
axarr[1].set_ylim([0,30])
axarr[1].set_xlim([0,550])
axarr[1].set_xlabel('HHIs of Inspectors who See Zipcodes', fontsize = 14)
axarr[1].set_ylabel('Number of Zipcodes', fontsize = 14)
axarr[1].set_title('Distribution of HHI of Inspectors Across Zipcodes',
          fontsize = 16)
plt.tight_layout(pad=0.4, w_pad=0.5, h_pad=3.0)

agg_dict = {}
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
    del df_inspect['FOUND']
    agg_dict[g] = 'mean'

agg_dict['SCORE'] = 'mean'
agg_dict['inspectionID'] = 'nunique'
df_inspector = \
df_inspect.groupby('InspectorID').agg(agg_dict).reset_index()

df_inspector['med'] = df_inspector['SCORE'] > 25
df_inspect = df_inspect.merge(df_inspector[['InspectorID','med']], 
                              on = 'InspectorID', how = 'left')
                             
pca = PCA(n_components=2)
X = np.array(df_inspector[df_inspector['inspectionID'] >= 50][groups])
decomposed = pca.fit_transform(X)
plt.figure(figsize = (10,10))
plt.scatter(decomposed[:,0],decomposed[:,1],s= 100)
plt.xticks(fontsize = 16)
plt.yticks(fontsize = 16)
plt.title('PCA on Inspector Citation Profile',fontsize = 24)

'''                      
Med_High_Cuisine = df_inspect.groupby('cuisine')\
.agg({'med':'sum','SCORE':'count'}).reset_index() 
Med_High_Cuisine['low'] = Med_High_Cuisine['SCORE'] - Med_High_Cuisine['med']

High = Med_High_Cuisine['med'].tolist()
High = [i*1.0/sum(High) for i in High]
Low = Med_High_Cuisine['low'].tolist()
Low = [i*1.0/sum(Low) for i in Low]

Med_High_Zip = df_inspect.groupby('ZIPCODE')\
.agg({'med':'sum','SCORE':'count'}).reset_index()
Med_High_Zip['low'] = Med_High_Zip['SCORE'] - Med_High_Zip['med']

High_Zip = Med_High_Zip['med'].tolist()
High_Zip = [i*1.0/sum(High_Zip) for i in High_Zip]
Low_Zip = Med_High_Zip['low'].tolist()
Low_Zip = [i*1.0/sum(Low_Zip) for i in Low_Zip]

Venue = df_inspect.groupby('venuecode')\
.agg({'med':'sum','SCORE':'count'}).reset_index()
'''
from scipy.stats import chisquare
for v in ['cuisine','ZIPCODE','venuecode','servicecode']:
    category = df_inspect[df_inspect['INSPDATE'] > pd.datetime(2010,10,1)]\
    .groupby(v).agg({'med':'sum','SCORE':'count'}).reset_index()
    category['low'] = category['SCORE'] - category['med']

    High = category['med'].tolist()
    High = [i*1.0/sum(High) for i in High]
    Low = category['low'].tolist()
    Low = [i*1.0/sum(Low) for i in Low]
    print "Testing", v
    print chisquare(High,Low)


f = plt.figure(figsize = (10,6))
df_inspector[df_inspector['inspectionID'] > 50]['SCORE'].hist(bins = 30,
ax = f.gca(),grid = False)
plt.xlabel('Scores',fontsize = 20)
plt.axvline(20.7,color = 'r',linewidth = 5)
plt.xticks(fontsize = 16)
plt.yticks(fontsize = 16)
plt.title('Histogram of Inspector Average Scores',fontsize = 24)
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

rename = {}
for c in codes:
    rename[c] = '_' + c
    rename[c + 'LO'] = 'LO_' + c

for g in groups:
    rename[g] = g.replace(' ','_').replace('/','_')
    rename[g + 'LO'] = 'LO_' + g.replace(' ','_').replace('/','_')
df_inspect.rename(columns = rename, inplace = True)

df_inspect.to_stata(dta_path + 'code.dta',
               convert_dates = {'INSPDATE':'td',
                                'CASE_DECISION_DATE':'td'},
               write_index = False)

'''
