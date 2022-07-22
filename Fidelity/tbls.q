optquote:([sym:`symbol$();expDate:`date$();putcall:`symbol$();strike:`float$()];
	lastPrice:`float$();
	bid:`float$();
	ask:`float$();
	openInterest:`float$();
	volume:`float$();
	iv:`float$());

quote:([sym:`symbol$();Date:`date$()];
	Open:`float$();
	High:`float$();
	Low:`float$();
	Close:`float$();
	Volume:`int$());

secmaster:([sym:`symbol$()];
	sector:`symbol$();
	invType:`symbol$();
	eps:`float$();
	beta:`float$();
	dividend:`float$();
	target1yr:`float$());

transaction:([];date:`date$();
	action:`symbol$();
	sym:`symbol$();
	description:`symbol$();
	sectype:`symbol$();
	qty:`float$();
	cost:`float$();
	commission:`float$();
	fee:`float$();
	interest:`float$();
	amount:`float$();
	settle_date:`date$();
	account:`symbol$());

ACCOUNT:([account:`symbol$()]; 
	acc_name:`symbol$();
	total_cash:`float$();
	opt_cash:`float$());

BALANCE:([item:`symbol$()];
	currentValue:`int$();
	futureValue:`int$())

