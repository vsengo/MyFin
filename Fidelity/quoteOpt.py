import pandas as pd
import numpy as np
import yfinance as yf
import datetime
import sys, getopt

def options_chain(symbol,expDates, eod):

    tk = yf.Ticker(symbol)
    # Expiration dates
    exps = expDates

    # Get options for each expiration
    options = pd.DataFrame()
    if eod == 'y':
        exps = tk.options
    for e in exps:
        opt = tk.option_chain(e)
        opt = pd.DataFrame().append(opt.calls).append(opt.puts)
        opt['expirationDate'] = e
        options = options.append(opt, ignore_index=True)

    if  options.empty:
        print("No Option Series for ",symbol)
        return options

    # Bizarre error in yfinance that gives the wrong expiration date
    # Add 1 day to get the correct expiration date
    options['expirationDate'] = pd.to_datetime(options['expirationDate']) + datetime.timedelta(days = 1)
    options['dte'] = (options['expirationDate'] - datetime.datetime.today()).dt.days / 365
    
    # Boolean column if the option is a CALL
    options['CALL'] = options['contractSymbol'].str[4:].apply(
        lambda x: "C" in x)
    
    options[['bid', 'ask', 'strike']] = options[['bid', 'ask', 'strike']].apply(pd.to_numeric)
    options['mark'] = (options['bid'] + options['ask']) / 2 # Calculate the midpoint of the bid-ask
    
    # Drop unnecessary and meaningless columns
    options = options.drop(columns = ['contractSize', 'currency', 'change', 'percentChange'])

    return options


def main(argv):
    eod='n'
    try:
       opts, arg = getopt.getopt(argv,"he:",["eod"])
    except getopt.GetoptError:
        print('quoteOpt -h -eod <y/n>')
        sys.exit(2)
    for opt, arg in opts:
        if opt == '-h':
            print ('quoteOpt -h -eod <y/n>')
            sys.exit()
        elif opt in ("-e", "--eod"):
            eod=arg


    f=open("CURRENT_OPTION.csv","r")
    fpath="./options/"
    symbol=""
    expDates = []
    for s in f:
       data=s.replace('\n','').split(",")
       if data[0] == 'sym':
          continue
       if symbol != data[0]:
          if len(symbol) > 0:
             option=options_chain(symbol,expDates,eod)
             if option.empty:
              print("Bad Data :"+option.columns)
             else:
              fileName=fpath+symbol+".csv"
              option.to_csv(path_or_buf=fileName)
       expDates.clear()

       print(data)
       symbol=data[0]
       expDate=data[1]
       expDates.append(expDate)

if __name__ == "__main__":
     main(sys.argv[1:])
