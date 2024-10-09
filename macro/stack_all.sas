/*
*****************************************************************************************************************
Project		 : _NA_
SAS file name: stack_all.sas
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


%macro stack_all(data_in=
				,data_out=);
	%local tables
		   table
		   random
		   common_char_vars
		   set_operator
		   i;
	%let tables = %sysfunc(countw(%bquote(&data_in), #));
	%do i=1 %to &tables;
		%local libname_&i
			   memname_&i;
		%let table = %upcase(%scan(&data_in, &i, #));
		%if %index(&table, .) %then %do;
			%let libname_&i = %scan(&table, 1, .);
			%let memname_&i = %scan(&table, 2, .);
		%end;
		%else %do;
			%let libname_&i = WORK;
			%let memname_&i = &table;
		%end;
	%end;
	%let common_char_vars=0;
	%let set_operator=;
	proc sql;
		create table commonvars as 
			select name
			from (
					%do i=1 %to &tables;
						&set_operator
						select upcase(name) as name
				    	from dictionary.columns
				   		where libname="&&libname_&i" and memname="&&memname_&i" 
				   		%let set_operator = union all;
				    %end; 
			   )
			group by name
			having count(name) > 1;
			%if ^&sqlObs %then %do;
				%put NOTE: No common variables found between datasets;
				quit;
				%goto skip;
			%end;
			%let set_operator=;
			create table commonvars2 as
				%do i=1 %to &tables;
					&set_operator
					select upcase(name) as name
					  	  ,type
					from dictionary.columns
					where libname="&&libname_&i" and memname="&&memname_&i" and calculated name in (select name from commonvars)
					%let set_operator = union;
				%end;;
				create table dupchk as 
					select name
			 		from commonvars2
			 		group by name
				having count(name) > 1;
				%if &sqlObs %then %do;
					%put ERROR: Conflicting types for variables with the same name;
					%put ERROR: Variables with the same name must have the same type across all datasets;
					%put ERROR: See work.dupchk data for more information;
					%put ERROR: Macro &sysmacroname aborted;
					quit;
					%return;
				%end;
				%let set_operator=;
				create table lengths as
				%do i=1 %to &tables;
					&set_operator
					select upcase(name) as name
					      ,length
					      ,&i as id
					from dictionary.columns
					where libname="&&libname_&i" and memname="&&memname_&i" and type = 'char' and calculated name in (select name from commonvars)
					%let set_operator = union all;
				%end;
				order by name;
	quit;
	
	%if ^&sqlObs %then %do;
		%put NOTE: No common character variables were found; 
		%goto skip;
	%end;
	
	proc transpose data=lengths out=t_len prefix=length;
		by name;
		var length;
		id id;
	run;
	
	data _null_;
		set t_len end=eof nobs=nobs;
		var+1;
		call symputx(cats('var_', var), name, 'l');
		call symputx(cats('length_', var), max(of length:), 'l');
		if eof then call symputx('common_char_vars', nobs, 'l');
	run;
	
	%skip:
	%let random=V%sysfunc(rand(integer, 1, 5E6), hex8.);
	data &data_out;
		length &random $200
		%do i=1 %to &common_char_vars;
			&&var_&i $&&length_&i
		%end;;	
		set 
		%do i=1 %to &tables;
			&&libname_&i...&&memname_&i
		%end;;
		call missing(&random);
		drop &random;
	run;
%mend stack_all;
options mprint;
 %stack_all(data_in=sashelp.class#sashelp.class#sashelp.cars
		   ,data_out=test);

