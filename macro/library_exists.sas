/*
*****************************************************************************************************************
Project		 : _NA_
SAS file name: library_exists.sas
File location: <path>
*****************************************************************************************************************
Purpose: Macro used to get nested counts. Typically used for safety analysis.
Author: Mazi Ntintelo
Creation Date: 2023-08-04
*****************************************************************************************************************
CHANGES:
Date: Date of first modification of the code
Modifyer name: Name of the programmer who modified the code
Description: Shortly describe the changes made to the program
*****************************************************************************************************************
*/

%macro library_exists(libref=);
	%if %sysfunc(libref(&libref)) %then %do;
		%put ERROR:1/[%sysfunc(datetime(), e8601dt.)] Library &libref is not assigned.; 
		%put ERROR:2/[%sysfunc(datetime(), e8601dt.)] Assign library &libref in study setup file.;
		%put ERROR:3/[%sysfunc(datetime(), e8601dt.)] Macro &macro_name aborted.;
		0
		%return;
	%end;
	1
%mend library_exists;