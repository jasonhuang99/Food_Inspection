# -*- coding: utf-8 -*-
"""
Created on Tue Apr  4 13:56:40 2017

@author: jasonhuang
"""

f_init_vio = plt.figure(figsize = (10,6))
df['issue'] = df.apply(lambda x: 1 if x['VIOLSCORE_sum'] == 0 and \
    x['SCORE'] > 0 else 0, 1)
f_init_vio = plt.figure(figsize = (10,6))
df[(df['year'] >= 2011) & (df['VIOLSCORE_sum'] <= Score_bar) 
& (df['INSPTYPE'] == "A")]['VIOLSCORE_sum']\
.hist(bins = [i - 0.5 for i in range(Score_bar + 2)],width=0.75,
              ax= f_init_vio.gca(),grid=False)

plt.axvline(x = 14, ymin = 0, ymax = 1, linewidth = 2,
            color = 'r', linestyle = '--')
plt.axvline(x = 28, ymin = 0, ymax = 1, linewidth = 2,
            color = 'r', linestyle = '--')
plt.xlim([-1,Score_bar+1])
plt.xlabel('Scores',fontsize = 20)
plt.xticks(fontsize = 16)
plt.yticks(fontsize = 16)
plt.title('Histogram of Initial Violation Sums',fontsize = 24)

f_pre = plt.figure(figsize = (14,6))
df[(df['INSPDATE'] < pd.datetime(2010,9,1)) & (df['SCORE'] <= Score_bar+18) 
& (df['INSPTYPE'] == "A") & (df['issue'] == 0)]['SCORE']\
.hist(bins = [i - 0.5 for i in range(Score_bar+20)],width=0.75,
              ax= f_pre.gca(),grid=False)
plt.xlim([-1,Score_bar + 19])
plt.xlabel('Scores',fontsize = 20)
plt.xticks(fontsize = 16)
plt.yticks(fontsize = 16)
plt.title('Histogram of Inspection Scores Before Reform', fontsize = 24)

f_init_score = plt.figure(figsize = (14,6))
df[(df['year'] >= 2011) & (df['SCORE'] <= Score_bar) 
& (df['INSPTYPE'] == "A")]['SCORE']\
.hist(bins = [i - 0.5 for i in range(Score_bar+2)],width=0.75,
              ax= f_init_score.gca(),grid=False)

plt.axvline(x = 14, ymin = 0, ymax = 1, linewidth = 2,
            color = 'r', linestyle = '--')
plt.axvline(x = 28, ymin = 0, ymax = 1, linewidth = 2,
            color = 'r', linestyle = '--')
plt.xlim([-1,Score_bar + 1])
plt.xlabel('Scores',fontsize = 20)
plt.xticks(fontsize = 16)
plt.yticks(fontsize = 16)
plt.title('Histogram of Initial Inspection Scores',fontsize = 24)

f_re_score = plt.figure(figsize = (10,6))
df[(df['year'] >= 2011) & (df['SCORE'] <= Score_bar ) 
& (df['INSPTYPE'] == "B")]['SCORE']\
.hist(bins = [i - 0.5 for i in range(Score_bar+2)],width=0.75,
              ax= f_re_score.gca(), grid=False, normed = True)

plt.axvline(x = 14, ymin = 0, ymax = 1, linewidth = 2,
            color = 'r', linestyle = '--')
plt.axvline(x = 28, ymin = 0, ymax = 1, linewidth = 2,
            color = 'r', linestyle = '--')
plt.xlim([-1,Score_bar + 1])
plt.xlabel('Scores',fontsize = 20)
plt.xticks(fontsize = 16)
plt.yticks(fontsize = 16)
plt.title('Histogram of Re-Inspection Scores',fontsize = 24)

f_re_vio = plt.figure(figsize = (10,6))
df[(df['year'] >= 2011) & (df['VIOLSCORE_sum'] <= Score_bar ) 
& (df['INSPTYPE'] == "B") & (df['issue'] == 0)]['VIOLSCORE_sum']\
.hist(bins = [i - 0.5 for i in range(Score_bar+2)],width=0.75,
              ax= f_re_vio.gca(), grid=False, normed = True)

plt.axvline(x = 14, ymin = 0, ymax = 1, linewidth = 2,
            color = 'r', linestyle = '--')
plt.axvline(x = 28, ymin = 0, ymax = 1, linewidth = 2,
            color = 'r', linestyle = '--')
plt.xlim([-1,Score_bar + 1])
plt.xlabel('Scores',fontsize = 20)
plt.xticks(fontsize = 16)
plt.yticks(fontsize = 16)
plt.title('Histogram of Re-Inspection Violation Sums',fontsize = 24)

f_re_mod = plt.figure(figsize = (10,6))
df[(df['year'] >= 2011) & (df['MOD_TOTALSCORE'] <= Score_bar) 
& (df['INSPTYPE'] == "B") & 
(df['CASE_DECISION_DATE'] > pd.datetime(1900,1,1)) &
(df['SCORE'] > 0)]['MOD_TOTALSCORE']\
.hist(bins = [i - 0.5 for i in range(Score_bar + 2)],width=0.75,
              ax= f_re_mod.gca(), grid=False, normed = True)
plt.axvline(x = 14, ymin = 0, ymax = 1, linewidth = 2,
            color = 'r', linestyle = '--')
plt.axvline(x = 28, ymin = 0, ymax = 1, linewidth = 2,
            color = 'r', linestyle = '--')
plt.xlim([-1,Score_bar + 1])
plt.xlabel('Scores',fontsize = 20)
plt.xticks(fontsize = 16)
plt.yticks(fontsize = 16)
plt.title('Histogram of Adjudication Modified Scores',fontsize = 24)

f_first = plt.figure(figsize = (10,6))

df_first[df_first['PROGRAM'] == 'FS']['SCORE']\
.hist(bins = [i - 0.5 for i in range(Score_bar + 2)],width=0.75,
             ax = f_first.gca(), grid=False, normed = True)
plt.axvline(x = 14, ymin = 0, ymax = 1, linewidth = 2,
            color = 'r', linestyle = '--')
plt.axvline(x = 28, ymin = 0, ymax = 1, linewidth = 2,
            color = 'r', linestyle = '--')
plt.xlim([-1,Score_bar + 1])
plt.xlabel('Scores',fontsize = 20)
plt.xticks(fontsize = 16)
plt.yticks(fontsize = 16)
plt.title('Histogram of First Inspection Scores',fontsize = 24)

'''
for yr in [2011,2012,2013,2014,2015,2016]:
    f_init_score = plt.figure(figsize = (10,6))
    df[(df['year'] == yr) & (df['SCORE'] <= Score_bar ) 
    & (df['INSPTYPE'] == "A")]['SCORE']\
    .hist(bins = [i - 0.5 for i in range(62)],width=0.75,
                  ax= f_init_score.gca(),grid=False)
    
    plt.axvline(x = 14, ymin = 0, ymax = 1, linewidth = 2,
                color = 'r', linestyle = '--')
    plt.axvline(x = 28, ymin = 0, ymax = 1, linewidth = 2,
                color = 'r', linestyle = '--')
    plt.xlim([-1,Score_bar])
    plt.ylim([0,2500])
    plt.xlabel('Scores',fontsize = 16)
    plt.xticks(fontsize = 16)
    plt.yticks(fontsize = 16)
    plt.title('Histogram of Initial Inspection Scores - ' + str(yr),
              fontsize = 20)
'''
