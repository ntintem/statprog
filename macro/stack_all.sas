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
	proc sql;
		/*get variables that appear in at least 2 datasets*/
		create table commonvars as 
			select name
			from (
					select upcase(name) as name
				    from dictionary.columns
				    where libname="&libname_1" and memname="&memname_1"
				    %do i=2 %to &tables;
					 union all
					 select upcase(name) as name
					 from dictionary.columns
					 where libname="&&libname_&i" and memname="&&memname_&i" 
				   %end;
			   )
			group by name
			having count(name) > 1;
			
			create table commonvars2 as
				select upcase(name) as name
				 	  ,type 
				from dictionary.columns
				where libname="&libname_1" and memname="&memname_1" and calculated name in (select name from commonvars)
				%do i=2 %to &tables;
					union
					select upcase(name) as name
					  	  ,type
					from dictionary.columns
					where libname="&&libname_&i" and memname="&&memname_&i" and calculated name in (select name from commonvars)
				%end;;
				create table dupchk as 
					select name
			              ,count(name) as count
			 		from commonvars2
			 		group by name
				having count(name) > 1;
			
				%if &sqlObs %then %do;
					%return;
				%end;
				create table lengths as
					select upcase(name) as name
					      ,length
					      ,1 as id 
			 	from dictionary.columns
				where libname="&libname_1" and memname="&memname_1" and type = 'char' and calculated name in (select name from commonvars)
				%do i=2 %to &tables;
					union all 
					select upcase(name) as name
					      ,length
					      ,&i as id
					from dictionary.columns
					where libname="&&libname_&i" and memname="&&memname_&i" and type = 'char' and calculated name in (select name from commonvars)
				%end;
				order by name;
	quit;
	
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
 %stack_all(data_in=x#x2
		   ,data_out=test);

