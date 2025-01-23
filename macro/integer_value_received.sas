%macro integer_value_received(parameter=);		         
	%if %sysfunc(notdigit(&&&parameter)) %then %do;
		%put ERROR:1/[%sysfunc(datetime(), e8601dt.)] Invalid value for &parameter parameter.;
		%put ERROR:2/[%sysfunc(datetime(), e8601dt.)] Valid value is a positive integer.;
		%put ERROR:3/[%sysfunc(datetime(), e8601dt.)] Macro &avMacroName aborted.;
		0
		%return;
	%end;
	1
%mend integer_value_received;