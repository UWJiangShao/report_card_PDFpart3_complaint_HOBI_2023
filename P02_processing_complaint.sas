OPTIONS PS=MAX FORMCHAR="|----|+|---+=|-/\<>*" MLOGIC MPRINT SYMBOLGEN noxwait noxsync;


%LET JOB = P02;

LIBNAME IN01 "..\DATA\raw_data\";
LIBNAME IN02 "..\Data\temp_data";


/* -------------Select targeted group within four covered program, with valid plancode, and not be excluded --------------*/

data &job._merge_confirmed_covered_prog;
	set IN02.p01_merged_data;
	where is_covered_prog = 1 
	AND is_plancode_valid = 1
	AND is_excluded = 0
	;
run;


/* Check Freq for targeted dataset */
proc freq data=&job._merge_confirmed_covered_prog;
	tables program * is_covered_prog / nocol nopercent norow;
	tables is_plancode_valid;
	tables MCOname;
	tables servicearea * Program / nocol nopercent norow;
	tables PHI_Plan_Code * Program / nocol nopercent norow;
run;


/* Macro to aggregate complaint count by Plancode, then seperate them into three different program datasets */

%macro create_program_table1(program_name, output_table);
    proc sql;
        create table &output_table as
        select a.PHI_Plan_Code
            ,a.MCONAME
            ,a.servicearea
            ,count(*) as Count
        from &job._merge_confirmed_covered_prog as a
        where a.Program = "&program_name."
        group by a.PHI_Plan_Code, a.MCONAME, a.servicearea
        order by a.servicearea, a.MCONAME;
    quit;

	proc sort data=&output_table; by SERVICEAREA MCONAME; run;

%mend create_program_table1;

%create_program_table1(STAR, ST);
%create_program_table1(STAR+PLUS, SP);
%create_program_table1(STAR Kids, SK);


/* Import the member month data, this would be used as the denominator */
data member_month;
	set IN01.plancod_mm_2022_dual;
	where prog in ('STAR', 'STAR+PLUS', 'STAR Kids');
run;


/* merge member month into corresponding plancode */

/* Count = complaint count for this plancode (numerator) */
/* mm = member month */
/* count_pct = complaint count percentage respect to the whole program */
/* mm_pct = member month percentage respect to the whole program */
/* AE Ratio = Actual/Expected (A/E) ratio, a measure of goodness of fit */
/* XXper10kmm = the "score" we use to measure the complaint for each plancode */

%macro merge_and_calculate(input_table, output_table, per10kmm_field);
    proc sql;
        create table &output_table as
        select a.PHI_Plan_Code
            ,a.MCONAME
            ,a.servicearea
            ,a.Count
            ,b.mm
            ,(a.Count / sum(a.Count))  as count_pct
            ,(b.mm / sum(b.mm))  as mm_pct
            ,calculated count_pct / calculated mm_pct as ae_ratio
            ,a.Count / b.mm * 10000 as &per10kmm_field.
        from &input_table as a
        left join member_month as b on a.PHI_Plan_Code = b.PLAN_CD
        order by a.servicearea, a.MCONAME;
    quit;

%mend merge_and_calculate;

%merge_and_calculate(ST, ST_new, STper10kmm);
%merge_and_calculate(SP, SP_new, SPper10kmm);
%merge_and_calculate(SK, SK_new, SKper10kmm);


/* Export each program's dataset for next step */

%macro export_to_excel(dataset, output_filename);
    proc export data=&dataset
        outfile="..\Data\temp_data\&output_filename..xlsx"
        dbms=xlsx
        replace;
    run;
%mend export_to_excel;

%export_to_excel(ST_new, ST_for_analysis);
%export_to_excel(SP_new, SP_for_analysis);
%export_to_excel(SK_new, SK_for_analysis);









