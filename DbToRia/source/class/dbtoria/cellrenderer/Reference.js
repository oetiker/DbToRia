/* ************************************************************************

  DbToRia - Database to Rich Internet Application
  
  http://www.dbtoria.org

   Copyright:
    2009 David Angleitner, Switzerland
    
   License:
    GPL: http://www.gnu.org/licenses/gpl-2.0.html

   Authors:
    * David Angleitner

************************************************************************ */

/* ************************************************************************

#asset(dbtoria/*)

************************************************************************ */

/**
 * Reference
 */
qx.Class.define("dbtoria.cellrenderer.Reference",
{
  extend : qx.ui.table.cellrenderer.AbstractImage,

  /*
  *****************************************************************************
     MEMBERS
  *****************************************************************************
  */

  members :
  {
    // overridden
    _getContentHtml : function(cellInfo) {
      return ("<em>" + cellInfo.value + "</em>" || "");
    }
  }
});
