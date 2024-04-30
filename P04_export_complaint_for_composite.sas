OPTIONS PS=MAX FORMCHAR="|----|+|---+=|-/\<>*" MLOGIC MPRINT SYMBOLGEN noxwait noxsync;
LIBNAME IN02 "C:\Users\jiang.shao\Dropbox (UFL)\MCO Report Card - 2024\Program\5. Composite\Data\raw_data\complaint";

%LET JOB = P04;

*** ------ STAR prepare data ----------------------------------------------------------------------------------------------------------;
proc import datafile="C:\Users\jiang.shao\Dropbox (UFL)\MCO Report Card - 2024\Program\4. Complaint\Data\temp_data\ST_for_analysis.xlsx"
	dbms=XLSX
	out=STAR
	;
	sheet="ST24_complaints";
run;


*** ------ STAR + PLUS prepare data ----------------------------------------------------------------------------------------------------------;
proc import datafile="C:\Users\jiang.shao\Dropbox (UFL)\MCO Report Card - 2024\Program\4. Complaint\Data\temp_data\SP_for_analysis.xlsx"
	dbms=XLSX
	out=STARPLUS
	;
	sheet="SP24_complaints";
run;


*** ------ STAR Kids prepare data ----------------------------------------------------------------------------------------------------------;
proc import datafile="C:\Users\jiang.shao\Dropbox (UFL)\MCO Report Card - 2024\Program\4. Complaint\Data\temp_data\SK_for_analysis.xlsx"
	dbms=XLSX
	out=STARKids
	;
	sheet="SK24_complaints";
run;






/* Prepare for merged dataset */ 
data IN02.SC_comp; 
	set STAR;
	rename STper10kmm_rat = SCper10kmm_rat;
	keep plancode STper10kmm_rat;
run;

data IN02.SA_comp;
	set STAR;
	rename STper10kmm_rat = SAper10kmm_rat;
	keep plancode STper10kmm_rat;
run;

data IN02.SP_comp;
	set STARPLUS;
	keep plancode SPper10kmm_rat;
run;

data IN02.SK_comp;
	set STARKIDS;
	keep plancode SKper10kmm_rat;
run;