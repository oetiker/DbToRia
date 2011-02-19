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
 * This class extends the qooxdoo table with a cellMouseOver event
 *
 * The qooxdoo table supports a cellMouseOver event but it is not possible to
 * attach an external listener for it, this class adds support for it.
 */
qx.Class.define("dbtoria.table.Table",
{
  extend : qx.ui.table.Table,

  /*
  *****************************************************************************
     CONSTRUCTOR
  *****************************************************************************
  */

  construct : function(tableModel, custom)
  {
    this.base(arguments, tableModel, custom);
  },

  /*
  *****************************************************************************
     EVENTS
  *****************************************************************************
  */

  events :
  {
    "cellMouseOver" : "qx.ui.table.pane.CellEvent"
    },

  /*
  *****************************************************************************
     STATICS
  *****************************************************************************
  */

  statics :
  {
    /** Events that must be redirected to the scrollers. */
    __redirectEvents : { cellClick: 1, cellDblclick: 1, cellContextmenu: 1, cellMouseOver: 1 }
  },

  /*
  *****************************************************************************
     PROPERTIES
  *****************************************************************************
  */
members : {

    // overridden
    addListener : function(type, listener, self, capture)
    {
      if (this.self(arguments).__redirectEvents[type] )
      {
        for (var i = 0, arr = this._getPaneScrollerArr(); i < arr.length; i++)
        {
          arr[i].addListener.apply(arr[i], arguments);
        }
      }
      else
      {
        return this.base(arguments, type, listener, self, capture);
      }
    }
}
});
