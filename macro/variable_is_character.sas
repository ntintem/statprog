/*
*****************************************************************************************************************
Project		 : _NA_
SAS file name: variable_is_character.sas
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

%macro variable_is_character(data_in=
							,var_in=);
	%if %variable_type(data_in=&data_in,var_in=&var_in) = N %then %do;
		%put ERROR:1/[%sysfunc(datetime(), e8601dt.)] Variable &var_in is not in the expected type.;
		%put ERROR:2/[%sysfunc(datetime(), e8601dt.)] Expected type is character.;
		%put ERROR:4/[%sysfunc(datetime(), e8601dt.)] Macro &macro_name aborted.;
		0
		%return;
	%end;
	1						
%mend variable_is_character;