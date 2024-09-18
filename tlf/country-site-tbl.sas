/*
*****************************************************************************************************************
Project		 : _NA_
SAS file name: country-site-tbl.sas
File location: _NA_
*****************************************************************************************************************
Purpose: Creating a summary by country and site
Author: Mazi Ntintelo
Creation Date: 2024-09-18
*****************************************************************************************************************
CHANGES:
Date: Date of first modification of the code
Modifyer name: Name of the programmer who modified the code
Description: Shortly describe the changes made to the program
*****************************************************************************************************************
*/

proc format;
	value $trt (multilabel notsorted)
		'A'='A'
		'B'='B'
		'C'='C'
		'A', 'B', 'C'='Total';
run;

data adsl;
	length Usubjid $3 Country $3 Siteid $3 TRT01A $6 FASFL $ 1;
	input Usubjid $ Country $ Siteid $ TRT01A $ FASFL $;
datalines;
001 USA 001 A Y
002 USA 001 B Y
003 USA 002 B Y
004 USA 003 A Y
005 ZAF 101 A Y
006 ZAF 101 A Y
007 ZAF 102 B Y
;
run;

proc summary data=adsl(where=(fasfl='Y')) completetypes nway;
	class trt01a/ preloadfmt mlf exclusive;
	format trt01a $trt.;
	output out=bign;
run;

proc summary data=adsl(where=(fasfl='Y')) completetypes;
	by country;
	class siteid;
	class trt01a/ preloadfmt mlf exclusive;
	format trt01a $trt.;
	types trt01a trt01a*siteid siteid;
	output out=freq;
run;

data _null_;
	set freq(where=(_type_ = 2))
		bign;
	if _type_ = 2 then call symputx(catx('_', country, siteid), _freq_, 'g');
	else call symputx(trt01a, _freq_, 'g');
run;

data adsl02;
	set freq;
	where _type_ in (1, 3);
	length col1 denominator $100;
	if _type_=1 then do;
		col1=strip(country);
		denominator=strip(trt01a);
	end;
	else do;
		col1=cat(" ", siteid);
		denominator=catx('_', country, siteid);
	end;
	perc=ifc( _freq_ ne 0, catx(' ', _freq_, cats('(', put(divide(_freq_, symgetn(denominator)) * 100, 8.1), ')')), "0 (0.0)");
run;

proc sort data=adsl02;
	by country siteid col1 trt01a;
run;

proc transpose data=adsl02 out=t_adsl;
	by country siteid col1;
	var perc;
	id trt01a;
run;