# -*- coding: utf-8 -*-
"""
Created on Fri Feb 17 07:24:26 2017

@author: jasonhuang
"""
import pandas as pd
import numpy as np

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
def LO(x):
    return (sum(x) - x)/(len(x) - 1)
    
def LO_score(x):
    n = (x['inspect_sum'] - x['inspect_rest_sum'])
    d = (x['inspect_cnt'] - x['inspect_rest_cnt'])
    if d == 0:
        return np.NaN
    else:
        return 1.0*n/d
        
def status(x):
    if pd.isnull(x['next']) and x['INSPDATE'] <= pd.datetime(2015,10,1):
        return 0
    else:
        return 1