/*
*****************************************************************************************************************
Project		 : _NA_
SAS file name: variable_type.sas
File location: _NA_
*****************************************************************************************************************
Purpose: Returns the data type of a variable from a dataset
Author: Mazi Ntintelo
Creation Date: 2025-03-18
*****************************************************************************************************************
CHANGES:
Date: Date of first modification of the code
Modifyer name: Name of the programmer who modified the code
Description: Shortly describe the changes made to the program
*****************************************************************************************************************
*/

%macro variable_type(data_in=
			        ,var_in=);			
	%local dsid
		   rc
		   var_type;
	%let dsid=%sysfunc(open(&data_in));
	%let var_type = %sysfunc(vartype(&dsid, %sysfunc(varnum(&dsid, &var_in))));
	%let rc=%sysfunc(close(&dsid));
	&var_type			
%mend variable_type;