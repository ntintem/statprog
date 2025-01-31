/*
*****************************************************************************************************************
Project		 : _NA_
SAS file name: join_two_tables.sas
File location: _NA_
*****************************************************************************************************************
Purpose: Facilitates the process of merging two tables
Author: Mazi Ntintelo
Creation Date: 2024-09-18
*****************************************************************************************************************
CHANGES:
Date: Date of first modification of the code
Modifyer name: Name of the programmer who modified the code
Description: Shortly describe the changes made to the program
*****************************************************************************************************************
*/


%macro join_two_tables(data_in=
					  ,data_out=
					  ,ref_data_in=
					  ,join_type=left
					  ,data_join_variables=
					  ,ref_data_join_variables=
					  ,vars_out=) / minoperator;
	%local j 
		   i 
		   macro_name
		   dsid 
		   rc 
		   ds1 
		   ds2 
		   data_join_variables_size
		   ref_data_join_variables_size
		   total_datasets_size
		   vars_out_size 
		   operator 
		   duplicate_vars_out;
	%let macro_name = &sysmacroname;
	%if %required_parameter_is_null(parameter=data_in) %then %return;
	%if %required_parameter_is_null(parameter=data_out) %then %return;
	%if %required_parameter_is_null(parameter=ref_data_in) %then %return;
	%if %required_parameter_is_null(parameter=join_type) %then %return;
	%if %required_parameter_is_null(parameter=data_join_variables) %then %return;
	%if %required_parameter_is_null(parameter=ref_data_join_variables) %then %return;
	%if %required_parameter_is_null(parameter=vars_out) %then %return;
	%if ^%dataset_exists(data_in=&data_in) %then %return;
	%if ^%dataset_exists(data_in=&ref_data_in) %then %return;
	%if ^%dataset_name_is_valid(data_in=&data_out) %then %return;
	%if ^%library_exists(libref=gml) %then %return;
	%if ^%eval(%qlowcase(%bquote(&join_type)) in full left right inner) %then %do;
		%put ERROR:1/[%sysfunc(datetime(), e8601dt.)] Join Type %bquote(&join_type) is invalid.; 
		%put ERROR:2/[%sysfunc(datetime(), e8601dt.)] Vaild types are: full, left, right and inner;
		%put ERROR:3/[%sysfunc(datetime(), e8601dt.)] Macro &macro_name aborted;
		%return;
	%end;
	
	%let data_join_variables_size=%argument_list_size(argument_list=&data_join_variables);
	%let ref_data_join_variables_size=%argument_list_size(argument_list=&ref_data_join_variables);
	
	%if &ref_data_join_variables_size ne &data_join_variables_size %then %do;
		%put ERROR:1/[%sysfunc(datetime(), e8601dt.)] Unequal number of join variables between ref_data_join_variables and data_join_variables;
		%put ERROR:2/[%sysfunc(datetime(), e8601dt.)] Number of join variables must match;
		%put ERROR:3/[%sysfunc(datetime(), e8601dt.)] Macro &macro_name aborted;
		%return;
	%end;
	%let ds1=&data_in;
	%let ds2=&ref_data_in;
	%let total_datasets_size=2;
	%let vars_out_size=%argument_list_size(argument_list=&vars_out);
	%do i=1 %to &data_join_variables_size;
		%local ds1_join_var&i 
		       ds2_join_var&i;
		%let ds1_join_var&i=%scan(&data_join_variables, &i, #);
		%let ds2_join_var&i=%scan(&ref_data_join_variables, &i, #);
		%do j=1 %to &total_datasets_size;
			%if ^%variable_name_is_valid(var_in=&&ds&j.join_var&i) %then %return;
		%end;
	%end;
	%do i=1 %to &total_datasets_size;
		%do j=1 %to &data_join_variables_size;
			%if ^%variable_exists(data_in=&&ds&i,var_in=&&ds&i.join_var&j) %then %return;
		%end;
	%end;
	%do i=1 %to &data_join_variables_size;		
		%if %variable_type(data_in=&data_in,var_in=&&ds1_join_var&i) ne %variable_type(data_in=&ref_data_in,var_in=&&ds2_join_var&i) %then %do;
			%put ERROR:1/[%sysfunc(datetime(), e8601dt.)] Variable type mismatch between &data_in..&&ds1_join_var&i and &ref_data_in..&&ds2_join_var&i;
			%put ERROR:2/[%sysfunc(datetime(), e8601dt.)] Macro &macro_name aborted;
			%return;
		%end;	
	%end;
	%do i=1 %to &vars_out_size;
		%local var_out&i;
		%let var_out&i=%scan(&vars_out, &i, #);
		%if ^%variable_name_is_valid(var_in=&&var_out&i) %then %return;
		%if ^%variable_exists(data_in=&ref_data_in,var_in=&&var_out&i) %then %return;
		%if %variable_exists(data_in=&data_in,var_in=&&var_out&i) %then %do;
			%put ERROR:1/[%sysfunc(datetime(), e8601dt.)] Variable &&var_out&i already exists in &data_in data;
			%put ERROR:2/[%sysfunc(datetime(), e8601dt.)] Macro &macro_name aborted;
			%return;
		%end;	
	%end;
	%let duplicate_vars_out=0;
	data _null_;
		length vname $100;
		array list [&vars_out_size] $200 _temporary_ ( %do i=1 %to &vars_out_size;
														"%upcase(%trim(&&var_out&i))"
											   		  %end;
											 		 );
		dcl hash _h_(hashexp:7);
				 _h_.definekey("vname");
				 _h_.definedone();

		do i=1 to dim(list);
			vname=strip(list[i]);
			if ^_h_.check() then do;
				call symputx('duplicate_variable', vname, 'l');
				call symputx('duplicate_vars_out', 1, 'l');
				leave;
			end;
			rc=_h_.add();
		end;
	run;

	%if &duplicate_vars_out %then %do;
		%put ERROR:1/[%sysfunc(datetime(), e8601dt.)] Duplicated variable &duplicate_variable found in vars_out list.;
		%put ERROR:2/[%sysfunc(datetime(), e8601dt.)] All variables supplied to the vars_out parameter must be unique.;
		%put ERROR:3/[%sysfunc(datetime(), e8601dt.)] Remove all duplicated variables.;
		%put ERROR:4/[%sysfunc(datetime(), e8601dt.)] Macro &macro_name aborted;
		%return;
	%end;

	%do i=1 %to &total_datasets_size;
		proc sql;
			create table gml.ds&i as 
				select 
					&&ds&i.join_var1
					%do j=2 %to &data_join_variables_size;
						,&&ds&i.join_var&j
					%end;
					,count(*) as _COUNT_
				from &&ds&i
				group by 
				&&ds&i.join_var1
					%do j=2 %to &data_join_variables_size;
						,&&ds&i.join_var&j
					%end;
				having count(*)> 1;
		quit;
	%end;
	%if %number_of_observations(data_in=gml.ds1) and %number_of_observations(data_in=gml.ds2) %then %do;
		%put ERROR:1/[%sysfunc(datetime(), e8601dt.)] Combination of join variables do not yield a unique row on either &data_in or &ref_data_in;
		%put ERROR:2/[%sysfunc(datetime(), e8601dt.)] Many-to-Many Merge operation not supported;
		%put ERROR:3/[%sysfunc(datetime(), e8601dt.)] See gml.DS1 and gml.DS2 for details;
		%put ERROR:4/[%sysfunc(datetime(), e8601dt.)] Macro &macro_name aborted;
		%return;
	%end;
	%let operator=;
	%if %lowcase(&join_type) = full %then %do;
		%local size3;
		%let dsid=%sysfunc(open(&data_in));
		%let size3=0;
		%do i=1 %to %sysfunc(attrn(&dsid, nvar));
			%if ^%eval(%lowcase(%sysfunc(varname(&dsid, &i))) in %sysfunc(tranwrd(%trim(%left(%lowcase(&data_join_variables))), #, %str( )))) %then %do;
				%local select_var&size3;
				%let size3=%eval(&size3 + 1);
				%let select_var&size3 = %sysfunc(varname(&dsid, &i));	
			%end;
		%end;
		%let rc=%sysfunc(close(&dsid));
	%end;

	proc sql;
		create table &data_out as 
			select 
			%if %lowcase(&join_type) = full %then %do;
				coalesce(l.&ds1_join_var1, r.&ds2_join_var1) as &ds1_join_var1
				%do i=2 %to &data_join_variables_size;
					,coalesce(l.&&ds1_join_var&i, r.&&ds2_join_var&i) as &&ds1_join_var&i
				%end;
				%do i=1 %to &size3;
					,l.&&select_var&i
				%end;
			%end;
			%else %do;
				l.*
			%end;
			%do i=1 %to &vars_out_size;
				,r.&&var_out&i
			%end;
			from &data_in    as l &join_type join
				 &ref_data_in as r on
			%do i=1 %to &data_join_variables_size;
				&operator
				l.&&ds1_join_var&i = r.&&ds2_join_var&i
				%let operator=and;
			%end;
			;
	quit;
%mend join_two_tables;