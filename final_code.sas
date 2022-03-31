/*proc print data = sasuser.n1;*/
/*run;*/

*Question 1a - exploratory data analysis;

goptions reset = all i = join;
axis1 label = (angle = 90 "Observed number of vechicles between New Road and Olifantsfontein");
axis2 label = ("Date");
title1 "Time plot of hourly traffic between 29 October 2001 and 4 August 2002";
proc sgplot data = sasuser.n1;
   series x = date y = vehicles;
run;

goptions reset = all i = join;
axis1 label = (angle = 90 "Observed number of vechicles between New Road and Olifantsfontein");
axis2 label = ("Hours between Monday 29 October and Monday 12 November");
title2 "Time plot of hourly traffic for two weeks and a day (360 hours)";
proc sgplot data = sasuser.n1_2week;
	series x = hours_cum y = vehicles;
run;

data hours_48;
	set sasuser.n1_2week;
	where hours_cum < 48;
run;


goptions reset = all i = join;
axis1 label = (angle = 90 "Observed number of vechicles between New Road and Olifantsfontein");
axis2 label = ("Hours between Monday 29 October and Wednesday 31 October");
title2 "Time plot of hourly traffic for one day (48 hours)";
proc sgplot data = hours_48;
	series x = hours_cum y = vehicles;
	refline 8 / axis = x;
	refline 16 / axis = x;
	refline 24 / axis = x;
	refline 32 / axis = x;
	refline 40 / axis = x;
run;

proc arima data = sasuser.n1 plots (only) = series (acf pacf);
	identify var = vehicles nlag = 30 ;
run;


proc spectra data = sasuser.n1 out = specdat p s adjmean whitetest;
   var vehicles;
   weights 1 2 3 4 3 2 1;
run;

*We definitely reject the H0 that the n1 series is White Noise.;

*Sort the specdat output to find the maximum of the smoothed spectral density.;

data specdat_new;
	set specdat;
run;

proc sort data = specdat_new out = specdat_sorted;
	by descending S_01;
run;

proc print data = specdat_sorted(obs = 12);
run;

*We see a peak here at a frequency of 0.26180 (a period of 24). This makes sense, since every 24 hours, a new day starts and the daily traffic
pattern resets;

*Visualise the smoothed periodograms (plotted against frequency and period) obtained after applying spectral analysis;
goptions reset = all i = join;
axis1 label = (angle = 90 "Spectral density of traffic time series");
axis2 label = ("Frequency from 0 to 1");
title3 "Spectral density of hourly vehicle count between 29 October 2001 and 4 August 2002 ";
proc sgplot data = specdat;
	where freq < 1;
	series x = freq y = s_01;
	refline 0.26180 /axis = x;
	refline 0.78640 /axis = x;
	refline 0.03740 /axis = x;
run;

proc sgplot data = specdat;
   *where period < 120;
   series x = period y = s_01 / markers markerattrs=(symbol=circlefilled);
   refline 24 / axis = x;
run;


***** Question b: Proposing a model ******;

*Proposed model;
*1) AR 2 with three sin-cos pairs

***** Question c: Fitting the model *******;

*Creating sine and cosine variables;

data cos_sin;
period1 = 24;
period2 = 168;
period3 = 8;
freq1 = 2*constant('pi')/period1;
freq2 = 2*constant('pi')/period2;
freq3 = 2*constant('pi')/period3;
do t = 1 to 6720 + 168;
	xt_cos1 = cos(freq1*(t-1));
	xt_sin1 = sin(freq1*(t-1));
	xt_cos2 = cos(freq2*(t-1));
	xt_sin2 = sin(freq2*(t-1));
	xt_cos3 = cos(freq3*(t-1));
	xt_sin3 = sin(freq3*(t-1));
	output;
end;
run;

data sincos_model;
	merge sasuser.n1 cos_sin;
run;

proc arima data = sincos_model out = final_out plot (only) = residual (acf pacf);
	identify var = vehicles crosscorr = (xt_sin1 xt_cos1 xt_sin2 xt_cos2 xt_sin3 xt_cos3) noprint;
	estimate p = 7 input = (xt_cos1 xt_sin1 xt_cos2 xt_sin2 xt_cos3 xt_sin3);
	forecast lead = 168 noprint;
run;

*Add dates again;

data final_out;
	set final_out;
 	hours = _n_;
	residual_lag = lag(residual);
run;

data dates_only;
	set sasuser.n1;
	keep date;
run;

data final_out;
	merge dates_only final_out;
run;


*Residual analysis;

goptions reset = all i = needle;
axis1 label = (angle = 90 "Residual");
axis2 label = ("Date");
symbol1 color = green line = 1;
title1 "Plot of residuals over time";
proc gplot data = final_out;
	plot residual*date / vaxis = axis1 haxis = axis2;
run;

goptions reset = all;
axis1 label = (angle = 90 "Residual");
axis2 label = ("Predicted values");
symbol1 color = green value = dot;
title1 "Scatter plot of residuals agains predicted number of vehicles";
proc gplot data = final_out;
	plot residual*forecast / vaxis = axis1 haxis = axis2;
run;

goptions reset = all;
symbol1 color = green value = dot;
title1 "Scatter plot of residuals against lagged residuals";
proc sgplot data = final_out;
	scatter x = residual_lag y = residual / markerattrs = (color = green symbol = Circlefilled);
	xaxis label = 'Errors at time t-1';
	yaxis label = 'Errors at time t';
	refline 0 /axis = x;
	refline 0 /axis = y;
run;

proc univariate data = final_out;
	var residual;
	histogram / normal;
	qqplot /normal;
run;


*Check R2;
proc corr data = final_out;
	var vehicles forecast;
run;

****FOR A FORECAST PLOT - Subset of the data, so that the plot is visible****;
data forecast_plot;
	set final_out;
    if hours > 6000 then output;
run;


goptions reset = all i = join;
axis1 label = (angle = 90 "Observed and predicted number of vechicles between New Road and Olifantsfontein");
axis2 label = ("Hour number");
legend1 label = ("Series:") value = ("Observed values" "Predicted Values");
symbol1 color = black line = 1;
symbol2 color = green line = 3;
title1 "Model 1: AR(2) and three cos-cosine pairs";
title2 "Time plot of observed and predicted hourly traffic";
proc gplot data = forecast_plot;
	plot (vehicles forecast)*hours / overlay vaxis=axis1 haxis=axis2 legend = legend1 href = 6720 ;
run;


