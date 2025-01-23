
%macro syserr_is_acceptable;
	%if &syserr %then %do;
		%put ERROR:1/[%sysfunc(datetime(), e8601dt.)] Automatic macro variable SYSERR indicates error/warning;
		%put ERROR:2/[%sysfunc(datetime(), e8601dt.)] Review the SAS log for more information;
		%put ERROR:3/[%sysfunc(datetime(), e8601dt.)] Macro &macro_name aborted.;
		0
		%return;
	%end;
	1
%mend syserr_is_acceptable;