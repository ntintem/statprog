/*
*****************************************************************************************************************
Project		 : _NA_
SAS file name: join_two_tables.sas
File location: _NA_
*****************************************************************************************************************
Purpose: Creating a summary by country and site
Author: Mazi Ntintelo
Creation Date: 2024-09-18
*****************************************************************************************************************
CHANGES:
Date: Date of first modification of the code
Modifyer name: Name of the programmer who modified the code
Description: Shortly describe the changes made to the program
*****************************************************************************************************************
*/


/**/
%macro join_two_tables(data_in=
					  ,data_out=join_two_tables
					  ,ref_data_in=
					  ,join_type=left
					  ,data_in_join_vars=
					  ,ref_data_in_join_vars=
					  ,extend_vars=) /minoperator;
					  		 
	%if %sysevalf(superq(data_in)=, boolean) 				or
		%sysevalf(superq(data_out)=, boolean)				or
		%sysevalf(superq(join_type)=, boolean)				or
		%sysevalf(superq(data_in_join_vars)=, boolean)		or
		%sysevalf(superq(ref_data_in)=, boolean)			or
		%sysevalf(superq(extend_vars)=, boolean) %then %do;
			%put ERROR: Macro parameters data_in, data_out, join_type, data_in_join_vars and extend_vars are required;
			%put ERROR: Macro &sysmacroname aborted;
			%return;
	%end;
	
	
	%let dsid1=%sysfunc(open(&data_in));
	%let dsid2=%sysfunc(open(&ref_data_in));
	%let ref_data_in_join_vars = %sysfunc(coalescec(&ref_data_in_join_vars, &data_in_join_vars));
	%let size_extend_vars=%sysfunc(countw(&extend_vars, #));
	%let size_join_vars=%sysfunc(countw(&data_in_join_vars, #));
	
	%do i=1 %to &size_extend_vars;
		%local extend_var_&i;
		%let extend_var_&i = %scan(&extend_vars, &i, #);
		%if ^%sysfunc(varnum(&dsid2, &&extend_var_&i)) %then %do;
			%put ERROR: Macro parameters data_in, data_out, join_type, data_in_join_vars and extend_vars are required;
			%put ERROR: Macro &sysmacroname aborted;
			%return;
		%end;
		%if %sysfunc(varnum(&dsid1, &&extend_var_&i)) %then %do;
			%put ERROR: Macro parameters data_in, data_out, join_type, data_in_join_vars and extend_vars are required;
			%put ERROR: Macro &sysmacroname aborted;
			%return;
		%end;
	%end;
	
	%do i=1 %to &size_join_vars;
		%local data_in_join_var_&i ref_data_in_join_var_&i;
		%let data_in_join_var_&i = %scan(&data_in_join_vars, &i, #);
		%let ref_data_in_join_var_&i = %scan(&ref_data_in_join_vars, &i, #);
		
		%if ^%sysfunc(varnum(&dsid1, &&data_in_join_var_&i)) %then %do;
		
			%return;
		%end;
		%if ^%sysfunc(varnum(&dsid2, &&ref_data_in_join_&i)) %then %do;
		
			%return;
		%end;
		
		%if %sysfunc(vartype(&dsid1, %sysfunc(varnum(&dsid1, &&data_in_join_var_&i)))) ne 
		   %sysfunc(vartype(&dsid2, %sysfunc(varnum(&dsid2, &&ref_data_in_join_&i)))) %then %do;
		 	%return;
		 %end;
	%end;
	
	
	data _null_;
		call symputx('duplicate_extend_variable', 0, 'l');
		length name $32;
		dcl hash _h_ (hashexp:7);
				 _h_.definekey("name");
				 _h_.definedone();
		array vars [&size_extend_vars] $32 _temporary_ (
														%do i=1 %to &size_extend_vars;
																"%upcase(%trim(&&extend_var_&i))"
														%end;);
		do i=1 to dim(vars);
			name=vars[i];
			if ^_h_.check() then do;	
				call symputx('duplicate_extend_variable', 1, 'l');
				leave;
			end;
			rc=_h_.add();
		end;
	run;

	%if &duplicate_extend_variables %then %do;
		%return;
	%end;
	
	proc sql;
		create table &dataOut as
			select l.*
				  ,r.&extend_var_1
			%do i=2 %to &size_extend_vars;
				  ,r.&&extend_var_&i
			%end;
		from &data_in     as l &join_type
		     &ref_data_in as r
		 on l.&data_in_join_var_1 = r.&ref_data_in_join_var1
		 %do i=2 %to &size_join_vars;
		 	and l.&&data_in_join_var_&i = r.&&ref_data_in_join_var_&i
		 %end;
		 ;
	quit;			
%mend join_two_tables;