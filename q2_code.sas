data vocal;
set sasuser.vocal;
t = _n_;
run;

*(a) - exploratory data analysis.;

goptions reset = all i = join;
axis1 label = ('Y_t & X_t');
legend1 label = ('Series:') value = ('Y_t' 'X_t');
symbol1 color = blue line = 1;
symbol2 color = red line = 3;
title1 'Time plots of Y_t and X_t';
proc gplot data = vocal ;
plot (y x)*t / overlay legend = legend1 vaxis = axis1;
run;

goptions reset = all;
title1 'Crosscorrelations between Y_t and X_t';
proc arima data = vocal plots (only) = series (crosscorr acf pacf);
identify var = y crosscorr = (x) nlag = 30;
identify var = x nlag = 6;
run;

proc spectra data = vocal out = spectral cross coef a k p ph s;
	var y x;
   	weights 1 1.5 2 4 8 9 8 4 2 1.5 1;
run;

*Sorting data to determine frequencies of significant cycles;

data spectral_new;
	set spectral;
run;

proc sort data = spectral_new out = spectral_sorted;
	by descending a_01_02;
run;



proc print data = spectral_sorted(obs = 24);
run;

*Spectral density of Yt;
goptions reset = all i = join;
title1 "Spectral density of Nosnows vocal activity";
proc sgplot data = spectral;
   series x = freq y = s_01;
   xaxis values = (0 to 3.14 by 1);
   	refline 0.16755 / axis = x;
	refline 1.17286 / axis = x;
run;


*Spectral density of Xt;
goptions reset = all i = join;
title1 "Spectral density of Nosnows wifes vocal activity";
proc sgplot data = spectral;
   series x = freq y = s_02;
   xaxis values = (0 to 3.14 by 1);
   	refline 0.16755 / axis = x;
	refline 1.17286 / axis = x;
run;

*Amplitude of y by x;
goptions reset = all i = join;
title1 "Amplitude of Y by X";
proc sgplot data = spectral;
   series x = freq y = a_01_02;
   xaxis values = (0 to 3.14 by 1);
	refline 0.16755 / axis = x;
	refline 1.17286 / axis = x;
run;


data cos_sin;
period1 = 5;
period2 = 14;
period3 = 38;
freq1 = 2*constant('pi')/period1;
freq2 = 2*constant('pi')/period2;
freq3 = 2*constant('pi')/period3;
do t = 1 to 150 + 30;
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
	merge vocal cos_sin;
run;

*(c) - fitting a model to the data.;

goptions reset = all;
proc varmax data = sincos_model plot = none;
model y x = xt_cos3 xt_sin3 / p = 1 method = ls; *print = (diagnose estimates);
output out = forecast lead = 30;
run;

*Obtaining R squared of the fitted model;
proc corr data = forecast;
	var y x for1 for2;
run;

data forecast;
	set forecast;
	res_nosnow_lag = lag(res1);
	res_wife_lag = lag(res2);
 	time = _n_;
run;


*Residual analysis (residuals for Nosnow); 

goptions reset = all i = needle;
axis1 label = (angle = 90 "Residual");
axis2 label = ("Time in seconds");
symbol1 color = blue line = 1;
title1 "Plot of residuals over time for Nosnow";
proc gplot data = forecast;
	plot res1*time / vaxis = axis1 haxis = axis2;
run;

goptions reset = all;
axis1 label = (angle = 90 "Residual");
axis2 label = ("Predicted values");
symbol1 color = blue value = dot;
title1 "Scatter plot of residuals agains predicted vocal acitivity for Nosnow";
proc gplot data = forecast;
	plot res1*for1 / vaxis = axis1 haxis = axis2;
run;

goptions reset = all;
symbol1 color = blue value = dot;
title1 "Scatter plot of residuals against lagged residuals for Nosnow";
proc sgplot data = forecast;
	scatter x = res_nosnow_lag y = res1 / markerattrs = (color = blue symbol = Circlefilled);
	xaxis label = 'Errors at time t-1 (Nosnow)';
	yaxis label = 'Errors at time t (Nosnow)';
	refline 0 /axis = x;
	refline 0 /axis = y;
run;

proc univariate data = forecast;
	var res1;
	histogram / normal;
	qqplot /normal;
run;

*Residual analysis (residuals for Nosnows wife); 

goptions reset = all i = needle;
axis1 label = (angle = 90 "Residual");
axis2 label = ("Time in seconds");
symbol1 color = red line = 1;
title1 "Plot of residuals over time for Nosnows wife";
proc gplot data = forecast;
	plot res2*time / vaxis = axis1 haxis = axis2;
run;

goptions reset = all;
axis1 label = (angle = 90 "Residual");
axis2 label = ("Predicted values");
symbol1 color = red value = dot;
title1 "Scatter plot of residuals agains predicted vocal acitivity for Nosnows wife ";
proc gplot data = forecast;
	plot res2*for2 / vaxis = axis1 haxis = axis2;
run;

goptions reset = all;
symbol1 color = red value = dot;
title1 "Scatter plot of residuals against lagged residuals for Nosnows wife";
proc sgplot data = forecast;
	scatter x = res_wife_lag y = res2 / markerattrs = (color = red symbol = Circlefilled);
	xaxis label = 'Errors at time t-1 (Nosnows wife)';
	yaxis label = 'Errors at time t (Nosnows wife)';
	refline 0 /axis = x;
	refline 0 /axis = y;
run;

proc univariate data = forecast;
	var res2;
	histogram / normal;
	qqplot /normal;
run;




****FOR A FORECAST PLOT - of both series****;
goptions reset = all i = join;
axis1 label = (angle = 90 "Observed and predicted vocal activity for Nosnow and his wife");
axis2 label = ("Time in seconds");
legend1 label = ("Series:") value = ("Nosnow Cannotski" "His Wife" "Predictions for Nosnow" "Predictions for his wife");
symbol1 color = black line = 1;
symbol2 color = red line = 1;
symbol3 color = blue line = 3;
symbol4 color = red line = 3;
title2 "Time plot of observed and predicted vocal activity for Nosnow and his wife with a 5 minutes forecast";
proc gplot data = forecast;
	plot (y x for1 for2 )*time / overlay vaxis=axis1 haxis=axis2 legend = legend1 href = 150;
run;

****FOR A FORECAST PLOT - Only Nosnow****;
goptions reset = all i = join;
axis1 label = (angle = 90 "Observed and predicted vocal activity for Nosnow");
axis2 label = ("Hour number");
legend1 label = ("Series:") value = ("Nosnow Cannotski" "Predictions for Nosnow");
symbol1 color = black line = 1;
symbol2 color = blue line = 3;
title2 "Time plot of observed and predicted vocal activity for Nosnow with a 5 minutes forecast";
proc gplot data = forecast;
	plot (y for1 )*time / overlay vaxis=axis1 haxis=axis2 legend = legend1 href = 150;
run;

****FOR A FORECAST PLOT - Only Nosnows wife****;
goptions reset = all i = join;
axis1 label = (angle = 90 "Observed and predicted vocal activity for Nosnow");
axis2 label = ("Hour number");
legend1 label = ("Series:") value = ("Nosnows Wife" "Predictions for Nosnows's wife");
symbol1 color = black line = 1;
symbol2 color = red line = 3;
title2 "Time plot of observed and predicted vocal activity for Nosnows wife with a 5 minutes forecast";
proc gplot data = forecast;
	plot (x for2)*time / overlay vaxis=axis1 haxis=axis2 legend = legend1 href = 150;
run;

