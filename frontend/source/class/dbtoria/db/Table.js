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
 * DbTable
 *
 * This class is used as the interface to communicate with the database.
 * It provides all functions to interact with the DB (CRUD).
 */
qx.Class.define("dbtoria.db.Table", {
    extend: qx.core.Object,
    
    /*
    *****************************************************************************
	CONSTRUCTOR
    *****************************************************************************
    */
    
    construct: function(tableName) {
	this.__tableName = tableName;
	this.__rpc = dbtoria.communication.Rpc.getInstance();
    },
    
    /*
    *****************************************************************************
       MEMBERS
    *****************************************************************************
    */
    
    members: {
	
	// the table name in the databse
	__tableName: null,
	
	// dbtoria.communication.Rpc object to query database
	__rpc: null,
	
	// number of columns in the table
	__numColumns: null,
	
	// object containing all table structure
	// see api for detail info
	__tableStructure: null,
	
	// number of rows in the table
	__numRows: null,
	
	// array containing dbtoria.db.Table objects
	// for referenced tables
	__referencedTables: null,
	
	// a dbtoria.window.TableFilter object to filter the data
	__filter: null,
	
	/**
	* Fetch table structure from database
	* See API for detailed info on the format
	*/
	getTableStructure: function() {
	    if(!this.__tableStructure) {
		try {
		    var result = this.__rpc.callSync("getTableStructure", this.__tableName);		
		    
		    // if no name is provided fill with id
		    for(var i = 0; i < result.structure.length; i++) {
			if(!result.structure[i].name) {
			    result.structure[i].name = result.structure[i].id
			}
		    }
		    
		    this.__tableStructure = result.structure;
		    
		} catch(e) {
		    var errorDialog = dbtoria.dialog.Error.getInstance();
		    errorDialog.showError("Connection to remote server failed: " + e);
		}
	    }
	    return this.__tableStructure;
	},
	
	/**
	* Gets the table structure of a column by ID
	*
	* @param column {Integer} Number of the column
	*/
	getColumn: function(column) {
	    return this.__tableStructure[column];
	},
	
	/**
	* Returns the ID of a column selected by name
	*
	* @param columnName {String} The column name
	*/
	getColumnIndexByName: function(columnName) {
	    for(var i = 0; i < this.getTableStructure().length; i++) {
		if(this.getTableStructure()[i].id == columnName) {
		    return i;
		}
	    }
	    return null;
	},
	
	/**
	* Returns a dbtoria.db.Table object of one of the
	* referenced tables.
	* 
	* @param table {String} The referenced table's name
	*/
	getReferencedTable: function(table) {
	    if(!this.__referencedTables) {
		this.__referencedTables = Array();
	    }
	    
	    if(!this.__referencedTables[table]) {
		try {
		    this.__referencedTables[table] = new dbtoria.db.Table(table);
		} catch(e) {
		    var errorDialog = dbtoria.dialog.Error.getInstance();
		    errorDialog.showError("Connection to remote server failed: " + e);
		}
	    }
	    return this.__referencedTables[table];
	},
	
	/**
	* Fetch data from a referenced table with a selected value in a column.
	* This is a shortcut to getReferencedTable and getDataWithKey
	* 
	* @param table {String}  The referenced table's name
	* @param column {String} The column name which should contain
	* 			 the provided value
	* @param key {String}    The value searched for
	*/
	getReferencedDataForKey: function(table, column, key) {
	    return this.getReferencedTable(table).getDataWithKey(column, key);
	},
	
	/**
	* Fetch data from the table with a selected value in a column.
	* This is mainly used for resolving references to other tables.
	* 
	* @param column {String} The column name which should contain
	* 			 the provided value
	* @param key {String}    The value searched for
	*/
	getDataWithKey: function(column, key) {
	    var columnIndex = this.getColumnIndexByName(column);
	    
	    try {
		var selection = {};
		selection[column] = key;
		
		var result = this.__rpc.callSync("getTableData", this.__tableName, selection);		
		
		var data = [];

		for(var i = 0; i < result.data.length; i++) {
		    var row = {};
		    
		    for(var j = 0; j < result.data[i].length; j++) {
			row[this.getColumnNames()[j]] = result.data[i][j];
		    }
		    
		    data.push(row);
		}

		return data;
	    
	    } catch(e) {
		var errorDialog = dbtoria.dialog.Error.getInstance();
		errorDialog.showError("Connection to remote server failed: " + e);
	    }
		
	    return null;
	},
	
	
	/**
	* Sets a dbtoria.window.TableFilter object for this table
	* 
	* @param filter {dbtoria.windowTableFilter} The filter object
	*/
	setFilter: function(filter) {
	    
	    // reset number of rows so that it is recalculated on the next getNumRows request
	    this.__numRows = null;
	    
	    this.__filter = filter;
	},
	
	
	/**
	* Fetch a chunk of data from the table .
	* 
	* @param firstRow {Integer} 	The first row to select
	* @param lastRow {Integer} 	The last row to select
	* @param sortId {Integer}    	The ID of the column that is sorted by
	* @param sortDirection {String} Either "ASC" for ascending or "DESC" for descending
	*/
	getDataChunk: function(firstRow, lastRow, sortId, sortDirection) {
	    try {
		
		if(sortId) {
		    var result = this.__rpc.callSync("getTableDataChunk", this.__tableName, this.__filter, firstRow, lastRow, sortId, sortDirection);
		}
		else {
		    var result = this.__rpc.callSync("getTableDataChunk", this.__tableName, this.__filter, firstRow, lastRow);
		}
		
		// otherwise display error message
		if (result.messageType == "answer") { 
		    
		    // TODO EVIL HACK: Convert everything to string because numbers
		    // are provided as integer from james.oetiker.ch
		    // MAYBE Fixed by different JSON version?
		    for(var i = 0; i < result.data.length; i++) {
			for(j = 0; j < result.data[i].length; j++) {
			    result.data[i][j] = String(result.data[i][j]);
			}
		    }
		    
		    return result.data;
		}
		else {
		    var errorDialog = dbtoria.dialog.Error.getInstance();
	    
		    switch(result.message) {
			case "SyntaxError":
			    errorDialog.showError("SQL syntax error in '" + result.params[0] + "'");
			    break;
			
			default:
			    errorDialog.showError(result.message);
		    }
		}
	    } catch(e) {
		var errorDialog = dbtoria.dialog.Error.getInstance();
		errorDialog.showError("Connection to remote server failed: " + e);
	    }
	    
	    return null;
	},
	
	/**
	* Update table data.
	* 
	* @param selection {JSON} 	Object defining selection criteria to select
	* 				which rows to update
	* 				ex. {columnName: "value"}
	* @param data {JSON} 		The data to update the selected rows
	* 				ex. {columnName: "value"}
	*/
	updateData: function(selection, data) {
	    try {
		var result = this.__rpc.callSync("updateTableData", this.__tableName, selection, data);
		
		// otherwise display error message
		if (result.messageType == "error") {
		    
		    var errorDialog = dbtoria.dialog.Error.getInstance();
	    
		    switch(result.message) {
			case "SyntaxError":
			    errorDialog.showError("SQL syntax error in '" + result.params[0] + "'");
			    break;
			
			default:
			    errorDialog.showError(result.message);
		    }
		    
		    return false;
		}
		
	    } catch(e) {
		var errorDialog = dbtoria.dialog.Error.getInstance();
		errorDialog.showError("Connection to remote server failed: " + e);
		
		return false;
	    }
	    
	    return true;
	},
	
	/**
	* Insert data into table.
	* 
	* @param data {JSON} 		The data to insert
	* 				ex. {columnName: "value"}
	*/
	insertData: function(data) {
	    try {
		var result = this.__rpc.callSync("insertTableData", this.__tableName, data);
		
		// reset number of rows so that it is recalculated on the next getNumRows request
		this.__numRows = null;
		
		// otherwise display error message
		if (result.messageType == "error") {
		    
		    var errorDialog = dbtoria.dialog.Error.getInstance();
	    
		    switch(result.message) {
			case "SyntaxError":
			    errorDialog.showError("SQL syntax error in '" + result.params[0] + "'");
			    break;
			
			default:
			    errorDialog.showError(result.message);
		    }
		    
		    return false;
		}
		
	    } catch(e) {
		var errorDialog = dbtoria.dialog.Error.getInstance();
		errorDialog.showError("Connection to remote server failed: " + e);
		
		return false;
	    }
	    
	    return true;
	},
	
	/**
	* Delete table data.
	* 
	* @param selection {JSON} 	Object defining selection criteria to select
	* 				which rows to delete
	* 				ex. {columnName: "value"}
	*/
	deleteData: function(selection) {
	    try {
		var result = this.__rpc.callSync("deleteTableData", this.__tableName, selection);
		
		// reset number of rows so that it is recalculated on the next getNumRows request
		this.__numRows = null;
		
		// otherwise display error message
		if (result.messageType == "error") {
		    
		    var errorDialog = dbtoria.dialog.Error.getInstance();
	    
		    switch(result.message) {
			case "SyntaxError":
			    errorDialog.showError("SQL syntax error in '" + result.params[0] + "'");
			    break;
			
			default:
			    errorDialog.showError(result.message);
		    }
		    
		    return false;
		}
		
	    } catch(e) {
		var errorDialog = dbtoria.dialog.Error.getInstance();
		errorDialog.showError("Connection to remote server failed: " + e);
		
		return false;
	    }
	    
	    return true;
	},
	
	/**
	* Fetch column names from table structure
	*
	* @return {Array} Single array with all column names
	*/
	getColumnNames: function() {
	    var tableStructure = this.getTableStructure();
	    var columnNames = Array();

	    // fetch all values with key = name
	    for(var i = 0; i < tableStructure.length; i++) {
		columnNames.push(tableStructure[i].name);
	    }

	    return columnNames;
	},
	
	/**
	* Fetch column ids from table structure
	*
	* @return {Array} Single array with all column ids
	*/
	getColumnIDs: function() {
	    var tableStructure = this.getTableStructure();
	    var columnIDs = Array();

	    // fetch all values with key = name
	    for(var i = 0; i < tableStructure.length; i++) {
		columnIDs.push(tableStructure[i].id);
	    }

	    return columnIDs;
	},
	
	/**
	* Fetch primary keys from table structure
	*
	* @return {Array} 		Array containing arrays of primary_key columns:
	* 				First value is name of column, second value is position in table 
	*/
	getPrimaryKeys: function() {
	    var tableStructure = this.getTableStructure();
	    var primaryKeys = Array();
	   
	    for(var i = 0; i < tableStructure.length; i++) {
		if(tableStructure[i].primaryKey == 1) {
		    primaryKeys.push({field: tableStructure[i].id, index: i});
		}
	    }
	    
	    return primaryKeys;
	},
	
	/**
	* Return number of columns in table
	*
	* @return {Integer} Number of columns
	*/
	getNumColumns: function() {
	    if(!this.__numColumns) {
		this.__numColumns = getTableStructure().length;
	    }
	    
	    return this.__numColumns;
	},
	
	/**
	* Return number of rows in table
	*
	* @return {Integer} Number of rows in table
	* */
	getNumRows: function() {
	    
	    if(!this.__numRows) {
		try {
		    var result = this.__rpc.callSync("getNumRows", this.__tableName,  this.__filter);
		    
		    if (result.messageType == "answer") {
			this.__numRows = result.numRows;
			
		    }
		    // otherwise display error message
		    else {
			var errorDialog = dbtoria.dialog.Error.getInstance();
		
			switch(result.message) {
			    case "SyntaxError":
				errorDialog.showError("SQL syntax error in '" + result.params[0] + "'");
				break;
			    
			    default:
				errorDialog.showError(result.message);
			}
			
			return 0;
		    }
		    
		} catch(e) {
		    var errorDialog = dbtoria.dialog.Error.getInstance();
		    errorDialog.showError("Connection to remote server failed: " + e);
		    
		    return 0;
		}
	    }
	    
	    return this.__numRows;
	}
    }
});