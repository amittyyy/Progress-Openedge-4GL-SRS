

DEFINE VARIABLE LJVWrapper   AS COM-HANDLE.
DEFINE VARIABLE sendCommand  AS CHAR NO-UNDO.
DEFINE VARIABLE Rc           AS CHAR NO-UNDO.
DEFINE VARIABLE resultvalue  AS CHARACTER   NO-UNDO.
DEFINE VARIABLE v-start      AS INTEGER   NO-UNDO.
DEFINE VARIABLE v-stop       AS INTEGER     NO-UNDO.
DEFINE VARIABLE v-go         AS CHARACTER   NO-UNDO.
DEFINE VARIABLE v-value      AS CHARACTER   NO-UNDO.

DEFINE VARIABLE ipaddress AS CHARACTER   NO-UNDO.
DEFINE VARIABLE portNo AS CHARACTER   NO-UNDO.
DEFINE VARIABLE location AS CHARACTER   NO-UNDO.
DEFINE VARIABLE fullpath AS CHARACTER   NO-UNDO.
DEFINE VARIABLE v-datetime AS CHARACTER   NO-UNDO.
/* DEFINE VARIABLE v-thickness        AS CHARACTER   NO-UNDO. */
/* DEFINE VARIABLE v-waving           AS CHARACTER   NO-UNDO. */
/* DEFINE VARIABLE v-burr             AS CHARACTER   NO-UNDO. */
/* DEFINE VARIABLE v-camber           AS CHARACTER   NO-UNDO. */
/* DEFINE VARIABLE v-thicknl          AS CHARACTER   NO-UNDO. */
/* DEFINE VARIABLE v-output6          AS CHARACTER   NO-UNDO. */

CREATE "LJV_Dllconsolesample.Server" LJVWrapper. /* programm identifier that initialize the new instances with specified progid*/
find first  xsetting where xsetting.xsetc = "IPSetting1" no-lock no-error.
  assign 
    ipaddress = entry(1,xsetting.xsett)
    portNo    = entry(2,xsetting.xsett)
   location   = ENTRY(3,xsetting.xsett)
   . 
v-datetime = REPLACE (STRING(DATETIME(TODAY, MTIME)),"/","-").
v-datetime = REPLACE (STRING(v-datetime),":","-").
v-datetime = REPLACE (STRING(v-datetime),".", "-").

ASSIGN fullpath = location + v-datetime.
  MESSAGE ipaddress portno fullpath 
      VIEW-AS ALERT-BOX INFO BUTTONS OK.


ASSIGN Rc          = LJVWrapper:EthernetOpen(ipaddress, portno).
ASSIGN v-value     = LJVWrapper:GetStorageData_data(fullpath).
ASSIGN v-go        = LJVWrapper:GetLastError().
MESSAGE rc v-value v-go
    VIEW-AS ALERT-BOX INFO BUTTONS OK.




/* ASSIGN sendCommand = LJVWrapper:GetMeasurementValue_value().                   */
/* ASSIGN resultvalue = LJVWrapper:GetLastError().                                */
/* /*                                                                          */ */
/* DO WHILE INDEX (resultvalue,"_GO_") > 0:                                 */
/*                                                                          */
/*    v-start     = INDEX (resultvalue,"_GO_").                             */
/*                                                                          */
/*    v-value     = v-value + SUBSTRING(resultvalue,(v-start + 7),6) + ",". */
/*    resultvalue = SUBSTRING(resultvalue,(v-start + 6)).                   */
/*                                                                          */
/* END.                                                                     */
/*                                                                          */
/*  ASSIGN                         */
/* v-thickness = ENTRY(1,v-value)  */
/* v-waving    = ENTRY(2,v-value)  */
/* v-burr      = ENTRY(3,v-value)  */
/* v-camber    = ENTRY(4,v-value)  */
/* v-thicknl   = ENTRY(5,v-value)  */
/* v-output6  = ENTRY(6,v-value).  */



/*
ASSIGN v-thickness         = SUBSTRING(resultvalue,86,5)
       v-waving            = SUBSTRING(resultvalue,115,5)
       v-burr              = SUBSTRING(resultvalue,144,5)
       v-camber            = SUBSTRING(RESULTvalue,173,5)
       v-thickness_live    = SUBSTRING(resultvalue,202,5)
       v-output6           = SUBSTRING(resultvalue,231,5).

MESSAGE "thickness       : " v-thickness SKIP
        "waving          : " v-waving SKIP
        "Burr            : " v-burr skip 
        "Camber          : " v-camber SKIP
        "Thickness Live  : " v-thickness_live SKIP
        "Wave Height     : " v-output6

    VIEW-AS ALERT-BOX INFO BUTTONS OK.
 */

  









