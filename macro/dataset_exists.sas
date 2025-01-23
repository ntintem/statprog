/*
*****************************************************************************************************************
Project		 : _NA_
SAS file name: dataset_exists.sas
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

%macro dataset_exists(data_in=);
	%if ^%sysfunc(exist(&data_in)) %then %do;
		%put ERROR:1/[%sysfunc(datetime(), e8601dt.)] data &data_in does not exist.;
		%put ERROR:2/[%sysfunc(datetime(), e8601dt.)] Macro &macro_name aborted.;
		0
		%return;
	%end;
	1
%mend dataset_exists;