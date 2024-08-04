/*
*****************************************************************************************************************
Project		 : _NA_
SAS file name: shift-ecg-tbl.sas
File location: _NA_
*****************************************************************************************************************
Purpose: Creating A Basic Shift ECG Table
Author: Mazi Ntintelo
Creation Date: 2024-08-04
*****************************************************************************************************************
CHANGES:
Date: Date of first modification of the code
Modifyer name: Name of the programmer who modified the code
Description: Shortly describe the changes made to the program
*****************************************************************************************************************
*/

options validvarname=v7;
proc format;
	value trt01an (notsorted)
		1 = '1'
		2 = '2';
			
	value $intp (notsorted)
		'NORMAL'                                = 'Normal'
		'ABNORMAL - NOT CLINICALLY SIGNIFICANT' = 'Abnormal - NCS'
		'ABNORMAL - CLINICALLY SIGNIFICANT'     = 'Abnormal - CS'
		'MISSING'     							= 'Missing';
run;

proc summary data=adsl completetypes;
	class trt01an / preloadfmt exclusive;
	format trt01an trt01an. ;
	types trt01an ();
	output out= big_n(rename=(_freq_ = big_n));
run;

data _null_;
	set big_n;
	if missing(trt01an) then trt01an=3;
	call symputx(cats('_', trt01an), big_n, 'g');
run;

data missing_rows;
	set adsl;
	length basec avalc avisit $200.;
	retain basec avalc 'MISSING';
	do week=4, 12, 16;
		avisit  = catx(' ', 'Week', week);
		avisitn = choosen(whichn(week, 4, 12, 16), 8, 11, 12); 
		output;
	end;
	drop week;
run;

data adeg002;
	update missing_rows 
		   adeg001(where=(avisitn > 6) keep=usubjid avisitn avisit basec avalc trt01an) updatemode=nomissingcheck;
	by usubjid avisitn avisit;
run;

proc sort data=adeg002;
	by avisitn avisit;
run;

proc summary data=adeg002(where=(saffl = 'Y')) completetypes;
	by avisitn avisit;
	class trt01an avalc basec / preloadfmt exclusive order=formatted;
	format trt01an trt01an. avalc basec $intp.;
	types trt01an*(avalc basec)
		  trt01an*avalc*basec
	      trt01an
	      basec
	      avalc
		  avalc*basec
		  ();
	output out=shift;
run;

data shift01;
	set shift;
	length percent $200.;
	array values avalc basec;
	do over values;
		if missing(values) then values='Total';
		else values=vvalue(values);
	end;
	if missing(trt01an) then trt01an=3;
	avalc_sort = whichc(avalc, 'Normal', 'Abnormal - NCS', 'Abnormal - CS', 'Missing', 'Total');
	percent    = catx(' ', _freq_ , cats('(', put(round(divide(_freq_, symgetn(cats('_', trt01an)))*100, .1), 8.1), '%)'));
run;

proc sort data=shift01;
	by avisitn avalc_sort trt01an basec;
run;

proc transpose data=shift01 delim=_ out=t_shift;
	by avisitn avisit avalc_sort avalc;
	var percent;
	id trt01an basec;
run;

proc report data=t_shift headline headskip  style(header)=[fontsize=8pt fontfamily='courier'] 
											style(column)=[fontsize=8pt fontfamily='courier']
											style(report)=[frame=hsides];
	columns avisitn avisit avalc_sort avalc ("Baseline Result"
							 		        ("Placebo(N=&_1)"        _1_normal _1_abnormal___ncs _1_abnormal___cs _1_missing _1_total)
							 		        ("Active (N=&_2)"        _2_normal _2_abnormal___ncs _2_abnormal___cs _2_missing _2_total)
							 		        ("All Subjects (N=&_3)"  _3_normal _3_abnormal___ncs _3_abnormal___cs _3_missing _3_total));
	define avisitn /					   noprint order order=internal ;
	define avalc_sort /					   noprint order order=internal ;
	define avisit / "Timepoint" ;
	define avalc /  "Post Baseline Result";
	define _1_normal / "Normal";
	define _1_abnormal___ncs / "Abnormal - NCS";
	define _1_abnormal___cs / "Abnormal - CS";
	define _1_missing / "Missing";
	define _1_total / "Total" ;
	define _2_normal / "Normal";
	define _2_abnormal___ncs / "Abnormal - NCS";
	define _2_abnormal___cs / "Abnormal - CS";
	define _2_missing / "Missing";
	define _2_total / "Total";
	define _3_normal / "Normal" ;
	define _3_abnormal___ncs / "Abnormal - NCS";
	define _3_abnormal___cs / "Abnormal - CS";
	define _3_missing / "Missing";
	define _3_total / "Total";
	compute after avisitn;
		line '';
	endcomp;
run;
	

	
	







		
		

