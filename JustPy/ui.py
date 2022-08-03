# Purpose: UI for myFin app
# 2022.07.01
#--------------------------------
import justpy as jp
import pandas as pd
import matplotlib.pyplot as plt


def getData(tableName, page):   
    data = pd.read_csv('http://localhost:1122/.csv?get'+tableName+'[]')
    page.grid.load_pandas_frame(data)
    page.table=True


def getEquity(self, msg):
    getData('CurrentEqty',msg.page)
def getBalance(self, msg):
    getData('Balance', msg.page)
def getRiskOption(self, msg):
    return getData('RiskOption',msg.page)
def getOption(self, msg):
    return getData('CurrentOptions',msg.page)
def getAccount(self, msg):  
    return getData('Account',msg.page)
def getOptionCall(self, msg):
    return getData('InvestCall',msg.page)
def getOptionPut(self, msg):
    return getData('InvestPut',msg.page)

def getOptionStrategy(self, msg):
    return getData('OptionStrategy',msg.page)

def getHome(self,msg):
    return charts()

def getCharts(page):   
    divRow1=jp.Div(classes='row', a=page)
    divRow2=jp.Div(classes='row', a=page)
    divRow3=jp.Div(classes='row', a=page)
    page.divRow1=divRow1
    page.divRow2=divRow2    
    page.divRow3=divRow3

    data = pd.read_csv('http://localhost:1122/.csv?getIncByMonth[]')
    data.jp.plot(0,data.loc[0].index,kind='bar', a=page.divRow1,title='Monthly Option Income',stacking='normal')
  
    #data = pd.read_csv('http://localhost:1122/.csv?getPnlByMonth[]')
    data = pd.read_csv('http://localhost:1122/.csv?getOptIncomeHist[]')
    data.jp.plot(0,data.loc[0].index,kind='spline', a=page.divRow1,title='Option Income Over Time',stacking='normal')

    data = pd.read_csv('http://localhost:1122/.csv?getOptRisk[]')
    data.jp.plot(0,data.loc[0].index,kind='bar', a=page.divRow2,title='Weekly  Option Risk',stacking='normal')

    data = pd.read_csv('http://localhost:1122/.csv?getOptIncome[]')
    data.jp.plot(0,data.loc[0].index,kind='bar', a=page.divRow2,title='Weekly Option Trades',stacking='normal')

    data = pd.read_csv('http://localhost:1122/.csv?getIncomeRate[]')
    data.jp.plot(0,data.loc[0].index,kind='bar', a=page.divRow3,title='Option and Dividend Rate',stacking='normal')
    
    data = pd.read_csv('http://localhost:1122/.csv?getBalanceChart[]')
    data.jp.plot(0,data.loc[0].index,kind='bar', a=page.divRow3,title='Portfolio Balance',stacking='normal')

    data = pd.read_csv('http://localhost:1122/.csv?getSector[]')
    #sector = data.iloc[:,[0]].values
    #invested=data.iloc[:,[1]].values
    
    #df_pie=pd.DataFrame(invested,index=sector,columns=['invested'])
    #df_pie.plot.pie(subplots=True,figsize=(8,8))
    #jp.Matplotlib(a=page)
    #data1 = data.iloc[:,[0,1]]
    #data1.jp.plot(0,data1.iloc[0].index,kind='pie', a=page.divRow3,title='Sectors Invested')
    
    data.jp.plot(0,data.loc[0].index,kind='bar', a=page.divRow3,title='Sectors Concentration vs Upnl')


def menu(wp):
    menus = jp.Div(classes='flex m-4 flex-wrap', a=wp)
    btGrp=jp.QBtnGroup(a=menus,name='menu')

    jp.QBtn(label='Home', a=btGrp,click=getHome)    
    jp.QBtn(label='Balance', a=btGrp,click=getBalance)
    jp.QBtn(label='Accounts', a=btGrp,click=getAccount)
    jp.QBtn(label='Equity', a=btGrp, click=getEquity)
    jp.QBtn(label='Options', a=btGrp, click=getOption)
    jp.QBtn(label='Risk Options', a=btGrp,click=getRiskOption)
    jp.QBtn(label='Invest Calls', a=btGrp,click=getOptionCall)
    jp.QBtn(label='Invest Puts', a=btGrp,click=getOptionPut)
    jp.QBtn(label='Option Strategies', a=btGrp,click=getOptionStrategy)
     
def home():
    wp = jp.QuasarPage()
    menu(wp)
    table = jp.Div(a=wp)
    grid=jp.AgGrid(a=table)
    wp.grid=grid   
    wp.table=table
    #getCharts(wp)
    getData('Balance',wp)
 
    return wp

def charts():
    wp = jp.QuasarPage()
    getCharts(wp)
    return wp

jp.Route('/charts',charts)
jp.Route('/getHome', getHome)
jp.Route('/getEquity', getEquity)
jp.Route('/getOption', getOption)
jp.Route('/getBalance', getBalance)
jp.Route('/getRiskOption', getRiskOption)
jp.Route('/getAccount', getAccount)
jp.Route('/getOptionCall', getOptionCall)
jp.Route('/getOptionPut', getOptionPut)
jp.Route('/getOptionStrategy', getOptionStrategy)

jp.justpy(home)
