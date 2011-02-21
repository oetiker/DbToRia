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
    
    construct: function(showViews) {
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
	    var layout = new qx.ui.layout.VBox(5);
    	this.setLayout(layout);
    
	    var rpc = dbtoria.communication.Rpc.getInstance()
        var that = this;    
        rpc.callAsyncSmart(function(ret){
    	    // generate a button for each table
	        for (var i = 0; i < ret.length; i++) {(function(){
                var table = ret[i];
    		    if ( ! table.name ) {
                    table.name = table.id
                }            
                var tableButton= new qx.ui.form.Button(table.name);
                that.add(tableButton);
                // on click open table view
                var desktop = dbtoria.window.Desktop.getInstance();
                tableButton.addListener("click", function(e) {
                    desktop.add(new dbtoria.window.Table(table.id,table.name));
                },this);
	        })()}
        }, showViews ? 'getViews' : 'getTables');
    }
});
