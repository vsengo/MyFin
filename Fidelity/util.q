\d .lg
out:{[x] show (string .z.D)," ",(string .z.T)," :",x};
\d .
\d .arg
getArg:{if[y~`NONE;.arg.required[x]]; ret:first  .arg.data[x]; if [ ""~ret; ret:string y];value ".arg.",string[x],":\"",ret,"\""; :ret}
required:{ if [ not any x in key .arg.data;.lg.out["Missing argument - ", string[x]];exit 1];};
init:{.arg.data:.Q.opt .z.x}
\d .
\d .conv
float:{"F"$ssr[ssr[string x;",";""];"+";""]}
date:{"D"$"01 ", string x}

/convert opra symbols to sym,putcall,exp,price
/t = S-Sym, D-expDate, C-putcall, p-strike
optsym:{[sym;t];
        n:first (string sym) ss "[12][0123456789]";
        s:`$n # string[sym];
        c:`$1# (6+n) _ string[sym];
        d:"D"$"20",6# n _ string[sym];
        p:"F"$(7+n) _ string[sym];
        $[t~`S;s;$[t~`C;c;$[t~`D;d;p]]]}
\d .
\d .dt
calendar:([date:`date$()];day:`int$();holiday:`boolean$();opt_expiry:`boolean$());
.dt.opt:0
{
        dt:2022.01.01 + x;
        wd:(6 + x) mod 7;
        nh:$[wd in (0;6);1b;0b];
        if[wd = 5; .dt.opt:.dt.opt+1];
        $[.dt.opt = 3;[optExp:1b;.dt.opt:0];optExp:0b];
        `calendar upsert (dt;wd;nh;optExp);
        } each til 550;

days2expire:{[dt];
        count select from .dt.calendar where holiday=0b, date within(.z.D;dt)}

nextFriday:{[dt]:
        first exec date from .dt.calendar where day=5, date >= dt}
\d .
.arg.init[];
