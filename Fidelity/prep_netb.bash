#!/bin/bash
# Usage :Download transaction from Netb.fmr.com save as Netb_yyyy_Q1.csv in NetbData dir and run this
#----------------------------------------------------------------
newfname=Netb.dat
#find end of transasction
cd NetbData;
echo "Date,Investment,Type,Amount,Shares" > $newfname
for fname in `ls Netb_20*.csv`
do
	yr=`echo $fname | awk -F_ '{print $2}' | awk -F. '{print $1}'`
	echo "Doing $fname -> $yr"
	if [ $yr -le 2020 ]; then
		n=`grep -n 'Date,Investment,Transaction' $fname | awk -F: '{print $1}'`
		sed -e "1,$n"d $fname >> $newfname
	else
		cat $fname | sed -e 's/\"//g' | grep -v Date >> $newfname
	fi
done
echo "$newfname updated"
