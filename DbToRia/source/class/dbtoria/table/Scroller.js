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
 * This class extends the qooxdoo table scroller with the cellMouseOver event
 *
 * When the mouse is moved on the pane this class fires an event which contains
 * the cell the mouse is currently over
 */
qx.Class.define("dbtoria.table.Scroller",
{
  extend : qx.ui.table.pane.Scroller,

events :
  {
    "cellMouseOver" : "qx.ui.table.pane.CellEvent"
  },
  /*
  *****************************************************************************
     CONSTRUCTOR
  *****************************************************************************
  */

  /**
   * @param table {qx.ui.table.Table} the table the scroller belongs to.
   */
  construct : function(table)
  {
    this.base(arguments, table);
  },

  members : {
  
    /**
     * Event handler. Called when the user moved the mouse over the pane.
     *
     * @param e {Map} the event.
     * @return {void}
     */
    _onMousemovePane : function(e)
    {
	var table = this.getTable();
	
	if (! table.getEnabled()) {
	    return;
	}
	
	//var useResizeCursor = false;
	
	var pageX = e.getDocumentLeft();
	var pageY = e.getDocumentTop();
	
	// Workaround: In onmousewheel the event has wrong coordinates for pageX
	//       and pageY. So we remember the last move event.
	this.__lastMousePageX = pageX;
	this.__lastMousePageY = pageY;
	
	var row = this._getRowForPagePos(pageX, pageY);
	var column = this._getColumnForPageX(pageX);
	if (row != null && this._getColumnForPageX(pageX) != null) {
	    // The mouse is over the data -> update the focus
	    if (this.getFocusCellOnMouseMove()) {
		this._focusCellAtPagePos(pageX, pageY);
	    }
	    this.fireEvent("cellMouseOver", qx.ui.table.pane.CellEvent, [this, e, row, column], true);
	}
	this.__header.setMouseOverColumn(null);
    }
}
});
