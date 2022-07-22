#----------------------------------
# Purpose : to format positions downloaded from
# Fidelity accounts.
# Download Positions from Both accounts. 
# run the script with date as parameter
# File format changed so need to modify it.
#-----------------------------------------------
#!/bin/bash

if [ $# -lt 1 ]; then
      echo "Prep_position <fileName>"
      exit 0;
fi

fname=$1
date=`
newfname=Position_EQ.csv
echo "Account,Symbol,Description,Qty,Price,PriceChange,MktValue,gain,gainp,dayGain,dayGainP,annualGainP,CostBasis,TotalCost,margin" > $newfname
cat $fname | sed -e '1,1d' | sed -e 's/\$//g' >> $newfname

exit 0

for f in `ls Portfolio_Positions_$date.csv | awk -F. '{print $1}'`
do
	echo "Processing $f";
	fname=./$f.csv
	echo "$f $fname $newfname";
	#find end of transasction
	n=`grep -n 'Fidelity.com' $fname | awk -F: '{print $1}'`
	n=`expr $n - 1`
	end=`cat $fname | wc -l`
	#cut 3rd to n and create a file
	sed -e "$n,$end"d $fname | sed -e '1,1d' | sed -e 's/\$//g' >> $newfname
done
q position.q
