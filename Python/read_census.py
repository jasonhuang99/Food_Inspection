# -*- coding: utf-8 -*-
"""
Created on Tue May  9 13:30:23 2017

@author: jasonhuang
"""

import pandas as pd


batch_matched_path = "../../Data/CSV/Batch_Matched/"
pkl_path = '../../Data/Pickles/'
dta_path = '../../Data/DTA/'
census_path = '../../Data/census/aff_download/'

df = pd.read_csv(census_path + 'ACS_15_5YR_B19001_with_ann.csv',
                 header = 1)
df = df[[i for i in df.columns if 'Margin' not in i]]

df.columns = \
[i[i.find('-') + 2:] if i.find('-') >= 0 else i for i in df.columns]
df.rename(columns = {'Estimate; Total:':'Total'}, inplace = True)
df = df[df['Total'] > 0]
df['more200k'] = df['$200,000 or more']/df['Total']

df['more100k'] = (df['$100,000 to $124,999'] + df['$125,000 to $149,999'] + 
                  df['$150,000 to $199,999'] + df['$200,000 or more'] + 
                  df[ u'more200k'])/df['Total']

df['less30k'] = (df['Less than $10,000'] + df['$10,000 to $14,999'] + 
                 df['$15,000 to $19,999'] + df['$20,000 to $24,999'] + 
                 df['$25,000 to $29,999'])/df['Total']

