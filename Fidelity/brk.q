/-------------------------------------------------------------------------------------
/ Purpose: Calculate Position using all transactions downloaded from Fidelity accounts
/ Updated: Original 2018.02.12
/------------------------------------------------------------------------------------
\l util.q
\l tbls.q
\c 100 200
.dat.PWD:first system "pwd"

.arg.getArg[`dataDir;"BrkData"];

/if there is new files from today move 
yr:4#string .z.D;
mt:"I"$2#5 _ string .z.D;
qtr:$[mt < 4;"1";$[mt < 7;"2";$[mt<10;"3";"4"]]]

{
	rec:"," vs x;
	`secmaster insert (`$3#rec),("F"$4# 3 _ rec);;
	} each 1 _ read0 `:symbols.txt;

WATCHLIST:("SSJF";enlist ",") 0:`$":",.arg.dataDir,"/watchlist.csv";

{
	nf:(-4 _ x),"_",yr,"_Q",qtr,".csv";
	system "mv  /Users/sengo/Downloads/",x," ",.arg.dataDir,"/",nf;
	} each system "ls /Users/sengo/Downloads/History_for_Account* | awk -F\/ '{print $5}'";

load_data:{[f];
	tx:read0 `$":",.arg.dataDir,"/",f;
	.dt.acc:`$9 # 20 _ f;
	.dt.qtrStart:-2+3*"I"$-1#-4 _ last ("_" vs f);
	.dt.qtrEnd:3*"I"$-1#-4 _ last ("_" vs f);
	.lg.out["Loading ",f];

	{
		rec:"," vs x;
		dt:"D"$rec[0];
		/.lg.out[" dt :",string[dt], " - ", string[.dt.qtrStart],":",string[.dt.qtrEnd]];

		
		if[ not 0Nd=dt;
			$[not (`mm$dt) within (.dt.qtrStart;.dt.qtrEnd);
				.lg.out["Ignoring ",rec[0], " outside ",string[.dt.qtrStart],"-",string[.dt.qtrEnd]];
				`transaction insert ("D"$rec[0];`$rec[1];`$rec[2];`$rec[3];`$rec[4];"F"$rec[5];"F"$rec[6];"F"$rec[7];"F"$rec[8];"F"$rec[9];"F"$rec[10];"D"$rec[11];.dt.acc) ]]; } each tx;
	}
load_data each system "ls ",.arg.dataDir," | grep History_for_Account_";
ACCOUNT:("SSFF";enlist ",") 0:`$":",.arg.dataDir,"/account.csv"

ca_split:([sym:`symbol$();date:`date$()]; old:`float$();new:`float$());
`ca_split insert (`NUGT;2020.04.23;4.0;1.0);
`ca_split insert (`QID;2018.05.24;4.0;1.0);
`ca_split insert (`SDS;2017.07.17;4.0;1.0);
`ca_split insert (`SQQQ;2020.08.18;5.0;1.0);
`ca_split insert (`TSLA;2020.08.31;1.0;5.0);
`ca_split insert (`NVDA;2021.07.20;1.0;4.0);

ca_merger:([];sym:`symbol$();date:`date$(); to:`symbol$();qty:`int$();toQty:`int$())
`ca_merger insert (`SCTY;2016.11.22;`TSLA;100;11);
`ca_merger insert (`IPOC;2021.03.01;`SOFI;100;100);
`ca_merger insert (`IPOE;2021.06.01;`SOFI;100;100);
`ca_merger insert (`NYLD;2015.05.15;`NYLDA;100;200);
`ca_merger insert (`NYLDA;2015.05.16;`CWENA;100;100);
`ca_merger insert (`NRG;2015.05.16;`CWEN;100;200);
`ca_merger insert (`FB;2022.06.08;`META;100;100);
`ca_merger insert (`4750169AS;2022.06.08;`$"-FB220617C210";100;100);

ca_delist:([];sym:`symbol$();date:`date$();price:`float$());
`ca_delist insert(`SIFY;2021.06.01;0.0);
`ca_delist insert(`SUNE;2019.10.08;0.0);
`ca_delist insert(`WFM;2017.08.28;42.0);
`ca_delist insert(`INXX;2019.06.21;11.42);

delete from `transaction where sym=`MAXFDRX97;
delete from `transaction where action like "REINVESTMENT";
delete from `transaction where action like "PURCHASE INTO CORE*";
delete from `transaction where action like "REDEMPTION FROM CORE*";
delete from `transaction where action like "NAME CHANGED*";
delete from `transaction where action like "DISTRIBUTION*";
update action:`BUY from `transaction where action like "YOU BOUGHT*"

update action:`BUY from `transaction where action like "ADJUST EXERCISE*", not qty=0N;
update action:`SELL from `transaction where action like "YOU SOLD*"
update action:`SELL from `transaction where action like "EXPIRED*"
update action:`DIV from `transaction where action like "DIVIDEND*"
update action:`DIV from `transaction where action like "LONG-TERM*"
update action:`DIV from `transaction where action like "SHORT-TERM*"
update action:`DIV from `transaction where action like "RETURN OF CAPITAL*"
update action:`CA_RVP from `transaction where action like "REVERSE SPLIT*"
update action:`CA_DELST from `transaction where action like "LIQUIDATION*"
update action:`CA_MERG  from `transaction where action like "MERGER*"

update action:`FEE from `transaction where action like "FEE CHARGED*"
update action:`FEE from `transaction where action like "FOREIGN TAX*"
update action:`CONTRIBUTION, sym:`FDRXX from `transaction where action like "CASH CONTRIBUTION*"

update action:`DISTRIBUTION, sym:`FDRXX from `transaction where action like "*NORMAL DIST*"
update action:`DISTRIBUTION, sym:`FDRXX from `transaction where action like "BILL PAYMENT*"

update sym:`AGNC from `transaction where description like "AMERICAN CAP AGY*";
update sym:`CASH from `transaction where action  like "INTEREST EARNED";
update sym:`WFM from `transaction where sym=`966837106;
update sym:`SDS from `transaction where sym=`74347B300;
update sym:`CTIC from `transaction where sym=`12648L106;
update sym:`INXX from `transaction where sym=`268461845;
update sym:`SCTY from `transaction where sym=`83416T100;
update sym:`NRG  from `transaction where sym=`62942X108;
update sym:`NYLD  from `transaction where sym=`62942X306;
update sym:`NYLDA  from `transaction where sym=`62942X405;
update sym:`IPOC from `transaction where sym=`G8251K107;
update sym:`$"-FB220617C210" from `transaction where sym=`4750169AS;

opt_transaction:select from transaction where sym like "-*"
transaction:delete from transaction where sym like "-*";
/convert opra symbols to sym,putcall,exp,price
optsym:{[sym;t];
	n:first (string sym) ss "[12][0123456789]";
	s:`$1 _ n # string[sym];	
	c:`$1# (6+n) _ string[sym];
	d:"D"$"20",6# n _ string[sym];
	p:"F"$(7+n) _ string[sym];
	$[t~`S;s;$[t~`C;c;$[t~`D;d;p]]]}


/calculate option income
update underlying:optsym'[sym;`S], putcall:optsym'[sym;`C], expDate:optsym'[sym;`D], strike:optsym'[sym;`P] from `opt_transaction;
position_opt_exp:select sum amount by account, underlying, putcall, expDate, strike  from opt_transaction

opt_spread:select sum amount,  distinct action, distinct strike, distinct expDate  by account, underlying, putcall, date  from opt_transaction
opt_spread:update strategy:`spread from opt_spread where 2={count x}'[action], 2={count x}'[strike], 1={count x}'[expDate]
opt_spreadpair:select from opt_spread where strategy=`spread 
/opt_spread:opt_spread lj (`underlying`putcall`expDate) xkey opt_transaction

/apply corp actions
{
	.lg.out["applying merger to ", string[x`sym]];
	factor:(x`toQty) % x`qty;
	update qty:qty*factor, sym:x`to from `transaction where sym=x`sym, date <= x`date;
	update cost:-1*amount % qty  from `transaction where sym=x`to, date <= x`date;
	update qty:qty*factor, underlying:x`to from `opt_transaction where underlying=x`sym, date <= x`date;
	update cost:-1*amount % qty  from `opt_transaction where underlying=x`to, date <= x`date;
	update underlying:x`to from `position_opt_exp where underlying=x`sym;
	} each 0!(`date) xasc select from ca_merger;

{
	.lg.out["applying delist to ", string[x`sym]];
	newrec:(1#select from transaction where sym=x`sym) lj select sum qty by sym from transaction where sym=x`sym, action in (`BUY`SELL),date <= x`date;
	`transaction insert  update cost:x`price, qty:-1*qty, amount:qty*(x`price),  action:`SELL, date:x`date  from newrec;
	} each 0!ca_delist;


{
	.lg.out["applying split to ", string[x`sym]];
	factor:(x`new) % x`old;
	update qty:qty*factor, cost:cost%factor from `transaction where sym=x`sym, date <= x`date;
	} each 0!ca_split;

position_current:update avg_cost: amount % qty from select sum amount, invested:sum {$[x~`BUY;y;0]}'[action;amount], sum qty, long_qty:sum {$[x~`BUY;y;0]}'[action;qty], last account  by sym  from transaction where action in (`BUY`SELL);
position_current:select from position_current where qty > 1.0

dividend:select sum amount by sym, date.year, date.month from transaction where action in (`DIV`FEE);
dividendBySym:select divInc:0.0^sum amount by sym from dividend;
dividendByMonth:(`month) xdesc select divIncd:sum amount by year,month from dividend;
dividendByYear:select divInc:sum amount by year from dividend;
dividendBySymYear:select divInc:sum amount by sym, year from dividend where amount > 0
dividendBySymYear:update perDiv:100.0*divInc%amount from dividendBySymYear lj position_current

position_current:position_current lj dividendBySym;
position_current:update costBasis:origCost from update optInc:0j, origCost:-1*invested%long_qty from position_current lj 1!ACCOUNT;


/calculate option income
if [ 0 < count position_opt_exp;
	opt_pnlBySym:select optInc:floor 0.0^sum amount by sym:underlying from position_opt_exp;
	opt_pnlByExpiry:(`expDate) xdesc select opt:0.0^sum amount by expDate from position_opt_exp;
	opt_pnlByMonthType:(`expDate) xdesc select opt:0.0^sum amount by `month$expDate, putcall  from position_opt_exp;
	opt_pnlByYear:`expDate xdesc select opt:0.0^sum amount by `year$expDate from position_opt_exp;
	opt_pnlRate:update optIncRate:12*opt%`mm$.z.D from select opt:0.0^sum amount by sym:underlying  from position_opt_exp where (`year$expDate) = `year$.z.D;

	CURRENT_OPTION:(`putcall`sym) xasc (`sym) xcol (`underlying`putcall`strike`action`qty`cost`amount) xcols delete sym,description,sectype,commission,fee,interest,settle_date from select from  opt_transaction where .z.D <= expDate;
	update risk:qty*100*strike  from `CURRENT_OPTION;
	CURRENT_OPTION:select sum qty, sum amount, sum risk, sum {$[x~`BUY;-1*y;y]}'[action;cost], max date  by account,sym, expDate, putcall, strike from CURRENT_OPTION;
	opt_pnl:select from CURRENT_OPTION where qty=0;
	delete from `CURRENT_OPTION where qty=0;

	position_current:position_current lj opt_pnlBySym lj 1!select sym, optIncRate from opt_pnlRate;
	update costBasis:-1*(amount + (0.0^divInc) + (0.0^optInc)) % qty from `position_current;
	update optIncRate:abs 100.0*optIncRate%invested  from `position_current;
	
	];

/realized pnl
sold_cost:raze { select sum amount, sum qty by date:x`date, sym:x`sym from transaction where sym=x`sym, action=`BUY,date <=x`date } each select sym, date from transaction where action=`SELL;
update avgCost:amount % qty from `sold_cost;
transaction:transaction lj 2!select date,sym,avgCost from sold_cost;
update rpnl:-1*(avgCost + cost)*qty from `transaction;

sold_position:select from transaction where action=`SELL;
sold_position:update tax:`YES from sold_position where account in (`X01601829);
sold_position:(`sym) xasc update tax:`NO from sold_position where not account in (`X01601829);

pnl_yearly:(`year) xdesc select `int$sum rpnl by date.year  from sold_position;
pnl_bySym:select sum rpnl by sym from sold_position;

position_current:position_current lj pnl_bySym;
CURRENT_EQTY:0!select sym, acc_name,qty,origCost,floor 0.0^divInc,floor 0.0^optInc, optIncRate, floor 0.0^rpnl,costBasis from position_current

\l hdb
hdbDates:date
last_date:last date;
quotes:1!select sym, Close from quote where date=last_date;
prev20:first -20# hdbDates;
prev01:first -2# hdbDates;
quoteStats:select minClose:min Close, maxClose:max Close, avgClose:avg Close, stdClose:dev Close, Close:last Close by sym from quote where date within (prev20;last_date);
quoteStats:update perChg:100*(Close - prevClose) % prevClose from  quoteStats lj select  prevClose:last Close by sym  from quote where date=prev01;

CURRENT_EQTY:CURRENT_EQTY lj quotes;
update upnl:floor (Close - origCost)*qty, roi:floor 100*(Close-costBasis)%origCost, upnlReal: floor (Close - costBasis)*qty from `CURRENT_EQTY; 
CURRENT_EQTY:update PE:`int$Close % eps, divRate:100.0*dividend%Close  from CURRENT_EQTY lj secmaster;

totalInvested:first exec sum qty*origCost from CURRENT_EQTY;
totalMktValue:first exec sum qty*Close    from CURRENT_EQTY;
CURRENT_EQTY:update perInvested:100.0*invested%totalInvested, perMv:100.0*mktValue%totalMktValue from update mktValue:floor qty*Close, invested:floor origCost*qty  from CURRENT_EQTY
RISK_SECTOR:update perInv:100*invested % totalInvested,perMv:100*mktValue%totalMktValue from select sum invested, sum mktValue, sum divInc, sum optInc, sum rpnl, sum upnl, sym  by sector from CURRENT_EQTY
RISK_SECTOR:(`invested) xasc update roi:ceiling 100.0*(mktValue - invested - Income) % abs(invested)  from update Income:divInc + optInc + rpnl from RISK_SECTOR;

save `$":",.dat.PWD,"/CURRENT_EQTY.csv"
yahoo_portfolio:(`Symbol) xdesc update Date:{`$ssr[string[x];".";"/"]}'[.z.D],Time:{`$(5#string[x])," EDT"}'[.z.T] ,Change:0,Open:0.0,High:0.0,Low:0.0,Volume:0,TradeDate:{`$ssr[string[x];".";""]}'[.z.D],Commission:0.0,High_Limit:0.0,Low_Limit:0.0,Comment:` from select Symbol:sym, Current_Price:Close,Purchase_Price:costBasis,Quantity:qty from CURRENT_EQTY
yahoo_portfolio:(`Symbol`Current_Price`Date`Time`Change`Open`High`Low`Volume`TradeDate`Purchase_Price`Quantity`Commission`High_Limit`Low_Limit`Comment) xcols yahoo_portfolio
update Purchase_Price:0.0 from `yahoo_portfolio where Purchase_Price<0.0;

save `$":",.dat.PWD,"/yahoo_portfolio.csv"
system "cp ",.dat.PWD,"/yahoo_header.csv ",.dat.PWD,"/yahoo_import.csv"
system "cat ",.dat.PWD,"/yahoo_portfolio.csv | grep -v Symbol >> ",.dat.PWD,"/yahoo_import.csv;"

optrpnl:0.0;
if [ 0 < count position_opt_exp;
	CURRENT_OPTION:(`sym`expDate) xasc (`sym`expDate`putcall`strike`Close`qty`cost`amount`risk`account) xcols 0!CURRENT_OPTION lj quotes;

	/load option quotes from hdb

	optQuotes:raze { 4!select sym, expDate, putcall, strike, lastPrice, bid,ask, openInterest, volume  from optquote where date=last date, sym=x`sym, expDate=x`expDate, putcall=x`putcall, strike=x`strike } each 0!select by sym,expDate,putcall,strike from CURRENT_OPTION;
	CURRENT_OPTION:CURRENT_OPTION lj optQuotes;
	CURRENT_OPTION:CURRENT_OPTION lj 1!select sym, costBasis from CURRENT_EQTY;
	CURRENT_OPTION:CURRENT_OPTION lj 1!select account, acc_name  from ACCOUNT;

	update upnl:-1*qty*100*(strike - costBasis) from `CURRENT_OPTION where putcall=`C,qty<0;
	update upnl:qty*100*(strike - costBasis) from `CURRENT_OPTION where putcall=`C, qty>0;
	save `$":",.dat.PWD,"/CURRENT_OPTION.csv";

	option_spread:select cnt:count i, totQty:sum qty,qty, strike, totCost:sum cost, cost, totAmount:sum amount, amount, lastPrice, last Close  by sym, expDate, putcall  from CURRENT_OPTION;
	delete from `option_spread where not cnt=2;
	OPTION_STRATEGY:0!update strategy:`DebitSpread from select  from option_spread where totQty=0, totAmount<0.0;
    OPTION_STRATEGY,:0!update strategy:`CreditSpread from select from option_spread where totQty=0, totAmount>0.0;

	option_straddle:select cnt:count i, cntPutCall:count distinct putcall, totQty:sum qty, strike, totCost:sum cost, cost, totAmount:sum amount, amount, lastPrice, last Close  by sym, expDate, qty  from CURRENT_OPTION;
	option_straddle:delete cntPutCall from select from option_straddle where cnt=2, cntPutCall=2;
	update strategy:`Straddle, putcall:`PC from `option_straddle where (totQty<0),totAmount>0;

    OPTION_STRATEGY,:(cols OPTION_STRATEGY) xcols 0!option_straddle;

	OPTION_STRATEGY:ungroup delete cnt from select from  OPTION_STRATEGY;	
	update cost:-1.0*cost from `OPTION_STRATEGY where totAmount < 0.0;
	update upnl:100*((qty*lastPrice) -  qty *cost)  from `OPTION_STRATEGY;
	OPTION_STRATEGY:select strike, last Close, cost, lastPrice,sum upnl,costBasis:first totAmount, qty, breakEven:min strike - first totCost by sym, expDate, putcall, strategy  from OPTION_STRATEGY;

	update roi:-100.0*upnl%costBasis, maxProfit:{100*(abs first y)*((max x) - min x)}'[strike;qty]+costBasis  from `OPTION_STRATEGY where strategy=`DebitSpread;
	update roi:-100.0*upnl%costBasis, maxProfit:costBasis  from `OPTION_STRATEGY where strategy=`Straddle;

	update roiMax:100.0*maxProfit%costBasis from `OPTION_STRATEGY;
	update action:`Take_Profit from `OPTION_STRATEGY where strategy=`DebitSpread, roi > 75.0;
	update action:`Cut_Loss from `OPTION_STRATEGY where strategy=`DebitSpread, roi <  -50.0;

	RISK_OPTION:update reason:`Loss_Call from select from CURRENT_OPTION where putcall=`C,strike <= costBasis, upnl<0, qty<0;
	RISK_OPTION,:update reason:`Assigned_Call from select from CURRENT_OPTION where putcall=`C,strike <= Close, qty<0;
	RISK_OPTION,:update reason:`Assigned_Put from select from CURRENT_OPTION where putcall=`P, Close <= strike;
	RISK_OPTION:(`upnl) xasc (`expDate`sym`putcall`strike`Close`costBasis`upnl) xcols RISK_OPTION;
	RISK_OPTION_TOTAL:select cash:sum risk,  unpl: sum upnl, count i by putcall from RISK_OPTION;

	PROFIT_OPTION:(`roi) xdesc update roi:floor 100*(cost - 0.5*(bid + ask)) % cost from CURRENT_OPTION;
	delete from `PROFIT_OPTION where roi < 60;

	CURRENT_EQTY:CURRENT_EQTY lj select optCallQty:sum 100*qty, min strike, min expDate  by sym from CURRENT_OPTION where putcall=`C;
	INVEST_OPTION_CALL:select cost:(sum qty*costBasis) % (sum qty) ,distinct Close,(sum qty + 0^optCallQty)%100, last costBasis  by sym, acc_name from CURRENT_EQTY;
	delete from `INVEST_OPTION_CALL where qty=0;
	delete from `INVEST_OPTION_CALL where sym in (`CUBA`CLM`IFN`AGNC);
	INVEST_OPTION_CALL:delete cost, prevClose, perChg, upnl from update strike:ceiling (Close + stdClose)  from INVEST_OPTION_CALL lj (`sym) xkey quoteStats;
	INVEST_OPTION_PUTT:select sym, qty:share % 100, strike:cost from WATCHLIST where action=`BUY;
	INVEST_OPTION_PUTT:INVEST_OPTION_PUTT lj (`sym) xkey quoteStats;
	INVEST_OPTION_PUTT:INVEST_OPTION_PUTT lj select oldqty:sum qty, oldstrike:avg strike by sym from CURRENT_OPTION where putcall=`P;
	INVEST_OPTION_PUTT:INVEST_OPTION_PUTT lj `sym xkey select sym, curQty:qty, costBasis  from CURRENT_EQTY;
	INVEST_OPTION_PUTT:select sym, qty + 0.0^oldqty, strike, invest:qty*100*strike,  oldqty, oldstrike, costBasis, Close, minClose, maxClose, stdClose from INVEST_OPTION_PUTT;
	delete from `INVEST_OPTION_PUTT where qty <=0;
	(`upnl) xdesc update upnl:ceiling 100.0*(strike - costBasis) % abs costBasis, ceiling strike from  `INVEST_OPTION_CALL;
    INVEST_OPTION_STRATEGY:(`upnlToReduce) xdesc select sym, acc_name, upnlToReduce:`int$100*qty*(costBasis - Close) from INVEST_OPTION_CALL where upnl < -20.0;  

	ACCOUNT:ACCOUNT lj select opt_cash:sum risk by account from CURRENT_OPTION where putcall=`P;
	optrpnl:first exec opt from opt_pnlByYear where expDate = `year$.z.D;
	];

update free_cash:total_cash + opt_cash from `ACCOUNT;

WATCHLIST:WATCHLIST lj 1!select sym, Close, stdClose from quoteStats
WATCHLIST:WATCHLIST lj 1!select sym, target1yr from  secmaster
WATCHLIST:WATCHLIST lj 1!select sym, curQty:qty, origCost, costBasis from CURRENT_EQTY
update newQty:curQty - share, newOrigCost:((origCost*curQty) - (share*cost))%(curQty - share), newCostBasis:((costBasis*curQty) - share*cost)%(curQty - share) from `WATCHLIST where action=`SELL;
update curQty:0.0, origCost:cost, costBasis:0.0 from `WATCHLIST where curQty=0n;
update newQty:share+curQty, newOrigCost:((origCost*curQty) + (share*cost))%(curQty + share), newCostBasis:((costBasis*curQty) + share*cost)%(curQty + share) from `WATCHLIST where action=`BUY;
update newInvest:share*cost, newTotal:newQty*newCostBasis from `WATCHLIST where action=`BUY;
update newInvest:-1.0*share*cost, newTotal:newQty*newCostBasis from `WATCHLIST where action=`SELL;
WATCHLIST:(`action`sym) xasc WATCHLIST

WATCHLIST_SELL:(select from WATCHLIST where action=`SELL) lj 1!CURRENT_EQTY
WATCHLIST_SELL:(`roi) xdesc select sym, acc_name, qty, sell:share, origCost, costBasis, Close, upnl, upnlReal, roi from  WATCHLIST_SELL

cash:exec sum total_cash, sum opt_cash from ACCOUNT where not account like "Y*"
`BALANCE insert (`Cash; `int$first cash`total_cash;0)
`BALANCE insert (`CoveredCash; `int$first cash`opt_cash;0)
tmp:exec mktValue: sum share*cost, futureValue:sum share*target1yr  from WATCHLIST where action=`BUY;
`BALANCE insert (`ToBuy; `int$first tmp`mktValue; `int$first tmp`futureValue)

tmp:exec mktValue: sum share*cost, futureValue:sum share*target1yr  from WATCHLIST where action=`SELL;
`BALANCE insert (`ToSell; `int$first tmp`mktValue; `int$first tmp`futureValue)
futureCash:first (exec currentValue from BALANCE where item=`Cash) + (exec currentValue from BALANCE where item=`ToSell) - exec currentValue from BALANCE where item=`ToBuy; 
update futureValue:futureCash from `BALANCE where item=`Cash;

tmp:exec sum mktValue, sum invested, futureValue:sum target1yr*qty  from CURRENT_EQTY
invested:first tmp`invested
mktValue:first tmp`mktValue
`BALANCE insert (`CurrentMktValue;`int$first tmp`mktValue;`int$first tmp`futureValue)
`BALANCE insert (`Invested;`int$first tmp`invested;0)
total:(first tmp`mktValue) + first cash`total_cash
perfutureCash:100.0*((first cash`total_cash) + futureCash )%(total)
perCurrCash:100.0*(first cash`total_cash)%(total)

update futureValue:`int$futureCash from `BALANCE where item=`Cash
update futurePer:perfutureCash, curPer:perCurrCash from `BALANCE where item=`Cash

divrpnl:first exec divInc from dividendByYear where year= `year$.z.D
divFuture:first exec sum qty*dividend  from CURRENT_EQTY where not dividend=0n;
rpnl:first exec sum rpnl from pnl_yearly where year= `year$.z.D
upnl:first exec sum upnl from CURRENT_EQTY where upnl>0.0
uloss:first exec sum upnl from CURRENT_EQTY where upnl<0.0

`BALANCE insert (`$"Realized Stock"; `int$rpnl;0;0.0;0.0);
`BALANCE insert (`$"Realized Option"; `int$optrpnl;0;0.0;0.0);
`BALANCE insert (`$"Realized Dividend"; `int$divrpnl;`int$divFuture;0.0;0.0);
`BALANCE insert (`$"Realized Total"; `int$(rpnl+divrpnl+optrpnl);0;0.0;0.0);
`BALANCE insert (`$"UnRealized Profit";`int$upnl;0;0.0;100*upnl%invested);
`BALANCE insert (`$"UnRealized Loss";`int$uloss;0;0.0;100*uloss%invested);
`BALANCE insert (`$"UnRealized Net";`int$(upnl+uloss);0;0.0;100*(upnl+uloss)%invested)


/save to hdb
.dat.hdb:":",.dat.PWD,"/hdb/";
{
   (`$.dat.hdb,"/",string[.z.D],"/",string[lower x],"/") set .Q.en[`$.dat.hdb;0!value x];
   .lg.out["Saved ",string[x]];
    } each `ACCOUNT`BALANCE`CURRENT_EQTY`CURRENT_OPTION`RISK_SECTOR;

/webservices
getCurrentEqty:{[];
	select sym, acc_name, qty, costBasis, Close, mktValue, upnl, invested, income:divInc + optInc + rpnl, 0.0^roi from CURRENT_EQTY}

getCurrentOptions:{[]
	select sym, acc_name, expDate, putcall, strike, `int$strike^Close, `int$0.0^costBasis, qty, amount, expires:.dt.days2expire'[expDate], risk, 0^upnl from CURRENT_OPTION}

getBalance:{[]
	select item, currentValue, futureValue, 0.0^curPer, 0.0^futurePer from BALANCE}

getRiskOption:{[]
    select sym,expDate, putcall, strike, Close, costBasis, `int$0^upnl, risk,  qty, amount, reason from RISK_OPTION}

getAccount:{[]
    select from ACCOUNT}

getInvestCall:{[]
	select from INVEST_OPTION_CALL}

getInvestPut:{[]
   select sym,qty,strike,invest,0^oldqty, 0.0^oldstrike, 0.0^costBasis, 0.0^Close from INVEST_OPTION_PUTT}

getOptionStrategy:{[]
	select `Wait^action, sym, expDate, putcall, abs {first x}'[qty], strategy, lowStrike:{first x}'[strike], highStrike:{last x}'[strike], costBasis:{x%(100*(abs first y))}'[costBasis;qty], amount:costBasis, upnl, breakEven, Close, `int$roi, `int$roiMax  from OPTION_STRATEGY}

getIncByMonth:{[]
	calls:select expDate,call:`int$opt from opt_pnlByMonthType where expDate > `month$2022.01.01, putcall=`C; 
	puts:1!select expDate,put:`int$opt from opt_pnlByMonthType where expDate > `month$2022.01.01, putcall=`P;
	weeklyCall:select call:sum amount by expDate from position_opt_exp where expDate > .z.D, putcall=`C;
	weeklyPutt:select put:sum amount by expDate from position_opt_exp where expDate > .z.D, putcall=`P;
	weeklys:`expDate xdesc update call:`int$0.0^call, put:`int$0.0^put, dividend:0i from 0!weeklyCall uj weeklyPutt;
	dividend:1!select expDate:month, dividend:`int$divIncd from dividendByMonth where month >= `month$2022.02.01;
	monthlys:update dividend:0i^dividend from 0!calls lj puts lj dividend;
	update `$string expDate from weeklys,monthlys}

//getIncByMonth:{[]
//	(select month:expDate,call:`int$opt from opt_pnlByMonthType where expDate >= `month$2022.01.01, putcall=`C) 
//	lj (1!select month:expDate,put:`int$opt from opt_pnlByMonthType where expDate >= `month$2022.01.01, putcall=`P)
//	lj (1!select month, divIncd from dividendByMonth where month >= `month$2022.02.01)}

getSector:{[]
	select sector,invested,upnl:(rpnl+upnl) from RISK_SECTOR}
getPnlByMonth:{[]
	(`date) xdesc 0!select sum rpnl by  `month$date from sold_position where date>=2022.01.01}
getOptRisk:{[]
	res:(0!select calls:abs `int$sum risk by expDate from CURRENT_OPTION where putcall=`C)
	lj select puts:abs `int$sum risk by expDate from CURRENT_OPTION where putcall=`P;
	update 0^puts, 0^calls from res}

getOptIncome:{[]
	res:(0!select calls:abs `int$sum amount by {.dt.nextFriday[x]}'[date] from CURRENT_OPTION where putcall=`C)
	lj select puts:abs `int$sum amount by {.dt.nextFriday[x]}'[date] from CURRENT_OPTION where putcall=`P;
	(`date) xdesc update 0^puts, 0^calls from res}

getIncomeRate:{[]
	select sym, `int$0.0^optIncRate, 0.0^divRate from CURRENT_EQTY where (optIncRate>0.0) or (divRate >0.0)}

\p 1122