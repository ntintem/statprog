/*
*****************************************************************************************************************
Project		 : _NA_
SAS file name: ae-max-severity-tbl.sas
File location: _NA_
*****************************************************************************************************************
Purpose: Creating a Basic Adverse Event Table By Maximum Severity
Author: Mazi Ntintelo
Creation Date: 2024-08-04
*****************************************************************************************************************
CHANGES:
Date: Date of first modification of the code
Modifyer name: Name of the programmer who modified the code
Description: Shortly describe the changes made to the program
*****************************************************************************************************************
*/

proc format;
	value $trt (multilabel notsorted)
		'Placebo'   				  = 'Placebo'
		'Drug A'					  = 'Drug A'
		'Drug B'					  = 'Drug B'
		'Drug A', 'Drug B'  		  = 'All Active'
		'Placebo', 'Drug A', 'Drug B' = 'All Subjects';
		
	value $aesev (multilabel notsorted)
		'Mild', 'Moderate', 'Severe'  = 'Total'
		'Mild' 					      = 'Mild'
		'Moderate'  			      = 'Moderate'
		'Severe'    			      = 'Severe';
run;

proc summary data=adsl(where=(saffl='Y')) completetypes nway;
	class trt01a/mlf preloadfmt exclusive order=formatted;
	format trt01a $trt.;
	output out=big_n;
run;

data _null_;
	set big_n;
	trt01a = tranwrd(strip(trt01a), ' ', '_');
	call symputx(trt01a, _freq_, 'g');
run;

proc sort data=adae;
	by usubjid aesoc aedecod asevn;
run;

data ae01;
	set adae (where=(saffl= 'Y' and trtemfl = 'Y'));
   	by usubjid aesoc aedecod;
   	retain max_sev_soc max_sev_subj;
    if first.usubjid  then max_sev_subj=0;
   	if first.aesoc    then max_sev_soc=0;
   	grp001= '2';
   	grp002= aesoc;
   	if last.aedecod then do;
    	grp003 = cat('  ', aedecod);
   		max_sev = asev;
   		max_sev_soc = max(max_sev_soc, asevn);
   		output;
   	end;
   	if last.aesoc then do;
   		call missing(grp003);
  		max_sev = choosec(max_sev_soc, 'Mild', 'Moderate', 'Severe');
  		max_sev_subj = max(max_sev_subj, max_sev_soc);
  	 	output;
   	end;
   	if last.usubjid then do;
   		call missing(grp003);
   		grp002 = 'With Any Adverse Event';
   		grp001 = '1';
  		max_sev = choosec(max_sev_subj, 'Mild', 'Moderate', 'Severe');
  	 	output;
   	end;
 	keep trta usubjid grp001-grp003 max_sev;
run;

proc sort data=ae01;
	by grp001-grp003;
run;

proc summary data=ae01 missing completetypes nway;
	by grp001-grp003;
	class trta max_sev/mlf exclusive preloadfmt order=fmt;
	format trta $trt. max_sev $aesev.;
	output out=ae02;
run;

proc sort data=ae02;
	by trta grp001-grp003;
run;

data ae03;
	set ae02;
	by trta grp001-grp003;
	_trta  = tranwrd(strip(trta), ' ', '_');
	col001 = cat('    ', strip(max_sev));
	trtlbl = catx(' ', trta, cats('(N=', symgetn(_trta), ')'));
	perc   = catx(' ', _freq_, cats('(', put(divide(_freq_, symgetn(_trta)) * 100, 8.1), '%)'));
	col001 = coalescec(grp003, grp002);
	grp004 = whichc(max_sev, 'Total', 'Mild', 'Moderate', 'Severe');
run;

proc sort data=ae03;
	by grp001 grp002 grp003 col001 max_sev grp004;
run;

options validvarname=v7;
proc transpose data=ae03 out=ae04;
	by grp001 grp002 grp003 col001 max_sev grp004;
	var perc;
	id trta;
	idlabel trtlbl;
run;

ods escapechar='~';
proc report data=ae04 split='|' missing nowd headline headskip;
	column grp001-grp003 col001 max_sev grp004 placebo drug_a drug_b all_active all_subjects;
	define grp001/ order order=internal noprint;
	define grp002/ order order=internal noprint;
	define grp003/ order order=internal noprint;
	define grp004/ order order=internal noprint;
	define col001/ order order=internal "System Organ Class|~{NBSPACE 2}Preferred Term|~{NBSPACE 4}Severity" style(column)=[asis=on] style(header)=[asis=on];
	define max_sev/ "Max Severity";
	compute before grp003;
		line '';
	endcomp;
run;