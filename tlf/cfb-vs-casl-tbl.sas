/*
*****************************************************************************************************************
Project		 : _NA_
SAS file name: cfb-vs-casl-tbl.sas
File location: _NA_
*****************************************************************************************************************
Purpose: Creating A Basic Change From Baseline Table For Vitals (CASL)
Author: Mazi Ntintelo
Creation Date: 2024-08-04
*****************************************************************************************************************
CHANGES:
Date: Date of first modification of the code
Modifyer name: Name of the programmer who modified the code
Description: Shortly describe the changes made to the program
*****************************************************************************************************************
*/

%let path=<Path to your data>;
*******************************************************
***********1. Establishing a CAS Connection************
*******************************************************;

cas mysession sessopts=(timeout=1800 locale="en_US", metrics=true);

*******************************************************
***********2. Create a user-defined CASLIB*************
*******************************************************;

proc cas;
	table.queryCasLib result=rc/ caslib="adam";
	describe rc;
	print rc;
	if !rc["adam"] then do; 
		table.addCasLib / path="&path/cdisc_pilot"
					  	  name="adam";
	end;
quit;

*******************************************************
**********3. Load base SAS tables into memory**********
*******************************************************;

proc cas;
	advsTable = {caslib="casuser", name="advs"};
	adslTable = {caslib="casuser", name="adsl"};
	summaryTable = {caslib="casuser", name="summary"}; 
	allData  = {advsTable, adslTable};
	do table over allData;
		table.loadtable/ path=table["name"]|| ".sas7bdat"
					     caslib="adam"
					     casOut=table || {replace=true};
	end;
quit;

*******************************************************
**********************4. Get Big N*********************
*******************************************************;

proc cas;
	adslTable = {caslib="casuser", name="adsl"};
	freqtab.freqtab result = bign/ table=adslTable || {where = "saffl = 'Y'"}
					tabulate= {{vars={"trt01a", "trt01an"}}};
	describe bign;
	print bign;

	bign_clean=bign["Table1.CrossList"].where(trt01an != . and f_trt01a != 'Total');

	saveresult bign_clean
			   caslib="casuser" 
			   casout="bign" replace;
quit;

*******************************************************
****************5. Get Summary stats*******************
*******************************************************;

proc cas;
	advsTable = {caslib="casuser", name="advs"};
	summaryTable = {caslib="casuser", name="summary"}; 
	aggregation.aggregate / table = advsTable || {where="saffl = 'Y' and anl01fl='Y'"
												 ,groupby={"paramcd", "param", "trta", "trtan", "avisitn", "avisit", "atptn", "atpt"}}
						    varSpecs = {{name="aval", agg="median"}
									   ,{name="aval", summarySubset={"n", "mean", "std", "min", "max"}}
									   ,{name="chg", agg="median"}
									   ,{name="chg", summarySubset={"n", "mean", "std", "min", "max"}}}
							casOut = summaryTable|| {replace=true};
quit;

*******************************************************
****************6. Get Max decimals********************
*******************************************************;

proc cas;
	source query;
		create table casuser.combined{options replace=true} as 
			select a.*
				  ,b.max_dec_aval
				  ,b.max_dec_chg
				  ,c.frequency
			from casuser.summary as a left join
			(select paramcd
				  ,param
				  ,max(lengthn(scan(put(aval, best.), 2, '.'))) as max_dec_aval
				  ,max(lengthn(scan(put(chg, best.), 2, '.')))  as max_dec_chg
			from casuser.advs
			group by paramcd, param) as b
			on a.paramcd = b.paramcd and 
			   a.param   = b.param  left join casuser.bign as c
			on a.trta    = c.trt01a and 
			   a.trtan   = c.trt01an;
	endsource;
	fedSql.execDirect/ query=query;
quit;

*******************************************************
****************7. Format to shell*********************
*******************************************************;

proc cas;	
	source shellFormat;
		data casuser.transformed;
			set casuser.combined;
			array stats [2, 6] _aval_summary_nobs_ _aval_summary_mean_ _aval_summary_std_  _aval_summary_min_  _aval_q2_ _aval_summary_max_ 
			                   _chg_summary_nobs_ _chg_summary_mean_ _chg_summary_std_ _chg_summary_min_ _chg_q2_ _chg_summary_max_;
			array max_dec[2] max_dec_aval max_dec_chg;
			length label varchar(10) value varchar(20) trtlabel varchar (40);
			array stats_c [2, 6] $10 _temporary_; 
			trtlabel = catx(' ', trta, cats('(N=', frequency, ')'));
			do i=1 to dim1(stats);
				var = choosec(i, 'AVAL', 'CHG');
				if avisitn = 0 and i = 2 then continue;
				do j=1 to dim2(stats);
					label = ifc(j = 1, 'n', ifc(j = 5, 'Median', ''));
					if j=1 then decimals = 0;
					else decimals = sum(max_dec[i], choosen(j-1, 1, 2, 0, 1, 0));
					stats_c[i, j]=left(putn(round(stats[i, j], divide(1, 10**decimals)), cats(sum(8, divide(decimals, 10)))));
					value=stats_c[i, j];
					ord=j;
					if j in (1 5) then output;
				end;
				ord=2;
				label = 'Mean (SD)';
				value = catx(' ', stats_c[i, 2], cats('(', stats_c[i, 3], ')'));
				output;
				ord=6;
				label = 'Min, Max';
				value = catx(', ', stats_c[i, 4], stats_c[i, 6]);
				output;
			end;
		run;
	endsource;
	datastep.runCode/ code=shellFormat;
quit;

*******************************************************
**********8. Transpose from Narrow to wide*************
*******************************************************;

proc cas;
	transpose.transpose / table = {name="transformed"
								  ,caslib="casuser"
								  ,groupby={"paramcd", "param", "avisitn", "avisit", "atptn", "atpt", "var", "ord", "label"}}
						  transpose = {"value"}
						  id = {"trtan"}
						  idlabel = "trtlabel"
						  prefix="_"
						 casOut={name="transposed", replace=true, caslib="casuser"};
quit;

*******************************************************
*********9. Add by rows for visual preference**********
*******************************************************;

proc cas;
	source addByRows;
		data casuser.final;
			length col001 varchar(100);
			set casuser.transposed;
			by paramcd avisitn atptn var ord;
			col001 = '   '!!strip(label);
			output;
			if first.atptn then do;
				ord = ord-.0001;
				col001 = catx(' ', avisit, propcase(atpt));
				call missing(of _0 -- _81);
				output;
			end;
			else if first.var and var='CHG' then do;
				ord = ord-.0001;
				col001 = '  Change from Baseline';
				call missing(of _0 -- _81);
				output;
			end;
		run;
	endsource;
	datastep.runCode/ code=addByRows;
quit;

*******************************************************
**************10. Reporting Effort*********************
*******************************************************;
options nobyline;
title j=c "Parameter: #byval2";
ods listing close;
proc report data=casuser.final split='~' missing style(column)=[asis=on just=c cellwidth=15%] style(header)=[asis=on just=c];;
	by paramcd param;
	columns paramcd avisitn atptn var ord col001 _0 _54 _81;
	define paramcd / order order=internal noprint;
	define avisitn / order order=internal noprint;
	define atptn / order order=internal noprint;
	define ord / order order=internal noprint;
	define var / order order=internal noprint;
	define col001 / "Visit/Timepoint~  Analysis Variable/~   Statistic" style(column)=[asis=on just=l cellwidth=54%] style(header)=[asis=on just=l];
	compute before var;
		line '';
	endcomp;
run;

*******************************************************
**************11. Cleaning Up**************************
*******************************************************;

proc cas;
	table.tableinfo result = rc/ caslib="casuser";
	do table over rc["TableInfo"][, "Name"] - {"ADSL", "ADVS"};
		table.dropTable / name=table
						  caslib="casuser"
						  quiet=true;
	end;
quit;
