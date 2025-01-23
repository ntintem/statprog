/*
*****************************************************************************************************************
Project		 : Open TLF
SAS file name: subset.sas
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

%macro subset;
	%if %sysevalf(%superq(subset)^=, boolean) %then %do;
		where &subset;
	%end;
%mend subset;