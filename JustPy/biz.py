# Python version of brk.q to load and process transactions
# Calculate positions, pnl and various stats
# Author : Sengo 2022.08.08
# Updates:
# 2022.08.10 : calculate positions, add dividend
#----------------------------------------------------------
import pandas as pd
import numpy as  np
import subprocess
import datetime as dt
import sys, getopt
import re
import os
import security as sec

dataDir="/Users/sengo/Documents/MyFin/Finance_2022/Fidelity/BrkData/"

class Account:   
    fileName="account.csv"

    def load(self):
        self.data=pd.read_csv(dataDir+self.fileName)
        print("Loaded "+str(self.data.shape[0])+" from "+self.fileName)

    def __init__(self):
        self.load()

class WatchList:
    fileName="watchlist.csv"

    def load(self):
        self.data=pd.read_csv(dataDir+self.fileName)
        print("Loaded "+str(self.data.shape[0])+" from "+self.fileName)

    def __init__(self):
        self.load()

class Transaction:
    fileNamePattern="History_for_account"
    qtrMonths={1:(1,3), 2:(4,6), 3:(7,9), 4:(10,12)}
    
    def convertAction(self,act):
        if re.search("^YOU BOUGHT*",act) or re.search("^ADJUST EXERCISE*",act):
            return 'BUY'
        if re.search("^YOU SOLD*",act) or re.search("^EXPIRED",act):
            return 'SELL'
        if re.search("^DIVIDEND*",act):
            return 'DIV'
        if re.search("^REVERSE SPLIT*",act):
            return 'CA_RVSP'
        if re.search("^LIQUIDATION*", act):
            return 'CA_DELIST'
        if re.search("^MERGER*",act):
            return 'CA_MERGER'

        return 'IGNORE'

    def load(self):

        fileNames=subprocess.check_output("ls -T "+dataDir, shell=True).decode().split("\n")
        dateList=[]
        actionList=[]
        symbolList=[]
        qtyList=[]
        priceList=[]
        commissionList=[]
        amountList=[]
        accountList=[]
        
        for fname in fileNames:
            if fname.find("History") == -1:
                continue
            qtr=int(fname[-5])
            account=fname.split('_')[3]

            f=open(dataDir+"/"+fname,"r")
            print("Loading "+fname)

            for row in f:
                if len(row.strip()) ==0:
                    continue
                cols=row.split(',')
                #if first column is not date ignore
                tmp=cols[0].split('/')
                if len(tmp) < 3:
                    continue
                try:
                    mm=int(tmp[0])
                    date=dt.datetime(int(tmp[2]), mm, int(tmp[1]))
                except ValueError:
                    continue

                if mm < self.qtrMonths[qtr][0] or mm > self.qtrMonths[qtr][1]:
                    print("Ignoring date from date ",str(date))
                    continue

                action=self.convertAction(cols[1].strip())
                
                try:
                    qty=int(cols[5])
                except ValueError:
                    qty=0

                if qty==0 and action in ['BUY','SELL']:
                    continue

                dateList.append(date)
                qtyList.append(qty)
                actionList.append(action)
                symbolList.append(cols[2].strip())

                try:
                    price=float(cols[6])
                except ValueError:
                    price=0.0
                priceList.append(price)
                try:
                    commission=float(cols[7])    
                except ValueError:
                    commission=0.0
                commissionList.append(commission)

                try:
                    amount=float(cols[10])
                except ValueError:
                    amount=0.0

                amountList.append(amount)
                accountList.append(account)
                
        data = {    'account':accountList,
                    "date":dateList,
                    "symbol":symbolList,
                    "action":actionList,
                    "qty":qtyList,
                    "origCost":priceList,
                    "amount":amountList,
                    "commission":commissionList,}
        
        dataAll=pd.DataFrame(data)
        dataAll=dataAll[dataAll['symbol'] != '']
        dataAll.loc[:,'badData']=dataAll['action'] == 'IGNORE'

        self.badData=dataAll[dataAll['badData']==True]
        dataAll=dataAll[dataAll['badData'] == False]
        self.dataEqty=dataAll[dataAll['symbol'].str[0] !='-']

        self.dataEqty=self.dataEqty.reset_index()

        #cleanupOptions 
        self.dataOption=dataAll[dataAll['symbol'].str[0]=='-']
        self.dataOption=self.dataOption.reset_index()
        
        underlyingList=[]
        expDateList=[]
        putCallList=[]
        strikeList=[]
        for index,row in self.dataOption.iterrows():
            (underlying,expDate,putCall,strike) = sec.Security.convertOptSymFid(row["symbol"])
            underlyingList.append(underlying)
            expDateList.append(expDate)
            putCallList.append(putCall)
            strikeList.append(strike)

  
        self.dataOption.loc[:,'underlying'] = underlyingList
        self.dataOption.loc[:,'expDate'] = expDateList
        self.dataOption.loc[:,'putCall'] = putCallList
        self.dataOption.loc[:,'strike'] = strikeList

    def isAction(self,data,bs):
        return bs in data["action"]

    def applyCorpAction(self,corpaction):
        for index, ca in corpaction.merger.iterrows():
            data=self.dataEqty.loc[ lambda df: self.dataEqty["symbol"] == ca["symbol"]]
            data=data.loc[lambda df: data["date"] < ca["date"]]

            mergedSyms=self.dataEqty["symbol"] == ca["symbol"]
            self.dataEqty.loc[mergedSyms,"symbol"] = ca["newSymbol"]
            self.dataEqty.loc[mergedSyms,"qty"]= data["qty"]*(ca['newQty']/ca['qty'])

            #TODO: Options
            print("Applied merger to " + ca['symbol'])

        for index, ca in corpaction.delist.iterrows():
            selectedRows=(self.dataEqty["symbol"] == ca["symbol"]) & (self.dataEqty["date"] < ca["date"]) & ((self.dataEqty["action"]=="BUY") | (self.dataEqty["action"]=="SELL"))

            data=self.dataEqty.loc[selectedRows,["symbol","qty"]]
            
            newrec=data.groupby("symbol").sum()
            data["qty"] = -1*newrec["qty"]
            data["action"] = "SELL"
            data["amount"] = newrec["qty"]*ca["price"]
            data["origCost"] = ca["price"]
            self.dataEqty=pd.concat([self.dataEqty,data])

            #TODO: Options
            print("Applied delist to " + ca['symbol'])

        for index, ca in corpaction.split.iterrows():
            factor=ca['new']/ca['old']

            selectedRows=(self.dataEqty["symbol"] == ca["symbol"]) & (self.dataEqty["date"] < ca["date"])
            self.dataEqty.loc[selectedRows,'qty'] = factor*self.dataEqty.loc[selectedRows,'qty']
            self.dataEqty.loc[selectedRows,'origCost'] = self.dataEqty.loc[selectedRows,'origCost']/factor

            #options
            selectedRows=(self.dataOption["underlying"] == ca["symbol"]) & (self.dataOption["date"] < ca["date"])
            self.dataOption.loc[selectedRows,'qty'] = factor*self.dataOption.loc[selectedRows,'qty']
            self.dataOption.loc[selectedRows,'origCost'] = self.dataOption.loc[selectedRows,'origCost']/factor
            self.dataOption.loc[selectedRows,'strike'] = self.dataOption.loc[selectedRows,'strike']/factor

            print("Applied split to " + ca['symbol'])

    def __init__(self):
        print("Transaction init")
        self.load()



class Position:

    def calcEquity(self, transaction):
        #Position cost and total qty
        data=transaction.dataEqty[["symbol","action","qty","amount","commission"]]
        eqtyBuy =data.loc[lambda df: data["action"] == "BUY",:]
        eqtyBuySym = eqtyBuy.groupby(["symbol"]).sum()
        eqtyBuySym["buyCost"] =    eqtyBuySym["amount"] / eqtyBuySym["qty"]
        eqtyBuySym=eqtyBuySym.rename(columns={"qty":"buyQty", "amount":"buyAmount"})

        eqtySell=data.loc[lambda df: data["action"] == "SELL",:]
        eqtySellSym = eqtySell.groupby(["symbol"]).sum()
        eqtySellSym["soldCost"] =    eqtySellSym["amount"] / eqtySellSym["qty"]
        eqtySellSym=eqtySellSym.rename(columns={"qty":"soldQty","amount":"soldAmount"})
        
        self.eqty=eqtyBuySym.add(eqtySellSym,fill_value=0)
        self.eqty=self.eqty.fillna(0)

        #Dividend
        tmp=transaction.dataEqty[["symbol","date","action","amount"]]
        self.dividend=tmp.loc[ lambda df: tmp["action"]=="DIV",:]
        self.dividendBySym=self.dividend[["symbol","amount"]].groupby(["symbol"]).sum()
        self.dividendBySym.rename(columns={'amount':'dividend'}, inplace="True")

        self.eqty=self.eqty.merge(self.dividendBySym, on='symbol', how='left')
        self.eqty.reset_index(inplace=True)
        #realized pnl and avgCost
        self.eqty.loc[:,'qty'] = self.eqty['buyQty'] + self.eqty['soldQty']
        
        #Realized pnl is calculated based on FIFO method
        symbolList=self.eqty['symbol']
        symbolList=['AAPL']

        for symbol in symbolList:
            tx=transaction.dataEqty.loc[lambda df:transaction.dataEqty['symbol']==symbol,:]
            tx=tx.sort_values(by=['account','date'])
            tx=tx.assign(rpnl=0)

  
            sellTx=tx.loc[lambda df:tx['action']=='SELL',:]
            rpnl=0
            totalPnl=0
            oldAccount=""

            for sellIndex, sellRow in sellTx.iterrows():
                sellQty=-1*sellRow['qty']   

                if sellRow['account'] != oldAccount:
                    buyTx=tx.loc[lambda df:(tx['action']=='BUY') & (tx['account']==sellRow['account']),:]
                    oldAccount=sellRow['account']

                for buyIndex, buyRow in buyTx.iterrows():
                    if buyRow['qty']==0:
                        continue
                    if buyRow['qty'] > sellQty:                      
                        buyTx.loc[buyTx['index']==buyRow['index'],'qty'] = buyRow['qty'] - sellQty       
                        rpnl += (sellRow['origCost'] - buyRow['origCost'])*sellQty
                        sellQty=0
                    else:
                        buyTx.loc[buyTx['index']==buyRow['index'],'qty']=0
                        rpnl += (sellRow['origCost'] - buyRow['origCost'])*buyRow['qty']
                        sellQty=sellQty-buyRow['qty']

                    if sellQty==0:
                        tx.loc[tx['index']==sellRow['index'],'rpnl'] = rpnl
                        transaction.dataEqty.loc[transaction.dataEqty["index"]==sellRow["index"],'rpnl']=rpnl
                        totalPnl += rpnl
                        print(symbol+"-"+sellRow['account']+" Rpnl :"+str(rpnl)+" TotRpnl :"+str(totalPnl)) 
                        rpnl=0

                        break

            self.eqty.loc[lambda df:self.eqty['symbol']==symbol,'rpnl'] = totalPnl
    
        self.eqtyCurrent=self.eqty.loc[lambda df:self.eqty['qty']>0,:]
        self.eqtyCurrent = self.eqtyCurrent.set_index("symbol")
        #TODO : These need to be properly corporate action adjusted
        self.eqtyCurrent=self.eqtyCurrent.drop(['CWENA','INXX','NUGT','QID','SIFY','SUNE','UVXY','WFM'])
        self.eqtyCurrent.loc[:,'avgDiv']  = self.eqtyCurrent['dividend']/self.eqtyCurrent['buyQty']
        self.eqtyCurrent.loc[:,'avgRpnl'] = self.eqtyCurrent['rpnl']/self.eqtyCurrent['buyQty']
        
        self.eqtyClosed=self.eqty.loc[lambda df:self.eqty['qty'] ==0,:]
     
    def calcAdjCost(self,optInc):
        self.eqty=self.eqty.merge(optInc, on="symbol")
        self.eqty.loc[:,'costBasis'] = (self.eqty['origCost']*self.eqty['qty'] - self.eqty['dividend'] - self.eqty['optInc'])/self.eqty['qty']

    def calcOption(self,transaction):
        #Option calculations

        today=dt.datetime.now().date()
        self.optionCurrent = self.dataOption.loc[lambda df:data['expDate'] > today,:]
        self.optionExpired = self.dataOption.loc[lambda df:data['expDate'] <= today,:]

        self.optionBySym = data.groupby(["underlying"]).sum().reset_index()
        self.optionBySym.rename(columns={'amount':'optInc'})

        data=data[["expDate","putCall","qty","amount","origCost","commission"]]
        self.optionByExp = data.groupby(["expDate"]).sum().reset_index()
        self.optionByExpPC = data.groupby(["expDate","putCall"]).sum().reset_index()

        data=transaction.dataOption[["date","qty","amount","origCost","commission"]]
        self.optionByDate = data.groupby(["date"]).sum().reset_index()

    def calcAdjCost(self,optInc):
        self.eqtyCurrent=self.eqtyCurrent.merge(optInc, on="symbol")
        self.eqtyCurrent.loc[:,'adjCost'] = self.eqtyCurrent['buyCost'] + self.eqtyCurrent['avgDiv'] +  self.eqtyCurrent['avgRpnl'] + self.eqtyCurrent['optInc']  
    
    def calcUpnl(self,quote):
        self.eqtyCurrent=self.eqtyCurrent.merge(quote.eqQuote.loc[:,["symbol","Close"]], on="symbol")
        self.eqtyCurrent["upnl"]=self.eqtyCurrent["qty"]*(self.eqtyCurrent["Close"] - self.eqtyCurrent["buyCost"])

        self.optionCurrent=self.optionCurrent.merge(quote.optionQuote.loc[:,:],on=["underlying","expDate","putCall","strike"])
        self.optionCurrent.loc[self.optionCurrent['qty']<0,'upnl'] = self.optionCurrent['amount'] + self.optionCurrent['bid']*self.optionCurrent['qty']*100
        self.optionCurrent.loc[self.optionCurrent['qty']>0,'upnl'] = self.optionCurrent['ask']*self.optionCurrent['qty']*100 + self.optionCurrent['amount']

def weGetEquity(self):
    return self.eqtyCurrent.loc[:,['symbol','qty','costBasis','origCost','close','mktValue','upnl','invested','income','roi']]


def main():
    print("starting main")
    corpAction = sec.CorporateAction()

    transaction = Transaction()
    print("Loaded Equity "+str(transaction.dataEqty.shape[0])+" Records")
    print("Loaded Options "+str(transaction.dataOption.shape[0])+" Records")

    transaction.applyCorpAction(corpAction)

    position = Position()
    position.calcEquity(transaction)


    position.calcOption(transaction)
    optInc=position.optionBySym[["underlying","amount"]].rename(columns={"underlying":"symbol", "amount":"optInc"})
    position.addOptInc(optInc)

    quote = sec.Quote()
    quote.loadEquity(position.eqtyCurrent["symbol"])
    if quote.eqQuote.empty:
        print("ERROR Loading Equity quotes")
        return
    
    quote.loadOptions(position.optionCurrent["symbol"])
    if quote.optionQuote.empty:
        print("ERROR Loading Option quotes")
        return
    
    position.calcUpnl(quote)
    position.calcAdjCost(optInc)

    print("Calculated Eqty and Options Positions")

    account = Account()
    #account.calcBalance(position)

    watchList= WatchList()
    #position.getSellPuts(watchList)

    security = sec.Security()
    #position.calcSecConcentration(security)

if __name__ == "__main__":
    main()
