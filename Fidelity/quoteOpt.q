\l util.q
\l tbls.q
dte:.z.D

load_csv:{[fileName];
	quoteOption:("ISSFFFFFFFSSFSF"; enlist ",")  0: `$":options/",fileName;
	quoteOption:update sym:.conv.optsym'[contractSymbol;`S], expDate:.conv.optsym'[contractSymbol;`D], putcall:.conv.optsym'[contractSymbol;`C] from quoteOption;
	`optquote upsert select sym,expDate, putcall,strike,lastPrice,bid,ask,openInterest,volume,iv:impliedVolatility  from quoteOption;
	};
load_csv each system "\\ls options"

s:`$":hdb/",string[dte],"/optquote/";
s set .Q.en[`$":hdb";0!optquote]
\\
