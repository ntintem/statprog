/*
*****************************************************************************************************************
Project		 : Open TLF
SAS file name: argument_list_size.sas
File location: <path>
*****************************************************************************************************************
Purpose: Macro used to get population counts from a dataset. Typically ADSL.
Author: Mazi Ntintelo
Creation Date: 2023-06-30
*****************************************************************************************************************
CHANGES:
Date: Date of first modification of the code
Modifyer name: Name of the programmer who modified the code
Description: Shortly describe the changes made to the program
*****************************************************************************************************************
*/

%macro argument_list_size(argument_list=);
	%if %sysevalf(%superq(argument_list)=, boolean) %then %do;
		0
		%return;
	%end;
	%sysfunc(countw(%bquote(&argument_list), #))
%mend argument_list_size;
