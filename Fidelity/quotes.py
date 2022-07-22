#Download quotes from Yahoo finance and save to csv.
from yahoo_historical import Fetcher
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
for s in f:
	symbol=s.replace('\n','').split(",")[0]
	print("Fetching "+symbol)
	data=Fetcher(symbol,[from_date.year,from_date.month,from_date.day],[to_date.year,to_date.month,to_date.day])
	history=data.getHistorical()
	if history.empty:
		print("Bad Data :"+history.columns)
	else:
		fileName=fpath+symbol+".csv"
		history.to_csv(path_or_buf=fileName)

quit()
