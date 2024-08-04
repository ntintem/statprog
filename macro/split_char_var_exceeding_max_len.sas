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
				   ,max_len=200
				   ,split_var=
				   ,prefix=);

	%local dsid 
		   rc 
		   splitVarExists
		   libref
		   i
		   hasData
		   dropTables;
	%*Ensure all parameters are given;
 	%if %sysevalf(%superq(dataIn)  =, boolean)  or 
 	 	%sysevalf(%superq(dataOut) =, boolean)  or
	 	%sysevalf(%superq(maxLen)  =, boolean)  or  
	 	%sysevalf(%superq(splitVar)=, boolean)  or 
	 	%sysevalf(%superq(prefix)  =, boolean)  %then %do;
	 		%put %sysfunc(repeat(-, 99));
	 		%put ERROR: All keyword parameters must be given!;
	 		%put NOTE: &dataIn=;
	 		%put NOTE: &dataOut=;
	 		%put NOTE: &maxLen=;
	 		%put NOTE: &splitVar=;
	 		%put NOTE: &prefix=;
	 		%put %sysfunc(repeat(-, 99));
			%return;
	%end;
	%*Ensure dataIn actually exists;
	%if ^%sysfunc(exist(%bquote(&dataIn))) %then %do;
			%put %sysfunc(repeat(-, 99));
	 		%put ERROR: Dataset &dataIn does not exist;
	 		%put %sysfunc(repeat(-, 99));
			%return;
	%end;
	%*Ensure prefix is a valid prefix for a variable name;
	%if ^%sysfunc(prxmatch(%str(m/^[A-Za-z_][A-Za-z_]+$/oi), %bquote(&prefix))) %then %do;
			%put %sysfunc(repeat(-, 99));
	 		%put ERROR: prefix is not a valid prefix for a SAS variable name;
	 		%put %sysfunc(repeat(-, 99));
			%return;
	%end;
	%*Ensure maxLen is actually a valid integer;
	%if ^%sysfunc(prxmatch(%str(m/^\d+$/oi), %bquote(&maxLen))) %then %do;
			%put %sysfunc(repeat(-, 99));
	 		%put ERROR: maxLen is not a valid integer;
	 		%put %sysfunc(repeat(-, 99));
			%return;
	%end;
	%*Ensure dataOut is a valid SAS Name 2 level SAS name;
	%if %sysfunc(prxmatch(%str(m/^[A-Za-z_][A-Za-z_0-9]{1,7}[.][A-Za-z_][A-Za-z_0-9]{1,31}$/oi), %bquote(&dataOut))) %then %do;
		%let libref=%scan(&dataOut, 1, .);
		%*if 2 level name, ensure libref is assinged;
		%if %sysfunc(libref(&libref)) %then %do;
			%put %sysfunc(repeat(-, 99));
	 		%put ERROR: dataOut is a valid SAS 2 level name, however libref &libref is not assigned!;
	 		%put %sysfunc(repeat(-, 99));
			%return;
		%end;
	%end;
	%*Ensure dataOut is a valid SAS Name 1 level SAS name;
	%else %if ^%sysfunc(prxmatch(%str(m/^[A-Za-z_][A-Za-z_0-9]{1,31}$/oi), %bquote(&dataOut))) %then %do;
		%put %sysfunc(repeat(-, 99));
	 	%put ERROR: dataOut is not a valid SAS dataset name!;
	 	%put %sysfunc(repeat(-, 99));
		%return;
	%end;
	%*Ensure splitVar is actually exists in dataIn;
	%let dsid=%sysfunc(open(&dataIn));
	%let splitVarExists=%sysfunc(varnum(&dsid, %bquote(&splitVar)));
	%if ^&splitVarExists %then %do;
		%let rc=%sysfunc(close(&dsid));
		%put %sysfunc(repeat(-, 99));
	 	%put ERROR: &splitVar variable was not found in dataset &dataIn!;
	 	%put %sysfunc(repeat(-, 99));
		%return;
	%end;
	%*Ensure splitVar is actually exists in dataIn;
	%if %sysfunc(vartype(&dsid, &splitVarExists)) ne C %then %do;
		%let rc=%sysfunc(close(&dsid));
		%put %sysfunc(repeat(-, 99));
	 	%put ERROR: &splitVar variable was found in dataset &dataIn, however, was not defined as Character;
	 	%put %sysfunc(repeat(-, 99));
		%return;
	%end;
	%let rc=%sysfunc(close(&dsid));

	%put %sysfunc(repeat(-, 99));
	%put NOTE: Begin Splitting Data;
	%put %sysfunc(repeat(-, 99));
	%let hasData=0;

	data split(drop=_:) 
		 temp(keep=row __counter__ __text__);
		retain __flag__ __maxCol__ 0;
		set &dataIn end=eof;
		length __text__ $&maxLen.. __tmp__ __string__ __stringTmp__ $32767. __lastWordFromString__ __lastWordFromStringTmp__ __word__$200.;
		__tmp__	   =strip(&splitVar);
		__counter__=0;
		row = _n_;
        do __ii__= 1 to countw(__tmp__, ' ');
			__word__ = scan(__tmp__, __ii__, ' ');
			if length(__word__)> &maxLen then do;
				put 'WARNING:' _n_ = 'word=' __word__+(-1) " is greater than &maxLen characters";
				goto end;
			end;
		end;
		if length(__tmp__) > &maxLen then do while(^missing(__tmp__));
			__counter__+1;
			__string__=substr(__tmp__, 1, &maxLen);
			__lastWordFromString__=scan(__string__, -1, ' ');
			__firstWhiteSpaceAfterMaxLen__= find(__tmp__, ' ', '', &maxLen);
			__stringTmp__ = substr(__tmp__, 1, __firstWhiteSpaceAfterMaxLen__-1);
			__lastWordFromStringTmp__ = scan(__stringTmp__, -1, ' ');
			if __lastWordFromStringTmp__ ne __lastWordFromString__ then do;
				__whiteSpace__= find(__tmp__, ' ', '', -&maxLen);
				__text__= substr(__tmp__, 1, __whiteSpace__ - 1);
				__tmp__ = substr(__tmp__, __whiteSpace__ + 1);
			end;
			else do;
				__text__ = __string__;
				__tmp__	 = substr(__tmp__, &maxLen + 1);
			end;
			output temp;
			__flag__ = 1;
		end;
		else do;
			__counter__=1;
			__text__   = __tmp__;
			output temp;
		end;
		__maxCol__ = max(__maxCol__, __counter__);
		end:
		if eof then do;
			call symputx('numberOfColumns', __maxCol__, 'l');
			call symputx('anyDataSplit', __flag__, 'l');
		end;
		output split;
	run;
	%if &sysnobs %then %do;
		%let dropTables=split temp t_text;
		proc transpose data=temp out=t_text prefix=&prefix;
			by row;
			id __counter__;
			var __text__;
		run;
		proc sql;
			create table &dataOut(drop=row) as 
				select a.*
					%do i=1 %to &numberOfColumns;
						,b.&prefix&i as &prefix.%sysfunc(ifc(&i=1, %str( ), %eval(&i - 1)))
					%end;
				from split 	as a natural left join 
					 t_text as b;
		quit;
		%if ^&anyDataSplit %then %do;
			%put %sysfunc(repeat(-, 99));
			%put NOTE: No Splitting done, since no text is greater than &maxLen characters;
			%put %sysfunc(repeat(-, 99));
		%end;
		%put %sysfunc(repeat(-, 99));
		%put NOTE: DataSet &dataOut Succsessfully created;
		%put %sysfunc(repeat(-, 99));
	%end;
	%else %do;
		%let dropTables=temp;
		proc datasets lib=work mt=data;
			%if %sysfunc(exist(&dataOut)) %then %do;
				delete &dataOut;
			%end;
			change split = &dataOut;
		quit;
		proc sql;
			alter table	&dataOut
			add &prefix char(&maxLen)
			drop column row;
		quit;	
	%end;
	proc delete data=&dropTables;
	run;
	%put %sysfunc(repeat(-, 99));
	%put NOTE: End of Macro &sysmacroname;
	%put %sysfunc(repeat(-, 99));
%mend splitCharVar;

options mprint;

data ees5;
	length text $32767.;
	text='Assessment of the change in tumour burden is an important feature of the clinical evaluation of cancer therapeutics. Both tumour shrinkage (objective response) and time to the development of disease progression are important endpoints in cancer clinical trials. The use of tumour regression as the endpoint for phase II trials screening new agents for evidence of anti-tumour effect is supported by years of evidence suggesting that, for many solid tumours, agents which produce tumour shrinkage in a proportion of patients have a reasonable (albeit imperfect) chance of subsequently demonstrating an improvement in overall survival or other time to event measures in randomised phase III studies (reviewed in [1–4]). At the current time objective response carries with it a body of evidence greater than for any other biomarker supporting its utility as a measure of promising treatment effect in phase II screening trials. Furthermore, at both the phase II and phase III stage of drug development, clinical trials in advanced disease settings are increasingly utilising time to progression (or progression-free survival) as an endpoint upon which efficacy conclusions are drawn, which is also based on anatomical measurement of tumour size'; output;
	text='This is a very long piece of text. More Text to Follow. More Text to Follow. More Text to Follow'; output;
	text='This is a very long piece of text. More Text to Follow.'; output;
	text='This'; output;
	text='This'; output;
run;

%split_char_var_exceeding_max_len(dataIn=ees5
			 ,dataOut=tttttt
			 ,maxLen=30
			 ,splitVar=text
			 ,prefix=DVTERM)