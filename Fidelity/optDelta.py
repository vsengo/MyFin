from math import log, sqrt, pi, exp
from scipy.stats import norm
from datetime import datetime, date
import numpy as np
import pandas as pd
from pandas import DataFrame

def d1(S,K,T,r,sigma):
    return(log(S/K)+(r+sigma**2/2.)*T)/(sigma*sqrt(T))
def d2(S,K,T,r,sigma):
    return d1(S,K,T,r,sigma)-sigma*sqrt(T)

def bs_call(S,K,T,r,sigma):
    return S*norm.cdf(d1(S,K,T,r,sigma))-K*exp(-r*T)*norm.cdf(d2(S,K,T,r,sigma))
  
def bs_put(S,K,T,r,sigma):
    return K*exp(-r*T)-S+bs_call(S,K,T,r,sigma)

today = datetime.now()
one_year_ago = today.replace(year=today.year-1)

def calcOpt(symbol,expiry,start,end):
	filePath="quotes/history/"+symbol+".csv"
	df = pd.read_csv(filePath)
	df = df.dropna()
	rows,cols = df.shape
	
	df = df.truncate(before=rows-252)
	print(df.shape)

	df = df.assign(close_day_before=df.Close.shift(1))
	df['returns'] = ((df.Close - df.close_day_before)/df.close_day_before)

	sigma = np.sqrt(252) * df['returns'].std()
	uty = pd.read_csv("quotes/history/^TNX.csv")['Close'].iloc[-1]/100
	lcp = df['Close'].iloc[-1]
	print("Option ",symbol,":",expiry,": close:",lcp," 10yr:",uty," sigma:",sigma)

	t = (datetime.strptime(expiry, "%m-%d-%Y") - datetime.utcnow()).days / 365

	for x in range (start,end):
		strike_price = x
		print('The Option strike:',strike_price, bs_call(lcp, strike_price, t, uty, sigma))

calcOpt("AAPL","06-17-2022",145,170)





