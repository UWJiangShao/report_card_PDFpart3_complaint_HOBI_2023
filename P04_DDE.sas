OPTIONS PS=MAX FORMCHAR="|----|+|---+=|-/\<>*" MLOGIC MPRINT SYMBOLGEN noxwait noxsync;

* Formatting results;
* Using DDE technique; 

%LET JOB = P04;

*** ------ STAR prepare data ----------------------------------------------------------------------------------------------------------;
proc import datafile="C:\Users\jiang.shao\Dropbox (UFL)\MCO Report Card - 2024\Program\4. Complaint\Data\temp_data\ST_for_analysis.xlsx"
	dbms=XLSX
	out=STAR
	;
	sheet="ST24_complaints";
run;

proc sort data = STAR;
	by SERVICEAREA MCONAME;
run;


*** ------ STAR + PLUS prepare data ----------------------------------------------------------------------------------------------------------;
proc import datafile="C:\Users\jiang.shao\Dropbox (UFL)\MCO Report Card - 2024\Program\4. Complaint\Data\temp_data\SP_for_analysis.xlsx"
	dbms=XLSX
	out=STARPLUS
	;
	sheet="SP24_complaints";
run;

proc sort data = STARPLUS;
	by SERVICEAREA MCONAME;
run;


*** ------ STAR Kids prepare data ----------------------------------------------------------------------------------------------------------;
proc import datafile="C:\Users\jiang.shao\Dropbox (UFL)\MCO Report Card - 2024\Program\4. Complaint\Data\temp_data\SK_for_analysis.xlsx"
	dbms=XLSX
	out=STARKids
	;
	sheet="SK24_complaints";
run;

proc sort data = STARKids;
	by SERVICEAREA MCONAME;
run;

** ---- Create frequency table for the rating guide ---------------------------------------------;

proc freq data=STAR nlevels;
	table STper10kmm_center * STper10kmm_rat/list out=RG_ST;
run;

proc freq data=STARPLUS nlevels;
	table SPper10kmm_center * SPper10kmm_rat/list out=RG_SP;
run;

proc freq data=STARKids nlevels;
	table SKper10kmm_center * SKper10kmm_rat/list out=RG_SK;
run;


** ---- Exporting using DDE --------------------------------------------------------------------;
filename ddeopen DDE 'Excel|system';

* template file;
x '"C:\Users\jiang.shao\Dropbox (UFL)\MCO Report Card - 2024\Program\4. Complaint\Data\raw_data\MCO Report Cards - Complaints Ratings - template 2023.xlsx"';


filename SC dde "Excel|STAR Child-Complaints!r3c1:r46c13" notab;
data _null_;
	set STAR;
	file SC;
	put MCONAME '09'x SERVICEAREA '09'x plancode '09'x
		mm 		'09'x Count 	  '09'x ae_ratio '09'x
		STper10kmm_center '09'x STper10kmm '09'x STper10kmm_rat '09'x
	;
run;


filename SC dde "Excel|STAR Adult-Complaints!r3c1:r46c13" notab;
data _null_;
	set STAR;
	file SC;
	put MCONAME '09'x SERVICEAREA '09'x plancode '09'x
		mm 		'09'x Count 	  '09'x ae_ratio '09'x
		STper10kmm_center '09'x STper10kmm '09'x STper10kmm_rat '09'x
	;
run;


filename SP dde "Excel|STAR+Plus-Complaints!r3c1:r31c13" notab;
data _null_;
	set STARPLUS;
	file SP;
	put MCONAME '09'x SERVICEAREA '09'x plancode '09'x
		mm 		'09'x Count 	  '09'x ae_ratio '09'x
		SPper10kmm_center '09'x SPper10kmm '09'x SPper10kmm_rat '09'x
	;
run;

filename SK dde "Excel|STAR Kids-Complaints!r3c1:r30c13" notab;
data _null_;
	set STARKids;
	file SK;
	put MCONAME '09'x SERVICEAREA '09'x plancode '09'x
		mm 		'09'x Count 	  '09'x ae_ratio '09'x
		SKper10kmm_center '09'x SKper10kmm '09'x SKper10kmm_rat '09'x
	;
run;

** ---- fill the rating guide -----------------------------------------------------------------------;

filename RG_ST dde "Excel|STAR Child-Complaints!r3c11:r7c13" notab;
data _null_;
	set RG_ST (where=(STper10kmm_rat ne .));
	file RG_ST;
	put STper10kmm_center '09'x STper10kmm_rat '09'x count;
run;

filename RG_ST dde "Excel|STAR Adult-Complaints!r3c11:r7c13" notab;
data _null_;
	set RG_ST (where=(STper10kmm_rat ne .));
	file RG_ST;
	put STper10kmm_center '09'x STper10kmm_rat '09'x count;
run;

filename RG_SP dde "Excel|STAR+PLUS-Complaints!r3c11:r7c13" notab;
data _null_;
	set RG_SP (where=(SPper10kmm_rat ne .));
	file RG_SP;
	put SPper10kmm_center '09'x SPper10kmm_rat '09'x count;
run;

filename RG_SK dde "Excel|STAR Kids-Complaints!r3c11:r7c13" notab;
data _null_;
	set RG_SK (where=(SKper10kmm_rat ne .));
	file RG_SK;
	put SKper10kmm_center '09'x SKper10kmm_rat '09'x count;
run;

** ---- file the frequency for No rating --------------------------------------------------;
* proc format;
* 	value rating_f
* 		. = "No rating"
* 		;
* run;

* filename M_ST dde "Excel|STAR Child-Complaints!r8c12:r8c13" notab;
* data _null_;
* 	set RG_ST(where=(STper10kmm_rat = .));
* 	file M_ST;
* 	put STper10kmm_rat '09'x count;
* 	format STper10kmm_rat rating_f.;
* run;

* filename M_ST dde "Excel|STAR Adult-Complaints!r8c12:r8c13" notab;
* data _null_;
* 	set RG_ST(where=(STper10kmm_rat = .));
* 	file M_ST;
* 	put STper10kmm_rat '09'x count;
* 	format STper10kmm_rat rating_f.;
* run;

* filename M_SP dde "Excel|STAR+PLUS-Complaints!r8c12:r8c13" notab;
* data _null_;
* 	set RG_SP(where=(SPper10kmm_rat = .));
* 	file M_SP;
* 	put SPper10kmm_rat '09'x count;
* 	format SPper10kmm_rat rating_f.;
* run;

* filename M_SK dde "Excel|STAR Kids-Complaints!r8c12:r8c13" notab;
* data _null_;
* 	set RG_SK(where=(SKper10kmm_rat = .));
* 	file M_SK;
* 	put SKper10kmm_rat '09'x count;
* 	format SKper10kmm_rat rating_f.;
* run;



data _null_;
	file ddeopen;
	put '[error(false)]';
	put '[save.as("C:\Users\jiang.shao\Dropbox (UFL)\MCO Report Card - 2024\Program\4. Complaint\Output\MCO Report Cards - Complaints Rating Final Nov 21.xlsx")]';
	put '[file.close(false)]';
run;
