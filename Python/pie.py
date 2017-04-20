# -*- coding: utf-8 -*-
"""
Created on Sat Feb 11 15:11:06 2017

@author: jasonhuang
"""

import pandas as pd
import matplotlib.pyplot as plt
from collections import Counter
import operator
import numpy as np

pkl_path = '../'
inspect_data = 'nyc_ind_inspect.pkl'
pkl_name = 'nyc_inspection.pkl'
import matplotlib as mpl
mpl.rcParams['font.size'] = 54.0

pkl_name = 'nyc_inspection.pkl'
pkl_path = '../../Data/Pickles/'
df = pd.read_pickle(pkl_path + pkl_name)

df = df[df['INSPDATE'] > pd.datetime(2010,10,1)]
def group(x):
    if pd.isnull(x):
        return np.NaN
    if '02' in x:
        return 'Food Temperature'
    if '03' in x:
        return 'Critical Food Source'
    if '04' in x:
        return 'Food Protection'
    if '05' in x:
        return 'Facility Design'
    if '06' in x:
        return 'Personal Hygiene'
    if '07' in x:
        return np.NaN
    if '08' in x:
        return 'Vermin/Garbage'
    if '09' in x:
        return 'General Food Source'
    if '10' in x:
        return 'Facility Maintenance'
        
df['VIOLGROUP'] = df['VIOLCODE'].apply(group)

codes = Counter(df[df['VIOLGROUP'].notnull()]['VIOLGROUP'].tolist())

codes = sorted(codes.items(), key=operator.itemgetter(1))

'''
cuisines = sorted(x.items(), key=operator.itemgetter(1))

#df = pd.read_pickle(pkl_path + inspect_data)

df_rest = df[df['cuisine'].notnull()]\
.groupby('CAMIS')['cuisine'].min().reset_index()

x = Counter(df_rest['cuisine'].tolist())

cuisines = sorted(x.items(), key=operator.itemgetter(1))
'''

sizes = [i[1] for i in codes]
labels = [i[0] for i in codes]

plt.style.use('seaborn-poster')
cmap = plt.get_cmap('jet')
index = np.linspace(0.25, 0.9, len(sizes))
#np.random.shuffle(index)

colors = cmap(index)

plt.pie(sizes, labels = labels,autopct='%1.1f%%',colors = colors,
        shadow=True,textprops = {'fontsize':20})
plt.axis('equal')

#df.groupby('CAMIS')