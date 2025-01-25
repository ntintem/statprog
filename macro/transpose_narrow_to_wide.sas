/*
*****************************************************************************************************************
Project		 : _NA_
SAS file name: transpose_narrow_to_wide.sas
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





%macro transpose_narrow_to_wide(data_in=
				  			   ,data_out=
				  			   ,subgroup_vars_in=
				  			   ,by_vars_in=
				  			   ,id_vars_in=
				 			   ,transpose_vars_in=);

	%local	j
			transpose_vars_size
			id_vars_size
			subgroup_vars_size
			by_vars_size
			macro_name 
			i;	

	/****************************************/
	/**************Validation****************/
	/****************************************/

	%let macro_name = &sysmacroname;	
	%if %required_parameter_is_null(parameter=data_in) %then %return;							
	%if %required_parameter_is_null(parameter=data_out) %then %return;		
	%if %required_parameter_is_null(parameter=transpose_vars_in) %then %return;			
	%if %required_parameter_is_null(parameter=id_vars_in) %then %return;			
	%if ^%library_exists(libref=gml) %then %return;
	%if ^%dataset_name_is_valid(data_in=&data_out) %then %return;	
	%let transpose_vars_size=%argument_list_size(argument_list=&transpose_vars_in);
	%let id_vars_size=%argument_list_size(argument_list=&id_vars_in);
	%let subgroup_vars_size=%argument_list_size(argument_list=&subgroup_vars_in);
	%let by_vars_size=%argument_list_size(argument_list=&by_vars_in);
	%do i=1 %to &transpose_vars_size;
		%local transpose_var&i;
		%let transpose_var&i=%scan(&transpose_vars_in, &i, #);
		%if ^%variable_exists(data_in=&data_in, var_in=&&transpose_var&i) %then %return;
	%end;
	%do i=1 %to &id_vars_size;
		%local id_var&i;
		%let id_var&i=%scan(&id_vars_in, &i, #);
		%if ^%variable_exists(data_in=&data_in, var_in=&&id_var&i) %then %return;
	%end;
	%do i=1 %to &subgroup_vars_size;
		%local subgroup_var&i;
		%let subgroup_var&i=%scan(&subgroup_vars_in, &i, #);
		%if ^%variable_exists(data_in=&data_in, var_in=&&subgroup_var&i) %then %return;
	%end;
	%do i=1 %to &by_vars_size;
		%local by_var&i;
	%end;
	
	%if ^%by_vars_are_valid %then %return;

	%if &subgroup_vars_size or &by_vars_size %then %do;
		proc sort data=&data_in;
			by %subgroups %by_vars;
		quit;
	%end;

	%do i=1 %to &transpose_vars_size;
		
		proc sql;
			create table gml.repeats as
			select &id_var1
					%do j=2 %to &id_vars_size;
						,&&id_var&j
					%end;
					%do j=1 %to &subgroup_vars_size;
						,&&subgroup_var&j
					%end;
					%do j=1 %to &&by_vars_size;
						,&&by_var&j
					%end; 
				from &data_in
				group by 
				&id_var1
				%do j=2 %to &id_vars_size;
					,&&id_var&j 
				%end;
				%do j=1 %to &subgroup_vars_size;
					,&&subgroup_var&j
				%end;
				%do j=1 %to &&by_vars_size;
					,&&by_var&j
				%end;
				having count(*) > 1;
			quit;

		%if %number_of_observations(data_in=gml.repeats) %then %do;
			%put ERROR:1/[%sysfunc(datetime(), e8601dt.)] Key combination of variable/s %subgroups %by_vars %sysfunc(tranwrd(&id_vars_in, #, %str( ))) does not yield a unique row;
			%put ERROR:2/[%sysfunc(datetime(), e8601dt.)] Please ensure that key combination yields a unique row;
			%put ERROR:3/[%sysfunc(datetime(), e8601dt.)] See gml.repeats data for further details;
			%put ERROR:4/[%sysfunc(datetime(), e8601dt.)] Macro &macro_name aborted;
			%return;
		%end;
		
		proc transpose data=&data_in 
					   out=
			%if &transpose_vars_size = 1 %then %do;
				&data_out
			%end;
			%else %do;
				gml.&&transpose_var&i 
			%end;
			prefix=&&transpose_var&i.._;
			%if &subgroup_vars_size or &by_vars_size %then %do;
				by %subgroups %by_vars;
			%end;
			var &&transpose_var&i;
			id
			%do j=1 %to &id_vars_size;
				&&id_var&j
			%end;;
		run;

	%end;
	%if &transpose_vars_size ne 1 %then %do;
		data &data_out;
			merge 
			%do i=1 %to &transpose_vars_size;
				gml.&&transpose_var&i (keep=%subgroups %by_vars &&transpose_var&i.._:)
			%end;;
			%if &subgroup_vars_size or &by_vars_size %then %do;
				by %subgroups %by_vars;
			%end; 
		run;
	%end;
%mend transpose_narrow_to_wide;