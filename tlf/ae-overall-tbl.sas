/*
*****************************************************************************************************************
Project		 : _NA_
SAS file name: ae-overall-tbl.sas
File location: _NA_
*****************************************************************************************************************
Purpose: Creating A Basic AE Overall Table
Author: Mazi Ntintelo
Creation Date: 2024-08-04
*****************************************************************************************************************
CHANGES:
Date: Date of first modification of the code
Modifyer name: Name of the programmer who modified the code
Description: Shortly describe the changes made to the program
*****************************************************************************************************************
*/

*==============Formats================;

proc format;
	value $trt (notsorted multilabel)
		"Drug A" 					  = "Drug A"
		"Drug B" 					  = "Drug B"
		"Placebo"					  = "Placebo"
		"Drug A", "Drug B", "Placebo" = "Overall";
		
	value $cat (notsorted)
		"Number of Subjects with TEAEs"                       = "Number of Subjects with TEAEs"
		"Number of Subjects with serious TEAEs"               = "Number of Subjects with serious TEAEs"
		"Number of Subjects with serious Fatal TEAEs"         = "Number of Subjects with serious Fatal TEAEs"
		"Number of Subjects with related TEAEs" 	          = "Number of Subjects with related TEAEs"
		"Number of Subjects with TEAEs Leading to Withdrawal" = "Number of Subjects with TEAEs Leading to Withdrawal";
run;

*==============Big N================;

proc summary data=adsl completetypes;
	class trt01a / mlf preloadfmt exclusive;
	format trt01a $trt.;
	types trt01a;
	output out = big_n(rename=(_freq_ = big_n));
run;

data _null_;
	set big_n;
	id = whichc(trt01a, "Drug A", "Drug B", "Placebo", "Overall");
	call symputx(cats('_', id), big_n, 'g');
run;

%put &=_1|&=_2|&=_3|&=_4;

*==============Prep Data================;

data _null_;
	set adae(where=(saffl = 'Y' and trtemfl = 'Y')) end=eof;
	length cat $60;
	if _n_ = 1 then do;
		dcl hash prep(hashexp:7);
			prep.definekey("usubjid", "trta", "cat");
			prep.definedata("usubjid", "trta", "cat");
			prep.definedone();
	end;
	cat = "Number of Subjects with TEAEs";
	if prep.check() then prep.add();
	cat = "Number of Subjects with serious TEAEs";
	if aeser = 'Y' and prep.check() then prep.add();
	cat = "Number of Subjects with serious Fatal TEAEs";
	if aesdth = 'Y' and prep.check() then prep.add();
	cat = "Number of Subjects with related TEAEs";
	if aerel = 'PROBABLE' and prep.check() then prep.add();
	cat = "Number of Subjects with TEAEs Leading to Withdrawal";
	if aedrop = 'Y' and prep.check() then prep.add();
	if eof then prep.output(dataset: "prep");
run;

*==============Count Summary===================;

proc summary data=prep completetypes;
	class trta cat/ mlf preloadfmt exclusive order=formatted;
	format trta $trt. cat $cat.;
	types trta*cat;
	output out = stats;
run;

*=========Transpose from narrow to wide========;

data percent;
	set stats;
	catn    = whichc(cat, "Number of Subjects with TEAEs", 
	                      "Number of Subjects with serious TEAEs", 
	                      "Number of Subjects with serious Fatal TEAEs", 
	                      "Number of Subjects with related TEAEs", 
	                      "Number of Subjects with TEAEs Leading to Withdrawal");
	id      = whichc(trta, "Drug A", "Drug B", "Placebo", "Overall");
	percent = catx(' ', _freq_ , cats('(', put(round(divide(_freq_, symgetn(cats('_', id)))*100, .1), 8.1), '%)'));
run;

proc sort data=percent;
	by catn id;
run;

*=========Transpose from narrow to wide========;

proc transpose data=percent out=final prefix=_;
	by catn cat;
	var percent;
	id id;
run;

*==================Clean Up===================;
%symdel _1 _2 _3 _4;		