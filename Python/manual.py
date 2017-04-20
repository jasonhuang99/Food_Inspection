# -*- coding: utf-8 -*-
"""
Created on Tue Mar 28 11:34:00 2017

@author: jasonhuang
"""
import pandas as pd
import ast, os, json, re

csv_path = '../../Data/CSV/'
json_path = '../../Data/JSON/'

json_file = 'matched_dict.json'
if json_file in os.listdir(json_path):
    match_dict = json.load(open(json_path + json_file))
else:
    match_dict = {}
def add_number(x):
    if pd.isnull(x):
        return x
    num = x.split(' ')[0]
    if num.isdigit():
        return int(num)
    else:
        return num
        
def boro(x):
    boro_dict = {}
    boro_dict[1] = 'Manhattan'
    boro_dict[2] = 'Bronx'
    boro_dict[3] = 'Brooklyn'
    boro_dict[4] = 'Queens'
    boro_dict[5] = 'Staten Island'
    boro_dict[0] = 'nan'
    if pd.isnull(x):
        return x
    return boro_dict[x]

def get_top(x):
    try:
        return ast.literal_eval(x)[0]
    except:
        return x

def manual_change(x):
    if x == '48 W. 27TH ST':
        return '48 W 27TH ST'
    if x == '365W W 34TH ST':
        return '365 W 34TH ST'
    if x == '245 BOWERY':
        return '245 BOWERY ST'
    if x == '165 LUDLOW ST':
        return '165-67 LUDLOW ST'
    if x == '210 E 9 TH ST':
        return '210 E 9TH ST'
    if x == '33 IRVING PLACE':
        return '21-33 IRVING PLACE'
    if x == '122-16 ROCKAWAY BEACH BLVD':
        return '112-16 ROCKAWAY BEACH BLVD'
    if x == '421A BEACH 129TH ST':
        return '421 BEACH 129TH ST'
    if x == '2-2 BEACH 116TH ST':
        return '222 BEACH 116TH ST'
    if x == '99-02 ROCKAWAY BEACH BLVD':
        return '9902 ROCKAWAY BEACH BLVD'
    if x == '420 B 129TH ST':
        return '420 BEACH 129TH ST'
    if x == '15E ELDRIDGE ST':
        return '15 ELDRIDGE ST'
    if x == '277C GRAND ST':
        return '277 GRAND ST'
    if x == '27A ESSEX ST':
        return '27 ESSEX ST'
    if x == '29 UNION SQUARE':
        return '29 UNION SQUARE W'
    if x == '219A MULBERRY ST':
        return '219 MULBERRY ST'
    if x == '18B DOYERS ST':
        return '18 DOYERS ST'
    if x == '78 BAYARD ST':
        return '78-80 BAYARD ST'
    if x == '194A CANAL ST':
        return '194 CANAL ST'
    if x == '143A MOTT ST':
        return '143 MOTT ST'
    if x == '61A MOTT ST':
        return '61 MOTT ST'
    if x == '1033A MORRIS PARK AVE' or x == '1033B MORRIS PARK AVE':
        return '1033 MORRIS PARK AVE'
    if x == '1171 GUY R BREWER BLVD':
        return '11701 GUY R BREWER BLVD'
    if x == '1182 E GUNHILL ROAD':
        return '1182 GUNHILL ROAD'
    if x == '12-14 VANDERBILT AVE':
        return '12 VANDERBILT AVE'
    if x == '110112 LIBERTY ST':
        return '110 LIBERTY ST'
    if x == '8789 GREENWICH ST':
        return '89 GREENWICH ST'
    if x == '1 E BEDFORD PARK BLVD':
        return '1 BEDFORD PARK BLVD'
    if x == '1 CITY ISLAND ROAD':
        return '1 CITY ISLAND RD'
    if x == '10223B HORACE HARDING EXPRESSWAY':
        return '10223 HORACE HARDING EXPRESSWAY'
    if x == '475A DRIGGS AVE':
        return '475 DRIGGS AVE'
    if x == '624 CONDUIT BLVD':
        return '624 SOUTH CONDUIT BLVD'
    if x == '6185S STRICKLAND AVE':
        return '6185 STRICKLAND AVE'
    if x == '615 HUDSON ST':
        return '615 1/2 HUDSON ST'
    if x == '60W W 48TH ST':
        return '60 W 48TH ST'
    if x == '1 BAY ST LANDING':
        return '1 BAY ST'
    if x == '1003 BROADWAY STE 1':
        return '1003 BROADWAY'
    if x in match_dict.keys():
        return match_dict[x]
    return x
    
def add_standardize(x):
    if pd.isnull(x):
        return x
    '''
    split_add = x.split(' ')
    num = split_add[0]
    if any(c.isdigit() for c in num):
        split_add[0] = re.sub("[^0-9]", "",num)
    x = ' '.join(split_add)
    '''
    x = x.replace(' WEST',' W').replace(' EAST',' E')\
          .replace(' NORTH',' N').replace(' SOUTH',' S')
    
    for num in range(4,12):
        x = x.replace(str(num)+' AVE',str(num) + 'TH AVE')
    x = x.replace('2 AVE','2ND AVE')\
         .replace('1 AVE','1ST AVE')\
         .replace('3 AVE','3RD AVE')
    x = x.replace("'",'').replace('-','')
    
    x = x.replace('DELANCY','DELANCEY')
    x = x.replace('KINGSBDGE','KINGSBRIDGE')
    x = x.replace('FORSYTHE','FORSYTH')
    x = x.replace('BAY RIDGE','BAYRIDGE')
    x = x.replace('GUNHILL','GUN HILL')
    x = x.replace('MAC DOUGAL','MACDOUGAL')
    x = x.replace('UNIVESITY','UNIVERSITY')
    x = x.replace('HORACE HARDING BLVD','HORACE HARDING EXPRESSWAY')
    x = x.replace('10223B ','10223 ')
    x = x.replace('CASTLEHILL','CASTLE HILL')
    x = x.replace('FREDERICK DOUGLAS','FREDERICK DOUGLASS')
    x = x.replace('BLEEKER','BLEECKER')
    x = x.replace('RICHMIND','RICHMOND')
    x = x.replace('MAC DONALD AVE','MCDONALD AVE')
    x = x.replace('MC DONALD AVE','MCDONALD AVE')
    x = x.replace('MACDONALD AVE','MCDONALD AVE')
    x = x.replace('WHITEPLAINS ROAD','WHITE PLAINS ROAD')
    x = x.replace('WHITE PLAIN ROAD','WHITE PLAINS ROAD')
    x = x.replace('GATEWAY DR','GATEWAY DRIVE')
    x = x.replace('COLOMBUS AVE','COLUMBUS AVE')
    x = x.replace('SOUTH SOUTH CONDUIT BLVD','SOUTH CONDUIT BLVD')
    x = x.replace('FT HAMILTON PARKWAY','FORT HAMILTON PARKWAY')
    x = x.replace('SPRINGFILD','SPRINGFIELD')
    x = x.replace('HAMILTN','HAMILTON')
    x = x.replace('BEGEN ST','BERGEN ST')
    x = x.replace('SPRINGFIELD AVE','SPRINGFIELD BLVD')
    x = x.replace('ROCKAWAY BEACH AVE','ROCKAWAY BEACH BLVD')
    x = x.replace('DEKALB AVE FL 1','DEKALB AVE')
    x = x.replace('MALCOM X','MALCOLM X')
    x = x.replace('CROSSBAY','CROSS BAY')
    x = x.replace('GUY BREWER BLVD','GUY R BREWER BLVD')
    x = x.replace('SAINT NICHOLAS','ST NICHOLAS')
    x = x.replace(" E E "," E ").replace(" W W "," W ")
    
    for num in range(300):
        if num % 10 == 1:
            x = x.replace(str(num) + ' STREET',str(num) + 'ST ST')
        if num % 10 == 2:
            x = x.replace(str(num) + ' STREET',str(num) + 'ND ST')
        if num % 10 == 3:
            x = x.replace(str(num) + ' STREET',str(num) + 'RD ST')
        else:
            x = x.replace(str(num) + ' STREET',str(num) + 'TH ST')
    x = re.sub(' +',' ',x)
    x = x.replace(' BOULEVARD',' BLVD').replace(' STREET',' ST')
    x = x.replace('AVENUE','AVE').replace(' DRIVE',' DR')
    x = x.replace(' PLACE',' PL')
    
    x = x.replace('SIXTH AVE','AVE OF THE AMERICAS')
    x = x.replace('FIRST','1ST').replace('SECOND','2ND').replace('THIRD','3RD')
    x = x.replace('FOURTH','4TH').replace('FIFTH','5TH')
    x = x.upper()
    return manual_change(x)
