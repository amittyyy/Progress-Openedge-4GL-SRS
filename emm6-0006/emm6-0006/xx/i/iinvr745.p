/* ---------------------- Euro-Mit Staal bv Vlissingen -------------------------
File : i/iinvr745.p
Description : Principal Truck Invoice
Parameters-in-emm4:
Parameters-in-emm5:
Tables used : xsys,xset,ttru,cpal,ocoi,ssiz,gcou,iinv

Version    Author     Description
---------- ------     --------------------------------------------------------------
08.02.2007 chandan    created
13/07/09  Sudhir      Added code to obtain the value for iinvn from xsequence table.
15/07/09  Sudhir      Removed code to generate header. Added error message if v-ttruc is invalid.
03/11/09  Mohan       EMM5-0523: To display the Signature of Managing Director using an extra setting rather than hardcoded value.
03/11/09  Mohan       EMM5-0513: Changed the date display format, alignment of total value, removed the page break and if the coils are already invoiced then set the truck number empty.
01/12/09  Nandeshwar  EMM5-0558: display the country name at "Client" Which was missing previously
08/12/09  Mohan       EMM5-0561:- Database will be updated only if the printer button is clicked
                                  else it will preview the report only.
13/07/15 Ku           EMM6-0006:- Added a condition for v-impd = 0 so that a text will appear in the report.  
24/08/15 ku           EMM6-0028: Added a logic for printing a line automatically for duties depending upon EU or NEU materail.
09/09/15 ku           EMM6-0028: Modified the logic for printing the line automatically depending upon the "Duty Paid" for NEU.
10/09/15 ku           EMM6-0040: Added a condition to correct the bank Details.                                
------------------------------------------------------------------------------*/

{i/iinvr745.s}
{x/xxxxrhedel.i &mode = E &nohead = true &noparam = true}

function FN_HsCode returns char (input pWid as deci,input pJob as char,input pProduct as char,input pGrade as char) forward.

define variable vGradeText as char no-undo.
define variable vBaseAmt   as deci no-undo. /* AMOUNT = SUM(wgt * ssizaprice) */
def var vImpdAmt as deci no-undo.
define variable npallets   as inte no-undo.
define variable vNetWgtTrc as inte no-undo.
define variable vNettWgt   as inte no-undo.
define variable vGrsWgtTrc as inte no-undo.
define variable vGrossWgt  as inte no-undo.
define variable nCoils     as inte no-undo.
define variable nSizes     as inte no-undo.
define variable vSizeQty   as inte no-undo.
define variable vProdQty   as inte no-undo.
define variable vSizeAmt   as deci no-undo.
define variable cw         as inte no-undo.
define variable tp         as inte no-undo.
define variable tc         as inte no-undo.
define variable tw         as inte no-undo.
define variable gw         as inte no-undo.
define variable casettl    as inte no-undo.
define variable lines      as inte no-undo initial 0.
define variable pages      as inte no-undo initial 1.
define variable id         as deci no-undo.
define variable eglist     as char no-undo.
define variable vColsInTrc  as inte no-undo.
define variable vNetWgtPal   as inte no-undo.
define variable vPalsInTrc    as inte no-undo.
define variable v-countryname  as char no-undo. 
define variable v-clientcountry as char no-undo. 
define variable vGoods          as char no-undo.
define variable vIctCode        as char no-undo.
define variable vGradeSpec      as char no-undo.
define variable v-iinvn         as inte no-undo.
define variable vSignature      as char no-undo format 'x(40)'. 
define variable vVatText        as char no-undo init " (VAT shifted to recipient based on EU VAT Directive 2006/112)".
define variable vMetric as inte no-undo init 1000.
def var vCustGrade as char no-undo.
def var vCbsCode as char no-undo.
def var gProducer as char no-undo init "C041".
def var vAnswer as logi no-undo.
def var v-eum as logi no-undo.
def var v-dp as logi no-undo.
def var v-impdut as char no-undo.

def var vMix as logi no-undo init false.
def var vSubAmt as deci no-undo.
def var vAllCbsCodes as char no-undo.
def var vSubWgt as inte no-undo.

define buffer bfCln for gcom.
define buffer b-iinv for iinv.
define buffer bfCustadres for gadres.

define buffer b1-gcou for gcou.
define buffer b2-gcou for gcou.

def var vSplit as logi no-undo init false.
def temp-table bCol
  field xlevc as char
  field cpaln as inte
  field sordn as inte
  field ocoiawidth as deci column-label "Width" format ">>,>>9.99"
  field ocoinweight as inte format ">>>>9"
  field ocoin as inte
  field ocoic as char column-label "EMS-col-nr" format "x(35)"
  field eu as logi
  field ocoinlength as inte format ">>>9"
  field ocoiapurchvalue as deci
  field ggrac as char
  field gjobc as char
  .
def temp-table bPal
  field xlevc as char
  field cpaln as inte
  field cpalm as char
  field cpalngrossweight as inte
  field sordn as inte
  field ttruc as char
  field eu as logi
  field cpalntarra as inte
  .
/*init*/


for each cpal no-lock where cpal.xlevc = '1'
and cpal.ttruc = v-ttruc:
  create bPal.
  assign
    bPal.xlevc = cpal.xlevc
    bPal.cpaln = cpal.cpaln
    bPal.cpalm = cpal.cpalm
    bPal.cpalngrossweight = cpal.cpalngrossweight
    bPal.sordn = cpal.sordn
    bPal.ttruc = cpal.ttruc
    bPal.cpalntarra = cpal.cpalntarra
    .
  for each ocoi no-lock where ocoi.xlevc = '1'
  and ocoi.cpaln = cpal.cpaln:
    create bCol.
    assign
      bCol.xlevc = ocoi.xlevc
      bcol.ggrac = ocoi.ggrac
      bcol.gjobc = ocoi.gjobc
      bCol.cpaln = ocoi.cpaln
      bCol.sordn = ocoi.sordn
      bCol.ocoiawidth = ocoi.ocoiawidth 
      bCol.ocoinweight = ocoi.ocoinweight
      bCol.ocoin = ocoi.ocoin
      bCol.ocoic = ocoi.ocoic
      bCol.eu = ocoi.ocoileu
      bcol.ocoinlength = ocoi.ocoinlength
      bcol.ocoiapurchval = ocoi.ocoiapurchval
      .
  end.
end.
if can-find(first bCol where bCol.eu = true)
and can-find(first bCol where bCol.eu = false) then vMix = true.
for each cpal no-lock where cpal.xlevc = '1'
and cpal.ttruc = v-ttruc:
  if can-find(first bCol where bCol.eu = true) 
  and can-find(first bCol where bCol.eu = false) then vSplit = true.
end.
/*message '#1' skip vMix skip v-impd view-as alert-box.*/


/*output*/

find xset no-lock where xset.xlevc = f-xlevc('xsetting') and xset.xsetc = "signature" no-error.
if available xset then assign vSignature = xset.xsett.
else message "Alert sysadmin(566) of R742 signature" view-as alert-box error.
    
find first ttru where ttru.xlevc = f-xlevc('ttruck') and ttru.ttruc = v-ttruc no-lock.
if not available ttru then
do:
  find first xerror where xerror.xerrc = 'notruck' and xerror.xmlac = f-xmlac () no-lock no-error.
  if available xerror then message xerror.xerrm + ' ' + v-ttruc view-as alert-box.
  return.
end.

find first sord no-lock where sord.xlevc = f-xlevc('sorder') and sord.sordn = ttru.sordn.
find first ggra no-lock where ggra.xlevc = f-xlevc('ggrade') and ggra.ggrac = sord.ggrac.
find first gcom no-lock where gcom.xlevc = f-xlevc('gcompany') and gcom.gcomn = sord.gcomnagent.
find first gadr no-lock where gadr.xlevc = f-xlevc('gadres') and gadr.gcomn = gcom.gcomn and gadr.gadrttype = "I".
find first bfCln no-lock where bfCln.xlevc = f-xlevc('gcompany') and bfCln.gcomn = sord.gcomnclient.
find first bfCustadres no-lock where bfCustadres.xlevc = f-xlevc('gadres') and bfCustadres.gcomn = bfCln.gcomn and bfCustadres.gadrttype = "D".
vCustGrade = trim(sord.sordtdispgrade).
if vCustGrade = '' then vCustGrade = trim(sord.ggrac).

assign vGoods = ggra.ggratdescription + chr(10) + chr(10).
if sord.gjobc = "T" then assign vGoods = "TOLLSLIT" + chr(10) + chr(10).
if sord.gjobc = "H" then assign vGoods = "THIN NON-ORIENTED SILICON STEEL STRIPS" + chr(10) + chr(10).

{inc\SetGradeSpec.i}

assign v-eum = sorder.sordlentrepot
       v-dp  = sorder.sordldutypaid. 
       
for each bCol
            break by bCol.eu:
            if (bCol.eu eq false) then                                                     /*Amity: not ot cal import duities in new Rule: ku EMM6-0038: Condition added for calculating ImpD of NEU Materials only */
                vSubAmt = vSubAmt + bCol.ocoinweight / 1000 * bCol.ocoiapurchvalue.
            
            if last-of(bCol.eu) and v-eum eq true and v-dp eq true then 
            do:
                assign v-impdut  =  string(vSubAmt * 0).  /*amity  not calculate import duties for all materials*/
            end.
            else 
                assign v-impdut = "0".
        end. 
        
        release bCol.      

if vSplit then do:
  run ipCifAmt.
  message '#5' 
  skip "NEU+EU = " vMix 
  skip "input = " v-impd 
  skip "calc = " vSubAmt 
  skip "calc35.9% = " vSubAmt * 0
  skip "wgt = " vSubWgt 
  skip(1) "Choose NO to select inputted value, " skip "choose YES to select calculated value."
  view-as alert-box question buttons yes-no
  update vAnswer.
  if vAnswer = true then assign v-impd = vSubAmt * 0.359.
  run ipNEU.
  page.
  run init.
  v-impd = 0. /*@#$! impduties only applies to NEU material*/
  run ipEU.
end.
else do:
  run ipSingle.
end.


PROCEDURE ipCifAmt:
  for each bCol
  where bCol.eu = false
  break by bCol.eu:
    vSubAmt = vSubAmt + bCol.ocoinweight / 1000 * bCol.ocoiapurchvalue.
    vSubWgt = vSubWgt + bCol.ocoinweight.
/*     disp space(5) */
/*       if bCol.eu then "EU" else "NEU" column-label "EU/NEU" */
/*       bCol.ocoic column-label "EMS-Col-nr" */
/*       bCol.ocoitpalname column-label "Pallet" */
/*       bCol.ocoinweight column-label "Weight" */
/*       bCol.ocoiapurchval column-label "PurchVal" */
/*     with stream-io no-box width 148. */
/*
    if last-of(bCol.eu) then do:
/*       put unformatted */
/*         space(5) " Subtotal weight = " vSubWgt format ">>>,>>9" skip */
/*         space(5) " Subtotal amount = " vSubAmt format "->>,>>9.99" skip */
/*         space(5) "           35.9% = " vSubAmt * 0.359 format "->>,>>9.99" skip. */
      vSubAmt = 0. vSubWgt = 0.
    end.
*/
  end.
END PROCEDURE. /*ipCifAmt*/

PROCEDURE init:
  assign
  vBaseAmt   = 0
  npallets   = 0
  vNetWgtTrc = 0
  vNettWgt   = 0
  vGrsWgtTrc = 0
  vGrossWgt  = 0
  nCoils     = 0
  nSizes     = 0
  vSizeQty   = 0
  vProdQty   = 0
  vSizeAmt   = 0
  cw         = 0
  tp         = 0
  tc         = 0
  tw         = 0
  gw         = 0
  casettl    = 0
  lines      = 0
  pages      = 1
  id         = 0
  vColsInTrc  = 0
  vNetWgtPal   = 0
  vPalsInTrc    = 0
  vImpdAmt = 0
  .
  
END PROCEDURE. /*init*/


PROCEDURE ipNEU:

do transaction:

  if v-output = "1" then  
    run x/xseql.p(input f-xlevc('iinv'), input 'iinvn', output v-iinvn).

  /* determine all cbscodes*/
  for each bPal no-lock where bPal.xlevc = '1'
  and bPal.ttruc = ttru.ttruc,
  each bCol no-lock where bCol.xlevc = '1'
  and bCol.cpaln = bPal.cpaln
  and bCol.eu = false:
    vCbsCode = string(FN_HsCode(bCol.ocoiawidth,bCol.gjobc,"coil",bCol.ggrac),"x(8)").
    if index(vAllCbsCodes,vCbsCode) = 0 then vAllCbsCodes = vAllCbsCodes + minimum(',',vAllCbsCodes) + vCbsCode.
  end.

  /* COUNT PALLETS, COILS */
  for each bPal no-lock where bPal.xlevc = '1'
  and bPal.ttruc = ttru.ttruc
  and can-find(first bCol where bCol.cpaln = bPal.cpaln and bCol.eu = false):
    assign
      vGrossWgt = vGrossWgt + bPal.cpalngrossweight
      npallets = npallets + 1.
    for each bCol no-lock where bCol.xlevc = '1'
    and bCol.cpaln = bPal.cpaln
    and bCol.eu = false:
      find first ssizes no-lock where ssiz.xlevc = f-xlevc('ssizes') and ssiz.sordn = bCol.sordn and ssiz.ssizawidth = bCol.ocoiawidth.
      assign
        nCoils = nCoils + 1
        vNettWgt = vNettWgt + bCol.ocoinweight.
      if v-output = "1" then run proc\c-invcol.p(bCol.ocoin,v-iinvn,ssiz.ssizaprice,"C"). 
    end.
  end.
  
  /*DETERMINE QTY AND SALESAMT */
  for first ttru no-lock where ttru.xlevc = f-xlevc('ttruck')
  and ttru.ttruc = v-ttruc,
  first sord no-lock where sord.xlevc = f-xlevc('sorder')
  and sord.sordn = ttru.sordn ,
  first bfCln no-lock where bfCln.xlevc = f-xlevc('gcompany')
  and bfCln.gcomn = sord.gcomnclient ,
  each bPal no-lock where bPal.xlevc = '1'
  and bPal.ttruc = ttru.ttruc
  and can-find(first bCol where bCol.cpaln = bPal.cpaln and bCol.eu = false),
  each bCol no-lock where bCol.xlevc = '1'
  and bCol.cpaln = bPal.cpaln
  and bCol.eu = false
  break by bCol.ocoiawidth:
    assign
      vSizeQty = vSizeQty + bCol.ocoinweight
      vProdQty = vProdQty + bCol.ocoinweight.
    if first-of(bCol.ocoiawidth) then assign nSizes = nSizes + 1.
    if last-of(bCol.ocoiawidth) then
    do:
      find first ssizes no-lock where ssiz.xlevc = f-xlevc('ssizes') and ssiz.sordn = sord.sordn and ssiz.ssizawidth = bCol.ocoiawidth.
      case sord.gjobc:
        when "S" then assign vBaseAmt = vBaseAmt + round(vSizeQty / 1000 * ssiz.ssizaprice,2).
        when "T" then assign vBaseAmt = vBaseAmt + round(vSizeQty / 1000 * ssiz.ssizaprice,2).
        when "H" then assign vBaseAmt = vBaseAmt + round(vSizeQty * ssiz.ssizaprice,2).
      end case.
      assign vSizeQty = 0.
    end.
  end. /* for-first-truck */

  run ipSetIct.

  find b2-gcou no-lock where b2-gcou.xlevc = f-xlevc('gcountry') and b2-gcou.gcouc = sord.gcouc.
  find first gcou no-lock where gcou.xlevc = f-xlevc('gcountry') and gcou.gcouc = gadr.gcouc.
  assign v-countryname = gcou.gcoum.
  find first gcou no-lock where gcou.xlevc = f-xlevc('gcountry') and gcou.gcouc = bfCustadres.gcouc .
  assign v-clientcountry = gcou.gcoum.
      
  /*ORG:
  put unformatted skip(9) /* EMS-BRIEFHOOFD! */
    space(5) 'I N V O I C E' skip
    space(5) "" skip
    space(5) 'Invoice No.        : ' trim(string(v-iinvn,"99999999")) skip
    space(5) 'Sales Contract no. : EMS-' sord.gjobc "-" string(sord.sordn)
      "Vlissingen, " + string(v-iinvdt,"99/99/9999") at 60 skip
    space(5) 'Load no.           : ' ttru.ttruc /*"  NEU"*/ skip
    space(5) 'Your reference     : ' sord.sordtagentordcd skip(1)
    space(5) 'Messrs.            : ' trim(gadr.gadrtname) + ' ' + trim(gadr.gadrtname2) skip
    space(5) '                     ' trim(gadr.gadrtstreet1) + '  ' + trim(gadr.gadrtstreet2) skip
    space(5) '                     ' trim(gadr.gadrtzipcode) + '  ' + trim(gadr.gadrtcity) skip
    space(5) '                     ' v-countryname skip(1). 
  END-ORG*/

  put unformatted skip(9) /* amity: emm6-0059 EMS-BRIEFHOOFD! */
    space(5) 'I N V O I C E' skip
    space(5) "" skip
    space(5) 'Invoice No.        : ' trim(string(v-iinvn,"99999999")) skip
    space(5) 'Sales Contract no. : EMS-' sord.gjobc "-" string(sord.sordn)
      "Vlissingen, " + string(v-iinvdt,"99/99/9999") at 60 skip
    space(5) 'Load no.           : ' ttru.ttruc /*"  NEU"*/ skip
    space(5) 'Your reference     : ' sord.sordtagentordcd skip(1)
    /*ORG: space(5) 'Messrs.            : ' trim(gadr.gadrtname) + ' ' + trim(gadr.gadrtname2) skip*/
    space(5) 'Messrs.            : ' trim(gadr.gadrtname) skip.
  if trim(gadr.gadrtname2) NE '' then 
  put unformatted 
    space(5) '                     ' trim(gadr.gadrtname2) skip.
  put unformatted 
    space(5) '                     ' trim(gadr.gadrtstreet1) + '  ' + trim(gadr.gadrtstreet2) skip
    space(5) '                     ' trim(gadr.gadrtzipcode) + '  ' + trim(gadr.gadrtcity) skip
    space(5) '                     ' v-countryname skip(1).

  put unformatted 
    space(5) 'Description        : ' /*vGoods skip(1)*/. 
  display 
    space(26) vGoods 
    VIEW-AS EDITOR SIZE 59 BY 1 
    no-label
    with stream-io no-box width 148.
  put unformatted 
    space(5) "HS-code            : " vAllCbsCodes  skip.
  put unformatted
    space(5) 'Grade              : ' vCustGrade /*OLD**trim(sord.ggrac)*/ vGradeSpec skip
    space(5) '                     Details as per contract' skip(1)
    space(5) 'Total Quantity     : ' vNettWgt / 1000 format ">>9.999" ' m/t nett weight' skip
    space(5) '                     ' vGrossWgt / 1000 format ">>9.999" ' m/t gross weight' skip(1)
    space(5) 'Contract price     : ' sord.gcurc ' ' vBaseAmt format "->,>>>,>>>,>>9.99" ' ,see attached specification for details' skip
    space(5) 'Add. costs         : ' sord.gcurc ' ' v-AddCosts format "->,>>>,>>>,>>9.99" skip.
  /*message '#2' skip vMix skip v-impd view-as alert-box.*/
  if dec(v-impdut) ne 0 then
  put unformatted
    space(5) 'Import duties      : ' sord.gcurc ' ' dec(v-impdut) format "->,>>>,>>>,>>9.99" skip.
  put unformatted
    space(5) 'Total excl.VAT     : ' sord.gcurc ' ' round((vBaseAmt + v-AddCosts + v-impd + v-ClearCharges),2) format "->,>>>,>>>,>>9.99" skip
    space(5) 'VAT ' v-vat format ">9.9" '%          : ' sord.gcurc ' ' round((vBaseAmt + v-AddCosts + v-impd + v-ClearCharges),2) * (v-vat / 100) format "->,>>>,>>>,>>9.99" skip
    space(5) 'Total incl.VAT     : ' sord.gcurc ' ' round((vBaseAmt + v-AddCosts + v-impd + v-ClearCharges),2) * (1 + v-vat / 100) format "->,>>>,>>>,>>9.99" skip.
  if vIctCode EQ "ICP" and v-vat EQ 0 then put unformatted space(15) vVatText skip.
  put unformatted
    skip(1)
  /*space(5) 'dIT IS EXTRA REGEL VOOR VAT: taxfree, obliged, recipient, ' fill('.',25) skip*/
    space(5) 'Terms of payment   : ' v-payterms skip
    space(5) 'Client             : ' trim(bfCln.gcomm) ', ' v-clientcountry skip 
    space(5) 'Client P/O No.     : ' sord.sordtcustordcd skip
    space(5) 'Place of delivery  : ' trim(sord.sordtdesti-city) ', ' b2-gcou.gcoum skip
    space(5) 'Manufacturer       : ' v-manufacturer skip.
  if l-Origin  = true then put unformatted
    space(5) 'Country of origin  : ' v-Origin skip.
  put unformatted
    space(5) 'Delivery conditions: ' v-dlvtext skip
    space(5) 'Shipment           : on or about ' ttru.ttrudexems format "99/99/9999" skip
    space(5) "Packing            : EMS' Standard Packing " trim(string(nCoils)) ' coils, ' trim(string(npallets)) ' pallets' skip
    space(5) "Weighing           : EMS' actual weighing shall be taken as final" skip
    space(5) "Insurance          : " v-insurance skip
    space(5) "Inspection         : Manufacturer's inspection to be taken as final" skip
    space(5) "Due date           : " v-duedate format "99/99/9999" skip
    space(5) "Bank               : Deutsche Bank AG, Amsterdam" skip
    space(5) "                     " if sorder.gcurc eq "USD" then "Account nr. 026.50.64.864" else "Account nr. 026.54.21.721" skip
    space(5) "                     " if sorder.gcurc eq "USD" then "IBAN NL73DEUT0265064864" else "IBAN NL41DEUT0265421721"  "   SWIFT BIC: DEUTNL2A" skip       /*ku EMM6-0040 : Condition added to correct the bank balance */               
    space(5) "EMS V.A.T. No.     : NL800275937B01" skip
    space(5) "Your V.A.T. No.    : " v-vatno skip(1)
    space(5) "              " if sorder.sordlentrepot eq true and sorder.sordldutypaid eq false and sorder.sordleu ne true then "Inward Processing - Suspensions(IP-S)goods under customs control"               /*EMM6-0006 : Added a same condiion for text apperance at the bottom of report                  */
    else if sorder.sordleu ne true and sorder.sordldutypaid eq true then "Goods in free circulation - anti-dumping duty paid in Netherlands"                                                                     /*EMM6-0028 : Added a logic for printing a line automatically depending upon EU or NEU materail */
    else ""  skip(1)
    space(5) "      -- Details as per attached sheet --" skip(2).
  put unformatted
    "EURO-MIT STAAL B.V." at 51 skip(1)
    vSignature            at 51 skip
    "Managing Director  " at 51 skip.
  
  /*** PART TWO OF INVOICE ***/
  page.
  assign
    nSizes = 0
    vProdQty = 0.
  
  put unformatted skip(2)
    space(5) 'S P E C I F I C A T I O N   O F   I N V O I C E'
    space(79 - length('S P E C I F I C A T I O N   O F   I N V O I C E') - length('EURO-MIT STAAL B.V.'))
    'EURO-MIT STAAL B.V.' skip
    space(5) fill('_',79) skip(1).
  
  put unformatted
    space(5) 'Sales Contract no. : EMS-' sord.gjobc "-" sord.sordn /*"  NEU"*/ skip
    space(5) 'Contract Date      : ' sord.sorddorddt format "99/99/9999" skip  
    space(5) 'ETD EMS            : ' ttru.ttrudexems format "99/99/9999" skip(1)
    space(5) 'Client             : ' bfCln.gcomm skip
    space(5) 'Client P/O No.     : ' sord.sordtcustordcd skip
    space(5) 'Grade              : ' vCustGrade /*OLD**trim(sord.ggrac)*/ skip(1)
    space(5) 'Invoice            : ' v-iinvn skip(1)
    .
  
  for first ttru where ttru.xlevc = f-xlevc('ttruck')
  and ttru.ttruc = v-ttruc no-lock,
  first sord where sord.xlevc = f-xlevc('sorder')
  and sord.sordn = ttru.sordn no-lock,
  first bfCln where bfCln.xlevc = f-xlevc('gcompany')
  and bfCln.gcomn = sord.gcomnclient no-lock,
  each bPal no-lock where bPal.xlevc = '1'
  and bPal.ttruc = ttru.ttruc 
  and can-find(first bCol where bCol.cpaln = bPal.cpaln and bCol.eu = false),
  each bCol no-lock where bCol.xlevc = '1'
  and bCol.cpaln = bPal.cpaln
  and bCol.eu = false
  break by bCol.ocoiawidth:
    assign vMetric = 1000.
    if sord.gjobc = "H" then vMetric = 1.
    assign
      vSizeQty = vSizeQty + bCol.ocoinweight
      vProdQty = vProdQty + bCol.ocoinweight.
    if first-of(bCol.ocoiawidth) then assign nSizes = nSizes + 1.
    if last-of(bCol.ocoiawidth) then
    do:
      find first ssiz no-lock where ssiz.xlevc = f-xlevc('ssizes') and ssiz.sordn = sord.sordn and ssiz.ssizawidth = bCol.ocoiawidth.
      vCbsCode = FN_HsCode(bcol.ocoiawidth,bcol.gjobc,"coil",bcol.ggrac).
      display space(5)
        bCol.ocoiawidth column-label "Width"
        vSizeQty        format ">,>>>,>>9" column-label "Produced!Qty"
        ssiz.ssizaprice format ">>,>>9.99" column-label "Price/mt"
        sord.gcurc                           no-label
        round(vSizeQty / vMetric * ssiz.ssizaprice,2) format ">>>,>>9.99" column-label "Amount!per size"
        vCbsCode format "x(8)" column-label "HS-code"
        with stream-io no-box width 148.
      assign vSizeAmt = vSizeAmt + round(vSizeQty / vMetric * ssiz.ssizaprice,2).
      assign vSizeQty = 0.
    end.
  end.
  
  put unformatted skip(1)
    '#' + string(nSizes) at 10    
    vProdQty format ">,>>>,>>9" at 16
    vSizeAmt format ">>>,>>9.99"at 40
    skip.
  
  /*** ATTACHED SHEET (part 3) ***/
  page.
  run ipPrintAS_C2.
  /****
  put unformatted skip(2)
    space(5) 'A T T A C H E D   S H E E T'
    space(79 - length('A T T A C H E D   S H E E T') - length('EURO-MIT STAAL B.V.'))
    'EURO-MIT STAAL B.V.' skip
    space(5) today format "99/99/9999" space(79 - length("99/99/9999") - length("page 1 ")) 'Page 1'skip
    space(5) fill('_',79) skip(1).
  assign lines = lines + 3.
  
  for first ttru no-lock where ttru.xlevc = f-xlevc('ttruck')
  and ttru.ttruc = v-ttruc ,
  first sord no-lock where sord.xlevc = f-xlevc('sorder')
  and sord.sordn = ttru.sordn ,
  first gcom no-lock where gcom.xlevc = f-xlevc('gcompany')
  and gcom.gcomn = sord.gcomnclient :
    put unformatted
      space(5) "Sales Contract no.  : EMS-" sord.gjobc "-" sord.sordn skip 
      space(5) "Load no.            : " ttru.ttruc /*"  NEU"*/ skip
      space(5) "Client              : " gcom.gcomm skip
      space(5) "Grade               : " vCustGrade /*OLD**trim(sord.ggrac)*/ skip
      space(5) "Client P/O No.      : " sord.sordtcustordcd skip
      space(5) fill('_',79) format "x(79)" skip(1).
    assign lines = lines + 8.
  end.
  
  put
    space(5) 'Pallet    EMS-col-nr               Width   Length Weight P-Nett  P-Gross' skip
    space(5) '--------- ------------------------ ------- ------ ------ ------- -------' skip.
  
  assign lines = lines + 2.
  
  for each bPal no-lock where bPal.xlevc = '1'
  and bPal.ttruc = v-ttruc 
  and can-find(first bCol where bCol.cpaln = bPal.cpaln and bCol.eu = false)
  by bPal.cpaln:
    assign
      nCoils = 0
      vNetWgtPal = 0
      vPalsInTrc = vPalsInTrc + 1
      vGrsWgtTrc = vGrsWgtTrc + bPal.cpalngrossweight.
  
    for each bCol no-lock where bCol.xlevc = '1'
    and bCol.cpaln = bPal.cpaln 
    and bCol.eu = false
    by bCol.ocoiawidth by bCol.ocoic:
      assign lines = lines + 1.
      if lines gt 60 then
      do:
        assign
          lines = 5
          pages = pages + 1.
        page.
        put unformatted skip(2)
          space(5) 'A T T A C H E D   S H E E T'
          space(79 - length('A T T A C H E D   S H E E T') - length('EURO-MIT STAAL B.V.'))
          'EURO-MIT STAAL B.V.' skip
          space(5) today format "99/99/9999" space(79 - length("99/99/9999") - length("page ###")) 'Page ' string(pages) format "x(3)" skip
          space(5) fill('_',79) skip(1).
      end.
      assign
        nCoils = nCoils + 1
        vColsInTrc = vColsInTrc + 1
        vNetWgtPal = vNetWgtPal + bCol.ocoinweight
        vNetWgtTrc = vNetWgtTrc + bCol.ocoinweight.
  
      if nCoils gt 1 then put skip space(5)
        space(9) ' '
        bCol.ocoic format "x(26)"
        bCol.ocoiawidth format ">>>9.9"
        bCol.ocoinlength format ">>>>>>9"
        bCol.ocoinweight format ">>>,>>9".
      else put space(5)
        bPal.cpalm format "x(9)" ' '
        bCol.ocoic format "x(26)"
        bCol.ocoiawidth format ">>>9.9"
        bCol.ocoinlength format ">>>>>>9"
        bCol.ocoinweight format ">>>,>>9".
    end. /*for-each-coil*/
    assign lines = lines + 1.
    put skip space(5)
      space(50) '------ '
      vNetWgtPal format ">>>,>>9" ' '
      bPal.cpalngrossweight format ">>,>>9" skip.
  end.
  
  put unformatted skip
    space(5) '------- -------------------------- ------- ------ ------ ------- -------' skip
    space(5) vPalsInTrc ' pallets, ' vColsInTrc ' coils.' space(30)
    vNetWgtTrc at 63 format ">>>,>>9"
    vGrsWgtTrc at 71 format ">>>,>>9" skip.
  *****/
  
  
  /*** CREATE RECORD INVOICE ***/
  if v-output = "1" then 
  do:
    for first ttru no-lock where ttru.xlevc = f-xlevc('ttruck')
    and ttru.ttruc = v-ttruc ,
    first sord no-lock where sord.xlevc = f-xlevc('sorder')
    and sord.sordn = ttru.sordn ,
    first gcom no-lock where gcom.xlevc = f-xlevc('gcompany')
    and gcom.gcomn = sord.gcomnagent ,
    first bfCln no-lock where bfCln.xlevc = f-xlevc('gcompany')
    and bfCln.gcomn = sord.gcomnclient ,
    first gcur no-lock where gcurrency.xlevc = f-xlevc('gcurrency') 
    and gcurrency.gcurc = sord.gcurc:
  
    create iinv.
    assign
      iinv.gcomnagent     = sord.gcomnagent
      iinv.iinvtdebtor    = gcom.gcomtshortname
      iinv.gcomnclient    = sord.gcomnclient
      iinv.iinvtclient    = bfCln.gcomtshortname
      iinv.gcurc          = sord.gcurc
      iinv.iinvarate      = gcur.gcurarate
      iinv.iinvdduedate   = v-duedate
      iinv.iinvdinvdt     = v-iinvdt
      iinv.iinvn          = v-iinvn
      iinv.iinvainvoiceam = round((vBaseAmt + v-AddCosts + v-ClearCharges),2) * (1 + v-vat / 100)
      iinv.sordn          = ttru.sordn
      iinv.iinvapayextra  = v-AddCosts + v-ClearCharges /* non operating charges */
      iinv.iinvdreceived  = ?
      iinv.iinvtreference = v-ttruc
      iinv.iinvqquantity  = vNettWgt
      iinv.iinvaimpduties = v-impd
      iinv.iinvasalesamt  = vBaseAmt
      iinv.iinvaadjamt    = 0
      iinv.iinvavatamt    = round((vBaseAmt + v-AddCosts + v-ClearCharges),2) * (v-vat / 100)
      iinv.iinvtictcode   = vIctCode
      iinv.gjobc          = sord.gjobc
      iinv.xstac          = '100'
      iinv.iinvtdlvtext   = v-dlvtext
      iinv.iinvtdir       = ''
      .
  
    release iinv.
  
    end.
  end.
  /* else do not assign because of preview */

end. /*transaction*/

END PROCEDURE. /*ipNEU*/


PROCEDURE ipEU:

do transaction:

  if v-output = "1" then  
    run x/xseql.p(input f-xlevc('iinv'), input 'iinvn', output v-iinvn).

  /* determine all cbscodes*/
  for each bPal no-lock where bPal.xlevc = '1'
  and bPal.ttruc = ttru.ttruc,
  each bCol no-lock where bCol.xlevc = '1'
  and bCol.cpaln = bPal.cpaln
  and bCol.eu = true:
    vCbsCode = string(FN_HsCode(bCol.ocoiawidth,bCol.gjobc,"coil",bCol.ggrac),"x(8)").
    if index(vAllCbsCodes,vCbsCode) = 0 then vAllCbsCodes = vAllCbsCodes + minimum(',',vAllCbsCodes) + vCbsCode.
  end.

  /* COUNT PALLETS, COILS */
  for each bPal no-lock where bPal.xlevc = '1'
  and bPal.ttruc = ttru.ttruc
  and can-find(first bCol where bCol.cpaln = bPal.cpaln and bCol.eu = true):
    assign
      vGrossWgt = vGrossWgt + bPal.cpalngrossweight
      npallets = npallets + 1.
    for each bCol no-lock where bCol.xlevc = '1'
    and bCol.cpaln = bPal.cpaln
    and bCol.eu = true:
      find first ssizes no-lock where ssiz.xlevc = f-xlevc('ssizes') and ssiz.sordn = bCol.sordn and ssiz.ssizawidth = bCol.ocoiawidth.
      assign
        nCoils = nCoils + 1
        vNettWgt = vNettWgt + bCol.ocoinweight.
      if v-output = "1" then run proc\c-invcol.p(bCol.ocoin,v-iinvn,ssiz.ssizaprice,"C"). 
    end.
  end.
  
  /*DETERMINE QTY AND SALESAMT */
  for first ttru no-lock where ttru.xlevc = f-xlevc('ttruck')
  and ttru.ttruc = v-ttruc,
  first sord no-lock where sord.xlevc = f-xlevc('sorder')
  and sord.sordn = ttru.sordn ,
  first bfCln no-lock where bfCln.xlevc = f-xlevc('gcompany')
  and bfCln.gcomn = sord.gcomnclient ,
  each bPal no-lock where bPal.xlevc = '1'
  and bPal.ttruc = ttru.ttruc
  and can-find(first bCol where bCol.cpaln = bPal.cpaln and bCol.eu = true),
  each bCol no-lock where bCol.xlevc = '1'
  and bCol.cpaln = bPal.cpaln
  and bCol.eu = true
  break by bCol.ocoiawidth:
    assign
      vSizeQty = vSizeQty + bCol.ocoinweight
      vProdQty = vProdQty + bCol.ocoinweight.
    if first-of(bCol.ocoiawidth) then assign nSizes = nSizes + 1.
    if last-of(bCol.ocoiawidth) then
    do:
      find first ssizes no-lock where ssiz.xlevc = f-xlevc('ssizes') and ssiz.sordn = sord.sordn and ssiz.ssizawidth = bCol.ocoiawidth.
      case sord.gjobc:
        when "S" then assign vBaseAmt = vBaseAmt + round(vSizeQty / 1000 * ssiz.ssizaprice,2).
        when "T" then assign vBaseAmt = vBaseAmt + round(vSizeQty / 1000 * ssiz.ssizaprice,2).
        when "H" then assign vBaseAmt = vBaseAmt + round(vSizeQty * ssiz.ssizaprice,2).
      end case.
      assign vSizeQty = 0.
    end.
  end. /* for-first-truck */

  run ipSetIct.

  find b2-gcou no-lock where b2-gcou.xlevc = f-xlevc('gcountry') and b2-gcou.gcouc = sord.gcouc.
  find first gcou no-lock where gcou.xlevc = f-xlevc('gcountry') and gcou.gcouc = gadr.gcouc.
  assign v-countryname = gcou.gcoum.
  find first gcou no-lock where gcou.xlevc = f-xlevc('gcountry') and gcou.gcouc = bfCustadres.gcouc .
  assign v-clientcountry = gcou.gcoum.
      
  /*ORG:
  put unformatted skip(9) /* amity:emm6-0059 EMS-BRIEFHOOFD! */
    space(5) 'I N V O I C E' skip
    space(5) "" skip
    space(5) 'Invoice No.        : ' trim(string(v-iinvn,"99999999")) skip
    space(5) 'Sales Contract no. : EMS-' sord.gjobc "-" string(sord.sordn)
      "Vlissingen, " + string(v-iinvdt,"99/99/9999") at 60 skip
    space(5) 'Load no.           : ' ttru.ttruc /*"  EU"*/ skip
    space(5) 'Your reference     : ' sord.sordtagentordcd skip(1)
    space(5) 'Messrs.            : ' trim(gadr.gadrtname) + ' ' + trim(gadr.gadrtname2) skip
    space(5) '                     ' trim(gadr.gadrtstreet1) + '  ' + trim(gadr.gadrtstreet2) skip
    space(5) '                     ' trim(gadr.gadrtzipcode) + '  ' + trim(gadr.gadrtcity) skip
    space(5) '                     ' v-countryname skip(1). 
  END-ORG*/

  put unformatted skip(9) /* amity:emm6-0059 EMS-BRIEFHOOFD! */
    space(5) 'I N V O I C E' skip
    space(5) "" skip
    space(5) 'Invoice No.        : ' trim(string(v-iinvn,"99999999")) skip
    space(5) 'Sales Contract no. : EMS-' sord.gjobc "-" string(sord.sordn)
      "Vlissingen, " + string(v-iinvdt,"99/99/9999") at 60 skip
    space(5) 'Load no.           : ' ttru.ttruc /*"  EU"*/ skip
    space(5) 'Your reference     : ' sord.sordtagentordcd skip(1)
    /*ORG: space(5) 'Messrs.            : ' trim(gadr.gadrtname) + ' ' + trim(gadr.gadrtname2) skip*/
    space(5) 'Messrs.            : ' trim(gadr.gadrtname) skip.
  if trim(gadr.gadrtname2) NE '' then 
  put unformatted 
    space(5) '                     ' trim(gadr.gadrtname2) skip.
  put unformatted 
    space(5) '                     ' trim(gadr.gadrtstreet1) + '  ' + trim(gadr.gadrtstreet2) skip
    space(5) '                     ' trim(gadr.gadrtzipcode) + '  ' + trim(gadr.gadrtcity) skip
    space(5) '                     ' v-countryname skip(1).

  put unformatted 
    space(5) 'Description        : ' /*vGoods skip(1)*/. 
  display 
    space(26) vGoods 
    VIEW-AS EDITOR SIZE 59 BY 1 
    no-label
    with stream-io no-box width 148.
  put unformatted 
    space(5) "HS-code            : " vAllCbsCodes  skip.
  put unformatted
    space(5) 'Grade              : ' vCustGrade /*OLD**trim(sord.ggrac)*/ vGradeSpec skip
    space(5) '                     Details as per contract' skip(1)
    space(5) 'Total Quantity     : ' vNettWgt / 1000 format ">>9.999" ' m/t nett weight' skip
    space(5) '                     ' vGrossWgt / 1000 format ">>9.999" ' m/t gross weight' skip(1)
    space(5) 'Contract price     : ' sord.gcurc ' ' vBaseAmt format "->,>>>,>>>,>>9.99" ' ,see attached specification for details' skip
    space(5) 'Add. costs         : ' sord.gcurc ' ' v-AddCosts format "->,>>>,>>>,>>9.99" skip.
  /*message '#3' skip vMix skip v-impd view-as alert-box.*/
    if dec(v-impdut) ne 0 then
  put unformatted
    space(5) 'Import duties      : ' sord.gcurc ' ' dec(v-impdut) format "->,>>>,>>>,>>9.99" skip.
  put unformatted
    space(5) 'Total excl.VAT     : ' sord.gcurc ' ' round((vBaseAmt + v-AddCosts + v-impd + v-ClearCharges),2) format "->,>>>,>>>,>>9.99" skip
    space(5) 'VAT ' v-vat format ">9.9" '%          : ' sord.gcurc ' ' round((vBaseAmt + v-AddCosts + v-impd + v-ClearCharges),2) * (v-vat / 100) format "->,>>>,>>>,>>9.99" skip
    space(5) 'Total incl.VAT     : ' sord.gcurc ' ' round((vBaseAmt + v-AddCosts + v-impd + v-ClearCharges),2) * (1 + v-vat / 100) format "->,>>>,>>>,>>9.99" skip.
  if vIctCode EQ "ICP" and v-vat EQ 0 then put unformatted space(15) vVatText skip.
  put unformatted
    skip(1)
  /*space(5) 'dIT IS EXTRA REGEL VOOR VAT: taxfree, obliged, recipient, ' fill('.',25) skip*/
    space(5) 'Terms of payment   : ' v-payterms skip
    space(5) 'Client             : ' trim(bfCln.gcomm) ', ' v-clientcountry skip 
    space(5) 'Client P/O No.     : ' sord.sordtcustordcd skip
    space(5) 'Place of delivery  : ' trim(sord.sordtdesti-city) ', ' b2-gcou.gcoum skip
    space(5) 'Manufacturer       : ' v-manufacturer skip.
  if l-Origin  = true then put unformatted
    space(5) 'Country of origin  : ' v-Origin skip.
  put unformatted
    space(5) 'Delivery conditions: ' v-dlvtext skip
    space(5) 'Shipment           : on or about ' ttru.ttrudexems format "99/99/9999" skip
    space(5) "Packing            : EMS' Standard Packing " trim(string(nCoils)) ' coils, ' trim(string(npallets)) ' pallets' skip
    space(5) "Weighing           : EMS' actual weighing shall be taken as final" skip
    space(5) "Insurance          : " v-insurance skip
    space(5) "Inspection         : Manufacturer's inspection to be taken as final" skip
    space(5) "Due date           : " v-duedate format "99/99/9999" skip
    space(5) "Bank               : Deutsche Bank AG, Amsterdam" skip
    space(5) "                     " if sorder.gcurc eq "USD" then "Account nr. 026.50.64.864" else "Account nr. 026.54.21.721" skip
    space(5) "                     " if sorder.gcurc eq "USD" then "IBAN NL73DEUT0265064864" else "IBAN NL41DEUT0265421721"  "   SWIFT BIC: DEUTNL2A" skip       /*ku EMM6-0040 : Condition added to correct the bank balance */               
    space(5) "EMS V.A.T. No.     : NL800275937B01" skip
    space(5) "Your V.A.T. No.    : " v-vatno skip(1)
    space(5) "              " if sorder.sordlentrepot eq true and sorder.sordldutypaid eq false and sorder.sordleu ne true then "Inward Processing - Suspensions(IP-S)goods under customs control"               /*EMM6-0006 : Added a same condiion for text apperance at the bottom of report                  */
    else if sorder.sordleu ne true and sorder.sordldutypaid eq true then "Goods in free circulation - anti-dumping duty paid in Netherlands"                                                                     /*EMM6-0028 : Added a logic for printing a line automatically depending upon EU or NEU materail */
    else ""  skip(1)
    space(5) "      -- Details as per attached sheet --" skip(2).
  put unformatted
    "EURO-MIT STAAL B.V." at 51 skip(1)
    vSignature            at 51 skip
    "Managing Director  " at 51 skip.
  
  /*** PART TWO OF INVOICE ***/
  page.
  assign
    nSizes = 0
    vProdQty = 0.
  
  put unformatted skip(2)
    space(5) 'S P E C I F I C A T I O N   O F   I N V O I C E'
    space(79 - length('S P E C I F I C A T I O N   O F   I N V O I C E') - length('EURO-MIT STAAL B.V.'))
    'EURO-MIT STAAL B.V.' skip
    space(5) fill('_',79) skip(1).
  
  put unformatted
    space(5) 'Sales Contract no. : EMS-' sord.gjobc "-" sord.sordn /*"  EU"*/ skip
    space(5) 'Contract Date      : ' sord.sorddorddt format "99/99/9999" skip  
    space(5) 'ETD EMS            : ' ttru.ttrudexems format "99/99/9999" skip(1)
    space(5) 'Client             : ' bfCln.gcomm skip
    space(5) 'Client P/O No.     : ' sord.sordtcustordcd skip
    space(5) 'Grade              : ' vCustGrade /*OLD**trim(sord.ggrac)*/ skip(1)
    space(5) 'Invoice            : ' v-iinvn skip(1)
    .
  
  for first ttru where ttru.xlevc = f-xlevc('ttruck')
  and ttru.ttruc = v-ttruc no-lock,
  first sord where sord.xlevc = f-xlevc('sorder')
  and sord.sordn = ttru.sordn no-lock,
  first bfCln where bfCln.xlevc = f-xlevc('gcompany')
  and bfCln.gcomn = sord.gcomnclient no-lock,
  each bPal no-lock where bPal.xlevc = '1'
  and bPal.ttruc = ttru.ttruc 
  and can-find(first bCol where bCol.cpaln = bPal.cpaln and bCol.eu = true),
  each bCol no-lock where bCol.xlevc = '1'
  and bCol.cpaln = bPal.cpaln
  and bCol.eu = true
  break by bCol.ocoiawidth:
    assign vMetric = 1000.
    if sord.gjobc = "H" then vMetric = 1.
    assign
      vSizeQty = vSizeQty + bCol.ocoinweight
      vProdQty = vProdQty + bCol.ocoinweight.
    if first-of(bCol.ocoiawidth) then assign nSizes = nSizes + 1.
    if last-of(bCol.ocoiawidth) then
    do:
      find first ssiz no-lock where ssiz.xlevc = f-xlevc('ssizes') and ssiz.sordn = sord.sordn and ssiz.ssizawidth = bCol.ocoiawidth.
      vCbsCode = FN_HsCode(bcol.ocoiawidth,bcol.gjobc,"coil",bcol.ggrac).
      display space(5)
        bCol.ocoiawidth column-label "Width"
        vSizeQty        format ">,>>>,>>9" column-label "Produced!Qty"
        ssiz.ssizaprice format ">>,>>9.99" column-label "Price/mt"
        sord.gcurc                           no-label
        round(vSizeQty / vMetric * ssiz.ssizaprice,2) format ">>>,>>9.99" column-label "Amount!per size"
        vCbsCode format "x(8)" column-label "HS-code"
        with stream-io no-box width 148.
      assign vSizeAmt = vSizeAmt + round(vSizeQty / vMetric * ssiz.ssizaprice,2).
      assign vSizeQty = 0.
    end.
  end.
  
  put unformatted skip(1)
    '#' + string(nSizes) at 10    
    vProdQty format ">,>>>,>>9" at 16
    vSizeAmt format ">>>,>>9.99"at 40
    skip.
  
  /*** ATTACHED SHEET (part 3) ***/
  page.
  run ipPrintAS_C1.
  /**********
  put unformatted skip(2)
    space(5) 'A T T A C H E D   S H E E T'
    space(79 - length('A T T A C H E D   S H E E T') - length('EURO-MIT STAAL B.V.'))
    'EURO-MIT STAAL B.V.' skip
    space(5) today format "99/99/9999" space(79 - length("99/99/9999") - length("page 1 ")) 'Page 1'skip
    space(5) fill('_',79) skip(1).
  assign lines = lines + 3.
  
  for first ttru no-lock where ttru.xlevc = f-xlevc('ttruck')
  and ttru.ttruc = v-ttruc ,
  first sord no-lock where sord.xlevc = f-xlevc('sorder')
  and sord.sordn = ttru.sordn ,
  first gcom no-lock where gcom.xlevc = f-xlevc('gcompany')
  and gcom.gcomn = sord.gcomnclient :
    put unformatted
      space(5) "Sales Contract no.  : EMS-" sord.gjobc "-" sord.sordn /*"  EU"*/ skip 
      space(5) "Load no.            : " ttru.ttruc skip
      space(5) "Client              : " gcom.gcomm skip
      space(5) "Grade               : " vCustGrade /*OLD**trim(sord.ggrac)*/ skip
      space(5) "Client P/O No.      : " sord.sordtcustordcd skip
      space(5) fill('_',79) format "x(79)" skip(1).
    assign lines = lines + 8.
  end.
  
  put
    space(5) 'Pallet    EMS-col-nr               Width   Length Weight P-Nett  P-Gross' skip
    space(5) '--------- ------------------------ ------- ------ ------ ------- -------' skip.
  
  assign lines = lines + 2.
  
  for each bPal no-lock where bPal.xlevc = '1'
  and bPal.ttruc = v-ttruc 
  and can-find(first bCol where bCol.cpaln = bPal.cpaln and bCol.eu = true)
  by bPal.cpaln:
    assign
      nCoils = 0
      vNetWgtPal = 0
      vPalsInTrc = vPalsInTrc + 1
      vGrsWgtTrc = vGrsWgtTrc + bPal.cpalngrossweight.
  
    for each bCol no-lock where bCol.xlevc = '1'
    and bCol.cpaln = bPal.cpaln 
    and bCol.eu = true
    by bCol.ocoiawidth by bCol.ocoic:
      assign lines = lines + 1.
      if lines gt 60 then
      do:
        assign
          lines = 5
          pages = pages + 1.
        page.
        put unformatted skip(2)
          space(5) 'A T T A C H E D   S H E E T'
          space(79 - length('A T T A C H E D   S H E E T') - length('EURO-MIT STAAL B.V.'))
          'EURO-MIT STAAL B.V.' skip
          space(5) today format "99/99/9999" space(79 - length("99/99/9999") - length("page ###")) 'Page ' string(pages) format "x(3)" skip
          space(5) fill('_',79) skip(1).
      end.
      assign
        nCoils = nCoils + 1
        vColsInTrc = vColsInTrc + 1
        vNetWgtPal = vNetWgtPal + bCol.ocoinweight
        vNetWgtTrc = vNetWgtTrc + bCol.ocoinweight.
  
      if nCoils gt 1 then put skip space(5)
        space(9) ' '
        bCol.ocoic format "x(26)"
        bCol.ocoiawidth format ">>>9.9"
        bCol.ocoinlength format ">>>>>>9"
        bCol.ocoinweight format ">>>,>>9".
      else put space(5)
        bPal.cpalm format "x(9)" ' '
        bCol.ocoic format "x(26)"
        bCol.ocoiawidth format ">>>9.9"
        bCol.ocoinlength format ">>>>>>9"
        bCol.ocoinweight format ">>>,>>9".
    end. /*for-each-coil*/
    assign lines = lines + 1.
    put skip space(5)
      space(50) '------ '
      vNetWgtPal format ">>>,>>9" ' '
      bPal.cpalngrossweight format ">>,>>9" skip.
  end.
  
  put unformatted skip
    space(5) '------- -------------------------- ------- ------ ------ ------- -------' skip
    space(5) vPalsInTrc ' pallets, ' vColsInTrc ' coils.' space(30)
    vNetWgtTrc at 63 format ">>>,>>9"
    vGrsWgtTrc at 71 format ">>>,>>9" skip.
  **********/
  
  
  /*** CREATE RECORD INVOICE ***/
  if v-output = "1" then 
  do:
    for first ttru no-lock where ttru.xlevc = f-xlevc('ttruck')
    and ttru.ttruc = v-ttruc ,
    first sord no-lock where sord.xlevc = f-xlevc('sorder')
    and sord.sordn = ttru.sordn ,
    first gcom no-lock where gcom.xlevc = f-xlevc('gcompany')
    and gcom.gcomn = sord.gcomnagent ,
    first bfCln no-lock where bfCln.xlevc = f-xlevc('gcompany')
    and bfCln.gcomn = sord.gcomnclient ,
    first gcur no-lock where gcurrency.xlevc = f-xlevc('gcurrency') 
    and gcurrency.gcurc = sord.gcurc:
  
    create iinv.
    assign
      iinv.gcomnagent     = sord.gcomnagent
      iinv.iinvtdebtor    = gcom.gcomtshortname
      iinv.gcomnclient    = sord.gcomnclient
      iinv.iinvtclient    = bfCln.gcomtshortname
      iinv.gcurc          = sord.gcurc
      iinv.iinvarate      = gcur.gcurarate
      iinv.iinvdduedate   = v-duedate
      iinv.iinvdinvdt     = v-iinvdt
      iinv.iinvn          = v-iinvn
      iinv.iinvainvoiceam = round((vBaseAmt + v-AddCosts + v-ClearCharges),2) * (1 + v-vat / 100)
      iinv.sordn          = ttru.sordn
      iinv.iinvapayextra  = v-AddCosts + v-ClearCharges /* non operating charges */
      iinv.iinvdreceived  = ?
      iinv.iinvtreference = v-ttruc
      iinv.iinvqquantity  = vNettWgt
      iinv.iinvaimpduties = v-impd
      iinv.iinvasalesamt  = vBaseAmt
      iinv.iinvaadjamt    = 0
      iinv.iinvavatamt    = round((vBaseAmt + v-AddCosts + v-ClearCharges),2) * (v-vat / 100)
      iinv.iinvtictcode   = vIctCode
      iinv.gjobc          = sord.gjobc
      iinv.xstac          = '100'
      iinv.iinvtdlvtext   = v-dlvtext
      iinv.iinvtdir       = ''
      .
  
    release iinv.
  
    end.
  end.
  /* else do not assign because of preview */

end. /*transaction*/

END PROCEDURE. /*ipEU*/


PROCEDURE ipSingle:

do transaction:

  if v-output = "1" then  
    run x/xseql.p(input f-xlevc('iinv'), input 'iinvn', output v-iinvn).

  /* determine all cbscodes*/
  for each cPal no-lock where cPal.xlevc = '1'
  and cPal.ttruc = ttru.ttruc,
  each ocoi no-lock where ocoi.xlevc = '1'
  and ocoi.cpaln = cPal.cpaln:
    vCbsCode = string(FN_HsCode(ocoi.ocoiawidth,ocoi.gjobc,"coil",ocoi.ggrac),"x(8)").
    if index(vAllCbsCodes,vCbsCode) = 0 then vAllCbsCodes = vAllCbsCodes + minimum(',',vAllCbsCodes) + vCbsCode.
  end.

  /* COUNT PALLETS, COILS */
  for each cpal no-lock where cpal.xlevc = f-xlevc('cpallet')
  and cpal.ttruc = ttru.ttruc:
    assign
      vGrossWgt = vGrossWgt + cpal.cpalngrossweight
      npallets = npallets + 1.
    for each ocoi no-lock where ocoi.xlevc = f-xlevc('ocoil')
    and ocoi.cpaln = cpal.cpaln:
      find first ssizes no-lock where ssiz.xlevc = f-xlevc('ssizes') and ssiz.sordn = ocoi.sordn and ssiz.ssizawidth = ocoi.ocoiawidth.
      assign
        nCoils = nCoils + 1
        vNettWgt = vNettWgt + ocoi.ocoinweight.
      if v-output = "1" then run proc\c-invcol.p(ocoi.ocoin,v-iinvn,ssiz.ssizaprice,"C"). 
    end.
  end.
  
  /*DETERMINE QTY AND SALESAMT */
  for first ttru no-lock where ttru.xlevc = f-xlevc('ttruck')
  and ttru.ttruc = v-ttruc,
  first sord no-lock where sord.xlevc = f-xlevc('sorder')
  and sord.sordn = ttru.sordn ,
  first bfCln no-lock where bfCln.xlevc = f-xlevc('gcompany')
  and bfCln.gcomn = sord.gcomnclient ,
  each cpal no-lock where cpal.xlevc = f-xlevc('cpallet')
  and cpal.ttruc = ttru.ttruc ,
  each ocoi no-lock where ocoi.xlevc = f-xlevc('ocoil')
  and ocoi.cpaln = cpal.cpaln
  break by ocoi.ocoiawidth:
    assign
      vSizeQty = vSizeQty + ocoi.ocoinweight
      vProdQty = vProdQty + ocoi.ocoinweight.
    if first-of(ocoi.ocoiawidth) then assign nSizes = nSizes + 1.
    if last-of(ocoi.ocoiawidth) then
    do:
      find first ssizes no-lock where ssiz.xlevc = f-xlevc('ssizes') and ssiz.sordn = sord.sordn and ssiz.ssizawidth = ocoi.ocoiawidth.
      case sord.gjobc:
        when "S" then assign vBaseAmt = vBaseAmt + round(vSizeQty / 1000 * ssiz.ssizaprice,2).
        when "T" then assign vBaseAmt = vBaseAmt + round(vSizeQty / 1000 * ssiz.ssizaprice,2).
        when "H" then assign vBaseAmt = vBaseAmt + round(vSizeQty * ssiz.ssizaprice,2).
      end case.
      assign vSizeQty = 0.
    end.
  end. /* for-first-truck */

  run ipSetIct.

  find b2-gcou no-lock where b2-gcou.xlevc = f-xlevc('gcountry') and b2-gcou.gcouc = sord.gcouc.
  find first gcou no-lock where gcou.xlevc = f-xlevc('gcountry') and gcou.gcouc = gadr.gcouc.
  assign v-countryname = gcou.gcoum.
  find first gcou no-lock where gcou.xlevc = f-xlevc('gcountry') and gcou.gcouc = bfCustadres.gcouc .
  assign v-clientcountry = gcou.gcoum.
      
  /*ORG:
  put unformatted skip(9) /* EMS-BRIEFHOOFD! */
    space(5) 'I N V O I C E' skip
    space(5) "" skip
    space(5) 'Invoice No.        : ' trim(string(v-iinvn,"99999999")) skip
    space(5) 'Sales Contract no. : EMS-' sord.gjobc "-" string(sord.sordn)
      "Vlissingen, " + string(v-iinvdt,"99/99/9999") at 60 skip
    space(5) 'Load no.           : ' ttru.ttruc skip
    space(5) 'Your reference     : ' sord.sordtagentordcd skip(1)
    space(5) 'Messrs.            : ' trim(gadr.gadrtname) + ' ' + trim(gadr.gadrtname2) skip
    space(5) '                     ' trim(gadr.gadrtstreet1) + '  ' + trim(gadr.gadrtstreet2) skip
    space(5) '                     ' trim(gadr.gadrtzipcode) + '  ' + trim(gadr.gadrtcity) skip
    space(5) '                     ' v-countryname skip(1). 
  END-ORG*/

  put unformatted skip(9) /* amity: emm6-0059 EMS-BRIEFHOOFD! */
    space(5) 'I N V O I C E' skip
    space(5) "" skip
    space(5) 'Invoice No.        : ' trim(string(v-iinvn,"99999999")) skip
    space(5) 'Sales Contract no. : EMS-' sord.gjobc "-" string(sord.sordn)
      "Vlissingen, " + string(v-iinvdt,"99/99/9999") at 60 skip
    space(5) 'Load no.           : ' ttru.ttruc skip
    space(5) 'Your reference     : ' sord.sordtagentordcd skip(1)
    /*ORG: space(5) 'Messrs.            : ' trim(gadr.gadrtname) + ' ' + trim(gadr.gadrtname2) skip*/
    space(5) 'Messrs.            : ' trim(gadr.gadrtname) skip.
  if trim(gadr.gadrtname2) NE '' then 
  put unformatted 
    space(5) '                     ' trim(gadr.gadrtname2) skip.
  put unformatted 
    space(5) '                     ' trim(gadr.gadrtstreet1) + '  ' + trim(gadr.gadrtstreet2) skip
    space(5) '                     ' trim(gadr.gadrtzipcode) + '  ' + trim(gadr.gadrtcity) skip
    space(5) '                     ' v-countryname skip(1).

  put unformatted 
    space(5) 'Description        : ' /*vGoods skip(1)*/. 
  display 
    space(26) vGoods 
    VIEW-AS EDITOR SIZE 59 BY 1 
    no-label
    with stream-io no-box width 148.
  put unformatted 
    space(5) "HS-code            : " vAllCbsCodes  skip.
  put unformatted
    space(5) 'Grade              : ' vCustGrade /*OLD**trim(sord.ggrac)*/ vGradeSpec skip
    space(5) '                     Details as per contract' skip(1)
    space(5) 'Total Quantity     : ' vNettWgt / 1000 format ">>9.999" ' m/t nett weight' skip
    space(5) '                     ' vGrossWgt / 1000 format ">>9.999" ' m/t gross weight' skip(1)
    space(5) 'Contract price     : ' sord.gcurc ' ' vBaseAmt format "->,>>>,>>>,>>9.99" ' ,see attached specification for details' skip
    space(5) 'Add. costs         : ' sord.gcurc ' ' v-AddCosts format "->,>>>,>>>,>>9.99" skip.
  /*message '#4' skip vMix skip v-impd view-as alert-box.*/
  if dec(v-impdut) ne 0 then
  put unformatted
    space(5) 'Import duties      : ' sord.gcurc ' ' dec(v-impdut) format "->,>>>,>>>,>>9.99" skip.
  put unformatted
    space(5) 'Total excl.VAT     : ' sord.gcurc ' ' round((vBaseAmt + v-AddCosts + v-impd + v-ClearCharges),2) format "->,>>>,>>>,>>9.99" skip
    space(5) 'VAT ' v-vat format ">9.9" '%          : ' sord.gcurc ' ' round((vBaseAmt + v-AddCosts + v-impd + v-ClearCharges),2) * (v-vat / 100) format "->,>>>,>>>,>>9.99" skip
    space(5) 'Total incl.VAT     : ' sord.gcurc ' ' round((vBaseAmt + v-AddCosts + v-impd + v-ClearCharges),2) * (1 + v-vat / 100) format "->,>>>,>>>,>>9.99" skip.
  if vIctCode EQ "ICP" and v-vat EQ 0 then put unformatted space(15) vVatText skip.
  put unformatted
    skip(1)
  /*space(5) 'dIT IS EXTRA REGEL VOOR VAT: taxfree, obliged, recipient, ' fill('.',25) skip*/
    space(5) 'Terms of payment   : ' v-payterms skip
    space(5) 'Client             : ' trim(bfCln.gcomm) ', ' v-clientcountry skip 
    space(5) 'Client P/O No.     : ' sord.sordtcustordcd skip
    space(5) 'Place of delivery  : ' trim(sord.sordtdesti-city) ', ' b2-gcou.gcoum skip
    space(5) 'Manufacturer       : ' v-manufacturer skip.
  if l-Origin  = true then put unformatted
    space(5) 'Country of origin  : ' v-Origin skip.
  put unformatted
    space(5) 'Delivery conditions: ' v-dlvtext skip
    space(5) 'Shipment           : on or about ' ttru.ttrudexems format "99/99/9999" skip
    space(5) "Packing            : EMS' Standard Packing " trim(string(nCoils)) ' coils, ' trim(string(npallets)) ' pallets' skip
    space(5) "Weighing           : EMS' actual weighing shall be taken as final" skip
    space(5) "Insurance          : " v-insurance skip
    space(5) "Inspection         : Manufacturer's inspection to be taken as final" skip
    space(5) "Due date           : " v-duedate format "99/99/9999" skip
    space(5) "Bank               : Deutsche Bank AG, Amsterdam" skip
    space(5) "                     " if sorder.gcurc eq "USD" then "Account nr. 026.50.64.864" else "Account nr. 026.54.21.721" skip
    space(5) "                     " if sorder.gcurc eq "USD" then "IBAN NL73DEUT0265064864" else "IBAN NL41DEUT0265421721"  "   SWIFT BIC: DEUTNL2A" skip       /*ku EMM6-0040 : Condition added to correct the bank balance */               
    space(5) "EMS V.A.T. No.     : NL800275937B01" skip
    space(5) "Your V.A.T. No.    : " v-vatno skip(1)
    space(5) "              " if sorder.sordlentrepot eq true and sorder.sordldutypaid eq false and sorder.sordleu ne true then "Inward Processing - Suspensions(IP-S)goods under customs control"               /*EMM6-0006 : Added a same condiion for text apperance at the bottom of report                  */
    else if sorder.sordleu ne true and sorder.sordldutypaid eq true then "Goods in free circulation - anti-dumping duty paid in Netherlands"                                                                     /*EMM6-0028 : Added a logic for printing a line automatically depending upon EU or NEU materail */
    else ""  skip(1)
    space(5) "      -- Details as per attached sheet --" skip(2).
  put unformatted
    "EURO-MIT STAAL B.V." at 51 skip(1)
    vSignature            at 51 skip
    "Managing Director  " at 51 skip.
  
  /*** PART TWO OF INVOICE ***/
  page.
  assign
    nSizes = 0
    vProdQty = 0.
  
  put unformatted skip(2)
    space(5) 'S P E C I F I C A T I O N   O F   I N V O I C E'
    space(79 - length('S P E C I F I C A T I O N   O F   I N V O I C E') - length('EURO-MIT STAAL B.V.'))
    'EURO-MIT STAAL B.V.' skip
    space(5) fill('_',79) skip(1).
  
  put unformatted
    space(5) 'Sales Contract no. : EMS-' sord.gjobc "-" sord.sordn skip
    space(5) 'Contract Date      : ' sord.sorddorddt format "99/99/9999" skip  
    space(5) 'ETD EMS            : ' ttru.ttrudexems format "99/99/9999" skip(1)
    space(5) 'Client             : ' bfCln.gcomm skip
    space(5) 'Client P/O No.     : ' sord.sordtcustordcd skip
    space(5) 'Grade              : ' vCustGrade /*OLD**trim(sord.ggrac)*/ skip(1)
    space(5) 'Invoice            : ' v-iinvn skip(1)
    .
  
  for first ttru where ttru.xlevc = f-xlevc('ttruck')
  and ttru.ttruc = v-ttruc no-lock,
  first sord where sord.xlevc = f-xlevc('sorder')
  and sord.sordn = ttru.sordn no-lock,
  first bfCln where bfCln.xlevc = f-xlevc('gcompany')
  and bfCln.gcomn = sord.gcomnclient no-lock,
  each cpal where cpal.xlevc = f-xlevc('cpallet')
  and cpal.ttruc = ttru.ttruc no-lock,
  each ocoi no-lock where ocoi.xlevc = f-xlevc('ocoil')
  and ocoi.cpaln = cpal.cpaln
  break by ocoi.ocoiawidth:
    assign vMetric = 1000.
    if sord.gjobc = "H" then vMetric = 1.
    assign
      vSizeQty = vSizeQty + ocoi.ocoinweight
      vProdQty = vProdQty + ocoi.ocoinweight.
    if first-of(ocoi.ocoiawidth) then assign nSizes = nSizes + 1.
    if last-of(ocoi.ocoiawidth) then
    do:
      find first ssiz no-lock where ssiz.xlevc = f-xlevc('ssizes') and ssiz.sordn = sord.sordn and ssiz.ssizawidth = ocoi.ocoiawidth.
      vCbsCode = FN_HsCode(ocoi.ocoiawidth,ocoi.gjobc,"coil",ocoi.ggrac).
      display space(5)
        ocoi.ocoiawidth
        vSizeQty        format ">,>>>,>>9" column-label "Produced!Qty"
        ssiz.ssizaprice format ">>,>>9.99" column-label "Price/mt"
        sord.gcurc                           no-label
        round(vSizeQty / vMetric * ssiz.ssizaprice,2) format ">>>,>>9.99" column-label "Amount!per size"
        vCbsCode format "x(8)" column-label "HS-code"
        with stream-io no-box width 148.
      assign vSizeAmt = vSizeAmt + round(vSizeQty / vMetric * ssiz.ssizaprice,2).
      assign vSizeQty = 0.
    end.
  end.
  
  put unformatted skip(1)
    '#' + string(nSizes) at 10    
    vProdQty format ">,>>>,>>9" at 16
    vSizeAmt format ">>>,>>9.99"at 40
    skip.
  
  /*** ATTACHED SHEET (part 3) ***/
  page.
  put unformatted skip(2)
    space(5) 'A T T A C H E D   S H E E T'
    space(79 - length('A T T A C H E D   S H E E T') - length('EURO-MIT STAAL B.V.'))
    'EURO-MIT STAAL B.V.' skip
    space(5) today format "99/99/9999" space(79 - length("99/99/9999") - length("page 1 ")) 'Page 1'skip
    space(5) fill('_',79) skip(1).
  assign lines = lines + 3.
  
  for first ttru no-lock where ttru.xlevc = f-xlevc('ttruck')
  and ttru.ttruc = v-ttruc ,
  first sord no-lock where sord.xlevc = f-xlevc('sorder')
  and sord.sordn = ttru.sordn ,
  first gcom no-lock where gcom.xlevc = f-xlevc('gcompany')
  and gcom.gcomn = sord.gcomnclient :
    put unformatted
      space(5) "Sales Contract no.  : EMS-" sord.gjobc "-" sord.sordn skip 
      space(5) "Load no.            : " ttru.ttruc skip
      space(5) "Client              : " gcom.gcomm skip
      space(5) "Grade               : " vCustGrade /*OLD**trim(sord.ggrac)*/ skip
      space(5) "Client P/O No.      : " sord.sordtcustordcd skip
      space(5) fill('_',79) format "x(79)" skip(1).
    assign lines = lines + 8.
  end.
  
  put
    space(5) 'Pallet    EMS-col-nr               Width   Length Weight P-Nett  P-Gross' skip
    space(5) '--------- ------------------------ ------- ------ ------ ------- -------' skip.
  
  assign lines = lines + 2.
  
  for each cpal no-lock where cpal.xlevc = f-xlevc('cpallet')
  and cpal.ttruc = v-ttruc 
  by cpal.cpaln:
    assign
      nCoils = 0
      vNetWgtPal = 0
      vPalsInTrc = vPalsInTrc + 1
      vGrsWgtTrc = vGrsWgtTrc + cpal.cpalngrossweight.
  
    for each ocoi no-lock where ocoi.xlevc = f-xlevc('ocoil')
    and ocoi.cpaln = cpal.cpaln 
    by ocoi.ocoiawidth by ocoi.ocoic:
      assign lines = lines + 1.
      if lines gt 60 then
      do:
        assign
          lines = 5
          pages = pages + 1.
        page.
        put unformatted skip(2)
          space(5) 'A T T A C H E D   S H E E T'
          space(79 - length('A T T A C H E D   S H E E T') - length('EURO-MIT STAAL B.V.'))
          'EURO-MIT STAAL B.V.' skip
          space(5) today format "99/99/9999" space(79 - length("99/99/9999") - length("page ###")) 'Page ' string(pages) format "x(3)" skip
          space(5) fill('_',79) skip(1).
      end.
      assign
        nCoils = nCoils + 1
        vColsInTrc = vColsInTrc + 1
        vNetWgtPal = vNetWgtPal + ocoi.ocoinweight
        vNetWgtTrc = vNetWgtTrc + ocoi.ocoinweight.
  
      if nCoils gt 1 then put skip space(5)
        space(9) ' '
        ocoi.ocoic format "x(26)"
        ocoi.ocoiawidth format ">>>9.9"
        ocoi.ocoinlength format ">>>>>>9"
        ocoi.ocoinweight format ">>>,>>9".
      else put space(5)
        cpal.cpalm format "x(9)" ' '
        ocoi.ocoic format "x(26)"
        ocoi.ocoiawidth format ">>>9.9"
        ocoi.ocoinlength format ">>>>>>9"
        ocoi.ocoinweight format ">>>,>>9".
    end. /*for-each-coil*/
    assign lines = lines + 1.
    put skip space(5)
      space(50) '------ '
      vNetWgtPal format ">>>,>>9" ' '
      cpal.cpalngrossweight format ">>,>>9" skip.
  end.
  
  put unformatted skip
    space(5) '------- -------------------------- ------- ------ ------ ------- -------' skip
    space(5) vPalsInTrc ' pallets, ' vColsInTrc ' coils.' space(30)
    vNetWgtTrc at 63 format ">>>,>>9"
    vGrsWgtTrc at 71 format ">>>,>>9" skip.
  
  /*** CREATE RECORD INVOICE ***/
  if v-output = "1" then 
  do:
    for first ttru no-lock where ttru.xlevc = f-xlevc('ttruck')
    and ttru.ttruc = v-ttruc ,
    first sord no-lock where sord.xlevc = f-xlevc('sorder')
    and sord.sordn = ttru.sordn ,
    first gcom no-lock where gcom.xlevc = f-xlevc('gcompany')
    and gcom.gcomn = sord.gcomnagent ,
    first bfCln no-lock where bfCln.xlevc = f-xlevc('gcompany')
    and bfCln.gcomn = sord.gcomnclient ,
    first gcur no-lock where gcurrency.xlevc = f-xlevc('gcurrency') 
    and gcurrency.gcurc = sord.gcurc:
  
    create iinv.
    assign
      iinv.gcomnagent     = sord.gcomnagent
      iinv.iinvtdebtor    = gcom.gcomtshortname
      iinv.gcomnclient    = sord.gcomnclient
      iinv.iinvtclient    = bfCln.gcomtshortname
      iinv.gcurc          = sord.gcurc
      iinv.iinvarate      = gcur.gcurarate
      iinv.iinvdduedate   = v-duedate
      iinv.iinvdinvdt     = v-iinvdt
      iinv.iinvn          = v-iinvn
      iinv.iinvainvoiceam = round((vBaseAmt + v-AddCosts + v-ClearCharges),2) * (1 + v-vat / 100)
      iinv.sordn          = ttru.sordn
      iinv.iinvapayextra  = v-AddCosts + v-ClearCharges /* non operating charges */
      iinv.iinvdreceived  = ?
      iinv.iinvtreference = v-ttruc
      iinv.iinvqquantity  = vNettWgt
      iinv.iinvaimpduties = v-impd
      iinv.iinvasalesamt  = vBaseAmt
      iinv.iinvaadjamt    = 0
      iinv.iinvavatamt    = round((vBaseAmt + v-AddCosts + v-ClearCharges),2) * (v-vat / 100)
      iinv.iinvtictcode   = vIctCode
      iinv.gjobc          = sord.gjobc
      iinv.xstac          = '100'
      iinv.iinvtdlvtext   = v-dlvtext
      iinv.iinvtdir       = ''
      .
  
    release iinv.
  
    end.
  end.
  /* else do not assign because of preview */

end. /*transaction*/

END PROCEDURE. /*ipSingle*/








PROCEDURE ipSetIct.
  for each gcou no-lock where gcou.xlevc = f-xlevc('gcountry')
  and gcou.gregc = '15' /*EU*/:
    assign eglist = eglist + minimum(",",eglist) + gcou.gcouc.
  end.
  assign vIctCode = "ICP".
  if lookup(sord.gcouc,eglist) EQ 0 then assign vIctCode = "EXP".
  if round((vBaseAmt + v-AddCosts + v-ClearCharges),2) * (v-vat / 100) GT 0 then assign vIctCode = 'NL '.
END PROCEDURE.


FUNCTION FN_HsCode returns character (input pWid as deci,input pJob as char, input pProduct as char, input pGrade as char):
  /* NOTES: ems uses 8 chars for hs-code, customs wants 22 chars, decided to add zeros after first 8*/
  def var returnvalue as char no-undo.
  
  define variable cbscodes as char no-undo initial "7226110091,7226110011,7225110010,7212101000,7210122000,7210301000,8504901899".
  define variable vCode    as inte no-undo extent 7 initial 0.

  if pProduct = "Laminations" then do:
    vCode[7] = vCode[7] + 1.
  end.
  else do:
    if pJob = "S" then do:
      if pwid LE 500                  then assign vCode[1] = vCode[1] + 1.
      if pwid GT 500 and pwid LT 600 then assign vCode[2] = vCode[2] + 1.
      if pwid GE 600                  then assign vCode[3] = vCode[3] + 1.
    end.            
    
    if pJob = "T" and (pGrade = "TPDR7BA" or pGrade = "TPDR7BA22") then do:
      if pwid LT 600 then assign vCode[4] = vCode[4] + 1.
      if pwid GE 600 then assign vCode[5] = vCode[5] + 1.
    end.
    
    if pJob = "T" and (pGrade = "EGNSC700") then do:
      assign vCode[6] = vCode[6] + 1.
    end.
  end.
  
  if maximum(vCode[1],vCode[2],vCode[3],vCode[4],vCode[5],vCode[6],vCode[7]) = 0 then returnvalue = " ".
  else if vCode[1] = maximum(vCode[1],vCode[2],vCode[3],vCode[4],vCode[5],vCode[6],vCode[7]) then returnvalue = entry(1,cbscodes).
  else if vCode[2] = maximum(vCode[1],vCode[2],vCode[3],vCode[4],vCode[5],vCode[6],vCode[7]) then returnvalue = entry(2,cbscodes).
  else if vCode[3] = maximum(vCode[1],vCode[2],vCode[3],vCode[4],vCode[5],vCode[6],vCode[7]) then returnvalue = entry(3,cbscodes).
  else if vCode[4] = maximum(vCode[1],vCode[2],vCode[3],vCode[4],vCode[5],vCode[6],vCode[7]) then returnvalue = entry(4,cbscodes).
  else if vCode[5] = maximum(vCode[1],vCode[2],vCode[3],vCode[4],vCode[5],vCode[6],vCode[7]) then returnvalue = entry(5,cbscodes).
  else if vCode[6] = maximum(vCode[1],vCode[2],vCode[3],vCode[4],vCode[5],vCode[6],vCode[7]) then returnvalue = entry(6,cbscodes).
  else returnvalue = entry(7,cbscodes).
  
  if returnvalue begins "8" then
  assign returnvalue = returnvalue + /*"00" +*/ "0000" + "00000000".
  else
  assign returnvalue = returnvalue + /*"00" +*/ gProducer + "00000000".

  return returnvalue.
  
END FUNCTION.


procedure ipPrintAS_C1:
  /* Purpose: Attached sheet per truck, onderdeel van PACKINGLIST */

  define variable vTruckWgt     as inte no-undo.
  define variable vLines        as inte no-undo.
  define variable vPages        as inte no-undo.
  define variable vCoils        as inte no-undo.
  define variable vPallets      as inte no-undo.
  define variable vPalletNetWgt as inte no-undo.
  define variable vTotalGross   as inte no-undo.
  define variable vTotalCoils   as inte no-undo.
  define variable vTotalNett    as inte no-undo.
  
  def var vPalNett  as inte no-undo.
  def var vPalGross as inte no-undo.
  def var vTrcNett  as inte no-undo.
  def var vTrcGross as inte no-undo.
  def var nPallets  as inte no-undo.
  def var nCoils    as inte no-undo.

  put unformatted skip(1)
    space(5) 'A T T A C H E D   S H E E T'  space(79 - length('A T T A C H E D   S H E E T') - length('EURO-MIT STAAL B.V.')) 'EURO-MIT STAAL B.V.' skip
    space(5) today format "99/99/9999" space(79 - length("99/99/9999") - length("page 1 ")) 'Page 1' skip
    space(5) fill('_',79) skip(1).
  assign vPages = 1. 
  assign vLines = vLines + 3 + 1.

  for first ttru no-lock where ttru.xlevc = f-xlevc('ttruck')
  and ttru.ttruc = v-ttruc,
  first sord no-lock where sord.xlevc = f-xlevc('sorder')
  and sord.sordn = ttru.sordn,
  first gcom no-lock where gcom.xlevc = f-xlevc('gcompany')
  and gcom.gcomn = sord.gcomnclient:
    put unformatted
      space(5) "Sales Contract no. : EMS-" sord.gjobc + "-" + string(sord.sordn)  skip
      space(5) "Load no.           : " ttru.ttruc /*"  EU"*/ skip
      space(5) "Client             : " gcom.gcomm skip
      space(5) "Grade              : " vCustGrade /*OLD**sord.ggrac*/ skip
      space(5) "Client P/O No.     : " sord.sordtcustordcd if sord.sordtpackref NE '' then "  Project: " + sord.sordtpackref else '' skip
      space(5) fill('_',79) format "x(79)" skip(1).
    assign vLines = vLines + 8.
    /* attempt redo the body which begins with put-statement after end-for-first-truck*/
    assign vLines = vLines + 3.
    for each bPal no-lock where bPal.xlevc = '1'
    and bPal.ttruc = ttru.ttruc,
    each bCol no-lock where bCol.xlevc = '1'
    and bCol.cpaln = bPal.cpaln
    and bCol.eu = true
    break by bPal.cpalm by bCol.ocoiawidth by bCol.ocoic:
      if vLines GT 66 then 
      do:
        put skip.
        page.
        assign
          vLines = 5 + 1
          vPages = vPages + 1.
     
        put unformatted skip(1)
          space(5) 'A T T A C H E D   S H E E T'  space(79 - length('A T T A C H E D   S H E E T') - length('EURO-MIT STAAL B.V.')) 'EURO-MIT STAAL B.V.' skip
          space(5) today format "99/99/9999" space(79 - length("99/99/9999") - length("page ###")) 'Page ' string(vPages) format "x(3)" skip
          space(5) fill('_',79) skip(1). 
      end.
      if first-of(bPal.cpalm) then assign 
        vPalGross = bPal.cpalntarra
        vTrcGross = vTrcGross + bPal.cpalntarra
        nPallets = nPallets + 1.
      assign 
        vPalNett = vPalNett + bCol.ocoinweight
        vPalGross = vPalGross + bCol.ocoinweight.
      assign 
        vTrcNett = vTrcNett + bCol.ocoinweight
        vTrcGross = vTrcGross + bCol.ocoinweight.
      assign nCoils = nCoils + 1.
      assign vLines = vLines + 1.
        
      disp space(5)
        if first-of(bPal.cpalm) then bPal.cpalm else '' column-label "Pallet"
        bCol.ocoic format "x(30)" /*@#$! wrong format, can be solved by applying new numbering system*/
        bCol.ocoiawidth
        bCol.ocoinlength column-label "Length"
        bCol.ocoinweight column-label "Weight"
        ''               column-label "P-Nett" format "x(7)"
        ''               column-label "P-Gross" format "x(7)"
      with stream-io no-box width 148.
      if last-of(bPal.cpalm) then 
      do:
        assign vLines = vLines + 1.
        put
            "------"                   at 63
            vPalNett  format ">>>,>>9" at 69
            vPalGross format ">>>,>>9" at 78
            skip.
        assign vPalNett = 0 vPalGross = 0. /*init*/
      end.
    end.
  end. /*for-first-ttru*/
  put unformatted skip
    space(5) '-------- ------------------------------ --------- ------ ------ ------- -------' skip
    space(5) nPallets ' pallets, ' nCoils ' Coils.' 
    vTrcNett  at 70 format ">>>,>>9"
    vTrcGross at 78 format ">>>,>>9" skip.
  
  /* old method
  put 
    space(5) 'Pallet    EMS-col-nr               Width    Length Weight P-Nett  P-Gross' skip
    space(5) '--------- ------------------------ -------- ------ ------ ------- -------' skip.
  assign vLines = vLines + 2.

  for each ttPal no-lock where ttPal.xlevc = '1'
  and ttPal.ttruc = v-ttruc 
  and can-find(first ttCol where ttCol.cpaln = ttPal.cpaln and ttCol.eu = true)
  break by ttPal.cpaln :
    assign
      vCoils = 0
      vPalletNetWgt = 0
      vPallets = vPallets + 1
      vTotalGross = vTotalGross + ttPal.cpalngrossweight.

    for each ttCol no-lock where ttCol.xlevc = '1'
    and ttCol.cpaln = ttPal.cpaln 
    break by ttCol.ocoiawidth by ttCol.ocoic:
      assign vLines = vLines + 1.
      if vLines GT 66 then 
      do:
        put skip.
        page.
        assign
          vLines = 5 + 1
          vPages = vPages + 1.
     
        put unformatted skip(1)
          space(5) 'A T T A C H E D   S H E E T'  space(79 - length('A T T A C H E D   S H E E T') - length('EURO-MIT STAAL B.V.')) 'EURO-MIT STAAL B.V.' skip
          space(5) today format "99/99/9999" space(79 - length("99/99/9999") - length("page ###")) 'Page ' string(vPages) format "x(3)" skip
          space(5) fill('_',79) skip(1). 
      end.
 
      assign
        vCoils = vCoils + 1
        vTotalCoils = vTotalCoils + 1
        vPalletNetWgt = vPalletNetWgt + ttCol.ocoinweight
        vTotalNett = vTotalNett + ttCol.ocoinweight.

      if vCoils GT 1 then put skip 
        ttCol.ocoic at 16 format "x(26)"
        ttCol.ocoiawidth format ">>>9.9"
        ttCol.ocoinlength format ">>>>>>9"
        ttCol.ocoinweight format ">>>,>>9".
      else put space(5) 
        ttPal.cpalm format "x(9)" ' '
        ttCol.ocoic format "x(26)"
        ttCol.ocoiawidth format ">>>9.9"
        ttCol.ocoinlength format ">>>>>>9"
        ttCol.ocoinweight format ">>>,>>9".
    end. /*for-each-ocoi*/
    assign vLines = vLines + 1.
    put skip 
      '------ ' at 57
      vPalletNetWgt format ">>>,>>9" '  '
      ttPal.cpalngrossweight format ">>,>>9" skip.
  end.  /*for-each-cpal*/

  put unformatted skip
    space(5) '--------- ------------------------ -------- ------ ------ ------- -------' skip
    space(5) vPallets ' pallets, ' vTotalCoils ' Coils.' 
    vTotalNett at 64 format ">>>,>>9"
    vTotalGross at 72 format ">>>,>>9" skip.
  */

END PROCEDURE. /* ipPrintAS_C1 */

procedure ipPrintAS_C2:
  /* Purpose: Attached sheet per truck, onderdeel van PACKINGLIST */

  define variable vTruckWgt     as inte no-undo.
  define variable vLines        as inte no-undo.
  define variable vPages        as inte no-undo.
  define variable vCoils        as inte no-undo.
  define variable vPallets      as inte no-undo.
  define variable vPalletNetWgt as inte no-undo.
  define variable vTotalGross   as inte no-undo.
  define variable vTotalCoils   as inte no-undo.
  define variable vTotalNett    as inte no-undo.
  
  def var vPalNett  as inte no-undo.
  def var vPalGross as inte no-undo.
  def var vTrcNett  as inte no-undo.
  def var vTrcGross as inte no-undo.
  def var nPallets  as inte no-undo.
  def var nCoils    as inte no-undo.

  put unformatted skip(1)
    space(5) 'A T T A C H E D   S H E E T'  space(79 - length('A T T A C H E D   S H E E T') - length('EURO-MIT STAAL B.V.')) 'EURO-MIT STAAL B.V.' skip
    space(5) today format "99/99/9999" space(79 - length("99/99/9999") - length("page 1 ")) 'Page 1' skip
    space(5) fill('_',79) skip(1).
  assign vPages = 1. 
  assign vLines = vLines + 3 + 1.

  for first ttru no-lock where ttru.xlevc = f-xlevc('ttruck')
  and ttru.ttruc = v-ttruc,
  first sord no-lock where sord.xlevc = f-xlevc('sorder')
  and sord.sordn = ttru.sordn,
  first gcom no-lock where gcom.xlevc = f-xlevc('gcompany')
  and gcom.gcomn = sord.gcomnclient:
    put unformatted
      space(5) "Sales Contract no. : EMS-" sord.gjobc + "-" + string(sord.sordn)  skip
      space(5) "Load no.           : " ttru.ttruc /*"  NEU"*/ skip
      space(5) "Client             : " gcom.gcomm skip
      space(5) "Grade              : " vCustGrade /*OLD**sord.ggrac*/ skip
      space(5) "Client P/O No.     : " sord.sordtcustordcd if sord.sordtpackref NE '' then "  Project: " + sord.sordtpackref else '' skip
      space(5) fill('_',79) format "x(79)" skip(1).
    assign vLines = vLines + 8.
    /* attempt redo the body which begins with put-statement after end-for-first-truck*/
    assign vLines = vLines + 3.
    for each bPal no-lock where bPal.xlevc = '1'
    and bPal.ttruc = ttru.ttruc,
    each bCol no-lock where bCol.xlevc = '1'
    and bCol.cpaln = bPal.cpaln
    and bCol.eu = false
    break by bPal.cpalm by bCol.ocoiawidth by bCol.ocoic:
      if vLines GT 66 then 
      do:
        put skip.
        page.
        assign
          vLines = 5 + 1
          vPages = vPages + 1.
     
        put unformatted skip(1)
          space(5) 'A T T A C H E D   S H E E T'  space(79 - length('A T T A C H E D   S H E E T') - length('EURO-MIT STAAL B.V.')) 'EURO-MIT STAAL B.V.' skip
          space(5) today format "99/99/9999" space(79 - length("99/99/9999") - length("page ###")) 'Page ' string(vPages) format "x(3)" skip
          space(5) fill('_',79) skip(1). 
      end.
      if first-of(bPal.cpalm) then assign 
        vPalGross = bPal.cpalntarra
        vTrcGross = vTrcGross + bPal.cpalntarra
        nPallets = nPallets + 1.
      assign 
        vPalNett = vPalNett + bCol.ocoinweight
        vPalGross = vPalGross + bCol.ocoinweight.
      assign 
        vTrcNett = vTrcNett + bCol.ocoinweight
        vTrcGross = vTrcGross + bCol.ocoinweight.
      assign nCoils = nCoils + 1.
      assign vLines = vLines + 1.
        
      disp space(5)
        if first-of(bPal.cpalm) then bPal.cpalm else '' column-label "Pallet"
        bCol.ocoic format "x(30)" /*@#$! wrong format, can be solved by applying new numbering system*/
        bCol.ocoiawidth
        bCol.ocoinlength column-label "Length"
        bCol.ocoinweight column-label "Weight"
        ''               column-label "P-Nett" format "x(7)"
        ''               column-label "P-Gross" format "x(7)"
      with stream-io no-box width 148.
      if last-of(bPal.cpalm) then 
      do:
        assign vLines = vLines + 1.
        put
            "------"                   at 63
            vPalNett  format ">>>,>>9" at 69
            vPalGross format ">>>,>>9" at 78
            skip.
        assign vPalNett = 0 vPalGross = 0. /*init*/
      end.
    end.
  end. /*for-first-ttru*/
  put unformatted skip
    space(5) '-------- ------------------------------ --------- ------ ------ ------- -------' skip
    space(5) nPallets ' pallets, ' nCoils ' Coils.' 
    vTrcNett  at 70 format ">>>,>>9"
    vTrcGross at 78 format ">>>,>>9" skip.
  
  /* old method
  put 
    space(5) 'Pallet    EMS-col-nr               Width    Length Weight P-Nett  P-Gross' skip
    space(5) '--------- ------------------------ -------- ------ ------ ------- -------' skip.
  assign vLines = vLines + 2.

  for each ttPal no-lock where ttPal.xlevc = '1'
  and ttPal.ttruc = v-ttruc 
  and can-find(first ttCol where ttCol.cpaln = ttPal.cpaln and ttCol.eu = false)
  break by ttPal.cpaln :
    assign
      vCoils = 0
      vPalletNetWgt = 0
      vPallets = vPallets + 1
      vTotalGross = vTotalGross + ttPal.cpalngrossweight.

    for each ttCol no-lock where ttCol.xlevc = '1'
    and ttCol.cpaln = ttPal.cpaln 
    break by ttCol.ocoiawidth by ttCol.ocoic:
      assign vLines = vLines + 1.
      if vLines GT 66 then 
      do:
        put skip.
        page.
        assign
          vLines = 5 + 1
          vPages = vPages + 1.
     
        put unformatted skip(1)
          space(5) 'A T T A C H E D   S H E E T'  space(79 - length('A T T A C H E D   S H E E T') - length('EURO-MIT STAAL B.V.')) 'EURO-MIT STAAL B.V.' skip
          space(5) today format "99/99/9999" space(79 - length("99/99/9999") - length("page ###")) 'Page ' string(vPages) format "x(3)" skip
          space(5) fill('_',79) skip(1). 
      end.
 
      assign
        vCoils = vCoils + 1
        vTotalCoils = vTotalCoils + 1
        vPalletNetWgt = vPalletNetWgt + ttCol.ocoinweight
        vTotalNett = vTotalNett + ttCol.ocoinweight.

      if vCoils GT 1 then put skip 
        ttCol.ocoic at 16 format "x(26)"
        ttCol.ocoiawidth format ">>>9.9"
        ttCol.ocoinlength format ">>>>>>9"
        ttCol.ocoinweight format ">>>,>>9".
      else put space(5) 
        ttPal.cpalm format "x(9)" ' '
        ttCol.ocoic format "x(26)"
        ttCol.ocoiawidth format ">>>9.9"
        ttCol.ocoinlength format ">>>>>>9"
        ttCol.ocoinweight format ">>>,>>9".
    end. /*for-each-ocoi*/
    assign vLines = vLines + 1.
    put skip 
      '------ ' at 57
      vPalletNetWgt format ">>>,>>9" '  '
      ttPal.cpalngrossweight format ">>,>>9" skip.
  end.  /*for-each-cpal*/

  put unformatted skip
    space(5) '--------- ------------------------ -------- ------ ------ ------- -------' skip
    space(5) vPallets ' pallets, ' vTotalCoils ' Coils.' 
    vTotalNett at 64 format ">>>,>>9"
    vTotalGross at 72 format ">>>,>>9" skip.
  */

END PROCEDURE. /* ipPrintAS_C2 */
