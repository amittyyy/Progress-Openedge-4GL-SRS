/* ---------------------- Euro-Mit Staal bv Vlissingen -------------------------
File : o/ocoir778.p
Description : Availability
Parameters-in-emm4:
Parameters-in-emm5:
Tables used : ocoi,sord,gcom,pbil,pshi,sfor

Version    Author     Description
---------- ------     --------------------------------------------------------------
09.10.2006 kalash     created
31.12.2009 Nandeshwar EMM5-0593: Modified the code to take delay value from new delay text box and compared the code with emm4. 
12.01.2010 Mohan      EMM5-0612:- Updated the code with latest from Eric on 11.01.2010
31/08/2015 Amity      [EMM6-0035] Split up EU and NEU material in availability.
28/09/2015 Amity      [EMM6-0052] Sales forecaset and forecast purchase are added or deducted from the stock level and filter in the availability program.
------------------------------------------------------------------------------*/

{o/ocoir778.s}
{x/xxxxrhedel.i &mode = C &nohead = true &noparam = true}

define VARIABLE maanden        as char no-undo initial 'january,february,march,april,may,june,july,august,september,october,november,december'.
define variable vBalance       as inte no-undo.
define variable vPostion       as inte no-undo.
define variable vsorderedWgt   as inte no-undo.
define variable vProducedWgt   as inte no-undo.
define variable vBalanceWgt    as inte no-undo.
define variable prodqty        as inte no-undo.
define variable startwght      as deci format ">>>,>>>,>>9.999" no-undo.
define variable v-xlevc-ssizes as char no-undo.
define variable vFrm           as inte no-undo initial 0.
define variable vSfram         as char no-undo.

define variable iGrade         as char no-undo.
define variable iScraprate     as deci no-undo.
define variable iShpDelay      as inte no-undo.
define variable iForecasts     as logi no-undo.
define variable iPurches       as logi no-undo.
define variable iFrm           as char no-undo.
define variable vOrderedWgt    as inte no-undo.
define variable iStockRM       as logi no-undo.
define variable iStockSRM      as logi no-undo.
define variable iSalesorders   as logi no-undo.
define variable iShipments     as logi no-undo.
def    var      iExclCut       as logi no-undo.

assign 
  v-xlevc-ssizes = f-xlevc('ssizes').

assign 
  iGrade       = v-ggrac
  iForecasts   = v-chkforecasts
  iSalesorders = v-chksalesorders
  iStockRM     = v-chkstock1
  iStockSRM    = v-chkstock2
  iShipments   = v-chkshipments
  iPurches     = v-chkpurforecasts
  iScrapRate   = v-scraprate
  iShpDelay    = v-delay
  .
if iGrade = ? or iGrade = " " then assign iGrade = "".

find first sFra no-lock where sFra.xlevc eq f-xlevc("sFra") and sFra.sfran eq int(v-sfran) no-error.
if available sFra then assign vSfram = sFra.sfram.
    
for first sFra no-lock where sFra.xlevc eq f-xlevc("sFra")
  and sFra.sfram = vSfram:
  assign 
    vFrm = sFra.sfran. 
end.

define temp-table tt
  field grade       as char
  field datum       as date
  field maand       as inte
  field jaar        as inte
  field positie     as inte
  field type        as char
  field id          as char
  field description as char
  field ordered     as inte
  field produced    as inte
  field balance     as inte format "-999999999"
  field remarks     as char
  field eu          as logi
  .

if iStockRM         = true then run ipCalcAvlRM.
if iStockSRM        = true then run ipCalcAvlSRM.
if iSalesorders     = true then run ipSalesorders.
if iShipments       = true then run ipExpectedRM.
if iForecasts       = true then run ipForecasts. /* Amity: [EMM6-0052] filter in the sales forecast */
if iPurches         = true then run ipPurForecasts. /* Amity: [EMM6-0052] filter in the purchase forcast */


/* create output as it should be from tt */
for each tt no-lock
  break by tt.grade by tt.jaar by tt.maand by tt.datum by tt.description:
  if first-of(tt.grade) then 
  do:
    put unformatted tt.grade ' (' vSfram ') AVAILABILITY dd ' today format "99/99/9999" '  (' iScraprate format "z9.99" '%)'skip(1).
    assign 
      vPostion = 0.
  end.
  if tt.type = 'SHIP' or tt.type = 'Available' or tt.type = 'F-PURCH' then assign vPostion = vPostion + tt.balance. 
  else assign vPostion = vPostion - tt.balance.
  if first-of(maand) then 
    put unformatted skip(1) 
      entry(maand,maanden) format "x(3)" ' :      Position Description         Client/Ship      Ordered Produced  Balance Remarks' skip(1).
  if tt.type = 'ORDER' or tt.type = 'F-SALES' then assign vOrderedWgt = vOrderedWgt + tt.ordered.
  if tt.type = 'ORDER'                        then assign vProducedWgt = vProducedWgt + tt.produced.
  if tt.type = 'ORDER' or tt.type = 'F-SALES' then assign vBalanceWgt = vBalanceWgt + tt.balance.
  put 
    datum format "99/99/9999" ' ' 
    vPostion / 1000 format "->,>>9.9" ' ' 
    trim(tt.type) + ' ' + tt.id format "x(19)" ' ' 
    tt.description format "x(15)" ' '
    tt.ordered / 1000 format "->,>>9.9" ' ' 
    tt.produced / 1000 format "->,>>9.9" ' ' 
    tt.balance / 1000 format "->,>>9.9" ' ' 
    tt.remarks format "x(80)" skip.  /* amity: [EMM6-0035] extended the length of remarks*/
  if last-of(maand) then 
  do:
    if vOrderedWgt GT 0 then
      put unformatted skip(1) 
        'total ' 
        entry(maand,maanden) format "x(12)" space(37)
        vOrderedWgt / 1000 format "->>,>>9.9"  
        vProducedWgt / 1000 format "->>,>>9.9"  
        vBalanceWgt / 1000 format "->>,>>9.9" 
        skip.
    assign
      vOrderedWgt  = 0
      vProducedWgt = 0
      vBalanceWgt  = 0.
  end.
  if last-of(tt.grade) then page.
end.

/*----PROCEDURES------------------------------------------------*/

PROCEDURE ipCalcAvlSRM.
  /* Purpose: calculate available semi-raw material */
  def var vCount as inte no-undo.
  for each ocoi no-lock
    where ocoi.xlevc = f-xlevc('ocoil')
    and ocoi.ocoitcoil = "S" 
    and ocoi.ggrac = iGrade 
    and ocoi.xstac NE '900'
    and ocoi.xstac NE '995'
    and ocoi.xstac GT '150' 
    and ocoi.gjobc = "S" 
    and ocoi.sfran = (if vFrm = 0 then ocoi.sfran else vFrm)
  
    break by ocoi.ocoileu by ocoi.ggrac:
    if v-customs = "YES" and ocoi.ocoileu = false then next. /* amity:  [EMM6-0035] Split up EU and NEU material in availability*/
    if v-customs = "NO" and ocoi.ocoileu  = true then next.  
    /*if lookup(ocoi.xstac,"100,150,205,700,905,995") GT 0 then message 'oops?' ocoi.xstac view-as alert-box error.*/    
    vCount = vCount + 1.
    assign 
      startwght = startwght + ocoi.ocoinweight.
    if last-of(ocoi.ggrac) then 
    do:
      create tt.
      assign 
        tt.grade       = ocoi.ggrac
        tt.datum       = today
        tt.maand       = month(today)
        tt.jaar        = year(today)
        tt.positie     = 0
        tt.type        = 'Available'
        tt.id          = ' SRM'
        tt.description = ""
        tt.ordered     = startwght
        tt.produced    = 0
        tt.balance     = startwght * (1 - iScraprate / 100)
        tt.remarks     = (if ocoi.ocoileu then "EU" else "NEU") + "(" + string(vCount) + ")"
        tt.eu          = ocoi.ocoileu
        .
      startwght = 0.
    end.
  end.
END PROCEDURE.


PROCEDURE ipCalcAvlRM.
  /* Purpose: calculate available raw material */
  for each ocoi no-lock
    where ocoi.xlevc = f-xlevc('ocoil')
    and ocoi.ocoitcoil = "R" 
    and ocoi.ggrac = iGrade 
    and ocoi.xstac NE '900'
    and ocoi.xstac GT '150' 
    and ocoi.gjobc = "S" 
    and ocoi.sfran = (if vFrm = 0 then ocoi.sfran else vFrm) 
    break by ocoi.ocoileu by ocoi.ggrac:
    if v-customs = "YES" and ocoi.ocoileu = false then next. /* amity: [EMM6-0035] Split up EU and NEU material in availability*/
    if v-customs = "NO" and ocoi.ocoileu  = true then next.  
    assign 
      startwght = startwght + ocoi.ocoinweight.
    if last-of(ocoi.ggrac) then 
    do:
      create tt.
      assign 
        tt.grade       = ocoi.ggrac
        tt.datum       = today
        tt.maand       = month(today)
        tt.jaar        = year(today)
        tt.positie     = 0
        tt.type        = 'Available'
        tt.id          = ' RM'
        tt.description = ""
        tt.ordered     = startwght
        tt.produced    = 0
        tt.balance     = startwght * (1 - iScraprate / 100)
        tt.remarks     = if ocoi.ocoileu then "EU" else "NEU"
        tt.eu          = ocoi.ocoileu
        .
      assign 
        startwght = 0.
    end.
  end.
END PROCEDURE.


PROCEDURE ipSalesorders.
  /* Purpose: gather data salesorders */
  for each sord no-lock
    where sord.xlevc = f-xlevc('sorder')
    and sord.ggrac = iGrade 
    and sord.xstac LT '800'
    and sord.xstac NE '999'
    and sord.gjobc = "S" 
    and sord.sfran = (if vFrm = 0 then sord.sfran else vFrm),
    first gcom no-lock
    where gcom.gcomn = sord.gcomnclient:
    if v-customs = "YES" and sord.sordleu = false then next. 
    if v-customs = "NO" and sord.sordleu  = true then next.  /*  amity:[EMM6-0035] removed "sordlentrepot" previously put this instead of sordleu */             
    /* run proc\CalcProdQty.p(input sord.sordn, output ProdQty). /*ip_bereken_prodqty(order.ordno). */*/
    run proc\CalcProdQty2.p(input sord.sordn,input sord.sordtproduct, input v-xlevc-ssizes, output ProdQty).
    create tt.
    assign 
      tt.grade       = sord.ggrac
      tt.datum       = sord.sorddetdems
      tt.maand       = month(sord.sorddetdems)
      tt.jaar        = year(sord.sorddetdems)
      tt.positie     = 0
      tt.type        = 'ORDER'
      tt.id          = string(sord.sordn) + if sord.xstac = '200'  then " new" else ""
      tt.description = gcom.gcomtshortname
      tt.ordered     = sord.sordnorderedweight
      tt.produced    = prodqty
      tt.balance     = sord.sordnorderedweight - prodqty
      tt.remarks     = if sord.sorddorgetd NE sord.sorddetdems 
        then ('org ' + string(sord.sorddorgetd)) else ""
      tt.eu          = ?.
    if tt.balance LT 0 then assign tt.balance = 0.
  end.
END PROCEDURE.


PROCEDURE ipExpectedRM.
  /* Purpose: gather data expected raw material */
  for each ocoi no-lock
    where ocoi.xlevc = f-xlevc('ocoil')
    and ocoi.ocoitcoil = "R" 
    and ocoi.ggrac = iGrade
    and ocoi.xstac LE '150'
    and ocoi.gjobc = "S"
    and ocoi.sfran = (if vFrm = 0 then ocoi.sfran else vFrm),
    first pbil no-lock
    where pbil.pbiln = ocoi.pbiln,
    first pshi no-lock where pshi.pshin = pbil.pshin,
    first gcom no-lock where gcom.gcomn = pbil.gcomncreditor
    break by ocoi.ocoileu by ocoi.ggrac by pshi.pshin by /*billlade.creditor */ gcom.gcomm:
    if v-customs = "YES" and ocoi.ocoileu = false then next. /* amity: [EMM6-0035] Split up EU and NEU material in availability*/
    if v-customs = "NO" and ocoi.ocoileu  = true then next.                                   
    assign 
      startwght = startwght + ocoi.ocoinweight.
    if last-of(/*billlade.creditor */ gcom.gcomm) then 
    do:
      create tt.
      assign 
        tt.grade       = ocoi.ggrac
        tt.datum       = pshi.pshidcta + iShpDelay
        tt.maand       = month(pshi.pshidcta + iShpDelay)
        tt.jaar        = year(pshi.pshidcta + iShpDelay)
        tt.positie     = 0
        tt.type        = 'SHIP'
        tt.id          = 'RM'
        tt.description = pshi.pshim
        tt.ordered     = startwght
        tt.produced    = 0
        tt.balance     = startwght * (1 - iScraprate / 100)
        tt.remarks     = (if ocoi.ocoileu then "EU" else "NEU") + "(" + substring(/*billlade.creditor */ gcom.gcomm,1,6) + ")" /*'org ' + string(pshi.shideta). */
        tt.eu          = ocoi.ocoileu
        .
      startwght = 0.
    end.
  end.
END PROCEDURE.


PROCEDURE ipForecasts.
  /*------------------------------------------------------------------------------
    Event: 
--------------------------------------------------------------------------------
  Purpose: To show the forecast sales  as well as filter it in neu and eu.
    Notes: [EMM6-0052]
  Created: 25/09/2015 Amity Timalsina 
------------------------------------------------------------------------------*/
  for each sforecast no-lock 
    where sfor.xlevc = f-xlevc('sforecast')
    and sforecast.ggrac = iGrade
    and sforecast.sfran = (if vFrm = 0 then sforecast.sfran else vFrm):
    find first sorder no-lock where sorder.sfran = sforecast.sfran no-error. /*  amity:[EMM6-0035] filter by order*/
/*    find first ocoil no-lock where ocoil.sordn = sorder.sordn no-error.*/
    if available sorder then     
    do:      
      if v-customs = "YES" and sorder.sordleu = false then next.  /*  amity:[EMM6-0035] removed "sordlentrepot" previously put this instead of sordleu */ 
      if v-customs = "NO" and sorder.sordleu  = true then next. 
    end.
    if sforecast.sforlftype = true and iForecasts = true then 
    do: /* sales */    
      find first gcom no-lock where gcom.xlevc = f-xlevc('gcompany') and gcom.gcomn = sfor.gcomn.
      create tt.
      assign 
        tt.grade       = sforecast.ggrac
        tt.datum       = sforecast.sfordfordate
        tt.maand       = month(sforecast.sfordfordate)
        tt.jaar        = year(sforecast.sfordfordate)
        tt.positie     = 0
        tt.type        = 'F-SALES'
        tt.id          = ""
        tt.description = gcom.gcomtshortname
        tt.ordered     = sforecast.sforqquantity
        tt.produced    = 0
        tt.balance     = sforecast.sforqquantity
        tt.remarks     = sforecast.sfortremarks /*+ ' (org ' + string(sforecast.orgdate) + ')' */.
    end.
  end.
END PROCEDURE.   /*  ipForecasts */

PROCEDURE ipPurForecasts.
  /*------------------------------------------------------------------------------
     Event: 
 --------------------------------------------------------------------------------
   Purpose: To show the purchase forecast as well as filter it in neu and eu quantity.
     Notes: [EMM6-0052]
   Created: 25/09/2015 Amity Timalsina 
 ------------------------------------------------------------------------------*/
  for each sforecast no-lock 
    where sfor.xlevc = f-xlevc('sforecast')
    and sforecast.ggrac = iGrade
    and sforecast.sfran = (if vFrm = 0 then sforecast.sfran else vFrm):
    find first sorder no-lock where sorder.sfran = sforecast.sfran no-error. /* amity:[EMM6-0035] filter by order*/
/*    find first ocoil no-lock where ocoil.sordn = sorder.sordn no-error.*/
    if available sorder then     
    do:         
      if v-customs = "YES" and sorder.sordleu = false then next.  /*  amity:[EMM6-0035] removed "sordlentrepot" previously put this instead of sordleu */ 
      if v-customs = "NO" and sorder.sordleu  = true then next. 
    end.      
    if sforecast.sforlftype = false and iPurches = true then 
    do: /* purchase */     
      create tt.
      assign 
        tt.grade       = sforecast.ggrac
        tt.datum       = sforecast.sfordfordate + iShpDelay
        tt.maand       = month(sforecast.sfordfordate + iShpDelay)
        tt.jaar        = year(sforecast.sfordfordate + iShpDelay)
        tt.positie     = 0
        tt.type        = 'F-PURCH'
        tt.id          = ""
        tt.description = ""
        tt.ordered     = sforecast.sforqquantity
        tt.produced    = 0
        tt.balance     = sforecast.sforqquantity * (1 - iScraprate / 100)
        tt.remarks     = sforecast.sfortremarks.
    end.
  end.
END PROCEDURE. /* ipPurForecasts*/
