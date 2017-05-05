/* ---------------------- Euro-Mit Staal bv Vlissingen -------------------------
                                                                                
  File        : t/ttrulsord.p                                                   
  Description :                                                                 
  Created     : 12/12/06 Alex Leenstra                                          
                                                                                
Date     Author      Version Description                                             
-------- ------      ------- --------------------------------------------------------
12/12/06 AlexL       1.00    Created
05/02/10 Nandeshwar  1.02    EMM5-0467: Removed the logic that changed "pw-date" on leaving of field "Truck ETD"   
25/02/10 Mohan       1.03    EMM5-0689:- Changed the logic to display the docs on p-rowdisplay event, Previous logic was wrong.  
11/09/15 Amity       1.03    [EMM6-0026] Force system to check IMA box in “trucks”. show warning while changing the Neu and Eu documents check boxes.                                        
------------------------------------------------------------------------------*/

function f-getcbs returns char (p-ttruc as char) forward.
function f-determinePW returns date (p-etd as date) forward.
function FN-cargo returns integer (vttruc as char) forward.   
  
                                                                                         
{x/xxxxlparam.i}                                                                         

PROCEDURE p-rowdisplay:
  /*------------------------------------------------------------------------------
      Field: v-browse01                                                           
      Event: ROW-DISPLAY                                                          
  --------------------------------------------------------------------------------
    Purpose: 
      Notes: Mohan,EMM5-0689:- Changed the logic to display the docs, Previous logic was wrong.                                                                      
    Created: 12/12/06 Alex Leenstra                                               
  ------------------------------------------------------------------------------*/

  define variable v-dag       as char no-undo. 
  define variable v-Cargo     as inte  no-undo.
  define variable v-docs      as char no-undo. 
  define variable v-status    as char no-undo. 
  define variable v-job       as char no-undo. 
  define variable v-comb      as char no-undo.
  define variable v-truck     as char no-undo. 
  define variable v-ttruttrnr as char no-undo. 
  
  find first ttru no-lock where rowid(ttruck) = p-rowid no-error.

  for each cpal no-lock where cpal.xlevc = f-xlevc('cpallet') 
  and cpal.ttruc = ttru.ttruc:
    assign v-Cargo = v-Cargo + cpal.cpalngrossweight.
  end.
  
  find first sord no-lock where sord.xlevc = f-xlevc('sorder') and sord.sordn = ttru.sordn no-error. 
  assign
    v-job       = sord.gjobc 
    v-ttruttrnr = ttru.ttruttrnr
    v-truck     = ttru.ttruc
    v-comb      = ttru.ttrutcombination 
    v-dag       = entry(weekday(ttru.ttrudexems),'Su,Mo,Tu,We,Th,Fr,Sa')  
    v-status    = entry(1,f-xstadisp("ttruck",ttru.xstac)).

  assign  
    v-docs = (if not ttru.ttrulloprinted then "LO-" else "")
    v-docs = v-docs + (if ttru.ttrulpacklist and not ttru.ttrulplprinted then "PL-" else "")
    v-docs = v-docs + (if ttru.ttrulcmr and not ttru.ttrulcmrprinted then "CMR-" else "")
    v-docs = v-docs + (if ttru.ttruleu1 and ttru.tdocc = '' then "EUA" else "")
    v-docs = v-docs + (if ttru.ttrulex1 and ttru.tdocc = '' then "EXA" else "")
    v-docs = v-docs + (if ttru.ttrult1 and ttru.tdocc = '' then "T1" else "")
    v-docs = v-docs + (if ttru.ttruldocima and ttru.tdocc = '' then "IMA" else "")
    .

  assign p-result = 
    'v-truck'     + chr(1) + v-truck         + chr(1) + 
    'v-job'       + chr(1) + v-job           + chr(1) + 
    'v-comb'      + chr(1) + v-comb          + chr(1) + 
    'v-dag'       + chr(1) + v-dag           + chr(1) + 
    'v-cargo'     + chr(1) + string(v-cargo) + chr(1) + 
    'v-status'    + chr(1) + v-status        + chr(1) +       
    'v-ttruttrnr' + chr(1) + v-ttruttrnr     + chr(1) +
    'v-docs'      + chr(1) + v-docs.
    
END PROCEDURE. /* p-rowdisplay */


PROCEDURE p-leave-sordn:
  /*------------------------------------------------------------------------------
       File: ttruck (Trucks)                                                      
      Field: sordn (Order)                                                        
      Event: LEAVE                                                                
  --------------------------------------------------------------------------------
    Purpose:                                                                      
      Notes: - this is fired when adding or copying truck in order mgt
             - this is NOT fired when adding truck in truck mgt
    Created: 13/12/06 Alex Leenstra                                               
  ------------------------------------------------------------------------------*/
  /*message 'ALERT hello from p-leave-sordn in ttrulsord.p' view-as alert-box.*/
  
  define variable v-date as date no-undo.

  find first sord no-lock where sord.xlevc = f-xlevc('sorder') and sord.sordn = integer(f-getvalue('sordn')) no-error.
  find first gcom no-lock where gcom.xlevc = f-xlevc('gcompany') and gcom.gcomn = sord.gcomnclient no-error.
  
  assign v-date = (if sord.sorddetdems LT today then today else sord.sorddetdems).
  assign p-result = 
    'ttrudexems'     + chr(1) + string(v-date)              + chr(1) + 
    'v-destination'  + chr(1) + gcom.gcomm                  + chr(1) + 
    'gcomnforwarder' + chr(1) + string(sord.gcomnforwarder) + chr(1) +   /*THIS LINE MAKES ..some lines elsewhere obsolete ?!? **/
    'gshic'          + chr(1) + sord.gshic                  + chr(1) + 
    'ttrulpacklist'  + chr(1) + 'yes'                       + chr(1) + 
    'ttrulcmr'       + chr(1) + 'yes'                       + chr(1) + 
    'ttruleu1'       + chr(1) + 'false'                     + chr(1) + 
    'ttrulex1'       + chr(1) + 'false'                     + chr(1) + 
    'ttrunmaxweight' + chr(1) + '24000'                     + chr(1) + 
    'ttrudpwdate'    + chr(1) + string(f-determinePW(v-date))
    .

END PROCEDURE. /* p-leave-sordn */


PROCEDURE p-display:
  /*------------------------------------------------------------------------------
      Event: BEFORE-DISPLAY                                                       
  --------------------------------------------------------------------------------
    Purpose:                                                                      
      Notes:                                                                      
    Created: 13/12/06 Alex Leenstra                                               
  ------------------------------------------------------------------------------*/
  /*message 'hello from p-display in ttrulsord.p' view-as alert-box information.*/
 
  define var v-count-truck  as inte no-undo. 
  define var v-total-target as inte no-undo. 
  define var v-total-cargo  as inte no-undo.

  define var v-company      as char no-undo.
  define var v-agentname    as char no-undo. 
  define var v-agent        as char no-undo. 
  
  define var v-lokaties     as char no-undo.  
  define var v-PTypes       as char no-undo. 
  define var v-pallets      as inte no-undo.
  define var v-grosswgt     as inte no-undo.
  define var v-nettwgt      as inte no-undo.

  define var v-minwid       as deci no-undo init 9999.
  define var v-maxwid       as deci no-undo init 0.

  define var v-minmax       as char no-undo.
   
  define variable vCBScode     as char no-undo.
  define variable cbscodes     as char no-undo initial "7226110091,7226110011,7225110010,7212101000,7210122000,7210301000".

  find first ttru no-lock where rowid(ttruc) = p-rowid no-error. 
 
  if available ttru then 
  do:
    
    find first sord no-lock where sord.xlevc = f-xlevc('sorder') and sord.sordn = ttru.sordn no-error.
    assign v-company = sord.sordtpay4tpt. 

    find first gcom no-lock where gcom.xlevc = f-xlevc('gcompany') and gcom.gcomn = sord.gcomnagent no-error.
               
    if available gcom then do:
      assign v-agentname = gcom.gcomtshortname. 
    end.     

    assign p-result = p-result + min(p-result,chr(1)) +   
      'v-sordtpay4tpt' + chr(1) + v-company   + chr(1) + 
      'v-agent'        + chr(1) + v-agentname.                                                             

    for each cpal no-lock where cpal.xlevc = f-xlevc('cpallet')
    and cpal.ttruc = ttru.ttruc 
    break by cpal.glocc:
      find first gpal no-lock where gpal.xlevc = f-xlevc('gpallettype') and gpal.gpalc = cpal.gpalc no-error.
         
      if index(v-PTypes,gpallet.gpalm) = 0 then assign v-PTypes = v-PTypes + minimum(",",v-PTypes) + gpallet.gpalm.
      if first-of(cpal.glocc) then assign v-lokaties = v-lokaties + minimum(",",v-lokaties) + cpal.glocc.
         
      assign 
        v-pallets  = v-pallets + 1
        v-grosswgt = v-grosswgt + cpal.cpalngrossweight.
              
      if sord.sordtproduct NE 'laminations' then do:
      for each ocoi no-lock where ocoi.xlevc = f-xlevc('ocoil')
      and ocoi.cpaln = cpal.cpaln:
        assign 
          v-nettwgt = v-nettwgt + ocoi.ocoinweight
          v-minwid  = if v-minwid GT ocoi.ocoiawidth then ocoi.ocoiawidth else v-minwid
          v-maxwid  = if v-maxwid LT ocoi.ocoiawidth then ocoi.ocoiawidth else v-maxwid.
      end.  /* for each ocoil */
      end.
      else do:
        assign v-nettwgt = v-nettwgt + cpal.cpalngrossweight - cpal.cpalntarra.
      end.
    end.   /* for each cpallet */   
     
    if v-maxwid GT 0 then assign v-minmax = string(v-minwid) + '-' + string(v-maxwid).
    else assign v-minmax = '?'.

    find first sord no-lock where rowid(sorder) = f-getrowid('sorder') no-error.
    find first gcou no-lock where gcou.xlevc = f-xlevc('gcountry') and gcou.gcouc = gcom.gcouc no-error.    
    find first gshi no-lock where gshi.xlevc = f-xlevc('gshipmode') and gshi.gshic = sord.gshic no-error.
    
    /*message '/1/' skip ttru.ttruc view-as alert-box warning.*/
    run proc\FindCbsCodeTrc.p(input ttru.ttruc,input '1',output vCBScode).
    for first gcbsgoodscd no-lock where gcbsgoodscd.xlevc = f-xlevc('gcbsgoodscd')
    and gcbsgoodscd.gcbsc = vCBScode:
      assign vCBScode = vCBScode + " " + gcbsgoodscd.gcbsm.
    end.
    /*message '/2/' skip vCBScode view-as alert-box warning.*/
                       
    assign p-result = p-result  + min(p-result,chr(1)) + 
      'v-lokaties'    + chr(1) + v-lokaties                                            + chr(1) + 
      'v-PType'       + chr(1) + v-PTypes                                              + chr(1) + 
      'v-minmax'      + chr(1) + v-minmax                                              + chr(1) + 
      'v-nettowgt'    + chr(1) + string(v-nettwgt)                                     + chr(1) + 
      'v-grosswgt'    + chr(1) + string(v-grosswgt)                                    + chr(1) + 
      'v-container'   + chr(1) + (if available gship then gship.gshim else sord.gshic) + chr(1) +
      'v-pallets'     + chr(1) + string(v-pallets)                                     + chr(1) + 
      /*OLD*** 'v-goedercode'  + chr(1) + f-getcbs(ttru.ttruc).*/
      'v-goedercode'  + chr(1) + vCbsCode.

    for each ttru no-lock where ttru.xlevc = f-xlevc('ttruck')
    and ttru.sordn = sord.sordn:
      assign v-count-truck  = v-count-truck  + 1. 
      assign v-total-target = v-total-target + ttru.ttrunmaxweight. 
      assign v-total-cargo  = v-total-cargo  + fn-cargo(ttru.ttruc).                               
    end.
    
    assign p-result =  p-result + min( p-result,chr(1)) + 
      'v-ttrucks'    + chr(1) + string(v-count-truck) + chr(1) + 
      'v-cargos'     + chr(1) + string(v-total-cargo) + chr(1) +
      'v-target'     + chr(1) + string(v-total-target).  
  end. 

  find first sord no-lock where rowid(sorder) = f-getrowid('sorder') no-error.
      
  find first gcom no-lock where gcom.xlevc = f-xlevc('gcompany')
  and gcom.gcomn = sord.gcomnclient no-error.
  
  assign p-result = p-result + min(p-result ,chr(1)) + 'v-destination' + chr(1) + (if available gcom then gcom.gcomtshortname else '').

END PROCEDURE. /* p-display */


PROCEDURE p-enable:
  /*------------------------------------------------------------------------------
      Event: AFTER-ENABLE                                                         
  --------------------------------------------------------------------------------
    Purpose:                                                                      
      Notes:                                                                      
    Created: 13/12/06 Alex Leenstra                                               
  ------------------------------------------------------------------------------*/
  define variable v-gcomnforwarder as inte no-undo.
  define variable v-sorddetdems as date no-undo.
  define variable v-ttrudpwdate as date no-undo.

  find first sord no-lock where rowid(sorder) = f-getrowid('sorder') no-error.
  if available sord then 
  do:
    if p-mode LT 3 then 
    do:
      find first scdm no-lock where scdm.xlevc = f-xlevc('scdm') and scdm.gcomnclient = sord.gcomnclient no-error. 
      run p-leave-sordn.
      assign
        v-gcomnforwarder = if available scdm then scdm.gcomnforwarder else 0
        v-sorddetdems = sord.sorddetdems
        v-ttrudpwdate = f-determinePW(sord.sorddetdems).
      assign v-gcomnforwarder = sord.gcomnforwarder. /* ECL.13.2.2014.this makes more sense, yet users indicated truck should always get customer-default */
    end.
  end.
  
  assign p-result = 
    'gcomnforwarder' + chr(1) + string(v-gcomnforwarder) + chr(1) + 
    'ttrudexems'     + chr(1) + string(v-sorddetdems)    + chr(1) + 
    'ttrudpwdate'    + chr(1) + string(v-ttrudpwdate)    + chr(1) +
    'sordn'          + chr(1) + string(sord.sordn).
  
  if p-mode LT 3 then assign p-result = p-result + chr (1) + 'ttrulloprinted' + chr (1) + 'no'.

END PROCEDURE. /* p-enable */


function f-getcbs returns char 
  (p-ttruc as char):
  /*****************************************************************************
  Purpose: bepaal cbs-goederencode
  Author: eric, 2.10.2003
  Called by: run proc\FindCBScode.p(input ttruck,output value) 
  Notes:
  - codes zijn gewijzigd, EL is nu twee categorieen, voor gemak hier dezelfde code tweemaal opgenomen
  
  !! this function is no longer required, a global proc now is used .ecl.10.11.2014.
 *****************************************************************************/ 
  define variable Returnvalue as char no-undo.
  define variable v-cbscodes  as char no-undo initial "72261100,72261100,72251100,72121010,72101220,72103010".
  define variable vCode       as inte no-undo extent 6 initial 0.

  for each cpal no-lock where cpal.xlevc = f-xlevc('cpallet')
  and cpal.ttruc = p-ttruc,
  each ocoi no-lock where ocoi.xlevc = f-xlevc('ocoil')
  and ocoi.cpaln = cpal.cpaln:
               
    if ocoil.gjobc = "S" then 
    do:
      if ocoi.ocoiawidth LE 500                            then assign vCode[1] = vCode[1] + 1.
      if ocoi.ocoiawidth GT 500 and ocoi.ocoiawidth LT 600 then assign vCode[2] = vCode[2] + 1.
      if ocoi.ocoiawidth GE 600                            then assign vCode[3] = vCode[3] + 1.
    end.
    if ocoil.gjobc = "T" and (ocoil.ggrac = "TPDR7BA" or ocoil.ggrac = "TPDR7BA22") then 
    do:
      if ocoil.ocoiawidth LT 600 then assign vCode[4] = vCode[4] + 1.
      if ocoil.ocoiawidth GE 600 then assign vCode[5] = vCode[5] + 1.
    end.
    if ocoil.gjobc = "T" and (ocoil.ggrac = "EGNSC700") then 
    do:
      assign 
        vCode[6] = vCode[6] + 1.
    end.
  end.

  if maximum(vCode[1],vCode[2],vCode[3],vCode[4],vCode[5],vCode[6]) = 0 then returnvalue = "?".
  else if vCode[1] = maximum(vCode[1],vCode[2],vCode[3],vCode[4],vCode[5],vCode[6]) then returnvalue = entry(1,v-cbscodes).
    else if vCode[2] = maximum(vCode[1],vCode[2],vCode[3],vCode[4],vCode[5],vCode[6]) then returnvalue = entry(2,v-cbscodes).
      else if vCode[3] = maximum(vCode[1],vCode[2],vCode[3],vCode[4],vCode[5],vCode[6]) then returnvalue = entry(3,v-cbscodes).
        else if vCode[4] = maximum(vCode[1],vCode[2],vCode[3],vCode[4],vCode[5],vCode[6]) then returnvalue = entry(4,v-cbscodes).
          else if vCode[5] = maximum(vCode[1],vCode[2],vCode[3],vCode[4],vCode[5],vCode[6]) then returnvalue = entry(5,v-cbscodes).
            else returnvalue = entry(6,v-cbscodes).

  return returnvalue.

end function.


function f-determinePW returns date
  (p-etd as date ) :
  /*------------------------------------------------------------------------------
    Purpose:  determine pw-date of truck
      Notes:  
  ------------------------------------------------------------------------------*/
  define variable pwdatum as date no-undo.
  
  /* REVISED DD 5-6-2003 : DETERMINE PWDATUM, DEFAULT 2 WORKING DAYS */
   
  assign pwdatum = p-etd - 2. 
   
  if weekday(pwdatum) = 1 /* sunday */   then pwdatum = pwdatum - 2.
  if weekday(pwdatum) = 7 /* saturday */ then pwdatum = pwdatum - 2.

  return pwdatum.   /* Function return value. */

end function.
 

PROCEDURE p-load-company:
/*------------------------------------------------------------------------------
    Event: BEFORE-DISPLAY                                                       
--------------------------------------------------------------------------------
  Purpose:                                                                      
    Notes:                                                                      
  Created: 22/02/07 Dipesh Maharjan                                             
------------------------------------------------------------------------------*/

END PROCEDURE. /* p-load-company */


function FN-cargo returns integer (vttruc as char):
  /*------------------------------------------------------------------------------
    Purpose:  return gross weight
      Notes:  
  ------------------------------------------------------------------------------*/
  define variable returnvalue as inte no-undo initial 0.
 

  for each cpal no-lock where cpal.xlevc = f-xlevc('cpallet')
  and cpal.ttruc = vttruc
  and cpal.xstac = '300':
    assign returnvalue = returnvalue + cpal.cpalnGrossWeight.
  end.
  
  return returnvalue.   /* Function return value. */

end function.


PROCEDURE p-cal-total:
/*------------------------------------------------------------------------------
    Event: BEFORE-DISPLAY                                                       
--------------------------------------------------------------------------------
  Purpose:                                                                      
    Notes:                                                                      
  Created: 22/02/07 Dipesh Maharjan                                             
------------------------------------------------------------------------------*/
END PROCEDURE. /* p-cal-total */


procedure p-value-ttrult1:
/*------------------------------------------------------------------------------
  File   : ttruck (Truck)                                                       
    Field: ttrult1 (T1)                                                         
    Event: VALUE-CHANGED                                                        
--------------------------------------------------------------------------------
  Purpose:                                                                      
    Notes:                                                                      
  Created: 15/04/16 Eric Clarisse  
  updated: 11/09/15 Amity timalsina                                             
------------------------------------------------------------------------------*/

  if p-value = 'yes' then assign p-result = 
    'ttruldocima' + chr(1) + 'no'. /* Amity : [EMM6-0026] not to check ima*/
    
END PROCEDURE. /* p-value-ttrult1 */

procedure p-value-ttruldocima:
/*------------------------------------------------------------------------------
  File   : ttruck (Truck)                                                       
    Field: ttruldocima (IMA)                                                         
    Event: VALUE-CHANGED                                                        
--------------------------------------------------------------------------------
  Purpose: to check the t1 widgets.                                                                     
    Notes:                                                                      
  Created: 09/10/2015 Amity timalsina [EMM6-0026] not to check t1                                             
------------------------------------------------------------------------------*/

  if p-value = 'yes' then assign p-result = 
    'ttrult1' + chr(1) + 'no'.
    
END PROCEDURE. /* p-value-ttrult1 */

PROCEDURE p-value-ttruleu1:
  /*------------------------------------------------------------------------------
       File: ttruck (Trucks)                                                      
      Field: ttruleu1 (EU1)                                                       
      Event: VALUE-CHANGED                                                        
  --------------------------------------------------------------------------------
    Purpose:                                                                      
      Notes:                                                                      
    Created: 07/07/20 Alex Leenstra  
    updated: 11/09/15 Amity timalsina  [EMM6-0026] not to check ex1                                            
  ------------------------------------------------------------------------------*/

  /*if p-value = 'yes' then assign p-result = 'ttrulex1' + chr(1) + 'no'.*/
  if p-value = 'yes' then assign p-result = 
    'ttrulex1' + chr(1) + 'no' . /* amity : [EMM6-0026] not to check ex1*/
  
END PROCEDURE. /* p-value-ttruleu1 */


PROCEDURE p-value-ttrulex1:
  /*------------------------------------------------------------------------------
       File: ttruck (Trucks)                                                      
      Field: ttrulex1 (EX1)                                                       
      Event: VALUE-CHANGED                                                        
  --------------------------------------------------------------------------------
    Purpose:                                                                      
      Notes:                                                                      
    Created: 07/07/20 Alex Leenstra   
    updated: 11/09/15 Amity timalsina                                            
  ------------------------------------------------------------------------------*/

  /*if p-value = 'yes' then assign p-result = 'ttruleu1' + chr(1) + 'no'.*/
  if p-value = 'yes' then assign p-result = 
    'ttruleu1' + chr(1) + 'no'. /*Amity  [EMM6-0026] not to check eu1*/

END PROCEDURE. /* p-value-ttrulex1 */


procedure p-before-commit:
/*------------------------------------------------------------------------------
    Event: BEFORE-COMMIT                                                        
--------------------------------------------------------------------------------
  Purpose:                                                                      
    Notes:                                                                      
  Created: 15/02/10 Eric Clarisse  
  updated: 11/09/15 Amity timalsina [EMM6-0026] Force system to check IMA box in “trucks”                                            
------------------------------------------------------------------------------*/
  /*message 'hello from p-before-commit in ttrulsord.p' view-as alert-box information.*/

  find first sord no-lock where sord.xlevc = '1' and sord.sordn = integer(f-getvalue('sordn')).
  if sord.sordtproduct = 'laminations'
  and date(f-getvalue('ttrudslitdate')) = ? then
  do:      
    assign p-error = 'incomplete' + chr(1) + 'slitdate'.
    return.
  end.
  
  find first ttruc exclusive-lock where ttruc.ttruc = f-screenvalue('ttruc') no-error.  /*amity: [EMM6-0026] warning while changing t1,ima,exa,eua */
  if available ttruc and ( ttruc.ttruleu1 ne logical(f-screenvalue('ttruleu1'))
                        or ttruc.ttrulex1 ne logical(f-screenvalue('ttrulex1'))
                        or ttruc.ttrult1 ne logical(f-screenvalue('ttrult1'))
                        or ttruc.ttruldocima ne  logical(f-screenvalue('ttruldocima'))) then 
  do:
    message "Do you want to change the value"
      view-as alert-box question buttons yes-no update v-values as logi.
    if v-values = no then    
      p-action = "s-cancel".
  end. /* amity: do */ 
  
END PROCEDURE. /* p-before-commit */
