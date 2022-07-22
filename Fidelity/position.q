/-------------------------------------------------------------------------
/ Purpose: Analyse full portfolio from Fidelity Positions and transactions.
/ Steps: 1. Download Portfolio_positions* from Sengo and Chelvi's account
/ 2. Delete X01601829 records from Chelvi's file
/ 3. Download History from each accounts separately and save to BrkData 
/ Last updated: 2021.01.01
/-------------------------------------------------------------------------
position:("SSSSSSSSSSSSSS"; enlist ",") 0:`:Position.csv
position:update Qty:{"F"$ssr[string x;",";""]}'[Qty] from position;
position:update Price:{"F"$ssr[string x;",";""]}'[Price] from position;
position:update MktValue:{"F"$ssr[string x;",";""]}'[MktValue] from position;
position:update CostBasis:{"F"$ssr[string x;",";""]}'[CostBasis] from position;
position:update TotalCost:{"F"$ssr[string x;",";""]}'[TotalCost] from position;
update Symbol:`FCASH from `position where Symbol=`;
update Symbol:`CASH from `position where Symbol in (`FNSXX;`MAXFDRXD97;`FCASH;`$"FDRXX**";`$"FCASH**";`$"CORE**"), not Account=	`81960
update TotalCost:Qty from `position where Symbol=`CASH;

position_summary:update pnl:(MktValue - TotalCost) from select sum Qty,sum TotalCost, avg Price, sum MktValue by Symbol from position;
position_summary:(`MktValue) xdesc update pnlPer:100*pnl % TotalCost from position_summary;
\l brk.q

position_summary:position_summary lj 1!(`Symbol) xcol 0!dividendBysym 
update totalPnl:pnl + 0.0^dividend from `position_summary
update totalPnlPer:100*totalPnl%TotalCost from `position_summary

SUMMARY:select sum MktValue, sum TotalCost, sum pnl, sum dividend from position_summary;

MutualFunds:(`FNSXX`FIQFX`FSRBX`FBIOX`FIJDX`FIKHX`FJSCX`FIKAX`FHOX`FSMEX`FSHCX`FSHOX`MAXFDRX97);
MutualFunds:(exec distinct Symbol from  position where Account in (`81960`81977`604975877`604975885)) except `CASH

position_stocks: (`Symbol) xasc select from position_summary where not Symbol in MutualFunds;
position_stocks:update CostBasis:(TotalCost - 0.0^dividend) % Qty from position_stocks

position_mfunds: (`Symbol) xasc select from position_summary where Symbol in MutualFunds;
position_mfunds:position_mfunds lj (`Symbol) xkey select Symbol, Description from  position where Symbol in MutualFunds;
POSITION_EQ:update pnlPer:pnl%(CostBasis*Qty) from update pnl:(Price - CostBasis)*Qty from select Symbol,Qty,CostBasis,Price from position_stocks
POSITION_MFUND:update pnlPer:pnl%(CostBasis*Qty) from select Symbol,Description,Qty,CostBasis:(TotalCost%Qty),Price, pnl:totalPnl from position_mfunds;

save `:position_stocks.csv;
save `:position_mfunds.csv;

\p 1133
