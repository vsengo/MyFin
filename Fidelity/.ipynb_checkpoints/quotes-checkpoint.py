#Download quotes from Yahoo finance
from yahoo_historical import Fetcher

f=open("symbols.txt","r")
for symbol in f:
	print("Fetching "+symbol)
	data=Fetcher(symbol,[2022,1,1],[2022,04,06])
	history=data.getHistorical()
	fileName=symbol+".csv"
	history.to_csv(path_or_buf=fileName)
