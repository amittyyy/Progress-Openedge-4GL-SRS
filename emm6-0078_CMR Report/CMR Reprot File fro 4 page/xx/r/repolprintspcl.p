/* ---------------------- Euro-Mit Staal bv Vlissingen -------------------------
                                                                                
  File        : r/repolprintspcl.p                                              
  Description :                                                                 
  Created     : 09/12/04 Mohan Niraula                                          
                                                                                
Date     Author Version Description                                             
-------- ------ ------- --------------------------------------------------------
09/12/04 mnirou 1.00    Created   (To print the CMR report in a special printer defined
                                   in the xsetting cmrprinter.)
14/12/15 ku     1.01    [EMM6-0078] Added a condition to print any number of copies for 
                        the CMR Documents.                                                                                  
------------------------------------------------------------------------------*/
function f-getparam returns character
    (input p-field as char) forward.
{x/xxxxlparam.i}   
{x/xxxxlprint-tb2.i}                                                                      

PROCEDURE p-printreport:
  /*------------------------------------------------------------------------------
      Event: PROGRAM-START                                                        
  --------------------------------------------------------------------------------
    Purpose: To print the CMR report in a special CMR printer CMR printer is defined in 
             Xsetting cmrprinter.                                                                     
      Notes:                                                                      
    Created: 09/12/04 Mohan Niraula                                               
  ------------------------------------------------------------------------------*/
  define variable v-location   as char no-undo.
  define variable v-newfile    as char no-undo.
  define variable v-outfile    as char no-undo.
  define variable v-cmrprinter as char no-undo.
  define variable v-ascreport  as char no-undo.
  define variable v-outputto   as char no-undo. /*user input for the location*/
  define variable v-folder     as logi no-undo. /*file-type:Directory */

  /* Location of the report file where it is generated*/
  assign v-location = "C:\temp\" + "R" + substring(p-xproc,8,3) + "_" + string(now,'999999') + string(time).
  /*Generate the text report in the above defined location with defined fonts and fontsize*/
      
  find first xsetting where xsetting.xsetc = "cmrcopies" no-lock no-error.    /*ku v1.01: Added a condition to print any number of copies*/
  if avail xsetting then    
  assign p-allvalues = p-allvalues + 
    "[v-xproc]"        + chr(1) +  v-xproc       + chr(1) +
    "[v-font]"         + chr(1) + (if (f-getparam('v-font') = '' or f-getparam('v-font') = ?) then "Lucida console" else f-getparam('v-font')) + chr(1) +  /*gp: the default font now can be changed in Print/Batch tab, otherwise it will be 'Lucida Console' */
    "[v-fontsize]"     + chr(1) + "8"            + chr(1) +
    "[v-condensed]"    + chr(1) + "no"           + chr(1) +
    "[v-filename-ext]" + chr(1) + ".txt"         + chr(1) +
    "[v-inbatch]"      + chr(1) + "no"           + chr(1) +
    "[v-batch]"        + chr(1) + "FIFO"         + chr(1) +
    "[v-once]"         + chr(1) + "yes"          + chr(1) +
    "[v-params]"       + chr(1) + "yes"          + chr(1) +
    "[v-parampage]"    + chr(1) + "yes"          + chr(1) +
    "[v-numcopies]"    + chr(1) + string(xsetting.xsett) + chr(1) +
    "[v-paged]"        + chr(1) + "yes"          + chr(1) +
    "[v-append]"       + chr(1) + "no"           + chr(1) +
    "[v-double]"       + chr(1) + "No"           + chr(1) +
    "[v-outputfile]"   + chr(1) + v-location     + chr(1) +
    "[v-closewindow]"  + chr(1) + "No".
  else   
  assign p-allvalues = p-allvalues + 
    "[v-xproc]"        + chr(1) +  v-xproc       + chr(1) +
    "[v-font]"         + chr(1) + (if (f-getparam('v-font') = '' or f-getparam('v-font') = ?) then "Lucida console" else f-getparam('v-font')) + chr(1) +  /*gp: the default font now can be changed in Print/Batch tab, otherwise it will be 'Lucida Console' */
    "[v-fontsize]"     + chr(1) + "8"            + chr(1) +
    "[v-condensed]"    + chr(1) + "no"           + chr(1) +
    "[v-filename-ext]" + chr(1) + ".txt"         + chr(1) +
    "[v-inbatch]"      + chr(1) + "no"           + chr(1) +
    "[v-batch]"        + chr(1) + "FIFO"         + chr(1) +
    "[v-once]"         + chr(1) + "yes"          + chr(1) +
    "[v-params]"       + chr(1) + "yes"          + chr(1) +
    "[v-parampage]"    + chr(1) + "yes"          + chr(1) +
    "[v-numcopies]"    + chr(1) + "1"            + chr(1) +
    "[v-paged]"        + chr(1) + "yes"          + chr(1) +
    "[v-append]"       + chr(1) + "no"           + chr(1) +
    "[v-double]"       + chr(1) + "No"           + chr(1) +
    "[v-outputfile]"   + chr(1) + v-location     + chr(1) +
    "[v-closewindow]"  + chr(1) + "No".

  /*Mohan- Find the xsetting for CMR Printer*/
  find xsetting where xsetting.xlevc = f-xlevc('xset')
  and xsetting.xsetc = 'cmrprinter'
  no-lock no-error.
  if available xsetting then assign v-cmrprinter = xsetting.xsett.
  else message "Xsetting for cmrprinter is not created!!. Please create cmrprinter xsetting and values will be the name of printer of CMR report ".
 
  /*Print the report in the special CMR printer*/
  assign p-allvalues = p-allvalues + chr(1) + 
    '[v-openfile]'  + chr(1) + f-getparam('v-openfile') + chr(1) + 
    '[v-printer]'   + chr(1) + v-cmrprinter  /*session:printer-name /*f-getparam('v-printer')*/*/ + chr(1) + 
    '[v-pagesize]'  + chr(1) + f-getparam('v-pagesize') + chr(1) + 
    '[v-landscape]' + chr(1) + f-getparam('v-landscape')    /* determain the default printer */ + chr(1) + 
    '[v-output]'    + chr(1) + "1"    /* Printer */   .

  run p-print(p-allvalues).

END PROCEDURE. /* p-printreport */


function f-getparam returns character
    (input p-field as char):

  /*Function for the inpur parameters for fontsize,font and necessary report parameters*/

  define variable v-value as char no-undo.
  define variable v-users as char no-undo.

  v-users = f-xusec() + ',default'.

  repeat v-cnt = 1 to num-entries(v-users):

    find xwde where xwde.xproc = v-xproc
    and xwde.xusec = entry(v-cnt,v-users)
    and xwde.xwidc = p-field
    no-lock no-error.

    if available xwde then 
    do:
      assign v-value =  xwde.xwdetvalue.
      leave.
    end. /* avail xwde */

  end. /* repeat v-cnt = 1 */

  find xuser where xuser.xusec = f-xusec() no-lock no-error.

  if v-value = '' or v-value = '000' then 
  do:
 
    case p-field:
      when 'v-openfile' then assign v-value = 'yes'.
      when 'v-pagesize' then assign v-value = '130'.   /* this is a default value and will be effective only if the value saved for pagesize in Print/Batch tab is '000' */
    end case.
      
  end. /* v-value = '' */

  return v-value.

end function. /* f-getparam */
