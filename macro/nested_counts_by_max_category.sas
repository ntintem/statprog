/*
*****************************************************************************************************************
Project		 : _NA_
SAS file name: nested_counts_by_max_category.sas
File location: <path>
*****************************************************************************************************************
Purpose: Macro used to get nested counts by maximum categorical variable.
Author: Mazi Ntintelo
Creation Date: 2023-08-04
*****************************************************************************************************************
CHANGES:
Date: Date of first modification of the code
Modifyer name: Name of the programmer who modified the code
Description: Shortly describe the changes made to the program
*****************************************************************************************************************
*/

%macro nested_counts_by_max_category(data_in=
									,data_out=nested_counts_by_max_category
									,by_vars=
									,by_vars_formats=
									,subgroup_vars=
									,subgroup_vars_formats=
									,table_by_vars=
									,table_by_vars_formats=
									,treatment_var=
									,treatment_var_format=									
									,categorical_var=
									,categorical_var_n=
									,categorical_var_format=
									,categorical_var_indent=
									,total=
									,nested_levels=
									,merge_nested_levels_into_1_col=
									,indent_nested_levels=
									,layout=
									,subset=saffl= 'Y') /minoperator des='';


	%local i
		   j
		   format_type
		   var_type
		   formats
		   types
		   rc
		   dsid
		   libref
		   max_cat_var_n
		   number_of_categorical_var_fmts
		   number_of_nested_levels
		   number_of_subgroup_vars
		   number_of_subgroup_vars_formats
		   number_of_table_by_vars
		   number_of_table_by_vars_formats
		   number_of_by_vars_formats
		   number_of_by_vars
		   total_definition_condition_part
		   total_definition_value_part
		   type_top_level
		;

	%validate_parameters_not_null(macro_variable_parameter_list=merge_nested_levels_into_1_col data_in treatment_var categorical_var categorical_var_n treatment_var_format data_out nested_levels indent_nested_levels);
	/*%if %superq(rc) ne 0 %then %do;
		%put %sysfunc(repeat(-,99));
		%put ERROR: The following parameters are required and may not be null!: &rc;
		%put %sysfunc(repeat(-,99));
		%return;
	%end;*/
	%if ^(%sysfunc(exist(%superq(data_in))) or %sysfunc(exist(%superq(data_in), VIEW))) %then %do;
		%put %sysfunc(repeat(-,99));
		%put ERROR: The dataset or view &data_in cannot be found!;
		%put %sysfunc(repeat(-,99));
		%return;
	%end;
	%if %sysfunc(prxmatch(%str(m/^[A-Za-z_][A-Za-z_0-9]{1,7}[.][A-Za-z_][A-Za-z_0-9]{1,31}$/oi), %superq(data_out))) %then %do;
		%let libref=%scan(&data_out, 1, .);
		%if %sysfunc(libref(&libref)) %then %do;
			%put %sysfunc(repeat(-, 99));
	 		%put ERROR: data_out is a valid SAS 2 level name, however libref &libref is not assigned!;
	 		%put %sysfunc(repeat(-, 99));
			%return;
		%end;
	%end;
	%else %if ^%sysfunc(prxmatch(%str(m/^[A-Za-z_][A-Za-z_0-9]{1,31}$/oi), %superq(data_out))) %then %do;
		%put %sysfunc(repeat(-, 99));
	 	%put ERROR: dataOut is not a valid SAS dataset name!;
	 	%put %sysfunc(repeat(-, 99));
		%return;
	%end;
	%if ^%eval(%qupcase(%superq(merge_nested_levels_into_1_col)) in Y YES N NO) %then %do;
		%return;
	%end;
	%let merge_nested_levels_into_1_col = %upcase(%substr(&merge_nested_levels_into_1_col, 1, 1));
	%let number_of_total_definitions=0;
	%let total_definition_condition_part=1;
	%let total_definition_value_part=2;
	%if ^%sysevalf(%superq(total)=, boolean) %then %do;
		%let number_of_total_definitions=%sysfunc(countw(&total, |));
		%do i=1 %to &number_of_total_definitions;
			%local total_definition_&i;
			%let total_definition_&i = %qscan(%bquote(&total), &i, |);
			%if ^%sysfunc(prxmatch(%str(m/^\d+[+]\d+([+]\d+)*=\d+$/oi),%superq(total_definition_&i))) %then %do;
				%put hello!;
				%return;
			%end;
			%local total_definition_&i._condition
				   total_definition_&i._value;
			%let total_definition_&i._condition = %sysfunc(tranwrd(%qscan(&&total_definition_&i, &total_definition_condition_part, =), +, %str(, )));
			%let total_definition_&i._value = %scan(&&total_definition_&i, &total_definition_value_part, =);
		%end;
	%end;
	%let dsid=%sysfunc(open(&data_in));
	%if ^%sysfunc(varnum(&dsid, &treatment_var)) %then %do;
		%put %sysfunc(repeat(-,99));
		%put ERROR: The variable &treatment_var was not found in the dataset or view &data_in!;
		%put %sysfunc(repeat(-,99));
		%let rc=%sysfunc(close(&dsid));
		%return;
	%end;
	%if %sysfunc(vartype(&dsid, %sysfunc(varnum(&dsid, %superq(treatment_var))))) ne N %then %do;
		%put %sysfunc(repeat(-,99));
		%put ERROR: The variable &treament_var was not found in the expected type (Numeric)!;
		%put %sysfunc(repeat(-,99));
		%let rc=%sysfunc(close(&dsid));
		%return;
	%end;
	%let number_of_subgroup_vars=0;
	%if ^%sysevalf(%superq(subgroup_vars)=, boolean) %then %do;
		%let number_of_subgroup_vars = sys%sysfunc(countw(&subgroup_vars, |)); 
		%do i=1 %to &number_of_subgroup_vars;
			%local subgroup_vars_&i;
			%let subgroup_vars_&i = %scan(&subgroup_vars, &i, |);
			%if ^%sysfunc(varnum(&dsid, &&subgroup_vars_&i)) %then %do;	
				%let rc=%sysfunc(close(&dsid));	
			%end;
		%end;
	%end;
	%let number_of_subgroup_vars_formats=0;
	%if ^%sysevalf(%superq(subgroup_vars_formats)=, boolean) %then %do;
		%let number_of_subgroup_vars_formats = %sysfunc(countw(&subgroup_vars_formats, |));
		%if &number_of_subgroup_vars ne &number_of_subgroup_vars_formats %then %do;
			%let rc=%sysfunc(close(&dsid));	
		%end;
		%do i=1 %to &number_of_subgroup_vars_formats;
			%let format_type=;
			%local subgroup_vars_formats_&i;
			%let subgroup_vars_formats_&i = %upcase(%scan(&subgroup_vars_formats, &i, |));
			%if %superq(subgroup_vars_formats_&i) = _NA_ %then %goto bypass_subgroup;
			%if %qsubstr(&&subgroup_vars_formats_&i, 1, 1) = $ %then %do;
				%let format_type = C;
				%let subgroup_vars_formats_&i = %substr(&&subgroup_vars_formats_&i, 2);
			%end;
			%if %qsubstr(&&subgroup_vars_formats_&i, %length(&&subgroup_vars_formats_&i)) ne . %then %let subgroup_vars_formats_&i = &&subgroup_vars_formats_&i...;
			%if ^%sysfunc(cexist(work.formats.&&subgroup_vars_formats_&i..format&format_type)) %then %do;
				%let rc=%sysfunc(close(&dsid));
				%return;
			%end;
			%if &format_type = C %then %let subgroup_vars_formats_&i = $&&subgroup_vars_formats_&i;
			%let var_type=%sysfunc(vartype(&dsid, %sysfunc(varnum(&dsid, &&subgroup_vars_&i))));
			%if ^((&var_type = C and &format_type = C) or 
			  	  (&var_type = N and &format_type = )) %then %do;
				%let rc=%sysfunc(close(&dsid));	
			%end; 
		%end;
		%bypass_subgroup:
	%end;
	%let number_of_table_by_vars=0;
	%if ^%sysevalf(%superq(table_by_vars)=, boolean) %then %do;
		%let number_of_table_by_vars = %sysfunc(countw(&table_by_vars, |)); 
		%do i=1 %to &number_of_table_by_vars;
			%local table_by_vars_&i;
			%let table_by_vars_&i = %scan(&table_by_vars, &i, |);
			%if ^%sysfunc(varnum(&dsid, &&table_by_vars&i)) %then %do;	
				%let rc=%sysfunc(close(&dsid));	
			%end;
		%end;
	%end;
	%let number_of_table_by_vars_formats=0;
	%if ^%sysevalf(%superq(table_by_vars_formats)=, boolean) %then %do;
		%let number_of_table_by_vars_formats = %sysfunc(countw(&table_by_vars_formats, |));
		%if &number_of_table_by_vars ne &number_of_table_by_vars_formats %then %do;
			%let rc=%sysfunc(close(&dsid));	
		%end;
		%do i=1 %to &number_of_table_by_vars_formats;
			%let format_type=;
			%local table_by_vars_formats_&i;
			%let table_by_vars_formats_&i = %upcase(%scan(&table_by_vars_formats, &i, |));
			%if %superq(table_by_vars_formats&i) = _NA_ %then %goto bypass_table_by;
			%if %qsubstr(&&table_by_vars_formats&i, 1, 1) = $ %then %do;
				%let format_type = C;
				%let table_by_vars_formats_&i = %substr(&&table_by_vars_formats_&i, 2);
			%end;
			%if %qsubstr(&&table_by_vars_formats_&i, %length(&&table_by_vars_formats_&i)) ne . %then %let table_by_vars_formats_&i = &&table_by_vars_formats_&i...;
			%if ^%sysfunc(cexist(work.formats.&&table_by_vars_formats_&i..format&format_type)) %then %do;
				%let rc=%sysfunc(close(&dsid));
				%return;
			%end;
			%if &format_type = C %then %let table_by_vars_formats_&i = $&&table_by_vars_formats_&i;
			%let var_type=%sysfunc(vartype(&dsid, %sysfunc(varnum(&dsid, &&table_by_vars_&i))));
			%if ^((&var_type = C and &format_type = C) or 
			  	  (&var_type = N and &format_type = )) %then %do;
				%let rc=%sysfunc(close(&dsid));	
			%end; 
		%end;
		%bypass_table_by:
	%end;
	%let number_of_by_vars=0;
	%if ^%sysevalf(%superq(by_vars)=, boolean) %then %do;
		%let number_of_by_vars = %sysfunc(countw(&by_vars, |)); 
		%do i=1 %to &number_of_by_vars;
			%local by_vars_&i;
			%let by_vars_&i = %scan(&by_vars, &i, |);
			%if ^%sysfunc(varnum(&dsid, &&by_vars&i)) %then %do;	
				%let rc=%sysfunc(close(&dsid));	
			%end;
		%end;
	%end;
	%let number_of_by_vars_formats=0;
	%if ^%sysevalf(%superq(by_vars_formats)=, boolean) %then %do;
		%let number_of_by_vars_formats = %sysfunc(countw(&by_vars_formats, |));
		%if &number_of_by_vars ne &number_of_by_vars_formats %then %do;
			%let rc=%sysfunc(close(&dsid));	
		%end;
		%do i=1 %to &number_of_by_vars_formats;
			%let format_type=;
			%local by_vars_formats_&i;
			%let by_vars_formats_&i = %upcase(%scan(&by_vars_formats, &i, |));
			%if %superq(by_vars_formats&i) = _NA_ %then %goto bypass_by;
			%if %qsubstr(&&by_vars_formats&i, 1, 1) = $ %then %do;
				%let format_type = C;
				%let by_vars_formats_&i = %substr(&&by_vars_formats_&i, 2);
			%end;
			%if %qsubstr(&&by_vars_formats_&i, %length(&&by_vars_formats_&i)) ne . %then %let by_vars_formats_&i = &&by_vars_formats_&i...;
			%if ^%sysfunc(cexist(work.formats.&&by_vars_formats_&i..format&format_type)) %then %do;
				%let rc=%sysfunc(close(&dsid));
				%return;
			%end;
			%if &format_type = C %then %let by_vars_formats_&i = $&&by_vars_formats_&i;
			%let var_type=%sysfunc(vartype(&dsid, %sysfunc(varnum(&dsid, &&by_vars_&i))));
			%if ^((&var_type = C and &format_type = C) or 
			  	  (&var_type = N and &format_type = )) %then %do;
				%let rc=%sysfunc(close(&dsid));	
			%end; 
		%end;
		%bypass_by:
	%end;
	%if ^%sysfunc(varnum(&dsid, &treatment_var)) %then %do;
		%let rc=%sysfunc(close(&dsid));
		%put issue 1;
		%return;
	%end;
	%if %sysfunc(vartype(&dsid, %sysfunc(varnum(&dsid, &treatment_var)))) ne N %then %do;
		%let rc=%sysfunc(close(&dsid));
		%put issue 2;
		%return;
	%end;
	%if ^%sysfunc(cexist(work.formats.&treatment_var_format.format)) %then %do;
		%put issue 3;
		%return;
	%end;
	%if ^%sysfunc(varnum(&dsid, &categorical_var)) %then %do;
		%let rc=%sysfunc(close(&dsid));
		%put issue 4;
		%return;
	%end; 
	%if ^%sysfunc(varnum(&dsid, &categorical_var_n)) %then %do;
		%let rc=%sysfunc(close(&dsid));
		%put issue 5;
		%return;
	%end; 
	%if %sysfunc(vartype(&dsid, %sysfunc(varnum(&dsid, &categorical_var_n)))) ne N %then %do;
		%let rc=%sysfunc(close(&dsid));
		%put issue 6;
		%return;
	%end;
	%let number_of_categorical_var_fmts=0;
	%if ^%sysevalf(%superq(categorical_var_format)=, boolean) %then %do;
		%let number_of_categorical_var_fmts = 1;
		%let format_type=;
		%if %qsubstr(&categorical_var_format, 1, 1) = $ %then %do;
			%let format_type = C;
			%let categorical_var_format = %substr(&categorical_var_format, 2);
		%end;
		%if %qsubstr(&categorical_var_format, %length(&categorical_var_format)) ne . %then %let categorical_var_format = &categorical_var_format..;
		%if ^%sysfunc(cexist(work.formats.&categorical_var_format.format&format_type)) %then %do;
			%let rc=%sysfunc(close(&dsid));
			%return;
		%end;
		%if &format_type = C %then %let categorical_var_format = $&categorical_var_format;
		%let var_type=%sysfunc(vartype(&dsid, %sysfunc(varnum(&dsid, &categorical_var))));
		%if ^((&var_type = C and &format_type = C) or 
			  (&var_type = N and &format_type = )) %then %do;
			%let rc=%sysfunc(close(&dsid));	
			%return;
		%end; 
	%end; 
    %let number_of_nested_levels = %sysfunc(countw(&nested_levels, |));
    %do i=1 %to &number_of_nested_levels;
		%local nested_levels_&i;
		%let nested_levels_&i = %scan(&nested_levels, &i, |);
		%if ^%sysfunc(varnum(&dsid, &&nested_levels_&i)) %then %do;	
			%let rc=%sysfunc(close(&dsid));	
		%end;	
   %end;
   %let rc=%sysfunc(close(&dsid));
   %let number_of_indentations  = %sysfunc(countw(&indent_nested_levels, |));
   %if &number_of_nested_levels ne &number_of_indentations %then %do;
   		%return;
   %end;
   %do i=1 %to &number_of_indentations;
   		%local indent_nested_levels_&i;
		%let indent_nested_levels_&i = %scan(&indent_nested_levels, &i, |);
		%if ^%sysfunc(prxmatch(%str(m/^\d+$/oi), %superq(indent_nested_levels_&i))) %then %do;
			%return;
		%end;
   %end;

   proc sort nodupkey data=&data_in(keep=&categorical_var &categorical_var_n) out=_uniques;
		by &categorical_var &categorical_var_n;	
   run; 

   proc sql;
   		create table _err as 
			select &categorical_var
				  ,&categorical_var_n
			from _uniques
			group by &categorical_var
			having count(*) > 1;
	quit;

	%if &sqlObs %then %do;
		%put Not 1 to 1;
		%return;
	%end;

	proc sort nodupkey data=&data_in(keep=&categorical_var &categorical_var_n) out=_uniques;
		by &categorical_var &categorical_var_n;	
    run;

	proc sort data=&data_in;
		by usubjid
		%if &&number_of_table_by_vars %then %do i=1 %to &&number_of_table_by_vars;
			&&table_by_vars_&i
		%end;
		%if &&number_of_by_vars %then %do i=1 %to &&number_of_by_vars;
			&&by_vars_&i
		%end;
		%if &&number_of_nested_levels %then %do i=1 %to &&number_of_nested_levels;
			&&nested_levels_&i
		%end;
		&categorical_var_n
		;
	run;

	data prep;
		set &data_in
		%if ^%sysevalf(%superq(subset)=, boolean) ne %then %do;
			(where=(&subset))
		%end;
		;
		by usubjid 
		%if &&number_of_table_by_vars %then %do i=1 %to &&number_of_table_by_vars;
			&&table_by_vars_&i
		%end;
		%if &&number_of_by_vars %then %do i=1 %to &&number_of_by_vars;
			&&by_vars_&i
		%end;
		%do i=1 %to &number_of_nested_levels;
			&&nested_levels_&i
		%end;
		;
		if _n_ = 1 then do;
			dcl hash _values(dataset: '_uniques');
				_values.definekey("&categorical_var_n");
				_values.definedata("&categorical_var");
				_values.definedone();
		end;
		retain _max_level_1 - _max_level_%eval(&number_of_nested_levels);
		%do i=1 %to %eval(&number_of_nested_levels - 1);
			if first.&&nested_levels_&i then _max_level_%eval(&i + 1)=-&sysMaxLong.;
		%end;
		%do i=1 %to &number_of_nested_levels;
			_level_&i = &&nested_levels_&i;
		%end;
		%let max_cat_var_n=&categorical_var_n;
		%do i=&number_of_nested_levels %to 1 %by -1;
			if last.&&nested_levels_&i then do;
				%if &i ne &number_of_nested_levels %then %do;
					call missing (of %do j = &i %to %eval(&number_of_nested_levels - 1);
										_level_%eval(&j + 1)	
									%end;
								  );
				%end;
				_level=&i;
				_max_1=&max_cat_var_n;
				_rc = _values.find(key: _max_1);
				_max_2=&categorical_var;
				_max_level_&i = max(_max_level_&i, &max_cat_var_n);
				output;
				%if &number_of_total_definitions %then %do j=1 %to &number_of_total_definitions;
					if &treatment_var in (&&total_definition_&j._condition) then do;
						treatment_var_prev = &treatment_var;
						&treatment_var = &&total_definition_&j._value;
						output;
						&treatment_var = treatment_var_prev;
					end;
				%end;
				%let max_cat_var_n=_max_level_&i;
			end;
		%end;
		keep &treatment_var 
		%if &number_of_table_by_vars %then %do i=1 %to &number_of_table_by_vars;
			&&table_by_vars_&i
		%end;
		%if &number_of_by_vars %then %do i=1 %to &number_of_by_vars;
			&&by_vars_&i
		%end;
		%if &number_of_subgroup_vars %then %do i=1 %to &number_of_subgroup_vars;
			&&subgroup_vars_&i
		%end;
		usubjid _level: _max_1 _max_2;
	run;

	proc sort data=prep presorted;
		by _level_1 - _level_&number_of_nested_levels _level;
	run;

	%let types	 = &treatment_var;
	%let formats = &treatment_var &treatment_var_format _max_2 &categorical_var_format;

	proc summary data=prep missing completetypes;
		by _level_1 - _level_&number_of_nested_levels _level;
		class &treatment_var / exclusive preloadfmt;
		class _max_2
		%if &number_of_categorical_var_fmts %then %do;
			/ exclusive preloadfmt
		%end;;
		%if &number_of_subgroup_vars %then %do;
			%do i=1 %to &number_of_subgroup_vars;
				class &&subgroup_vars_&i
				%let types=&types*&&subgroup_vars_&i;
				%if &number_of_subgroup_vars_formats %then %do;
					%if &&subgroup_vars_formats_&i ne _NA_ %then %do;
						%let formats=&formats &&subgroup_vars_&i &&subgroup_vars_formats_&i;
						 / exclusive preloadfmt
					%end;;
				%end;
			%end;
		%end;
		%if &number_of_by_vars %then %do;
			%do i=1 %to &number_of_by_vars;
				class &&by_vars_&i
				%let types=&types*&&by_vars_&i;
				%if &number_of_by_vars_formats %then %do;
					%if &&by_vars_formats_&i ne _NA_ %then %do;
						%let formats=&formats &&by_vars_&i &&by_vars_formats_&i;
						 / exclusive preloadfmt
					%end;;
				%end;
			%end;
		%end;
		%if &number_of_table_by_vars %then %do;
			%do i=1 %to &number_of_table_by_vars;
				class &&table_by_vars_&i
				%let types=&types*&&by_vars_&i;
				%if &number_of_table_by_vars_formats %then %do;
					%if &&table_by_vars_formats_&i ne _NA_ %then %do;
						%let formats=&formats &&table_by_vars_&i &&table_by_vars_formats_&i;
						 / exclusive preloadfmt
					%end;;
				%end;
			%end;
		%end;
		%let types=&types*_max_2;
		types &types %substr(&types, 1, %length(&types) - %length(_max_2) - 1);
		format &formats;
		output out=counts(rename=(_FREQ_ = NSUB));
	run;

	proc sql noprint;
		select min(_type_) into: type_top_level
		from counts;
	quit;

	%if &merge_nested_levels_into_1_col = Y %then %do;
		data _merge_into_1_col;
			length COL1 $200.;
			set counts;	
			if _type_=&type_top_level then COL1=repeat(' ',symgetn(cats('indent_nested_levels_', _level)))!!choosec(_level, of _level_1-_level_&number_of_nested_levels);
			else COL1=repeat(' ', symgetn('categorical_var_indent'))!!cats(_max_2);
		run;
	%end;

	proc sort data=&syslast;
		by treat _level_1 _level_2 _level _type_ ;
	run;

%mend;

options mprint;
%nested_counts_by_max_category(data_in=ae
							  ,data_out=nested_counts
							  ,by_vars=
							  ,by_vars_formats=
							  ,subgroup_vars=
							  ,subgroup_vars_formats=
							  ,table_by_vars=
							  ,table_by_vars_formats=
						      ,treatment_var=trt01pn
							  ,treatment_var_format=treat.
							  ,categorical_var=aesev
							  ,categorical_var_format=$max.
							  ,categorical_var_n=aesevn
							  ,categorical_var_indent=2
							  ,total=1+2=77|1+2+3=99
							  ,nested_levels=aesoc|aedecod
							  ,indent_nested_levels=0|1
							  ,merge_nested_levels_into_1_col=Y
							  ,subset=saffl= 'Y')


