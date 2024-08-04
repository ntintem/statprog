/*
*****************************************************************************************************************
Project		 : _NA_
SAS file name: ae-soc-pt-tbl.sas
File location: _NA_
*****************************************************************************************************************
Purpose: Creating A Basic Adverse Event Table By SOC and PT
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
run;

proc summary data=adsl(where=(saffl='Y')) completetypes nway;
	class trt01a /mlf preloadfmt exclusive order=formatted;
	format trt01a $trt.;
	output out=big_n;
run;

data _null_;
	set big_n;
	trt01a=ifc(prxmatch('m/\w+\s\w+/oi', trt01a)
			  ,prxchange('s/(\w+)\s(\w+)/$1_$2/oi', -1, trt01a), trt01a);
	call symputx(trt01a, _freq_, 'g');
run;

data ae01;
	set adae(keep = usubjid aoccfl aoccsfl aoccpfl aesoc aedecod saffl trtemfl trta
			 where=(saffl='Y' and trtemfl = 'Y'));
				  
	length col001 grp001 $200;
	
	if aoccfl = 'Y' then do;
		col001 = 'Subjects with Any Adverse Event';
		grp001 = '1';
		grp002 = 1;
		output;
	end;
	if aoccsfl = 'Y' then do;
		col001 = aesoc;
		grp001 = aesoc;
		grp002 = 2;
		output;
	end;
	if aoccpfl = 'Y' then do;
		col001 = '  '!!strip(aedecod);
		grp001 = aesoc;
		grp002 = 3;
		output;
	end;
run;

proc sort data=ae01;
	by grp001 grp002 col001; 
run;

proc summary data=ae01 completetypes nway;
	by grp001 grp002 col001; 
	class trta /mlf preloadfmt exclusive order=formatted;
	format trta $trt.;
	output out = ae02;
run;

data ae03;
	set ae02;
	_trta=ifc(prxmatch('m/\w+\s\w+/oi', trta)
		     ,prxchange('s/(\w+)\s(\w+)/$1_$2/oi', -1, trta), trta);
	trtlbl = catx(' ', trta, cats('(N=',symgetn(_trta), ')'));
	perc = catx(' ', _freq_, cats('(', put(divide(_freq_, symgetn(_trta)) * 100, 8.1), '%)'));
run;

proc transpose data=ae03 out=ae04;
	by grp001 grp002 col001;
	var perc;
	id _trta;
	idlabel trtlbl;
run;

proc report data=ae04 split='|';
	column grp001 grp002 col001 placebo drug_a drug_b all_active all_subjects;
	define grp001/ order order=internal noprint;
	define grp002/ order order=internal noprint;
	define col001/ "System Organ Class|  Preferred Term" style(column)=[asis=on]  style(header)=[asis=on];
run;




	









