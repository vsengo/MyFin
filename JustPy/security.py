# Python version of brk.q to load and process transactions
# Calculate positions, pnl and various stats
# Author : Sengo 2022.08.08
#----------------------------------------------------------
from ssl import Options
import pandas as pd
import numpy as  np
import yfinance as yf
import subprocess
import datetime as dt
import sys, getopt
import re
import os

dataDir="/Users/sengo/Documents/MyFin/Finance_2022/"
class Security:

    fileName=dataDir+"Fidelity/CommonData/symbols.csv"

    #Converts Fidelity symbol -<sym><yymmdd><C/P><strike>
    @staticmethod
    def convertOptSymFid(symbol):
        (part1,part2)=re.split('\d[C,P]\d',symbol)
        n=len(part1)
        underlying=symbol[1:n-5]
        yy=2000+int(symbol[n-5:n-3])
        mm=int(symbol[n-3:n-1])
        dd=int(symbol[n-1:n+1])
        expDate=dt.date(yy,mm,dd)
        putCall=symbol[n+1:n+2]
        strike=float(symbol[n+2:])
        return (underlying,expDate,putCall,strike)

    #Converts Yahoo symbol <sym><yymmdd><C/P><strike 8 Digits>
    @staticmethod
    def convertOptSymYhoo(symbol):
        (part1,part2)=re.split('\d[C,P]\d',symbol)
        n=len(part1)
        underlying=symbol[0:n-5]
        yy=2000+int(symbol[n-5:n-3])
        mm=int(symbol[n-3:n-1])
        dd=int(symbol[n-1:n+1])
        expDate=dt.date(yy,mm,dd)
        putCall=symbol[n+1:n+2]
        strike=float(symbol[n+2:]) / 1000

        return (underlying,expDate,putCall,strike)

    @staticmethod
    def getPutCall(symbol):
        (underlying,expDate,putCall,strike) = Security.convertOptSymYhoo(symbol)
        return putCall

    def __init__(self):
        self.data = pd.read_csv(self.fileName)
        print("Loaded "+str(self.data.shape[0])+" from "+self.fileName)


class CorporateAction:
    fileNameSplit=dataDir+"Fidelity/CommonData/caSplit.csv"
    fileNameMerger=dataDir+"Fidelity/CommonData/caMerger.csv"
    fileNameDelist=dataDir+"Fidelity/CommonData/caDelist.csv"

    def __init__(self):
        self.split=pd.read_csv(self.fileNameSplit)     
        for index, data in self.split.iterrows():
            self.split["date"][index]=dt.datetime.strptime(data['date'],"%Y.%m.%d")
        print("Loaded "+str(self.split.shape[0])+" from "+self.fileNameSplit)
        
        self.delist=pd.read_csv(self.fileNameDelist)
        for index, data in self.delist.iterrows():
            self.delist["date"][index]=dt.datetime.strptime(data['date'],"%Y.%m.%d")
        print("Loaded "+str(self.delist.shape[0])+" from "+self.fileNameDelist)

        self.merger=pd.read_csv(self.fileNameMerger)
        for index, data in self.merger.iterrows():
            self.merger["date"][index]=dt.datetime.strptime(data['date'],"%Y.%m.%d")

        print("Loaded "+str(self.merger.shape[0])+" from "+self.fileNameMerger)

class Quote:
    subDir="quotes/"

    def __init__(self):
        self.eqQuote=pd.DataFrame()
        self.optionQuote=pd.DataFrame()

    def loadEquity(self,symbols):
        toDate=dt.datetime.now()+dt.timedelta(days=1)
        fromDate=dt.datetime.now()


        for symbol in symbols:
            ticker=yf.Ticker(symbol)
            data=ticker.history(interval='1d',start=fromDate.strftime("%Y-%m-%d"),end=toDate.strftime("%Y-%m-%d"))
            if data.empty:
                print("Error loading "+symbol)    
            else:
                data["symbol"] = symbol
                self.eqQuote=pd.concat([self.eqQuote,data])
                print("Loaded quotes for " + symbol)
    
    @classmethod
    def optionChain(cls,symbol,expDates, eod):

        tk = yf.Ticker(symbol)
        # Expiration dates
        exps = expDates

        # Get options for each expiration
        options = pd.DataFrame()
        if eod == 'y':
            exps = tk.options
        for e in exps:
            try:
                opt = tk.option_chain(e)
                opt = pd.concat([opt.calls,opt.puts])
                opt['expirationDate'] = e
                opt["symbol"] = symbol
                options = pd.concat([options,opt])
            except ValueError:
                print("No Options for "+symbol+"-"+str(e))

        if  options.empty:
            print("No Option Series for "+symbol)
            return options

        # Bizarre error in yfinance that gives the wrong expiration date
        # Add 1 day to get the correct expiration date
        #options['expirationDate'] = pd.to_datetime(options['expirationDate']) + dt.timedelta(days = 1)
        #options['dte'] = (options['expirationDate'] - dt.datetime.today()).dt.days / 365
        options[['bid', 'ask', 'strike']] = options[['bid', 'ask', 'strike']].apply(pd.to_numeric)
        options['mid'] = (options['bid'] + options['ask']) / 2 # Calculate the midpoint of the bid-ask
    
        # Drop unnecessary and meaningless columns
        options = options.drop(columns = ['contractSize', 'currency', 'change', 'percentChange'])
        underlyingList=[]
        expDateList=[]
        putCallList=[]
        strikeList=[]
        for index,row in options.iterrows():
            (underlying,expDate,putCall,strike) = Security.convertOptSymYhoo(row['contractSymbol'])
            underlyingList.append(underlying)
            expDateList.append(expDate)
            putCallList.append(putCall)
            strikeList.append(strike)
        
        options.loc[:,'underlying'] = underlyingList
        options.loc[:,'expDate']    = expDateList
        options.loc[:,'putCall']    = putCallList
        options.loc[:,'strike']     = strikeList
        return options

    def getOption(self,symbol,expDates,eod):
        option=Quote.optionChain(symbol,expDates,eod)
        #print(option)
        if option.empty:
            print("Bad Data :"+option.columns)
        else:
            
            print("Loaded option Quote "+symbol)
        
        return option

    def loadOptions(self,symbols):
        expDates = set([])
        oldsymbol=""
        eod='y'

        for symbol in sorted(symbols):
            (underlying,expDate,putCall,strike) = Security.convertOptSymFid(symbol)
            if len(oldsymbol) == 0:
                oldsymbol=underlying

            if oldsymbol != underlying:
                option=self.getOption(oldsymbol,expDates,eod)  
                self.optionQuote=pd.concat([self.optionQuote,option])
                expDates.clear()
                oldsymbol=underlying
                
            expDates.add(expDate)

        option=self.getOption(oldsymbol,expDates,eod)  
        self.optionQuote=pd.concat([self.optionQuote,option])


def main():
    quote = Quote()
    
    data=['AAPL','ABNB','TSLA']
    #quote.loadEquity(data)

    data=['-AAPL220826C170','-ABNB220902C200']
    quote.loadOptions(data)

if __name__ == "__main__":
    main()