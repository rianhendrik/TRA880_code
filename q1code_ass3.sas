data paris;
infile "C:\Users\rianh\OneDrive - Rocketmine Pty Ltd\Desktop\TRA880 unit3 ass windows\Data\paris.txt";
input empl;
month = _n_;
run;

/*a - Studentised Dicky-Fuller test for stationarity (assuming AR(1) dgp)*/

*I think, to be more complete, I ought to fit an AR(1) model to this data, and perform residual analysis!
*that is, first check if the series is autocorrelated.

/*First determine if the series has constant or not*/
goptions reset = all i = join;
axis1 label = (angle = 90 "Number of workers");
axis2 label = ("Date");
title1 "Number of workers in a certain occupation in Paris between 1812 and 1854";
proc sgplot data = paris;
   series x = month y = empl;
run;


proc arima data = paris plots = none;
identify var = empl  nlag = 12 stationarity = (adf = (0, 1));*adf = 0 since we are assuming an AR(1) d.g.p;
run;

/*From the above Dicky Fuller test, the series is trend stationary.*/
/*But now, just read up about the STUDENTISED version of the Dickt-Fuller test, an make sure that I am*/
/*using that one! Is it rho or tau? Which one is the studentised one?*/

/*b - Use the KPSS test to test if the Paris time series is sationary*/

proc autoreg data = paris plots = none;
/*model empl = / stationarity = (kpss = (kernel = nw lag = 1));*/
model empl = / stationarity = (kpss = (kernel = nw lag = 5));
run;

*The KPSS test says that we reject the H0 of stationarity, meaning that the time series is stochastic.;
*Or rather, that is has a stochastic trend.;

/*c - Estimate the order of integration of the Paris time series using an appropriate iml subroutine.*/

proc iml;
use paris;
read all into data;
call farmafit(d, ar, ma, sigma, data[,2] - mean(data[,2]));
print 'Estimated value of d for Paris data';
print 'd  = ' d[label = none];
	
