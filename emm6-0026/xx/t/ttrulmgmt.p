/* ---------------------- Euro-Mit Staal bv Vlissingen -------------------------

  File        : t/ttrulmgmt.p
  Description :
  Created     : 05/01/07 Kalash Shrestha

Date     Author     Version Description
-------- ------     ------- --------------------------------------------------------
05/01/07 Kalash     1.00    Created
17/07/09 Sudhir     1.01    Changed query from ppk_attr table to gcbsgoodscd table.
05/02/10 Nandeshwar 1.02    EMM5-0467: Removed the logic that changed "pw-date" on leaving of field "Truck ETD"
27/08/15 Amity      1.03    [EMM6-0013] change biz-logics regarding customs doc.
11/09/15 Amity      1.04    [EMM6-0026] CHeck/Uncheck the eua,exa,t1,ima value.
------------------------------------------------------------------------------*/

{x/xxxxlparam.i}

function FN-cargo returns integer (vttruc as char )  forward.
function FN_docs returns character ()  forward.
function FN_Totals returns character()  forward.
function f-determinePW returns date  (  p-etd as date ) forward.
function FN_CustomsRdy returns logical () forward.
function FN_generate_truckno returns char  (v-sordn as integer ) forward.


PROCEDURE p-before-commit:
/*------------------------------------------------------------------------------
    Event: BEFORE-COMMIT                                                        
--------------------------------------------------------------------------------
  Purpose: Check if the truck with same id is already created at different 
           workstation during the process
    Notes: EMM5-0871                                                                
  Created: 10/09/06 gaurab poudel                                               
------------------------------------------------------------------------------*/
  /*message 'hello from p-before-commit' view-as alert-box.*/

  define variable v-ttruc like ttru.ttruc no-undo.

  if p-mode NE 1 or p-mode NE 2 then /* return if no record is to be created */
  return.

  assign v-ttruc = f-getvalue('ttruc').

  find last ttru where ttru.xlevc = f-xlevc('ttruck') and ttru.sordn = integer(f-getvalue('sordn')) no-lock.
                   
  if ttru.ttruc = v-ttruc then
  do:
    message "This truck has been already created by another user, action canceled : " ttru.ttruc view-as alert-box info.
    assign p-action = 's-cancel'.
  end.  
               
END PROCEDURE. /* p-before-commit */

PROCEDURE p-row-display:
/*------------------------------------------------------------------------------
    Field: v-browse01
    Event: ROW-DISPLAY
--------------------------------------------------------------------------------
  Purpose: Display truck details in browse.
    Notes:
  Created: 05/01/07 Kalash Shrestha
  Modified: 17/02/07 Jaya N Pasachhe.
------------------------------------------------------------------------------*/
  /*message 'hello3' view-as alert-box information.*/

  define variable v-destination as char no-undo. /* destination in the browser */
  define variable v-grosswgt    as inte no-undo.    /* grossweight in the browser */
  define variable v-clientDesc  as char no-undo.
  define variable v-job         as char no-undo.
  define variable v-dag         as char no-undo.
  define variable v-status      as char no-undo.
  define variable v-docs        as char no-undo.

  find first ttru no-lock where rowid(ttruc) = p-rowid no-error.
  if available ttru then
  do:

    /*  Display documents to be printed, ex EMS day, status and weight of truck   */
    assign
      v-docs     = FN_docs()
      v-dag      = entry(weekday(ttru.ttrudexems),'Su,Mo,Tu,We,Th,Fr,Sa')
      v-status   = entry (1,f-xstadisp("ttruck",ttru.xstac))
      v-grosswgt = FN-cargo(ttru.ttruc).

    /*  Job type of the order     */
    find first sord no-lock where sord.xlevc = f-xlevc('sorder') and sord.sordn = ttru.sordn no-error.
    if available sord then assign v-job = sord.gjobc.

    /*  Company name of ordering client     */
    find first gcom no-lock where gcom.xlevc = f-xlevc('gcompany') and gcom.gcomn = ttru.gcomnclient no-error.
    if available gcom then assign v-clientDesc = gcom.gcomtshortname.
  end.

  assign p-result = 
    'v-grosswgt'   + chr(1) + string(v-grosswgt) + chr(1) + 
    'v-docs'       + chr(1) + v-docs             + chr(1) + 
    'v-job'        + chr(1) + v-job              + chr(1) + 
    'v-clientDesc' + chr(1) + v-clientDesc       + chr(1) + 
    'v-status'     + chr(1) + v-status           + chr(1) + 
    'v-day'        + chr(1) + v-dag
    .

END PROCEDURE. /* p-row-display */


PROCEDURE p-generate-ttruc:
/*------------------------------------------------------------------------------
     File: ttruck (Trucks)
    Field: sordn (Order)
    Event: LEAVE
--------------------------------------------------------------------------------
  Purpose:
    Notes:
  Created: 08/01/07 Jay Narayan Pasachhe
------------------------------------------------------------------------------*/
  define variable v-sordn          like ttruck.sordn no-undo.
  define variable v-agent          as char no-undo.
  define variable v-client         as char no-undo.
  define variable v-client-nr      like sord.Gcomnclient.
  define variable v-etd            as date no-undo.
  define variable v-pwdate         as date no-undo.
  define variable v-transporter    as char no-undo.
  define variable v-forwarder      as char no-undo.
  define variable v-gcomnforwarder as inte  no-undo.
  define variable v-date           as date no-undo.
  define variable v-container      as char no-undo.  

  if p-mode = 1 /*ADD*/ then
  do:
    if program-name(5) = 's-commit x/xxxxv.p' then
      return.
    
    assign v-sordn = integer(f-getvalue('sordn')).
    /*assign p-result = p-result + min(p-result, chr(1)) + 'ttruc' + chr(1) + FN_generate_truckno(v-sordn).*/
    find first sord no-lock where sord.xlevc = f-xlevc('sorder') and sord.sordn = v-sordn no-error.

    if available sord then
    do:
      /*message 'show picture' view-as alert-box.*/
      case sord.sordtproduct:
        when 'Coils' then if search('img\coils.bmp') NE ? then
          assign p-attribute = p-attribute  + min(p-attribute,chr(1)) + 'v-image01' + chr(1) + 'load-image()' + chr(1) + search('img\coils.bmp').
        when 'Laminations' then if search('img\laminations.bmp') NE ? then
          assign p-attribute = p-attribute  + min(p-attribute,chr(1)) + 'v-image01' + chr(1) + 'load-image()' + chr(1) + search('img\laminations.bmp').
        otherwise if search('img\blank.bmp') NE ? then
          assign p-attribute = p-attribute  + min(p-attribute,chr(1)) + 'v-image01' + chr(1) + 'load-image()' + chr(1) + search('img\blank.bmp').
      end case.
      
      assign
        v-etd            = sord.sorddetdems
        v-pwdate         = v-etd  - 2
        v-gcomnforwarder = sord.gcomnforwarder.

      /* finding agent */
      find first gcom no-lock where gcom.xlevc = f-xlevc('gcompany') and gcom.gcomn = sord.gcomnagent no-error.
      if available gcom then
      do:
        assign v-agent = gcom.gcomtshortname.
      end.

      /* finding forwarder */
      find first gcom no-lock where gcom.xlevc = f-xlevc('gcompany') and gcom.gcomn = sord.gcomnforwarder no-error.
      if available gcom then
      do:
        assign v-forwarder = gcom.gcomtshortname.
      end.

      /* finding client */
      find first gcom no-lock where gcom.xlevc = f-xlevc('gcompany') and gcom.gcomn = sord.gcomnclient no-error.
      if available gcom then
      do:
        assign v-client = gcom.gcomtshortname.
      end.

      find first gshi no-lock where gshi.xlevc = f-xlevc('gshipmode') and gshi.gshic = sord.gshic no-error.
      assign v-container = (if available gshi then gshi.gshim else sord.gshic).

      assign v-date = (if sord.sorddetdems LT today then today else  sord.sorddetdems).
      assign p-result = p-result + min(p-result, chr(1))
          + 'ttrudexems'        + chr(1) + (if v-etd = ?    then ''    else  string(v-etd))    + chr(1)
          + 'ttrudpwdate'       + chr(1) + (if v-pwdate = ? then ''    else  string(v-pwdate)) + chr(1)
          + 'v-sordtpay4tpt'    + chr(1) + string(sord.sordtpay4tpt)                           + chr(1)
          + 'Gcomnclient'       + chr(1) + string(sord.gcomnclient)                            + chr(1)
          + 'v-gcomtshortname1' + chr(1) + v-client                              	       + chr(1)
          + 'gcomnforwarder'    + chr(1) + string(sord.gcomnforwarder)                         + chr(1)
          + 'v-gcomtshortname'  + chr(1) + v-forwarder                             	       + chr(1)
          + 'v-agent'           + chr(1) + v-agent                                             + chr(1)
          + 'v-container'       + chr(1) + v-container
          .
    end. /* avail sorder */
  end.

END PROCEDURE. /* p-generate-ttruc */


PROCEDURE p-view-status:
  /*------------------------------------------------------------------------------
      Event: PROGRAM-START
  --------------------------------------------------------------------------------
    Purpose: Shows the info of status.
      Notes:
    Created: 05/01/07 Kalash Shrestha
  ------------------------------------------------------------------------------*/

  define variable vMessage as char no-undo.

  find first ttru no-lock where rowid(ttruck) = p-rowid no-error.

  if available ttru then
  do:

    define variable l_ostatus   as logi no-undo.
    define variable l_ordqty    as inte no-undo.
    define variable l_planned   as inte no-undo.
    define variable l_produced  as inte no-undo.
    define variable l_pallet    as inte no-undo.
    define variable l_assigned  as inte no-undo.
    define variable l_wgtnotasg as inte no-undo.
    define variable l_ready     as inte no-undo.
    define variable l_ncoils    as inte no-undo.
    define variable l_npallets  as inte no-undo.
    define variable l_ntrucks   as inte no-undo.
    define variable vTasks      as char no-undo.

    for first sord no-lock where sord.xlevc = f-xlevc('sorder')
    and sord.sordn = ttru.sordn:
      l_ostatus = sord.xstac = '800'.
      l_ordqty  = sord.sordnorderedweight.
    end.
    for each ocoi no-lock where ocoi.xlevc = f-xlevc('sorder')
    and ocoi.sordn = ttru.sordn :
      l_planned = l_planned + ocoi.ocoinweight.
      if ocoi.xstac GT '150' then l_produced = l_produced + ocoi.ocoinweight.
      if ocoi.cpaln GT 0 then l_pallet = l_pallet + 1.
      if ocoi.xstac GT '150' then l_wgtnotasg = l_wgtnotasg + ocoi.ocoinweight.
      if ocoi.xstac GT '150' then l_ncoils = l_ncoils + 1.
    end.
    for each cpal no-lock where cpal.xlevc = f-xlevc('cpallet')
    and cpal.sordn = ttru.sordn :
      l_npallets = l_npallets + 1.
      if cpal.ttruc NE '' then l_assigned = l_assigned + 1.
    end.
    define buffer bf-truck for ttruck.
    for each bf-truck no-lock where bf-truck.xlevc = f-xlevc('ttruck')
    and bf-truck.sordn = ttru.sordn :
      assign l_ntrucks = l_ntrucks + 1.
      if ttru.xstac = '700' then assign l_ready = l_ready + 1.
    end.

    for each acot no-lock where acot.xlevc = f-xlevc('acot')
    and acot.sordn = ttru.sordn,
    first atask no-lock where atas.xlevc = f-xlevc('atask')
    and atas.atasn = acot.atasn
    and atas.xstac LT '900'
    break by atas.atasnrank by atas.atasn:
      if first-of(atas.atasn) then
        assign vTasks = vTasks + chr(13) + string(atas.atasn) + " " + atas.gmacc + " " + string(atas.atasnrank).
    end.


    if l_ostatus then
      vmessage = vmessage + chr(10) + 'Planning complete'.
    else
      vmessage = vmessage + chr(10) + string(l_planned / l_ordqty * 100,">>9.9") + chr(1) + '% planned' .

    if l_ostatus and l_planned = l_produced then
      vmessage = vmessage + chr(10) + 'Production complete'.
    else
      vmessage = vmessage + chr(10) + string(l_produced / l_ordqty * 100,">>9.9") + '% produced, ' + string((l_ordqty - l_produced) / 1000,"->>9.9") + ' mt to produce'.

    if l_ostatus and l_planned = l_produced and l_ncoils = l_pallet then
      vmessage = vmessage + chr(10) + 'All coils palletized'.
    else
      vmessage = vmessage + chr(10) + string(l_ncoils - l_pallet) + ' coils to palletize, (' + string(l_wgtnotasg / 1000,"->>9.9") + ' mt)'.

    if l_ostatus and l_planned = l_produced and l_ncoils = l_pallet and l_npallets = l_assigned then
      vmessage = vmessage + chr(10) + 'All pallets in truck'.
    else
      vmessage = vmessage + chr(10) + string(l_npallets - l_assigned) + ' pallets not in truck'.

    vmessage = vmessage + chr(10) + string(l_ntrucks - l_ready) + ' trucks not ready'.

    vmessage = vmessage + chr(10) + vtasks.

    assign p-error = 'def-info' + chr(1) + vmessage.

  end.
END PROCEDURE. /* t/ttrulviewbtn.p */


PROCEDURE p-calc-total:
  /*------------------------------------------------------------------------------
      Event: value changed of v-xstac v-comnclient, v-gcomnforwarder and program-start
  --------------------------------------------------------------------------------
    Purpose:
      Notes:
    Created: 08/01/07 Jay Narayan Pasachhe
  ------------------------------------------------------------------------------*/

  define variable v-count-truck  as inte no-undo.
  define variable v-total-cargo  as inte no-undo.
  define variable v-total-target as inte no-undo.

  define variable qh             as widget-handle.
  define variable v-client       as char no-undo.
  define variable v-forwarder    as char no-undo.
  define variable v-xstac        as char no-undo.
  define variable v-query        as char no-undo.

  v-client = f-getvalue('v-gcomnclient').
  v-forwarder = f-getvalue('v-gcomnforwarder').
  v-xstac = f-getvalue('v-xstac').

  assign v-query = "for each ttru where ttru.xlevc = " + quoter(f-xlevc('ttruck')).

  if v-client = ?    then assign v-client = ''.
  if v-forwarder = ? then assign v-forwarder = ''.
  if v-xstac = ?     then assign v-xstac = ''.

  if  v-client NE ''   then v-query = v-query + " and ttru.gcomnclient = " + v-client.
  if v-forwarder NE '' then v-query = v-query + " and ttru.gcomnforwarder = "  + v-forwarder.
  if v-xstac NE ''     then v-query = v-query + " and ttru.xstac = " + quoter(v-xstac).

  v-query = v-query + " and ttru.xstac LT '900' ".
  v-query = v-query + " NO-LOCK".
  create query qh.

  qh:SET-BUFFERS(buffer ttruck:HANDLE).
  qh:QUERY-PREPARE(v-query).
  qh:QUERY-OPEN.

  repeat:
    qh:GET-NEXT().
    if qh:QUERY-OFF-END then leave.
    v-count-truck = v-count-truck + 1.
    v-total-cargo = v-total-cargo + fn-cargo(ttru.ttruc).
    v-total-target = v-total-target + ttrunmaxweight.
  end.

  qh:QUERY-CLOSE().
  delete object qh.

  assign p-result = p-result + min(p-result, chr(1)) + 
    'v-ttrucks' + chr(1) + string(v-count-truck)  + chr(1) +
    'v-target'  + chr(1) + string(v-total-target) + chr(1) +
    'v-cargo'   + chr(1) + string(v-total-cargo).

END PROCEDURE. /* p-calc-total */


PROCEDURE p-before-display:
/*------------------------------------------------------------------------------
    Event: BEFORE-DISPLAY
--------------------------------------------------------------------------------
  Purpose: Shows several fields records on before display.
    Notes:
  Created: 08/01/07 Kalash Shrestha
------------------------------------------------------------------------------*/

  define buffer b-gcompany for gcom.

  define variable vagent       as char no-undo.
  define variable vtransporter as char no-undo.
  define variable vptypes      as char no-undo.
  define variable minwid       as deci no-undo initial 9999.
  define variable maxwid       as deci no-undo initial 0.
  define variable vlokaties    as char no-undo.
  define variable vpallets     as inte no-undo.
  define variable vnetto       as deci no-undo.
  define variable vminmax      as char no-undo.
  define variable vCBScode     as char no-undo.
  define variable cbscodes     as char no-undo initial "7226110091,7226110011,7225110010,7212101000,7210122000,7210301000".
  define variable vCode        as inte no-undo extent 6 initial 0.
  define variable vcontainer   as char no-undo.
  define variable v-grosswgt   as inte no-undo.

  find first ttru no-lock where rowid(ttruc) = f-getrowid("ttruck") no-error.
  if available ttru then
  do:
    /*  Store truck number and rowid    */
    f-dynafunc ('f-ttruc' + chr (1) + ttru.ttruc).
    v-temp = f-dynafunc ('f-storeids' + chr(1) + replace(p-ids,chr(1),'|')).

    assign v-grosswgt = FN-cargo(ttru.ttruc).

    find first sord no-lock where sord.xlevc = f-xlevc('sorder') and sord.sordn = ttru.sordn no-error.
    if available sord then 
    do:  
      /*message 'show picture' view-as alert-box.*/
      case sord.sordtproduct:
        when 'Coils' then if search('img\coils.bmp') NE ? then
          assign p-attribute = p-attribute  + min(p-attribute,chr(1)) + 'v-image01' + chr(1) + 'load-image()' + chr(1) + search('img\coils.bmp').
        when 'Laminations' then if search('img\laminations.bmp') NE ? then
          assign p-attribute = p-attribute  + min(p-attribute,chr(1)) + 'v-image01' + chr(1) + 'load-image()' + chr(1) + search('img\laminations.bmp').
        otherwise if search('img\blank.bmp') NE ? then
          assign p-attribute = p-attribute  + min(p-attribute,chr(1)) + 'v-image01' + chr(1) + 'load-image()' + chr(1) + search('img\blank.bmp').
      end case.
    end.
    if available sord then
    do:

      find first b-gcompany no-lock where b-gcompany.xlevc = f-xlevc('gcompany') and b-gcompany.gcomn = sord.gcomnclient no-error.

      find first gcom no-lock where gcom.xlevc = f-xlevc('gcompany') and gcom.gcomn = sord.gcomnagent no-error.
      if available gcom then
      do:
        find first gshi no-lock where gshi.xlevc = f-xlevc('gshipmode') and gshi.gshic = sord.gshic no-error.

        assign
          vagent = gcom.gcomtshortname
          vcontainer = (if available gship then gshi.gshim else sord.gshic).
      end.
    end.  /* if available sorder */

    find first gcom no-lock where gcom.xlevc = f-xlevc('gcompany') and gcom.gcomn = ttru.gcomnforwarder no-error.
    if available gcom then assign vtransporter = gcom.gcomtshortname.

    for each cpal no-lock where cpal.xlevc = f-xlevc('cpallet') 
    and cpal.ttruc = ttru.ttruc,
    each gpal no-lock where gpal.xlevc = f-xlevc('gpallettype') 
    and gpal.gpalc = cpal.gpalc 
    break by gpal.gpalm:
      if index(vPTypes,gpal.gpalm) = 0 then assign vPTypes = vPTypes + minimum(",",vPTypes) + gpal.gpalm.
      if index(vlokaties,cpal.glocc) = 0 then assign vlokaties = vlokaties + minimum(",",vlokaties) + cpal.glocc.

      assign vpallets = vpallets + 1.

      for each ocoi no-lock where ocoi.xlevc = f-xlevc('ocoil')
      and ocoi.cpaln = cpal.cpaln:
        assign
          vnetto = vnetto + ocoi.ocoinweight
          minwid = if minwid GT ocoi.ocoiawidth then ocoi.ocoiawidth else minwid
          maxwid = if maxwid LT ocoi.ocoiawidth then ocoi.ocoiawidth else maxwid.
      end.
    end.   /* for each cpallet */

    if maxwid GT 0 then assign vminmax = string(minwid) + '-' + string(maxwid).
    else assign vminmax = '?'.

    run proc\FindCbsCodeTrc.p(input ttru.ttruc,input '1',output vCBScode).
    for first gcbsgoodscd no-lock where gcbsgoodscd.xlevc = f-xlevc('gcbsgoodscd')
    and gcbsgoodscd.gcbsc = vCBScode:
      assign vCBScode = vCBScode + " " + gcbsgoodscd.gcbsm.
    end.
    
  end.
  
  if avail ttru and ttru.ttrutinstructions NE '' then
  assign p-attribute = p-attribute + min(p-attribute,chr(1)) + 'ttrutinstructions' + chr(1) + 'bgcolor' + chr(1) + '14'.
  else assign p-attribute = p-attribute + min(p-attribute,chr(1)) + 'ttrutinstructions' + chr(1) + 'bgcolor' + chr(1) + '?'.
  
  assign p-result = 
    'v-agent'           + chr(1) + vagent             + chr(1) + 
    'v-transporter'     + chr(1) + vtransporter       + chr(1) + 
    'v-pallettype'      + chr(1) + vptypes            + chr(1) + 
    'gcomnclient'       + chr(1) + string(if available sord then string(sorder.gcomnclient) else "0")         + chr(1) + 
    'v-gcomtshortname1' + chr(1) + (if available b-gcompany then b-gcompany.gcomtshortname else "") + chr(1) + 
    'v-netwgt'          + chr(1) + string(vnetto)     + chr(1) + 
    'v-minmax'          + chr(1) + string(vminmax)    + chr(1) + 
    'v-tarifcode'       + chr(1) + vCBScode           + chr(1) + 
    'v-location'        + chr(1) + vlokaties          + chr(1) + 
    'v-pallet'          + chr(1) + string(vpallets)   + chr(1) + 
    'v-grosswgt'        + chr(1) + string(v-grosswgt) + chr(1) + 
    'v-container'       + chr(1) + vcontainer         + chr(1) + 
    'v-confirmed'       + chr(1) + (if available ttru and ttru.tdocc NE ? and ttru.tdocc NE "" then 'yes' else 'no').       

END PROCEDURE. /* p-before-display */


procedure p-pstart-goods:
/*------------------------------------------------------------------------------
    Field: v-browse01
    Event: ROW-DISPLAY
--------------------------------------------------------------------------------
  Purpose: Display truck details in browse.
    Notes:
  Created: amity: 12/08/2015 SR EMM6-0013 
------------------------------------------------------------------------------*/

def var vCustoms as char no-undo.
    
  find first ttru no-lock where rowid(ttru) = p-rowid no-error.
  find first tdoc no-lock where tdoc.xlevc = f-xlevc('tdocument') and tdoc.ttruc = ttru.ttruc no-error.

  for each cpal no-lock where cpal.xlevc = '1'
  and cpal.ttruc = ttru.ttruc,
  each ocoi no-lock where ocoi.xlevc = '1'
  and ocoi.cpaln = cpal.cpaln:
    if index(vCustoms,string(ocoi.ocoileu)) = 0 then assign vCustoms = vCustoms + minimum(',',vCustoms) + string(ocoi.ocoileu).
  end.
  vCustoms = replace(vCustoms,"yes","EU").
  vCustoms = replace(vCustoms,"no","NEU").
  
end procedure. /*end p-pstart-goods */

PROCEDURE p-valchange-t1:
/*------------------------------------------------------------------------------
  File   : ttruck (Truck)                                                       
    Field: ttrult1 (T1)                                                         
    Event: VALUE-CHANGED                                                        
--------------------------------------------------------------------------------
  Purpose:                                                                      
    Notes:                                                                      
  Created: 15/04/16 Eric Clarisse   
  updated: 11/09/15 Amity timalsina  [EMM6-0026]                                            
------------------------------------------------------------------------------*/ 

  if p-value = 'yes' then assign p-result = 
    'ttruldocima' + chr(1) + 'no'. /* amity: [EMM6-0026] do not  check eu materials.*/
  
END PROCEDURE. /* p-valchange-t1 */

PROCEDURE p-valchange-ima:
/*------------------------------------------------------------------------------
  File   : ttruck (Truck)                                                       
    Field: ttruldocima (IMA)                                                         
    Event: VALUE-CHANGED                                                        
--------------------------------------------------------------------------------
  Purpose: check only one non european materails at once                                                                     
    Notes:                                                                      
  Created: 09/10/2015  amity timalsina  [EMM6-0026]                                              
-------------------------------------- ----------------------------------------*/ 

  if p-value = 'yes' then assign p-result = 
    'ttrult1' + chr(1) + 'no'. 
  
END PROCEDURE. /* p-valchange-ima */

PROCEDURE p-valchange-eu1:
/*------------------------------------------------------------------------------
     File: ttruck (Trucks)
    Field: ttruleu1 (EU1)
    Event: VALUE-CHANGED
--------------------------------------------------------------------------------
  Purpose: Shows the negative value for ex1.
    Notes:
  Created: 17/02/07 Kalash Shrestha
------------------------------------------------------------------------------*/

  if p-value = 'yes' then assign p-result = 
    'ttrulex1' + chr(1) + 'no'.   /* amity : [EMM6-0026] do not check t1.*/

END PROCEDURE. /* p-valchange-eu1 */


PROCEDURE p-valchange-ex1:
/*------------------------------------------------------------------------------
     File: ttruck (Trucks)
    Field: ttrulex1 (EX1)
    Event: VALUE-CHANGED
--------------------------------------------------------------------------------
  Purpose: Shows the negative value for eu1.
    Notes:
  Created: 17/02/07 Kalash Shrestha
  updated: 11/09/15 Amity timalsina [EMM6-0026]
------------------------------------------------------------------------------*/

  if p-value = 'yes' then assign p-result = 
    'ttruleu1' + chr(1) + 'no' . /* amity: [EMM6-0026] do not check t1.*/
END PROCEDURE. /* p-valchange-ex1 */


PROCEDURE p-display-company:
/*------------------------------------------------------------------------------
    Event: BEFORE-DISPLAY
--------------------------------------------------------------------------------
  Purpose:
    Notes:
  Created: 22/02/07 Dipesh Maharjan
------------------------------------------------------------------------------*/

  define variable v-company as char no-undo.

  find first ttru no-lock where rowid(ttruck) = p-rowid no-error.

  if available ttru then
  do:
    find first sord no-lock where sord.xlevc = f-xlevc('sorder') and sord.sordn = ttru.sordn no-error.
    if available sorder then
    do:
      assign v-company = sord.sordtpay4tpt.
    end.
  end.

  assign p-result = 'v-sordtpay4tpt' + chr(1) + v-company.

END PROCEDURE. /* p-display-company */


PROCEDURE p-afenable-xstac:
/*------------------------------------------------------------------------------
     File:
    Field:
    Event: after-enable
--------------------------------------------------------------------------------
  Purpose:
    Notes:
  Created: 17/02/07 Kalash Shrestha
------------------------------------------------------------------------------*/

  /* p-attribute = 'v-xstac' + chr(1) + 'sensitive' + chr(1) + 'false' .*/

END PROCEDURE. /* p-afenable-xstac */


PROCEDURE p-after-enable:
  /*------------------------------------------------------------------------------
      Event: AFTER-ENABLE
  --------------------------------------------------------------------------------
    Purpose: Set default value of LO Printed to yes on new and copy mode.
      Notes:
    Created: 09/09/11 Sudhir Shakya
  ------------------------------------------------------------------------------*/
  if p-mode LT 3 then assign p-result = 'ttrulloprinted' + chr (1) + 'no'.
     
END PROCEDURE. /* p-after-enable */


PROCEDURE p-tab-show:
/*------------------------------------------------------------------------------
    Event: TAB-SHOW                                                             
--------------------------------------------------------------------------------
  Purpose:                                                                      
    Notes:                                                                      
  Created: 09/09/23 gaurab poudel                                               
------------------------------------------------------------------------------*/

  assign p-action = 's-qryreopen'.
  
END PROCEDURE. /* p-tab-show */




function FN-cargo  returns integer (vttruc as char):
/*------------------------------------------------------------------------------
  Purpose:  return gross weight
    Notes:
------------------------------------------------------------------------------*/

  define variable returnvalue as inte no-undo initial 0.

  for each cpal no-lock where cpal.xlevc = f-xlevc('cpallet') 
  and cpal.ttruc = vttruc 
  and cpal.xstac = '300':
    returnvalue = returnvalue + cPal.cpalnGrossWeight.
  end.

  return returnvalue.   /* Function return value. */
  
end function.


function FN_docs returns character () :
/*------------------------------------------------------------------------------
  Purpose: Return string containing list of truck reports that need to be printed.
    Notes:
------------------------------------------------------------------------------*/

  define variable docs as char no-undo.

  find first ttru no-lock where rowid(ttruc) = p-rowid no-error.
  if available ttru then
    assign
      docs = (if not ttru.ttrulloprinted then "LO-" else "")
      docs = docs + (if ttru.ttrulpacklist and not ttru.ttrulplprinted then "PL-" else "")
      docs = docs + (if ttru.ttrulcmr and not ttru.ttrulcmrprinted then "CMR-" else "")
      docs = docs + (if ttru.ttruleu1 and ttru.tdocc = '' then "EUA" else "")
      docs = docs + (if ttru.ttrulex1 and ttru.tdocc = '' then "EXA" else "")
      docs = docs + (if ttru.ttrult1 and ttru.tdocc = '' then "T1" else "")
      docs = docs + (if ttru.ttruldocima and ttru.tdocc = '' then "IMA" else "")
      .
  return docs.
  
end function.


function FN_generate_truckno returns char
  (v-sordn as integer ):
  
  define variable v-next-ttruc   as char no-undo.
  define variable v-next-ttrucno as char no-undo.
  define variable v-curr-ttrucno as inte no-undo.
  define variable v-temp         as char no-undo.
  define variable v-index        as inte no-undo.
  
  assign v-temp = string(v-sordn) + "-".
  find first sord no-lock where sord.xlevc = f-xlevc('sorder')
  and sord.sordn = v-sordn no-error.
  if available sord then
  do:
    find last ttru no-lock where ttru.xlevc = f-xlevc('ttruck')
    and ttru.ttruc begins v-temp no-error.
    if available ttru then
    do:
      assign v-index = index(ttru.ttruc, '-',1).
      if  v-index GT 0 then
      do:
        assign v-curr-ttrucno = integer(trim(substring(ttru.ttruc,v-index + 1), '0')).
        if v-curr-ttrucno LT 9 then
          assign v-next-ttrucno = string(sord.sordn)+ '-0' + string(v-curr-ttrucno + 1).
        else
          assign v-next-ttrucno = string(sord.sordn)+ '-' + string(v-curr-ttrucno + 1).
        return v-next-ttrucno.
      end.
      else
      do:
        assign v-next-ttrucno = string(sord.sordn) + '-0' + '1'.
      end.
      return v-next-ttrucno.
    end.
    else
    do:
      assign v-next-ttrucno = string(sord.sordn) + '-0' + '1'.
      return v-next-ttrucno.
    end.
  end.
  
end.


function FN_Totals returns character() :
  /*------------------------------------------------------------------------------
    Purpose:  return number of trucks, planned and cargo
      Notes:  @#$! this FN does not work properly in EMM5, coz of xe-sort/filter method, need redesign!!
  ------------------------------------------------------------------------------*/
  /* summary */
  define variable returnvalue as char no-undo.
  define variable s-trucks    as inte no-undo.
  define variable s-target    as inte no-undo.
  define variable s-cargo     as inte no-undo.

  define variable qry         as inte no-undo initial 1.

  assign s-trucks = 0 s-target = 0 s-cargo = 0.
  if available ttru then
  do:
    for each ttru no-lock where ttru.xlevc = f-xlevc('ttruck')
    and ttru.xstac LT '900'
    and ttru.ttrunmaxweight GT 0:
      s-target = s-target + ttru.ttrunmaxweight.
      s-trucks = s-trucks + 1.
      for each cpal no-lock where cpal.xlevc = f-xlevc('cpallet')
      and cpal.ttruc = ttru.ttruc :
        assign s-cargo = s-cargo + cpal.cpalngrossweight.
      end.
    end.
  end.
  assign returnvalue = "#Trucks: " + string(s-trucks) +
    "              Target: " + string(s-target,">>,>>>,>>9") +
    "    Cargo: " + string(s-cargo,">>,>>>,>>9").

  return returnvalue.   /* Function return value. */

end function.


function f-determinePW returns date
  (p-etd as date ) :
  /*------------------------------------------------------------------------------
    Purpose:  determine pw-date of truck
      Notes:
  ------------------------------------------------------------------------------*/
  define variable pwdatum as date no-undo.

  /* REVISED DD 5-6-203 : DETERMINE PWDATUM, DEFAULT 2 WORKING DAYS */

  assign pwdatum = p-etd - 2.

  if weekday(pwdatum) = 1 /* sunday */   then pwdatum = pwdatum - 2.
  if weekday(pwdatum) = 7 /* saturday */ then pwdatum = pwdatum - 2.

  return pwdatum.   /* Function return value. */

end function.


function FN_CustomsRdy returns logical ():
  /*------------------------------------------------------------------------------
    Purpose: determine if truck is customs ready
      Notes:
  ------------------------------------------------------------------------------*/
  define variable v-ready as logi no-undo init false.

  find first ttru no-lock where rowid(ttruck) = f-getrowid('ttruck') no-error.
  if available ttru then
  do:
    if ttru.ttruleu1 then do:
      assign v-ready = can-find(first tdoc where tdoc.xlevc = f-xlevc('tdocument') and tdoc.ttruc = ttru.ttruc and (tdoc.gdctc = "EU1" or tdoc.gdctc = "EUA")).
    end.
    else if ttru.ttrulex1 then do:
      assign v-ready = can-find(first tdoc where tdoc.xlevc = f-xlevc('tdocument') and tdoc.ttruc = ttru.ttruc and (tdoc.gdctc = "EX1" or tdoc.gdctc = "EXA")).
    end.
  end.  
  return v-ready.
  
end function.

