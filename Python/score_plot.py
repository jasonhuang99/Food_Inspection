# -*- coding: utf-8 -*-
"""
Created on Sun Feb  5 22:09:17 2017

@author: jasonhuang
"""

import pandas as pd
import matplotlib.pyplot as plt

pkl_path = '../../Data/Pickles/'
inspect_data = 'nyc_ind_inspect.pkl'
df = pd.read_pickle(pkl_path + inspect_data)
Score_bar = 60

class graph():
    def __init__(self, title, size, max_score, df, ax):
        self.title = title
        self.size = size
        self.Score_bar = max_score
        self.df = df
        self.ax = ax
    def create_graph(self, title_size = 24):
        plt.style.use('seaborn-poster')
        self.df.hist(bins = [i - 0.5 for i in range(self.Score_bar + 2)],
                        width=0.75,grid=False, normed = True, 
                        ax = self.ax, figsize = self.size, 
                        )

        plt.axvline(x = 14, ymin = 0, ymax = 1, linewidth = 2,
            color = 'r', linestyle = '--')
        plt.axvline(x = 28, ymin = 0, ymax = 1, linewidth = 2,
            color = 'r', linestyle = '--')
        plt.xlim([-1,self.Score_bar+1])
        plt.ylim([0,0.1])
        plt.xlabel('Scores',fontsize = 20)
        plt.xticks(fontsize = 16)
        plt.yticks(fontsize = 16)
        plt.title(self.title,fontsize = title_size)

df.sort_values(['CAMIS','INSPDATE'], inplace = True)

df_first = df.groupby('CAMIS').first().reset_index()
df_first = df_first[df_first['INSPDATE'] > pd.datetime(2010,10,1)]

df_before = df[(df['INSPDATE'] < pd.datetime(2010,9,1)) \
& (df['SCORE'] <= Score_bar+18) & (df['INSPTYPE'] == "A")]['SCORE']

f1 = plt.figure()
G_before = graph('Histogram of Inspection Scores Before Reform',
                 (10,6),Score_bar, df_before, f1.gca())
G_before.create_graph()

df_init = df[(df['year'] >= 2011) & (df['SCORE'] <= Score_bar) 
& (df['INSPTYPE'] == "A")]['SCORE']

f2 = plt.figure()
G_init = graph('Initial Inspection Scores',(6,6),
               Score_bar, df_init, f2.gca())
G_init.create_graph(20)

df_re = df[(df['year'] >= 2011) & (df['SCORE'] <= Score_bar ) 
& (df['INSPTYPE'] == "B")]['SCORE']

f3 = plt.figure()

G_re = graph('Re-Inspection Scores', (6,6), Score_bar, df_re, f3.gca())
G_re.create_graph(20)

f, axarr = plt.subplots(2, 3, sharex=True, figsize = (18,6))
plt.suptitle('Initial Inspection Scores Across Years', fontsize = 20)
for idx, yr in enumerate([2011,2012,2013,2014,2015,2016]):
    #f_init_score = plt.figure(figsize = (10,6))
    i = idx/3
    j = idx % 3
    df_yr = df[(df['year'] == yr) & (df['SCORE'] <= Score_bar ) 
    & (df['INSPTYPE'] == "A")]['SCORE']
    df_yr.hist(bins = [x - 0.5 for x in range(Score_bar + 2)],
                width=0.75,grid=False, normed = True, 
                ax = axarr[i,j])
    axarr[i,j].axvline(x = 14, ymin = 0, ymax = 1, linewidth = 1,
            color = 'r', linestyle = '--')
    axarr[i,j].axvline(x = 28, ymin = 0, ymax = 1, linewidth = 1,
            color = 'r', linestyle = '--')
    axarr[i,j].set_xlim([-1, Score_bar+1])
    axarr[i,j].set_title(str(yr), fontsize = 14)
    axarr[i,j].set_ylim([0,0.1])
    axarr[i,j].tick_params(axis='y', labelsize=10)
    axarr[i,j].tick_params(axis='x', labelsize=10)



f_new = plt.figure(figsize = (10,6))
df_n = df_first[df_first['PROGRAM'] == 'FS']['SCORE']
G_n = graph('Initial Scores of First Inspections', 
            (10,6), Score_bar, df_n, f_new.gca())
#G_n.create_graph()


df['first'] = df.groupby('CAMIS')['INSPDATE'].transform('min')
df['age'] = df['INSPDATE'] - df['first']
df['age'] = df['age'].apply(lambda x: x.days)
f_old = plt.figure(figsize = (10,6))
df_old = df[(df['age'] >= 1000) & (df['year'] >= 2011) \
& (df['SCORE'] <= Score_bar) & (df['INSPTYPE'] == 'A') ]['SCORE']

G_o = graph('hello', (10,6), Score_bar, df_old, f_old.gca())
#G_o.create_graph()

f2, axarr2 = plt.subplots(1, 2, sharex=True, figsize = (14,6))

df_n.hist(bins = [x - 0.5 for x in range(Score_bar + 2)],
                width=0.75,grid=False, normed = True, 
                ax = axarr2[0])
df_old.hist(bins = [x - 0.5 for x in range(Score_bar + 2)],
                width=0.75,grid=False, normed = True, 
                ax = axarr2[1])
titles = ['First Inspections', 'After 1000 Days in Business']
for i in [0,1]:
    axarr2[i].axvline(x = 14, ymin = 0, ymax = 1, linewidth = 1,
            color = 'r', linestyle = '--')
    axarr2[i].axvline(x = 28, ymin = 0, ymax = 1, linewidth = 1,
            color = 'r', linestyle = '--')
    axarr2[i].set_xlim([-1, Score_bar+1])
    axarr2[i].set_title(titles[i])
    axarr2[i].set_ylim([0,0.08])
    axarr2[i].tick_params(axis='y', labelsize=10)
    axarr2[i].tick_params(axis='x', labelsize=10)
