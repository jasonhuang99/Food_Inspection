# -*- coding: utf-8 -*-
"""
Created on Wed Mar 29 20:37:32 2017

@author: jasonhuang
"""
from yelp.client import Client
from yelp.oauth1_authenticator import Oauth1Authenticator
import json
import io
import rauth
import time
from fuzzywuzzy import fuzz

with io.open('config_secret.json') as cred:
    creds = json.load(cred)
    auth = Oauth1Authenticator(**creds)
    
    client = Client(auth)

def get_result(params,creds):
    session = rauth.OAuth1Session(
    consumer_key = creds['consumer_key'],
    consumer_secret = creds['consumer_secret'],
    access_token = creds['token'],
    access_token_secret = creds['token_secret']
    )
    
    request = session.get("http://api.yelp.com/v2/search",params=params)
       
    #Transforms the JSON API response into a Python dictionary
    data = request.json()
    return data
    

params = {}
api_calls = []
limit = 4
df_des['categories'] = ''
df_des['new_name'] = ''
df_des['wrong_add'] = ''
for i, row in df_des.iterrows():
    if i % 200 == 0:
        print i
    params["term"] = row['DBA']
    params['location'] = row['address'] + " " + row['boro']
    params["limit"] = limit
    result = get_result(params,creds)
    #print "looking " + row['DBA']
    score_name_1 = 0   
    score_name_2 = 0
        #print "found " + result['businesses'][0]['name']
    if 'businesses' in result.keys() and len(result['businesses']) > 0:
        b = result['businesses'][0]
        try:
            #Unicode issue
            score_name_1 = \
            fuzz.ratio(row['DBA'].lower(),b['name'].lower())
            score_name_2 = \
            fuzz.token_set_ratio(row['DBA'].lower(),b['name'].lower())
        except UnicodeDecodeError:
            pass
        address = " ".join(b['location']['display_address']).lower()
        comp_add = row['address'] + ' ' \
        + row['boro'] + ", ny " + str(row['ZIPCODE'])
        score_add_1 = fuzz.token_set_ratio(comp_add.lower(),
                                           address)
        #print "{0} {1} {2}".format(score_name_1, score_name_2, score_add_1)
        if score_add_1 < 60:
            df_des['wrong_add'] = address
        if max(score_name_1,score_name_2) > 80 and score_add_1 > 60:
            if 'categories' in b.keys():
                df_des.ix[i,'categories'] = \
                ','.join([j[0] for j in b['categories']])
            df_des.ix[i,'new_name'] = b['name']
            df_des.ix[i,'rating'] = b['rating']
            df_des.ix[i,'review_count'] = b['review_count']
            df_des.ix[i,'Lat'] = b['location']['coordinate']['latitude']
            df_des.ix[i,'Lon'] = b['location']['coordinate']['longitude']
            
    api_calls.append(result)    
    time.sleep(0.01)
