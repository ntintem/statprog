/*
*****************************************************************************************************************
Project		 : _NA_
SAS file name: nested_counts.sas
File location: <path>
*****************************************************************************************************************
Purpose: Macro used to get nested counts. Typically used for safety analysis.
Author: Mazi Ntintelo
Creation Date: 2023-08-04
*****************************************************************************************************************
CHANGES:
Date: Date of first modification of the code
Modifyer name: Name of the programmer who modified the code
Description: Shortly describe the changes made to the program
*****************************************************************************************************************
*/

%macro nested_counts(data_in=
					,data_out=open_tlf_nested_counts
					,usubjid_var=
					,subgroup_vars=
					,subgroup_vars_formats=
					,table_by_vars=
					,table_by_vars_formats=
					,by_vars=
					,by_vars_formats=
					,treatment_var=trt01pn
					,treatment_var_format=treat.
					,totals_definition=
					,nested_levels_vars=aesoc|aedecod
					,nested_levels_indent=0|1
					,subset=
					,table_section=
					,table_layout=COL001\label=System organ class Preferred Term=AESOC\indent_spaces=0 AEDECOD\indent_spaces=1
					,sort_table_by=
					,include_event_count=Y
					,debug=N
					) /minoperator des='Macro used to obtain nested counts from a dataset. Typically AEs.';
	%local
	    i
	    totals_definition_n
		subgroup_vars_n
		subgroup_vars_formats_n
		table_by_vars_n
		table_by_vars_formats_n
		by_vars_n
		by_vars_formats_n
		nested_levels_vars_n;	
		
	%let subgroup_vars_n         = %macro_var_size(macro_var=subgroup_vars, split_char=|);
	%let subgroup_vars_formats_n = %macro_var_size(macro_var=subgroup_vars_formats, split_char=|);
	%let table_by_vars_n         = %macro_var_size(macro_var=table_by_vars, split_char=|);
	%let table_by_vars_formats_n = %macro_var_size(macro_var=table_by_vars_formats, split_char=|);
	%let by_vars_n               = %macro_var_size(macro_var=by_vars, split_char=|);
	%let by_vars_formats_n       = %macro_var_size(macro_var=by_vars_formats, split_char=|);
	%let totals_definition_n     = %macro_var_size(macro_var=totals_definition, split_char=|);
	%let nested_levels_vars_n    = %macro_var_size(macro_var=nested_levels_vars, split_char=|);
	
	%if &subgroup_vars_n %then %do i=1 %to &subgroup_vars_n;
		%local subgroup_vars_&i;
	%end;
	%if &subgroup_vars_formats_n %then %do i=1 %to &subgroup_vars_formats_n;
		%local subgroup_vars_formats_&i;
	%end;
	%if &table_by_vars_n %then %do i=1 %to &table_by_vars_n;
		%local table_by_vars_&i;
	%end;
	%if &table_by_vars_formats_n %then %do i=1 %to &table_by_vars_formats_n;
		%local table_by_vars_formats_&i;
	%end;
	%if &by_vars_n %then %do i=1 %to &by_vars_n;
		%local by_vars_&i;
	%end;
	%if &by_vars_formats_n %then %do i=1 %to &by_vars_formats_n;
		%local by_vars_formats_&i;
	%end;
	%if &nested_levels_vars_n %then %do i=1 %to &nested_levels_vars_n;
		%local nested_levels_vars_&i;
	%end;
	%if &totals_definition_n %then %do i=1 %to &totals_definition_n;
		%local totals_definition_&i
		       totals_definition_&i._condition
			   totals_definition_&i._value;
	%end;
	
	/****************************************/
	/**************Validation****************/
	/****************************************/
	
	%validate_parameters_not_null(macro_variable_parameter_list=table_section debug data_in treatment_var treatment_var_format data_out nested_levels_vars nested_levels_indent include_event_count)
	%if &open_tlf_err %then %return;
	%validate_dataset_exists(data_in=&data_in)
	%if &open_tlf_err %then %return;
	%validate_dataset_name(data_name=&data_out)
	%if &open_tlf_err %then %return;
	%validate_yes_no_value(yes_no_macro_var=include_event_count)
	%if &open_tlf_err %then %return;
	%validate_yes_no_value(yes_no_macro_var=debug)
	%if &open_tlf_err %then %return;
	%validate_totals_definition
	%if &open_tlf_err %then %return;
	%validate_variable_exists(data_in=&data_in,var=&treatment_var)
	%if &open_tlf_err %then %return;
	%validate_variable_type(data_in=&data_in,var=&treatment_var,expected_var_type=N)
	%if &open_tlf_err %then %return;
	%validate_variable_exists(data_in=&data_in,var=USUBJID)
	%if &open_tlf_err %then %return;
	%validate_variable_type(data_in=&data_in,var=USUBJID,expected_var_type=C)
	%if &open_tlf_err %then %return;
	%validate_format(format_macro_var=treatment_var_format, var=&treatment_var)
	%if &open_tlf_err %then %return;
	%validate_vars(vars_macro_var=subgroup_vars)
	%if &open_tlf_err %then %return;
	%validate_formats(formats_macro_var=subgroup_vars_formats,vars_macro_var=subgroup_vars)
	%if &open_tlf_err %then %return;
	%validate_vars(vars_macro_var=table_by_vars)
	%if &open_tlf_err %then %return;
	%validate_formats(formats_macro_var=table_by_vars_formats,vars_macro_var=table_by_vars)
	%if &open_tlf_err %then %return;
	%validate_vars(vars_macro_var=by_vars)
	%if &open_tlf_err %then %return;
	%validate_formats(formats_macro_var=by_vars_formats,vars_macro_var=by_vars)
	%if &open_tlf_err %then %return;
    %validate_vars(vars_macro_var=nested_levels_vars)
	%if &open_tlf_err %then %return;
    %validate_vars(vars_macro_var=nested_levels_vars)
	%if &open_tlf_err %then %return;
	%validate_indent(indent_macro_var=nested_levels_indent, nested_level_macro_var=nested_levels_vars)
	%if &open_tlf_err %then %return;
	%merge_symbol_tables
	
	proc sort data=&data_in;
		by usubjid
		%subgroup_vars
		%table_by_vars
		%by_vars
		%nested_levels_vars;
	run;

	/****************************************/
	/**************Prep Data*****************/
	/****************************************/

	data open_tlf_nested_counts_1(%rename_nested_levels_vars);
		%length_statement_subgroup_vars
		%length_statement_table_by_vars
		%length_statement_by_vars
		set &data_in;
		%subset
		by usubjid %subgroup_vars %table_by_vars %by_vars %nested_levels_vars;
		length _level_1 - _level_&nested_levels_vars_n id_var id_lbl $200.;
		%do i=1 %to &nested_levels_vars_n;
			_level_&i=&&nested_levels_vars_&i;
			%if &include_event_count = Y %then %do;
				id_var = 'N_EVT';
				id_lbl = 'Number of Events';
				output;
				%compute_totals_definition
			%end;
			if first.&&nested_levels_vars_&i then do;
			    id_var = 'N_SUB';
			    id_lbl = 'Number of Subjects';
				output;
				%compute_totals_definition
			end;
		%end;
		keep &treatment_var id_var id_lbl
		%subgroup_vars
		%table_by_vars
		%by_vars
		_level_:;
	run;

	proc sort data=open_tlf_nested_counts_1;
		by %nested_levels_vars id_var;
	run;
	
	/****************************************/
	/*********Get NSUB and EVT count*********/
	/****************************************/

	proc summary data=open_tlf_nested_counts_1 missing completetypes nway;
		by %nested_levels_vars id_var id_lbl;
		class &treatment_var / exclusive preloadfmt;
		%class_statement_subgroup_vars
		%class_statement_by_vars
		%class_statement_table_by_vars
		format %format_statement_subgroup_vars %format_statement_table_by_vars
		       %format_statement_by_vars &treatment_var &treatment_var_format;
		output out=open_tlf_nested_counts_2;
	run;
	
	proc sort data=open_tlf_nested_counts_2;
		by %subgroup_vars %table_by_vars %by_vars
		   &treatment_var %nested_levels_vars id_var;
	run;
	
	proc transpose data=open_tlf_nested_counts_2 out=open_tlf_nested_counts_3;
		by %subgroup_vars %table_by_vars %by_vars
		   &treatment_var %nested_levels_vars;
		var _freq_;
		id id_var;
		idlabel id_lbl;
	run;
	
	 /****************************************/
	 /*************Finalization***************/
	 /****************************************/
	
	data &data_out;
		set open_tlf_nested_counts_3;
		%formatted_values_subgroup_vars
		%formatted_values_by_vars
		%formatted_values_table_by_vars
		table_section=&table_section;
		keep %subgroup_vars %table_by_vars %by_vars
			 %nested_levels_vars &treatment_var n_sub
		%if &include_event_count = Y %then n_evt;
		table_section
		;
	run;

	 /****************************************/
	 /******Clean up temporary datasets*******/
	 /****************************************/
	
	 %housekeeping(datasets_in=open_tlf_nested_counts_1 open_tlf_nested_counts_2 open_tlf_nested_counts_3)
%mend nested_counts;