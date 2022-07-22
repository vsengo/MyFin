#!/bin/bash
LOGFILE=log/download_quotes.log
echo $APPS_HOME >> $LOGFILE 2>&1
source venv/bin/activate
python3 quoteEqy.py   >> $LOGFILE 2>&1
python3 quoteOpt.py -eod n   >> $LOGFILE 2>&1
QHOME=/Applications/q   >> $LOGFILE 2>&1
$QHOME/m64/q quotes.q   >> $LOGFILE 2>&1
$QHOME/m64/q quoteOpt.q   >> $LOGFILE 2>&1

