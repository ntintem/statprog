/*
*****************************************************************************************************************
Project		 : _NA_
SAS file name: number_of_observations.sas
File location: <path>
*****************************************************************************************************************
Purpose: Project setup program.
Author: Mazi Ntintelo
Creation Date: 2023-08-04
*****************************************************************************************************************
CHANGES:
Date: Date of first modification of the code
Modifyer name: Name of the programmer who modified the code
Description: Shortly describe the changes made to the program
*****************************************************************************************************************
*/

%macro number_of_observations(data_in);
	%local dsid nobs rc;
	%if %sysfunc(%superq(data_in)=, boolean) %then %do;
		%put ERROR: Parameter data_in is required;
		%put ERROR: Macro &sysmacroname aborted;
		%return;
	%end;
	%if ^%sysfunc(exist(%bquote(&data_in))) %then %do;
		%put ERROR: Data &data_in does not exist;
		%put ERROR: Macro &sysmacroname aborted;
		%return;
	%end;
	%let dsid=%sysfunc(open(&data_in));
	%let nobs=%sysfunc(attrn(&dsid, nlobsf));
	%let rc=%sysfunc(close(&dsid));
	&nobs
%mend number_of_observations;