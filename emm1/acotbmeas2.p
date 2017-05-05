/* ---------------------- Euro-Mit Staal bv Vlissingen -------------------------

  File        : a/acotbmeas2.p
  Description :
  Created     : 07/12/06 Alex Leenstra

Date      Author    Version Description
--------  ------    ------- --------------------------------------------------------
07/12/06  AlexL     1.00    Created
8/1/2008  kamals    1.01    Added bizlogic for checking whiteline and maxwelds
9/24/2008 kamals    1.02    Deleted display and checks for the field 'Shift'
22/09/09  Sudhir    1.03    If event of a/acotbmeas2-leader.p, then acut row is
                         obtained from value in x/xxxxpcustom.p
23/09/09 Sudhir     1.04    Obtain coil and order no. from temp-table and store in
                         x/xxxxpcustom.p for use by function programs.
23/09/09  AlexL     2.00 added PROCEDURE p-restore and changed
14/12/09  Mohan     2.01    EMM5-0573,Mohan: Store the slit number for remarks tab.
21/01/10 Nandeshwar 1.03    EMM5-0625:Fixed the problem of displaying wrong slit number in the error messages.   
10/06/15 AlexL      2.02    Locking problem with acot 
10/06/15 AlexL      2.03    Only copy the measurement fields in acot
10/06/15 AlexL      2.04    Releasing locked records
10/06/15 AlexL      2.05    cleaning up the handles 
10/07/21 AlexL      2.06    [EMM5-0850] Assign the mesurement values on the app-server 
13/08/2015 amity    2.07    [SR:EMM6-0022] implement the laser api value to the acot table
------------------------------------------------------------------------------*/

function f-fields returns char (input p-grecc as char) forward .

def temp-table tt-fields no-undo
  field v-field as char.

define variable v-BizError as char no-undo.

def temp-table tt-acot like acot.

def stream sFrom.
def var vLine as char no-undo.
def var n     as inte no-undo.
def temp-table tt
  field linenr as inte
  field p1     as char
  field p2     as char
  field p3     as char
  field p4     as char
  field p5     as char
  .

{x/xxxxlparam.i}

/*message 'hello from acotbmeas2.p at ' string(time,"hh:mm:ss") view-as alert-box warning.*/

PROCEDURE p-tabshow:
  /*------------------------------------------------------------------------------
      Event: TAB-SHOW
  --------------------------------------------------------------------------------
    Purpose:
      Notes:
    Created: 07/12/06 Alex Leenstra
  ------------------------------------------------------------------------------*/
  
  /*message 'hello from p-tabshow in acotbmeas2.p at ' string(time,"hh:mm:ss") view-as alert-box warning.*/
  
  define variable h-fbrowse as handle no-undo.
  define variable h-tbrowse as handle no-undo.
  define variable h-query   as handle no-undo.
  define variable h-buffer  as handle no-undo.
  define variable h-column  as handle no-undo.
  define variable h-fillin  as handle no-undo.
  define variable h-field   as handle no-undo.
  define variable v-fields  as char   no-undo.
  define variable v-label   as char   no-undo.
  define variable v-lengte  as inte   no-undo.
  define variable v-atasn   as inte   no-undo.

  define frame f-test.

  find first atas no-lock where rowid(atask) = f-getrowid('atask') no-error.
  find first acut no-lock where rowid(acut) = f-getrowid('acut') no-error.
   
  if not available atas then
  do:
    v-atasn = integer(f-dynafunc ('f-atasn' + chr (1) + '-1')).
    find first atas no-lock where atas.xlevc = f-xlevc('atask') and atas.atasn = v-atasn no-error.
    if not available atas then
      return.
  end.

  assign
    h-fbrowse = f-handle('v-fbrowse')
    h-tbrowse = f-handle('v-tbrowse')
    v-fields  = f-fields(atas.grecc).
 
  /* EMM5-0820, the logic which changes the focus of another browser to correct record when one is selected */
  on value-changed of h-fbrowse persistent  run p-rowleave in v-customhandle  (input h-fbrowse:handle,h-tbrowse:handle).      /* moved, not only main query   -   v3.15   */
  on value-changed of h-tbrowse persistent  run p-rowleave in v-customhandle  (input h-tbrowse:handle,h-fbrowse:handle).      /* moved, not only main query   -   v3.15   */

  create buffer h-buffer for table 'tt-acot'.

  repeat v-cnt = 1 to num-entries(v-fields):
    assign
      h-field  = h-buffer:buffer-field( entry(v-cnt,v-fields) )
      v-lengte = max(length(string('x',h-field:format)) + 4 , length(h-field:label) + 2)
      v-label  = caps(substring(h-field:label,1,1)) + substring(h-field:label,2).
    if index(entry(v-cnt,v-fields),'-end') GT 0 then next.
    assign
      h-column             = h-fbrowse:add-like-column('tt-acot' + "." + entry(v-cnt,v-fields))
      h-column:label       = v-label
      h-column:width-chars = v-lengte
      h-column:name        = entry(v-cnt,v-fields)
      h-column:read-only   = true
      no-error .
  end. /*repeat*/

  repeat v-cnt = 1 to num-entries(v-fields):
    if index(entry(v-cnt,v-fields),'-bgn') GT 0 then next.
    assign
      h-field  = h-buffer:buffer-field( entry(v-cnt,v-fields) )
      v-lengte = max(length(string('x',h-field:format)) + 4 , length(h-field:label) + 2)  /*gp: EMM5-0856, applied the same width settings for columns as upper browser */
      v-label  = caps(substring(h-field:label,1,1)) + substring(h-field:label,2).
    assign
      h-column             = h-tbrowse:add-like-column('tt-acot' + "." + entry(v-cnt,v-fields))
      h-column:label       = v-label
      h-column:width-chars = v-lengte
      h-column:name        = entry(v-cnt,v-fields)
      h-column:read-only   = true
      no-error .
  end. /*repaet*/

  delete object h-buffer.

  /* gp:  EMM5-0857, do not delete the h-column here, that will remove the last column it is pointing to in browser */
  /* delete object h-column. */ /* 2.05 */
  
  assign
    h-fbrowse:num-locked-columns = 2
    h-tbrowse:num-locked-columns = 2.
    
  /* EMM5-0820 */
  if available atas then
    find first gtsk no-lock where gtsk.xlevc = f-xlevc('gtsktype') and gtsk.gtskc = atas.gtskc no-error.

  assign 
    p-result = 'v-xstac'    + chr (1) + (if available atas then atas.xstac else '') + chr (1) + 
    'v-timefrom' + chr (1) + (if acut.acutnstarttime = ? then '' else string(acut.acutnstarttime,'hh:mm:ss')) + chr (1) + 
    'v-timeto'   + chr (1) + (if acut.acutnendtime   = ? then '' else string(acut.acutnendtime,'hh:mm:ss') ) + chr (1) + 
    'v-gtskm'    + chr (1) + (if available gtsk then gtsk.gtskm else '').

  apply 'home' to h-fbrowse.
  apply 'home' to h-tbrowse.

END PROCEDURE. /* p-tabshow */


PROCEDURE p-tabhide:
  /*------------------------------------------------------------------------------
      Event: TAB-HIDE
  --------------------------------------------------------------------------------
    Purpose:
      Notes:
    Created: 07/12/07 Alex Leenstra
  ------------------------------------------------------------------------------*/
  
  /*message 'hello from p-tabhide in acotbmeas2.p' view-as alert-box information.*/

  define variable h-fbrowse as handle no-undo.
  define variable h-tbrowse as handle no-undo.
  define variable h-column  as handle no-undo.
  define variable v-fields  as char   no-undo.

  find first atas no-lock where rowid(atask) = f-getrowid('atask') no-error.

  /*if available atas then message "do check: are you handling following task ?" skip atas.atasn view-as alert-box information.*/

  if not avail atas then return.

  assign
    h-fbrowse = f-handle('v-fbrowse').
  h-tbrowse = f-handle('v-tbrowse').

  apply 'tab' to h-fbrowse.

  repeat v-cnt = h-fbrowse:num-columns to 1 by -1:
    if v-cnt GT 2 then
    do:
      h-column = h-fbrowse:get-browse-column(v-cnt). 
      delete widget h-column. 
    end.
  end. /* repeat, cleanup the upper browser */

  apply 'tab' to h-tbrowse.

  repeat v-cnt = h-tbrowse:num-columns to 1 by -1:
    if v-cnt GT 2 then
    do:
      h-column = h-tbrowse:get-browse-column(v-cnt).
      delete widget h-column. 
    end.
  end. /* repeat, cleanup the lower browser */
 
END PROCEDURE. /* p-tabhide */


PROCEDURE p-bc:
  /*------------------------------------------------------------------------------
      Event: BEFORE-COMMIT
  --------------------------------------------------------------------------------
    Purpose: Validate fields acutnlength and acutnweight.
             Validate/calculate the start time and end time.
             Force leave from the 2 browse (quick fix for Progress bug).
             Commit from the browsers to acot table.
      Notes:
    Created: 07/12/07 Alex Leenstra
  ------------------------------------------------------------------------------*/
  
  /*message 'hello from p-bc in acotbmeas2.p at ' string(time,"hh:mm:ss") view-as alert-box warning.*/
  
  define variable h-fbrowse        as handle no-undo.
  define variable h-tbrowse        as handle no-undo.
  define variable h-column         as handle no-undo.
  define variable h-query          as handle no-undo.
  define variable h-fbuffer        as handle no-undo.
  define variable h-tbuffer        as handle no-undo.
  define variable h-field1         as handle no-undo.
  define variable h-change         as handle no-undo.
  define variable v-fields         as char   no-undo.
  define variable v-prepare        as char   no-undo.

  define variable v-acutcstarttime as char   no-undo.
  define variable v-acutcendtime   as char   no-undo.
  define variable v-acutnstarttime as inte   no-undo.
  define variable v-acutnendtime   as inte   no-undo.
  define variable v-hour           as inte   no-undo.
  define variable v-minute         as inte   no-undo.
  define variable v-second         as inte   no-undo.
  define variable v-time           as inte   no-undo.
  define variable v-skip           as char   no-undo.

  define variable v-result         as char   no-undo.
  define variable v-attribute      as char   no-undo.
  define variable v-action         as char   no-undo.
  define variable v-return-error   as char   no-undo.
  
  define variable h-buffer         as handle no-undo.
  define variable h-field          as handle no-undo.
 
  find first atas no-lock where rowid(atask) = f-getrowid('atask') no-error.
  /*if f-xusec() = 'ecl' then 
  message "hi eric, this is after find first atas no-lock no-error" skip avail atas skip
  view-as alert-box warning.*/

  assign 
    v-fields = f-fields(atas.grecc). /* these are the measurement fields in the browser */ 
   
  create buffer h-buffer for table 'acot'.
  
  repeat v-cnt = 1 to h-buffer:num-fields: /* v2.03 Walkthrough all of the acot fields */
    h-field = h-buffer:buffer-field(v-cnt).
    if lookup(h-field:name,v-fields) = 0 then /* v2.03 If the field is not a measurement field then don't copy it */ 
      assign v-skip = v-skip + min(v-skip,',') + h-field:name.
  end. /*repeat*/

  delete object h-field.
  delete object h-buffer.
 
  /*  Force leave from the browse */
  assign
    h-fbrowse = f-handle('v-fbrowse')
    h-tbrowse = f-handle('v-tbrowse').

  /*  Copy record from browse to acot table */
  assign
    h-query   = h-fbrowse:query
    h-fbuffer = h-query:get-buffer-handle(1) no-error.

  empty temp-table tt-acot.

  find first acut no-lock where rowid(acut) = f-getrowid('acut') no-error.
  /*if f-xusec() = 'ecl' then 
  message "hi eric, this is after find first acut no-lock no-error" skip avail acut skip
  view-as alert-box warning.*/

  create buffer h-tbuffer for table 'tt-acot'.
  v-prepare = 'where acot.xlevc = ' + quoter(f-xlevc('acot')) +
    '  and acot.atasn = ' + string(acut.atasn) +
    '  and acot.acutn = ' + string(acut.acutn) +
    '  and acot.acotnseq = '.

  h-query:get-first(no-lock).
  repeat while h-fbuffer:avail: /* fill the temp-table */ 
    v-ok = h-tbuffer:buffer-create.
    h-tbuffer:buffer-copy (h-fbuffer:handle). /*  v2.03 skip the non measurement fields */ 
    h-query:get-next (no-lock).
  end. /*repeat*/
 
  /* v2.06 [EMM5-0850] run the assign program on the appserver whn it's available  */ 
  
  /*message 'hello from acotbmeas2.p' 
  skip 'f-lanapp()=' f-lanapp()
  view-as alert-box.*/
  
 
  if valid-handle(f-lanapp()) then 
    run a/acotrpers.p on f-lanapp() ({x/xxxxlparamstd.i} input table tt-acot, input v-skip). 
  else 
    run a/acotrpers.p ({x/xxxxlparamstd.i} input table tt-acot, input v-skip). 
 
END PROCEDURE. /* p-bc */


PROCEDURE p-enable:
  /*------------------------------------------------------------------------------
      Event: AFTER-ENABLE
  --------------------------------------------------------------------------------
    Purpose:
      Notes:
    Created: 06/12/06 Alex Leenstra
  ------------------------------------------------------------------------------*/
  
  /*message 'hello from p-enable in acotbmeas2.p at ' string(time,"hh:mm:ss") view-as alert-box warning.*/
  
  define variable h-fbrowse as handle no-undo.
  define variable h-tbrowse as handle no-undo.
  define variable h-column  as handle no-undo.
  define variable v-fields  as inte   no-undo.

  define variable h-buffer  as handle no-undo.
  define variable h-field   as handle no-undo.

  find first atas no-lock where rowid(atask) = f-getrowid('atask') no-error.
  if not available atas then return.

  assign
    h-fbrowse = f-handle('v-fbrowse').
  h-tbrowse = f-handle('v-tbrowse').

  apply 'home' to  h-fbrowse.
  apply 'home' to  h-tbrowse.

  repeat v-fields = 3 to h-fbrowse:num-columns:
    h-column = h-fbrowse:get-browse-column(v-fields).
    h-column:read-only = false.
  end. /*repeat*/

  repeat v-fields = 3 to h-tbrowse:num-columns:
    h-column = h-tbrowse:get-browse-column(v-fields).
    h-column:read-only = false.
  end. /*repeat*/

  find first acot no-lock where rowid(acot) = f-getrowid('acot') no-error.
  find first acut no-lock where rowid(acut) = f-getrowid('acut') no-error.

  find first atas no-lock where rowid(atask) = f-getrowid('atask') no-error.

  assign 
    p-attribute = ''.
  repeat v-cnt = 1 to num-entries( f-fields(atas.grecc)):
    assign 
      p-attribute = p-attribute  + min(p-attribute,chr(1)) + entry(v-cnt, f-fields(atas.grecc))  + chr(1) + 'sensitive' + chr(1) + 'true'.
  end. /*repeat*/

  create buffer h-buffer for table 'atask'.
  v-ok = h-buffer:find-by-rowid(f-getrowid('atask'),no-lock) no-error.

  if v-ok then
  do:
    h-field = h-buffer:buffer-field('grecc') no-error.
    for each xwid where xwid.xproc = p-xproc no-lock :
      assign 
        h-field = h-buffer:buffer-field(replace(xwid.xwidc,'v-','')) no-error.
      if valid-handle(h-field) then assign p-result = p-result  + min(p-result,chr(1)) + xwid.xwidc + chr(1) + h-field:buffer-value.
    end. /*for-each*/
  end.
 
END PROCEDURE. /* p-enable */


PROCEDURE p-disable-browse:
  /*------------------------------------------------------------------------------
      Event: AFTER-ENABLE
  --------------------------------------------------------------------------------
    Purpose:
      Notes:
    Created: 06/12/06 Alex Leenstra
  ------------------------------------------------------------------------------*/
  
  /*message 'hello from p-disable-browse in acotbmeas2.p at ' string(time,"hh:mm:ss") view-as alert-box warning.*/
  
  define variable h-fbrowse as handle no-undo.
  define variable h-tbrowse as handle no-undo.
  define variable h-column  as handle no-undo.

  define variable v-cancel  as logi   no-undo init false.

  assign 
    p-mode = 0.
  assign
    h-fbrowse = f-handle('v-fbrowse')
    h-tbrowse = f-handle('v-tbrowse').

  if valid-handle( h-fbrowse ) then
  repeat v-cnt = 3 to h-fbrowse:num-columns:
    assign 
      h-column = h-fbrowse:get-browse-column(v-cnt).
    if h-column:read-only = false then assign v-cancel = true.
    h-column:read-only = true.
  end. /*repeat*/

  if valid-handle( h-tbrowse ) then
  repeat v-cnt = 3 to h-tbrowse:num-columns:
    assign
      h-column = h-tbrowse:get-browse-column(v-cnt).
    if h-column:read-only = false then
      assign v-cancel = true.
    h-column:read-only = true.
  end. /*repeat*/

  if v-cancel = true or p-mode GT 0 then
  do:
  end.

END PROCEDURE. /* p-disable-browse*/


PROCEDURE p-AfterCommit:
  /*------------------------------------------------------------------------------
      Event: COMMIT-COMPLETE
  --------------------------------------------------------------------------------
    Purpose:
      Notes:
    Created: 07/12/10 Alex Leenstra
  ------------------------------------------------------------------------------*/
  
  /*message 'hello from p-aftercommit in acotbmeas2.p at ' string(time,"hh:mm:ss") view-as alert-box warning.*/

  define variable h-fbrowse as handle no-undo.
  define variable h-tbrowse as handle no-undo.
  define variable h-column  as handle no-undo.
  define variable h-query   as handle no-undo.
  define variable h-buffer  as handle no-undo.
  define variable h-field   as handle no-undo.
  define variable h-change  as handle no-undo.
  define variable v-fields  as inte   no-undo.

  create buffer h-change for table 'acot'.

  find first atas no-lock where rowid(atask) = f-getrowid('atask') no-error.
  find first acut no-lock where rowid(acut) = f-getrowid('acut') no-error.

  for each acot no-lock where acot.xlevc = f-xlevc('acot')
    and acot.atasn = acut.atasn
    and acot.acutn = acut.acutn:
    run p-CheckSlit(input rowid(acot)).
  end.

  if v-BizError GT '' then
    assign p-error = 'def-warn' + chr(1)
      + 'Please carefully read BLOCKS and WARNS and act accordingly.' 
      + chr(13) + v-BizError 
      + CHR(13) + chr(13) + 'Incase BLOCK mentioned you will be blocked when trying to set cut to measured (350).'
      + chr(13) + chr(13) + 'When bizrules unclear please take note of code between []'.

  run p-disable-browse.
  run p-tabhide.
  run p-tabshow.
  
  run p-restore. /* show the correct fields in the browsers */ 

  assign 
    p-action = 's-qryreopen'.

END PROCEDURE. /* p-AfterComple */


PROCEDURE p-CheckSlit:
  /*------------------------------------------------------------------------------
      Event: COMMIT-COMPLETE
  --------------------------------------------------------------------------------
    Purpose:
      Notes:
    Created: 08/12/06 Alex Leenstra
  ------------------------------------------------------------------------------*/
  
  /*message 'hello from p-checkslit in acotbmeas2.p at ' string(time,"hh:mm:ss") view-as alert-box warning.*/

  define input parameter p-rowid as rowid no-undo.

  define variable v-WidRange      as inte no-undo.
  define variable v-PlusTolerance as deci no-undo.
  define variable v-MinTolerance  as deci no-undo.
  
  def buffer b2cot for acot.

  find first acot no-lock where rowid(acot) = p-rowid no-error.
  find first acut no-lock where acut.xlevc = f-xlevc('acut') and acut.atasn = acot.atasn and acut.acutn = acot.acutn no-error.
  find first atas no-lock where atas.xlevc = f-xlevc('atask') and atas.atasn = acot.atasn no-error.
 
  if acot.acotaburr-ws-bgn * 1000 - acot.acotathick-ws-bgn * 1000 LT 0  then v-BizError = v-BizError + chr(13) + '[4A] negative burr for slit ' + string(acot.acutn) + "-" + string(acot.acotnseq) + " (ws-bgn)".
  if acot.acotaburr-ws-bgn * 1000 - acot.acotathick-ws-bgn * 1000 GT 40 then v-BizError = v-BizError + chr(13) + '[4B] too high burr for slit ' + string(acot.acutn) + "-" + string(acot.acotnseq) + " (ws-bgn)".
  if acot.acotaburr-ds-bgn * 1000 - acot.acotathick-ds-bgn * 1000 LT 0  then v-BizError = v-BizError + chr(13) + '[4C] negative burr for slit ' + string(acot.acutn) + "-" + string(acot.acotnseq) + " (ds-bgn)".
  if acot.acotaburr-ds-bgn * 1000 - acot.acotathick-ds-bgn * 1000 GT 40 then v-BizError = v-BizError + chr(13) + '[4D] too high burr for slit ' + string(acot.acutn) + "-" + string(acot.acotnseq) + " (ds-bgn)".

  if acot.acotaburr-ws-end * 1000 - acot.acotathick-ws-end * 1000 LT 0  then v-BizError = v-BizError + chr(13) + '[4E] negative burr for slit ' + string(acot.acutn) + "-" + string(acot.acotnseq) + " (ws-end)".
  if acot.acotaburr-ws-end * 1000 - acot.acotathick-ws-end * 1000 GT 40 then v-BizError = v-BizError + chr(13) + '[4F] too high burr for slit ' + string(acot.acutn) + "-" + string(acot.acotnseq) + " (ws-end)".
  if acot.acotaburr-ds-end * 1000 - acot.acotathick-ds-end * 1000 LT 0  then v-BizError = v-BizError + chr(13) + '[4G] negative burr for slit ' + string(acot.acutn) + "-" + string(acot.acotnseq) + " (ds-end)".
  if acot.acotaburr-ds-end * 1000 - acot.acotathick-ds-end * 1000 GT 40 then v-BizError = v-BizError + chr(13) + '[4H] too high burr for slit ' + string(acot.acutn) + "-" + string(acot.acotnseq) + " (ds-end)".

  find first ocoi no-lock where ocoi.xlevc = f-xlevc('ocoil') and ocoi.ocoin = acot.ocoin no-error.
  find first ggra no-lock where ggra.xlevc = f-xlevc('ggrade') and ggra.ggrac = ocoi.ggrac no-error.

  if acot.sordn GT 0 then
  do:
    find first sord no-lock where sord.xlevc = f-xlevc('sorder') and sord.sordn = acot.sordn no-error.

    /*BEGIN-BLOCK:order-demands, beware this block is very similar to other sections and should be kept synched!*/
    if acutnwelds GT sord.sordnmaxwelds then v-BizError = v-BizError + chr(13) + '[4i] too many welds ' + string(acot.acutn) + "-" + string(acot.acotnseq) + (if sord.sordlblockwelds then ' BLOCK' else ' WARN').

    if num-entries(sord.sordtwidrange1,"-") = 2 then
    do:
      if decimal(entry(1,sord.sordtwidrange1,"-"))      LT ocoi.ocoiawidth and decimal(entry(2,sorder.sordtwidrange1,"-")) GE ocoi.ocoiawidth then v-WidRange = 1.
      else if decimal(entry(1,sord.sordtwidrange2,"-")) LT ocoi.ocoiawidth and decimal(entry(2,sorder.sordtwidrange2,"-")) GE ocoi.ocoiawidth then v-WidRange = 2.
        else if decimal(entry(1,sord.sordtwidrange3,"-")) LT ocoi.ocoiawidth and decimal(entry(2,sorder.sordtwidrange3,"-")) GE ocoi.ocoiawidth then v-WidRange = 3.
          else v-WidRange = 0.
      case v-WidRange:
        when 1 then
          assign
            v-PlusTolerance = sord.sordamaxwidtol1
            v-MinTolerance  = sord.sordaminwidtol1.
        when 2 then
          assign
            v-PlusTolerance = sord.sordamaxwidtol2
            v-MinTolerance  = sord.sordaminwidtol2.
        when 3 then
          assign
            v-PlusTolerance = sord.sordamaxwidtol3
            v-MinTolerance  = sord.sordaminwidtol3.
        otherwise.
      end case.
    end.

    if acot.acotawidth + v-PlusTolerance LT acot.acotawidth-bgn and acot.acotawidth-bgn NE 0                                                  then assign v-BizError = v-BizError + chr(13) + '[4J] out of plustolerance ' + string(acot.acutn) + "-" + string(acot.acotnseq) + (if sord.sordlblockwidtol1 then ' BLOCK' else 'WARN').
    if acot.acotawidth + v-MinTolerance GT acot.acotawidth-bgn and acot.acotawidth-bgn NE 0                                                   then assign v-BizError = v-BizError + chr(13) + '[4K] out of mintolerance ' + string(acot.acutn) + "-" + string(acot.acotnseq) + (if sord.sordlBlMinWidTol1 then ' BLOCK' else 'WARN').
    if acot.acotathick-ws-bgn GT 0 and abs(acot.acotathick-ws-bgn - ggra.ggraathickness) GT ggra.ggraathickness * ggra.ggraathickmargin / 100 then assign v-BizError = v-BizError + chr(13) + '[4L] thickness out of tolerance for slit ' + string(acot.acutn) + "-" + string(acot.acotnseq) + "(ws-bgn)".
    if acot.acotathick-ds-bgn GT 0 and abs(acot.acotathick-ds-bgn - ggra.ggraathickness) GT ggra.ggraathickness * ggra.ggraathickmargin / 100 then assign v-BizError = v-BizError + chr(13) + '[4M] thickness out of tolerance for slit ' + string(acot.acutn) + "-" + string(acot.acotnseq) + "(ds-bgn)".

    if acot.acotaburr-ds-bgn * 1000 - acot.acotathick-ds-bgn * 1000 GT sord.sordnmaxburr and sord.sordnMaxBurr NE ?                           then assign v-BizError = v-BizError + chr(13) + "[4N] burr too high for order " + string(acot.sordn) + ", " + string(acot.acutn) + "-" + string(acot.acotnseq) + " (ds-bgn) " + (if sord.sordlBlockBurr then 'BLOCK' else 'WARN').
    if acot.acotaburr-ws-bgn * 1000 - acot.acotathick-ws-bgn * 1000 GT sord.sordnmaxburr and sord.sordnMaxBurr NE ?                           then assign v-BizError = v-BizError + chr(13) + "[4O] burr too high for order " + string(acot.sordn) + ", " + string(acot.acutn) + "-" + string(acot.acotnseq) + " (ws-bgn) " + (if sord.sordlBlockBurr then 'BLOCK' else 'WARN').
    if acot.acotacamber-bgn GT sord.sordamaxcamber and sord.sordamaxcamber NE ?                                                               then assign v-BizError = v-BizError + chr(13) + "[4P] camber too high for order " + string(acot.sordn) + ", " + string(acot.acutn) + "-" + string(acot.acotnseq) + " (bgn) " + (if sord.sordlblockcamber then 'B-WARN 250mm!' else 'WARN').

    if acot.acotawavehgt-ds-bgn GT sord.sordnmaxwavehgt and sord.sordnmaxwavehgt NE ?                                                         then assign v-BizError = v-BizError + chr(13) + "[4Q] waveheight too high DS-BGN " + string(acot.sordn) + ", " + " (ds-bgn) " + (if sord.sordlBlockWaveHgt then 'BLOCK' else 'WARN') + ' ' + string(acot.acutn) + "-" + string(acot.acotnseq).
    if acot.acotawavehgt-ws-bgn GT sord.sordnmaxwavehgt and sord.sordnmaxwavehgt NE ?                                                         then assign v-BizError = v-BizError + chr(13) + "[4R] waveheight too high WS-BGN " + string(acot.sordn) + ", " + " (ws-bgn) " + (if sord.sordlBlockWaveHgt then 'BLOCK' else 'WARN') + ' ' + string(acot.acutn) + "-" + string(acot.acotnseq).

    if acot.acotawavehgt-ds-bgn / acot.acotawavepitch-ds-bgn * 100 GT sord.sordamaxwavefactor and sord.sordamaxwavefactor NE ?                then assign v-BizError = v-BizError + chr(13) + "[4S] wavefactor too high DS-BGN " + string(acot.sordn) + ", " + " (ds-bgn) " + (if sord.sordlBlockWaveFactor then 'BLOCK' else 'WARN') + ' ' + string(acot.acutn) + "-" + string(acot.acotnseq).
    if acot.acotawavehgt-ws-bgn / acot.acotawavepitch-ws-bgn * 100 GT sord.sordamaxwavefactor and sord.sordamaxwavefactor NE ?                then assign v-BizError = v-BizError + chr(13) + "[4T] wavefactor too high WS-BGN " + string(acot.sordn) + ", " + " (ws-bgn) " + (if sord.sordlBlockWaveFactor then 'BLOCK' else 'WARN') + ' ' + string(acot.acutn) + "-" + string(acot.acotnseq).

    if acot.acotathick-ws-end GT 0 and abs(acot.acotathick-ws-end - ggra.ggraathickness) GT ggra.ggraathickness * ggra.ggraathickmargin / 100 then assign v-BizError = v-BizError + chr(13) + '[4U] thickness out of tolerance for slit ' + string(acot.acutn) + "-" + string(acot.acotnseq) + "(ws-end)".
    if acot.acotathick-ds-end GT 0 and abs(acot.acotathick-ds-end - ggra.ggraathickness) GT ggra.ggraathickness * ggra.ggraathickmargin / 100 then assign v-BizError = v-BizError + chr(13) + '[4V] thickness out of tolerance for slit ' + string(acot.acutn) + "-" + string(acot.acotnseq) + "(ds-end)".

    if acot.acotaedge-ds-bgn GT sord.sordnmaxedge and sord.sordnmaxedge NE ?                                                                  then assign v-BizError = v-BizError + chr(13) + "[4W] whiteline too high for order " + string(acot.sordn) + ", " + string(acot.acutn) + "-" + string(acot.acotnseq) + " (ds-bgn) " + (if sord.sordlblockedge then 'BLOCK' else 'WARN').
    if acot.acotaedge-ws-bgn GT sord.sordnmaxedge and sord.sordnmaxedge NE ?                                                                  then assign v-BizError = v-BizError + chr(13) + "[4X] whiteline too high for order " + string(acot.sordn) + ", " + string(acot.acutn) + "-" + string(acot.acotnseq) + " (ws-bgn) " + (if sord.sordlblockedge then 'BLOCK' else 'WARN').
    if acot.acotaedge-ds-end GT sord.sordnmaxedge and sord.sordnmaxedge NE ?                                                                  then assign v-BizError = v-BizError + chr(13) + "[4Y] whiteline too high for order " + string(acot.sordn) + ", " + string(acot.acutn) + "-" + string(acot.acotnseq) + " (ds-end) " + (if sord.sordlblockedge then 'BLOCK' else 'WARN').
    if acot.acotaedge-ws-end GT sord.sordnmaxedge and sord.sordnmaxedge NE ?                                                                  then assign v-BizError = v-BizError + chr(13) + "[4Z] whiteline too high for order " + string(acot.sordn) + ", " + string(acot.acutn) + "-" + string(acot.acotnseq) + " (ws-end) " + (if sord.sordlblockedge then 'BLOCK' else 'WARN').

    if acot.acotaburr-ds-end * 1000 - acot.acotathick-ds-end * 1000 GT sord.sordnMaxBurr and sord.sordnMaxBurr NE ?                           then assign v-BizError = v-BizError + chr(13) + "[41] burr too high for order " + string(acot.sordn) + ", " + string(acot.acutn) + "-" + string(acot.acotnseq) + " (ds-end) " + (if sord.sordlBlockBurr then 'BLOCK' else 'WARN').
    if acot.acotaburr-ws-end * 1000 - acot.acotathick-ws-end * 1000 GT sord.sordnMaxBurr and sord.sordnMaxBurr NE ?                           then assign v-BizError = v-BizError + chr(13) + "[42] burr too high for order " + string(acot.sordn) + ", " + string(acot.acutn) + "-" + string(acot.acotnseq) + " (ws-end) " + (if sord.sordlBlockBurr then 'BLOCK' else 'WARN').
    if acot.acotacamber-end GT sord.sordaMaxCamber and sord.sordaMaxCamber NE ?                                                               then assign v-BizError = v-BizError + chr(13) + "[43] camber too high for order " + string(acot.sordn) + ", " + string(acot.acutn) + "-" + string(acot.acotnseq) + " (end) " + (if sord.sordlBlockCamber then 'B-WARN 250mm!' else 'WARN').

    if acot.acotawavehgt-ds-end GT sord.sordnMaxWavehgt and sord.sordnmaxwavehgt NE ?                                                         then assign v-BizError = v-BizError + chr(13) + "[44] waveheight too high DS-END " + string(acot.sordn) + ", " + " (ds-end) " + (if sord.sordlBlockWaveHgt then 'BLOCK' else 'WARN') + ' ' + string(acot.acutn) + "-" + string(acot.acotnseq).
    if acot.acotawavehgt-ws-end GT sord.sordnMaxWavehgt and sord.sordnmaxwavehgt NE ?                                                         then assign v-BizError = v-BizError + chr(13) + "[45] waveheight too high WS-END " + string(acot.sordn) + ", " + " (ws-end) " + (if sord.sordlBlockWaveHgt then 'BLOCK' else 'WARN') + ' ' + string(acot.acutn) + "-" + string(acot.acotnseq).

    if acot.acotawavehgt-ds-end / acot.acotawavepitch-ds-end * 100 GT sord.sordaMaxWavefactor and sord.sordamaxwavefactor NE ?                then assign v-BizError = v-BizError + chr(13) + "[46] wavefactor too high DS-END " + string(acot.sordn) + ", " + " (ds-end) " + (if sord.sordlBlockWaveFactor then 'BLOCK' else 'WARN') + ' ' + string(acot.acutn) + "-" + string(acot.acotnseq).
    if acot.acotawavehgt-ws-end / acot.acotawavepitch-ws-end * 100 GT sord.sordaMaxWavefactor and sord.sordamaxwavefactor NE ?                then assign v-BizError = v-BizError + chr(13) + "[47] wavefactor too high DS-END " + string(acot.sordn) + ", " + " (ws-end) " + (if sord.sordlBlockWaveFactor then 'BLOCK' else 'WARN') + ' ' + string(acot.acutn) + "-" + string(acot.acotnseq).
  /*END-BLOCK:order-demands*/
  end.
  else
  do: /* stock-coil */
    if acot.acotawidth + 1 LT acot.acotawidth-bgn and acot.acotawidth-bgn NE 0                                                                then assign v-BizError = v-BizError + chr(13) + '[48] out of plustolerance ' + string(acot.acutn) + "-" + string(acot.acotnseq) + ' WARN'.
    if acot.acotawidth - 1 GT acot.acotawidth-bgn and acot.acotawidth-bgn NE 0                                                                then assign v-BizError = v-BizError + chr(13) + '[49] out of mintolerance ' + string(acot.acutn) + "-" + string(acot.acotnseq) + ' WARN'.
    if acot.acotathick-ws-bgn GT 0 and abs(acot.acotathick-ws-bgn - ggra.ggraathickness) GT ggra.ggraathickness * ggra.ggraathickmargin / 100 then assign v-BizError = v-BizError + chr(13) + '[410] thickness out of tolerance for slit ' + string(acot.acutn) + "-" + string(acot.acotnseq) + "(ws-bgn)".
    if acot.acotathick-ds-bgn GT 0 and abs(acot.acotathick-ds-bgn - ggra.ggraathickness) GT ggra.ggraathickness * ggra.ggraathickmargin / 100 then assign v-BizError = v-BizError + chr(13) + '[411] thickness out of tolerance for slit ' + string(acot.acutn) + "-" + string(acot.acotnseq) + "(ds-bgn)".
    /*change-ccc: if consequetive k-task then compare measurements with demands of that salesorder!*/
    /*message 'change-ccc-1' view-as alert-box warning.*/
    for first acin no-lock where acin.xlevc = f-xlevc('acin')
      and acin.ocoin = acot.ocoin,
      first atas no-lock where atas.xlevc = f-xlevc('atask')
      and atas.atasn = acin.atasn
      and atas.gtskc = "K":
      for first b2cot no-lock where b2cot.xlevc = '1'
        and b2cot.atasn = atas.atasn:
        for first sord no-lock where sord.xlevc = f-xlevc('sorder')
          and sord.sordn = b2cot.sordn
          and sord.sordtproduct = "Laminations":
          /*message 'change-ccc-1 order found' 
          skip sord.sordn 
          skip b2cot.acotacamber-bgn 
          skip sord.sordamaxcamber 
          view-as alert-box warning.*/
          /*BEGIN-BLOCK:order-demands, beware this block is very similar to other sections and should be kept synched!*/
          if acutnwelds GT sord.sordnmaxwelds then v-BizError = v-BizError + chr(13) + '[4i] too many welds ' + string(acot.acutn) + "-" + string(acot.acotnseq) + (if sord.sordlblockwelds then ' BLOCK' else ' WARN').
      
          if num-entries(sord.sordtwidrange1,"-") = 2 then
          do:
            if decimal(entry(1,sord.sordtwidrange1,"-"))      LT ocoi.ocoiawidth and decimal(entry(2,sorder.sordtwidrange1,"-")) GE ocoi.ocoiawidth then v-WidRange = 1.
            else if decimal(entry(1,sord.sordtwidrange2,"-")) LT ocoi.ocoiawidth and decimal(entry(2,sorder.sordtwidrange2,"-")) GE ocoi.ocoiawidth then v-WidRange = 2.
              else if decimal(entry(1,sord.sordtwidrange3,"-")) LT ocoi.ocoiawidth and decimal(entry(2,sorder.sordtwidrange3,"-")) GE ocoi.ocoiawidth then v-WidRange = 3.
                else v-WidRange = 0.
            case v-WidRange:
              when 1 then
                assign
                  v-PlusTolerance = sord.sordamaxwidtol1
                  v-MinTolerance  = sord.sordaminwidtol1.
              when 2 then
                assign
                  v-PlusTolerance = sord.sordamaxwidtol2
                  v-MinTolerance  = sord.sordaminwidtol2.
              when 3 then
                assign
                  v-PlusTolerance = sord.sordamaxwidtol3
                  v-MinTolerance  = sord.sordaminwidtol3.
              otherwise.
            end case.
          end.
      
          if acot.acotawidth + v-PlusTolerance LT acot.acotawidth-bgn and acot.acotawidth-bgn NE 0                                                  then assign v-BizError = v-BizError + chr(13) + '[4J] out of plustolerance ' + (if sord.sordlblockwidtol1 then 'BLOCK' else 'WARN').
          if acot.acotawidth + v-MinTolerance GT acot.acotawidth-bgn and acot.acotawidth-bgn NE 0                                                   then assign v-BizError = v-BizError + chr(13) + '[4K] out of mintolerance ' + (if sord.sordlBlMinWidTol1 then 'BLOCK' else 'WARN').
          if acot.acotathick-ws-bgn GT 0 and abs(acot.acotathick-ws-bgn - ggra.ggraathickness) GT ggra.ggraathickness * ggra.ggraathickmargin / 100 then assign v-BizError = v-BizError + chr(13) + '[4L] thickness out of tolerance for slit ' + string(acot.acutn) + "-" + string(acot.acotnseq) + "(ws-bgn)".
          if acot.acotathick-ds-bgn GT 0 and abs(acot.acotathick-ds-bgn - ggra.ggraathickness) GT ggra.ggraathickness * ggra.ggraathickmargin / 100 then assign v-BizError = v-BizError + chr(13) + '[4M] thickness out of tolerance for slit ' + string(acot.acutn) + "-" + string(acot.acotnseq) + "(ds-bgn)".
      
          if acot.acotaburr-ds-bgn * 1000 - acot.acotathick-ds-bgn * 1000 GT sord.sordnmaxburr and sord.sordnMaxBurr NE ?                           then assign v-BizError = v-BizError + chr(13) + "[4N] burr too high for order " + string(b2cot.sordn) + ", " + string(acot.acutn) + "-" + string(acot.acotnseq) + " (ds-bgn) " + (if sord.sordlBlockBurr then 'BLOCK' else 'WARN').
          if acot.acotaburr-ws-bgn * 1000 - acot.acotathick-ws-bgn * 1000 GT sord.sordnmaxburr and sord.sordnMaxBurr NE ?                           then assign v-BizError = v-BizError + chr(13) + "[4O] burr too high for order " + string(b2cot.sordn) + ", " + string(acot.acutn) + "-" + string(acot.acotnseq) + " (ws-bgn) " + (if sord.sordlBlockBurr then 'BLOCK' else 'WARN').
          if acot.acotacamber-bgn GT sord.sordamaxcamber and sord.sordamaxcamber NE ?                                                               then assign v-BizError = v-BizError + chr(13) + "[4P] camber too high for order " + string(b2cot.sordn) + ", " + string(acot.acutn) + "-" + string(acot.acotnseq) + " (bgn) " + (if sord.sordlblockcamber then 'B-WARN 250mm!' else 'WARN').
      
          if acot.acotawavehgt-ds-bgn GT sord.sordnmaxwavehgt and sord.sordnmaxwavehgt NE ?                                                         then assign v-BizError = v-BizError + chr(13) + "[4Q] waveheight too high DS-BGN " + string(b2cot.sordn) + ", " + " (ds-bgn) " + (if sord.sordlBlockWaveHgt then 'BLOCK' else 'WARN') + ' ' + string(acot.acutn) + "-" + string(acot.acotnseq).
          if acot.acotawavehgt-ws-bgn GT sord.sordnmaxwavehgt and sord.sordnmaxwavehgt NE ?                                                         then assign v-BizError = v-BizError + chr(13) + "[4R] waveheight too high WS-BGN " + string(b2cot.sordn) + ", " + " (ws-bgn) " + (if sord.sordlBlockWaveHgt then 'BLOCK' else 'WARN') + ' ' + string(acot.acutn) + "-" + string(acot.acotnseq).
      
          if acot.acotawavehgt-ds-bgn / acot.acotawavepitch-ds-bgn * 100 GT sord.sordamaxwavefactor and sord.sordamaxwavefactor NE ?                then assign v-BizError = v-BizError + chr(13) + "[4S] wavefactor too high DS-BGN " + string(b2cot.sordn) + ", " + " (ds-bgn) " + (if sord.sordlBlockWaveFactor then 'BLOCK' else 'WARN') + ' ' + string(acot.acutn) + "-" + string(acot.acotnseq).
          if acot.acotawavehgt-ws-bgn / acot.acotawavepitch-ws-bgn * 100 GT sord.sordamaxwavefactor and sord.sordamaxwavefactor NE ?                then assign v-BizError = v-BizError + chr(13) + "[4T] wavefactor too high WS-BGN " + string(b2cot.sordn) + ", " + " (ws-bgn) " + (if sord.sordlBlockWaveFactor then 'BLOCK' else 'WARN') + ' ' + string(acot.acutn) + "-" + string(acot.acotnseq).
      
          if acot.acotathick-ws-end GT 0 and abs(acot.acotathick-ws-end - ggra.ggraathickness) GT ggra.ggraathickness * ggra.ggraathickmargin / 100 then assign v-BizError = v-BizError + chr(13) + '[4U] thickness out of tolerance for slit ' + string(acot.acutn) + "-" + string(acot.acotnseq) + "(ws-end)".
          if acot.acotathick-ds-end GT 0 and abs(acot.acotathick-ds-end - ggra.ggraathickness) GT ggra.ggraathickness * ggra.ggraathickmargin / 100 then assign v-BizError = v-BizError + chr(13) + '[4V] thickness out of tolerance for slit ' + string(acot.acutn) + "-" + string(acot.acotnseq) + "(ds-end)".
      
          if acot.acotaedge-ds-bgn GT sord.sordnmaxedge and sord.sordnmaxedge NE ?                                                                  then assign v-BizError = v-BizError + chr(13) + "[4W] whiteline too high for order " + string(b2cot.sordn) + ", " + string(acot.acutn) + "-" + string(acot.acotnseq) + " (ds-bgn) " + (if sord.sordlblockedge then 'BLOCK' else 'WARN').
          if acot.acotaedge-ws-bgn GT sord.sordnmaxedge and sord.sordnmaxedge NE ?                                                                  then assign v-BizError = v-BizError + chr(13) + "[4X] whiteline too high for order " + string(b2cot.sordn) + ", " + string(acot.acutn) + "-" + string(acot.acotnseq) + " (ws-bgn) " + (if sord.sordlblockedge then 'BLOCK' else 'WARN').
          if acot.acotaedge-ds-end GT sord.sordnmaxedge and sord.sordnmaxedge NE ?                                                                  then assign v-BizError = v-BizError + chr(13) + "[4Y] whiteline too high for order " + string(b2cot.sordn) + ", " + string(acot.acutn) + "-" + string(acot.acotnseq) + " (ds-end) " + (if sord.sordlblockedge then 'BLOCK' else 'WARN').
          if acot.acotaedge-ws-end GT sord.sordnmaxedge and sord.sordnmaxedge NE ?                                                                  then assign v-BizError = v-BizError + chr(13) + "[4Z] whiteline too high for order " + string(b2cot.sordn) + ", " + string(acot.acutn) + "-" + string(acot.acotnseq) + " (ws-end) " + (if sord.sordlblockedge then 'BLOCK' else 'WARN').
      
          if acot.acotaburr-ds-end * 1000 - acot.acotathick-ds-end * 1000 GT sord.sordnMaxBurr and sord.sordnMaxBurr NE ?                           then assign v-BizError = v-BizError + chr(13) + "[41] burr too high for order " + string(b2cot.sordn) + ", " + string(acot.acutn) + "-" + string(acot.acotnseq) + " (ds-end) " + (if sord.sordlBlockBurr then 'BLOCK' else 'WARN').
          if acot.acotaburr-ws-end * 1000 - acot.acotathick-ws-end * 1000 GT sord.sordnMaxBurr and sord.sordnMaxBurr NE ?                           then assign v-BizError = v-BizError + chr(13) + "[42] burr too high for order " + string(b2cot.sordn) + ", " + string(acot.acutn) + "-" + string(acot.acotnseq) + " (ws-end) " + (if sord.sordlBlockBurr then 'BLOCK' else 'WARN').
          if acot.acotacamber-end GT sord.sordaMaxCamber and sord.sordaMaxCamber NE ?                                                               then assign v-BizError = v-BizError + chr(13) + "[43] camber too high for order " + string(b2cot.sordn) + ", " + string(acot.acutn) + "-" + string(acot.acotnseq) + " (end) " + (if sord.sordlBlockCamber then 'B-WARN 250mm!' else 'WARN').
      
          if acot.acotawavehgt-ds-end GT sord.sordnMaxWavehgt and sord.sordnmaxwavehgt NE ?                                                         then assign v-BizError = v-BizError + chr(13) + "[44] waveheight too high DS-END " + string(b2cot.sordn) + ", " + " (ds-end) " + (if sord.sordlBlockWaveHgt then 'BLOCK' else 'WARN') + ' ' + string(acot.acutn) + "-" + string(acot.acotnseq).
          if acot.acotawavehgt-ws-end GT sord.sordnMaxWavehgt and sord.sordnmaxwavehgt NE ?                                                         then assign v-BizError = v-BizError + chr(13) + "[45] waveheight too high WS-END " + string(b2cot.sordn) + ", " + " (ws-end) " + (if sord.sordlBlockWaveHgt then 'BLOCK' else 'WARN') + ' ' + string(acot.acutn) + "-" + string(acot.acotnseq).
      
          if acot.acotawavehgt-ds-end / acot.acotawavepitch-ds-end * 100 GT sord.sordaMaxWavefactor and sord.sordamaxwavefactor NE ?                then assign v-BizError = v-BizError + chr(13) + "[46] wavefactor too high DS-END " + string(b2cot.sordn) + ", " + " (ds-end) " + (if sord.sordlBlockWaveFactor then 'BLOCK' else 'WARN') + ' ' + string(acot.acutn) + "-" + string(acot.acotnseq).
          if acot.acotawavehgt-ws-end / acot.acotawavepitch-ws-end * 100 GT sord.sordaMaxWavefactor and sord.sordamaxwavefactor NE ?                then assign v-BizError = v-BizError + chr(13) + "[47] wavefactor too high DS-END " + string(b2cot.sordn) + ", " + " (ws-end) " + (if sord.sordlBlockWaveFactor then 'BLOCK' else 'WARN') + ' ' + string(acot.acutn) + "-" + string(acot.acotnseq).
        /*END-BLOCK:order-demands*/
        end.
      end.
    end.
  end.

END PROCEDURE. /* p-CheckSlit */


PROCEDURE p-fbrowseleave:
  /*------------------------------------------------------------------------------
      Field: v-tbrowse
      Event: ROW-LEAVE
  --------------------------------------------------------------------------------
    Purpose:
      Notes:
    Created: 08/03/10 Alex Leenstra
  ------------------------------------------------------------------------------*/
  
  /*message 'hello from p-fbrowseleave in acotbmeas2.p at ' string(time,"hh:mm:ss") view-as alert-box warning.*/
  
  define variable h-fbrowse as handle no-undo.
  define variable h-query   as handle no-undo.
  define variable h-buffer  as handle no-undo.
  define variable h-column  as handle no-undo.
  define variable h-field   as handle no-undo.
  
  define variable v-num-col as inte   no-undo.
  define variable v-bufcnt  as inte   no-undo.
 
  assign
    h-fbrowse = f-handle('v-fbrowse')
    h-query   = h-fbrowse:query
    h-buffer  = h-query:get-buffer-handle(1)
    h-field   = h-buffer:buffer-field('acotnseq').
  if h-fbrowse:current-row-modified then
  do:
    repeat v-num-col = 1 to h-fbrowse:num-columns:  /* Walk through the columns */
      assign 
        h-column = h-fbrowse:get-browse-column(v-num-col) no-error.
      if h-column:modified /* Is this column modified ? */ then
      do:
        assign
          h-field           = h-column:buffer-field
          h-column:modified = false no-error.
        do transaction:
          h-query:get-current(exclusive-lock) no-error.
          if h-field ne ? then
            assign h-field:buffer-value = h-column:screen-value no-error.
          repeat v-bufcnt = 1 to h-query:num-buffers: /* v2.04 h-query:get-current(exclusive-lock) locked all of the buffers in the query */ 
            h-buffer = h-query:get-buffer-handle (v-bufcnt). 
            h-buffer:buffer-release() no-error. /* v2.04 */
          end. /*repeat*/
        end. /* transaction */
      end. /* modified */
    end. /* repeat */
  end. /* current-row-modified */

END PROCEDURE. /* p-fbrowseleave */


PROCEDURE p-tbrowseleave:
  /*------------------------------------------------------------------------------
      Field: v-tbrowse
      Event: ROW-LEAVE
  --------------------------------------------------------------------------------
    Purpose:
      Notes:
    Created: 08/03/10 Alex Leenstra
  ------------------------------------------------------------------------------*/
  
  /*message 'hello from p-tbrowseleave in acotbmeas2.p at ' string(time,"hh:mm:ss") view-as alert-box warning.*/
  
  define variable h-tbrowse as handle no-undo.
  define variable h-query   as handle no-undo.
  define variable h-buffer  as handle no-undo.
  define variable h-column  as handle no-undo.
  define variable h-field   as handle no-undo.
  
  define variable v-num-col as inte   no-undo.
  define variable v-bufcnt  as inte   no-undo.
 
  assign
    h-tbrowse = f-handle('v-tbrowse')
    h-query   = h-tbrowse:query
    h-buffer  = h-query:get-buffer-handle(1)
    h-field   = h-buffer:buffer-field('acotnseq').

  if h-tbrowse:current-row-modified then
  do:
    repeat v-num-col = 1 to h-tbrowse:num-columns:  /* Walk through the columns */
      assign 
        h-column = h-tbrowse:get-browse-column(v-num-col) no-error.
      if h-column:modified /* Is this column modified ? */ then
      do:
        assign
          h-field           = h-column:buffer-field
          h-column:modified = false no-error.
        do transaction:
          h-query:get-current(exclusive-lock) no-error.
          if h-field ne ? then
            assign h-field:buffer-value = h-column:screen-value no-error.
          repeat v-bufcnt = 1 to h-query:num-buffers: /* v2.04 h-query:get-current(exclusive-lock) locked all of the buffers in the query */ 
            h-buffer = h-query:get-buffer-handle (v-bufcnt). 
            h-buffer:buffer-release() no-error. /* v2.04 */
          end. /*repeat*/
        end. /* transaction */
      end. /* modified */
    end. /* repeat */
  end. /* current-row-modified */

END PROCEDURE. /* p-rowleave */


PROCEDURE p-firsttab:
  /*------------------------------------------------------------------------------
      Event: TAB-COMPLETE
  --------------------------------------------------------------------------------
    Purpose:
      Notes:
    Created: 08/03/31 Alex Leenstra
  ------------------------------------------------------------------------------*/
  
  /*message 'hello from p-firsttab in acotbmeas2.p at ' string(time,"hh:mm:ss") view-as alert-box warning.*/

  find first acut no-lock where rowid(acut) = f-getrowid('acut') no-error.

  if avail acut then 
  do:
  
    for each acot no-lock where acot.xlevc = f-xlevc('acot')
      and acot.atasn = acut.atasn
      and acot.acutn = acut.acutn:
      p-tt:default-buffer-handle:buffer-create.
      p-tt:default-buffer-handle:BUFFER-COPY(buffer acot:handle).
    end.
  
  end.
  else
    message 'hell, acut is not found !!!'.

END PROCEDURE. /* p-firsttab */


PROCEDURE p-cancel:
  /*------------------------------------------------------------------------------
      Event: Before-cancel
  --------------------------------------------------------------------------------
    Purpose:
      Notes:
    Created: 08/03/31 Alex Leenstra
  ------------------------------------------------------------------------------*/
  
  /*message 'hello from p-cancel acotbmeas2.p at ' string(time,"hh:mm:ss") view-as alert-box warning.*/

  run p-disable-browse.
  run p-tabhide.
  run p-tabshow.

  assign 
    p-action = 's-qryreopen'.

END PROCEDURE. /* p-cancel */


PROCEDURE p-valchange-gknic:
  /*------------------------------------------------------------------------------
      Event: leave
  --------------------------------------------------------------------------------
    Purpose:
      Notes:
    Created: 07/12/07 Kalash
  ------------------------------------------------------------------------------*/
  
  /*message 'hello from p-valchange-gknic in acotbmeas2.p at ' string(time,"hh:mm:ss") view-as alert-box warning.*/
  
  define variable v-gknmn as inte no-undo.

  find first gknm no-lock where gknm.gknic = f-getvalue('gknic') and gknm.xstac = '100' no-error.

  if available gknm then
  do:
    assign 
      v-gknmn = gknm.gknmn.
  end.
  assign 
    p-result = 'gknmn' + chr(1) + string(v-gknmn).

END PROCEDURE. /* p-valchange-gknic */


PROCEDURE p-refreshmeasure:
  /*------------------------------------------------------------------------------
      Event: program start
  --------------------------------------------------------------------------------
    Purpose: To get the change done in task mgt planner & operator in one another.
             Here the navigation panel is unsuitable to add,
             so worked with a button.
      Notes:
    Created: 8/30/2008 Kamal Raj Subedi
  ------------------------------------------------------------------------------*/
  
  /*message 'hello from p-refreshmeasure in acotbmeas2.p at ' string(time,"hh:mm:ss") view-as alert-box warning.*/
  
  assign 
    p-action = 's-refresh'.

END PROCEDURE. /* p-refreshmeasure */


PROCEDURE p-validate-date:
  /*------------------------------------------------------------------------------
       File: acut (Kappen)
      Field: acutdbegindate (BeginDate)
      Event: LEAVE
  --------------------------------------------------------------------------------
    Purpose:
      Notes:
    Created: 09/08/26 Sudhir Shakya
  ------------------------------------------------------------------------------*/
  
  /*message 'hello from p-validate-date in acotbmeas2.p at ' string(time,"hh:mm:ss") view-as alert-box warning.*/

  date (p-value) no-error.
  if error-status:error then assign p-error = 'invaliddate'.

END PROCEDURE. /* p-validate-date */


PROCEDURE p-aftercommit2:
  /*------------------------------------------------------------------------------
      Event: AFTER-COMMIT
  --------------------------------------------------------------------------------
    Purpose: this assigns the values of start and end of date/time of a task
             when a cut/slit in that task is started or finished.
      Notes:
    Created: 09/09/07 gaurab poudel
  ------------------------------------------------------------------------------*/
  
  /*message 'hello from p-aftercommit2 in acotbmeas2.p at ' string(time,"hh:mm:ss") view-as alert-box warning.*/
  
  find first acut no-lock where rowid(acut) = f-getrowid('acut') no-error.
  
  if available acut then
  do:
    find first atas exclusive-lock where atas.xlevc = f-xlevc('atask') and atas.atasn = acut.atasn no-error.
    do preselect 
      each acut no-lock where acut.xlevc = f-xlevc('acut')
      and acut.atasn = atas.atasn
      by acut.acutdbegindate by acut.acutnstarttime.
      find first acut no-error.
      assign 
        atas.atasnstarttime = acut.acutnstarttime.  /*gp: start time of the first started cut/slit is the start time of that TASK */
    end.  /* do preselect */
 
    do preselect 
      each acut no-lock where acut.xlevc = f-xlevc('acut')
      and acut.atasn = atas.atasn
      by acut.acutdenddate by acut.acutnendtime.
      find last acut no-error.
      assign 
        atas.atasdenddate = acut.acutdenddate       /*gp: end time of the last finished cut/slit is the end time of the TASK */
        atas.atasnendtime = acut.acutnendtime.
    end.  /* do preselect */
  
    release atas.
  end.  /* if available acut */

  find first acut exclusive-lock where rowid(acut) = f-getrowid('acut') no-error.
  if available acut then
  do: 
    if acut.acutnendtime = 0 /*00:00*/ then assign acut.gsftc = 'M'.           
    if acut.acutnendtime GT 0 /*00:00*/ and acut.acutnendtime LE 22500 /*06:15*/ then assign acut.gsftc = 'N'. 
    else if acut.acutnendtime GT 22500 /*06:15*/ and acut.acutnendtime LE 54000 /*15:00*/ then assign acut.gsftc = 'O'.
      else if acut.acutnendtime GT 54000 /*15:00*/ and acut.acutnendtime LE 86400 /*24:00*/ then assign acut.gsftc = 'M'. 
    release acut.
  end. /* if available acut */
 
END PROCEDURE. /* p-aftercommit2 */


PROCEDURE p-restore:
  /*------------------------------------------------------------------------------
    Purpose: This will restore the temp-table with the original values after an
             update is canceled
      Notes:
    Created: 09/09/07 Alex Leenstra
  ------------------------------------------------------------------------------*/
  
  /*message 'hello from p-restore in acotbmeas2.p at ' string(time,"hh:mm:ss") view-as alert-box warning.*/

  define variable h-fbrowse as handle no-undo.
  define variable h-tbrowse as handle no-undo.
  define variable h-column  as handle no-undo.
  define variable h-query   as handle no-undo.
  define variable h-fbuffer as handle no-undo.
  define variable h-tbuffer as handle no-undo.
  define variable h-field1  as handle no-undo.
  define variable h-change  as handle no-undo.
  define variable v-fields  as inte   no-undo.
  define variable v-prepare as char   no-undo.

  assign 
    h-fbrowse = f-handle('v-fbrowse')
    h-tbrowse = f-handle('v-tbrowse').

  assign 
    h-query   = h-fbrowse:query
    h-fbuffer = h-query:get-buffer-handle(1) no-error.

  find first acut no-lock where rowid(acut) = f-getrowid('acut') no-error.
  create buffer h-tbuffer for table 'acot'.
  v-prepare = 'where acot.xlevc    = ' + quoter(f-xlevc('acot')) +
    '  and acot.atasn    = ' + string(acut.atasn) +
    '  and acot.acutn    = ' + string(acut.acutn) +
    '  and acot.acotnseq = '.

  /* This is the opposite of the commit find the original record and store */
  /* v2.04 it in the temp-table no exclusive-lcok need to update temp-table */

  h-query:get-first(no-lock).
  repeat while h-fbuffer:avail :
    h-query:get-current(no-lock).  /* v2.04 */
    h-field1 = h-fbuffer:buffer-field ('acotnseq').

    v-ok = h-tbuffer:find-unique (v-prepare + string (h-field1:buffer-value), no-lock) no-error.

    h-fbuffer:buffer-copy (h-tbuffer:handle).
    h-fbuffer:buffer-release. /* v2.02 release the copied record */ 
 
    h-query:get-next (no-lock).
  end.

  /* show the new value */

  apply 'home' to  h-fbrowse.
  apply 'home' to  h-tbrowse.

END PROCEDURE. /* p-restore*/

/*---FUNCTIONS---------------------------------------------------------------------*/

FUNCTION f-fields returns char
  (input p-grecc as char ) :

  define variable v-cnt1       as inte   no-undo.
  define variable v-cnt2       as inte   no-undo.

  define variable h-grecipe    as handle no-undo.
  define variable h-acot       as handle no-undo.

  define variable h-grec-field as handle no-undo.
  define variable h-acot-field as handle no-undo.

  define variable v-return     as char   no-undo.
  define variable v-field      as handle no-undo.

  create buffer h-grecipe for table 'grecipe'.
  create buffer h-acot    for table 'acot'.

  empty temp-table tt-fields.

  v-ok = h-grecipe:find-unique('where grecipe.xlevc = ' + quoter(f-xlevc('ggrec')) + '  and grecipe.grecc = ' + quoter(p-grecc) ,no-lock ) no-error.

  repeat v-cnt1 = 1 to h-grecipe:num-fields:
    assign 
      h-grec-field = h-grecipe:buffer-field(v-cnt1) no-error.
    if lookup(h-grec-field:name,'grecllength,greclweight') GT 0 then next.
    if h-grecipe:avail and  valid-handle(h-grec-field) and h-grec-field:data-type = 'logical'
      and h-grec-field:buffer-value = 'yes' then
    do:
      repeat v-cnt2 = 1 to num-entries('a,n,t'):
        v-field = h-acot:buffer-field('acot' + entry(v-cnt2,'a,n,t') + substring(h-grec-field:name,6)) no-error.
        if valid-handle(v-field) then
        do:
          create tt-fields.
          assign 
            tt-fields.v-field = v-field:name.
        end.
      end. /*repeat*/
    end.
  end. /*repeat*/

  assign 
    v-return = ''.
  for each tt-fields :
    assign 
      v-return = v-return + min(v-return,',') + tt-fields.v-field.
  end.

  /* 2.05 cleaning up handles */
    
  if valid-handle(v-field) then delete widget v-field.
  if valid-handle(h-grec-field) then delete widget h-grec-field.
  if valid-handle(h-acot-field) then delete widget h-acot-field.
  if valid-handle(h-grecipe) then delete widget h-grecipe.
  if valid-handle(h-acot) then delete widget h-acot.

  return v-return.

END FUNCTION.

procedure Ipsetting1:
  /*------------------------------------------------------------------------------
     Event:                                                   
 --------------------------------------------------------------------------------
   Purpose: To connect the laser device through ip 192.168.196.18.                                                                    
     Notes:                                                                      
   Created: 14/08/2015 amity timalsina SR:EMM6-0022 implement the laser api value to the acot table.                                            
 ------------------------------------------------------------------------------*/
  define variable LJVWrapper     as com-handle.    /* amity:SR:EMM6-0022*/
  define variable sendCommand    as character  no-undo.
  define variable portNo         as character  no-undo. 
  define variable v-errormessage as character  no-undo.
  
  define output parameter v-result       as character  no-undo.  
  define output parameter Rc             as character  no-undo.  
  define output parameter Ipaddress      as character  no-undo.
 

  CREATE "LJV_Dllconsolesample.Server" LJVWrapper.  /* amity:SR:EMM6-0022 programm identifier that initialize the new instances with specified progid*/
  find first  xsetting where xsetting.xsetc = "IPSetting1" no-lock no-error.
  assign 
    ipaddress = entry(1,xsetting.xsett)
    portNo    = entry(2,xsetting.xsett)
    . 
  ASSIGN 
    Rc             = LJVWrapper:EthernetOpen(ipaddress,portNo)   
    sendCommand    = LJVWrapper:GetMeasurementValue_value()
    v-result       = LJVWrapper:GetLastError()
    v-errormessage = SUBSTRING(v-result,71,12)
    v-result       = SUBSTRING (v-result,1,218). 
     
end procedure. /* Ipsetting1*/

procedure Ipsetting2:
  /*------------------------------------------------------------------------------
      Event:                                                   
  --------------------------------------------------------------------------------
    Purpose: To connect the laser device through ip 192.168.196.19.                                                                    
      Notes:                                                                      
    Created: 14/08/2015 amity timalsina SR:EMM6-0022 implement the laser api value to the acot table.                                            
  ------------------------------------------------------------------------------*/
  define variable LJVWrapper     as com-handle.    /* amity:SR:EMM6-0022*/
  define variable sendCommand    as character  no-undo.
  define variable portNo         as character  no-undo. 
  define variable v-errormessage as character  no-undo.
  
  define output parameter v-result       as character  no-undo.  
  define output parameter Rc             as character  no-undo.  
  define output parameter Ipaddress      as character  no-undo. 

  CREATE "LJV_Dllconsolesample.Server" LJVWrapper.  /* amity:SR:EMM6-0022 programm identifier that initialize the new instances with specified progid*/
  find first  xsetting where xsetting.xsetc = "IPSetting2" no-lock no-error.
  assign 
    ipaddress = entry(1,xsetting.xsett)
    portNo    = entry(2,xsetting.xsett)
    . 
  ASSIGN 
    Rc             = LJVWrapper:EthernetOpen(ipaddress,portNo)   
    sendCommand    = LJVWrapper:GetMeasurementValue_value()
    v-result       = LJVWrapper:GetLastError()
    v-errormessage = SUBSTRING(v-result,71,12)
    v-result       = SUBSTRING (v-result,1,218).  
     
end procedure.  /* Ipsetting2*/

procedure p-fetch1:
  /*------------------------------------------------------------------------------
      Event: PROGRAM-START                                                        
  --------------------------------------------------------------------------------
    Purpose:  Begin of work side laser 1                                                                    
      Notes:                                                                      
    Created: 14/10/02 Eric Clarisse  
    updated: 13/08/2015 amity timalsina, SR:EMM6-0022 implement the laser api value to the acot table.                                             
  ------------------------------------------------------------------------------*/ 
  define variable vCotno         as integer   no-undo.   
  define variable Rc             as character no-undo.
  define variable v-result       as character no-undo.
  define variable v-start        as integer   no-undo.
  define variable v-value        as character no-undo.
  define variable v-thickness    as character no-undo.
  define variable v-waving       as character no-undo.
  define variable v-burr         as character no-undo.
  define variable v-camber       as character no-undo.  
  define variable v-errormessage as character no-undo.
  define variable Ipaddress      as character no-undo.  
   
  run Ipsetting1 (output v-result, output Rc, output Ipaddress ). /*amity  emm6-0022  calling Ipsetting1 */
  
  if Rc = "0" and  not v-result MATCHES "*Alarm*" THEN 
  DO:  /* amity:SR:EMM6-0022 to take the required value using index*/             
    DO WHILE INDEX (v-result,"_GO_") > 0:      
      v-start     = INDEX (v-result,"_GO_").
      v-value     = v-value + SUBSTRING(v-result,(v-start + 7),6) + ";".
      v-result    = SUBSTRING(v-result,(v-start + 6)).
    END. /* DO WHILE */
    assign 
      v-value = replace(v-value,',','.').
    assign 
      v-thickness = ENTRY(1,v-value)
      v-waving    = ENTRY(2,v-value)
      v-burr      = ENTRY(3,v-value)
      v-camber    = ENTRY(4,v-value)
      .
 
    find first acut no-lock where rowid(acut) = f-getrowid('acut') no-error.
    find first acot no-lock where rowid(acot) = p-rowid no-error.      
    assign 
      vCotno = integer(f-get-xsest('t-acotn')).
         
    for first acot exclusive-lock where acot.xlevc = f-xlevc('acot')
      and acot.atasn = acut.atasn
      and acot.acutn = acut.acutn
      and acot.acotnslitno = vCotno:
      assign
        acot.acotathick-ws-bgn   = if v-thickness begins "0 " or v-thickness begins "-" then 0.000 else decimal(v-thickness)
        acot.acotaburr-ws-bgn    = if v-burr begins "0 " or v-burr begins "-"  then 0.000 else decimal(v-burr) 
        acot.acotawavehgt-ws-bgn = if v-waving begins "0 " or v-waving begins "-" then 0.000 else decimal(v-waving) 
        acot.acotacamber-bgn     = if v-camber begins "0 " or v-camber begins "-" then 0.00 else decimal(v-camber)
        .
    end.            
    run p-disable-browse.
    run p-tabhide.
    run p-tabshow.      
    run p-restore. /* amity:SR:EMM6-0022 show the correct fields in the browsers */     
    assign 
      p-action = 's-qryreopen'.
    run ipCheckSlits.    
    if v-BizError GT '' then
      assign p-error = 'def-warn' + chr(1)
            + 'Please carefully read BLOCKS and WARNS and act accordingly.' 
            + chr(13) + v-BizError 
            + CHR(13) + chr(13) + 'Incase BLOCK mentioned you will be blocked when trying to set cut to measured (350).'
            + chr(13) + chr(13) + 'When bizrules unclear please take note of code between []'.
  end. /* amity: end of do v-errormessage <> "Alarm value" and Rc = "0" */
  else
    message "Wrong input vlaue or Ip" ipaddress "is Offline please check ...."
      view-as alert-box.

END PROCEDURE. /* p-fetch1 */

procedure p-fetch2:
  /*------------------------------------------------------------------------------
      Event: PROGRAM-START                                                        
  --------------------------------------------------------------------------------
    Purpose: end of work side  laser 1                                                                    
      Notes:                                                                      
    Created: 14/10/02 Eric Clarisse   
    updated: 14/08/2015 amity timalsina SR:EMM6-0022 implement the laser api value to the acot table.                                            
  ------------------------------------------------------------------------------*/
  define variable vCotno         as integer   no-undo. 
  define variable Rc             as character no-undo.
  define variable v-result       as character no-undo.
  define variable v-start        as integer   no-undo.
  define variable v-value        as character no-undo.
  define variable v-thickness    as character no-undo.
  define variable v-waving       as character no-undo.
  define variable v-burr         as character no-undo.
  define variable v-camber       as character no-undo. 
  define variable v-errormessage as character no-undo.
  define variable Ipaddress      as character no-undo.
  
  run Ipsetting1 (output v-result, output Rc, output Ipaddress ). /*amity  emm6-0022  calling Ipsetting1 */
  
  IF  not v-result  matches "*Alarm*" and Rc = "0" THEN  /* amit: SR:EMM6-0022 to check error */
  DO:             
    DO WHILE INDEX (v-result,"_GO_") > 0:
      v-start     = INDEX (v-result,"_GO_").
      v-value     = v-value + SUBSTRING(v-result,(v-start + 7),6) + ";".
      v-result    = SUBSTRING(v-result,(v-start + 6)).
    END.
   
    assign 
      v-value = replace(v-value,',','.').
    ASSIGN
      v-thickness = ENTRY(1,v-value,';')
      v-waving    = ENTRY(2,v-value,';')
      v-burr      = ENTRY(3,v-value,';')
      v-camber    = ENTRY(4,v-value,';')
      .  
    find first acut no-lock where rowid(acut) = f-getrowid('acut') no-error.
    find first acot no-lock where rowid(acot) = p-rowid no-error.
  
    assign 
      vCotno = integer(f-get-xsest('t-acotn')).

    for first acot exclusive-lock where acot.xlevc = f-xlevc('acot')
      and acot.atasn = acut.atasn
      and acot.acutn = acut.acutn
      and acot.acotnslitno = vCotno:
      assign
        acot.acotathick-ws-end   = if v-thickness begins "0 " or v-thickness begins "-" then 0.000 else decimal(v-thickness)
        acot.acotaburr-ws-end    = if v-burr begins "0 " or v-burr begins "-" then 0.000 else decimal(v-burr)
        acot.acotawavehgt-ws-end = if v-waving begins "0 " or v-waving begins "-" then 0.000 else decimal(v-waving)
        acot.acotacamber-end     = if v-camber begins "0 " or v-camber begins "-" then 0.00 else decimal(v-camber)
        .
    end.  
    run p-disable-browse.
    run p-tabhide.
    run p-tabshow.  
    run p-restore. /*amity:SR:EMM6-0022 show the correct fields in the browsers*/ 
    assign 
      p-action = 's-qryreopen'.
    run ipCheckSlits.

    if v-BizError GT '' then
      assign p-error = 'def-warn' + chr(1)
      + 'Please carefully read BLOCKS and WARNS and act accordingly.' 
      + chr(13) + v-BizError 
      + CHR(13) + chr(13) + 'Incase BLOCK mentioned you will be blocked when trying to set cut to measured (350).'
      + chr(13) + chr(13) + 'When bizrules unclear please take note of code between []'.
  end. /* amity: end of do v-errormessage <> "Alarm value" and Rc = "0" */
  else
    message "Wrong input vlaue or Ip " ipaddress " is Offline please check ...."
      view-as alert-box.
END PROCEDURE. /* p-fetch */

procedure p-fetch3:
  /*------------------------------------------------------------------------------
      Event: PROGRAM-START                                                        
  --------------------------------------------------------------------------------
    Purpose:  begin of drive side laser 1                                                                     
      Notes:                                                                      
    Created: 14/10/02 Eric Clarisse  
    updated: 13/08/2015 amity timalsina, SR:EMM6-0022 implement the laser api value to the acot table.                                               
  ------------------------------------------------------------------------------*/  
  define variable vCotno         as integer   no-undo.
  define variable Rc             as character no-undo.
  define variable v-result       as character no-undo.
  define variable v-start        as integer   no-undo.
  define variable v-value        as character no-undo.
  define variable v-thickness    as character no-undo.
  define variable v-waving       as character no-undo.
  define variable v-burr         as character no-undo.
  define variable v-camber       as character no-undo. 
  define variable v-errormessage as character no-undo.
  define variable Ipaddress      as character no-undo.
 
  run Ipsetting1 (output v-result, output Rc, output Ipaddress ). /*amity  emm6-0022  calling Ipsetting1 */

  if Rc = "0" and  not v-result MATCHES "*Alarm*" THEN 
  DO:  /* amity:SR:EMM6-0022 to take the required value using index*/             
    DO WHILE INDEX (v-result,"_GO_") > 0:      
      v-start     = INDEX (v-result,"_GO_").
      v-value     = v-value + SUBSTRING(v-result,(v-start + 7),6) + ";".
      v-result    = SUBSTRING(v-result,(v-start + 6)).
    END. /* DO WHILE */
    assign 
      v-value = replace(v-value,',','.').
    assign 
      v-thickness = ENTRY(1,v-value,';')
      v-waving    = ENTRY(2,v-value,';')
      v-burr      = ENTRY(3,v-value,';')
      v-camber    = ENTRY(4,v-value,';')
      .
    find first acut no-lock where rowid(acut) = f-getrowid('acut') no-error.
    find first acot no-lock where rowid(acot) = p-rowid no-error.
  
    assign 
      vCotno = integer(f-get-xsest('t-acotn')).

    for first acot exclusive-lock where acot.xlevc = f-xlevc('acot')
      and acot.atasn = acut.atasn
      and acot.acutn = acut.acutn
      and acot.acotnslitno = vCotno:
      assign
        acot.acotathick-ds-bgn   = if v-thickness begins "0 " or v-thickness begins "-" then 0.000 else decimal(v-thickness)
        acot.acotaburr-ds-bgn    = if v-burr begins "0 " or v-burr begins "-" then 0.000 else decimal(v-burr)        
        acot.acotawavehgt-ds-bgn = if v-waving begins "0 " or v-waving begins "-" then 0.000 else decimal(v-waving)       
        .     
    end.  
    run p-disable-browse.
    run p-tabhide.
    run p-tabshow.  
    run p-restore. /* amity:SR:EMM6-0022 show the correct fields in the browsers*/ 
    assign 
      p-action = 's-qryreopen'.
    run ipCheckSlits.
    if v-BizError GT '' then
      assign p-error = 'def-warn' + chr(1)
      + 'Please carefully read BLOCKS and WARNS and act accordingly.' 
      + chr(13) + v-BizError 
      + CHR(13) + chr(13) + 'Incase BLOCK mentioned you will be blocked when trying to set cut to measured (350).'
      + chr(13) + chr(13) + 'When bizrules unclear please take note of code between []'.
  end. /* amity: end of do v-errormessage <> "Alarm value" and Rc = "0" */
  else
    message "Wrong input vlaue or Ip" ipaddress "is Offline please check ...."
      view-as alert-box.
END PROCEDURE. /* p-fetch */

procedure p-fetch4:
  /*------------------------------------------------------------------------------
      Event: PROGRAM-START                                                        
  --------------------------------------------------------------------------------
    Purpose:  end of drive side laser 1                                                                    
      Notes:                                                                      
    Created: 14/10/02 Eric Clarisse  
    updated: 13/08/2015 amity timalsina, SR:EMM6-0022 implement the laser api value to the acot table.                                               
  ------------------------------------------------------------------------------*/ 
  define variable vCotno         as integer   no-undo.  
  define variable Rc             as character no-undo.
  define variable v-result       as character no-undo.
  define variable v-start        as integer   no-undo.
  define variable v-value        as character no-undo.
  define variable v-thickness    as character no-undo.
  define variable v-waving       as character no-undo.
  define variable v-burr         as character no-undo.
  define variable v-camber       as character no-undo.  
  define variable v-errormessage as character no-undo.
  define variable Ipaddress      as character no-undo.
    
  run Ipsetting1 (output v-result, output Rc, output Ipaddress ). /*amity  emm6-0022  calling Ipsetting1 */

  IF  not v-result  matches "*Alarm*" and Rc = "0" THEN  /* amit: SR:EMM6-0022 to check error */
  DO:             
    DO WHILE INDEX (v-result,"_GO_") > 0:
      v-start     = INDEX (v-result,"_GO_").
      v-value     = v-value + SUBSTRING(v-result,(v-start + 7),6) + ";".
      v-result    = SUBSTRING(v-result,(v-start + 6)).
    END.
    assign 
      v-value = replace(v-value,',','.').
    ASSIGN
      v-thickness = ENTRY(1,v-value,';')
      v-waving    = ENTRY(2,v-value,';')
      v-burr      = ENTRY(3,v-value,';')
      v-camber    = ENTRY(4,v-value,';')
      .  
    find first acut no-lock where rowid(acut) = f-getrowid('acut') no-error.
    find first acot no-lock where rowid(acot) = p-rowid no-error.
  
    assign 
      vCotno = integer(f-get-xsest('t-acotn')).

    for first acot exclusive-lock where acot.xlevc = f-xlevc('acot')
      and acot.atasn = acut.atasn
      and acot.acutn = acut.acutn
      and acot.acotnslitno = vCotno:
      assign

        acot.acotathick-ds-end   = if v-thickness begins "0 " or v-thickness begins "-" then 0.000 else decimal(v-thickness)
        acot.acotaburr-ds-end    = if v-burr begins "0 " or v-burr begins "-"then 0.000 else decimal(v-burr)
        acot.acotawavehgt-ds-end = if v-waving begins "0 " or v-waving begins "-" then 0.000 else decimal(v-waving)              
        .    
    end.  
    run p-disable-browse.
    run p-tabhide.
    run p-tabshow.  
    run p-restore. /*amity: SR:EMM6-0022 show the correct fields in the browsers */ 
    assign 
      p-action = 's-qryreopen'.
    run ipCheckSlits.  
    if v-BizError GT '' then
      assign p-error = 'def-warn' + chr(1)
      + 'Please carefully read BLOCKS and WARNS and act accordingly.' 
      + chr(13) + v-BizError 
      + CHR(13) + chr(13) + 'Incase BLOCK mentioned you will be blocked when trying to set cut to measured (350).'
      + chr(13) + chr(13) + 'When bizrules unclear please take note of code between []'.
  end. /* amity: end of do v-errormessage <> "Alarm value" and Rc = "0" */
  else
    message "Wrong input vlaue or Ip" ipaddress "is Offline please check ...."
      view-as alert-box.
END PROCEDURE. /* p-fetch */

procedure p-fetch5:
  /*------------------------------------------------------------------------------
      Event: PROGRAM-START                                                        
  --------------------------------------------------------------------------------
    Purpose: Begin of work side laser 2                                                                      
      Notes:                                                                      
    Created: 13/08/2015 amity timalsina, SR:EMM6-0022 implement the laser api value to the acot table.                                               
  ------------------------------------------------------------------------------*/ 
  define variable vCotno         as integer   no-undo. 
  define variable Rc             as character no-undo.
  define variable v-result       as character no-undo.
  define variable v-start        as integer   no-undo.
  define variable v-value        as character no-undo.
  define variable v-thickness    as character no-undo.
  define variable v-waving       as character no-undo.
  define variable v-burr         as character no-undo.
  define variable v-camber       as character no-undo. 
  define variable v-errormessage as character no-undo.
  define variable Ipaddress      as character no-undo.  
  
  run Ipsetting2 (output v-result, output Rc, output Ipaddress ). /*amity  emm6-0022  calling Ipsetting2 */
 
  IF  not v-result  matches "*Alarm*" and Rc = "0" THEN  /* amit: SR:EMM6-0022 to check error */
  DO:             
    DO WHILE INDEX (v-result,"_GO_") > 0:
      v-start     = INDEX (v-result,"_GO_").
      v-value     = v-value + SUBSTRING(v-result,(v-start + 7),6) + ";".
      v-result    = SUBSTRING(v-result,(v-start + 6)).
    END.
    assign 
      v-value = replace(v-value,',','.').
    ASSIGN
      v-thickness = ENTRY(1,v-value,';')
      v-waving    = ENTRY(2,v-value,';')
      v-burr      = ENTRY(3,v-value,';')
      v-camber    = ENTRY(4,v-value,';')
      .   
    find first acut no-lock where rowid(acut) = f-getrowid('acut') no-error.
    find first acot no-lock where rowid(acot) = p-rowid no-error.
  
    assign 
      vCotno = integer(f-get-xsest('t-acotn')).

    for first acot exclusive-lock where acot.xlevc = f-xlevc('acot')
      and acot.atasn = acut.atasn
      and acot.acutn = acut.acutn
      and acot.acotnslitno = vCotno:
      assign
        acot.acotathick-ws-bgn   = if v-thickness begins "0 " or v-thickness begins "-" then 0.000 else decimal(v-thickness)
        acot.acotaburr-ws-bgn    = if v-burr begins "0 " or v-burr begins "-"  then 0.000 else decimal(v-burr) 
        acot.acotawavehgt-ws-bgn = if v-waving begins "0 " or v-waving begins "-" then 0.000 else decimal(v-waving) 
        acot.acotacamber-bgn     = if v-camber begins "0 " or v-camber begins "-" then 0.00 else decimal(v-camber)
        .    
    end.  
    run p-disable-browse.
    run p-tabhide.
    run p-tabshow.  
    run p-restore. /*amity: SR:EMM6-0022 show the correct fields in the browsers */ 
    assign 
      p-action = 's-qryreopen'.
    run ipCheckSlits.  
    if v-BizError GT '' then
      assign p-error = 'def-warn' + chr(1)
      + 'Please carefully read BLOCKS and WARNS and act accordingly.' 
      + chr(13) + v-BizError 
      + CHR(13) + chr(13) + 'Incase BLOCK mentioned you will be blocked when trying to set cut to measured (350).'
      + chr(13) + chr(13) + 'When bizrules unclear please take note of code between []'.
  end. /* amity: end of do v-errormessage <> "Alarm value" and Rc = "0" */
  else
    message "Wrong input vlaue or Ip" ipaddress "is Offline please check ...."
      view-as alert-box.

END PROCEDURE. /* p-fetch */

procedure p-fetch6:
  /*------------------------------------------------------------------------------
      Event: PROGRAM-START                                                        
  --------------------------------------------------------------------------------
    Purpose:  End of work side laser 2                                                                    
      Notes:                                                                   
   Created : 13/08/2015 amity timalsina, SR:EMM6-0022 implement the laser api value to the acot table.                                               
  ------------------------------------------------------------------------------*/
 
  define variable vCotno         as integer    no-undo.
  define variable LJVWrapper     as com-handle.
  define variable sendCommand    as character  no-undo.
  define variable Rc             as character  no-undo.
  define variable v-result       as character  no-undo.
  define variable v-start        as integer    no-undo.
  define variable v-value        as character  no-undo.
  define variable v-thickness    as character  no-undo.
  define variable v-waving       as character  no-undo.
  define variable v-burr         as character  no-undo.
  define variable v-camber       as character  no-undo.
  define variable v-errormessage as character  no-undo.
  define variable Ipaddress      as character  no-undo. 
  
  run Ipsetting2 (output v-result, output Rc, output Ipaddress ). /*amity  emm6-0022  calling Ipsetting2 */
  
  IF  not v-result  matches "*Alarm*" and Rc = "0" THEN  /* amit: SR:EMM6-0022 to check error */
  DO:             
    DO WHILE INDEX (v-result,"_GO_") > 0:
      v-start     = INDEX (v-result,"_GO_").
      v-value     = v-value + SUBSTRING(v-result,(v-start + 7),6) + ";".
      v-result    = SUBSTRING(v-result,(v-start + 6)).
    END.
    assign 
      v-value = replace(v-value,',','.'). 
    ASSIGN
      v-thickness = ENTRY(1,v-value,';')
      v-waving    = ENTRY(2,v-value,';')
      v-burr      = ENTRY(3,v-value,';')
      v-camber    = ENTRY(4,v-value,';')
      .
  
    find first acut no-lock where rowid(acut) = f-getrowid('acut') no-error.
    find first acot no-lock where rowid(acot) = p-rowid no-error.
  
    assign 
      vCotno = integer(f-get-xsest('t-acotn')).

    for first acot exclusive-lock where acot.xlevc = f-xlevc('acot')
      and acot.atasn = acut.atasn
      and acot.acutn = acut.acutn
      and acot.acotnslitno = vCotno:
      assign
        acot.acotathick-ws-end   = if v-thickness begins "0 " or v-thickness begins "-" then 0.000 else decimal(v-thickness)
        acot.acotaburr-ws-end    = if v-burr begins "0 " or v-burr begins "-" then 0.000 else decimal(v-burr)
        acot.acotawavehgt-ws-end = if v-waving begins "0 " or v-waving begins "-" then 0.000 else decimal(v-waving)
        acot.acotacamber-end     = if v-camber begins "0 " or v-camber begins "-" then 0.00 else decimal(v-camber)
        .    
    end.  
    run p-disable-browse.
    run p-tabhide.
    run p-tabshow.  
    run p-restore. /*amity: SR:EMM6-0022 show the correct fields in the browsers */ 
    assign 
      p-action = 's-qryreopen'.
    run ipCheckSlits.  
    if v-BizError GT '' then
      assign p-error = 'def-warn' + chr(1)
      + 'Please carefully read BLOCKS and WARNS and act accordingly.' 
      + chr(13) + v-BizError 
      + CHR(13) + chr(13) + 'Incase BLOCK mentioned you will be blocked when trying to set cut to measured (350).'
      + chr(13) + chr(13) + 'When bizrules unclear please take note of code between []'.
  end. /* amity: end of do v-errormessage <> "Alarm value" and Rc = "0" */
  else
    message "Wrong input vlaue or Ip" ipaddress "is Offline please check ...."
      view-as alert-box.
END PROCEDURE. /* p-fetch */

procedure p-fetch7:
  /*------------------------------------------------------------------------------
      Event: PROGRAM-START                                                        
  --------------------------------------------------------------------------------
    Purpose:   Begin of drive side laser 2                                                                  
      Notes:                                                                      
    Created:  13/08/2015 amity timalsina, SR:EMM6-0022 implement the laser api value to the acot table.                                               
  ------------------------------------------------------------------------------*/ 
  define variable vCotno         as integer   no-undo. 
  define variable Rc             as character no-undo.
  define variable v-result       as character no-undo.
  define variable v-start        as integer   no-undo.
  define variable v-value        as character no-undo.
  define variable v-thickness    as character no-undo.
  define variable v-waving       as character no-undo.
  define variable v-burr         as character no-undo.
  define variable v-camber       as character no-undo.
  define variable v-errormessage as character no-undo.
  define variable Ipaddress      as character no-undo.  
  
  run Ipsetting2 (output v-result, output Rc, output Ipaddress ).  /*amity  emm6-0022  calling Ipsetting2 */
  
  IF  not v-result  matches "*Alarm*" and Rc = "0" THEN  /* amit: SR:EMM6-0022 to check error */
  DO:             
    DO WHILE INDEX (v-result,"_GO_") > 0:
      v-start     = INDEX (v-result,"_GO_").
      v-value     = v-value + SUBSTRING(v-result,(v-start + 7),6) + ";".
      v-result    = SUBSTRING(v-result,(v-start + 6)).
    END.
    assign 
      v-value = replace(v-value,',','.'). 
    ASSIGN
      v-thickness = ENTRY(1,v-value,';')
      v-waving    = ENTRY(2,v-value,';')
      v-burr      = ENTRY(3,v-value,';')
      v-camber    = ENTRY(4,v-value,';')
      .
  
    find first acut no-lock where rowid(acut) = f-getrowid('acut') no-error.
    find first acot no-lock where rowid(acot) = p-rowid no-error.
  
    assign 
      vCotno = integer(f-get-xsest('t-acotn')).

    for first acot exclusive-lock where acot.xlevc = f-xlevc('acot')
      and acot.atasn = acut.atasn
      and acot.acutn = acut.acutn
      and acot.acotnslitno = vCotno:
      assign
        acot.acotathick-ds-bgn   = if v-thickness begins "0 " or v-thickness begins "-" then 0.000 else decimal(v-thickness)
        acot.acotaburr-ds-bgn    = if v-burr begins "0 " or v-burr begins "-" then 0.000 else decimal(v-burr)        
        acot.acotawavehgt-ds-bgn = if v-waving begins "0 " or v-waving begins "-" then 0.000 else decimal(v-waving)  
        .    
    end.  
    run p-disable-browse.
    run p-tabhide.
    run p-tabshow.  
    run p-restore. /*amity: SR:EMM6-0022 show the correct fields in the browsers */ 
    assign 
      p-action = 's-qryreopen'.
    run ipCheckSlits.  
    if v-BizError GT '' then
      assign p-error = 'def-warn' + chr(1)
      + 'Please carefully read BLOCKS and WARNS and act accordingly.' 
      + chr(13) + v-BizError 
      + CHR(13) + chr(13) + 'Incase BLOCK mentioned you will be blocked when trying to set cut to measured (350).'
      + chr(13) + chr(13) + 'When bizrules unclear please take note of code between []'.
  end. /* amity: end of do v-errormessage <> "Alarm value" and Rc = "0" */
  else
    message "Wrong input vlaue or Ip" ipaddress "is Offline please check ...."
      view-as alert-box.
END PROCEDURE. /* p-fetch */
procedure p-fetch8:
  /*------------------------------------------------------------------------------
      Event: PROGRAM-START                                                        
  --------------------------------------------------------------------------------
    Purpose:  End of Drive side laser 2.                                                                    
      Notes:                                                                      
    Created: 13/08/2015 amity timalsina, SR:EMM6-0022 implement the laser api value to the acot table.                                               
  ------------------------------------------------------------------------------*/ 
  define variable vCotno         as integer   no-undo. 
  define variable Rc             as character no-undo.
  define variable v-result       as character no-undo.
  define variable v-start        as integer   no-undo.
  define variable v-value        as character no-undo.
  define variable v-thickness    as character no-undo.
  define variable v-waving       as character no-undo.
  define variable v-burr         as character no-undo.
  define variable v-camber       as character no-undo.
  define variable v-errormessage as character no-undo.
  define variable Ipaddress      as character no-undo.
   
  run Ipsetting2 (output v-result, output Rc, output Ipaddress ). /*amity  emm6-0022  calling Ipsetting2 */

  IF  not v-result  matches "*Alarm*" and Rc = "0" THEN  /* amit: SR:EMM6-0022 to check error */
  DO:             
    DO WHILE INDEX (v-result,"_GO_") > 0:
      v-start     = INDEX (v-result,"_GO_").
      v-value     = v-value + SUBSTRING(v-result,(v-start + 7),6) + ";".
      v-result    = SUBSTRING(v-result,(v-start + 6)).
    END.
    assign 
      v-value = replace(v-value,',','.').  
    ASSIGN
      v-thickness = ENTRY(1,v-value,';')
      v-waving    = ENTRY(2,v-value,';')
      v-burr      = ENTRY(3,v-value,';')
      v-camber    = ENTRY(4,v-value,';')
      .
  
    find first acut no-lock where rowid(acut) = f-getrowid('acut') no-error.
    find first acot no-lock where rowid(acot) = p-rowid no-error.
  
    assign 
      vCotno = integer(f-get-xsest('t-acotn')).

    for first acot exclusive-lock where acot.xlevc = f-xlevc('acot')
      and acot.atasn = acut.atasn
      and acot.acutn = acut.acutn
      and acot.acotnslitno = vCotno:
      assign
        acot.acotathick-ds-end   = if v-thickness begins "0 " or v-thickness begins "-" then 0.000 else decimal(v-thickness)
        acot.acotaburr-ds-end    = if v-burr begins "0 " or v-burr begins "-"then 0.000 else decimal(v-burr)
        acot.acotawavehgt-ds-end = if v-waving begins "0 " or v-waving begins "-" then 0.000 else decimal(v-waving)                 
        .    
    end.  
    run p-disable-browse.
    run p-tabhide.
    run p-tabshow.  
    run p-restore. /*amity: SR:EMM6-0022 show the correct fields in the browsers */ 
    assign 
      p-action = 's-qryreopen'.
    run ipCheckSlits.  
    if v-BizError GT '' then
      assign p-error = 'def-warn' + chr(1)
      + 'Please carefully read BLOCKS and WARNS and act accordingly.' 
      + chr(13) + v-BizError 
      + CHR(13) + chr(13) + 'Incase BLOCK mentioned you will be blocked when trying to set cut to measured (350).'
      + chr(13) + chr(13) + 'When bizrules unclear please take note of code between []'.
  end. /* amity: end of do v-errormessage <> "Alarm value" and Rc = "0" */
  else
    message "Wrong input vlaue or Ip" ipaddress "is Offline please check ...."
      view-as alert-box.
END PROCEDURE. /* p-fetch */

PROCEDURE ipCheckSlits:
  for each acot no-lock where acot.xlevc = f-xlevc('acot')
    and acot.atasn = acut.atasn
    and acot.acutn = acut.acutn:   
    run p-CheckSlit(input rowid(acot)).
  end.
END PROCEDURE. /* ipCheckslits*/

PROCEDURE ipGetData:
  def input parameter iFname as char no-undo.
  def output parameter p1 as char no-undo.
  def output parameter p2 as char no-undo.
  def output parameter p3 as char no-undo.
  def output parameter p4 as char no-undo.
  def output parameter p5 as char no-undo.

  if search(iFname) EQ ? then message " @@ FILE NOT FOUND !" view-as alert-box error.
  else 
  do:
    input STREAM sFrom FROM VALUE(iFname).

    repeat: 
      import stream sFrom unformatted vLine no-error.
      n = n + 1.
      /*   disp vLine. */
      create tt.
      assign
        tt.linenr = n 
        tt.p1     = entry(1,vLine)
        tt.p2     = entry(2,vLine)
        tt.p3     = entry(3,vLine)
        tt.p4     = entry(4,vLine)
        tt.p5     = entry(5,vLine)
    no-error.
      if tt.p1 = '' then delete tt.
    end. /*repeat*/

    input close.
    for first tt:
      assign
        p1 = tt.p1
        p2 = tt.p2
        p3 = tt.p3
        p4 = tt.p4
        p5 = tt.p5
        .
    end.

  /*put unformatted "@@ " n ' lines imported from ' vDesignSheet skip.*/
  end. /*else*/

  message p1 skip p2 skip p3 skip p4 skip p5 view-as alert-box information.

END PROCEDURE.

PROCEDURE ipCleanup:
  def input parameter iFname as char no-undo.
  def var iToname as char no-undo.
  
  iToname = replace(iFname,"csv","old").
  
  if search(iFname) NE ? then 
  do:
    /*os-rename value(iFname) value(iToname).*/
    os-delete value(iFname).
  end.
  
END PROCEDURE.

PROCEDURE ipGenFile:
  def input parameter iFname as char no-undo.
  message iFname view-as alert-box information.
  output to value(iFname).
  put unformatted random(1,99) "," random(1,99) "," random(1,99) "," random(1,99) "," random(1,99) skip.
  output close.
END PROCEDURE.