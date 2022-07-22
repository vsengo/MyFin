#!/bin/bash

cd $HOME/Downloads/fidelity
dataDir=$HOME/Documents/MyFin/Finance_2021/Fidelity/BrkData

for f in `ls | grep History_for_Account`
do
   nf=`echo $f | awk -F. '{print $1}'`
   cp $dataDir/$nf.csv  $dataDir/$nf.csv.$$
   
   cat $f | grep -e [0-12] | grep -v  ^\" >> $dataDir/${nf}_2021_Q2.csv

   #for rw in `cat $f | grep -e [0-12] | grep -v  ^\"`
   #do
#	echo "RW => $rw"
#	mn=`echo $rw | awk -F, '{print $1}' | awk -F\/ '{print $1}'`
#	yr=`echo $rw | awk -F, '{print $1}' | awk -F\/ '{print $3}'`
#
#	if [ $mn -le 3 ]; then
#		Qt="Q1"
# 	elif [ $mn -le 6 ]; then
#		Qt="Q2"
# 	elif [ $mn -le 9 ]; then
#		Qt="Q3"
# 	elif [ $mn -le 12 ]; then
#		Qt="Q4"
#	fi
#
#	ofn=${nf}_${yr}_$mn.csv
#	cp $dataDir/$ofn   $dataDir/$ofn.$$
#	echo "output file :$ofn"
#	echo $rw 
#	#echo $rw >> $dataDir/$ofn	
#   done
done


