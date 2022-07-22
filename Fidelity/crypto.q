\l util.q
\l tbls.q
\c 100 200

{
	.lg.out["Loading ",x];
	system "mv  /Users/sengo/Downloads/",x," Crypto/cointracker.csv";
	} each system "ls /Users/sengo/Downloads/transactions_HIFO_Universal* | awk -F\/ '{print $5}'";

crypto_transaction:("ZSSFSSSSSSFSFFSSSSFSFS";enlist ",") 0:`$":Crypto/cointracker.csv"
crypto_transaction:(`date`action`tranid`qty`sym`amount`costBasis`wallet`address`tag`comment`sqty`scur`balance`scostBasis`sWallet`sAddress`sTag`sComment`fee`fcur`rpnl) xcol crypto_transaction
update date:`date$date, amount:"F"$string amount, costBasis:"F"$string costBasis, sqty:"F"$string sqty, fee:"F"$string fee, "F"$string rpnl  from `crypto_transaction

knownCrypto:(`BTC`ETH`LTC`SOL`ADA`CGLD`ALGO`XLM`GRT`CELO`USD)
fcrypto:{[x]; 
	i:0;ret:`unk;	
	do [ count knownCrypto;
		y:knownCrypto[i];
		if [ not 0N=first ss[string[x];string[y]]; ret:y]; 
		i:i+1;
		];
	:ret}
	
delete from `crypto_transaction where sym in (`ALGO`CGLD`XLM`GRT`CGLO`CELO)
delete from `crypto_transaction where action like "Indicates*"

update amount:sqty  from `crypto_transaction where action=`Buy
update amount:qty, sym:fcrypto'[sWallet]  from `crypto_transaction where action in (`Sell`Send);
update qty:sqty from `crypto_transaction where action=`Sell;
update qty:sqty, amount:"F"$string scostBasis  from `crypto_transaction where action=`Send

ltc:first exec sum amount from crypto_transaction where sym=`LTC, date<2020.01.01
ltcQ:first exec sum qty from crypto_transaction where sym=`LTC, date<2020.01.01
update amount:ltc, action:`Buy from `crypto_transaction where sym=`BTC, action=`Trade, date<2020.01.01

transaction:crypto_transaction:select sum qty, sum amount, sum fee by date, sym, action from crypto_transaction

delete from `transaction where action in (`Transfer`Receive)
delete from `transaction where action in (`Send`Receive), sym=`USD
update action:`Sell from `transaction where action=`Send
update costBasis:amount % qty from `transaction
update amount:-1*amount, qty:-1*qty from `transaction where action=`Sell

position:update costBasis:amount%qty from select sum amount, sum qty  by sym from transaction
delete from `position where qty < 0.0001
sold_cost:raze { select sum amount, sum qty by date:x`date, sym:x`sym from transaction where sym=x`sym, action=`Buy,date <=x`date } each select sym, date from transaction where action=`Sell;
update avgCost:amount % qty from `sold_cost;
transaction:transaction lj 2!select date,sym,avgCost from sold_cost;
update rpnl:(avgCost -  costBasis)*qty from `transaction;

sold_position:select from transaction where action=`Sell;
pnl_yearly:(`year) xdesc select `int$sum rpnl by date.year  from sold_position;
pnl_bySym:select sum rpnl by sym from sold_position;
\p 1133
