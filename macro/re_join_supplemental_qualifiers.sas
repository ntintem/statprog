/*
*****************************************************************************************************************
Project		 : _NA_
SAS file name: re_join_supplemental_qualifiers.sas
File location: <path>
*****************************************************************************************************************
Purpose: Macro used to re join supplemental qualifiers to parent dataset.
Author: Mazi Ntintelo
Creation Date: 2023-08-04
*****************************************************************************************************************
CHANGES:
Date: Date of first modification of the code
Modifyer name: Name of the programmer who modified the code
Description: Shortly describe the changes made to the program
*****************************************************************************************************************
*/


%macro re_join_supplemental_qualifiers(data_in=
									  ,data_out=
									  ,supp_data_in=);

	%if %sysfunc(%superq(data_in)=, boolean)  or 
		%sysfunc(%superq(data_out)=, boolean) or
		%sysfunc(%superq(supp_data_in)=, boolean)  %then %do;
		%return;
	%end;


	/*Hello world*/
%mend re_join_supplemental_qualifiers;