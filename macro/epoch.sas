/*
*****************************************************************************************************************
Project		 : StatProg
SAS file name: epoch.sas
File location: /statprog/macro/epoch.sas
*****************************************************************************************************************
Purpose: Macro used to populate SDTM timing variable EPOCH
Author: Mazi Ntintelo
Creation Date: 2025-05-28
*****************************************************************************************************************
CHANGES:
Date: Date of first modification of the code
Modifyer name: Name of the programmer who modified the code
Description: Shortly describe the changes made to the program
*****************************************************************************************************************
*/

%macro epoch(data_in=
			,usubjid=usubjid
			,var_in=
			,se_data_in=
			,sestdtc=sestdtc
			,seendtc=seendtc
			,epoch=epoch
			,data_out=);
			
	%local macro_name 
		   random;
		   
	%let macro_name = &sysmacroname;

	/****************************************/
	/**************Validation****************/
	/****************************************/
	%if %required_parameter_is_null(parameter=data_in) %then %return;							
	%if %required_parameter_is_null(parameter=data_out) %then %return;
	%if %required_parameter_is_null(parameter=se_data_in) %then %return; 
	%if %required_parameter_is_null(parameter=var_in) %then %return;
	%if %required_parameter_is_null(parameter=usubjid) %then %return;
	%if %required_parameter_is_null(parameter=sestdtc) %then %return;
	%if %required_parameter_is_null(parameter=seendtc) %then %return;
	%if %required_parameter_is_null(parameter=epoch) %then %return;
	%if ^%dataset_name_is_valid(data_in=&data_out) %then %return;
	%if ^%library_exists(libref=gml) %then %return;
	%if ^%dataset_exists(data_in=&data_in) %then %return;
	%if ^%variable_exists(data_in=&data_in,var_in=&usubjid) %then %return;
	%if ^%variable_exists(data_in=&data_in,var_in=&var_in) %then %return;
	%if	^%variable_is_character(data_in=&data_in,var_in=&var_in) %then %return;
	%if ^%dataset_exists(data_in=&se_data_in) %then %return;
	%if ^%variable_exists(data_in=&se_data_in,var_in=&usubjid) %then %return;
	%if ^%variable_exists(data_in=&se_data_in,var_in=&sestdtc) %then %return;
	%if	^%variable_is_character(data_in=&se_data_in,var_in=&sestdtc) %then %return;
	%if ^%variable_exists(data_in=&se_data_in,var_in=&seendtc) %then %return;
	%if	^%variable_is_character(data_in=&se_data_in,var_in=&seendtc) %then %return;
	%if ^%variable_exists(data_in=&se_data_in,var_in=&epoch) %then %return;
	%if %internal_derived_variable_exists(data_in=&data_in,var_in=epoch) %then %return;
	
	%if %variable_type(data_in=&data_in,var_in=&usubjid) ne %variable_type(data_in=&se_data_in,var_in=&usubjid) %then %do;
		%put ERROR:1/[%sysfunc(datetime(), e8601dt.)] Variable type mismatch between &data_in..&usubjid and &se_data_in..&usubjid;
		%put ERROR:2/[%sysfunc(datetime(), e8601dt.)] Macro &macro_name aborted;
		%return;
	 %end;
	 
	%let random = V%sysfunc(rand(integer, 1, 5E6), hex8.);
	proc sort data=&se_data_in out=gml.se;
		by &usubjid &sestdtc &seendtc;
	run;

	data gml.last;
		set gml.se;
		by &usubjid;
		if last.&usubjid then &random.flag=1;
	run;

	data &data_out;
		set &data_in;
		retain &random.patternid1 &random.patternid2 &random.patternid3;
		if _n_ = 1 then do;
			if 0 then set gml.last(keep=&usubjid &epoch &sestdtc &seendtc &random.flag);
			dcl hash &random._h_(dataset: "gml.last(keep=&usubjid &epoch &sestdtc &seendtc &random.flag)", multidata: "Y", ordered: "Y");
			&random._h_.definekey("&usubjid");
			&random._h_.definedata(all:"Y");
			&random._h_.definedone();
			&random.patternid1=prxparse('m/^\d{4}\-(0[1-9]|1[0-2])\-(0[1-9]|1[0-9]|2[0-9]|3[01])T([0-1][0-9]|2[0-3]):[0-5][0-9](:[0-5][0-9])?$/oi');
			&random.patternid2=prxparse('m/^\d{4}\-(0[1-9]|1[0-2])\-(0[1-9]|1[0-9]|2[0-9]|3[01])$/oi');
			&random.patternid3=prxparse('m/^\d{4}\-(0[1-9]|1[0-2])\-(0[1-9]|1[0-9]|2[0-9]|3[01])(T([0-1][0-9]|2[0-3]):[0-5][0-9](:[0-5][0-9])?)?$/oi');
		end;
		if prxmatch(&random.patternid1, strip(&var_in)) then do;
			&random&var_in=input(&var_in, e8601dt.);
			&random.lvl=1;
		end;
		else if prxmatch(&random.patternid2, strip(&var_in)) then do;
			&random&var_in=input(&var_in, e8601da.);
			&random.lvl=2;
		end;
		if ^missing(&random&var_in) and ^&random._h_.check() then do;
			&random.rc=&random._h_.find();
		 	do while(^&random.rc);
				if &random.lvl = 1 and prxmatch(&random.patternid1, strip(&sestdtc)) and prxmatch(&random.patternid1, strip(&seendtc)) then do;
					&random.start =input(&sestdtc, e8601dt.);
					&random.end   =input(&seendtc, e8601dt.);
				end;
				else if prxmatch(&random.patternid3, strip(&sestdtc)) and prxmatch(&random.patternid3, strip(&seendtc)) then do;
					&random.start =input(&sestdtc, e8601da.);
					&random.end   =input(&seendtc, e8601da.);
					&random.temp  =&random&var_in;
					if &random.lvl=1 then &random&var_in=datepart(&random&var_in);
				end;
				if (&random.flag  and .<&random.start<=&random&var_in<=&random.end) or
			   	   (^&random.flag and .<&random.start<=&random&var_in<&random.end) then leave;
				else call missing(epoch);
				&random&var_in=coalesce(&random.temp, &random&var_in);
				&random.rc=&random._h_.find_next();
				call missing(&random.temp);
			end;
		end;
		output;
		call missing(epoch);
		drop &random: &sestdtc &seendtc;
	run;
%mend epoch;