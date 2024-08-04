/*
*****************************************************************************************************************
Project		 : _NA_
SAS file name: epoch.sas
File location: _NA_
*****************************************************************************************************************
Purpose: Using SAS Hash Table Operations To Obtain EPOCH.
Author: Mazi Ntintelo
Creation Date: 2024-08-04
*****************************************************************************************************************
CHANGES:
Date: Date of first modification of the code
Modifyer name: Name of the programmer who modified the code
Description: Shortly describe the changes made to the program
*****************************************************************************************************************
*/

data se;
	infile datalines dlm=',' dsd;
	length sestdtc seendtc $16 epoch $20;
	input usubjid $ seseq etcd $ sestdtc $ seendtc $ taeord epoch $;
datalines;
789,1,SCREEN,2006-06-01,2006-06-03T10:32,1,SCREENING
789,2,IV,2006-06-03T10:32,2006-06-10T09:47,2,TREATMENT 1
789,3,ORAL,2006-06-10T09:47,2006-06-17,3,TREATMENT 2
789,4,FOLLOWUP,2006-06-17,2006-06-17,4,FOLLOW-UP
790,1,SCREEN,2006-06-01,2006-06-03T10:14,1,SCREENING
790,2,IV,2006-06-03T10:14,2006-06-10T10:32,,TREATMENT 1
790,3,ORAL,2006-06-10T10:32,2006-06-17,,TREATMENT 2
790,4,FOLLOWUP,2006-06-17,2006-06-17,4,FOLLOW-UP
791,1,SCREEN,2006-06-01,2006-06-03T10:17,1,SCREENING
791,2,IV,2006-06-03T10:17,2006-06-07,2,TREATMENT 1
;

data ae;
	infile datalines dlm=',' dsd;
	length aeterm $200 aestdtc aeendtc $16;
	input usubjid $ aeseq aeterm $ aestdtc $ aeendtc $;
datalines;
789,1,HEADACHE,2006-06-02,2006-06-02T15:45
789,2,NAUSEA,2006-06-03T10:50,2006-06-10T11:47
789,3,VOMMITING,2006-06-11T08:13,2006-06-12
789,4,HYPOGLYCEMIA,2006-06-15T06:25,2006-06-17
790,1,SUN BURN,2006-06-04,2006-06-15T08:00
790,2,BROKEN TOE,2006-06-06T00:45,
790,3,FATIGUE,2006-06-07T06:15,2006-06-07T16:35
790,4,HYPERTENSION,2006-06-10T09:00,2006-06-10T10:40
791,1,HEADACHE,2006-06-03T09:00,2006-06-03T12:15
791,2,HEADACHE,2006-06-04T16:24,2006-06-04T20:20
;

data ae_epoch;
	length evt 8;
	if 0 then set se(keep=usubjid seendtc sestdtc epoch);
	declare hash _h_(dataset: "se", multidata: "Y");
	rc=_h_.definekey("usubjid");
	rc=_h_.definedata("sestdtc", "seendtc", "epoch");
	rc=_h_.definedone();
	
	declare hash cache();
	rc=cache.definekey('usubjid', 'evt');
	rc=cache.definedata('epoch');
	rc=cache.definedone();
	do until(eof);
		set ae end=eof;
		len=length(aestdtc);
		rc=_h_.find();
		do while(^rc);
			if len=16 and length(sestdtc)=16 and length(seendtc)=16 then do;
				start=input(sestdtc, e8601dt.);
				end=input(seendtc, e8601dt.);
				evt=input(aestdtc, e8601dt.);
			end;
			else do;
				start=input(sestdtc, e8601da.);
				end=input(seendtc, e8601da.);
				evt=input(aestdtc, e8601da.);
			end;
			if .<start<=evt<=end then leave;
			call missing(epoch);
			rc=_h_.find_next();
		end;
		output;
		call missing(epoch);
	end;
run;

