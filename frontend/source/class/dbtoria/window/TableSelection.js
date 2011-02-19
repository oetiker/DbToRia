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
 * This class provides a window to choose a table
 *
 * The database is asked for all available tables. A list of buttons is
 * generated and a click on them opens the detailled TableView. 
 */
qx.Class.define("dbtoria.window.TableSelection", {
    extend: qx.ui.window.Window,
    
    /*
    *****************************************************************************
	CONSTRUCTOR
    *****************************************************************************
    */
    
    construct: function(application, showViews) {

	// call super class
	if(showViews) {
	    this.base(arguments, this.tr("View Selection"));
	    this.moveTo(170, 0);
	}
	else {
	    this.base(arguments, this.tr("Table Selection"));
	}
	
	// disable window resizing and moving
	this.set({
	    showMaximize: false,
	    showMinimize: false,
	    resizable: false,
	    showClose: false,
	    contentPadding: 20,
	    minWidth: 150,
	    margin: 20
	});
    
	// layout properties
	var layout = new qx.ui.layout.Grid(20, 5);
	layout.setColumnAlign(0, "right", "middle");
	layout.setColumnFlex(0, 1);
    
	this.setLayout(layout);
    
	var rpc = dbtoria.communication.Rpc.getInstance()
    
	try {
	    
	    // fetch tables from database
	    if(showViews) {
		var result = rpc.callSync("getViews");
	    }
	    else {
		var result = rpc.callSync("getTables");
	    }
	    
	    var tableLabel = null;
	    var skipped = 0;
	    
	    // generate a button for each table
	    for (var i = 0; i < result.tables.length; i++) {
		
		if(!result.tables[i].name) {
		    result.tables[i].name = result.tables[i].id
		}
		
		tableButton= new qx.ui.form.Button(result.tables[i].name);
		tableButton.setValue(result.tables[i].id);
		
		if(result.tables[i].id[0] != '_') {
		    this.add(tableButton, { row: (i - skipped), column: 0 });
		}
		else {
		    skipped++;
		}
	       
		// on click open table view
		tableButton.addListener("click", function(e) {
		    new dbtoria.window.Table(this.getValue(), this.getLabel(), application);
		});
	    }

	    // add the window to desktop, this way it doesn't overlap with
	    // taskbar and toolbar
	    application.getDesktop().add(this);
	    this.open();
	    
	} catch(e) {
	    var errorDialog = dbtoria.dialog.Error.getInstance();
	    errorDialog.showError("Connection to remote server failed: " + e);
	}
    }
});