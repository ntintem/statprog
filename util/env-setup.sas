/*
*****************************************************************************************************************
Project		 : _NA_
SAS file name: env-setup.sas
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

/*mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm*/
/*mmmmmmmmmmmmmmmmmmmmmmmmmmmmm Global Macro Variables mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm*/
/*mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm*/

%let client=;
%let root=;

/*mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm*/
/*mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm Librariesmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm*/
/*mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm*/

libname raw  base "&root/&client/sourcedata";
libname sdtm base "&root/&client/statprog/sdtm";
libname adam base "&root/&client/statprog/adam";
libname tlf  base "&root/&client/statprog/tlf";

/*mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm*/
/*mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm Options mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm*/
/*mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm*/

options validvarname=upcase compress=yes msglevel=i missing='' pagesize='A4' yearcutoff=1930 ls=max pageno=1
orientation=landscape nodate nonumber topmargin=1in bottommargin=1in leftmargin=1in rightmargin=1in
nobyline mprint mlogic mprintnest noquotelenmax symbolgen mautosource mautolocdisplay mrecall mautocomploc sasautos=(sasautos, "&root/statprog/macro/");
ods escapechar='!';

/*mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm*/
/*mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm Formats mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm*/
/*mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm*/

proc format;
	value trtovr (multilabel notsorted)
		'Drug A' = 'Drug A'
		'Drug B' = 'Drug B'
		'Drug C' = 'Drug C'
		'Drug A', 'Drug B', 'Drug C' = 'Total';
		
	value trtbasic (multilabel notsorted)
		'Drug A' = 'Drug A'
		'Drug B' = 'Drug B'
		'Drug C' = 'Drug C';
run;

/*mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm*/
/*mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm Templates mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm*/
/*mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm*/

proc template;
  define style RTFStyle;
  parent = Styles.RTF;
  style systemtitle /
    font_face  = "Courier New"
    background = white;
  style systemfooter /
    font_face  = "Courier New"
    background = white;
  style header /
    font_face  = "Courier New"
    font_size  = 8
    background = white;
  style data /
    font_face  = "Courier New"
    font_size  = 8
    background = white;
  style table /
    foreground  = black
    background  = white
    cellspacing = 0
    cellpadding = 3;
  style body /
    foreground   = black
    background   = white
    topmargin    = 1in
    bottommargin = 1in
    leftmargin   = 1in
    rightmargin  = 1in;
  end;
run;




