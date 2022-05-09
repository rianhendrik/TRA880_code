/*Question 2*/

data cve;
infile "C:\Users\rianh\OneDrive - Rocketmine Pty Ltd\Desktop\TRA880 unit3 ass windows\Data\chicken_vs_egg.txt";
input t yt xt;
yt_d1 = dif(yt);
xt_d1 = dif(xt);
t = _n_ + 1811;
run;


proc sgplot data = cve;
	series y = xt x = t; *Do not overlay the two plots, because the one has much smaller values than the other (Yt is much larger);
run;

proc sgplot data = cve;
	series y = yt x = t; *Do not overlay the two plots, because the one has much smaller values than the other (Yt is much larger);
run;

proc sgplot data = cve;
	series y = xt_d1 x = t; *Do not overlay the two plots, because the one has much smaller values than the other (Yt is much larger);
run;

proc sgplot data = cve;
	series y = yt_d1 x = t; *Do not overlay the two plots, because the one has much smaller values than the other (Yt is much larger);
run;



/*Testing for a unit root in Xt*/
proc arima data = cve;
identify var = xt nlag = 12 stationarity = (adf = (0, 1, 2, 3, 4));*adf = 0 since we are assuming an AR(1) d.g.p;
run;

/*Testing for a unit root in Yt*/
proc arima data = cve;
identify var = yt nlag = 12 stationarity = (adf = (0, 1, 2, 3, 4));*adf = 0 since we are assuming an AR(1) d.g.p;
run;

/*Testing for a unit root in delta_Xt (first difference of Xt)*/
proc arima data = cve;
identify var = xt_d1 nlag = 12 stationarity = (adf = (0, 1, 2, 3, 4));*adf = 0 since we are assuming an AR(1) d.g.p;
run;

/*Testing for a unit root in delta_Yt (first difference of Yt)*/
proc arima data = cve;
identify var = yt_d1 nlag = 12 stationarity = (adf = (0, 1, 2, 3, 4));*adf = 0 since we are assuming an AR(1) d.g.p;
run;

/*We conclude that both Xt and Yt are integrated to the order 1.*/

proc autoreg data = cve plots = none;
	model yt = xt / stationarity = (pp = (0 1 2 3)) ;
	model yt = xt / stationarity = (adf = (0 1 2 3)) ;
	output out = reg_out r = residuals;
run;

/*proc print data = reg_out;*/
/*run;*/

proc sgplot data = reg_out;
	series x = t y = residuals;
run;

proc arima data = reg_out;
identify var = residuals  nlag = 12 stationarity = (adf = (0, 1, 2, 3));*adf = 0 since we are assuming an AR(1) d.g.p;
run;

/*Computing the Critical Values for the Phillips-Ouliaris test*/
proc iml;
c10 = -3.04445 - 4.2412/54 - 2.720/54**2;
c05 = -3.33613 - 6.1101/54 - 6.823/54**2;
c01 = -3.89644 - 10.9519/54 - 22.527/54**2;
print c10 c05 c01;

