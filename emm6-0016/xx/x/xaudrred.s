/* ------------------------------------  ---------------------------------------
                                                                                
  File        : x/xaudrred.s                                                    
  Description : Include file for this printing                                  
  Created     : 15/08/18 Kushal Basnet                                          
                                                                                
Date     Author Version Description                                             
-------- ------ ------- --------------------------------------------------------
15/08/18 kushal 1.00    Created                                                 
------------------------------------------------------------------------------*/

{x/xxxxpvar.i}      /* standard variables               */

def input param v-inputparam as char no-undo.         /* input parameters */

{x/xxxxs.i}         /* standard include for reports     */

def var v-basedate as DATE no-undo.    /* Base Date */
def var v-batchconf as LOGICAL no-undo.    /* Run in Batch */


/* fill the variables out of the inputparameter  */


if lookup("v-basedate",v-inputparam,chr(1)) > 0 then /*  */ 
  assign v-basedate = DATE(entry(lookup("v-basedate",v-inputparam,chr(1)) + 1, v-inputparam,chr(1))).

if lookup("v-batchconf",v-inputparam,chr(1)) > 0 then /*  */ 
  assign v-batchconf = entry(lookup("v-batchconf",v-inputparam,chr(1)) + 1, v-inputparam,chr(1)) = "yes".

