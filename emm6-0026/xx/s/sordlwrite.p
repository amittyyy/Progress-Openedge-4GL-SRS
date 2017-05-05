/* ---------------------- Euro-Mit Staal bv Vlissingen -------------------------

  File        : s/sordlwrite.p
  Description :
  Created     : 04/10/06 Alex Leenstra

Date     Author Version Description
-------- ------ ------- ----------------------------------------------------------------------------------------------------------------
04/10/06 AlexL  1.00       Created
29/09/08 AlexL  1.01       When created the value from gcomnforwarder is not copied
                                                from scdm (Default client-demands)
22/06/10 pb     1.02    [EMM5-0802]     locking problems in various sources
07/07/10 pb     1.03    [EMM5-0827]     check the logic that uses "disable trigger"
09/07/15 ku     1.04    [EMM6-I-0008]   to remove extra module Order Mgmt, logic added to 
                                        create cut/slit orders from independent programs.
24/08/15 amity  1.05    [EMM6-0026]     When box duty paid and box NEU are checked then in 100% of the cases the IMA box in tab "Trucks" should
                                        be checked and case when box duty paid is unchecked and NEU are checked then  the t1 box shuld checked.                                                                                 
----------------------------------------------------------------------------------------------------------------------------------------------*/

define input parameter p-bufferhdl as handle no-undo.    /* handle of the trigger buffer */
define input parameter p-oldbuffer as handle no-undo.    /* handle of the old buffer       -   v2.21  */
define input parameter p-xproc     as handle no-undo.    /* handle of the program with the transaction */

define variable p-mode         as char    no-undo.
define variable p-free-input   as char    no-undo.
define variable v-from-x-files as logi    no-undo.
define variable v-cutorder     as integer no-undo.
define buffer b-sordd for sord.


/* check if this trigger is started from the X-files or from a manual program */

if lookup("p-givevalue",p-xproc:internal-entries) GT 0 then
do:
  run p-givevalue in p-xproc ("p-free-input", output p-free-input).
  if p-xproc:private-data = "x-files" then
  do:
    assign 
      v-from-x-files = true.
    run p-givevalue in p-xproc ("p-mode", output p-mode).  /* check n/c/u/ msode */
  end.
end.

/* ku v1.04 : check if the new order number to add to sord table is already in the table*/
/* also check for the c/u/d operations involved for table sorder */
if p-mode ne "3" and p-mode ne "" then
do:
  find first sord exclusive-lock where rowid(sorder) = p-bufferhdl:rowid no-error no-wait.
  assign 
    v-cutorder = sord.sordn.

  find first sord where sord.sordn = v-cutorder exclusive-lock no-error.
  if avail sord then
  do:
    find last b-sordd no-lock no-error.
    assign 
      sord.sordn = b-sordd.sordn + 1.
  end.
end.



/*{x/xxxxlwrite.i} */
{x/xxxxpvar.i}   /*- default variables -*/


PROCEDURE p-gshic:
  /*------------------------------------------------------------------------------
    Purpose: what is this proc doing ???
      Notes: - this is fired when committing an order and the value for shipmode was changed !
             - the condition 20 is about promoting forecast to actual order, this is not active, hence this block of code currently is nonsense !
  ------------------------------------------------------------------------------*/
  define input  parameter v-rowid    as rowid no-undo.
  define input  parameter v-newvalue like sord.gshic no-undo.
  define input  parameter v-oldvalue like sord.gshic no-undo.
  define output parameter v-xerrc    like xerr.xerrc no-undo.

/* COMMENTED AS A TEST dd 25.6.2012*
message 'hello from p-gshic in sordlwrite.p' view-as alert-box.

define variable v-xstac as char no-undo.

find first sord exclusive-lock where rowid(sorder) = v-rowid no-error.
assign v-xstac = f-xstanext("sorder",sord.xstac,20,true,rowid(sorder)).
assign sord.xstac = v-xstac.

release sord.
*END COMMENTED*/

END PROCEDURE. /* p-gshic */


PROCEDURE p-commit :
  /*------------------------------------------------------------------------------
    Purpose:
      Notes:
     update: - amity: [emm6-0026] Force system to check IMA box in “trucks”.
  ------------------------------------------------------------------------------*/
  /*message 'hello from p-commit in sordlwrite.p' view-as alert-box information.*/
  
  define variable v-sordn       as inte   no-undo.
  define variable h-sord-buffer as handle no-undo.
  define variable h-scdm-buffer as handle no-undo.
  define variable h-field1      as handle no-undo.
  define variable h-field2      as handle no-undo.
  define variable v-newfield    as char   no-undo.
  define variable v-xstac       as char   no-undo.
  define variable vCurOrdn      as inte   no-undo.

  define buffer b-sord   for sord.
  define buffer b-sorder for sord.
  define buffer b-ssize  for ssiz.
  define buffer b-srec   for srec.

  find first sord exclusive-lock where rowid(sorder) = p-bufferhdl:rowid no-error no-wait.

  if p-mode = '1' or p-mode = '2' then assign sord.sorddorddt = today no-error.

  create buffer h-sord-buffer for table 'sorder'.
  create buffer h-scdm-buffer for table 'scdm'.

  if f-getoutput('xstac',p-free-input) GT '' then assign sord.xstac = f-getoutput('xstac',p-free-input).

  h-scdm-buffer:find-unique('where scdm.xlevc = "' + f-xlevc('scdm') + '" and scdm.gcomnclient = ' + string(sord.gcomnclient) ,no-lock).
   
  for each ttruck exclusive-lock where ttru.xlevc = f-xlevc('ttruck') and ttruck.sordn = sord.sordn and ttruck.xstac = "100" : /*amity SR [emm6-0026]*/
    if sord.sordlentrepot = yes then 
    do:     
      if sord.sordldutypaid = no then 
        assign 
          ttruck.ttrult1     = yes
          ttruck.ttruldocima = no.
      else 
        assign
          ttruc.ttruldocima = yes
          ttruck.ttrult1    = no.   
    end.
    
    if sorder.sordleu = yes then 
    do:
      assign
        ttruck.ttrult1     = no
        ttruck.ttruldocima = no.     
    end.
  end. /*amity: for each ttruck [emm6-0026] for each ttruck*/
  
  release sord.
  
  if p-mode GT '0' and p-mode LT '3'  then
  do:
    h-sord-buffer:find-by-rowid(p-bufferhdl:rowid ,exclusive).
    repeat v-cnt = 1 to h-scdm-buffer:num-fields:
      assign
        h-field1   = h-scdm-buffer:buffer-field(v-cnt)
        v-newfield = substring(h-sord-buffer:table,1,4) + substring(h-field1:name,5).
      h-field2 = h-sord-buffer:buffer-field(v-newfield) no-error.
      if not valid-handle(h-field2) then
        h-field2 = h-sord-buffer:buffer-field(h-field1:name) no-error.
      if valid-handle(h-field2) and lookup(substring(h-field2:name,5),'tsendtodb,tsendtime,tsendxusec,dsend') = 0 
        and lookup(h-field2:name,'xstac,gcomnforwarder') = 0 then
        assign h-field2:buffer-value = h-field1:buffer-value.
    end. /*repeat*/
    h-sord-buffer:buffer-release.
  end. /*endif p-mode gt 0 and p-mode lt 3*/

  define variable h-buffer as handle no-undo.
  define variable h-field  as handle no-undo.

  define variable v-cnt    as inte   no-undo.

  create buffer h-buffer for table 'sorder'.

  h-buffer:find-by-rowid(p-bufferhdl:rowid,exclusive).

  repeat v-cnt = 1 to h-buffer:num-fields:
    h-field = h-buffer:buffer-field(v-cnt).
    if valid-handle(h-field) and f-getoutput(h-field:name,p-free-input) = '?' then
      assign h-field:buffer-value = f-getoutput(h-field:name,p-free-input).
    if valid-handle(h-field) and h-field:name = 'gmllc' and h-field:buffer-value = ? then assign h-field:buffer-value = ''.
  end.

  h-buffer:buffer-release().
  if p-mode = '2' /*COPY*/ then
  do:
    find last sord where sord.xlevc = f-xlevc('sorder') and sord.gcomnclient = p-bufferhdl:buffer-field("gcomnclient"):buffer-value no-lock use-index sordn.
    assign 
      v-sordn = sord.sordn.
    find first b-sorder no-lock where rowid(b-sorder) = to-rowid(f-getoutput('copy',p-free-input)) no-error.
    find first sord no-lock where rowid(sorder) = p-bufferhdl:rowid no-error no-wait.
    for each ssiz no-lock where ssiz.xlevc = f-xlevc('ssizes')
      and ssize.sordn = b-sorder.sordn:
      create b-ssize.
      buffer-copy ssize to b-ssize
        assign
        b-ssize.sordn = sord.sordn.
      release b-ssize.
    end.
    for each srec no-lock where srec.xlevc = f-xlevc('srecipient')
      and srec.sordn = v-sordn:
      create b-srec.
      buffer-copy srec to b-srec
        assign
        b-srec.sordn = sord.sordn.
      release b-srec.
    end.
  end.

  if p-mode = '1' /*ADD*/ or p-mode = '2' /*COPY*/ then 
  do:
    find first sord no-lock where rowid(sorder) = p-bufferhdl:rowid no-error.
    assign 
      vCurOrdn = sord.sordn.
    run proc\sys429-p.p(input vCurOrdn). /*add records shape incase laminations*/

    /* Add record recipient (if customer has previous salesorder, take from this salesorder otherwise set blank) */
    find first sord no-lock where rowid(sorder) = p-bufferhdl:rowid no-error.
    assign 
      vCurOrdn = sord.sordn.
  
    if not can-find(first srec no-lock where srec.xlevc = f-xlevc('srecipient') and srec.sordn = vCurOrdn) then
    do:
      /*CREATE RECORD AND FILL WITH DEFAULT VALUES*/
      define buffer bfrecipient for srecipient.
      define variable vClient as inte no-undo.
  
      find first sord no-lock where sord.xlevc = f-xlevc('sorder') and sord.sordn = vCurOrdn no-error.
  
      if available sord then assign vClient = sord.gcomnclient.
      if vClient NE 0 then
      do:
        for each sord no-lock where sord.xlevc = f-xlevc('sorder')
          and sord.sordn NE vCurOrdn
          and sord.gcomnclient = vClient,
          first bfrecipient no-lock where bfrecipient.xlevc = f-xlevc('srecipient') 
          and bfrecipient.sordn = sord.sordn 
          break by sord.sordn descending:
          create srec.
          assign
            srec.sordn          = vCurOrdn
            srec.srectdoc1      = bfrecipient.srectdoc1
            srec.srectdoc2      = bfrecipient.srectdoc2
            srec.srectdoc3      = bfrecipient.srectdoc3
            srec.srectdoc4      = bfrecipient.srectdoc4
            srec.srectdoc5      = bfrecipient.srectdoc5
            srec.srectdoc6      = bfrecipient.srectdoc6
            srec.srectdoc7      = bfrecipient.srectdoc7
            srec.srectdoc8      = bfrecipient.srectdoc8
            srec.sreclhardcopy1 = bfrecipient.sreclhardcopy1
            srec.sreclhardcopy2 = bfrecipient.sreclhardcopy2
            srec.sreclhardcopy3 = bfrecipient.sreclhardcopy3
            srec.sreclhardcopy4 = bfrecipient.sreclhardcopy4
            srec.sreclhardcopy5 = bfrecipient.sreclhardcopy5
            srec.sreclhardcopy6 = bfrecipient.sreclhardcopy6
            srec.sreclhardcopy7 = bfrecipient.sreclhardcopy7
            srec.sreclhardcopy8 = bfrecipient.sreclhardcopy8
            srec.sreclemail1    = bfrecipient.sreclemail1
            srec.sreclemail2    = bfrecipient.sreclemail2
            srec.sreclemail3    = bfrecipient.sreclemail3
            srec.sreclemail4    = bfrecipient.sreclemail4
            srec.sreclemail5    = bfrecipient.sreclemail5
            srec.sreclemail6    = bfrecipient.sreclemail6
            srec.sreclemail7    = bfrecipient.sreclemail7
            srec.sreclemail8    = bfrecipient.sreclemail8
            .
          release srec.
          leave.
        end. /*for-each*/
      end. /*endif*/
    end. /*endif not canfind*/
  
    if not can-find(first srec no-lock where srec.xlevc = f-xlevc('srecipient') and srec.sordn = vCurOrdn) then
    do:
      /*CREATE EMPTY*/
      create srec.
      assign
        srec.sordn          = vCurOrdn
        srec.srectdoc1      = ""
        srec.srectdoc2      = ""
        srec.srectdoc3      = ""
        srec.srectdoc4      = ""
        srec.srectdoc5      = ""
        srec.srectdoc6      = ""
        srec.srectdoc7      = ""
        srec.srectdoc8      = ""
        srec.sreclhardcopy1 = false
        srec.sreclhardcopy2 = false
        srec.sreclhardcopy3 = false
        srec.sreclhardcopy4 = false
        srec.sreclhardcopy5 = false
        srec.sreclhardcopy6 = false
        srec.sreclhardcopy7 = false
        srec.sreclhardcopy8 = false
        srec.sreclemail1    = false
        srec.sreclemail2    = false
        srec.sreclemail3    = false
        srec.sreclemail4    = false
        srec.sreclemail5    = false
        srec.sreclemail6    = false
        srec.sreclemail7    = false
        srec.sreclemail8    = false
        .
      release srec.
    end. /*endif not canfind*/
  end. /*endif p-mode = add or copy*/

END PROCEDURE. /* p-commit*/


PROCEDURE p-xstac:
  /*------------------------------------------------------------------------------
    Purpose:
      Notes:
  ------------------------------------------------------------------------------*/
  define input  parameter v-rowid    as rowid no-undo.
  define input  parameter v-newvalue like sord.xstac no-undo.
  define input  parameter v-oldvalue like sord.xstac no-undo.
  define output parameter v-xerrc    like xerr.xerrc no-undo.
  
  find first sord no-lock where rowid(sorder) = v-rowid no-error.

  case true:
    when v-newvalue = '400' and v-oldvalue = '200' then 
      do:
        message 'stub for send SALESRECORD NEW' skip sord.sordn view-as alert-box. /*EJINOTE: do note, this msg will only appear in appsrvlog !*/
        run ipSendSrNew.
      end.
    /* COMMENTED AS TEST REMOVING xstac 850
    when v-newvalue = '900' and v-oldvalue = '200' then assign v-sordlagreepm = false. /* EJINOTE: this is an illegal route! thus obsolete!? */
    when v-newvalue = '800' and v-oldvalue = '850' then assign v-sordlagreepm = false.
    when v-newvalue = '850' and v-oldvalue = '800' then assign v-sordlagreepm = true.
    */
    when v-oldvalue = '100' then
      do:
      /* THIS BLOCK IS NO LONGER REQUIRED !!
      find first sfra exclusive-lock where sfra.xlevc = f-xlevc('sframecont') and sfra.sfran = sord.sfran no-error.
      /*assign sfra.sfranforecast = sfra.sfranforecast - sord.sordnorderedweight
             sfra.sfranorder    = sfra.sfranorder    + sord.sordnorderedweight
             .
      eji:fields in FRM are obsolete !! cleanup !*/
      release sfra.
      */
      end.
  end case.

/* EJINOTE: the following if-then-do-end seems obsolete, the logic was replaced by xstac !?*
if sord.sordlagreepm NE v-sordlagreepm then
do:
  find current sord exclusive.
  assign sord.sordlagreepm = v-sordlagreepm.
  release sord.
end.
*END EJINOTE*/

END PROCEDURE. /* p-xstac */


PROCEDURE p-gcurc:
  /*------------------------------------------------------------------------------
    Purpose:
      Notes:
  ------------------------------------------------------------------------------*/

  define input  parameter v-rowid    as rowid no-undo.
  define input  parameter v-newvalue like sord.gcurc no-undo.
  define input  parameter v-oldvalue like sord.gcurc no-undo.
  define output parameter v-xerrc    like xerr.xerrc no-undo.

  find first gcur no-lock where gcur.xlevc = f-xlevc('gcurrency') and gcur.gcurc = v-newvalue no-error.
  if available gcur then
  do:
    find first sord exclusive-lock where rowid(sorder) = v-rowid no-error.
    assign 
      sord.sordarate = gcur.gcurarate.
    release sord.
  end.

END PROCEDURE. /* p-gcurc */


PROCEDURE p-gcomnclient:
  /*------------------------------------------------------------------------------
    Purpose:
      Notes:
  ------------------------------------------------------------------------------*/

  define input  parameter v-rowid    as   rowid no-undo.
  define input  parameter v-newvalue like sord.gcomnclient no-undo.
  define input  parameter v-oldvalue like sord.gcomnclient no-undo.
  define output parameter v-xerrc    like xerr.xerrc no-undo.
  
  define variable v-count as inte no-undo.

  find first sord exclusive-lock where rowid(sorder) = v-rowid no-error.
  find first gcom no-lock where gcom.xlevc = f-xlevc('gcompany') and gcom.gcomn = sord.gcomnclient no-error.
  if available gcom then assign sord.sordtfullname = gcom.gcomtshortname.
  
  for each ttru exclusive-lock where ttru.xlevc = f-xlevc('ttruck')
    and ttru.sordn = sord.sordn:
    assign 
      ttru.gcomnclient = sord.gcomnclient.
  end. /* for each ttru */
  
  release sord.

END PROCEDURE. /* p-gcomnclient */


PROCEDURE p-sordtdummy:
  /*------------------------------------------------------------------------------
    Purpose:
      Notes:
  ------------------------------------------------------------------------------*/

  def input  parameter v-rowid    as rowid no-undo.
  def input  parameter v-newvalue like sord.sordtdummy no-undo.
  def input  parameter v-oldvalue like sord.sordtdummy no-undo.
  def output parameter v-xerrc    like xerr.xerrc no-undo.

  find first sord exclusive-lock where rowid(sorder) = v-rowid no-error.
  assign 
    sord.sordtdummy = ''.
  release sord.

END PROCEDURE. /* p-sordtdummy */


PROCEDURE p-gcomnforwarder.

  def input  parameter v-rowid    as rowid no-undo.
  def input  parameter v-newvalue like sord.gcomnforwarder no-undo.
  def input  parameter v-oldvalue like sord.gcomnforwarder no-undo.
  def output parameter v-xerrc    like xerr.xerrc no-undo.

 
  find first sord exclusive-lock where rowid(sorder) = v-rowid no-error.
  assign 
    sord.gcomnforwarder = v-newvalue.
  release sord.

END PROCEDURE.


PROCEDURE ipSendSrNew:
  /*purpose: send mail to some persons to alert there is a new salesorders */
  
  define variable s          as char no-undo init " ".
  define variable vSender    as char no-undo init "emm@euro-mit-staal.com".
  define variable vRecipient as char no-undo init "e.clarisse@euro-mit-staal.com".
  define variable vFileAtt   as char no-undo init "".
  define variable vBodyText  as char no-undo init "c:\temp\bodyalert.txt".
  define variable vSubject   as char no-undo init "NEWORD".
  define variable vTruck     as char no-undo.
  define variable lFile      as char no-undo init "".

  assign 
    lFile = SESSION:TEMP-DIRECTORY + 'error.log'.
  assign 
    vSubject = vSubject + "-" + upper(f-xusec()).

  /*find xuser no-lock where xuser.xusec = f-xusec() no-error.
  if available xuser and ( xuser.xusetmail NE ? or xuser.xusetmail NE '' ) then assign vRecipient = xuser.xusetmail.*/
  /*assign vRecipients = "m.lerke@euro-mit-staal.com,a.da.cruz@euro-mit-staal.com,j.hitijahubessy@euro-mit-staal.com".*/

  output to value(vBodyText).
  put unformatted 
    "this is an automated message from EMM," skip
    "someone has accepted a salesorder," skip
    "please familiarize yourselves with this new salesorder." skip(2).
  put unformatted
    "this is to be replaced with result from r650!" skip.
  output close.
  
  run proc\rep650-p.p(vBodyText,sord.sordn,"NEW",""). 

  output to c:\temp\executealert.bat.
  put unformatted 
    't:\xx\blat.exe' + s  
    + vBodyText + s
    + "-to" + s + vRecipient + s
    + "-bcc" + s + "ecl@euro-mit-staal.com,c.seitte@euro-mit-staal.com" + s
    + "-f" + s + vSender + s
    + "-subject" + s + vSubject + s
    + vFileAtt + s
    + "-log" + s + lFile
    skip.
  output close.
  /*message 'check exe!' view-as alert-box.*/
  os-command silent value("c:\temp\executealert.bat").

END PROCEDURE.

