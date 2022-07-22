\l util.q
\l tbls.q
.dat.PWD:first system "pwd"

{
	.lg.out["Loading ",x];
	data:delete x from ("DFFFFIFFF";enlist ",") 0: `$":",x;
	symbol:-4 _ 7 _ x;
	`quote upsert select sym:`$symbol, Date, Open,High, Low, Close, Volume from data; 

	} each system "ls quotes/*.csv"

{
	.lg.out["Saving to ",.dat.PWD];
	s:`$":",.dat.PWD,"/hdb/",string[x],"/quote/";
	s set .Q.en[`$":hdb";delete Date from select from quote where Date=x];
	} each exec distinct Date from quote;


{
        rec:"," vs x;
        `secmaster insert (`$3#rec),("F"$4 # 3 _ rec);;
        } each read0 `:symbols.txt;

delete quote from `.

\l hdb
{
	.lg.out["Saving ", string[x]];
	data::select from quote where sym=x;
	save `$":",.dat.PWD,"/quotes/history/data.csv";
	system "mv ",.dat.PWD,"/quotes/history/data.csv ",.dat.PWD,"/quotes/history/",string[x],".csv";	
	 } each exec distinct sym from secmaster;
\\
