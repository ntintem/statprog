/*
*****************************************************************************************************************
Project		 : Open TLF
SAS file name: n_percentage.sas
File location: <path>
*****************************************************************************************************************
Purpose: Macro used to get population counts from a dataset. Typically ADSL.
Author: Mazi Ntintelo
Creation Date: 2023-06-30
*****************************************************************************************************************
CHANGES:
Date: Date of first modification of the code
Modifyer name: Name of the programmer who modified the code
Description: Shortly describe the changes made to the program
*****************************************************************************************************************
*/


%macro n_percentage(data_in=
				   ,data_out=
				   ,denom_data_in=
				   ,subgroup_vars_in=
				   ,by_vars_in= 
				   ,treatment_var_in=
				   ,event_count_var_in=N
				   ,subject_count_var_in=N
				   ,denom_var_in=Denom
				   ,var_out=N_PCT
				   ,display_option=1
				   ,null_if_denom_zero=Y /*If denom missing how to handle*/
				   ,zero_decimal_100_percent=Y /*handel 0 and 100 values*/
				   ,percent_symbol=Y
				   ,percentfmt=8.1
					 	   ) /minoperator;

 %local i
 		random
 		n_only_display
		n_percent_display
		n_percent_denom_display
		n_percent_event_display
		n_percent_denom_event_display
 		join_variables
		macro_name;

	%*Option 0: n;
	%*Option 1: n (x.xx[%]);
	%*Option 2: n/N (x.xx[%]);
	%*Option 3: n (x.xx[%]) [xx];
	%*Option 4: n/N (x.xx[%]) [xx];

	%let n_only_display					 =0;	
	%let n_percent_display				 =1;	
	%let n_percent_denom_display		 =2;	
	%let n_percent_event_display		 =3;
	%let n_percent_denom_event_display   =4;	
 
	%let macro_name = &sysmacroname;

	/****************************************/
	/**************Validation****************/
	/****************************************/

	%if %required_parameter_is_null(parameter=data_in) %then %return;
	%if %required_parameter_is_null(parameter=data_out) %then %return;
	%if %required_parameter_is_null(parameter=var_out) %then %return;
	%if %required_parameter_is_null(parameter=subject_count_var_in) %then %return; 
	%if %required_parameter_is_null(parameter=display_option) %then %return;
	%if ^%variable_name_is_valid(var_in=&var_out) %then %return;
	%if ^%library_exists(libref=gml) %then %return;
	%if ^%dataset_exists(dataset=&data_in) %then %return;
	%if ^%dataset_name_is_valid(datasetName=&data_out) %then %return;					
	%if ^%variable_name(data_in=&data_in,varIn=&subject_count_var_in) %then %return;
	%if ^%variable_is_numeric(data_in=&data_in,varIn=&subject_count_var_in) %then %return;
	%if %internal_derived_variable_exists(data_in=&data_in,varIn=&var_out) %then %return;
	%if %internal_derived_variable_exists(data_in=&data_in,varIn=pct) %then %return;

	%if ^(%bquote(&display_option) in (&n_only_display &n_percent_display &n_percent_denom_display &n_percent_event_display &n_percent_denom_event_display)) %then %do;
		%put ERROR:1/[%sysfunc(datetime(), e8601dt.)] Invalid selection for display_option;
		%put ERROR:2/[%sysfunc(datetime(), e8601dt.)] Valid options are &n_only_display, &n_percent_display, &n_percent_denom_display, &n_percent_event_display, and &n_percent_denom_event_display;
		%put ERROR:3/[%sysfunc(datetime(), e8601dt.)] Macro &macro_name aborted.;
		%return;
	%end;

	%if &display_option %then %do;
		%if %required_parameter_is_null(parameter=treatment_var_in) %then %return;
		%if %required_parameter_is_null(parameter=percent_symbol) %then %return;
		%if %required_parameter_is_null(parameter=percentfmt) %then %return;
		%if %required_parameter_is_null(parameter=denom_data_in) %then %return;
		%if %required_parameter_is_null(parameter=denom_var_in) %then %return; 
		%if %required_parameter_is_null(parameter=null_if_denom_zero) %then %return; 
		%if ^%dataset_exists(data_in=&denom_data_in) %then %return;
		%if ^%yes_no_value_received(parameter=null_if_denom_zero) %then %return;
		%if ^%yes_no_value_received(parameter=percent_symbol) %then %return;

		%if ^%sysfunc(prxmatch(%str(m/^\d\.\d$/oi), &percentfmt)) %then %do;
			%put ERROR:1/[%sysfunc(datetime(), e8601dt.)] Invalid selection for percentfmt;
			%put ERROR:2/[%sysfunc(datetime(), e8601dt.)] Supply a valid format w.d format;
			%put ERROR:3/[%sysfunc(datetime(), e8601dt.)] Macro &macro_name aborted.;
			%return;
		%end;
	
		%let join_variables = %sysfunc(tranwrd(&treatment_var_in &subgroup_vars_in &by_vars_in, %str( ), #));
	
		%join_two_tables(data_in=&data_in
						,data_out=gml.percent
						,ref_data_in=&denom_data_in
						,join_type=left
						,data_join_variables=&join_variables
						,ref_data_join_variables=&join_variables
						,vars_out=&denom_var_in) 

		%if ^%dataset_exists(dataset=gml.percent) %then %do;
			%put ERROR:1/[%sysfunc(datetime(), e8601dt.)] Could not successfully merge &data_in with &denom_data_in;
			%put ERROR:2/[%sysfunc(datetime(), e8601dt.)] See Log for futher details;
			%put ERROR:3/[%sysfunc(datetime(), e8601dt.)] Macro &macro_name aborted.;
			%return;
		%end;
		%if ^%variable_is_numeric(data_in=gml.percent,varIn=&denom_var_in) %then %return;
	%end;

	%if &display_option in (&n_percent_event_display &n_percent_denom_event_display) %then %do;
		%if %required_parameter_is_null(parameter=event_count_var_in) %then %return;
		%if ^%variable_exists(data_in=&data_in,varIn=&event_count_var_in) %then %return;
		%if ^%variable_is_numeric(data_in=&data_in,varIn=&event_count_var_in) %then %return;
	%end;

	%let random=V%sysfunc(rand(integer, 1, 5E6), hex8.);

	data &data_out;
		set %if &display_option %then gml.percent;
			%else &data_in;;
		length &var_out $200;
		retain &random "%sysfunc(ifc(&percent_symbol=Y, %str(%%), %str( )))";
		%if &display_option = &n_only_display %then %do;
			&var_out=cats(&subject_count_var_in);
		%end;
		%else %do;
			if &denom_var_in not in (. 0) then do;
				pct=divide(&subject_count_var_in, &denom_var_in) * 100;
				%if &display_option = &n_percent_display %then %do;
					&var_out=catx(' ', &subject_count_var_in, cats('(', put(pct, &percentfmt.), &random, ')'));
				%end;
				%else %if &display_option = &n_percent_denom_display %then %do;
					&var_out=catx(' ', catx('/', &subject_count_var_in, &denom_var_in), cats('(', put(pct, &percentfmt.), &random ,')'));
				%end;
				%else %if &display_option = &n_percent_event_display %then %do;
					&var_out=catx(' ', &subject_count_var_in, cats('(', put(pct, &percentfmt.), &random, ')'), &event_count_var_in);
				%end;
				%else %if &display_option = &n_percent_denom_event_display %then %do;
					&var_out=catx(' ', catx('/', &subject_count_var_in, &denom_var_in), cats('(', put(pct, &percentfmt.) , &random ,')'), &event_count_var_in);
				%end;
			end;
		%end;
		drop &random;
	run;
%mend n_percentage;