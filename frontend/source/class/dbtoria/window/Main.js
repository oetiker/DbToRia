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
 * This class provides the main window for dbtoria.
 *
 * The main window consists of a menu bar, a desktop where the windows are
 * located and a taskbar where minimized windows are held.
 */
qx.Class.define("dbtoria.window.Main", {
    extend: qx.ui.container.Composite,

    /*
    *****************************************************************************
	CONSTRUCTOR
    *****************************************************************************
    */
    
    construct: function() {
        var containerLayout = new qx.ui.layout.VBox();
        containerLayout.setSeparator("separator-vertical");
        this.base(arguments,containerLayout);

       
    	// the desktop area is the largest part of dbtoria, make sure it is
    	// scrollable
	    var desktopContainer = new qx.ui.container.Scroll()
     
    	// the desktop holds all other windows
	    var desktop = dbtoria.window.Desktop.getInstance();

    	desktopContainer.add(desktop, { width: '100%', height: '100%'});
	
    	var toolbar = new qx.ui.toolbar.ToolBar();
    	this.add(toolbar);

        this.add(desktopContainer, { flex: 1 });

    	var taskbar = dbtoria.window.Taskbar.getInstance();
    	this.add(taskbar);

    	// toolbar
    	var spacer = toolbar.addSpacer();
    	spacer.setMaxWidth(10);
	
    	var tableSelectionBtn = new qx.ui.toolbar.CheckBox(this.tr("Table Selection"), "icon/22/actions/format-justify-left.png");
    	toolbar.add(tableSelectionBtn);
	
    	var viewSelectionBtn = new qx.ui.toolbar.CheckBox(this.tr("View Selection"), "icon/22/actions/format-justify-left.png");
    	toolbar.add(viewSelectionBtn);
	
    	toolbar.addSpacer();
	
	    var logoutBtn = new qx.ui.toolbar.Button(this.tr("logout"), "icon/16/status/dialog-error.png");
	
    	toolbar.add(logoutBtn);
	
	    // on a click on the table selection button the table selection window is shown, on the next
    	// click it is hidden
        var tableSelection = new dbtoria.window.TableSelection(false);
        tableSelection.close();
        desktop.add(tableSelection);

	    tableSelectionBtn.addListener("changeValue", function(e) {
	        if ( e.getTarget().isValue()) {
                tableSelection.open();
    	    }
	        else {
                tableSelection.close();
	        }
    	}, this);
	
    	// on a click on the view selection button the view selection window is shown, on the next
	    // click it is hidden
        var viewSelection = new dbtoria.window.TableSelection(true);
        viewSelection.close();
        desktop.add(viewSelection);
	    viewSelectionBtn.addListener("changeValue", function(e) {
	        if ( e.getTarget().isValue() ) {
        		viewSelection.open();
            }
    	    else {
	        	viewSelection.close();
    	    }
	    }, this);
    
    	// call logout on the backend to destroy session
	    logoutBtn.addListener("execute", function(e) {
	        var rpc = dbtoria.communication.Rpc.getInstance();
            rpc.callAsyncSmart(function() {
                window.location.href = window.location.href;
            }, 'logout');
    	}, this);
	
	    var spacer = toolbar.addSpacer();
    	spacer.setMaxWidth(10);
	    
    	tableSelectionBtn.setValue(true);
    }
});
