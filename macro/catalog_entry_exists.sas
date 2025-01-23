/*
*****************************************************************************************************************
Project		 : _NA_
SAS file name: catalog_entry_exists.sas
File location: <path>
*****************************************************************************************************************
Purpose: Macro used to get population counts from a dataset. Typically ADSL.
Author: Mazi Ntintelo
Creation Date: 2025-01-23
*****************************************************************************************************************
CHANGES:
Date: Date of first modification of the code
Modifyer name: Name of the programmer who modified the code
Description: Shortly describe the changes made to the program
*****************************************************************************************************************
*/


%macro catalog_entry_exists(entry=);
	%if ^%sysfunc(cexist(&entry)) %then %do;
		%put ERROR:1/[%sysfunc(datetime(), e8601dt.)] The entry &entry was not found.;
		%put ERROR:2/[%sysfunc(datetime(), e8601dt.)] Macro &macro_name aborted.;
		0
		%return;
	%end;
	1
%mend catalog_entry_exists;
