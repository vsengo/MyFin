\l util.q
transaction:([]
	account :`symbol$();
	date	:`date$();
	time	:`time$();
	action	:`symbol$();
	symbol	:`symbol$();
	qty	:`float$();
	price	:`float$();
	cost	:`float$();
	fee	:`float$();
	descrp  :());

filename:.arg.getArg[`coinbase];
data:1_read0 `$":",filename;
{
	xx:"," vs x;
	`transaction insert (`coinbase;"D"$10#xx[0];("T"$-1 _ 11_xx[0]);`$xx[1];`$xx[2];"F"$xx[3];"F"$xx[4];"F"$xx[6];"F"$xx[7];xx[8]);
	} each data;


filename:.arg.getArg[`coinbasePro];
data:1_read0 `$":",filename;
{
	xx:"," vs x;
	symbol:`$first "-" vs xx[2];
	dt:"D"$10#xx[4];
	tm:"T"$-1 _ 11_xx[4];
	`transaction insert (`coinbasePro;dt;tm;`$xx[3];symbol;"F"$xx[5];"F"$xx[7];"F"$xx[9];"F"$xx[8];`);
	} each data;


delete from `transaction where symbol=`ALGO;
trans_summary:select sum qty, sum cost, sum fee by symbol,action,date from transaction;
update costBasis:cost % qty from `trans_summary;
update action:`BUY from `trans_summary where action=`Buy;
update action:`SELL from `trans_summary where action=`Sell;
update qty:-1*qty  from `trans_summary where action=`SELL;
position:select sum qty, sum cost, sum fee by symbol from trans_summary;
show position
