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
 * This class implements the remote table model for dbtoria
 *
 * It allows the dynamic display of the currently visible rows. Since the data
 * is retrieved from the perl backend the corresponding SELECT query is updated
 * with the needed LIMIT and OFFSET
 */
qx.Class.define("dbtoria.table.RemoteDataModel",
{
  extend : qx.ui.table.model.Remote,
/*
  *****************************************************************************
     CONSTRUCTOR
  *****************************************************************************
  */

  construct : function(dbTable)
  {
    this.base(arguments);
    this.__dbTable = dbTable;
  },
  
  /*
  *****************************************************************************
     MEMBERS
  *****************************************************************************
  */

  members :
  {
    __dbTable: null,
    
   // overloaded - called whenever the table requests the row count
    _loadRowCount : function()
    {
	this._onRowCountLoaded(parseInt(this.__dbTable.getNumRows()));
    },
    
    // overloaded - called whenever the table requests new data
    _loadRowData : function(firstRow, lastRow)
    {
	var sortId = null;
	var sortDirection = null;
	
	if(this.getSortColumnIndex() > -1) {
	    sortId = this.getColumnId(this.getSortColumnIndex());
	    sortDirection = this.isSortAscending() ? "ASC" : "DESC";
	}
	
	var data = this.__dbTable.getDataChunk(firstRow, lastRow, sortId, sortDirection);
	var dataMap = Array();
	
	for(var j = 0; j < data.length; j++) {
	    var map = {};

	    for(var i = 0; i < this.__dbTable.getColumnIDs().length; i++) {
		map[this.__dbTable.getColumnIDs()[i]] = data[j][i];
	    }
	    dataMap.push(map);
	}
	
	this._onRowDataLoaded(dataMap);
    }
  }
});
