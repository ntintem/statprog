/*
*****************************************************************************************************************
Project		 : _NA_
SAS file name: split_char_var_exceeding_max_len.sas
File location: <path>
*****************************************************************************************************************
Purpose: Macro used to split a character variable into N chuncks depending on max_len.
Author: Mazi Ntintelo
Creation Date: 2023-08-04
*****************************************************************************************************************
CHANGES:
Date: Date of first modification of the code
Modifyer name: Name of the programmer who modified the code
Description: Shortly describe the changes made to the program
*****************************************************************************************************************
*/

%macro split_char_var_exceeding_max_len(data_in=
				   					   ,data_out=
				   					   ,max_length=200
				   					   ,var_in=
									   ,split_var_in_by=
				   					   ,var_out_prefix=);
	%local macro_name
		   i
		   vars_out 
		   random;
	%let macro_name = &sysmacroname; 
	%if %required_parameter_is_null(parameter=data_in) %then %return;							
	%if %required_parameter_is_null(parameter=data_out) %then %return;
	%if %required_parameter_is_null(parameter=max_length) %then %return; 
	%if %required_parameter_is_null(parameter=var_in) %then %return;
	%if %required_parameter_is_null(parameter=var_out_prefix) %then %return;
	%if ^%dataset_exists(data_in=&data_in) %then %return;
	%if ^%library_exists(libref=gml) %then %return;
	%if %length(%bquote(&split_var_in_by)) > 1 %then %do;
		%put ERROR:1/[%sysfunc(datetime(), e8601dt.)] Split character %bquote(&split_var_in_by) is too long;
		%put ERROR:2/[%sysfunc(datetime(), e8601dt.)] Specify only one character;
		%put ERROR:2/[%sysfunc(datetime(), e8601dt.)] Macro &sysmacroname aborted;
		%return;
	%end;
	%if ^%sysfunc(prxmatch(%str(m/^[A-Za-z_][A-Za-z_]+$/oi), %bquote(&var_out_prefix))) %then %do;
	 	%put ERROR:1/[%sysfunc(datetime(), e8601dt.)] var_out_prefix is not a valid prefix for a variable name;
		%put ERROR:2/[%sysfunc(datetime(), e8601dt.)] var_out_prefix must begin with an underscore or a letter and may not contain numbers;
		%put ERROR:2/[%sysfunc(datetime(), e8601dt.)] Macro &sysmacroname aborted;
		%return;
	%end;
	%if ^%integer_value_received(parameter=max_length) %then %return;	
	%if ^%dataset_name_is_valid(data_in=&data_out) %then %return;
	%if ^%variable_exists(data_in=&data_in,var_in=&var_in) %then %return;
	%if ^%variable_is_character(data_in=&data_in,var_in=&var_in) %then %return;
	
	%if %sysevalf(%superq(split_var_in_by)=, boolean) %then %let split_var_in_by=%str( );
	%let random=V%sysfunc(rand(integer, 1, 5E6), hex8.);

	data gml.split(drop=&random:) gml.temp(keep=row_&random &random._counter &random._text);
		retain &random._flag &random._max_col 0;
		set &data_in(rename=(&var_in = &random)) end=eof;
		length &random._text $&max_length.;
		&random._tmp=strip(compbl(&random));
		&random._counter=0;
		row_&random. = _n_;
		&random._datetime=datetime();
		do while(length(&random._tmp) > &max_length);
			&random._counter+1;
			&random._pos = find(&random._tmp, "&split_var_in_by", 'i', -&max_length);
			if ^&random._pos then do;
				put "ERROR:1/[" &random._datetime e8601dt. "] record " _n_ "split character &split_var_in_by not found in '" &random._tmp +(-1) "' within &max_length character limit";
				put "ERROR:2/[" &random._datetime e8601dt. "] record " _n_ "review input variable and adjust lengths as needed";
				put "ERROR:3/[" &random._datetime e8601dt. "] record " _n_ "split unsuccsessful";
				goto end;
			end;
			else do;
				&random._text = substr(&random._tmp, 1, &random._pos - 1);
				&random._tmp  = strip(substr(&random._tmp, &random._pos + 1));
			end;
			output gml.temp;
			&random._flag = 1;
		end;
		if ^missing(&random._tmp) then do;
			&random._counter+1;
			&random._text=&random._tmp;
			output gml.temp;
		end;
		&random._max_col = max(&random._max_col, &random._counter);
		end:
		if eof then do;
			call symputx('number_of_columns', &random._max_col, 'l');
			call symputx('any_data_split', &random._flag, 'l');
		end;
		output gml.split;
	run;

	%if %number_of_observations(data_in=gml.temp) %then %do;

		proc transpose data=gml.temp out=gml.t_text prefix=&var_out_prefix;
			by row_&random;
			id &random._counter;
			var &random._text;
		run;

		proc datasets lib=gml mt=data nodetails nolist;
			modify t_text;
			rename
				&var_out_prefix.1 = &var_out_prefix
				%do i=2 %to &number_of_columns;
					&var_out_prefix&i = &var_out_prefix.%eval(&i - 1)
				%end;
				;
		quit;

		proc sql noprint;
			select name into: vars_out separated by '#'
			from dictionary.columns
			where libname='GML' and memname='T_TEXT' and name eqt "%upcase(&var_out_prefix)";
		quit;

		%join_two_tables(data_in=gml.split
						,data_out=&data_out
						,ref_data_in=gml.t_text
						,join_type=left
						,data_join_variables=row_&random
						,ref_data_join_variables=row_&random
						,vars_out=&vars_out)

		%if ^%sysfunc(exist(&data_out)) %then %do;
			%put ERROR:1/[%sysfunc(datetime(), e8601dt.)] Data &data_out not created;
			%put ERROR:2/[%sysfunc(datetime(), e8601dt.)] See Log For details;
			%put ERROR:3/[%sysfunc(datetime(), e8601dt.)] Macro &sysmacroname aborted;
			%return;
		%end;

		%if ^&any_data_split %then %do;
			%put NOTE:1/[%sysfunc(datetime(), e8601dt.)] No text is greater than &max_length characters.;
			%put NOTE:2/[%sysfunc(datetime(), e8601dt.)] No Splitting Done.;
		%end;

		proc sql;
			alter table	&data_out
			drop column row_&random;
		quit;	
	%end;
	%else %do;
		data &data_out;
			set gml.split;
			length &var_out_prefix $&max_length;
			call missing(of &var_out_prefix);
			drop row_&random;
		run;
	%end;
%mend split_char_var_exceeding_max_len;