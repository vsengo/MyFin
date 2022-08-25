/-------------------------------------------------------
/ Portfolio analysis for 401k.
/ History : 2012.12.31 intial
/ 2020.01.01 Simplified using Positions and transctions
/-------------------------------------------------------
\l util.q
\p 1133
/.arg.required[`posFile];

transaction_orig:("DSSSS";enlist ",") 0:`$":NetbData/Netb.dat";
transaction_orig:update .conv.float'[Amount], .conv.float'[Shares] from transaction_orig;
update Investment:{`$ssr[string x;"&";""]}'[Investment]  from `transaction_orig;
update Investment:{`$ssr[string x;"amp;";""]}'[Investment]  from `transaction_orig;

/Name Changes
update Investment:`$"FID SEL HTH CARE SVC" from `transaction_orig where Investment in (`$"FID SEL MEDICAL DEL";`$"FID SEL HEALTH CARE");
update Investment:`$"FID SEL MED TECH&DV" from `transaction_orig where Investment in (`$"FID SEL MED TECHDV");
/update Investment:`$"FA ENERGY Z" from `transaction_orig where Investment in (`$"FID SEL ENERGY");

SOLD:select soldAmount:sum Amount, soldShares:sum Shares, endDate:last Date by Investment from transaction_orig where Type like "Exchanges*", Amount <0
BOUGHT:select boughtAmount:sum Amount, boughtShares:sum Shares, startDate:first Date, endDate:last Date by Investment from transaction_orig where Type like "Exchanges*", Amount>0

contribution:select invAmount:sum Amount, invShares:sum Shares, endDate:last Date by Investment from transaction_orig where Type like "CONTRIBUTION*"
dividend:select divAmount:sum Amount, divShares:sum Shares by Investment from transaction_orig where Type like "Dividend*"
SOLD:SOLD lj contribution
SOLD:SOLD lj dividend;
SOLD:SOLD lj BOUGHT
update invAmount:0.0^invAmount, invShares:0.0^invShares, 0.0^divAmount, 0.0^divShares, 0.0^boughtAmount, 0.0^boughtShares  from `SOLD;

update costBasis:(invAmount + boughtAmount) % (invShares + 0.0^boughtShares + 0.0^divShares), shares:0.0^soldShares + invShares + 0.0^divShares + 0.0^boughtShares from `SOLD;
update RPNL:-1*(soldAmount - costBasis*soldShares)  from `SOLD;
CLOSED:select Investment, startDate, endDate, soldAmount, invAmount:0.0^invAmount + 0.0^boughtAmount, RPNL from SOLD where 5 > abs shares

PART_SOLD:select Investment, startDate, endDate, soldAmount, invAmount:0.0^invAmount + 0.0^boughtAmount, soldShares, totalShares:(invShares + divShares + boughtShares) from SOLD where 5 < abs shares, not Investment like "FIMM*"
PART_SOLD:update RPNL:-1*soldAmount - soldShares *invAmount % totalShares from PART_SOLD
CLOSED,:select Investment, startDate, endDate, soldAmount, invAmount, RPNL from PART_SOLD

RPNL_byyear:select sum RPNL by endDate.year from CLOSED;

transaction:transaction_orig

\

/From Netb Positions.
posFile:.arg.getArg[`posFile];
position_mfunds:([sym :`symbol$()];
		 Investment:`symbol$();
		 qty  :`float$();
		 price:`float$();
		 costTot  :`float$();
		 avgCost:`float$());

data:1 _ read0 `$":NetbData/",posFile
{
	d:"," vs x;
	`position_mfunds insert (`$d[2];`$d[3];"F"$d[4];"F"$1 _ d[5];"F"$1 _ d[7];"F"$1 _ d[14]);
	} each data;

update Type:`BUY	from `transaction where Type  like "Adjustment*", Shares > 0;
update Type:`BUY	from `transaction where Type =`Exchanges, Shares > 0;
update Type:`SELL   from `transaction where Type =`Exchanges, Shares < 0;

update Type:`CONT	from `transaction where Type =`CONTRIBUTION;
update Type:`CONT	from `transaction where Type =`Contributions;
update Type:`DIV, Amount:-1*Amount from `transaction where Type=`$"Dividends and Interest";
update Type:`DIV, Amount:-1*Amount from `transaction where Type=`$"REVENUE CREDIT";
update Type:`FEE	from `transaction where Type like "*FEE*";
update costBasis:Amount % Shares from `transaction where Type in (`BUY`SELL);

delete from `transaction where Type like "Balance Transfer", Shares=0
delete from `transaction where Type like "Change in Market Value", Shares=0

update Investment:`$"FID SEL MED TECH&DV" from `transaction where Investment like "FID SEL MED TECH*"

dividends:select sum Amount, sum Shares by Date.year, Investment from transaction where Type=`DIV

dividends_byyear:select sum Amount by year  from dividends;
dividends_byfund:select Amount_div:sum Amount, Shares_div:sum Shares by Investment from dividends;

invested:select Amount_inv:sum Amount, Shares_inv:sum Shares by Investment from transaction where Type in (`CONT`BUY)
invested:invested lj dividends_byfund;
update CostBasis:Amount_inv % (Shares_inv + Shares_div) from `invested;

closed:select Amount_sold:sum Amount, Shares_sold:sum Shares, last Date by Investment from transaction where Type in (`SELL)

delete from `closed where Investment like "FIMM*"
closed_position:closed lj (`Investment) xkey invested;
update rpnl:-1*(Amount_inv+Amount_sold) from `closed_position
update ROI:100*rpnl%Amount_inv from `closed_position;

Yearly_rpnl:select sum rpnl, sum Amount_inv by Date.year from closed_position
Monthly_rpnl:select sum rpnl, sum Amount_inv by Date.month from closed_position

position_mfunds_div:position_mfunds lj (`Investment) xkey select  Investment, dividend:Amount from dividends where year=2020
save `:position_mfunds_div.csv

position_cost:select costBasis:sum Amount % (sum Shares), sharesHeld:sum Shares, last Date by Investment from transaction where Type in (`BUY`CONT`DIV);
position_pnl:select soldPrice:(sum Amount) % (sum Shares),sharesSold:sum Shares, last Date  by Investment from transaction where Type in (`SELL);

position:(`shares) xdesc select Investment, Date, Rpnl:(soldPrice - costBasis )*(-1*0^sharesSold), Amount:costBasis*(sharesHeld - 0^sharesSold), shares:(sharesHeld +  0^sharesSold), costBasis  from select from position_cost uj position_pnl;
delete from `position where shares < 10;
position:position lj dividends_byfund;
position_mfunds:position_mfunds lj invested
update perUpnl:100.0*(price - CostBasis) % CostBasis from `position_mfunds;

\c 100 200
show position_mfunds;
