foreach n, 10
	printt "{d:n} "
endr
	printt "-> {d:n}\n"

foreach v, 0
	printt "unreached"
endr

foreach v, 2, 1
	printt "unreached"
endr

foreach v, 1, 2, 0
	printt "unreached"
endr

foreach x, 1, 5+1
	printt "{d:x} "
endr
	printt "-> {d:x}\n"

foreach v, 10, -1, -1
	printt "{d:v} "
v = 42
endr
	printt "-> {d:v}\n"

foreach q, 5, 21, 5
	printt "{d:q} "
purge q
endr
	printt "-> {d:q}\n"

s EQUS "x"
foreach s, 3, 30, 3
	printt "{d:x} "
endr
	printt "-> {d:x}\n"

foreach v, 10
	printt "{d:v}\n"
if v == 3
purge v
v equ 42 ; causes a fatal error
endc
endr
	printt "-> {d:v}\n"
