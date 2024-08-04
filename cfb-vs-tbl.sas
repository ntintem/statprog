/*
*****************************************************************************************************************
Project		 : _NA_
SAS file name: cfb-vs-tbl.sas
File location: _NA_
*****************************************************************************************************************
Purpose: Creating A Basic Change From Baseline Table For Vitals
Author: Mazi Ntintelo
Creation Date: 2024-08-04
*****************************************************************************************************************
CHANGES:
Date: Date of first modification of the code
Modifyer name: Name of the programmer who modified the code
Description: Shortly describe the changes made to the program
*****************************************************************************************************************
*/

%*-------------------------------Treatment Formats---------------------------------------;

proc format;
	value $trt (multilabel notsorted)
		'Placebo'   				  = 'Placebo'
		'Drug A'					  = 'Drug A'
		'Drug B'					  = 'Drug B'
		'Drug A', 'Drug B'  		  = 'All Active'
		'Placebo', 'Drug A', 'Drug B' = 'All Subjects';
run;

%*-----------------------------------Get Big N-------------------------------------------;

proc summary data=adsl(where=(saffl='Y')) completetypes nway;
	class trt01a /mlf preloadfmt exclusive order=formatted;
	format trt01a $trt.;
	output out=big_n;
run;

%*---------------------------Store In Global Symbol Table--------------------------------;

data _null_;
	set big_n;
	id = whichc(trt01a, 'Placebo', 'Drug A', 'Drug B', 'All Subjects');
	call symputx(cats('_', id), _freq_, 'g');
run;

%*-----------------------Custom Function to Calculate Decimal Places---------------------;

proc fcmp outlib=work.funcs.math;
	function get_decimal_places(value);
			places=0;
			temp=value;
			do while(mod(temp, 1));
				places+1;
				temp=temp*10;
			end;
		return (places);
	endsub;
run;

proc sort data=advs(where=(saffl = "Y" and anl01fl = "Y")) out=advs01;
	by paramn avisitn atptn;
run;

%*-------------------------------Get Descriptive Statistics------------------------------;

proc means data=advs01 completetypes nway missing noprint;
	by paramn paramcd param avisitn avisit atptn atpt;
	var aval chg;
	class trta/ mlf preloadfmt order=formatted;
	format trta $trt.;
	output out=advs02 
	mean  (aval chg)=
	min   (aval chg)=
	max   (aval chg)=
	std   (aval chg)=
	median(aval chg)=
	n     (aval chg)=/autoname;
run;

%*-----------------------------Get Max Decimals Per Parameter----------------------------;

options cmplib=(work.funcs);
proc sql;
	create table advs03 as 
		select a.*
			  ,b.maxdec
		from advs02 as a 
		natural left join
		(select
				paramcd
				,max(get_decimal_places(aval)) as maxdec
				from advs 
				group by paramcd
		) as b;
quit;

%*--------------------------------Map to Shell Format------------------------------------;
data advs04;
	set advs03;
	length label $10. value trtlabel $20.;
	array precision [5] 8 _temporary_ (1 2 0 1 0);
	array stats1 [2]    aval_n chg_n;
	array stats2 [2, 5] aval_mean aval_stddev aval_min aval_median aval_max    
					    chg_mean chg_stddev  chg_min  chg_median chg_max;  
	array stats3 [2, 5] $10 _temporary_; 
	ubound = 2 - (avisitn = 0); *Ignore CHG Statistics for baseline visit; 
	do i=1 to ubound;
		label = 'n';
		var = choosec(i, 'AVAL', 'CHG');
		value = put(stats1[i], best. -l);
		ord=1;
		output;
		do j=1 to 5;
			stats3[i, j] = left(putn(round(stats2[i, j], divide(1, 10**sum(maxdec, precision[j]))), cats(sum(8, divide(precision[j], 10)))));
			if j = 5 then do;
				label = 'Median';
				ord=3;
				value=stats3[i, j];
				output;
			end;
		end;
		label = 'Mean (SD)';
		value=catx(' ', stats3[i, 1], cats('(', stats3[i, 2] ,')'));
		ord=2;
		output;
		label = 'Min, Max';
		value=catx(', ', stats3[i, 3], stats3[i, 5]);
		ord=4;
		output;
	end;
	keep avisitn avisit atptn atpt trta paramcd paramn param value var label ord;
run;

proc sort data=advs04;
	by paramn avisitn atptn ord;
run;

%*---------------------------Transpose from Narrow to Wide-------------------------------;
options validvarname=v7;
proc transpose data=advs04 delimiter=_ out=t_advs04 ;
	by paramn paramcd param avisitn avisit atptn atpt ord label;
	var value;
	id trta var;
run;

%*---------------------------Add By Rows By Visit/Timepoint------------------------------;

data final;
	length col001 atpt $200.;
	set t_advs04;
	by paramn avisitn atptn;
	col001 = cats('^{NBSPACE 3}', label);
	atpt = prxchange('s/^(After (Lying Down|Standing) For \d) (Minutes?)$/$1^n^{NBSPACE 4}$3/oi',-1, propcase(strip(atpt)));
	output;
	if first.atpt then do;
		count+1;
		ord = ord-.0001;
		col001 = cats("^{NBSPACE 1}", catx('/^n^{NBSPACE 3}', avisit, atpt));
		call missing(of label drug_a_aval -- all_active_chg);
		output;
	end;
	if count=3 and last.atpt then do;
		count=0;
		page+1;
	end;
run;

%*-------------------------Final Output for Reporting Effort-----------------------------;

proc sort data=final;
	by page paramn avisitn atptn ord;
run;

proc report data=final headline headskip split="~" formchar='-' missing
	style(header)=[just=c asis=on font_face="Courier New" font_size = 8pt]
	style(column)=[just=c asis=on cellwidth=9.8%  font_face="Courier New" font_size = 8pt]
    style(report)=[rules= groups frame=hsides width=100%];
   	column page paramn param avisitn atptn ord col001
    ("^S={borderbottomcolor=black borderbottomwidth=0.2} Placebo (N=&_1)" placebo_aval placebo_chg)
	blank1
   	("^S={borderbottomcolor=black borderbottomwidth=0.2} Drug A (N=&_2)"  drug_a_aval drug_a_chg)
	blank2
   	("^S={borderbottomcolor=black borderbottomwidth=0.2} Drug B (N=&_3)"  drug_b_aval drug_b_chg)
	blank3
   	("^S={borderbottomcolor=black borderbottomwidth=0.2} All Subjects (N=&_4)" all_subjects_aval all_subjects_chg);
   	define page / order order = internal noprint;
   	define paramn / order order = internal noprint;
   	define param / noprint;
	define blank1 / "" computed style(column)=[cellwidth=0.1%];
    define blank2 / "" computed style(column)=[cellwidth=0.1%];
	define blank3 / "" computed style(column)=[cellwidth=0.1%];
   	define avisitn / order order = internal noprint;
   	define atptn  / order order = internal noprint;
   	define ord  / order order = internal noprint;
   	define col001 / "Visits/Statistc" style(header)=[just=l] style(column)=[just=l asis=on cellwidth=17.8%];
   	define placebo_aval     / "AV";
   	define placebo_chg     / "CFB";
   	define drug_a_aval     / "AV";
   	define drug_a_chg    / "CFB" ;
   	define drug_b_aval     / "AV";
    define drug_b_chg     / "CFB";
   	define all_subjects_aval / "AV" ;
   	define all_subjects_chg / "CFB";
	compute blank1/ character length=1;
    	blank1 = " ";  
   	endcomp;
	compute blank2/ character length=1;
    	blank2 = " ";  
   	endcomp;
	compute blank3/ character length=1;
     	blank3 = " ";  
   	endcomp;
   	compute before atptn;
     	line " ";  
   	endcomp;
   	compute before _page_ / style={just=l font_face="Courier New" font_size = 8pt borderbottomwidth=2 borderbottomcolor=black};
   		len = length(param);
     	line @1 "Parameter: " param $varying.len;  
   	endcomp;
   	break after page/page;
run;