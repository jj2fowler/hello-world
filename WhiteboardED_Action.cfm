<!--- 

--->

<cfparam name="URL.clearCache" default="false">

<!--- Show only COVID patients --->
<cfparam name="URL.covid" default=false>
<!--- Show only ARC Clinic patients --->
<cfparam name="URL.arconly" default=false>

<!--- If we aren't just looking for COVID or ARC patients then default to the Huddleboard view --->
<cfif URL.covid or URL.arconly>
  <cfparam name="URL.huddleboard" default=false>
<cfelse>	
  <cfparam name="URL.huddleboard" default=true>
</cfif>

<!--- Default table sort order --->
<cfparam name="URL.orderCol" default="1">
<cfparam name="URL.orderDir" default="asc">

<cfset urList = "">
<cfset episodeList = "">
<cfset miList = "">
<cfset isbarEpisodeNumbers=ArrayNew(1)>

<!--- Flag patients as a 24hr risk after this many minutes --->
<cfset wait24hrWarning = 1200>

<cfset totalTriage = 0>
<cfset totalWaiting = 0>
<cfset totalWaitingAmb = 0>
<cfset totalWaitingFT = 0>
<cfset totalED = 0>
<cfset totalEDUnassigned = 0>
<cfset totalSOU = 0>

<cftry>                
<!--- Get patient data --->
<cfquery name="GetEDData" datasource="#Session.HospODBC#" <!---cachedwithin="#createTimeSpan(0,0,0,30)#"--->>   
   select 0.5 as Rank,
    'Triage' as Loc,
    curr_locn as CurrLocn,
    trim(left(shift(a.c_urnumber, -1),6)) as UrNumber,
    a.surname as Surname,
    a.given_name_1 as GivenName,
    p.surname + ', ' + p.given_name_1 + ' ' + p.given_name_2 as Name,
    a.sex as Sex,
    a.age as Age,
    a.urgency as Urgency,
    a.pres_problem as PresProb,
    a.ae_refno as RefNo,
	a.ae_episode as EpisodeNo,
	'C' as EpisodeType,
    a.patient_id as PatientID,
    a.arr_date as ArDate,
	uppercase(lk.amb_code) as AmbCode,
	0 as Position,
	int4(interval('mins', date('now')- arr_date)) as WaitMins,
    '' as InsFund,
	trim(d.initials) as CurrDoc,
	d.title + ' ' + d.initials + ' ' + d.name as CurrDocName,
	a.curr_doct as CurrDocCode,
	0 as IpEpisode,
	a.ae_episode as AeEpisode,
    a.adm_type as AdmType,
    p.address_1 as Address1
  from ae_current a
    left outer join pat_name p on p.patient_id = a.patient_id and p.name_no = 0
    left outer join lk_mtd_arrl lk on lk.code = a.meth_arr
	left outer join anedoctor d on d.dr_code = a.curr_doct
  where a.hosp_code = #Session.HospCode#
    and ae_stage = ''

    <cfif URL.covid>
      <cfif URL.arconly>
        and curr_locn in ('ARC','ELEC','ARCS','RRNA','RRB','RRTT','RRN')
      <cfelse>		
	    and curr_locn in ('STAF','COMM','ARC','COMR','COMP','COMS','COMB','COMT','ARC2''ELEC','ARCS','RRR','RRT','RRN','RRA','RRC','RRK','RRS','RRH','RRNA','RRB','RRW')
      </cfif>
    <cfelse> 
      and curr_locn not in ('STAF','COMM','ARC','COMR','COMP','COMS','COMB','COMT','ARC2','ELEC','ARCS','RRR','RRT','RRN','RRA','RRC','RRK','RRS','RRH','RRNA','RRB','RRW')
    </cfif> 

  union all

  select 1 as Rank,
    'Wait' as Loc,
    curr_locn as CurrLocn,    
    trim(left(shift(a.c_urnumber, -1),6)) as UrNumber,
    a.surname as Surname,
    a.given_name_1 as GivenName,
    p.surname + ', ' + p.given_name_1 + ' ' + p.given_name_2 as Name,
    a.sex as Sex,
    a.age as Age,
    a.urgency as Urgency,
    a.pres_problem as PresProb,
    a.ae_refno as RefNo,
	a.ae_episode as EpisodeNo,
	'C' as EpisodeType,
    a.patient_id as PatientID,
    a.arr_date as ArDate,
	uppercase(lk.amb_code) as AmbCode,
	0 as Position,
	int4(interval('mins', date('now')- arr_date)) as WaitMins,
    ei.ins_fund as InsFund,
	trim(d.initials) as CurrDoc,
	d.title + ' ' + d.initials + ' ' + d.name as CurrDocName,
	a.curr_doct as CurrDocCode,
	0 as IpEpisode,	
	a.ae_episode as AeEpisode,
    a.adm_type as AdmType,
    p.address_1 as Address1
  from ae_current a
    inner join pat_name p on p.patient_id = a.patient_id and p.name_no = 0
	inner join lk_mtd_arrl lk on lk.code = a.meth_arr
	left outer join anedoctor d on d.dr_code = a.curr_doct
    left outer join ep_insurance ei on ei.episode_no = a.ae_episode
  where a.hosp_code = #Session.HospCode#

    <cfif URL.huddleboard>
	  and curr_doct = ''
      and curr_locn not in ('STAF','COMM','ARC','COMR','COMP','COMS','COMB','COMT','ARC2','ELEC','RRR','RRT','RRN','RRA','RRC','RRK','RRS','RRH','RRNA','RRB','RRW')
    <cfelseif URL.covid>
      <cfif URL.arconly>
        and curr_locn in ('ARC','ELEC','ARCS','RRNA','RRB','RRTT','RRN')
      <cfelse>	
	    and curr_locn in ('STAF','COMM','COMR','COMP','COMS','COMB','COMT','ARC2','ELEC','ARCS','RRR','RRT','RRN','RRA','RRC','RRK','RRS','RRH','RRNA','RRB','RRW')
      </cfif>
    <cfelse>
	  and curr_locn = '' or curr_locn = 'RAT' or curr_locn = 'WR' or curr_locn = 'XRW'
      and curr_locn not in ('STAF','COMM','ARC','COMR','COMP','COMS','COMB','COMT','ARC2','ELEC','ARCS','RRR','RRT','RRN','RRA','RRC','RRK','RRS','RRH','RRNA','RRB','RRW')
    </cfif>

    <cfif (URL.covid)>
      and ae_stage != 'SN'
	  <cfif URL.arconly>
	    and ae_stage != 'IC'
	  </cfif>
    <cfelse>
      and ae_stage != ''
    </cfif>

  union all

  select 2 as Rank,
    'A&E' as Loc,
    curr_locn as CurrLocn,  
    trim(left(shift(a.c_urnumber, -1),6)) as UrNumber,
    a.surname as Surname,
    a.given_name_1 as GivenName,
    p.surname + ', ' + p.given_name_1 + ' ' + p.given_name_2 as Name,
    a.sex as Sex,
    a.age as Age,
    a.urgency as Urgency,
    a.pres_problem as PresProb,
    a.ae_refno as RefNo,
    a.ae_episode as EpisodeNo,
    'C' as EpisodeType,
    a.patient_id as PatientID,
    a.arr_date as ArDate,    
	uppercase(lk.amb_code) as AmbCode,
	
	<!--- Move patients with RAT doctor code to the top of the Rank 2 list --->
	CASE WHEN trim(d.initials) = 'RAT'
	  THEN 0
	  ELSE ll.whiteboard_order
	END as Position,
	
	int4(interval('mins', date('now')- arr_date)) as WaitMins,
    ei.ins_fund as InsFund,
	trim(d.initials) as CurrDoc,
	d.title + ' ' + d.initials + ' ' + d.name as CurrDocName,
	a.curr_doct as CurrDocCode,
	0 as IpEpisode,
	a.ae_episode as AeEpisode,
    a.adm_type as AdmType,
    p.address_1 as Address1
  from ae_current a
    inner join pat_name p on p.patient_id = a.patient_id and p.name_no = 0
	inner join lk_mtd_arrl lk on lk.code = a.meth_arr
	inner join lk_aelocn ll on ll.code = a.curr_locn
	left outer join anedoctor d on d.dr_code = a.curr_doct
    left outer join ep_insurance ei on ei.episode_no = a.ae_episode
  where a.hosp_code = #Session.HospCode#

    <cfif (URL.huddleboard)>
	  and curr_doct != ''
      and curr_locn not in ('STAF','COMM','ARC','COMR','COMP','COMS','COMB','COMT','ARC2','ELEC','ARCS','RRR','RRT','RRN','RRA','RRC','RRK','RRS','RRH','RRNA','RRB','RRW')
    <cfelseif (URL.covid)>
      <cfif URL.arconly>
  	    and curr_locn in ('ARC','ELEC','ARCS','RRNA','RRB','RRTT','RRN')
      <cfelse>	
	    and curr_locn in ('STAF','COMM','ARC','COMR','COMP','COMS','COMB','COMT','ARC2','ELEC','ARCS''RRR','RRT','RRN','RRA','RRC','RRK','RRS','RRH','RRNA','RRB','RRW')
      </cfif>
    <cfelse>
	  and curr_locn != '' and curr_locn != 'RAT' and curr_locn != 'WR' and curr_locn != 'XRW'
      and curr_locn not in ('STAF','COMM','ARC','COMR','COMP','COMS','COMB','COMT','ARC2','ELEC','ARCS','RRR','RRT','RRN','RRA','RRC','RRK','RRS','RRH','RRNA','RRB','RRW')
    </cfif>
    
    and ae_stage != ''

  <cfif !URL.covid>
    union all

    select 3 as Rank,
      l.ward_code as Loc,
      l.bed_no as CurrLocn, 
      trim(left(shift(p.c_urnumber, -1),6)) as UrNumber,
      p.surname as Surname,
      p.given_name_1 + ' ' + p.given_name_2 as GivenName,
      p.surname + ', ' + p.given_name_1 + ' ' + p.given_name_2 as Name,
      p.sex as Sex,
      vchar(int2(interval('yrs', l.adm_date -  p.birth_date))) as Age,
      '' as Urgency,
      l.prov_diag as PresProb,
      ifnull(ah.ae_refno,0) as RefNo,
      e.episode_no as EpisodeNo,
      'I' as EpisodeType,
      p.patient_id as PatientId,
      e.adm_date as ArDate,    
	  '' as AmbCode,
	
	  <cfif (URL.huddleboard)>
	    99 + int2(l.extension_no) as Position,
	  <cfelse>
  	    1 + int2(l.extension_no) as Position,
	  </cfif>
	
	  int4(interval('mins', date('now')- e.adm_date)) as WaitMins,
	  ei.ins_fund as InsFund,
  	  trim(ah.curr_doct) as CurrDoc,
      '' as CurrDocName,
	  '' as CurrDocCode,
	  l.episode_no as IpEpisode,
	  ah.ae_episode as AeEpisode,
      ah.adm_type as AdmType,
      p.address_1 as Address1
    from episode e
      inner join location l on l.episode_no = e.episode_no and l.ward_code in ('ED','EMU','SOU','MAPU','HHRV') and l.episode_no > 0
      inner join pat_name p on p.patient_id = l.cur_pat and p.name_no = 0
	  left outer join ae_history ah on ah.ip_episode = e.episode_no and ah.patient_id = e.patient_id
      left outer join ep_insurance ei on ei.episode_no = e.episode_no
    where e.hosp_code = #Session.HospCode#
      and e.ep_status != 'X'
  </cfif>

  <cfif URL.huddleboard>
    order by Rank, Position, Urgency, WaitMins desc    
  <cfelse>
	order by Rank, ArDate
  </cfif>
</cfquery>
<cfcatch type="database">
  <cfif cfcatch.cause.errorcode eq 0 >
    <!--- Data source does not exist --->
    <cfif cfcatch.cause.errorcode eq 0 >
      <h4>Error: Vital database unavailable. Please try again in a few minutes.</h4>	
      Timestamp: <cfoutput>#DateFormat(Now(), "dd-mmm-yyyy")# #TimeFormat(Now(), "HH:mm:ss")#</cfoutput>
      <cfabort />
    </cfif>
  </cfif>
</cfcatch>
</cftry>

<cfset queryRefNoList = ValueList(GetEDData.RefNo)>
<cfset queryPatientIDList = ValueList(GetEDData.PatientId)>
<cfset queryEpisodeNumberList = ValueList(GetEDData.EpisodeNo)>

<cfset edPatientTotal = 0>

<cfloop query="GetEDData">
  <cfif GetEDData.Rank LT 3>
  	<cfset edPatientTotal++>
  </cfif>	
</cfloop>

<cfif URL.covid or URL.arconly>
  <cfset reportTitle = "COVID Screening (#edPatientTotal#)">
<cfelse>   	
  <cfset reportTitle = "ED Patients (#edPatientTotal#)">
</cfif>

<!--- Get any empty inpatient beds --->
<cfquery name="GetEmptyBeds" datasource="#Session.HospODBC#" cachedwithin="#createTimeSpan(0,0,1,0)#">
  select 
    w.ward_code as WardCode,
    rl.total_beds - count(*) as Empty
  from ward w, rl_ward_beds rl, location l
  where w.hosp_code = #Session.HospCode# and w.active_flag = 'Y'
	and w.ward_code = rl.ward_code
	and l.ward_code = w.ward_code
	and l.episode_no != ''
	and date('today') >= rl.effective_date
	and date('today') < rl.end_date
	and rl.total_beds > 0
    and w.ward_code not in ('DIA','DPU','GN','ONC','RCE','RCHO','RCN','HHPD','DL','WNH','PARK','EMU','WACH','TCPG','MDS','GRUT')
  group by w.ward_code, rl.total_beds
</cfquery>

<!--- Get any empty ED cubicles --->
<cfquery name="GetEmptyCubicles" datasource="#Session.HospODBC#" cachedwithin="#createTimeSpan(0,0,0,30)#">
  select 
    lk.code as Cubicle
  from lk_aelocn lk
  where lk.code not in (select curr_locn from ae_current)
    and lk.code not in (
      select ah.curr_locn
      from ae_history ah, location l
	  where ah.ip_episode = l.episode_no
		and ah.patient_id = l.cur_pat
		and l.hosp_code = #Session.HospCode#
		and l.ward_code in ('SOU','MAPU','ED','HHRV')
		and l.bed_no = ''
    )
    and active_flag = 'Y'
    and hosp_code = #Session.HospCode#
    and locn_type = 'C'
    and code not in ('SCS','EJEC','THC','THNA','THNU','TRI','MT1','MT2','MT3','FTW','THKY','RRR','RRN','RRS','RRH')
  order by whiteboard_order
</cfquery>

<cfset notesData = StructNew()>

<cfif queryRefNoList NEQ "">
  <!--- Get various notes code data. 
        For things like NIPM, bed booking, behaviour of concern. --->	
  <cfquery name="GetNotesData" datasource="#Session.HospODBC#">
    select 
      ae_refno as AeRefNo,
      Trim(notes_code) as NotesCode
    from ae_notes
    where notes_code in ('NIPM','E','MH','MHOA','BOC')
      and ae_refno in (#queryRefNoList#)
    group by ae_refno, notes_code  	
  </cfquery>

  <cfloop query="GetNotesData">
    <cfset notesData[GetNotesData.AeRefNo & "_" & GetNotesData.NotesCode] = {aerefno=#GetNotesData.AeRefNo#, notescode=#GetNotesData.NotesCode#}>	
  </cfloop>
</cfif>

<cfset referralData1 = StructNew()>

<cfif queryRefNoList NEQ "">
  <!--- Get referral data --->
  <cfquery name="GetRefData1" datasource="#Session.HospODBC#">
    select 
      n1.ae_refno as RefNo,
      trim(n1.notes_code) as thisCode, 
      n1.date_time as DateTime
    from ae_notes n1
    where n1.ae_refno in (#queryRefNoList#)
      and (n1.notes_code = 'PW' or n1.notes_code = 'TR' or n1.notes_code = 'RA')
      and date_time in(
        select max(date_time)	
        from ae_notes n2
        where n1.ae_refno = n2.ae_refno
          and n1.notes_code = n2.notes_code      
      )  
    order by n1.ae_refno, n1.date_time desc
  </cfquery>

  <cfloop query="GetRefData1">
    <cfset referralData1[GetRefData1.RefNo] = {refno=#GetRefData1.RefNo#, notescode=#GetRefData1.thisCode#, datetime=#GetRefData1.DateTime#}>	
  </cfloop>
</cfif>

<cfset referralData2 = StructNew()>

<cfif queryRefNoList NEQ "">
  <!--- Get referral data --->
  <cfquery name="GetRefData2" datasource="#Session.HospODBC#">
    select 
      n1.ae_refno as RefNo,
      trim(n1.notes_code) as thisCode, 
      n1.date_time as DateTime
    from ae_notes n1
    where n1.ae_refno in (#queryRefNoList#)
      and notes_code in ('RT','M','S','EXT','I','P','MCU','O','O&G','MHR','WT','WD','ONC','RES')
      and date_time in(
        select max(date_time)	
        from ae_notes n2
        where n1.ae_refno = n2.ae_refno     
          and notes_code in ('RT','M','S','EXT','I','P','MCU','O','O&G','MHR','WT','WD','ONC','RES')
      )  
    order by n1.ae_refno, n1.date_time desc
  </cfquery>

  <cfloop query="GetRefData2">
    <cfset referralData2[GetRefData2.RefNo] = {refno=#GetRefData2.RefNo#, notescode=#GetRefData2.thisCode#, datetime=#GetRefData2.DateTime#}>	
  </cfloop>
</cfif>

<cfset bedBookings = StructNew()>

<cfif queryPatientIDList NEQ "">
  <!--- Get bed booking data --->
  <cfquery name="GetBedBookingData" datasource="#Session.HospODBC#">
    select trim(ward_code) as WardCode,
	  trim(completed) as Completed,
	  bed_no as BedNo,
	  booking_date as BookingDate, 
	  booking_no as BookingNo,
	  patient_id as PatientId
    from bed_booking
    where patient_id in (#queryPatientIDList#)
      and completed not in ('Y', 'X')
	  and hosp_code = #Session.HospCode#
	  and entry_date > date('now') - '1 day'
  </cfquery>

  <cfloop query="GetBedBookingData">
    <cfset bedBookings[GetBedBookingData.PatientId] = {bookingno=#GetBedBookingData.BookingNo#, wardcode=#GetBedBookingData.WardCode#, completed=#GetBedBookingData.Completed#, bedno="#GetBedBookingData.BedNo#", bookingdate="#GetBedBookingData.BookingDate#"}>	
  </cfloop>
</cfif>

<cfset alertsFlags = StructNew()>

<cfif queryPatientIDList NEQ "">
  <!--- Get alerts and flags data --->
  <cfquery name="GetAlertsFlagsData" datasource="#Session.HospODBC#" cachedwithin="#createTimeSpan(0,0,1,0)#">
    select
      1 as Rank,
      patient_id as PatientId,
      'Alert' as Type, 
      lk.description as Description,
      lk.code as ThisCode
    from med_alerts ma, lk_alert lk
    where ma.patient_id in (#queryPatientIDList#)
      and ma.alert_code = lk.code
  
    union all
  
    select
      2 as Rank,
      patient_id as PatientId, 
      'Drug flag' as Type,
      lk.description as Description,
      ad.drug_code as ThisCode
    from adv_drugs ad, lk_drugs lk
    where ad.patient_id in (#queryPatientIDList#)
      and ad.drug_code = lk.code
  
    union all
  
    select
      2 as Rank,
      patient_id as PatientId,
      'Allergy flag' as Type, 
      lk.description as Description,
      pa.code as ThisCode
    from pat_aller pa, lk_allergies lk
    where pa.patient_id in (#queryPatientIDList#)
      and pa.code = lk.code
  
    order by PatientId, Rank, Description
  </cfquery>

  <cfloop query="GetAlertsFlagsData">
    <cfset alertsFlags[GetAlertsFlagsData.PatientId & "_" & GetAlertsFlagsData.ThisCode] = {patientid=#GetAlertsFlagsData.PatientId#, type=#GetAlertsFlagsData.Type#, description=#GetAlertsFlagsData.Description#}>	
  </cfloop>
</cfif>

<cfset situationData = StructNew()>

<cfif queryEpisodeNumberList NEQ "">
  <cftry>	
    <!--- Get ISBAR Situation data --->
    <cfquery name="GetSituationData" datasource="#db#">
      select
        d1.episode_no as EpisodeNo,
        d1.work_diag as EventText,
        d1.diag_type_1 as EventType1
      from ep_work_diag d1
      where d1.episode_no in (#queryEpisodeNumberList#)
        and d1.diag_no in(
          select max(diag_no)
          from ep_work_diag d2
          where d1.episode_no = d2.episode_no
            and status != 'X'
        )
    </cfquery>

    <cfloop query="GetSituationData">
      <cfset situationData[GetSituationData.EpisodeNo] = {episodeno=#GetSituationData.EpisodeNo#, eventtext=#GetSituationData.EventText#, eventtype1=#GetSituationData.EventType1#}>	
    </cfloop>
    
    <cfcatch type="any">
      <!--- Data source does not exist --->
      <cfif cfcatch.cause.errorcode eq 0 >
        <h4>Error: ISBAR database unavailable. Please try again in a few minutes.</h4>	
        Timestamp: <cfoutput>#DateFormat(Now(), "dd-mmm-yyyy")# #TimeFormat(Now(), "HH:mm:ss")#</cfoutput>
        <cfabort />
      </cfif>	
    </cfcatch>  
  </cftry>
</cfif>

<cfset admitDocData = StructNew()>

<cfif queryEpisodeNumberList NEQ "">
  <!--- Get admitting doctor data --->
  <cfquery name="GetAdmitDocData" datasource="#Session.HospODBC#">
    select 
      a.admit_doc as AdmitDocCode, 
      d.name as AdmitDoc,
      a.date_time as DateTime,
      a.episode_no as EpisodeNo
    from  ae_ip_doctor a, doctor d
    where a.episode_no in (#queryEpisodeNumberList#)
      and a.admit_doc = d.dr_code
      and date_time in (
        select max(date_time)
        from ae_ip_doctor a2
        where a.episode_no = a2.episode_no	
      )
  </cfquery>

  <cfloop query="GetAdmitDocData">
    <cfset admitDocData[GetAdmitDocData.EpisodeNo] = {episodeno=#GetAdmitDocData.EpisodeNo#, doccode=#GetAdmitDocData.AdmitDocCode#, docname=#GetAdmitDocData.AdmitDoc#, datetime=#GetAdmitDocData.DateTime#}>	
  </cfloop>
</cfif>

<!--- Get all the pending inbound transfers --->
<cfquery name="GetExpectedPatients" datasource="#db#">
  select * 
  from patient_transfers
  where cancelled != 'y'
    and completed_transfer_date = ''
    and io = 'E'
  order by io, pending_transfer_date
</cfquery>

<!DOCTYPE html>
<html lang="en">
<head>  
  <cfinclude template="includes/html_head.cfm">
  <style>
  	.glyphicon.glyphicon-dot {
      margin-top: -.9em;
      overflow: hidden;
    }
  	.glyphicon.glyphicon-dot:before {
      content: "\25cf";
      font-size: 3.5em;
    }
    
    .tl-black{
      color: #000;	
    }
    
    .tl-red{
      color: rgb(217, 83, 79)	
    }
    
    .tl-orange{
      color: rgb(240, 173, 78)	
    }
    
    .tl-green{
      color: rgb(92, 184, 92)	
    }
    
    .text-pink{
      color: rgb(255, 128, 192)	
    }
    
    .container-fluid{
      margin: 10px !important;	
    }
    
    #referralDetailsTable td:first-child{
      font-weight: bold
    }
    
    .label-custom{
      min-width: 75px !important;
      display: inline-block !important;
      font-size: .9em;
    }
    
    .checklist{
      text-align:center;
      color:#999;	
    }
    
    .checklist-icon, .checklist-icon-priority{
      cursor: pointer;	
    }
    
    .checklist-icon-text{
      color:#999;	
    }
    
    .checklist-icon-text-light{
      color:#ccc;	
    }
    
    th{
      text-align:center;	
    }
    
    .dummy-class{}
    
    .page-header{
      margin: 5px 0 10px !important;	
    }
    
    h1{
      margin-top: 6px !important;
      margin-bottom: 6px !important;	
    }
    
    #mainTable td:not(:last-child) {border-right:1px solid #f0f0f0 !important;}

    .text-warning{
      color: rgb(240,173, 78)
    } 
    
    .text-success{
      color: rgb(92, 184, 92)
    }   
    
    .editThis:hover{
      color: rgb(49, 112, 143);
      background: rgb(217, 237, 247);
      <!--- border: 1px solid rgb(217, 237, 247); --->
      border-radius: 4px; 
      <!--- padding: 6px; --->
    }	
    
    .badge:hover {
      color: #ffffff;
      text-decoration: none;
      cursor: pointer;
    }

    .badge-error {
      background-color: #b94a48;
    }

    .badge-error:hover {
      background-color: #953b39;
    }

    .badge-danger {
      background-color: rgb(217, 83, 79);
    }

    .badge-warning {
      background-color: #f0ad4e;
    }

    .badge-warning:hover {
      background-color: #c67605;
    }

    .badge-success {
      background-color: #5cb85c;
    }

    .badge-success:hover {
      background-color: #5cb85c;
    }
 
    .badge-info {
      background-color: #3a87ad;
    }

    .badge-info:hover {
      background-color: #2d6987;
    } 

    .badge-inverse {
      background-color: #333333;
    }
 
    .badge-inverse:hover {
      background-color: #1a1a1a;
    }

    .danger-custom{background-color: #ffcccc !important;}
    .danger-custom:hover{background-color: #ffb3b3;}
    .success-custom{background-color: #ccff99 !important;}

    .editThis{
      outline: 0px !important;
    }

    .editThis:focus{
      background-color: rgb(217, 237, 247) !important;
    }
    
    
    .td-red{
      background-color: #ff9999 !important;	
    }
    
    .td-orange{
      background-color: #ffdd99 !important;	
    }
    
    .td-yellow{
      background-color: #ffff99 !important;	
    }
    
    .td-green{
      background-color: #ccff99 !important;	
    }
    
    .td-blue{
      background-color: #d9edf7 !important;	
    }
    
    .td-dataTable-child{
      background-color: #eaf5fb;	
    }      
    
    div.patientDetailsSlider{
      display: none;
    }
    <!---
    a{color: #1d70b8 !important;}
    a:hover{color: #003078 !important;}
    .back-to-top{color: #ffffff !important;}
    .back-to-top:hover{color: #ffffff !important;}
    --->
    .label{text-shadow: 1px 1px #999999;font-size:85% !important;}
  </style>
</head>
<body>

<!--- **************************************************************************************************************************** --->
<!--- Main container --->
<div class="container-fluid" style="margin:15px !important;">
  
  <!--- **************************************************************************************************************************** --->
  <!--- Heading --->
  <div class="page-header"> 
    <div class="row">  		
      <div class="col-md-5">          	
        <h2><img src="images/gvhealth_logo.png" width="50" alt="GV Health logo" /> <cfoutput>#reportTitle# <small>as at #TimeFormat(Now(), "HH:mm:ss")#</small></cfoutput></h2>
      </div>
      <div class="col-md-5 hidden-print">
        <h5 class="text-right" style="padding-top:20px;">
          <a href="http://gvhcf01/cfapps/"><span class="glyphicon glyphicon-home"></span> Home</a> |
          <a href="" id="isbarWardReport" target="_blank"><span class="glyphicon glyphicon-file"></span> ISBAR</a> |                          
          <a href="http://gvhcf01.gvhealth.local/cfapps/Wards/bedbookingportal_action.cfm" target="_blank"><span class="glyphicon glyphicon-bed"></span> Bed booking</a> |
          <a href="http://gvhcf01.gvhealth.local/cfapps/ambulance/Ambulance_Form.cfm" target="_blank"><span class="glyphicon glyphicon-road"></span> Transp.</a> |
          <a href="http://gvhcf01.gvhealth.local/cfapps/wards/PatientTransfer_Form.cfm" target="_blank"><span class="glyphicon glyphicon-transfer"></span> Transfer</a> |
          <a href="http://gvhcf02.gvhealth.local/cfapps/Dashboard/EDShift_Action.cfm" target="_blank"><span class="glyphicon glyphicon-stats"></span> Dashboard</a> |
          <a href="#" id="help" title="View documentation" data-toggle="modal" data-target="#helpModal"><span class="glyphicon glyphicon-question-sign"></span> Help</a>	
        </h5>
      </div>
      <div class="col-md-2 hidden-print" style="padding-top:20px;">  
      	<form name="patientSearch" method="post" action="http://gvhcf01/cfapps/wards/PatEnq_Action.cfm">      	  	
          <div class="input-group">
            <input type="text" class="form-control input-sm" name="UnitRecord" placeholder="UR number...">
            <span class="input-group-btn">
              <button class="btn btn-default btn-primary input-sm" aria-label="Search" name="Search" style="box-shadow: 0px 0px !important;"><span class="glyphicon glyphicon-search"></span></button>
            </span>
          </div>
          
          <cfif Session.UserType EQ "M">
            <a href="http://gvhcf01/cfapps/Wards/PatAdvEnq_Form.cfm" title="Search by patient name, dob etc." target="_blank">Advanced search</a>
          </cfif>
        </form>
      </div> 	
    </div>
  </div>
  <!--- /Heading --->
  
  <!--- Empty inpatient beds and empty cubicles --->
  <cfif !URL.covid or !URL.arconly>
    <div class="row hidden-print">
      <div class="well" id="emptyBedsCubicles">
      	
      	<div>
      	  <b>Totals:</b>
          <span class="label label-info" style="font-size:85% !important;">Triage: <span id="totalTriage">-</span></span>
          <span class="label label-info" style="font-size:85% !important;">Waiting: <span id="totalWaiting">-</span></span>
          <span class="label label-info" style="font-size:85% !important;">ED: <span id="totalED">-</span></span>
          <span class="label label-info" style="font-size:85% !important;">SOU: <span id="totalSOU">-</span></span>				
        </div>
        
        <h5><b>Empty inpatient beds</b> (<a href="#" id="toggleEmptyBeds">Toggle</a>)</h5>
        <table class="table table-condensed table-border" id="emptyBedsTable" style="display:none;"> 
        <tr>
          <cfoutput query="GetEmptyBeds">
            <th>#GetEmptyBeds.WardCode#</th>	
          </cfoutput>
        </tr>
        <tr>
          <cfoutput query="GetEmptyBeds">
            <td class="text-center">#GetEmptyBeds.Empty#</td>	
          </cfoutput>
        </tr>
        </table>	
      
        <h5><b>Empty cubicles</b> (<a href="#" id="toggleEmptyCubicles">Toggle</a>)</h5>
        <div id="emptyCubicles" style="display:none;">
          <cfoutput query="GetEmptyCubicles">
            #GetEmptyCubicles.Cubicle#&nbsp;&nbsp;	
          </cfoutput>
        </div>
      </div>
   </div>  
  </cfif>
  
  <cfif GetExpectedPatients.recordcount NEQ 0>
    <div class="row hidden-print">
  	  <div class="alert alert-danger"><cfoutput><span class="glyphicon glyphicon-info-sign"></span> #GetExpectedPatients.recordcount# expected patient(s). 
  	  <a href="includes/WhiteboardEDExpectedPatients_Form.cfm" class="btn-openModal" data-target="##expectedPatientsModal"><b>Click here</b></a> to view details.</cfoutput></div>
  	</div>
  </cfif>
  
  <!---
  <!--- Department totals --->
  <div class="row">
  	<b>Totals:</b>
    <span class="label label-info" style="font-size:100% !important;">Triage: <span id="totalTriage">-</span></span>
    <span class="label label-info" style="font-size:100% !important;">Waiting: <span id="totalWaiting">-</span></span>
    <span class="label label-info" style="font-size:100% !important;">ED: <span id="totalED">-</span></span>
    <span class="label label-info" style="font-size:100% !important;">SOU: <span id="totalSOU">-</span></span>				
  </div>
  --->
      
  <div class="row">  	      
    <table class="table table-condensed table-hover table-border table-striped" id="mainTable">
    <thead>
    <tr>
      <th>&nbsp;</th>
      <th>Bed</th>	    	        
      <th>LOS</th>      	                   
      <th>Urg.</th>  
      <th class="hidden-print">&nbsp;</th>    
      <th>UR</th>     	
      <th>Name</th>
      <th>Sex</th>
      <th>Age</th>
      <th>Doctor</th>
      <th>Presenting problem/Situation</th>
      <th nowrap>Book bed</th>
      <th>Referral</th>
      <th nowrap>IP cons.</th>            	
    </tr>
    </thead>
    <tbody>
    
    
    <!--- Output each patient row --->  	
    <cfoutput query="GetEDData">
      <cftry>

      <!--- bookmark --->
      <cfif GetEDData.Rank EQ 0.5>    
        <cfset totalTriage++>
      <cfelseif GetEDData.Rank EQ 1>        
        <cfset totalWaiting++>
      <cfelseif GetEDData.Rank EQ 2>
        <cfset totalED++>
      <cfelseif GetEDData.Rank EQ 3>
        <cfset totalSOU++>
      </cfif>
      
      <cfset urList = ListAppend(urList, GetEDData.UrNumber)>
	  <cfset episodeList = ListAppend(episodeList, GetEDData.EpisodeNo)>
	  <cfset miList = ListAppend(miList, "#GetEDData.UrNumber#|#GetEDData.EpisodeNo#")>
	  <cfset ArrayAppend(isbarEpisodeNumbers, "#GetEDData.EpisodeNo#:#GetEDData.EpisodeType#")>
	  
      <!--- Figure out what flags the patient has set against them --->
	  <cfset nipm = false> <!--- Nurse Initiated Patient Management --->
      <cfset bedFlagE = false>
      <cfset bedFlagMH = false>
      <cfset bedFlagMHOA = false>
      <cfset boc = false> <!--- Behaviour of concern --->

      <cfset thisNotes = StructFindValue(notesData, GetEDData.RefNo, "all")>

      <!--- Check any codes we have found --->
      <cfloop array="#thisNotes#" index="note">  

        <cfif note.owner.notescode EQ "NIPM">
          <cfset nipm = true>
        </cfif>
        
        <cfif note.owner.notescode EQ "E">
          <cfset bedFlagE = true>
        <cfelseif note.owner.notescode EQ "MH">
          <cfset bedFlagMH = true>
        <cfelseif note.owner.notescode EQ "MHOA">
          <cfset bedFlagMHOA = true>
        <cfelseif note.owner.notescode EQ "BOC">
          <cfset boc = true>  
        </cfif>
      </cfloop>
	  
      <cfset thisTRClass = "dummy-class">
      
      <cfif (GetEDData.WaitMins GT wait24hrWarning) and (GetEDData.Rank LT 3)>
        <cfset thisTRClass = "danger">	
      </cfif>
      		
      <tr class="#thisTRClass#">
      	<!--- Expand/collapse patient details --->
      	<cfif GetEDData.Rank GT 0.5>
      	  <td><a href="" title="Expand/collapse patient details"><span class="expandRow glyphicon glyphicon-chevron-down" data-ur="#GetEDData.UrNumber#" data-episodeNo="#GetEDData.EpisodeNo#" data-episodeType="<cfif GetEDData.Rank LT 3>C<cfelse>I</cfif>"></span></a></td>
      	<cfelse>
      	  <td>&nbsp;</td>
      	</cfif>

      	<cfset thisSituation = "">
      	<cfif StructKeyExists(situationData, GetEDData.EpisodeNo)>
      	  <cfset thisSituation = situationData[GetEDData.EpisodeNo].EventText>      	 
        </cfif>
      	
      	<!--- Fast track patient --->
      	<cfset fastTrack = false>
      	
      	<!--- Triage/waiting patient or in FT cubical with no doctor assigned --->
      	<cfif (GetEDData.Rank LTE 1) or ((GetEDData.Rank EQ "2.0") and (Left(Trim(GetEDData.CurrLocn), 2) EQ "FT") and (GetEDData.CurrDoc NEQ ""))>
      	  <!--- If no Situation exists then check the Presenting Problem. Otherwise check the Situation. --->	
      	  <cfif thisSituation EQ "">
      	  	<cfif FindNoCase("FTW", GetEDData.PresProb) NEQ 0>
      	  	  <cfset fastTrack = true>
      	  	</cfif>
      	  <cfelse>
      	    <cfif FindNoCase("FTW", thisSituation) NEQ 0>
      	  	  <cfset fastTrack = true>
      	  	</cfif>	
      	  </cfif>
      	</cfif>
      	
      	<!--- Location --->
        <td <cfif GetEDData.Rank EQ 3>class="info"</cfif>>
          <cfif fastTrack>
          	<!--- Fast track --->
          	<span class="label label-success" data-toggle="tooltip" title="Fast Track waiting"><span class="glyphicon glyphicon-flash"></span> FT waiting</span>
          	<cfset totalWaitingFT++>
          </cfif>
          
          <cfif (GetEDData.AmbCode EQ "Y") and (GetEDData.WaitMins GT 20) and (GetEDData.CurrLocn LT "1")>
            <!--- Ambulance ramping --->
      	    <span class="label label-danger"><span class="iconify" data-icon="mdi:ambulance"></span> Ramp.</span>
      	    <cfset totalWaitingAmb++>	      
	      <cfelseif (Trim(GetEDData.CurrLocn) EQ "") and (GetEDData.AmbCode EQ "Y")>
	        <!--- Ambulance waiting --->
      	    <span class="label label-warning"><span class="iconify" data-icon="mdi:ambulance"></span> Amb.</span>
      	    <cfset totalWaitingAmb++>	
          <cfelseif (Trim(GetEDData.Loc) EQ "Wait") and (!fastTrack)>
            <div class="label label-info"><span class="glyphicon glyphicon-time"></span> Waiting</div> #GetEDData.CurrLocn#
          <cfelseif (Trim(GetEDData.Loc) EQ "Triage") and (!fastTrack)>
            <div class="label label-info"><span class="glyphicon glyphicon-random"></span> Triage</div>
          <cfelseif GetEDData.Rank EQ 3>
            #GetEDData.CurrLocn# <div class="label label-info">#GetEDData.Loc#</div>
          <cfelse>		
        	#GetEDData.CurrLocn#
          </cfif>	
        </td>
        
        <cfset waitClass = "">
        
        <cfif GetEDData.Rank LT 3>
          <cfif GetEDData.WaitMins GT 1200>
          	<cfset waitClass = "td-red">
          <cfelseif GetEDData.WaitMins GT 480>
            <cfset waitClass = "td-red">
          <cfelseif GetEDData.WaitMins GT 240>
            <cfset waitClass = "td-red">
          <cfelseif GetEDData.WaitMins GT 180>
            <cfset waitClass = "td-orange">
          <cfelseif GetEDData.WaitMins GT 120>
            <cfset waitClass = "td-orange">
          <cfelseif GetEDData.WaitMins GT 60>
            <cfset waitClass = "td-yellow">
          </cfif>	
        
        </cfif>
        
        <!--- Adding a couple of days to the data-order value for Rank 3 patients so they remain grouped together when sorted. --->
        <td <cfif GetEDData.Rank EQ 3>data-order="#GetEDData.WaitMins+2880#"<cfelse>data-order="#GetEDData.WaitMins#"</cfif> <cfif waitClass NEQ "">class="#waitClass#"</cfif>>
          <span data-toggle="tooltip" title="Arrived: #DateFormat(GetEDData.ArDate, 'dd/mm')# #TimeFormat(GetEDData.ArDate, 'HH:mm')#" class="los">#GetEDData.WaitMins\60#h #GetEDData.WaitMins MOD 60#m</span>
          
          <cfif (GetEDData.WaitMins GT wait24hrWarning) and (GetEDData.Rank LT 3)>
          	<span class="label label-default"><span class="glyphicon glyphicon-warning-sign"></span> 24h</span>
          <cfelseif (GetEDData.WaitMins GT 240) and (GetEDData.Rank LT 3)>
          	<!--- <span class="label label-default"><span class="glyphicon glyphicon-arrow-up"></span> NEAT</span> --->
          <cfelseif (GetEDData.WaitMins GT 180) and (GetEDData.WaitMins LTE 240) and (GetEDData.Rank LT 3)>
            <span class="label label-default"><span class="glyphicon glyphicon-hourglass"></span> NEAT</span>          
          </cfif>
        </td>
        
        <cfset urgencyClass = "">
        
        <cfif GetEDData.Urgency EQ 1>
          <cfset urgencyClass = "td-red">
        <cfelseif GetEDData.Urgency EQ 2>
          <cfset urgencyClass = "td-orange"> 	
        <cfelseif GetEDData.Urgency EQ 3>
          <cfset urgencyClass = "td-yellow">
        <cfelseif GetEDData.Urgency EQ 4>
          <cfset urgencyClass = "td-green">
        <cfelseif GetEDData.Urgency EQ 5>
          <cfset urgencyClass = "td-blue">       
        </cfif>
        
        <td class="text-center #urgencyClass#" data-order="#GetEDData.Urgency#">
          #GetEDData.Urgency#
        </td>
        <td nowrap class="hidden-print">
          <cfif Trim(GetEDData.UrNumber) NEQ "">
          	
          	<cfif URL.covid OR URL.arconly>
          	  <cfif GetEDData.Rank EQ 3>
                <a href="http://gvhcf01.gvhealth.local/cfapps/isbar/version_2.2/Covid19Screening_Form.cfm?episodeNo=#EncryptEncode(GetEDData.EpisodeNo)#&episodeType=#EncryptEncode('I')#" title="COVID-19 Screening" target="_blank"><span class="glyphicon glyphicon-asterisk"></span></a>
              <cfelse>
                <a href="http://gvhcf01.gvhealth.local/cfapps/isbar/version_2.2/Covid19Screening_Form.cfm?episodeNo=#EncryptEncode(GetEDData.EpisodeNo)#&episodeType=#EncryptEncode('C')#" title="COVID-19 Screening" target="_blank"><span class="glyphicon glyphicon-asterisk"></span></a>
              </cfif>  	
          	</cfif>
          			
            <a href="http://gvh3mkyweb01.gvhealth.local/CHARTVIEW-LIVE/UserInterface/3mHISImaging.application?moduleid=-2000&url=http://GVH3MWEB1:80/DI-LIVE/CustomConfigurationServer.rem&EXTID=#ListGetAt(CGI.Auth_User, 2, '\')#&MRN=#GetEDData.UrNumber#" title="3M ChartView" target="_blank" rel="noopener"><span class="glyphicon glyphicon-folder-open" ></span></a>	
		    <a href="http://gvhcf01.gvhealth.local/cfapps/Wards/PromedStudies_Action.cfm?URNO=#GetEDData.UrNumber#" class="text-default medicalImaging" title="Medical Imaging results and requests" style="font-size:1.25em;padding-left:4px;" data-ur="#GetEDData.URnumber#" title="Medical Imaging results and requests" id="mi-#GetEDData.EpisodeNo#"><span class="ionicons ion-nuclear"></span></a>
		    <a href="orderpathology_form.cfm?episodeNo=#EncryptEncode(GetEDData.EpisodeNo, salt)#&episodeType=#EncryptEncode('C', salt)#&patConfirmed=true" title="Pathology requests" style="font-size:1em;padding-left:4px;" target="_blank" rel="noopener"><span class="glyphicon glyphicon-file"></span></a>
		    <a href="http://gvhpath1.gvhealth.local/labtrak_autologin/csp/logon.csp?LANGID=1&alldeps=true&LaunchPage=E&MRN=#NumberFormat(GetEDData.UrNumber, 0)#" title="Pathology results" target="_blank" rel="noopener" style="font-size:1.25em;padding-left:4px;"><span class="ionicons ion-flask"></span></a>
		  </cfif>		    		    		    		    		   		     	
        </td>
        <td>
          <cfif GetEDData.Rank EQ 3>
            <a href="http://gvhcf01.gvhealth.local/cfapps/isbar/version_2.2/Handover_Form.cfm?episodeNo=#EncryptEncode(GetEDData.EpisodeNo)#&episodeType=#EncryptEncode('I')#" title="Open ISBAR" target="_blank">#GetEDData.UrNumber#</a><br />
            
            <cfif GetEDData.AeEpisode NEQ "">            
              <small><a href="http://gvhcf01.gvhealth.local/cfapps/isbar/version_2.2/Login_Form.cfm?episodeNo=#EncryptEncode(GetEDData.AeEpisode)#&episodeType=#EncryptEncode('C')#&dest=ED5" title="Open ED5" target="_blank"><span class="glyphicon glyphicon-file"></span> ED5</a></small>
            </cfif>            
          <cfelse>		
            <cfif Session.UserType EQ "M">
        	  <a href="http://gvhcf01.gvhealth.local/cfapps/isbar/version_2.2/Login_Form.cfm?episodeNo=#EncryptEncode(GetEDData.EpisodeNo)#&episodeType=#EncryptEncode('C')#&dest=ED5" title="Open ED5" target="_blank">#GetEDData.UrNumber#</a>
            <cfelse>
              <a href="http://gvhcf01.gvhealth.local/cfapps/isbar/version_2.2/Handover_Form.cfm?episodeNo=#EncryptEncode(GetEDData.EpisodeNo)#&episodeType=#EncryptEncode('C')#" title="Open ISBAR" target="_blank">#GetEDData.UrNumber#</a>
            </cfif>
          </cfif>
        </td>
        <td id="patname_#GetEDData.UrNumber#">
          <a href="http://gvhcf01.gvhealth.local/cfapps/wards/PatEnq_Action.cfm?UnitRecord=#GetEDData.UrNumber#" title="#GetEDData.Surname#, #GetEDData.GivenName# - View patient details"><b>#GetEDData.Surname#, <small>#GetEDData.GivenName#</small></b></a>

          <!--- Patient alerts and flags --->
          <!--- Get any alerts and flags for this patient --->  
          <cfset thisAlertsFlags = StructFindValue(alertsFlags, GetEDData.PatientID, "all")>

          <!--- Where we will store our alerts and flags --->
          <cfset alertsList = "">
          <cfset flagsList = "">
	
	      <!--- Loop through any alerts or flags we found for this patient --->
          <cfloop array="#thisAlertsFlags#" index="data">    
            <cfif data.owner.type EQ "Alert">
  	          <cfset alertsList = ListAppend(alertsList, data.owner.description, ";")>
            <cfelseif data.owner.type EQ "Drug flag">
              <cfset flagsList = ListAppend(flagsList, data.owner.description, ";")>	
            <cfelseif data.owner.type EQ "Allergy flag">
              <cfset flagsList = ListAppend(flagsList, "Allergy: " & data.owner.description, ";")>
            </cfif>
          </cfloop>
          
          <!--- Do some formatting --->
          <cfif alertsList EQ "">
          	<cfset thisAlerts = "None">
          <cfelse>
            <cfset thisAlerts = Replace(alertsList, ";", "; ", "all")>
          </cfif>
          
          <cfif flagsList EQ "">
          	<cfset thisFlags = "None">
          <cfelse>
            <cfset thisFlags = Replace(flagsList, ";", "; ", "all")>
          </cfif>
          
          <!--- Display any alerts or flags--->	
          <cfif (thisAlerts NEQ "None") or (thisFlags NEQ "None")>
          	<cfif thisAlerts NEQ "None">
          	  <br /><div class="label label-danger hidden-print" data-toggle="tooltip" data-html="true" title="<div style='text-align: left;'><span class='glyphicon glyphicon-alert'></span> Alerts: #thisAlerts#<br /><br /><span class='glyphicon glyphicon-flag'></span> Flags: #thisFlags#</div>"><span class="glyphicon glyphicon-alert"></span> Alerts</div>
          	<cfelse>
          	  <br /><div class="label label-warning hidden-print" data-toggle="tooltip" data-html="true" title="<div style='text-align: left;'><span class='glyphicon glyphicon-alert'></span> Alerts: #thisAlerts#<br /><br /><span class='glyphicon glyphicon-flag'></span> Flags: #thisFlags#</div>"><span class="glyphicon glyphicon-flag"></span> Flags</div>
          	</cfif>
          	
          	<div class="visible-print">Alerts: #thisAlerts#</div>
          	<div class="visible-print">Flags: #thisFlags#</div>	
          </cfif>
          
          <!--- Behaviour of concern --->
          <cfif boc>
          	<span class="label label-default hidden-print" data-toggle="tooltip" title="Behaviour of concern">BOC</span>
          	<div class="visible-print">Behaviour of concern</div>
          </cfif>
          
          <!--- Nursing home patients --->
          <cfset nursingHomeList = "NURSING,AGED,TARCOOLA,MERCY,HAKEA,ACACIA H,BANKSIA,MOYOLA,HARMONY,ELDERS,AMAROO L,RODNEY P,PIONEER,OTTREY,AVE MARIA,MACULATA PLACE">
          
          <cfloop list="#nursingHomeList#" index="nursingHome">
            <cfif FindNoCase(nursingHome, GetEDData.Address1, 1)>
              <span class="label label-info" data-toggle="tooltip" title="Nursing home patient">NH</span>
              <cfbreak>	
            </cfif>
          </cfloop>
          
          <!--- Private patient --->
          <cfif Trim(GetEDData.InsFund) NEQ "">
          	<span class="glyphicon glyphicon-star hidden-print" aria-hidden="true" data-toggle="tooltip" title="Private Patient"></span>
          	<div class="visible-print">Private patient</div>
          </cfif> 	              
        </td>
        <td>#GetEDData.Sex#</td>
        
        <!--- To make the age sort order properly we need to first remove any non-numeric characters from the age string --->
        <cfset thisAgeOrderValue = reReplaceNoCase(GetEDData.Age, '[^[:digit:]]', '', 'ALL')>
        
        <!--- Now, if the age value is in months then divide by 10 so that they fall in order below the year values --->
        <cfif Right(GetEDData.Age, 1) EQ "M">
          <cfset thisAgeOrderValue = thisAgeOrderValue/10>
        </cfif>
        
        <td data-order="#thisAgeOrderValue#">#GetEDData.Age#</td>
        
        <td <cfif GetEDData.CurrDoc EQ "" and GetEDData.Rank GT 0.5>class="info"<cfelseif GetEDData.CurrDoc EQ "RAT">class="success-custom"</cfif>>
          <!--- It is much quicker to get the rank 3 patient doctors outside of the main query for some reason --->	
          <cfif GetEDData.Rank EQ 3>
            <cfquery name="GetEDDoctor" datasource="#Session.HospODBC#" cachedwithin="#createTimeSpan(1,0,0,0)#">
  	          select 
  	            initials as CurrDoc,
  	            title + ' ' + initials + ' ' + name as CurrDocName             
  	          from anedoctor
  	          where dr_code = '#GetEDData.CurrDoc#' 
            </cfquery>
            
            <cfif GetEDDoctor.recordcount NEQ 0>
              <span data-toggle="tooltip" title="#GetEDDoctor.CurrDocName#">#GetEDDoctor.CurrDoc#</span>
            </cfif>
          <cfelse>
            <span id="doctor_#GetEDData.EpisodeNo#" data-toggle="tooltip" title="#GetEDData.CurrDocName#">#GetEDData.CurrDoc#</span>
          </cfif>
          
          <!--- NIPM --->
          <cfif (GetEDData.Rank LT 3) and (GetEDData.CurrDoc EQ "") and (nipm)>
            <span class="label label-info">NIPM</span>            
	      </cfif>

          <cfif (GetEDData.Rank GTE 1) and (GetEDData.Rank NEQ 3) and (!URL.covid) and (!URL.arconly)>
            <a href="includes/WhiteboardUpdateDoctor_Form.cfm?episodeNo=#GetEDData.EpisodeNo#&episodeType=C&URNO=#Trim(GetEDData.UrNumber)#&Urgency=#GetEDData.Urgency#<cfif GetEDData.CurrDoc EQ ''>&insert=true</cfif>" title="Update Emergency Department doctor" class="btn-openModal" data-target="##addDoctorModal"><cfif GetEDData.CurrDoc EQ "">+<cfelse><span class="glyphicon glyphicon-refresh"></span></cfif></a>
	      </cfif>	
        </td>
	    
	    <!--- <cfif situationData[GetEDData.EpisodeNo].recordcount NEQ 0> --->
	    <cfif StructKeyExists(situationData, GetEDData.EpisodeNo)>	  
	      <cfset displaySituationChars = 100>
	      <cfset displaySituationCharsExceeded = false>
	      
	      <cfif Len(situationData[GetEDData.EpisodeNo].EventText) GT displaySituationChars>
	        <cfset displaySituationCharsExceeded = true>  	
	      </cfif>
	          
	      <td>
	        <div class="hidden-print" <cfif displaySituationCharsExceeded>data-toggle="tooltip" title="#EncodeForHTML(situationData[GetEDData.EpisodeNo].EventText)#" data-placement="auto"</cfif>>
	          <span id="situationLabel_#GetEDData.EpisodeNo#"><b>SIT:</b></span> 	            
	          <!--- <span <cfif (GetEDData.Rank GTE 1) and ((Trim(situationData[GetEDData.EpisodeNo].EventType1) EQ "") and (ListFind("M,N", Session.UserType) NEQ 0)) or ((situationData[GetEDData.EpisodeNo].EventType1 EQ "M") and (Session.UserType EQ "M"))>contenteditable="true" class="editThis hidden-print"<cfelse>class="hidden-print"</cfif> data-placement="left" data-episodeNo="#EncryptEncode(GetEDData.EpisodeNo, salt)#" data-episodeType="#EncryptEncode(GetEDData.EpisodeType, salt)#" data-userType="#Session.UserType#" data-eventType="situation" data-originalText="None available." data-maxLength="1000" data-episodeNoUnencrypted="#GetEDData.EpisodeNo#">#EncodeForHTML(Left(Trim(situationData[GetEDData.EpisodeNo].EventText), displaySituationChars))#<cfif displaySituationCharsExceeded><mark>...</mark></cfif></span> --->

	          <span <cfif (GetEDData.Rank GTE 1) and (ListFind("M,N", Session.UserType) NEQ 0)>contenteditable="true" class="editThis hidden-print"<cfelse>class="hidden-print"</cfif> data-placement="left" data-episodeNo="#EncryptEncode(GetEDData.EpisodeNo, salt)#" data-episodeType="#EncryptEncode(GetEDData.EpisodeType, salt)#" data-userType="#Session.UserType#" data-eventType="situation" data-originalText="#situationData[GetEDData.EpisodeNo].EventText#" data-maxLength="1000" data-episodeNoUnencrypted="#GetEDData.EpisodeNo#" data-situationCharsExceeded="#displaySituationCharsExceeded#">#EncodeForHTML(Left(Trim(situationData[GetEDData.EpisodeNo].EventText), displaySituationChars))#<cfif displaySituationCharsExceeded><mark>...</mark></cfif></span>
	        </div>	      		      		      	

	        <div class="visible-print"><b>SIT:</b> <span id="situationPrint_#GetEDData.EpisodeNo#">#EncodeForHTML(situationData[GetEDData.EpisodeNo].EventText)#</span></div>
	      </td>
        <cfelse>
          <td>          	
          	<cfif (GetEDData.Rank GTE 1) and (ListFind("M,N", Session.UserType) NEQ 0)>
          	  <div class="hidden-print"><span id="situationLabel_#GetEDData.EpisodeNo#"><b>PP:</b></span> <span contenteditable="true" class="editThis" data-episodeNo="#EncryptEncode(GetEDData.EpisodeNo, salt)#" data-episodeType="#EncryptEncode(GetEDData.EpisodeType, salt)#" data-userType="#Session.UserType#" data-eventType="situation" data-originalText="#GetEDData.PresProb#" data-maxLength="1000" data-episodeNoUnencrypted="#GetEDData.EpisodeNo#">#GetEDData.PresProb#</span></div>          	
          	<cfelse>
          	  <span class="hidden-print"><b>PP:</b> #GetEDData.PresProb#</span>
	        </cfif>

          	<div class="visible-print"><b>PP:</b> <span id="situationPrint_#GetEDData.EpisodeNo#">#GetEDData.PresProb#</span></div>
          </td>
	    </cfif>
	    
        
         <!--- Bed booking column --->         
         <cfif GetEDData.Rank NEQ 0.5 >
           <!--- If the patient has a SOU flag set and they aren't already in SOU or MAPU then don't display the bed booking selection box --->
           <cfif (bedFlagE) and (GetEDData.Rank NEQ 3)>
			 <td class="success-custom">SOU/MAPU</td>
           <cfelseif (bedFlagMH) and (GetEDData.Rank NEQ 3)>
             <td class="success-custom">MHealth</td>
           <cfelseif (bedFlagMHOA) and (GetEDData.Rank NEQ 3)>
             <td class="success-custom">MentalOA</td>
	       <cfelse>	
	         <!---	     
  		     <cfset thisBedTypesList = "">		     
	  	     <!--- Replace instances of 'unclassified' with 'standard' --->
		     <cfset thisBedTypesList = ReplaceList(thisBedTypesList, "Unclassified", "Std")>
		     --->
		     
		     <cfif !StructKeyExists(bedBookings, GetEDData.PatientId)>
		       <cfif (!URL.covid) and (!URL.arconly)>	
                 <td>
	               <span id="bedBooking_#GetEDData.PatientID#"><a href="includes/WhiteboardBedBooking_Form.cfm?episodeNo=#GetEDData.EpisodeNo#&patId=#GetEDData.PatientID#&edRefNo=#GetEDData.RefNo#&episodeType=C&urNumber=#Trim(GetEDData.UrNumber)#&fromWard=A%26E" class="btn-openModal" data-target="##bedBookingModal">+</a></span>
		         </td>
		       <cfelse>
		         <td>&nbsp;</td>
		       </cfif>
	       <cfelse>	         	             
	         <cfif StructKeyExists(bedBookings, GetEDData.PatientId)>
	         	
	           <cfquery name="GetBedTypes" datasource="#Session.HospODBC#" cachedwithin="#createTimeSpan(1,0,0,0)#">
		         select 
		           bbt.code as Code,
		           trim(lkbt.description) as Description
		         from bed_booking_types bbt, lk_bed_types lkbt
		         where bbt.booking_no = '#bedBookings[GetEDData.PatientId].bookingno#'
		           and bbt.code = lkbt.code
		           and bbt.status != 'X'
		           and lkbt.active_flag = 'Y'
		         order by Description
		       </cfquery>
		       
		       <cfset thisBedTypesList = "">
		  
		       <!--- Assign the query result to a list (there should always be at least one result) --->  
		       <cfset thisBedTypesList = ValueList(GetBedTypes.Description, '/')>
		
	  	       <!--- Replace instances of 'unclassified' with 'standard' --->
		       <cfset thisBedTypesList = ReplaceList(thisBedTypesList, "Unclassified", "Std")>
		       <cfset thisBedTypesList = ReplaceList(thisBedTypesList, "Telemetry", "Telem")>
		    	
               <cfif bedBookings[GetEDData.PatientId].completed EQ 'P'>
		         <td>
			       <span data-toggle="tooltip" title="Pending bed manager approval."><span class="iconify" data-icon="ic:round-pending-actions" data-inline="false"></span> #bedBookings[GetEDData.PatientId].wardcode# (#thisBedTypesList#) - Pending<span>
			       <a href="http://gvhcf02/cfapps/Wards/BedBookingStatus_Action.cfm?bookingNo=#bedBookings[GetEDData.PatientId].bookingno#&status=X&UrNumber=#RTrim(GetEDData.UrNumber)#&FromWard=ED&ToWard=#bedBookings[GetEDData.PatientId].wardcode#" class="cancelBedBooking" title="Cancel this bed booking"><span class="glyphicon glyphicon-remove text-danger"></span></a>
		         </td>
		       <cfelseif bedBookings[GetEDData.PatientId].completed EQ 'A'>
		         <td class="info">
			       <span data-toggle="tooltip" title="Approved by the bed manager and waiting for bed allocation."><span class="iconify" data-icon="cil:bed" data-inline="false"></span> #bedBookings[GetEDData.PatientId].wardcode# (#thisBedTypesList#) - Approved</span>
			       <a href="http://gvhcf02/cfapps/Wards/BedBookingStatus_Action.cfm?bookingNo=#bedBookings[GetEDData.PatientId].bookingno#&status=X&UrNumber=#RTrim(GetEDData.UrNumber)#&FromWard=ED&ToWard=#bedBookings[GetEDData.PatientId].wardcode#" class="cancelBedBooking" title="Cancel this bed booking"><span class="glyphicon glyphicon-remove text-danger"></span></a>
		         </td>
		       <cfelseif bedBookings[GetEDData.PatientId].completed EQ ''>
		         <cfset timeUntilBedAvailable = DateDiff("h", Now(), bedBookings[GetEDData.PatientId].bookingdate)>

		         <cfif timeUntilBedAvailable LTE 0>
			       <cfset timeUntilBedAvailable = DateDiff("n", Now(), bedBookings[GetEDData.PatientId].bookingdate)>

			       <cfif timeUntilBedAvailable LTE 0>
                     <cfset timeUntilBedAvailableText = "avail. now">
			       <cfelse>
			         <cfset timeUntilBedAvailableText = "avail. #timeUntilBedAvailable#m">
			       </cfif>
		         <cfelse>
			       <cfif timeUntilBedAvailable EQ 1>
			         <cfset timeUntilBedAvailableText = "avail. #DateDiff("h", Now(), bedBookings[GetEDData.PatientId].bookingdate)#h">
			       <cfelse>
			         <cfset timeUntilBedAvailableText = "avail. #DateDiff("h", Now(), bedBookings[GetEDData.PatientId].bookingdate)#h">
			       </cfif>
		         </cfif>

		         <td class="success-custom"><span data-toggle="tooltip" title="Bed #bedBookings[GetEDData.PatientId].bedno# in ward #bedBookings[GetEDData.PatientId].wardcode# available on #DateFormat(bedBookings[GetEDData.PatientId].bookingdate, "dd/mm")# at #TimeFormat(bedBookings[GetEDData.PatientId].bookingdate, "HH:mm")#."><span class="glyphicon glyphicon-ok"></span> #bedBookings[GetEDData.PatientId].wardcode# (#thisBedTypesList#) bed #bedBookings[GetEDData.PatientId].bedno# #timeUntilBedAvailableText#</span></td>
		       <cfelse>
		         <td>&nbsp;</td>
		       </cfif>
             </cfif>
           </cfif>
         </cfif>
	   <cfelse>
 	     <td>&nbsp;</td>
	   </cfif>
       <!--- /Bed booking column --->

       <!--- Referrals --->
       <cfif Rank NEQ 4>
       	
       	 <cfset thisRefCode = "">
         <cfset thisTime = "">
         <cfset thisRefTime = "">
             
         <cfif StructKeyExists(referralData1, GetEDData.RefNo)>
           <cfset thisRefCode = referralData1[GetEDData.RefNo].notescode>
           <cfset thisTime = referralData1[GetEDData.RefNo].datetime>
               
           <cfif thisRefCode EQ "TR">
           	 <cfif StructKeyExists(referralData2, GetEDData.RefNo)>                   
               <cfset thisRefTime = referralData2[GetEDData.RefNo].datetime>  	
             </cfif>
           </cfif>
         <cfelse>
           <cfif StructKeyExists(referralData2, GetEDData.RefNo)>
             <cfset thisRefCode = referralData2[GetEDData.RefNo].notescode>
             <cfset thisTime = referralData2[GetEDData.RefNo].datetime>  	
           </cfif>
         </cfif>             
             
	     <!--- Referred-Reviewed column --->
	     <cfif thisRefCode EQ "">
	       <td>
	     <cfelseif thisRefCode EQ "TR">
           <td nowrap class="info">
	     <cfelseif thisRefCode EQ "RA">
           <td nowrap class="success-custom">
	     <cfelseif thisRefCode EQ "PW">
           <td nowrap class="success-custom">
         <cfelse>
           <td nowrap class="success-custom">
         </cfif>

	     <cfif trim(GetEDData.Loc) NEQ "Wait" AND trim(GetEDData.Loc) NEQ "Triage">
           <select class="form-control reviewStatus" data-edRefNo="#GetEDData.RefNo#">

	       <cfif thisRefCode EQ "">
	         <option value=""></option>
	       </cfif>

		   <option value="RT" <cfif thisRefCode EQ "RT">selected</cfif>>Referred</option>
  	       <option value="M" <cfif thisRefCode EQ "M">selected</cfif>>Medical</option>
	       <option value="S" <cfif thisRefCode EQ "S">selected</cfif>>Surgical</option>
	       <option value="I" <cfif thisRefCode EQ "I">selected</cfif>>ICU</option>
	       <option value="P" <cfif thisRefCode EQ "P">selected</cfif>>Paediatric</option>
	       <option value="MCU" <cfif thisRefCode EQ "MCU">selected</cfif>>MCU</option>
	       <option value="O" <cfif thisRefCode EQ "O">selected</cfif>>Orthopaedic</option>
           <option value="O&G" <cfif thisRefCode EQ "O&G">selected</cfif>>O&G</option>
           <option value="MHR" <cfif thisRefCode EQ "MHR">selected</cfif>>MH</option>
           <option value="ONC" <cfif thisRefCode EQ "ONC">selected</cfif>>Oncology</option>
           <option value="RES" <cfif thisRefCode EQ "RES">selected</cfif>>Respiratory</option>
           <option value="WT" <cfif thisRefCode EQ "WT">selected</cfif>>Waiting Trans.</option>
           <option value="WD" <cfif thisRefCode EQ "WD">selected</cfif>>Waiting Disch.</option>
           <option value="EXT" <cfif thisRefCode EQ "EXT">selected</cfif>>External Ref</option>
  		   <option value="RA" <cfif thisRefCode EQ "RA">selected</cfif>>Accepted</option>
 		   <option value="TR" <cfif thisRefCode EQ "TR">selected</cfif>>Reviewed</option>
		   <option value="PW" <cfif thisRefCode EQ "PW">selected</cfif>>PW done</option>
		   </select>
           
           <span id="refTime_#GetEDData.RefNo#">
           <cfif thisTime NEQ "">           	 
             #TimeFormat(thisTime, "HH:mm")#
	         <cfif thisRefTime NEQ "">
               <br>
               Referred: #TimeFormat(thisRefTime, "HH:mm")#
             </cfif>
           </cfif>
           </span>
 	   </td>
     <cfelse>
	   <cfif (huddleboard)>
	     &nbsp;</td>
	   </cfif>
     </cfif>
   <cfelse>
     &nbsp;</td>
   </cfif>
   <!--- /Referred-Reviewed column --->

   <!--- IP consultant --->
   <cfif (Rank EQ 2) and (!URL.covid) and (!URL.arconly)>
     <cfif StructKeyExists(admitDocData, GetEDData.EpisodeNo)>
       <td>
         <a href="includes/WhiteboardUpdateIPDoctor_Form.cfm?episodeNo=#GetEDData.EpisodeNo#&episodeType=C&URNO=#Trim(GetEDData.UrNumber)#&Urgency=#GetEDData.Urgency#" id="ipDoctor_#GetEDData.EpisodeNo#" title="Update Emergency Department doctor" class="btn-openModal" data-target="##addIPDoctorModal"><cfif admitDocData[GetEDData.EpisodeNo].docname EQ "">+<cfelse>#admitDocData[GetEDData.EpisodeNo].docname#</cfif></a> <cfif admitDocData[GetEDData.EpisodeNo].docname NEQ ""><span id="ipDoctorTime_#GetEDData.EpisodeNo#">#TimeFormat(admitDocData[GetEDData.EpisodeNo].datetime, "HH:mm")#</span></cfif>
       </td>
     <cfelse>
       <td><a href="includes/WhiteboardUpdateIPDoctor_Form.cfm?episodeNo=#GetEDData.EpisodeNo#&episodeType=C&URNO=#Trim(GetEDData.UrNumber)#&Urgency=#GetEDData.Urgency#" id="ipDoctor_#GetEDData.EpisodeNo#" title="Update Emergency Department doctor" class="btn-openModal" data-target="##addIPDoctorModal">+</a></td>
     </cfif>
   <cfelse>
     <td>&nbsp;</td>
   </cfif>
   <!--- /IP consultant --->
   
      </tr>
      
      <cfcatch type="any">
          <td colspan="1"><b class="text-danger"><span class="glyphicon glyphicon-warning-sign"></span> Error displaying patient details.</b></td>	
        </tr>
      </cfcatch>	
    </cftry>        
    </cfoutput>
      
     
    </tbody>
    </table>

    <br />
    <a id="back-to-top" href="#" class="btn btn-primary btn-lg back-to-top" role="button"><span class="glyphicon glyphicon-chevron-up"></span></a>
	<br />
  </div>
  
  <!--- Footer --->
  <cfinclude template="includes/footer.cfm">
</div>
<!--- /Main container --->

  <!--- Loading modal --->
  <div id="loadingModal" class="modal" tabindex="-1" role="dialog" aria-hidden="true">
    <div class="modal-dialog modal-lg">
      <div class="modal-content">
      	<div class="modal-body">
      	  <h5><b>Loading...</b></h5>	
          <div class="progress">
            <div class="progress-bar progress-bar-striped active" role="progressbar" aria-valuenow="100" aria-valuemin="0" aria-valuemax="100" style="width: 100%">
              <span class="sr-only">Loading...</span>
            </div>
          </div>	
      	</div>  
      	<div class="modal-footer">
          <button type="button" class="btn btn-primary" data-dismiss="modal">Close</button>        
        </div>    	
      </div>
    </div>
  </div>

  <!--- Add/update doctor modal --->
  <div id="addDoctorModal" class="modal fade" tabindex="-1" role="dialog" aria-hidden="true">
    <div class="modal-dialog">
      <div class="modal-content">
        <!--- Content dynamically generated --->
      </div>
    </div>
  </div>
  
  <!--- Add/update IP doctor modal --->
  <div id="addIPDoctorModal" class="modal fade" tabindex="-1" role="dialog" aria-hidden="true">
    <div class="modal-dialog">
      <div class="modal-content">
        <!--- Content dynamically generated --->
      </div>
    </div>
  </div>
  
  <!--- Bed booking modal --->
  <div id="bedBookingModal" class="modal fade" tabindex="-1" role="dialog" aria-hidden="true">
    <div class="modal-dialog">
      <div class="modal-content">
        <!--- Content dynamically generated --->
      </div>
    </div>
  </div>
  
  <!--- Expected patients modal --->
  <div id="expectedPatientsModal" class="modal fade" tabindex="-1" role="dialog" aria-hidden="true">
    <div class="modal-dialog modal-lg">
      <div class="modal-content">
        <!--- Content dynamically generated --->
      </div>
    </div>
  </div>
  
  <!--- Refusal of treatment modal --->
  <div id="refusalTreatModal" class="modal fade" tabindex="-1" role="dialog" aria-hidden="true">
    <div class="modal-dialog modal-lg">
      <div class="modal-content">
      	<div class="modal-body">
      	  <h5><b>Loading...</b></h5>	
          <div class="progress">
            <div class="progress-bar progress-bar-striped active" role="progressbar" aria-valuenow="100" aria-valuemin="0" aria-valuemax="100" style="width: 100%">
              <span class="sr-only">Loading...</span>
            </div>
          </div>	
      	</div>        	  
      </div>
    </div>
  </div>
  
  <!--- Help modal --->
  <div id="helpModal" class="modal fade" tabindex="-1" role="dialog" aria-hidden="true">
    <div class="modal-dialog modal-lg">
      <div class="modal-content">
        <div class="modal-header">
       	  <button type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button>
	      <h4><span class="glyphicon glyphicon-question-sign"></span> Help</h4>		    
		</div>	
        <div class="modal-body">
                     
          <table class="table table-condensed table-striped table-hover dataDefinitionsTable">
          <tr>
            <td width="150px"><span class="glyphicon glyphicon-chevron-down"></span></td>
            <td>
              Click the down arrow to expand the patient row and view additional information such as demographics and previous episode history. To close the expanded information click the 
              corresponding up arrow. Multiple rows can be expanded at the same time.              
            </td>	
          </tr>		
          <tr>
            <td>LOS</td>
            <td>
              How long since the patient arrived. Hover or click to show the patient's arrival date and time.<br /><br /> 

              <div style="background-color:#ffff99;width:30%;padding:6px;">Greater than 1 hour</div>
              <div style="background-color:#ffdd99;width:30%;padding:6px;">Greater than 3 hours</div>
              <div style="background-color:#ff9999;width:30%;padding:6px;">Greater than 4 hours</div>
              
              <br />
              <span class="label label-default"><span class="glyphicon glyphicon-hourglass"></span> NEAT</span> Patients who are within one hour of exceeding the NEAT target.<br />
              <span class="label label-default"><span class="glyphicon glyphicon-warning-sign"></span> 24h</span> Patients who are approaching a 24 hour length of stay.   
            </td>	
          </tr>
          <tr>
            <td>Clinical system icons</td>
            <td>
              Icons that link directly to other systems:
              <br /><br />
              <span class="glyphicon glyphicon-folder-open" aria-hidden="true"></span> 3M<br />
              <span class="glyphicon ionicon ion-nuclear" aria-hidden="true"></span> Medical Imaging (<span class="ionicon ion-nuclear text-success" aria-hidden="true"></span> = Images ready; <span class="ionicon ion-nuclear text-danger" aria-hidden="true"></span> = In progress; <span class="ionicon ion-nuclear text-info" aria-hidden="true"></span> = New request; <span class="glyphicon glyphicon-list-alt" aria-hidden="true"></span> = Report available)<br />
              <span class="glyphicon ionicon ion-flask" aria-hidden="true"></span> Pathology results<br />
              <span class="glyphicon glyphicon-file" aria-hidden="true"></span> Pathology ordering<br />                               
            </td>	
          </tr>
          <tr>
          	<td>UR</td>
          	<td>Click the patient's UR number to be taken to their ISBAR or ED5 form.</td>
          </tr>
          <tr>
            <td>Name</td>
            <td>
              Click to view additional patient details.<br /><br />
              <span class="label label-danger"><span class="glyphicon glyphicon-alert" aria-hidden="true"></span> Alerts</span> The patient has one or more alerts (hover or click to view details).<br />
              <span class="label label-warning"><span class="glyphicon glyphicon-flag" aria-hidden="true"></span> Flags</span> The patient has one or more flags but no alerts (hover or click to view details).<br /><br />
              Patients with Treatment Refusal, ACP and SDM etc. documents will be flagged beneath the patient's name. Click this warning to view a list of relevant documents with links directly to 3M.                           
            </td>              
          </tr>
          <tr>
            <td>Doctor</td>
            <td>
              Click the + or <span class="glyphicon glyphicon-refresh"></span> symbols to add or update the patient's doctor.                                         
            </td>              
          </tr>	
          <tr>
          	<td>Presenting problem (PP)/Situation (SIT)</td>
          	<td>The patient's presenting problem (PP) or current Situation (SIT) from ISBAR/ED5. This is restricted to a certain number of characters to conserve space, with truncated entries shown with <mark>...</mark> at the end. Hover or click these to view the full entry.</td>
          </tr>	
          <tr>
          	<td>Book bed</td>
          	<td>
          	  Click the + symbol to book a bed. You will be asked to select the destination ward and bed type(s), which will vary depending on the ward selected. 
          	</td>
          </tr>
          <tr>
          	<td>Referral</td>
          	<td>
          	  Select a referral destination from the selection list, which will be automatically recorded in Vital in addition to the current date and time.
          	</td>
          </tr>				
          <tr>
          	<td>IP consultant</td>
          	<td>
          	  Click the + symbol to select an inpatient consultant for the patient.
          	</td>
          </tr>
          <tr>
          	<td>Searching</td>
          	<td>Use the Search field at the top-right of the main patient table to filter the displayed rows. This is useful if you want to search for a specific patient or doctor etc. It works with the text in any column.</td>
          </tr>
          </table>
        </div>          
      </div>
    </div>
  </div>
  <!--- /Modals --->
  
  <!--- **************************************************************************************************************************** --->
  <!--- Import required javascript and css files --->
  <cfinclude template="includes/bootstrap_JS.cfm">
  <!--- Auto resizes textareas --->
  <script src="js/jquery.autosize.min.js"></script>
  <!--- Used for validating forms --->
  <script src="js/bootstrapValidator.min.js"></script>
  <link rel="stylesheet" href="css/bootstrapValidator.min.css" property="stylesheet" />
  
  <!--- Set timeout library --->
  <script src="js/jquery.ba-dotimeout.min.js"></script>
  <!--- Character counter for textareas --->
  <script src="js/jquery.charactercounter.js"></script>
  <!--- Animation engine --->
  <script src="js/velocity.min.js"></script>
  <script src="js/velocity.ui.js"></script>
  <!--- For the add referral modal datepicker --->
  <link rel="stylesheet" href="css/jquery-ui.min.css" property="stylesheet" />
  <!---
  <script src="js/jquery-ui.min.js"></script>
  <script src="js/jquery-ui.multidatespicker.js"></script>
  <script src="js/bootstrap-list-filter.min.js"></script>
  <script src="js/jquery.maskedinput.js"></script>
  --->
  <!--- Custom error handling script --->
  <script src="js/error.min.js"></script>
  <!--- For encrypting URL parameters --->
  <script src="js/aes.js"></script>
  <script src="js/enc-base64-min.js"></script>
  <!--- Datatable library for enabling column sorting etc. --->
  <script src="js/jquery.dataTables.min.js"></script>
  <link rel="stylesheet" href="css/dataTables.bootstrap.min.css" property="stylesheet" />  
  <!--- Datatables ---> 	
  <link rel="stylesheet" type="text/css" href="css/datatables.min.css"/>
  <script type="text/javascript" src="js/datatables.min.js"></script>
  <script src="js/iconify.min.js"></script>
  <script src="js/bootstrap-notify.min.js"></script>
  <!--- For fixed table header --->
  <script src="js/dataTables.fixedHeader.min.js"></script>
  <link rel="stylesheet" href="css/fixedHeader.bootstrap.min.css">
  
  <style>
    @media print{
      a[href]:after {
        content: none !important;
      }
      
      .dataTable > thead > tr > th[class*="sort"]:before,
      .dataTable > thead > tr > th[class*="sort"]:after {
        content: "" !important;
      }

      #mainTable_filter{display:none !important;}
      
      .label-edd{border:0px !important;text-align:left !Important;}      
    }	       
  </style>
  
  <script>
	//Global variables
	var animationSpeed = 350; //Default animation speed in milliseconds.
    var activeUser = false;
    
    $(document).ready(function(){

      $('[data-toggle="tooltip"]').tooltip();
      
      $('#isbarWardReport').attr('href', 'http://gvhcf01/cfapps/isbar/version_2.2/HandoverWardReportCheckEpisodes_Action.cfm?episodeData=<cfoutput>#ArrayToList(isbarEpisodeNumbers)#</cfoutput>');
      
      <cfif DateDiff("d", '2021-06-09', Now()) LTE 30>
      /**************************************************************************************/ 
      //Show report update modal 
	  if(localStorage.getItem('notify_update09062021_ed') != 'shown'){
        //Show notification        
        bootbox.alert({
	  	  title: '<span class="glyphicon glyphicon-info-sign"></span> New updates',
	  	  closeButton: false,
	  	  message: "Please note that patients with Treatment Refusal, ACP and SDM etc. documents will be flagged beneath the patient's name. Click this warning to view a list of relevant documents with links directly to 3M.",
	  	  callback: function(){
	  	    //Set local storage so that we don't display this alert again    
            localStorage.setItem('notify_update09062021_ed','shown');
	  	  }          
        });
      }
      </cfif>
      
      /**************************************************************************************/
      //Refresh and page timeout stuff.
      //This sets a timer to check if the user has been active since the last page refresh
      //and then either refreshes the page or makes it timeout. The timeout occurs if the 
      //number of minutes since the last user action (keypress of mouse-click) is greater 
      //than the timeout value. The time since the last user action is tracked and stored
      //in local session storage.
       
      var refreshRate = 300;   //Refresh rate for page (in seconds)
      var timeoutMinutes = 60; //Timeout page after x minutes
      var wb = false;          //Whether the report is running as a whiteboard
     
      //Setup the page refresh timer (value in seconds) 
      //var pageTimer = $.timer(function(){
      var pageTimer = setInterval(function(){
      	
      	var fromSessionStorage = 0; //Session storage value      	     	
      	
      	//If not active user, not whiteboard report type, and session storage is supported by the browser
      	if((!activeUser) && (!wb) && (typeof(Storage) !== "undefined")){
      	  //No existing data in session storage 	
      	  if(sessionStorage.getItem("activeUser_EDWhiteBoard") === null) {
            //Set a session storage item and refresh the page
            window.sessionStorage.setItem('activeUser_EDWhiteBoard', refreshRate/60);
            location.href = location.href;
          }
          else{
          	//Existing session storage item exists. Get its value.
            fromSessionStorage = window.sessionStorage.getItem('activeUser_EDWhiteBoard').trim();
         
            //Check that stored value is numeric
            if((!isNaN(fromSessionStorage)) && (fromSessionStorage.trim().length != 0)){
              //If the session value is greater than our timeout value then timeout the page. Otherwise,
              //increment the session value and store it.	
              if(parseFloat(fromSessionStorage) >= timeoutMinutes){
              	//Reset the session value
              	window.sessionStorage.setItem('activeUser_EDWhiteBoard', 0);
              	//Clear the timer
              	clearInterval(pageTimer);
  	         	//Clear the page and display a message to the user
                $('body').empty();
                $('body').html('<div style="margin:15px;"><h2><span class="glyphicon glyphicon-time"></span> ED patients - Timeout</h2><hr /><div class="alert alert-info"><span class="glyphicon glyphicon-info-sign"></span> Page expired after 1 hour of inactivity. Please <a href=""><b>refresh</b></a> your page to continue.</div></div>')                
              }
              else{	
              	//Session value is still less than the timeout value. Increment the session value and refresh the page	              	
                window.sessionStorage.setItem('activeUser_EDWhiteBoard', parseFloat(fromSessionStorage) + (refreshRate/60));
                location.href = location.href;
              }
            }
            else{
              //Existing session value is not a numeric value (shouldn't happen). Reset the session value.
       	      window.sessionStorage.setItem('activeUser_EDWhiteBoard', refreshRate/60);
       	      location.href = location.href;
            }
 	      }
      	}
      	else{
      	  //User is active. Reset session value and refresh the page.	
      	  window.sessionStorage.setItem('activeUser_EDWhiteBoard', 0);	
      	  location.href = location.href;
      	}
      }, refreshRate*1000);
	 
	  //If user has a keypress of mouse-click event then set the status to active. 
	  $(document).on('keypress click', function(){
        activeUser = true;	
      });

      /**************************************************************************************/
      //Upates the LOS time values each minute
      setInterval(function(){
        $('.los').each(function(e){
      	  
      	  var thisLOS = $(this).text(); //Get the current LOS value     	
      	  var losArray = thisLOS.split(" "); //Split the LOS into the hours and mintes components
      	
      	  //Make sure we have two values (hours, minutes)
      	  if(losArray.length == 2){
      	  	//Get rid on any non-numeric character from each value
      	    var hours = losArray[0].replace(/\D/g, '');
      	    var minutes = losArray[1].replace(/\D/g, '');
      	  
      	    //Make sure both values are integers so we can perform our calculation
      	    if((hours.toString() === parseInt(hours, 10).toString()) && (minutes.toString() === parseInt(minutes, 10).toString())){
      	  	  //Update the hours and minutes values as required
      	      if(minutes == 59){
      	        minutes = 0;
      	        hours = parseInt(hours) + 1;	
      	      }	
      	      else{
      	  	    minutes = parseInt(minutes) + 1;
      	      }

              //Update the display with the new time value
              $(this).text(hours + 'h ' + minutes + 'm');
            }
          }	
        });
      }, 60000);
    
      /**************************************************************************************/
      //
      $('#totalTriage').text('<cfoutput>#totalTriage#</cfoutput>');
      $('#totalWaiting').text('<cfoutput>#totalWaiting#</cfoutput>');
      $('#totalED').text('<cfoutput>#totalED#</cfoutput>');
      $('#totalSOU').text('<cfoutput>#totalSOU#</cfoutput>');
      
	  /**************************************************************************************/
	  //
	  $('.toggleSituation').on('click', function(e){
	    e.preventDefault();
	    
	    var episodeNo = $(this).attr("data-episodeNo");
	    var expandText = $(this).attr("data-expandText");
	    //$('#situation_' + episodeNo).text(expandText);
	    
	    var val = $(this).text();

        if(val == "[expand]"){
  	      $('#situation_' + episodeNo).css('white-space', 'wrap');
          $('#situation_' + episodeNo).css('height', '100%');
          $(this).text("[collapse]");
        }
        else{
          $('#situation_' + episodeNo).css('height', '20');
          $(this).text("[expand]");
        }	     	
	  });

      var dTable = $('#mainTable').DataTable({
      	fixedHeader: true,
      	"paging": false,
      	"info":   true,
      	"bFilter": true,
      	stateSave: false,
      	"order": [],
      	"columnDefs": [
      	  {"orderable": false, "targets": [0,4,11,12,13]}
        ]     
      });
      
      $('#mainTable').on('click', 'span.expandRow', function(e){
        
        e.preventDefault();
        
      	var tr = $(this).closest('tr');
      	var row = dTable.row(tr);
        var ur = $(this).attr('data-ur');
        var episodeNo = $(this).attr('data-episodeNo');
        var episodeType = $(this).attr('data-episodeType');
        
        if(row.child.isShown()){
          //This row is already open - close it
          $('div.patientDetailsSlider', row.child()).slideUp(function(){
            row.child.hide();
            tr.removeClass('shown');
          });
          
          $(this).removeClass('glyphicon-chevron-up');
          $(this).addClass('glyphicon-chevron-down');
        }
        else{
          //Open this row
          row.child('<h5><b>Loading...</b></h5><div class="progress"><div class="progress-bar progress-bar-striped active" role="progressbar" aria-valuenow="100" aria-valuemin="0" aria-valuemax="100" style="width: 100%"><span class="sr-only">100% Complete</span></div></div>').show();
          tr.addClass('shown');           
          
          //Update the icon
          $(this).removeClass('glyphicon-chevron-down');
          $(this).addClass('glyphicon-chevron-up');
          
          //Get the patient details
          $.ajax({
            type: 'GET',
            cache: false,
            url: 'includes/WhiteboardPatientDetails_Action.cfm?episodeNo=' + episodeNo + '&episodeType=' + episodeType + '&ur=' + ur,
            success: function(response){
              //Add the returned html to the table row	               
              row.child(response, 'td-dataTable-child');   
              
              //Display the row
              $('div.patientDetailsSlider', row.child()).slideDown();                                   
            },
            error: function(xhr, status, error){	
              row.child('<span class="glyphicon glyphicon-warning-sign"></span> <b>Error:</b> Could not load patient details.', 'danger text-danger');              
            }
          });
        }
      });

      /**************************************************************************************/
      //Animate alerts and flags for better visability
	  $('.alert-animate').velocity("callout.pulse", {stagger: 400});

      /**************************************************************************************/
      //Don't allow direct user input in readonly fields
      $('.readonly').focus(function(){
        this.blur();
      });

      /**************************************************************************************/
      //Show the 'back to top' button when required when the user stops scrolling
	  $(window).scroll(function(){

        $.doTimeout( 'scroll', 250, function(){
          if($(this).scrollTop() > 100){
       	    //Show the button
            $('#back-to-top').fadeIn();
          }
          else{
      	    //Hide the button
            $('#back-to-top').fadeOut();
          }
        });
      });

      //Scroll body to 0px on click
      $('#back-to-top').click(function(){
        //Scroll back to the top of the page
        $("html, body").animate({ scrollTop: 0 }, 400);
        return false;
      });           

      $('#back-to-bottom').click(function(){
        //Scroll to the bottom of the page
        $("html, body").animate({scrollTop: $(document).height()}, 400);
        return false;
      }); 
      
    /**************************************************************************************/
    //Auto-resize all of the textareas to accomodate their contents
    $('textarea').autosize();
      
      //IE likes to cache modal content so we need to update a 'nocache' parameter in the relevant URL's
      //so that IE is forced to update the modal's content.   
      $('.btn-openModal').click(function(e){
        $(this).attr("href", function(_, val){
          return val.replace(/(nocache=)[0-9]+/, 'nocache=' + new Date().getTime());
        });
      });
    });
        
    /**************************************************************************************/
	//Open a modal window with dynamic content.
	$("body").on("click", ".btn-openModal", function(e){

      e.preventDefault();

      //Get the modal window that we want to open.
      var thisDataTarget = $(this).attr('data-target');
        
      //Get the URL that we want to open in the modal.
      var thisModalHref = $(this).attr("href");
       
      //Load the url and show modal on success
      $(thisDataTarget + " .modal-content").load(thisModalHref, function(){ 
        $(thisDataTarget).modal("show");          
      });
    });    
    
    /**************************************************************************************/
	//Limit textarea input to the number of characters defined in the maxlength attribute.
	function limitTextarea(){
      $("textarea[maxlength]").bind('input propertychange', function(){  
      	//Get the textarea's maxlength value
        var maxLength = $(this).attr('maxlength');  
      
        //If the current number of characters exceeds the defined maxlength then subtract the 
        //required amount of characters from the end of the string.
        if($(this).val().length > maxLength){  
          $(this).val($(this).val().substring(0, maxLength));  
        }  
      }); 
	}
	
    /**************************************************************************************/
	// 	
	$("#patientDetailsModal").on("hidden.bs.modal", function(){
      $('#patientDetailsModal .modal-header').remove();
      $('#patientDetailsModal .modal-body').html('<h5><b>Loading...</b></h5><div class="progress"><div class="progress-bar progress-bar-striped active" role="progressbar" aria-valuenow="100" aria-valuemin="0" aria-valuemax="100" style="width: 100%"><span class="sr-only">Loading...</span></div></div>');
      $('#patientDetailsModal .modal-footer').remove();
    });
	
	/**************************************************************************************/
	// 	
	$("#iframeModal").on("hidden.bs.modal", function(){      
      $('#iframeModal .modal-body').html('<h5><b>Loading...</b></h5><div class="progress"><div class="progress-bar progress-bar-striped active" role="progressbar" aria-valuenow="100" aria-valuemin="0" aria-valuemax="100" style="width: 100%"><span class="sr-only">Loading...</span></div></div>');
    });
    
    /**************************************************************************************/
	// 
	$('body').on('click', '.iframeLink', function(e){
	  e.preventDefault();
	  
	  $('.modal').modal('hide');
	  
	  var thisHref = $(this).attr('href');
	  var thisModal = $(this).attr('data-modalTarget');
	  
	  $('#loadingModal').modal('show');
	  
	  $('#' + thisModal + ' .modal-body').html('<iframe src="' + thisHref + '" style="width:100%;height:800px;" frameBorder="0" onLoad="swapModals();"></iframe>');	  	 
	});	
	
	function swapModals(){
	  $('#loadingModal').modal('hide');
	  $('#iframeModal').modal('show');	
	}
    
    /**************************************************************************************/
    //Runs when the addDoctorModal window is shown
	$('#addDoctorModal').on('shown.bs.modal', function(e){
      	  
	  //Apply form validation	  
	  $('form').bootstrapValidator().on('success.form.bv', function(e){
	    e.preventDefault();

	    var episodeNo = $("#updateEdDoctor :input[name='episodeNo']").val(); 
	    var edDoctor = $("#updateEdDoctor :input[name='edDoctor']").val();
	    var edDoctorInitials = $("#edDoctor option:selected").attr('data-doctorInitials');
        var urgency = $("#updateEdDoctor :input[name='urgency']").val();
        var insert = $("#updateEdDoctor :input[name='insert']").val();  
        
	    //Ajax call to insert the request.            
        $.ajax({
          type: 'GET',
          cache: false,
          url: 'includes/WhiteboardUpdateDoctor_Action.cfm?episodeNo=' + episodeNo + '&newEDDoctor=' + edDoctor + '&urgency=' + urgency + '&insert=' + insert + '&ajax=true',
          success: function(response){ 
            //Hide the modal window	            
            $('#addDoctorModal').modal('hide');
            
            if(response.trim() === 'Finished'){
	          $.notify({
	            // options
	            icon: 'glyphicon glyphicon-info-sign',
	            message: 'Doctor updated successfully.'	      
              },{
	            // settings
	            type: 'success'
              });
              
              $('#doctor_' + episodeNo).text(edDoctorInitials);          
	        }
	        else{
	          $.notify({
	            // options
	            icon: 'glyphicon glyphicon-warning-sign',
	            message: '<b>Error:</b> Doctor could <b>not</b> be updated. Please refresh the page and try again.'	      
              },{
	            // settings
	            type: 'danger'
              });	
	        }                       
          },
          error: function(xhr, status, error){
            //Something went wrong with the Ajax call and the event wasn't cancelled.
            processError(xhr.status, xhr.responseText, "WhiteboardUpdateDoctor_Action.cfm", "We're really sorry, but it looks like something went wrong while trying to update the EDD.");            
          }
        });              
      });          
    });
    
    /**************************************************************************************/
    //Runs when the addIPDoctorModal window is shown
	$('#addIPDoctorModal').on('shown.bs.modal', function(e){
      	  
	  //Apply form validation	  
	  $('form').bootstrapValidator().on('success.form.bv', function(e){
	    e.preventDefault();

	    var episodeNo = $("#updateIPDoctor :input[name='episodeNo']").val(); 	    
	    var ipDoctor = $("#updateIPDoctor :input[name='ipDoctor']").val();
	    var ipDoctorInitials = $("#ipDoctor option:selected").attr('data-doctorInitials');
        var urgency = $("#updateIPDoctor :input[name='urgency']").val();
        var insert = $("#updateIPDoctor :input[name='insert']").val();  
                
        //Ajax call to insert the request.            
        $.ajax({
          type: 'GET',
          cache: false,
          url: 'includes/WhiteboardUpdateIPDoctor_Action.cfm?episodeNo=' + episodeNo + '&ipDoctor=' + ipDoctor + '&urgency=' + urgency + '&insert=' + insert + '&ajax=true',
          success: function(response){ 
            //Hide the modal window	
	        $('#addIPDoctorModal').modal('hide');   
	          
	        if(response.trim() === 'Finished'){
	          $.notify({
	            // options
	            icon: 'glyphicon glyphicon-info-sign',
	            message: 'Doctor updated successfully.'	      
              },{
	            // settings
	            type: 'success'
              });
              
              $('#ipDoctor_' + episodeNo).text(ipDoctorInitials);
              $('#ipDoctorTime_' + episodeNo).text('');          
	        }
	        else{
	          $.notify({
	            // options
	            icon: 'glyphicon glyphicon-warning-sign',
	            message: '<b>Error:</b> Doctor could <b>not</b> be updated. Please refresh the page and try again.'	      
              },{
	            // settings
	            type: 'danger'
              });	
	        }                    
          },
          error: function(xhr, status, error){
            //Something went wrong with the Ajax call and the event wasn't cancelled.
            processError(xhr.status, xhr.responseText, "WhiteboardUpdateIPDoctor_Action.cfm", "We're really sorry, but it looks like something went wrong while trying to update the EDD.");            
          }
        });
      });          
    });
    
    /**************************************************************************************/
    //Runs when the addDoctorModal window is shown
	$('.reviewStatus').on('change', function(e){
	  e.preventDefault();
	  
	  var edRefNo = $(this).attr('data-edRefNo');
	  var reviewStatus = $(this).val();
	  var thisDateTime = new Date();
	  var thisTime = thisDateTime.getHours() + ':' + thisDateTime.getMinutes();	
	  
	  //Ajax call to insert the request.            
      $.ajax({
        type: 'GET',
        cache: false,
        url: 'includes/WhiteboardReviewStatus_Action.cfm?EdRefNo=' + edRefNo + '&ReviewStatus=' + encodeURIComponent(reviewStatus) + '&ajax=true',
        success: function(response){ 
          
          if(response.trim() === 'Finished'){
	        $.notify({
	          // options
	          icon: 'glyphicon glyphicon-info-sign',
	          message: 'Referral status updated.'	      
            },{
	          // settings
	          type: 'success'
            });
              
            $('#refTime_' + edRefNo).text(thisTime); 		                  
	      }
	      else{
	        $.notify({
	          // options
	          icon: 'glyphicon glyphicon-warning-sign',
	          message: '<b>Error:</b> Referral status could <b>not</b> be updated. Please refresh the page and try again.'	      
            },{
	          // settings
	          type: 'danger'
            });	
	      }                          
        },
        error: function(xhr, status, error){
          //Something went wrong with the Ajax call and the event wasn't cancelled.
          processError(xhr.status, xhr.responseText, "WhiteboardReviewStatus_Action.cfm", "We're really sorry, but it looks like something went wrong while trying to update the EDD.");            
        }
      });
	});	
	
    /**************************************************************************************/
    //Runs when the addDoctorModal window is shown
	$('#bedBookingModal').on('shown.bs.modal', function(e){

      $('#toWard').on('change', function(e){
                
        var toWard = $('#toWard').val();

        $('.bedType').hide();
        
        if(toWard === 'ICU'){
          $('#bedType_12').show();	
          $('#bedType_13').show();
          $('#bedType_10').show();
          $('#bedType_11').show();
          $('#bedType_5').show();
          $('#bedType_14').show();          
        }
        else if(toWard === 'PAED'){
          $('#bedType_7').show();	
          $('#bedType_5').show();
          $('#bedType_6').show();
          $('#bedType_3').show();
          $('#bedType_0').show();	
        } 
        else if(toWard === 'MED'){
          $('#bedType_4').show();	
          $('#bedType_5').show();
          $('#bedType_6').show();
          $('#bedType_3').show();
          $('#bedType_0').show();	
          $('#bedType_9').show();
          $('#bedType_14').show();
        }	
        else if(toWard === 'SOU' || toWard === 'MH' || toWard === ''){
          //
        }
        else{
          $('#bedType_4').show();	
          $('#bedType_5').show();
          $('#bedType_6').show();
          $('#bedType_3').show();
          $('#bedType_0').show();	         
          $('#bedType_14').show();
        }
      });
      	  
	  //Apply form validation	  
	  $('form').bootstrapValidator().on('success.form.bv', function(e){
	    e.preventDefault();

        var thisData = $(this).serialize();
                
	    var patID = $("#bedBooking :input[name='patId']").val(); 
	    var toWard = $("#bedBooking :input[name='toWard']").val();	    
        var bedType = $("#bedBooking [name='BedType']:checked");

	    //Ajax call to insert the request.            
        $.ajax({
          type: 'GET',
          cache: false,
          url: 'includes/WhiteboardBedBooking_Action.cfm',
          data: thisData, 
          success: function(response){ 
          	//Hide the modal window
          	$('#bedBookingModal').modal('hide'); 
          	
          	if(response.trim() === 'Finished'){
	          $.notify({
	            // options
	            icon: 'glyphicon glyphicon-info-sign',
	            message: 'Bed booking submitted.'	      
              },{
	            // settings
	            type: 'success'
              });
              
              $('#bedBooking_' + patID).html('<span class="label label-info">' + toWard + ' - Just booked</span>')              		                 
	        }
	        else{
	          $.notify({
	            // options
	            icon: 'glyphicon glyphicon-warning-sign',
	            message: '<b>Error:</b> Bed booking could <b>not</b> be made. Please refresh the page and try again.'	      
              },{
	            // settings
	            type: 'danger'
              });	
	        }               	                                
          },
          error: function(xhr, status, error){
            //Something went wrong with the Ajax call and the event wasn't cancelled.
            processError(xhr.status, xhr.responseText, "WhiteboardBedBooking_Action.cfm", "We're really sorry, but it looks like something went wrong while trying to process this request.");            
          }
        });
      });          
    });
    
    <cfif !URL.covid and !URL.arconly>
    /**************************************************************************************/
	// 
    if(sessionStorage.getItem("edemptybedsview") === "false"){
      document.getElementById("emptyBedsTable").style.display = "none";
      document.getElementById("toggleEmptyBeds").innerHTML = "Show";
    }  
    else if(sessionStorage.getItem("edemptybedsview") === "true"){
      document.getElementById("emptyBedsTable").style.display = "block";
      document.getElementById("toggleEmptyBeds").innerHTML = "Hide";
    }  		
    else{
  	  document.getElementById("toggleEmptyBeds").innerHTML = "Show";
    }  	
  
    /**************************************************************************************/
	// 
	$('#toggleEmptyBeds').on('click', function(e){
	  e.preventDefault();

	  $('#emptyBedsTable').toggle();	  
	  	  
	  if($(this).text() === 'Hide'){
	    $(this).text('Show');
	    
	    sessionStorage.setItem('edemptybedsview', 'false');
	  }
	  else{
	  	$(this).text('Hide');
	  	
	  	sessionStorage.setItem('edemptybedsview', 'true');
	  }	  	 
	});
	
	/**************************************************************************************/
	// 
    if (sessionStorage.getItem("edemptycubicles") === "false"){
      document.getElementById("emptyCubicles").style.display = "none";
      document.getElementById("toggleEmptyCubicles").innerHTML = "Show";
    }
    else if (sessionStorage.getItem("edemptycubicles") === "true"){
      document.getElementById("emptyCubicles").style.display = "block";
      document.getElementById("toggleEmptyCubicles").innerHTML = "Hide";
    }  	
    else{
  	  document.getElementById("toggleEmptyCubicles").innerHTML = "Show";
    }  	
  
    /**************************************************************************************/
	// 
	$('#toggleEmptyCubicles').on('click', function(e){
	  e.preventDefault();

	  $('#emptyCubicles').toggle();	  
	  	  
	  if($(this).text() === 'Hide'){
	    $(this).text('Show');
	    
	    sessionStorage.setItem('edemptycubicles', 'false');
	  }
	  else{
	  	$(this).text('Hide');
	  	
	  	sessionStorage.setItem('edemptycubicles', 'true');
	  }	  	 
	});
    </cfif>
	
    /**************************************************************************************/
	//
	function getMedicalImagingStatus(){
	  
	  var miList = <cfoutput>'#miList#'</cfoutput>;

      $.ajax({
	  	url: 'includes/MedicalImagingGetStatusV2_Action.cfm?patDetails=' + miList, 
	  	success: function(result){

          var resultArray = result.trim().split(',');
          
          $.each(resultArray, function(i){
          	
          	var details = resultArray[i].split('|');
          	
          	if(details.length === 3){
          	  if(details[2] === 'Images Ready'){
       	        $('#mi-' + details[1]).addClass('text-success');	
          	  }
          	  else if(details[2] === 'In progress'){
       	        $('#mi-' + details[1]).addClass('text-danger');	
          	  }
          	  else if(details[2] === 'New request'){
       	        $('#mi-' + details[1]).addClass('text-info');	
          	  }
          	  else if (details[2] === 'Read'){
          	  	$('#mi-' + details[1]).html('<span class="glyphicon glyphicon-list-alt" style="font-size:0.8em;padding-left:2px;"></span>');
          	  }
          	}
          });
        }
      });		
	}
	
	getMedicalImagingStatus();

	/**************************************************************************************/
	//Get the Refusal of Treatment status and update the display where necessary.
	function getRefusalTreatStatus(){
	  
	  var urList = <cfoutput>'#urList#'</cfoutput>;

      $.ajax({
	  	url: 'includes/RefusalTreat_Action.cfm?urList=' + urList, 
	  	success: function(result){
 
          var resultArray = result.trim().split(',');
          
          $.each(resultArray, function(i){
            $('#patname_' + resultArray[i]).append('<br /><a href="includes/RefusalTreat_Form.cfm?ur=' + resultArray[i] + '" data-target="#refusalTreatModal" class="btn-openModal text-danger" style="font-weight: normal;" title="Check record for Refusal of Treatment, Advanced Care Plan, and Substitute Decision Maker">TreatRefusal,ACP,SDM</a>');   	       
          });
         }
      });		
	}
	
	getRefusalTreatStatus();
	
	/**************************************************************************************/	
	//Show full text when clicked for editing. 
	$('.editThis').on('mousedown', function(e){
		
	  if($(this).is(":focus")){	
	    //
	  }
	  else{	
	  	//If contenteditable container does not already have focus, display the full text for the user to edit.
	  	var charsExceeded = $(this).attr('data-situationCharsExceeded');
	  	
	  	if(charsExceeded === 'true'){
	  	  var thisOriginalText = $(this).attr('data-originalText').trim().replace(/<br \/>/gi, '\r\n');
	  	
	  	  $(this).text(thisOriginalText);
	  	}
	  }  	
	});	
	
	/**************************************************************************************/
	$('.cancelBedBooking').on('click', function(e){
	  e.preventDefault();
	  
	  var thisHref = $(this).attr('href');
	  
	  bootbox.confirm({
	  	title: "Confirm",
	  	message: "Are you sure you want to cancel this bed booking?", 
	  	callback: function(result){ 
          if(result){
            window.location = thisHref;
          }
        }
      });	
	});
	
	/**************************************************************************************/
      $('.editThis').on('blur', function(e){
      	e.preventDefault();
      	
      	var _this = $(this);
      	
      	var thisOriginalText = $(this).attr('data-originalText').trim().replace(/<br \/>/gi, '\r\n');
      	var thisEventText = $(this).text().trim().replace(/<\/div>|<\/p>/gi, '').replace(/<div>|<p>|<br>/gi, '\r\n').replace(/\&amp\;nbsp\;/gi, '').replace(/\&nbsp\;/gi, '');
      	
      	if((thisEventText != thisOriginalText) && (thisEventText.replace(/\s/g, '').length > 0)){
      		      	
      	  var thisEpisodeNo = $(this).attr('data-episodeNo');
      	  var thisEpisodeType = $(this).attr('data-episodeType');      	
      	  var thisUserType = $(this).attr('data-userType');
      	  var thisEventType = $(this).attr('data-eventType');
          var thisMaxLength = $(this).attr('data-maxLength');
          var thisEpisodeNoUnencrypted = $(this).attr('data-episodeNoUnencrypted');          
          
          if(thisEventText.length > thisMaxLength){
          	bootbox.alert({
           	  title: "Character limit exceeded",
              message: "Sorry, you have exceeded the character limit for this field (" + (thisEventText.length - thisMaxLength) + " characters over). Please remove some text and try again.",
              closeButton: false
            });
            
          	return;
          }
          
      	  $.ajax({
      	    url: 'EventAdd_Action.cfm?episodeNo=' + thisEpisodeNo + '&episodeType=' + thisEpisodeType + '&eventType=' + encodeURIComponent(thisEventType) + '&userType=' + encodeURIComponent(thisUserType) + "&eventText=" + encodeURIComponent(thisEventText) + '&ajax=true',
      	    success: function(response){
      	  	
      	  	  $.notify({
	            // options
	            icon: 'glyphicon glyphicon-info-sign',
	            message: 'Text updated successfully'	      
              },{
	            // settings
	            type: 'success'
              });
              
              $('#situationLabel_' + thisEpisodeNoUnencrypted).html('<b>SIT:</b>');
              $('#situationPrint_' + thisEpisodeNoUnencrypted).text(thisEventText);
              
              _this.attr('data-originalText', thisEventText);
      	    },
      	    cache: false	
      	  }).fail(function(jqXHR, textStatus, error){
      	    //console.log(error);
      	  
      	    $.notify({
	          // options
	          message: '<b>Error:</b> Text could <b>not</b> be updated. Please refresh the page and try again.' 
            },{
	          // settings
	          icon: 'glyphicon glyphicon-warning-sign',
	          type: 'danger'
            });
      	  }); 	
        }
      });
      
      
  </script>
</body>
</html>    

<!---
<cffile action="append" file="#ExpandPath('test\edlog.txt')#" output="#DateFormat(Now(), 'dd-mmm-yyyy')# #TimeFormat(Now(), 'HH:mm:ss')#:#CGI.Auth_User#">
--->

