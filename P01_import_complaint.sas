OPTIONS PS=MAX FORMCHAR="|----|+|---+=|-/\<>*" MLOGIC MPRINT SYMBOLGEN noxwait noxsync;


%LET JOB = P01;

LIBNAME IN01 "..\DATA\raw_data\";
LIBNAME IN02 "..\DATA\temp_data";

title;

/* ---------------------------Import OMCAT------------------------------- */

proc import datafile="..\Data\raw_data\2024 MCO Report Cards Complaints Data.xlsx"
	dbms=XLSX
	out=omcat;
	SHEET = 'OMCAT';
	GETNAMES=YES;
run;



/* --------------------------Import HEART-------------------------------- */

proc import datafile="..\Data\raw_data\2024 MCO Report Cards Complaints Data.xlsx"
	dbms=XLSX
	out=heart;
	SHEET = 'MCCO HEART';
	GETNAMES=YES;
run;



/* --------------------------Import CADS-------------------------------- */

proc import datafile="..\Data\raw_data\2024 MCO Report Cards Complaints Data.xlsx"
	dbms=XLSX
	out=cads;
	SHEET = 'MCO Self-Reported';
	GETNAMES=YES;
run;


/* Change the plan code variable name, as they are all different among three datasets*/
/* Please note that this auto name conversion step will not work in SAS Enterprise 9.3, nor SAS 9.4 Base */

data omcat (rename=(VAR2=plancode)); set omcat; run;
data heart (rename=(Plan_Code=plancode)); set heart; run;
data cads(rename=(PLAN_CD=plancode)); set cads; run;



/* Process Plancode */
%macro process_plan_code(dataset);
    data work.&dataset.;
        set &dataset.;
        if length(plancode) < 2 then
            PHI_Plan_Code = cats('0', plancode);
        else
            PHI_Plan_Code = plancode;
    run;
%mend process_plan_code;

%process_plan_code(omcat);
%process_plan_code(heart);
%process_plan_code(cads);

proc import datafile="..\Data\raw_data\plancode.xlsx"
    dbms=XLSX
    out=plancode
    ;
run;

proc sort data = plancode; by plancode; run;


/* Attach original Complaint data with the correct and official Program/MCO/SA name */
%macro add_phi_info(prog);
    proc sort data = &prog.;
        by PHI_Plan_Code;
    run;

    data &prog._new;
        merge &prog.(in=a) 
        plancode (keep=Program MCONAME PLANCODE SERVICEAREA STATUS rename=(PLANCODE=PHI_Plan_Code STATUS = plancode_status));
        by PHI_Plan_Code;
    if a;
    run;

%mend add_phi_info;

%add_phi_info(omcat);
%add_phi_info(heart);
%add_phi_info(cads);


/* label each dataset with corresponding criteria: is_excluded, is_covered_prog, is_member) */

/* exclusion criteria: Only confirmed complaints, substantiated complaints, 
and confirmed initial contact complaints (ICCs) should be used.
OMCAT will also exclude: non-covered service, not eligible at the time of service, 
MCO position upheld, unsubstantiated, no disposition */
data &job._omcat_for_sum_count; 
    set omcat_new; 
	
   	is_excluded = .;
    if Resolution ne 'Substantiated' or
       (Disposition = 'Non-covered Service' or 
        Disposition = 'Not Eligible at Time of Service' or 
        Disposition = 'MCO Position Upheld') then
        is_excluded = 1;
    else
        is_excluded = 0;
	
	is_covered_prog =.;
    if Program in ('STAR', 'STAR+PLUS', 'STAR Kids') then
        is_covered_prog = 1;
    else
        is_covered_prog = 0;
	
	is_member =.;
    if Relationship_To_Client = 'Member' then
        is_member = 1;
    else
        is_member = 0;

    is_plancode_valid = .;
    if plancode_status = 'A' then
        is_plancode_valid = 1;
    else
        is_plancode_valid = 0;


	data_source = 'omcat';
run;


/* exclusion criteria: Only confirmed complaints, substantiated complaints, 
and confirmed initial contact complaints (ICCs) should be used.
HEART will also exclude: Not confirmed and N/A referred out. */
data &job._heart_for_sum_count; 
    set heart_new; 
	
   	is_excluded = .;
    if (Outcome = 'N/A Referred Out' or 
        Outcome = 'Not Confirmed' ) then
        is_excluded = 1;
    else
        is_excluded = 0;
	
	is_covered_prog =.;
    if Program in ('STAR', 'STAR+PLUS', 'STAR Kids') then
        is_covered_prog = 1;
    else
        is_covered_prog = 0;
	
	is_member =.;
    if Request_Type = 'Client' then
        is_member = 1;
    else
        is_member = 0;

    is_plancode_valid = .;
    if plancode_status = 'A' then
        is_plancode_valid = 1;
    else
        is_plancode_valid = 0;

		data_source = 'heart';
run;


/* exclusion criteria: Only confirmed complaints, substantiated complaints, 
and confirmed initial contact complaints (ICCs) should be used.
CADS will also exclude: non-covered service (CD014); member not eligible for service (CD015) */
data &job._cads_for_sum_count; 
    set cads_new; 
	
   	is_excluded = .;
    if COMPLAINT_OUTCOME ne 'CON' or
       (COMPLAINT_REF_DISP_CD = 'CD014' or 
        COMPLAINT_REF_DISP_CD = 'CD015') then
        is_excluded = 1;
    else
        is_excluded = 0;
	
	is_covered_prog =.;
    if Program in ('STAR', 'STAR+PLUS', 'STAR Kids') then
        is_covered_prog = 1;
    else
        is_covered_prog = 0;
	
	is_member =.;
    if TYPE_COMPLAINT = 'M' then
        is_member = 1;
    else
        is_member = 0;

    is_plancode_valid = .;
    if plancode_status = 'A' then
        is_plancode_valid = 1;
    else
        is_plancode_valid = 0;

	data_source = 'cads';
run;

data combined_dataset_for_count;
    set &job._omcat_for_sum_count (keep=data_source PHI_Plan_Code Program MCONAME SERVICEAREA is_excluded is_covered_prog is_member is_plancode_valid plancode_status)
        &job._heart_for_sum_count (keep=data_source PHI_Plan_Code Program MCONAME SERVICEAREA is_excluded is_covered_prog is_member is_plancode_valid plancode_status)
        &job._cads_for_sum_count (keep=data_source PHI_Plan_Code Program MCONAME SERVICEAREA is_excluded is_covered_prog is_member is_plancode_valid plancode_status);
run;


proc sql;
    create table summary_table as
    select 
        data_source,
        count(*) as total_complaints,
        sum(is_covered_prog = 0) as prog_not_covered,
        sum(is_excluded = 1) as complaints_excluded,
        sum(is_plancode_valid = 0) as plan_code_invalid,

        sum(is_excluded = 1 or is_covered_prog = 0 or is_plancode_valid = 0) as total_exclude,

        sum(is_excluded = 0 and is_covered_prog = 1 and is_plancode_valid = 1) as total_analyzed,
        sum(is_member = 1 and is_excluded = 0 and is_covered_prog = 1 and is_plancode_valid = 1) as complaints_member,
        sum(is_member = 0 and is_excluded = 0 and is_covered_prog = 1 and is_plancode_valid = 1) as complaints_provider
    from combined_dataset_for_count
    group by data_source

    union all

    select 
        'Total' as data_source,
        count(*) as total_complaints,
        sum(is_covered_prog = 0) as prog_not_covered,
        sum(is_excluded = 1) as complaints_excluded,
        sum(is_plancode_valid = 0) as plan_code_invalid,

        sum(is_excluded = 1 or is_covered_prog = 0 or is_plancode_valid = 0) as total_exclude,

        sum(is_excluded = 0 and is_covered_prog = 1 and is_plancode_valid = 1) as total_analyzed,
        sum(is_member = 1 and is_excluded = 0 and is_covered_prog = 1 and is_plancode_valid = 1) as complaints_member,
        sum(is_member = 0 and is_excluded = 0 and is_covered_prog = 1 and is_plancode_valid = 1) as complaints_provider
    from combined_dataset_for_count;
quit;

* proc transpose data=summary_table out=summary_table_trans;
*     var total_complaints prog_not_covered complaints_excluded 
*         plan_code_invalid total_exclude total_analyzed 
*         complaints_member complaints_provider;
*     id data_source;
* run;

* proc freq data = combined_dataset_for_count;
*     tables is_covered_prog;
*     tables is_excluded;
*     tables is_plancode_valid;
*     tables is_excluded * is_plancode_valid / nocol norow nopct;
*     tables is_excluded * is_covered_prog / nocol norow nopct;
*     tables is_plancode_valid * is_covered_prog / nocol norow nopct;
* run;

/* Output the dataset for P02 to use */
* data IN02.P01_merged_data;
*     set combined_dataset_for_count;
* run;

* proc export data=summary_table_trans
*         outfile="..\Data\temp_data\total_summary_table1.xlsx"
*         dbms=xlsx
*         replace;
* run;





/* Check dataset */
* proc freq data = &job._omcat_for_sum_count;
*     tables  Resolution * is_excluded / nocol norow nopct;
*     tables Disposition* is_excluded / nocol norow nopct;
*     tables program * is_covered_prog / nocol norow nopct;
*     tables Program_Type * is_covered_prog / nocol norow nopct;
*     tables Program_Type * program / nocol norow nopct;
*     tables Relationship_To_Client * is_member / nocol norow nopct;
*     tables MCOname * is_plancode_valid / nocol norow nopct;
* run;


* proc freq data = &job._omcat_for_sum_count;
*     where is_excluded = 1;
*     tables Disposition * Resolution / nocol norow nopct;
* run;

* proc freq data = &job._heart_for_sum_count;
*     tables outcome * is_excluded / nocol norow nopct;
*     tables program * is_covered_prog / nocol norow nopct;
*     tables Program_Type * is_covered_prog / nocol norow nopct;
*     tables Program_Type * program / nocol norow nopct;
*     tables Request_Type * is_member / nocol norow nopct;
*     tables MCOname * is_plancode_valid / nocol norow nopct;
* run;

* proc contents data = &job._cads_for_sum_count;
*     run;

* proc freq data = &job._cads_for_sum_count;
*     tables complaint_outcome * is_excluded / nocol norow nopct;
*     tables COMPLAINT_REF_DISP_CD * is_excluded / nocol norow nopct;
*     tables program * program_cd / nocol norow nopct;
*     tables TYPE_COMPLAINT * is_member / nocol norow nopct;
*     tables plancode * is_plancode_valid / nocol norow nopct;
* run;

proc freq data = &job._omcat_for_sum_count;
    where program_type = 'STAR Plus Dual Demo';
    tables PHI_Plan_Code;
    tables MCOname;
run;