\d .lg
out:{[x] show (string .z.D)," ",(string .z.T)," :",x};
\d .
\d .arg
getArg:{ first  .arg.data[x]}
required:{ if [ not any x in key .arg.data;.lg.out["Missing some arguments."];exit 1];};
init:{.arg.data:.Q.opt .z.x}
\d .
\d .conv
float:{"F"$ssr[ssr[string x;",";""];"+";""]}
date:{"D"$"01 ", string x}
\d .
.arg.init[];
