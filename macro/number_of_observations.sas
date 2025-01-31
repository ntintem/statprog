/*
*****************************************************************************************************************
Project		 : _NA_
SAS file name: number_of_observations.sas
File location: <path>
*****************************************************************************************************************
Purpose: Macro to determine number of observations in a given dataset
Author: Mazi Ntintelo
Creation Date: 2025-01-31
*****************************************************************************************************************
CHANGES:
Date: Date of first modification of the code
Modifyer name: Name of the programmer who modified the code
Description: Shortly describe the changes made to the program
*****************************************************************************************************************
*/

%macro number_of_observations(data_in=);
	%local dsid
		   rc 
		   nobs 
		   macro_name;
	%let macro_name = &sysmacroname;
	%if %required_parameter_is_null(parameter=data_in) %then %return;
	%if ^%dataset_exists(data_in=&data_in) %then %return;
	%let dsid=%sysfunc(open(&dataIn));
	%let nobs=%sysfunc(attrn(&dsid, nlobsf));
	%let rc=%sysfunc(close(&dsid));
	&nobs
%mend number_of_observations;