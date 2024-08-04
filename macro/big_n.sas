/*
*****************************************************************************************************************
Project		 : _NA_
SAS file name: big_n.sas
File location: <path>
*****************************************************************************************************************
Purpose: Macro used to get population counts from a dataset. Typically ADSL.
Author: Mazi Ntintelo
Creation Date: 2024-08-04
*****************************************************************************************************************
CHANGES:
Date: Date of first modification of the code
Modifyer name: Name of the programmer who modified the code
Description: Shortly describe the changes made to the program
*****************************************************************************************************************
*/

%macro big_n(data_in=adsl
            ,data_out=open_tlf_big_n	
			,subgroup_vars=
			,subgroup_vars_formats=
			,treatment_var=
			,treatment_var_format=
			,subset=saffl='Y'
			,totals_definition=
			,debug=N
			) /des='Macro used to get population counts from a dataset. Typically ADSL.' ;
			
			
	/****************************************/
	/****************Setup*******************/
	/****************************************/		
	%log_info(message=Setup big_n)
	%local
	    i
	    totals_definition_n
		subgroup_vars_n
		subgroup_vars_formats_n;	
	%let subgroup_vars_n         = %macro_var_size(macro_var=subgroup_vars, split_char=|);
	%let subgroup_vars_formats_n = %macro_var_size(macro_var=subgroup_vars_formats, split_char=|);
	%let totals_definition_n     = %macro_var_size(macro_var=totals_definition, split_char=|);
	%if &subgroup_vars_n %then %do i=1 %to &subgroup_vars_n;
		%local subgroup_vars_&i;
	%end;
	%if &subgroup_vars_formats_n %then %do i=1 %to &subgroup_vars_formats_n;
		%local subgroup_vars_formats_&i;
	%end;
	%if &totals_definition_n %then %do i=1 %to &totals_definition_n;
		%local totals_definition_&i
		       totals_definition_&i._condition
			   totals_definition_&i._value;
	%end;
	
	/****************************************/
	/**************Validation****************/
	/****************************************/
	
	%validate_parameters_not_null(macro_variable_parameter_list=data_in treatment_var treatment_var_format data_out debug)
	%if &open_tlf_err %then %return;
	%validate_dataset_exists(data_in=&data_in)
	%if &open_tlf_err %then %return;
	%validate_dataset_name(data_name=&data_out)
	%if &open_tlf_err %then %return;
	%validate_yes_no_value(yes_no_macro_var=debug)
	%if &open_tlf_err %then %return;
	%validate_totals_definition
	%if &open_tlf_err %then %return;
	%validate_vars(vars_macro_var=subgroup_vars)
	%if &open_tlf_err %then %return;
	%validate_formats(formats_macro_var=subgroup_vars_formats,vars_macro_var=subgroup_vars)
	%if &open_tlf_err %then %return;
	%validate_variable_exists(data_in=&data_in,var=&treatment_var)
	%if &open_tlf_err %then %return;
	%validate_variable_type(data_in=&data_in,var=&treatment_var,expected_var_type=N)
	%if &open_tlf_err %then %return;
	%validate_format(format_macro_var=treatment_var_format, var=&treatment_var)
	%if &open_tlf_err %then %return;
	
	/****************************************/
	/**************Prep Data*****************/
	/****************************************/
	
	%log_info(message=Prep data)
	
	data open_tlf_big_n_1;
		%length_statement_subgroup_vars
		set &data_in;
		%subset
		output;
		%compute_totals_definition
		keep &treatment_var %subgroup_vars;
	run;
	
	/****************************************/
	/**************Get Big N*****************/
	/****************************************/
	
	%log_info(message=Get Big N)
	
	proc summary data=open_tlf_big_n_1 completetypes nway;
		%class_statement_subgroup_vars
		class &treatment_var / preloadfmt exclusive;
		format %format_statement_subgroup_vars &treatment_var &treatment_var_format;
		output out=open_tlf_big_n_2;
	 run;
	 
	 /****************************************/
	 /*************Finalization***************/
	 /****************************************/
	 
	 %log_info(message=Finalization)
	 
	 data &data_out;
	 	set open_tlf_big_n_2;
	 	%formatted_values_subgroup_vars
	 	rename _freq_ = big_n;
	 	keep &treatment_var %subgroup_vars _freq_;
	 run;
	  
	 /****************************************/
	 /******Clean up temporary datasets*******/
	 /****************************************/
	
	 %housekeeping(datasets_in=open_tlf_big_n_1 open_tlf_big_n_2)
%mend big_n;