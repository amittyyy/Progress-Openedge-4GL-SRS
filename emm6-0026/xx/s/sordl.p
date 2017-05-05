/* ---------------------- Euro-Mit Staal bv Vlissingen -------------------------
                                                                                
  File        : s/sordl.p                                                       
  Description :                                                                 
  Created     : 28/09/06 Alex Leenstra                                          
                                                                                
Date      Author Version Description                                             
--------  ------ ------- --------------------------------------------------------
28/09/06  AlexL  1.00      Created  
6/20/2008 kamals 1.01      Added PROCEDURE p-info
03/09/08  AlexL	 1.02      Only if available sorder	
23/09/09  Mohan EMM5-0456  Deleted the f-complete function from here and made a .i file 
                           named s/sordlfunc.i to show the complete percentage. 
31/08/15  ku     1.03      EMM6-0034: Logic added to update the price in ssize whenever sorder is updated.
                           Implemented Pop-up Box for confirmation by user. It is still possible to update
                           the price from the ssize module manually.   			
11/09/15  Amity  1.04      [EMM6-0026] Can check eu or neu at once. 													
------------------------------------------------------------------------------*/

define variable v-ordered    as inte no-undo.
define variable v-produced   as inte no-undo.
define variable v-planned    as inte no-undo.
define variable v-slitted    as inte no-undo.
define variable v-palletized as inte no-undo.
define variable v-shipped    as inte no-undo.
define variable v-invoiced   as inte no-undo.
define variable v-closed     as char no-undo.
         
define buffer bfMaster for ocoil.

def stream sFrom.

def temp-table ttDesign
  field linenr as inte
  field key    as char
  field stap   as char
  field batch  as char
  field shape  as char
  field pal1   as char
  field pal2   as char
  field plates as char
  field wid    as char
  field lena   as char
  field hgt    as char
  field wgt    as char
  field ordno  as inte
  field lenc   as char
  field drawing as char
  field palsize as char
  field L14     as char
  field L07     as char
  field L11     as char
  field L12     as char
  .
                                                                                          
{x/xxxxlparam.i}                                                                         
{s/sordlfunc.i} /* Include file for the function f-complete*/


PROCEDURE p-rowdisplay:
/*------------------------------------------------------------------------------
    Field: v-browse01                                                           
    Event: ROW-DISPLAY                                                          
--------------------------------------------------------------------------------
  Purpose:                                                                      
    Notes:                                                                      
  Created: 28/09/06 Alex Leenstra
  Modified : 20/02/07 Chandan Deo                                               
------------------------------------------------------------------------------*/
  /*message 'hello from p-rowdisplay in sordl.p' view-as alert-box.*/
  
  define variable v-prefix         as char no-undo.
  define variable v-gcomm          as char no-undo.     
  define variable v-gcomm1         as char no-undo. 
  define variable v-gcomtshortname as char no-undo.

  find first sord no-lock where rowid(sorder) = p-rowid no-error.

  if available sord then 
  do:
    case true:
      when sord.sordlstock then v-prefix = "V-". 
      otherwise v-prefix = sord.gjobc + '-'.
    end.
  
    assign p-result = 
      'v-gjobc'    + chr(1) + v-prefix                                       + chr(1) + 
      'v-complete' + chr(1) + f-complete(sord.sordn,sord.sordtproduct,sord.sordnorderedweight) + chr(1) +  
      'v-status'   + chr(1) + entry(1,f-xstadisp("sorder",sord.xstac)).      
  
    find first gcom no-lock where gcom.xlevc = f-xlevc('gcompany') and gcom.gcomn = sord.gcomnagent no-error.                    
                           
    if available gcom then 
    do:
      assign v-gcomm = gcom.gcomtshortname.
    end.
    assign p-result = p-result + min(p-result, chr(1)) + 'v-agent' + chr(1) + v-gcomm. 
    
    find first gcom no-lock where gcom.xlevc = f-xlevc('gcompany') and gcom.gcomn = sord.gcomnclient no-error.                    
   
    if available gcom then
    do:
      assign v-gcomm1 = gcom.gcomtshortname.
    end.
    assign p-result = p-result + min(p-result, chr(1)) + 'v-Client' + chr(1) + v-gcomm1.
  end. /*endif avail sord*/

  /*message 'leaving p-rowdisplay in sordl.p' view-as alert-box.*/

END PROCEDURE. /* p-rowdisplay */


PROCEDURE p-display:
/*------------------------------------------------------------------------------
    Event: BEFORE-DISPLAY                                                       
--------------------------------------------------------------------------------
  Purpose:                                                                      
    Notes:                                                                      
  Created: 28/09/06 Alex Leenstra (aleen																				
  Modified : 20/02/07 Chandan Deo                                               
------------------------------------------------------------------------------*/
  /*message 'hello from p-display in sordl.p' view-as alert-box.*/

  define variable v-sfram like sFra.sfram no-undo.
  
  assign p-attribute = p-attribute + min(p-attribute,chr(1)) + 
    'v-xstac'  + chr(1) + 'sensitive' + chr(1) + 'true'  + chr(1) + 
    'v-gcomn'  + chr(1) + 'sensitive' + chr(1) + 'true'  + chr(1) + 
    'v-ggrac'  + chr(1) + 'sensitive' + chr(1) + 'true'.
       
  find first sord no-lock where rowid(sorder) = p-rowid no-error.
  
  find first sfra no-lock where sfra.xlevc = f-xlevc('sframecont') and sFra.sfran = sord.sfran no-error.

  if available sFra then assign v-sfram = sFra.sfram.
  else assign v-sfram = ''.
    
  if available sord then assign v-ok = f-set-xsest("v-ordno",string(sord.sordn)).
  
  assign p-value = f-dynafunc('f-sordn' + chr(1) + string( if available sord then sord.sordn else 0)).
  if available sord then 
  do:
    case sord.sordtproduct:
      when 'Coils' then if search('img\coils.bmp') NE ? then
        assign p-attribute = p-attribute  + min(p-attribute,chr(1)) + 'v-image01' + chr(1) + 'load-image()' + chr(1) + search('img\coils.bmp').
      when 'Laminations' then if search('img\laminations.bmp') NE ? then
        assign p-attribute = p-attribute  + min(p-attribute,chr(1)) + 'v-image01' + chr(1) + 'load-image()' + chr(1) + search('img\laminations.bmp').
      otherwise if search('img\blank.bmp') NE ? then
        assign p-attribute = p-attribute  + min(p-attribute,chr(1)) + 'v-image01' + chr(1) + 'load-image()' + chr(1) + search('img\blank.bmp').
    end case.

    if sord.xstac = '900' then 
    do:
      assign v-closed = chr(13) + "order is closed !!".
    end.  
       
    if sord.sordtproduct NE "Laminations" then do:
      /*message 'not k' view-as alert-box.*/
      for each ocoi no-lock where ocoi.xlevc = f-xlevc('ocoil')
      and ocoi.sordn = sord.sordn:
        if ocoi.xstac NE '100' then assign v-produced   = v-produced   + ocoi.ocoinweight.  
        if ocoi.xstac EQ '100' then assign v-planned    = v-planned    + ocoi.ocoinweight.
        if ocoi.cpaln GT 0     then assign v-palletized = v-palletized + ocoi.ocoinweight.
        if ocoi.xstac EQ '800' then assign v-shipped    = v-shipped    + ocoi.ocoinweight.            
        if sord.gjobc EQ "S"   then if can-find(first iivc no-lock where iivc.xlevc = f-xlevc('iivcol') and iivc.ocoin = ocoi.ocoin and iivc.iivctobjtype = "C") then 
        do: 
          assign v-invoiced = v-invoiced + ocoi.ocoinweight.
        end.
      end . /* for each ocoil */          
    end.
    else do:
      /*message "K" view-as alert-box.*/
      for each ocoi no-lock where ocoi.xlevc = f-xlevc('ocoil')
      and ocoi.sordn = sord.sordn:
        /*if ocoi.xstac NE '100' then assign v-produced   = v-produced   + ocoi.ocoinweight.  */
        if ocoi.xstac EQ '100' then assign v-planned    = v-planned    + ocoi.ocoinweight.
      end . /* for each ocoil */          
      for each cpal no-lock where cpal.xlevc = f-xlevc('cpallet')
      and cpal.sordn = sord.sordn:
        /*OLD**assign v-produced = v-produced + cpal.cpalngrossweight - cpal.cpalntarra.*/
        assign v-produced = v-produced + max(0,cpal.cpalnnetwgt).
        /*OLD**if cpal.xstac = '900' then v-shipped = v-shipped + cpal.cpalngrossweight - cpal.cpalntarra.*/
        if cpal.xstac = '900' then v-shipped = v-shipped + max(0,cpal.cpalnnetwgt).
      end.
      assign v-palletized = v-produced.
    end. 
     
    /* DETERMINE ORDERED QTY */
    for each ssiz no-lock where ssiz.xlevc = f-xlevc('ssizes')
    and ssiz.sordn = sord.sordn:
      assign v-ordered = v-ordered + ssiz.ssiznweight.
    end.
       
    case sord.gjobc:
      when "S" then do:
      end.
      when "T" then do:
        /*   DETERMINE SLITTED QTY */
        for each ocoi no-lock where ocoi.xlevc = f-xlevc('ocoil')
        and ocoi.sordn = sord.sordn,
        first bfMaster no-lock where bfMaster.xlevc = f-xlevc('ocoil')
        and bfMaster.ocoin = ocoi.ocoinmclno 
        and bfMaster.xstac = '900'
        break by bfMaster.ocoin:
          if first-of(bfMaster.ocoin) then v-slitted = v-slitted + bfMaster.ocoinweight.
        end.  /* for each ocoil */
       
        /*  DETERMINE INVOICED QTY */
        for each ocoi no-lock where ocoi.xlevc = f-xlevc('ocoil')
        and ocoi.sordn = sord.sordn,
        first bfMaster no-lock where bfMaster.xlevc = f-xlevc('ocoil')
        and bfMaster.ocoin = ocoi.ocoinmclno,
        first iivc no-lock where iivc.xlevc = f-xlevc('iivcol')
        and iivc.ocoin = bfMaster.ocoin
        and iivc.iivctobjtype = "C"
        break by bfMaster.ocoin:
          if first-of(bfMaster.ocoin) then v-invoiced = v-invoiced + bfMaster.ocoinweight.
        end.  /* for each ocoil */
      end.
      when 'H' then do:
      end.
    end case.
    
    if sord.sordtproduct = "Laminations" then do:
      /*message '//' view-as alert-box.*/
      /*DETERMINE INVOICED QTY*/
      for each cpal no-lock where cpal.xlevc = f-xlevc('cpallet')
      and cpal.sordn = sord.sordn,
      first iivc no-lock where iivc.xlevc = f-xlevc('iinvcol')
      and iivc.iivctobjtype = 'P'
      and iivc.ocoin = cpal.cpaln:
        v-invoiced = v-invoiced + cpal.cpalngrossweight - cpal.cpalntarra.
      end.
    end.
    
    assign p-result = 
      'v-ordered'    + chr(1) + trim(string(v-ordered))    + chr(1) + 
      'v-slitted'    + chr(1) + trim(string(v-slitted))    + chr(1) + 
      'v-produced'   + chr(1) + trim(string(v-produced))   + chr(1) + 
      'v-planned'    + chr(1) + trim(string(v-planned))    + chr(1) + 
      'v-palletized' + chr(1) + trim(string(v-palletized)) + chr(1) + 
      'v-shipped'    + chr(1) + trim(string(v-shipped))    + chr(1) + 
      'v-invoiced'   + chr(1) + trim(string(v-invoiced)).  
 
    assign p-result = p-result  + min(p-result,chr(1)) + 
      'v-balance' + chr(1) + string(v-ordered - v-planned - v-produced)                            + chr(1) + 
      'v-proper'  + chr(1) + (if v-ordered GT 0 then string(v-produced / v-ordered * 100) else '') + chr(1) + 
      'v-plaper'  + chr(1) + (if v-ordered GT 0 then string((v-produced + v-planned)  / v-ordered * 100) else '') .
    assign v-temp = f-dynafunc('f-forwarder' + chr(1) + string(sord.gcomnforwarder)).
  end. /* if available sorder */
  else do:
    if search('img\blank.bmp') NE ? then
      assign p-attribute = p-attribute  + min(p-attribute,chr(1)) + 'v-image01' + chr(1) + 'load-image()' + chr(1) + search('img\blank.bmp').
  end.
   
  /*message 'leaving p-display in sordl.p' view-as alert-box.*/

END PROCEDURE. /* p-disp */


procedure p-commit-before:
/*------------------------------------------------------------------------------
    Event: BEFORE-COMMIT                                                        
--------------------------------------------------------------------------------
  Purpose: For updating the ssize whenever the order price is updated. A pop-up box appears when price is updated.                                                                     
    Notes:                                                                      
  Created: 15/08/31 Kushal Basnet                                               
------------------------------------------------------------------------------*/
                                                                                                
    find first sorder exclusive-lock where sorder.sordn = integer(f-screenvalue('sordn')) no-error.   /* ku EMM6-0034 : For updating the ssize whenever the order price is updated.*/
    if avail sorder and sorder.sordaordprice ne decimal(f-screenvalue('sordaordprice')) then
    do:                                                                                           
        message "Do you want the price to be changed in all sizes ?"                                  /* ku EMM6-0034 : Pop-up Box for Confirmation */                 
            view-as alert-box question buttons yes-no update vAnswer as logi.

        if vAnswer eq yes then
        do:
            for each  ssizes where ssizes.sordn = sorder.sordn exclusive-lock:
                assign 
                    ssizes.ssizaprice = decimal(f-screenvalue('sordaordprice')).
            end.
        end.
        else 
            p-action = "s-cancel".
    end.    
  
END PROCEDURE. /* p-commit-before */


PROCEDURE p-commit:
/*------------------------------------------------------------------------------
    Event: BEFORE-COMMIT                                                        
--------------------------------------------------------------------------------
  Purpose:                                                                      
    Notes:                                                                      
  Created: 05/10/06 Alex Leenstra                                               
------------------------------------------------------------------------------*/
  /*message 'hello from p-commit in sordl.p' view-as alert-box.*/

  define variable h-buffer as handle no-undo.
  define variable h-field  as handle no-undo.
  
  define variable v-label   as char no-undo.
  define variable v-tooltip as char no-undo.
  define variable h-error   as logi no-undo.
  
  for each xwid no-lock where xwid.xproc = p-xproc
  and xwid.xwidlman = true:
              
    create buffer h-buffer for table xwid.xfilc no-error.
    
    if valid-handle(h-buffer) then  
    do:
      h-field = h-buffer:buffer-field(xwid.xwidc) no-error.
      if valid-handle(h-field) then 
      do:
        case h-field:data-type:
          when 'date'      then assign h-error = date(f-getvalue(xwid.xwidc)) = ?.
          when 'integer'   then assign h-error = integer(f-getvalue(xwid.xwidc)) = 0.
          when 'character' then assign h-error = trim(f-getvalue(xwid.xwidc)) = ''.
        end case.
      end.
    end.

    if h-error then 
    do:
      assign v-ok = f-xlabel(input p-xproc,       /* program  */
                             input xwid.xfilc,    /* file     */
                             input xwid.xwidc,    /* widget   */
                             input f-xmlac(),     /* language */
                             input true,          /* normal label */
                             output v-label,
                             output v-tooltip).
      if v-label = '' then assign p-error = 'Mandatory' .
      else assign p-error = 'Mandatory' + chr(1) + v-label.
      leave.
    end.          
  end.
 
  if p-mode = 2 then assign p-result = p-result + min(p-result,chr(1)) + '[copy]' + chr(1) + string(p-rowid).
                        
  /*message 'leaving p-commit in sordl.p' view-as alert-box.*/

END PROCEDURE. /* p-commit */

 
PROCEDURE p-leave-gcomnclient:
/*------------------------------------------------------------------------------
     File: sorder (Sales orders)                                                
    Field: gcomnclient (Customer)                                               
    Event: LEAVE                                                                
--------------------------------------------------------------------------------
  Purpose:                                                                      
    Notes:                                                                      
  Created: 12/10/06 Alex Leenstra                                               
------------------------------------------------------------------------------*/
  /*message 'hello from p-leave-gcomnclient' 
  skip 'p-value=' p-value
  skip 'program-name(5)=' program-name(5)
  skip 'p-mode=' p-mode
  view-as alert-box.*/
  
  /*
  if program-name(5) NE 's-commit x/xxxxv.p' then
  do:
    assign p-result = 'v-gcomnclientbuf' + chr(1) + p-value.
    find first gcom no-lock where gcom.xlevc = f-xlevc('gcompany') and gcom.gcomn = integer(p-value) no-error.
    find first gadr no-lock where gadr.xlevc = f-xlevc('gadres') and gadr.gcomn = gcom.gcomn and gadr.gadrttype = "D" no-error.
    if available gcom then
    do:
      assign p-result = p-result + min(p-result,chr(1)) + 
        "sordtdesti-name"    + chr(1) + gcom.gcomm        + chr(1) + 
        "sordtdesti-address" + chr(1) + gadr.gadrtstreet1 + chr(1) + 
        "sordtdesti-zipcode" + chr(1) + gadr.gadrtzipcode + chr(1) + 
        "sordtdesti-city"    + chr(1) + gadr.gadrtcity    + chr(1) + 
        'gcouc'              + chr(1) + gadr.gcouc.   
    end.  
    find first scdm no-lock where scdm.xlevc = f-xlevc('scdm') and scdm.gcomnclient = integer(p-value) no-error. 
    assign p-result = p-result + min(p-result,chr(1)) + "gcomnforwarder" + chr(1) + if available scdm then string(scdm.gcomnforwarder) else ''.                                            
  end.	                                                  
  */

END PROCEDURE. /* p-leave-gcomnclient */


PROCEDURE p-sordaccept:
/*------------------------------------------------------------------------------
    Event: PROGRAM-START                                                        
--------------------------------------------------------------------------------
  Purpose:                                                                      
    Notes: - this seems never fired !
  Created: 13/10/06 Alex Leenstra                                               
------------------------------------------------------------------------------*/
  /*message 'hello from p-sordaccept in sordl.p' view-as alert-box.*/
  
  define variable v-xstac as char no-undo.
  
  find first sord exclusive-lock where rowid(sorder) = p-rowid no-error.
  
  assign 
    v-xstac = f-xstanext("sorder",sord.xstac,25,true,rowid(sorder))
    sord.xstac = v-xstac.
  
  release sord.
         
  assign p-action = "s-refresh".
      
END PROCEDURE. /* p-sordaccept */


PROCEDURE p-sordcompl:
/*------------------------------------------------------------------------------
    Event: PROGRAM-START                                                        
--------------------------------------------------------------------------------
  Purpose:                                                                      
    Notes: - this seems never fired !
  Created: 13/10/06 Alex Leenstra                                               
------------------------------------------------------------------------------*/
  /*message 'hello from p-sordaccept in sordl.p' view-as alert-box.*/
  
  define variable v-xstac as char no-undo.

  find first sord exclusive-lock where rowid(sorder) = p-rowid no-error.
  
  assign 
    v-xstac = f-xstanext("sorder",sord.xstac,80,true,rowid(sorder))
    sord.xstac = v-xstac.
  
  release sord.
         
  assign p-action   = "s-refresh".
        
END PROCEDURE. /* p-sordcompl */


PROCEDURE p-askset:
/*------------------------------------------------------------------------------
    Event: PROGRAM-START                                                        
--------------------------------------------------------------------------------
  Purpose:                                                                      
    Notes: - this seems never fired !                                                                     
  Created: 17/10/06 Alex Leenstra                                               
------------------------------------------------------------------------------*/
  /*message 'hello from p-askset in sordl.p' view-as alert-box.*/
  
  define variable v-set as logi no-undo.
  define variable v-reset as logi no-undo.
  
  find first sord no-lock where rowid(sorder) = p-rowid no-error.
  
  find xfile where xfile.xfilc = 'sorder' no-lock no-error.
  
  find first xstr where xstr.xsgrc = xfil.xsgrc 
  and xstr.xstacfrom = sord.xstac 
  and xstr.xstrncon = 80
  no-lock no-error. 
                  
  if available xstr then 
    assign v-set = true.
   
  find first xstr where xstr.xsgrc = xfil.xsgrc 
  and xstr.xstacfrom = sord.xstac 
  and xstr.xstrncon = 25 
  no-lock no-error. 
  
  if available xstr then assign v-reset = true.
    
  assign p-result = '[mode]' + chr(1) + (if v-set then 'set' else 'reset').
    
  if v-set or v-reset then assign p-error = (if v-set then 'set' else 'reset').   
            
END PROCEDURE. /* p-askset */


PROCEDURE p-sordreset:
/*------------------------------------------------------------------------------
    Event: PROGRAM-START                                                        
--------------------------------------------------------------------------------
  Purpose:                                                                      
    Notes: - this seems never fired !
  Created: 17/10/06 Alex Leenstra                                               
------------------------------------------------------------------------------*/
  /*message 'hello from p-sordreset in sordl.p' view-as alert-box.*/
  
  define variable v-xstac as char no-undo.
  
  if f-getvalue('answer') = 'true' then 
  do:
    find first sord exclusive-lock where rowid(sorder) = p-rowid no-error.
  
    case f-getvalue('mode'):
      when 'Set' then 
      do:
        assign v-xstac = f-xstanext("sorder",sord.xstac,80,true,rowid(sorder)).
        assign sord.xstac = v-xstac.
      end.
      when 'Reset' then 
      do:
        assign v-xstac = f-xstanext("sorder",sord.xstac,25,true,rowid(sorder)).
        assign sord.xstac = v-xstac.
      end.
    end.
  
    release sord.
  
  end.
  
  assign p-action = "s-refresh".
  
END PROCEDURE. /* p-sordreset */


PROCEDURE p-sorddefault:
/*------------------------------------------------------------------------------
    Event: PROGRAM-START                                                        
--------------------------------------------------------------------------------
  Purpose:                                                                      
    Notes: - this is fired when hitting btn in order mgt 2nd tab demands.
  Created: 20/10/06 Alex Leenstra                                               
------------------------------------------------------------------------------*/
  /*message 'hello from p-sorddefault in sordl.p' view-as alert-box.*/

  define variable h-sord-buffer as handle no-undo.
  define variable h-scdm-buffer as handle no-undo.
  
  define variable h-field1      as handle no-undo.
  define variable h-field2      as handle no-undo.
  
  define variable v-newfield as char no-undo.
 
  find first sord no-lock where rowid(sorder) = p-rowid no-error. 

  create buffer h-sord-buffer for table 'sorder' .
  create buffer h-scdm-buffer for table 'scdm' .
 
  h-scdm-buffer:find-unique('where scdm.xlevc = "' + f-xlevc('scdm') + '" and scdm.gcomnclient = ' + string(sord.gcomnclient) ,no-lock).
   
  repeat v-cnt = 1 to h-scdm-buffer:num-fields:
  
    assign 
      h-field1 = h-scdm-buffer:buffer-field(v-cnt)
      v-newfield = substring(h-sord-buffer:table,1,4) + substring(h-field1:name,5).
  
    assign h-field2 = h-sord-buffer:buffer-field(v-newfield) no-error.
    
    if not valid-handle(h-field2) then
      assign h-field2 = h-sord-buffer:buffer-field(h-field1:name) no-error.

    if valid-handle(h-field2) and lookup(substring(h-field2:name,5),'tsendtodb,tsendtime,tsendxusec,dsend') = 0 then
      assign p-result = p-result + min(p-result,chr(1)) + h-field2:name  + chr(1) +  (if h-field1:buffer-value = ? then ' ' else h-field1:buffer-value).
  end.    

END PROCEDURE. /* p-sorddefault */
 

PROCEDURE p-leave-sfran:
/*------------------------------------------------------------------------------
     File: sorder (Sales orders)                                                
    Field: sfran (Contract)                                                     
    Event: LEAVE                                                                
--------------------------------------------------------------------------------
  Purpose:                                                                      
    Notes: - this is fired when widget frame of order is changed
  Created: 20/10/06 Alex Leenstra                                               
------------------------------------------------------------------------------*/
  /*message 'hello from p-leave-sfran in sordl.p' view-as alert-box.*/

  /*
  define variable v-fields as char no-undo init 'sordnduedays,gjobc,ggrac'.
  define variable v-list   as char no-undo.    
 
  find first sfra where sfra.xlevc = f-xlevc('sframecont') and sfra.sfran = integer(p-value ) no-lock no-error.
  
  assign v-list = f-dynafunc('f-xstaact' + chr(1) + 'ggrade').
  find first ggra no-lock where ggra.xlevc = f-xlevc('ggrade') and ggra.ggrac = sfra.ggrac and lookup(ggra.xstac,v-list) GT 0 no-error.
     
  repeat v-cnt = 1 to num-entries(v-fields):  
     
    find xwid where xwid.xproc = p-xproc
    and xwid.xwidc = entry(v-cnt,v-fields) 
    no-lock no-error.
    
    if f-replfunction(xwid.xwidtsecupdate,true) = 'yes' or p-mode = 1 then 
    do:
      case xwid.xwidc:
        when 'sordnduedays' then assign p-result = p-result + min(p-result,chr(1)) + 'sordnduedays' + chr(1) + string(sfra.sfranduedays).
        when 'gjobc'        then assign p-result = p-result + min(p-result,chr(1)) + 'gjobc'        + chr(1) + sfra.gjobc + chr(1) + 
                                                                                     'ginmc'        + chr(1) + entry(lookup(sfra.gjobc,"S,T,H,"),"FG,MC,TRADE,").
        when 'ggrac'        then assign p-result = p-result + min(p-result,chr(1)) + 'ggrac'        + chr(1) + (if available ggra then ggra.ggrac else ' ').
      end case.
    end.
  end.
*/

END PROCEDURE. /* p-leave-sfran*/


PROCEDURE p-value-gjobc:
/*------------------------------------------------------------------------------
     File: sorder (Sales orders)                                                
    Field: gjobc (Job)                                                          
    Event: VALUE-CHANGED                                                        
--------------------------------------------------------------------------------
  Purpose:                                                                      
    Notes: - this is fired when leaving widget whilst add/upd order and value has changed
  Created: 31/01/07 Alex Leenstra                                               
------------------------------------------------------------------------------*/
  /*message '## hello from p-value-gjobc in sordl.p' view-as alert-box.*/
 
  assign p-result = 'ginmc' + chr(1) + entry(lookup(p-value,"S,T,H,"),"FG,MC,TRADE,").

END PROCEDURE. /* p-value-gjobc */


PROCEDURE p-delete:
/*------------------------------------------------------------------------------
  Purpose: Display error and cancel if order has coils and pallets created for it.
    Notes:                                                                      
  Created: 12/10/06 Alex Leenstra                                               
------------------------------------------------------------------------------*/
  /*message 'hello from p-delete in sordl.p' view-as alert-box.*/

  find first sord no-lock where rowid(sorder) = p-rowid no-error.

  /*message 'ordno=' sord.sordn view-as alert-box.*/

  assign p-error = (if can-find(first ocoi no-lock where ocoi.xlevc = f-xlevc('ocoil') and ocoi.sordn = sord.sordn) then 'CoilAvail' else '').
  if p-error = '' then
  assign p-error = (if can-find(first cpal no-lock where cpal.xlevc = f-xlevc('cpallet') and cpal.sordn = sord.sordn) then 'PalletAvail' else '').

  assign p-action = 's-qryreopen'.

  /*message 'leaving p-delete in sordl.p' 
  skip 'p-error=' p-error
  view-as alert-box.*/

END PROCEDURE. /* p-delete */


PROCEDURE p-info: 
/*------------------------------------------------------------------------------
    Event: PROGRAM-START                                                        
--------------------------------------------------------------------------------
  Purpose:  To show tata information                                                                    
    Notes:                                                                      
  Created: 6/20/2008 4:46PM Kamal Raj Subedi                                              
------------------------------------------------------------------------------*/

  find first sord no-lock where sord.xlevc = f-xlevc('sorder') and sord.sordn = integer(f-getvalue('sordn')) no-error.
  if available sord then
  do:
    define variable v-nCCD as inte no-undo.
    
    for each ccd no-lock 
    where ccd.ib_ident = sord.sordtagentordcd 
    or ccd.ib_ident = sord.sordtcustordcd:
      assign v-nCCD = v-nCCD + 1.
    end.
    message "Verify existing tata-data related to this order..." skip
      skip "Label-data" can-find(first cld where sord.sordtcustordcd begins trim(cld.ib_ident) or sord.sordtagentordcd begins trim(cld.ib_ident))
      skip "Order-data" can-find(first cod where substring(cod.ib_ident,1,6) = sord.sordtcustordcd)
      skip v-nCCD " Coil-data" can-find(first ccd where ccd.ib_ident = sord.sordtagentordcd or ccd.ib_ident = sord.sordtcustordcd)
      view-as alert-box information.
  end.
   
END PROCEDURE. /* p-info */


PROCEDURE p-display-rdy:
/*------------------------------------------------------------------------------
    Field: v-rdy                                                                
    Event: BEFORE-DISPLAY                                                       
--------------------------------------------------------------------------------
  Purpose:                                                                      
    Notes: this is fired when navigating to other tabfolders
  Created: 09/07/13 Mohan Niroula                                               
------------------------------------------------------------------------------*/
  /*message 'hello from p-display-rdy in sordl.p' view-as alert-box.*/

  define variable v-output         as deci no-undo.
  define variable v-gcomtshortname as char no-undo.

  find first sord no-lock where rowid(sorder) = f-getrowid('sorder') no-error.
  if available sord then
  do:
    /* Get the shortname of client company */
    find first gcom no-lock where gcom.xlevc = f-xlevc('gcompany') and gcom.gcomn = sord.gcomnclient no-error.                    
    assign v-gcomtshortname = if available gcom then gcom.gcomtshortname else ''.    
    
    /*  calculate produced weight  */
    if sord.sordtproduct NE 'laminations' then do:
      for each ocoi no-lock where ocoi.xlevc = f-xlevc('ocoil') 
      and ocoi.sordn = sord.sordn 
      and ocoi.xstac GT '150':
        assign v-output = v-output + ocoi.ocoinweight. 
      end.
    end.
    else do:
      /*message "K-row" view-as alert-box.*/
      for each cpal no-lock where cpal.xlevc = f-xlevc('cpallet')
      and cpal.sordn = sord.sordn:
        /*OLD**assign v-output = v-output + cpal.cpalngrossweight - cpal.cpalntarra.*/
        assign v-output = v-output + max(0,cpal.cpalnnetwgt).
      end.
    end.
    assign p-result = 
      'v-client' + chr(1) + v-gcomtshortname + chr(1) + 
      'v-rdy'    + chr(1) + string(max(0,v-output) / sord.sordnorderedweight * 100,">>9.9") + '%' .
  end.
           
END PROCEDURE. /* p-display-rdy */
  

PROCEDURE p-value-sfran:
/*------------------------------------------------------------------------------
  File   : sorder (Salesorder)                                                  
    Field: sfran (FrameContract)                                                
    Event: VALUE-CHANGED                                                        
--------------------------------------------------------------------------------
  Purpose:                                                                      
    Notes:                                                                      
  Created: 12/06/28 Eric Clarisse                                               
------------------------------------------------------------------------------*/
  /*message 'hello from p-value-sfran in sordl.p' view-as alert-box.*/
  
  define variable v-fields as char no-undo init 'sordnduedays,gjobc,ggrac'.
  define variable v-list   as char no-undo.    
 
  find first sfra no-lock where sfra.xlevc = f-xlevc('sframecont') and sfra.sfran = integer(p-value ) no-error.
  
  assign v-list = f-dynafunc('f-xstaact' + chr(1) + 'ggrade').
  find first ggra no-lock where ggra.xlevc = f-xlevc('ggrade') and ggra.ggrac = sfra.ggrac and lookup(ggra.xstac,v-list) GT 0 no-error.
     
  repeat v-cnt = 1 to num-entries(v-fields):  
     
    find first xwid no-lock where xwid.xproc = p-xproc and xwid.xwidc = entry(v-cnt,v-fields) no-error.
    
    if f-replfunction(xwid.xwidtsecupdate,true) = 'yes' or p-mode = 1 then 
    do:
      case xwid.xwidc:
        when 'sordnduedays' then assign p-result = p-result + min(p-result,chr(1)) + 'sordnduedays' + chr(1) + string(sfra.sfranduedays).
        when 'gjobc'        then assign p-result = p-result + min(p-result,chr(1)) + 'gjobc'        + chr(1) + sfra.gjobc + chr(1) + 
                                                                                     'ginmc'        + chr(1) + entry(lookup(sfra.gjobc,"S,T,H,"),"FG,MC,TRADE,").
        when 'ggrac'        then assign p-result = p-result + min(p-result,chr(1)) + 'ggrac'        + chr(1) + (if available ggra then ggra.ggrac else ' ').
      end case.
    end.
  end.
  
END PROCEDURE. /* p-value-sfran */


PROCEDURE p-value-gcomnclient:
/*------------------------------------------------------------------------------
  File   : sorder (Salesorder)                                                  
    Field: gcomnclient (Customer)                                               
    Event: VALUE-CHANGED                                                        
--------------------------------------------------------------------------------
  Purpose:                                                                      
    Notes:                                                                      
  Created: 12/06/28 Eric Clarisse                                               
------------------------------------------------------------------------------*/
  /*message 'hello from p-value-gcomnclient'   view-as alert-box.*/
  
  assign p-result = 'v-gcomnclientbuf' + chr(1) + p-value. /*what is v-gcomnclientbuf doing ?*/
  find first gcom no-lock where gcom.xlevc = f-xlevc('gcompany') and gcom.gcomn = integer(p-value) no-error.
  if avail gcom then
  find first gadr no-lock where gadr.xlevc = f-xlevc('gadres') and gadr.gcomn = gcom.gcomn and gadr.gadrttype = "D" no-error.
  
  assign p-result = p-result + min(p-result,chr(1)) + 
    "sordtdesti-name"    + chr(1) + (if avail gcom then gcom.gcomm else '')        + chr(1) + 
    "sordtdesti-address" + chr(1) + (if avail gadr then gadr.gadrtstreet1 else '') + chr(1) + 
    "sordtdesti-zipcode" + chr(1) + (if avail gadr then gadr.gadrtzipcode else '') + chr(1) + 
    "sordtdesti-city"    + chr(1) + (if avail gadr then gadr.gadrtcity else '')    + chr(1) + 
    "gcouc"              + chr(1) + (if avail gadr then gadr.gcouc else '').   
  
  find first scdm no-lock where scdm.xlevc = f-xlevc('scdm') and scdm.gcomnclient = integer(p-value) no-error. 
  if avail scdm then 
  do:
    assign p-result = p-result + min(p-result,chr(1)) + "gcomnforwarder" + chr(1) + string(scdm.gcomnforwarder).                                            
  end.
  if avail gcom then do:
    assign p-result = p-result + min(p-result,chr(1)) + 
      "sordtpayterms"       + chr(1) + gcom.gcomtpayterms     + chr(1) +
      "sordtcountryorigin"  + chr(1) + gcom.gcomtorigin       + chr(1) +
      "sordtmanufacturer"   + chr(1) + gcom.gcomtmanufacturer + chr(1) +
      "sordtinsurancetext"  + chr(1) + gcom.gcomtinsurance    + chr(1) +
      "sordtdlvterms"       + chr(1) + gcom.gcomtcity.  /*@#$! this is a mistake, new field should be added to table gcom with proper name*/
  end.
  
END PROCEDURE. /* p-value-gcomnclient */


PROCEDURE p-value-ggrac:
/*------------------------------------------------------------------------------
  File   : sorder (Salesorder)                                                  
    Field: ggrac (Grade)                                                        
    Event: VALUE-CHANGED                                                        
--------------------------------------------------------------------------------
  Purpose:                                                                      
    Notes:                                                                      
  Created: 12/06/28 Eric Clarisse                                               
------------------------------------------------------------------------------*/
  /*message 'hello from p-value-ggrac in sordl.p' view-as alert-box.*/
  if p-mode GT 2 then
  do:  /* should not fire when adding, just when updating*/
  
  find first sord no-lock where rowid(sorder) = f-getrowid('sorder') no-error.
  if available sord then
  do:
    if can-find(first ocoi no-lock where ocoi.xlevc = f-xlevc('ocoil') and ocoi.sordn = sord.sordn) then
    do:
      message 'You can not change grade, at least one coil already planned or produced.' 
        skip 'After you click OK the grade is reset to ' sord.ggrac view-as alert-box information.
      assign p-result = p-result + min(p-result,chr(1)) + "ggrac" + chr(1) + sord.ggrac.
    end.
  end.
  
  end.
  
END PROCEDURE. /* p-value-ggrac */


PROCEDURE p-testchars:
/*------------------------------------------------------------------------------
  File   : sorder (Salesorder)                                                  
    Field: sordtcustordcd (Customer order number)                               
    Event: LEAVE                                                                
--------------------------------------------------------------------------------
  Purpose:                                                                      
    Notes:                                                                      
  Created: 13/04/18 Eric Clarisse                                               
------------------------------------------------------------------------------*/
  
  /*purpose: test presence of certains chars in a string*/
  define variable returnvalue as logi no-undo init false.
  define variable i           as inte no-undo.
  define variable c-list      as char no-undo init "<,>,\,/,:,*,?,~",|,&,., ,".
  
  repeat i = 1 to num-entries(c-list):
    if index(p-value,entry(i,c-list)) GT 0 then assign returnvalue = true.
  end. /*repeat*/
  
  if returnvalue = true then
  message "Be aware, your input contains special characters."
    skip "This will cause problems elsewehere."
    skip "Best to replace those characters by underscore."
    view-as alert-box warning.

END PROCEDURE. /* p-testchars */

procedure p-cleanup:
/*------------------------------------------------------------------------------
    Event: BEFORE-DELETE                                                        
--------------------------------------------------------------------------------
  Purpose:                                                                      
    Notes: this is bad solution but functional, fired tru event when deleting salesorder
  Created: 14/03/19 Eric Clarisse                                               
------------------------------------------------------------------------------*/

  find first sord no-lock where rowid(sorder) = f-getrowid('sorder') no-error.

  /*message program-name(1) skip
  '' sord.sordn
  view-as alert-box.*/
  
  for each ttru exclusive-lock where ttru.xlevc = f-xlevc('ttruck')
  and ttru.sordn = sord.sordn:
    /*message 'del 1' view-as alert-box.*/
    delete ttru.
  end.
  for each oshp exclusive-lock where oshp.xlevc = f-xlevc('oshp')
  and oshp.sordn = sord.sordn:
    /*message 'del 2' view-as alert-box.*/
    delete oshp.
  end.
  disable triggers for load of srec.
  for each srec exclusive-lock where srec.xlevc = f-xlevc('srecipient')
  and srec.sordn = sord.sordn:
    /*message 'del 3' view-as alert-box.*/
    delete srec.
  end.
  disable triggers for load of ssiz.
  for each ssiz exclusive-lock where ssiz.xlevc = f-xlevc('ssizes')
  and ssiz.sordn = sord.sordn:
    /*message 'del 4' view-as alert-box.*/
    delete ssiz.
  end.
  disable triggers for load of oshp.
  for each oshp exclusive-lock where oshp.xlevc = f-xlevc('oshp')
  and oshp.sordn = sord.sordn:
    /*message 'del 5' view-as alert-box.*/
    delete oshp.
  end.
  disable triggers for load of sdsn.
  for each sdsn exclusive-lock where sdsn.xlevc = f-xlevc('sdsn')
  and sdsn.sordn = sord.sordn:
    /*message 'del 6' view-as alert-box.*/
    delete sdsn.
  end.
  
  /*message 'leaving p-cleanup in sordl.p' view-as alert-box.*/

END PROCEDURE. /* p-cleanup */

procedure p-impdesign:
/*------------------------------------------------------------------------------
    Event: PROGRAM-START                                                        
--------------------------------------------------------------------------------
  Purpose:                                                                      
    Notes:                                                                      
  Created: 14/09/16 Eric Clarisse                                               
------------------------------------------------------------------------------*/
  /*message 'hello from sordl' view-as alert-box information.*/

  find first sord no-lock where rowid(sorder) = f-getrowid('sorder') no-error.
  
  if avail sord then do:
  message /*program-name(1) skip sord.sordn*/
  "Importing for " sord.sordn
  view-as alert-box.
  
  def var vSourceFile as char no-undo.

  vSourceFile = replace("x:\everyone\cutting\D[1].csv","[1]",string(sord.sordn)).
  if search(vSourceFile) NE ? then do:
    disable triggers for load of sdsn.
    for each sdsn exclusive-lock where sdsn.xlevc = '1'
    and sdsn.sordn = sord.sordn:
      delete sdsn.
    end.
    run ipReadFile(input vSourceFile).
    for each ttDesign no-lock where ttDesign.ordno = sord.sordn:
      if not ttDesign.drawing begins "TK" then message 'mistake1 in drawing!' skip ttDesign.drawing view-as alert-box error.
      else if length(ttDesign.drawing) NE 4 then do:
        if length(ttDesign.drawing) EQ 3 then assign ttDesign.drawing = "TK0" + substring(ttDesign.drawing,3,1).
        else message 'mistake2 in drawing!' view-as alert-box error.
      end.
      create sdsn.
      assign
        sdsn.sdsnahgt    = decimal(ttDesign.hgt)
        sdsn.sdsnawid    = integer(ttDesign.wid)
        sdsn.sdsnnlena   = integer(ttDesign.lena)
        sdsn.sdsnnlenc   = integer(ttDesign.lenc)
        sdsn.sdsnnpallet = integer(ttDesign.pal1)
        /*sdsn.sdsnnpal2   = integer(ttDesign.pal2)*/
        sdsn.sdsnllaststack   = if ttDesign.pal2 NE "" then false else true
        sdsn.sdsnnplates = integer(ttDesign.plates)
        sdsn.sdsnnstap   = integer(ttDesign.stap)
        sdsn.sdsnnwgt    = integer(ttDesign.wgt)
        sdsn.sdsntbatch  = ttDesign.batch
        sdsn.sdsntshape  = ttDesign.shape
        sdsn.sordn       = sord.sordn
        sdsn.sdsntdrawing = ttDesign.drawing
        sdsn.sdsntpalsize = caps(ttDesign.palsize)
        sdsn.sdsnaL07     = decimal(ttDesign.L07) 
        sdsn.sdsnaL11     = decimal(ttDesign.L11) 
        sdsn.sdsnaL12     = decimal(ttDesign.L12) 
        sdsn.sdsnaL14     = decimal(ttDesign.L14) 
        sdsn.xdepc = 'EMM5'
        sdsn.xlevc = '1'
        /*
        sdsn.sdsndsend = today
        sdsn.sdsntsendtime = string(time,"HH:MM:SS")
        sdsn.sdsntsendtodb = ''
        sdsn.sdsntsendxusec = 'ecl'
        */
        sdsn.xstac = '100'
        .
    end.
    run proc\sys429-p.p(sord.sordn). /*this will generate the relevant shape-records*/
    /*message 'Finished importing design data! Please refresh and check' view-as alert-box information.*/
    message 'Finished importing design data! Please check' view-as alert-box information.
  end.
  else message 'File not found!' view-as alert-box error.
  end.
  
END PROCEDURE. /* p-impdesign */


PROCEDURE ipReadFile:
  def input parameter iSourceFile as char no-undo.

def var vLine as char no-undo.
def var n as inte no-undo.

if search(iSourceFile ) EQ ? then put " @@ FILE NOT FOUND !" skip.
else do:
input STREAM sFrom FROM VALUE(iSourceFile ).

repeat: /* txt file with two fields [colno,desti] */
  import stream sFrom unformatted vLine no-error.
   n = n + 1.
/*   disp vLine. */
  create ttDesign.
  assign
    ttDesign.linenr = n 
    ttDesign.key = entry(1,vLine)
    ttDesign.stap = entry(2,vLine)
    ttDesign.batch = entry(3,vLine)
    ttDesign.shape = entry(4,vLine)
    ttDesign.pal1 = entry(5,vLine)
    ttDesign.pal2 = entry(6,vLine)
    ttDesign.plates = entry(7,vLine)
    ttDesign.wid = entry(8,vLine)
    ttDesign.lena = entry(9,vLine)
    ttDesign.hgt = entry(10,vLine)
    ttDesign.wgt = entry(11,vLine)
    ttDesign.lenc = entry(12,vLine)
    ttDesign.ordno = sord.sordn
    ttDesign.drawing = caps(entry(13,vLine))
    ttDesign.palsize = entry(14,vLine)
    ttDesign.L07 = entry(15,vLine)
    ttDesign.L11 = entry(16,vLine)
    ttDesign.L12 = entry(17,vLine)
    ttDesign.L14 = entry(18,vLine)
    no-error.
  if ttDesign.stap = '' or ttDesign.stap = 'stap' then delete ttDesign.
end. /*repeat*/


input close.

/* for each tt: */
/*   if ttDesign.stap GE 137 and ttDesign.stap LT 200 then */
/*   disp ttDesign. */
/* end. */

 /*put unformatted "@@ " n ' lines imported from ' vDesignSheet skip.*/
end. /*else*/

END PROCEDURE. /*ipReadFile*/

procedure p-value-sordlentrepot:
/*------------------------------------------------------------------------------
  File   : ttruck (Truck)                                                       
    Field: sordlenterpot (NEU)                                                         
    Event: VALUE-CHANGED                                                        
--------------------------------------------------------------------------------
  Purpose: To uncheck eu check box.                                                                     
    Notes:                                                                      
  Created: 09/10/2015 Amity timalsina  [EMM6-0026]                                            
------------------------------------------------------------------------------*/

  if p-value = 'yes' then assign p-result = 
    'sordleu' + chr(1) + 'no'.
    
 END PROCEDURE. /* p-value-sordlenterpot */  
  
procedure p-value-sordleu:
/*------------------------------------------------------------------------------
  File   : ttruck (Truck)                                                       
    Field: sordleu (EU)                                                         
    Event: VALUE-CHANGED                                                        
--------------------------------------------------------------------------------
  Purpose: to uncheck NEU check box.                                                                     
    Notes:                                                                      
  Created: 09/10/2015 amity timalsina  [EMM6-0026]                                            
------------------------------------------------------------------------------*/

  if p-value = 'yes' then assign p-result = 
    'sordlentrepot' + chr(1) + 'no'.
    
 END PROCEDURE. /* p-value-sordleu */
