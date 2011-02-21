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
#asset(qx/icon/${qx.icontheme}/22/actions/format-justify-left.png)
#asset(qx/icon/${qx.icontheme}/16/status/dialog-error.png)

************************************************************************ */

/**
 * This class provides the filter functionality in the table window
 *
 * This filter allows the user to restrict the displayed rows using
 * a search key for each column. All criteria are joined using AND.
 * 
 * This may be improved in various ways (OR, brackets...) for better
 * selectabilty but its difficult to find a user friendly way to display these
 * options.
 */
qx.Class.define("dbtoria.window.TableFilter", {
    extend: qx.ui.container.Composite,

    /*
    *****************************************************************************
	CONSTRUCTOR
    *****************************************************************************
    
    * @param tableWindow {dbtoria.window.Table} The table window the filter is applied to
    * @param dbTable {dbtoria.db.Table} The db table model the filter is applied to
    */
    construct: function(tableWindow, dbTable) {
	
	// call super class
	this.base(arguments);
	
	// save references
	this.__tableWindow 	= tableWindow;
	this.__dbTable 		= dbTable;
	
	this.__selection = new Array();
	
	this.setLayout(new qx.ui.layout.Grid(5, 5));
	
	this.set({
	    padding: 10
	});

	this.addSelectionProperty();
    },
    
    /*
    *****************************************************************************
	MEMBERS
    *****************************************************************************
    */
    
    members: {
	
	// db table
	__dbTable: null,
	
	// used to add and remove filter criteria
	__rowCounter: 0,
	
	// array containing references to all criteria
	__selection: null,
	
	/**
	* Add another filter critera
	*
	* This function generates another row in the filter panel.
	* It contains a checkbox to activate/deactivate a filter,
	* a selectbox to choose which to column to search in and a
	* checkbox to enter the search string.
	*/
	addSelectionProperty: function() {
	    
	    
	    var checkBox = new qx.ui.form.CheckBox();
	    checkBox.setChecked(true);
	    
	    var selectBox = new qx.ui.form.SelectBox();
	    
	    // generate list of columns
	    for(var i = 0; i < this.__dbTable.getTableStructure().length; i++) {
		var column = this.__dbTable.getTableStructure()[i];
		
		var listItem = new qx.ui.form.ListItem(column.name, null, column.id);
		selectBox.add(listItem);
	    }
		
	    var textField = new qx.ui.form.TextField();
	    textField.setWidth(200);
	    
	    this.getLayout().setRowAlign(this.__rowCounter, "left", "middle");
	    this.getLayout().setColumnFlex(3, 1);
	    
	    this.add(checkBox, {row: this.__rowCounter, column: 0});
	    this.add(selectBox, {row: this.__rowCounter, column: 1});
	    this.add(textField, {row: this.__rowCounter, column: 2});
	    
	    var refreshButton = new qx.ui.form.Button(this.tr("Refresh Filter"));
	    var addButton = new qx.ui.form.Button(this.tr("Add Critera"));
	    
	    // on clicking the filter refresh button the tableWindow
	    // is updated with the current filter
	    refreshButton.addListener("execute", function(e) {
		this.__tableWindow.updateFilter(this.getFilter());
	    }, this);
	    
	    addButton.addListener("execute", function(e) {
		this.tableFilter.addSelectionProperty();
		this.addButton.destroy();
		this.refreshButton.destroy();
	    }, { tableFilter: this, addButton: addButton, refreshButton: refreshButton });
	    
	    this.add(refreshButton, {row: this.__rowCounter, column: 4});
	    this.add(addButton, {row: this.__rowCounter, column: 5});

	    this.__selection.push({selectBox: selectBox, textField: textField, checkBox: checkBox});
	    this.__rowCounter++;
	    
	    
	},
	
	/**
	* Return current filter
	*
	* This function returns an array of search column and value pairs.
	*/
	getFilter: function() {
	    var filter = new Array();
	    
	    for(var i = 0; i < this.__selection.length; i++) {
		var selection = this.__selection[i];
		if(selection.checkBox.isChecked()) {
		    
		    var tmp = {};
		    tmp[selection.selectBox.getValue()] = selection.textField.getValue();
		    
		    filter.push(tmp);
		}
		filter.push();
	    }
	    
	    //qx.dev.Debug.debugObject(filter);
	    
	    return filter;
	}
    }

});
