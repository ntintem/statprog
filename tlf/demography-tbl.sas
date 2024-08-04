/*
*****************************************************************************************************************
Project		 : _NA_
SAS file name: dempography-tbl.sas
File location: _NA_
*****************************************************************************************************************
Purpose: Creating A Basic Demography Table
Author: Mazi Ntintelo
Creation Date: 2024-08-04
*****************************************************************************************************************
CHANGES:
Date: Date of first modification of the code
Modifyer name: Name of the programmer who modified the code
Description: Shortly describe the changes made to the program
*****************************************************************************************************************
*/

%*-----------------------------------------------------------------------------------;
%*---------Setup Formats for usage with Completetypes and Preloadfmt Options---------;
%*-----------------------------------------------------------------------------------;

proc format;
	value $trt (multilabel notsorted)
		'Placebo'   				  = 'Placebo'
		'Drug A'					  = 'Drug A'
		'Drug B'					  = 'Drug B'
		'Placebo', 'Drug A', 'Drug B' = 'All Subjects';
		
	value $agegr (multilabel notsorted)
		'<65', '65-80', '>80' = 'n'
		'<65'   			  = '<65'
		'65-80'				  = '65-80'
		'>80'				  = '>80';
		
	invalue agegr
		'n' 	= 1
		'<65'   = 2
		'65-80'	= 3
		'>80'	= 4;
		
	value $arace (multilabel notsorted)
		'American Indian or Alaska Native', 'Asian', 'Black or African American', 'Native Hawaiian or Other Pacific Islander', 
		'White', 'Other' 							 = 'n'	
		'American Indian or Alaska Native'     		 = 'American Indian or Alaska Native'
		'Asian'					  					 = 'Asian'
		'Black or African American'					 = 'Black or African American'
		'Native Hawaiian or Other Pacific Islander'  = 'Native Hawaiian or Other Pacific Islander'
		'White' 									 = 'White'
		'Other' 									 = 'Other';
		
	invalue arace
		'n' 										= 1
		'American Indian or Alaska Native'   		= 2
		'Asian'								 		= 3
		'Black or African American'					= 4
		'Native Hawaiian or Other Pacific Islander'	= 5
		'White'										= 6
		'Other'										= 7;
		
	value $aethnic (multilabel notsorted)
		'Hispanic or Latino', 'Not Hispanic or Latino'  = 'n'
		'Hispanic or Latino'     		 		        = 'Hispanic or Latino'
		'Not Hispanic or Latino'     					= 'Not Hispanic or Latino';
		
	invalue aethnic
		'n' 										= 1
		'Hispanic or Latino'   						= 2
		'Not Hispanic or Latino'					= 3;
run;

%*-----------------------------------------------------------------------------------;
%*-------------------------------------Get Big N-------------------------------------;
%*-----------------------------------------------------------------------------------;

proc summary data=adsl(where=(saffl='Y')) completetypes nway;
	class trt01a /mlf preloadfmt exclusive;
	format trt01a $trt.;
	output out=big_n;
run;

%*-----------------------------------------------------------------------------------;
%*-----------------------Store Big N in Global Symbol Table--------------------------;
%*-----------------------------------------------------------------------------------;

data _null_;
	set big_n;
	_trt01a = tranwrd(strip(trt01a), ' ', '_');
	call symputx(_trt01a, _freq_, 'g');
run;

%*-----------------------------------------------------------------------------------;
%*---------------------Custom Function To Calculate Decimal Places-------------------;
%*-----------------------------------------------------------------------------------;

proc fcmp outlib=work.funcs.numbers;
	function get_decimal_places(value);
			decimal_places=0;
			temp=value;
			do while(mod(temp, 1));
				decimal_places+1;
				temp=temp*10;
				if decimal_places = 3 then return (decimal_places);
			end;
		return (decimal_places);
	endsub;
run;

options cmplib=work.funcs;

%*-----------------------------------------------------------------------------------;
%*-----------------Get Maximum Number of Decimal Places for Reporting----------------;
%*-----------------------------------------------------------------------------------;

proc sql noprint;
	select max(get_decimal_places(age))    
		  ,max(get_decimal_places(bmibl))   
		  ,max(get_decimal_places(weightbl)) 
		  ,max(get_decimal_places(heightbl)) 
	into  :age_max_dec       trimmed
		 ,:bmibl_max_dec     trimmed
		 ,:weightbl_max_dec  trimmed
		 ,:heightbl_max_dec  trimmed
	from adsl;
quit;

%*-----------------------------------------------------------------------------------;
%*-------------------------Transform to Shell Format---------------------------------;
%*-----------------------------------------------------------------------------------;

proc means data=adsl(where=(saffl='Y')) completetypes noprint nway;
	var age bmibl weightbl heightbl;
	class trt01a / mlf preloadfmt order=formatted;
	format trt01a $trt.;
	output out= adsl01
	mean  (age  bmibl weightbl heightbl)=
	min   (age  bmibl weightbl heightbl)=
	max   (age  bmibl weightbl heightbl)=
	std   (age  bmibl weightbl heightbl)=
	median(age  bmibl weightbl heightbl)=
	n     (age  bmibl weightbl heightbl)=/autoname;
run;

%*-----------------------------------------------------------------------------------;
%*-------------------------Transform to Shell Format---------------------------------;
%*-----------------------------------------------------------------------------------;

data adsl02;
	set adsl01;
	length label header value $200.;
	array labels      [4]  $25. _temporary_ ('Age (years)','Body Mass Index (kg/m^2)','Weight (kg)', 'Height (cm)');
	array stats_labels[6]  $10. _temporary_ ('n' 'Mean' 'SD' 'Minimum' 'Median' 'Maximum');
	array precision   [4,6]     _temporary_ (0 %eval(&age_max_dec + 1)      %eval(&age_max_dec + 2)      &age_max_dec      %eval(&age_max_dec + 1)      &age_max_dec
								             0 %eval(&bmibl_max_dec + 1)    %eval(&bmibl_max_dec + 2)    &bmibl_max_dec    %eval(&bmibl_max_dec + 1)    &bmibl_max_dec
								             0 %eval(&weightbl_max_dec + 1) %eval(&weightbl_max_dec + 2) &weightbl_max_dec %eval(&weightbl_max_dec + 1) &weightbl_max_dec
								             0 %eval(&heightbl_max_dec + 1) %eval(&heightbl_max_dec + 2) &heightbl_max_dec %eval(&heightbl_max_dec + 1) &heightbl_max_dec
								            ); 
	array descriptive_stats [4, 6]  age_n 	   age_mean       age_stddev      age_min      age_median      age_max     
					   				bmibl_n    bmibl_mean    bmibl_stddev    bmibl_min    bmibl_median    bmibl_max    
					    			weightbl_n weightbl_mean weightbl_stddev weightbl_min weightbl_median weightbl_max 
					   			    heightbl_n heightbl_mean heightbl_stddev heightbl_min heightbl_median heightbl_max;  	
	do i=1 to dim1(descriptive_stats);
		header=labels[i];
		ord1=i;
		do j=1 to dim2(descriptive_stats);
			label=stats_labels[j];
			ord2=j;
			value=left(putn(round(descriptive_stats[i, j], divide(1, 10**precision[i, j])), cats(sum(8, divide(precision[i, j], 10)))));
			output;
		end;
	end;
	keep header label ord: value trt01a;
run;

%*-----------------------------------------------------------------------------------;
%*---------------Setup Macro Variables Needed By Categorical Macro-------------------;
%*-----------------------------------------------------------------------------------;

%macro categorical_counts_basic(data_in=
							   ,categorical_vars=
							   ,categorical_vars_formats=
							   ,categorical_vars_informats=
							   ,categorcial_vars_headers=
							   ,categorical_vars_table_orders=
							   ,data_out=categorical
							   ,analysis_set=saffl
							   ,debug= N);						
	%local i 
		   elif 
		   categorical_vars_n;
	
	%let categorical_vars_n = %sysfunc(countw(&categorical_vars, |));
	
	%do i=1 %to &categorical_vars_n;
		%local categorical_var_&i
			   categorical_var_&i._format
			   categorical_var_&i._informat
			   categorical_var_&i._table_order
			   categorical_var_&i._header;
			   
		%let categorical_var_&i  		      = %scan(&categorical_vars, &i, |);
		%let categorical_var_&i._format       = %scan(&categorical_vars_formats, &i, |);
		%let categorical_var_&i._informat     = %scan(&categorical_vars_informats, &i, |);
		%let categorical_var_&i._header       = %scan(&categorcial_vars_headers, &i, |);
		%let categorical_var_&i._table_order  = %scan(&categorical_vars_table_orders, &i, |);
	%end;
	
	%*-----------------------------------------------------------------------------------;
	%*--------------------------------Get Frequencies------------------------------------;
	%*-----------------------------------------------------------------------------------;
	
	%do i=1 %to &categorical_vars_n;
		proc summary data=&data_in(where=(&analysis_set = 'Y')) completetypes nway;
			class &&categorical_var_&i trt01a/ mlf preloadfmt exclusive;
			format trt01a $trt. &&categorical_var_&i &&categorical_var_&i._format;
			output out=cat_helper_stats_&i;
		run;       
	%end;
	%let elif=;
	
	%*-----------------------------------------------------------------------------------;
	%*---------------------------Stack Interim Datasets----------------------------------;
	%*-----------------------------------------------------------------------------------;
	
	data &data_out;
		length label $200.;
		set %do i=1 %to &categorical_vars_n;
				cat_helper_stats_&i (in=_&i rename=(&&categorical_var_&i = label))
			%end;
			;
		%do i=1 %to &categorical_vars_n;
			&elif if _&i then ord1 = &&categorical_var_&i._table_order;
			%let elif=else;
		%end;
		%let elif=;
		%do i=1 %to &categorical_vars_n;
			&elif if _&i then header = "&&categorical_var_&i._header";
			%let elif=else;
		%end;
		%let elif=;
		%do i=1 %to &categorical_vars_n;
			&elif if _&i then ord2  = input(label, &&categorical_var_&i._informat.);
			%let elif=else;
		%end;
		_trt01a = tranwrd(strip(trt01a), ' ', '_');
		value   = ifc(label eq 'n', cats(_freq_)
				     ,catx(' ', _freq_, cats('(', put(divide(_freq_, symgetn(_trt01a)) * 100, 8.1), '%)')));
		keep header label ord: value trt01a;
	run;
	
	%*-----------------------------------------------------------------------------------;
	%*----------------------------Remove Interim Datasets--------------------------------;
	%*-----------------------------------------------------------------------------------;
	
	%if %bquote(&debug) = N %then %do;
		proc datasets lib=work mt=data nolist;
			delete cat_helper_stats_:;
		run;
	%end;
%mend categorical_counts_basic;

%*-----------------------------------------------------------------------------------;
%*----------------------------Get Categorical Counts---------------------------------;
%*-----------------------------------------------------------------------------------;

%categorical_counts_basic(data_in=adsl
						 ,data_out=adsl03
						 ,categorical_vars=agegr1|arace|aethnic
						 ,categorical_vars_formats=$agegr.|$arace.|$aethnic.
						 ,categorical_vars_informats=agegr.|arace.|aethnic.
						 ,categorcial_vars_headers=Age Group|Race|Ethnicity
						 ,categorical_vars_table_orders=5|6|7);
						 
%*-----------------------------------------------------------------------------------;
%*-------------------Combine Continuos and Categorical Statistics--------------------;
%*-----------------------------------------------------------------------------------;	
		   					   		 
data adsl04;
	set adsl02
		adsl03;
	_trt01a = tranwrd(strip(trt01a), ' ', '_');
	trtlbl  = catx(' ', trt01a, cats('(N=',symgetn(_trt01a), ')'));
run;
				   
proc sort data=adsl04;
	by ord1 header ord2 label;
run;

%*-----------------------------------------------------------------------------------;
%*--------------------------Transpose from Narrow to Wide----------------------------;
%*-----------------------------------------------------------------------------------;
	
options validvarname=v7;
proc transpose data=adsl04 out=t_adsl04;
	by ord1 header ord2 label;
	var value;
	id trt01a;
	idlabel trtlbl;
run;

%*-----------------------------------------------------------------------------------;
%*--------------------------------Add By Row Label-----------------------------------;
%*-----------------------------------------------------------------------------------;

data adsl05;
	length col001 $200.;
	set t_adsl04;
	by ord1;
	col001 = cat('  ', strip(label));
	output;
	if first.ord1 then do;
		ord2 = ord2-0.0001;
		col001 = header;
		call missing(of all_subjects -- placebo);
		output;
	end;
	keep col001 ord1 ord2 all_subjects -- placebo;
run;

%*-----------------------------------------------------------------------------------;
%*--------------------Re-order Data To Ensure Label Appears First--------------------;
%*-----------------------------------------------------------------------------------;

proc sort data=adsl05;
	by ord1 ord2;
run;

proc report data=adsl05 split='!';
	column ord1 ord2 col001 placebo drug_a drug_b all_subjects;
	define ord1/ order order=internal noprint;
	define ord2/ order order=internal noprint;
	define col001/ "Demographic Variable" style(column)=[asis=on];
	compute before ord1;
		line '';
	endcomp;
run;