#Download quotes from Yahoo finance and save to csv.
import yfinance as yf
import subprocess
import datetime
import sys, getopt

dates=subprocess.check_output("ls -t hdb | grep 202", shell=True).decode()
all_dates=dates.split("\n")
last_date=all_dates[0]
first_date=all_dates[len(all_dates)-1]
yy=int(last_date.split('.')[0])
mm=int(last_date.split('.')[1])
dd=int(last_date.split('.')[2])

from_date=datetime.date(yy,mm,dd) + datetime.timedelta(days=1)
# use argParse to parse optional argument.

to_date=datetime.date.today() + datetime.timedelta(days=1)
if from_date == to_date:
	print("Latest quotes downloaded deleting "+last_date)
	from_date=datetime.date(yy,mm,dd)
	subprocess.check_output("rm -r hdb/"+last_date, shell=True).decode()

print("Fetching Date Range :"+from_date.strftime("%Y%m%d")+" to "+to_date.strftime("%Y%m%d"))


f=open("symbols.txt","r")
fpath="./quotes/"
def getQuote(from_date, to_date, f, fpath):
    for s in f:
        symbol=s.replace('\n','').split(",")[0]
        if symbol != 'sym':
            print("Fetching "+symbol)
            ticker=yf.Ticker(symbol)
            data=ticker.history(interval='1d',start=from_date.strftime("%Y-%m-%d"),end=to_date.strftime("%Y-%m-%d"))
            data.head()
            if data.empty:
                print("Bad Data :"+data.columns)
            else:
                fileName=fpath+symbol+".csv"
                data.to_csv(path_or_buf=fileName)

getQuote(from_date, to_date, f, fpath)

quit()
