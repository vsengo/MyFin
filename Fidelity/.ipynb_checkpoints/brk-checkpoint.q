/-----------------------------------------------
/ Purpose: Calculate Position using all transactions downloaded from Fidelity accounts
/ Updated: 2018.02.12
/-----------------------------------------------
\l util.q
\c 100 200

transaction:([];date:`date$();action:`symbol$();sym:`symbol$();description:`symbol$();sectype:`symbol$();qty:`float$();cost:`float$();commission:`float$();fee:`float$();interest:`float$();amount:`float$();settle_date:`date$();account:`symbol$());

/transaction:([];date:`date$();action:`symbol$();sym:`symbol$();qty:`float$();cost:`float$();commission:`float$();fee:`float$();interest:`float$();amount:`float$());
load_data:{[f];
	tx:read0 `$":BrkData/",f;
	.dt.acc:`$9 # 20 _ f;
	.lg.out["Loading ",f];

	{
		rec:"," vs x;
		$[ 0Nd="D"$rec[0];
			.lg.out["Ignoring ",rec[0]];
			`transaction insert ("D"$rec[0];`$rec[1];`$rec[2];`$rec[3];`$rec[4];"F"$rec[5];"F"$rec[6];"F"$rec[7];"F"$rec[8];"F"$rec[9];"F"$rec[10];"D"$rec[11];.dt.acc) ]; } each tx;
	}
load_data each system "ls BrkData | grep History_for_Account";

account:([account:`symbol$()]; acc_name:`symbol$())
`account insert (`177712043;`HSA)
`account insert (`301668648;`CROTH)
`account insert (`301668710;`ROTH)
`account insert (`301793531;`ROLL)
`account insert (`X01601829;`WROS)
`account insert (`481846813;`SEP)


ca_split:([sym:`symbol$();date:`date$()]; old:`float$();new:`float$());
`ca_split insert (`NUGT;2020.04.23;4.0;1.0);
`ca_split insert (`QID;2018.05.24;4.0;1.0);
`ca_split insert (`SDS;2017.07.17;4.0;1.0);
`ca_split insert (`SQQQ;2020.08.18;5.0;1.0);
`ca_split insert (`TSLA;2020.08.31;1.0;5.0);

ca_merger:([];sym:`symbol$();date:`date$(); to:`symbol$();qty:`int$();toQty:`int$())
`ca_merger insert (`SCTY;2016.11.22;`TSLA;100;11);
`ca_merger insert (`IPOE;2021.06.01;`SOFI;100;100);
`ca_merger insert (`NYLD;2015.05.15;`NYLDA;100;200);
`ca_merger insert (`NYLDA;2015.05.16;`CWENA;100;100);
`ca_merger insert (`NRG;2015.05.16;`CWEN;100;200);

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

opt_transaction:select from transaction where sym like "-*"
transaction:delete from transaction where sym like "-*";

/apply corp actions
{
	.lg.out["applying merger to ", string[x`sym]];
	factor:(x`toQty) % x`qty;
	update qty:qty*factor, sym:x`to from `transaction where sym=x`sym, date <= x`date;
	update cost:amount % qty  from `transaction where sym=x`to, date < x`date;
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

position_current:update avg_cost: amount % qty from select sum amount, sum qty, last account  by sym  from transaction where action in (`BUY`SELL);
position_current:select from position_current where qty > 1.0
dividend:select sum amount by sym, date.year, date.month from transaction where action in (`DIV`FEE);
dividendBySym:select dividend:0.0^sum amount by sym from dividend;
dividendByMonthr:select dividend:sum amount by year,month from dividend;
dividendByYear:select dividend:sum amount by year from dividend;
dividendBySymYear:select dividend:sum amount by sym, year from dividend where amount > 0
dividendBySymYear:update perDiv:100.0*dividend%amount from dividendBySymYear lj position_current

position_current:position_current lj dividendBySym;
position_current:position_current lj account;

position_opt_exp:select sum amount by account, sym from opt_transaction
optsym:{[sym;t];
	n:first (string sym) ss "[12][0123456789]";
	s:`$1 _ n # string[sym];	
	c:`$1# (6+n) _ string[sym];
	d:"D"$"20",6# n _ string[sym];
	p:"F"$(7+n) _ string[sym];
	$[t~`S;s;$[t~`C;c;$[t~`D;d;p]]]}

update underlying:optsym'[sym;`S], putcall:optsym'[sym;`C], expDate:optsym'[sym;`D], price:optsym'[sym;`P] from `opt_transaction;
update underlying:optsym'[sym;`S], putcall:optsym'[sym;`C], expDate:optsym'[sym;`D] from `position_opt_exp;

opt_pnlBySym:select optInc:0.0^sum amount by sym:underlying from position_opt_exp
opt_pnlByMonth:(`expDate) xdesc select opt:0.0^sum amount by expDate from position_opt_exp
CURRENT_OPTION:(`putcall`underlying) xasc (`underlying`putcall`price`action`qty`cost`amount) xcols delete sym,description,date,sectype,commission,fee,interest,settle_date from select from  opt_transaction where .z.D <= expDate
update risk:qty*100*price from `CURRENT_OPTION;
CURRENT_OPTION_RISK:select pnl:sum amount, sum risk by putcall from CURRENT_OPTION;

position_current:position_current lj opt_pnlBySym
update costBasis:-1*(amount + (0.0^dividend) + (0.0^optInc)) % qty from `position_current
CURRENT_EQTY:0!select sym, acc_name,qty,costBasis,dividend,optInc from position_current

/pnl
update action:`BUY, cost:0.0, avgCost:0.0, long_qty:qty from `transaction where sym like "-*", cost=0n;
sold_position:select from transaction where action=`SELL;
position_eq:update avgCost:cost%qty from select cost:sum amount, qty:sum qty by sym from transaction where action=`BUY, not sym like "-*"
position_opt:update avgCost:cost%qty from select cost:sum amount, qty:sum qty by sym from transaction where action=`BUY, sym like "-*"

sold_position:(`date) xdesc sold_position lj (`sym) xkey select sym, avgCost, long_qty:qty from position_eq;
update rpnl:amount - qty*avgCost from `sold_position;
sold_position:update tax:`YES from sold_position where account in (`X01601829);
sold_position:update tax:`NO from sold_position where not account in (`X01601829);

yearly_pnl:(`year`month) xdesc select sum rpnl by date.year, date.month, tax  from sold_position;

\p 1122
