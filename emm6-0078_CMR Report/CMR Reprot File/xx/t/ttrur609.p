/* ---------------------- Euro-Mit Staal bv Vlissingen -------------------------
File : t/ttrur609.p
Description : CMR document
Parameters-in-emm4: 
Parameters-in-emm5: 
Tables used : ttru,sord,cpal

Version    Author       SR              Description
---------- ------      ---------------  ----------------------------------------------
22.02.2007 kalash                       created
04.09.2009 Mohan      EMM5-0380         Changed the program according to new emm4. 
04.01.2010 Mohan      EMM5-0587         Removed the preview-only frame and that will be worked now on click of print button.
21.01-2010 Nandeshwar EMM5-I-0087       Add db changes according to emm4 when report is printed.
22.01-2010 Mohan                        Optimized the code for faster execution.
12/02/2016 Amity,Neha     EMM6-0078     PLaced the report program inside the CRM report format.
------------------------------------------------------------------------------*/

define variable v-parentprog as handle no-undo.
assign v-parentprog = widget-handle(entry(2,active-window:private-data,chr(1))) no-error.  /* this must be the parent prog */

{t/ttrur609.s}
{x/xxxxrhedel.i &mode = E &nohead = true &noparam = true}
/*{x/xxxxrhdrems.i &vRepTitle = "CMR document" &vLineLen  = "75"}*/

if v-output = "1" then 
  find first ttru exclusive-lock where ttru.xlevc = f-xlevc('ttruck') and ttru.ttruc = v-ttruc.
  if available ttru then
  do:
    if ttru.ttruttrailerlicno NE v-vak18b then assign ttru.ttruttrailerlicno = v-vak18b.
    if ttru.ttruttrucklicno NE v-vak18 then assign ttru.ttruttrucklicno = v-vak18.
    if ttru.ttrutsealno NE v-vak18c then assign ttru.ttrutsealno = v-vak18c.
    if ttru.xstac = '700' then ttru.ttrulcmrprinted = yes.    
  end.
  release ttru.
/* end */


define variable vPalletList as char no-undo.
define variable vPallets as inte no-undo.
define variable vGoodsDescription as char no-undo format 'X(15)'.
define variable vGrossWgt as inte no-undo.
define variable vT1 as logi no-undo.

define variable vVak01a as char no-undo initial 'EURO-MIT STAAL b.v.'.
define variable vVak01b as char no-undo initial 'P.O.BOX 535'.
define variable vVak01c as char no-undo initial '4380 AM Vlissingen '.

def var vVak13a as char no-undo format "x(40)".
def var vVak13b as char no-undo format "x(40)".
def var vVak13c as char no-undo format "x(40)".

define frame print with width 120.
define frame print1 with width 120.
define frame print2 with width 120.


for first ttru where ttru.xlevc = f-xlevc('ttruck') 
and ttru.ttruc = v-ttruc exclusive-lock,
first sord where sord.xlevc = f-xlevc('sorder') 
and sord.sordn = ttru.sordn no-lock,
each cpal where cpal.xlevc = f-xlevc('cpallet') 
and cpal.ttruc = ttru.ttruc no-lock
break by ttru.ttruc by cpal.cpaln:
  assign 
    vVak01a = v-vak01
    vVak01b = v-vak01b
    vVak01c = v-vak01c + " " + v-vak01d.
  assign
    vGrossWgt = vGrossWgt + (cpal.cpalngrossweight)
    vPalletList = vPalletList + STRING(cpal.cpaln) + ' '
    vPallets = vPallets + 1
    vT1 = sord.sordldutypaid.
  if LAST-OF(ttru.ttruc) then
  do:
    assign vGoodsDescription = (if sord.gjobc = "S" then 'ELEC. STEEL' else 'TOLLSLIT ').
    
    display skip (4) 
     if vVak01a = "" then "" else vVak01a format 'X(35)':U colon 9 skip
     if vVak01b = "" then "" else vVak01b format 'X(35)':U colon 9 skip
     if vVak01c = "" then "" else vVak01c format 'X(35)':U colon 9 SKIP(1)
      SKIP(5) /*2*/
      if v-vak02  = "" then "" else v-vak02  format 'X(30)':U colon 9           if v-vak16  = "" then "" else v-vak16  format 'X(30)':U colon 64 skip
      if v-vak02b = "" then "" else v-vak02b format 'X(30)':U colon 9           if v-vak16b = "" then "" else v-vak16b format 'X(30)':U colon 64 skip
      if v-vak02c = "" then "" else v-vak02c format 'X(30)':U colon 9           if v-vak16c = "" then "" else v-vak16c format 'X(30)':U colon 64 skip
      if v-vak02d = "" then "" else v-vak02d format 'x(30)':U colon 9           if v-vak16d = "" then "" else v-vak16d format 'X(30)':U colon 64 SKIP(1)
      SKIP(4)  /*3*/
      if v-vak03 = "" then "" else v-vak03 format 'X(40)':U colon 9 SKIP(1)
      SKIP(4) /*4*/
      if v-vak04  = "" then "" else v-vak04  format 'X(63)':U colon 9
      if v-vak04b = "" then "" else v-vak04b format 'X(30)':U colon 9          'KENTEKEN TRUCK       :' + if v-vak18  = "" then "" else v-vak18  format 'X(35)':U colon 64 skip
                                                                               'TRAILER-/CONTAINER NO:' + if v-vak18b = "" then "" else v-vak18b format 'X(35)':U colon 64 skip
                                                                               'SEAL NO.             :' + if v-vak18c = "" then "" else v-vak18c format 'X(35)':U colon 64 skip
      SKIP(2)  /*4*/
      if v-vak05 = "" then "" else v-vak05 format 'X(30)':U colon 9 SKIP(5)
      'Order' colon 9
      TRIM(ttru.ttruc) colon 15 /*15*/
      TRIM(STRING(vPallets)) colon 26 /*  space(1)  ns check*/
       'PALLETS' colon 34
      vGoodsDescription colon 41
      TRIM(STRING(vGrossWgt)) colon 90 SKIP(1)  /*pervious 59*/
      skip(2)
      'PALLETNUMBER:' colon 9 skip(1)
      with frame print2 no-label stream-io.

    display
      vPalletList view-as editor size 90 by 1  /* ns 60 by  8 */ colon 9 skip
      with frame print1 no-label.

    put unformatted skip(1)
    space (9) if v-vak06 = "" then "" else v-vak06 format 'X(80)'.

    /*
    if vT1 = false then 
    do:
      display
        SKIP(1)
        'DEDOUANER - ' + "?" + "/" + "?" format 'X(40)':U colon 4 skip
        'T1:______________________' colon 4 skip
        with frame print no-label.
    end.
    else display skip(5) with frame print no-label.
    */
    vVak13a = "! " + entry(1,v-vak13,chr(15)).
    vVak13b = "! " + entry(2,v-vak13,chr(15)) no-error.
    vVak13c = "! " + entry(3,v-vak13,chr(15)) no-error.
    if vVak13a = ? or vVak13a = '! ' then vVak13a = ''.
    if vVak13b = ? or vVak13b = '! ' then vVak13b = ''.
    if vVak13c = ? or vVak13c = '! ' then vVak13c = ''.
    display
/*      "" skip /*unexpected*/*/
      "" skip(1)
      "" vVak13a colon 9 skip
      "" vVak13b colon 9 skip
      "" vVak13c colon 9 skip
      /*      "" skip*/
      /* ns "" skip */
       /*  ns    "" skip*/
      with frame print no-label no-error.

    display
      SKIP(26)
      (if v-vak14 = true then '[X]':U else '[ ]':U) colon 9
      (if v-vak14 = false then '[X]':U else '[ ]':U) colon 9
      SKIP(2)
      'VLISSINGEN,' colon 9 (if ttru.xstac = '900' then string(ttru.ttrudexems,"99-99-9999") else '') format "x(12)" SKIP(2)
     
      "on behalf of" COLON 9 SKIP
      vVak01a  FORMAT 'X(25)':U COLON 9 SKIP
      vVak01b  FORMAT 'X(25)':U COLON 9 SKIP
      v-vak01c + " " + v-vak01d FORMAT 'X(25)':U COLON 9      
      WITH FRAME print NO-LABEL.

    assign 
      vGrossWgt = 0 
      vPallets = 0 
      vPalletList = ''.
  end.
end.

output close.

assign v-newfilename = v-filename.

/*  Quick fix to redirect error from s-finished to some other temporary file    */
if v-output = "1" then
do:
  output close.
  output to C:\temp\temp.tmp.
  publish "s-finished" from v-parentprog.
end.
