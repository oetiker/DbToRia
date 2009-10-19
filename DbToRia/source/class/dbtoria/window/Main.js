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
#asset(icon/22/actions/format-justify-left.png)
#asset(icon/16/status/dialog-error.png)

************************************************************************ */

/**
 * This class provides the main window for dbtoria.
 *
 * The main window consists of a menu bar, a desktop where the windows are
 * located and a taskbar where minimized windows are held.
 */
qx.Class.define("dbtoria.window.Main", {
    extend: qx.core.Object,

    /*
    *****************************************************************************
	CONSTRUCTOR
    *****************************************************************************
    */
    
    construct: function(application) {

	// save reference to application root
	this.__application = application;
    
	// use vertical layout with small separator
	var containerLayout = new qx.ui.layout.VBox();
	containerLayout.setSeparator("separator-vertical");
	
	var container = new qx.ui.container.Composite(containerLayout);
    
	var toolbar = new qx.ui.toolbar.ToolBar();
	var taskbar = new qx.ui.toolbar.ToolBar();
       
	// the desktop area is the largest part of dbtoria, make sure it is
	// scrollable
	var desktopContainer = new qx.ui.container.Scroll()
     
	// the desktop holds all other windows
	var desktop = new qx.ui.window.Desktop(new qx.ui.window.Manager());

	desktopContainer.add(desktop, { width: "100%", height: "100%"});
	
	container.add(toolbar);
	container.add(desktopContainer, { flex: 1 });
	container.add(taskbar);
    
	application.setDesktop(desktop);
	application.setTaskbar(taskbar);
	application.getRoot().add(container, { edge: 0 } );
    
	// toolbar
	var spacer = toolbar.addSpacer();
	spacer.setMaxWidth(10);
	
	var tableSelection = new qx.ui.toolbar.CheckBox(application.tr("Table Selection"), "icon/22/actions/format-justify-left.png");
	toolbar.add(tableSelection);
	
	var viewSelection = new qx.ui.toolbar.CheckBox(application.tr("View Selection"), "icon/22/actions/format-justify-left.png");
	toolbar.add(viewSelection);
	
	toolbar.addSpacer();
	
	var logoutButton = new qx.ui.toolbar.Button(application.tr("logout"), "icon/16/status/dialog-error.png");
	
	toolbar.add(logoutButton);
	
	// on a click on the table selection button the table selection window is shown, on the next
	// click it is hidden
	tableSelection.addListener("changeChecked", function(e) {
	    if(this.__tableSelection == null) {
		this.__tableSelection = new dbtoria.window.TableSelection(this.__application, false);
	    }
	    if(e.getTarget().isChecked()) {
		this.__tableSelection.show();
	    }
	    else {
		this.__tableSelection.close();
	    }
	}, this);
	
	// on a click on the view selection button the view selection window is shown, on the next
	// click it is hidden
	viewSelection.addListener("changeChecked", function(e) {
	    if(this.__viewSelection == null) {
		this.__viewSelection = new dbtoria.window.TableSelection(this.__application, true);
	    }
	    if(e.getTarget().isChecked()) {
		this.__viewSelection.show();
	    }
	    else {
		this.__viewSelection.close();
	    }
	}, this);
    
	// call logout on the backend to destroy session
	logoutButton.addListener("execute", function(e) {
	    var rpc = dbtoria.communication.Rpc.getInstance();
	
	    try {
		var result = rpc.callSync("logout");
	    }
	    catch(e) { alert(e) };
	    
	    window.location.reload();
	}, this);
	
	var spacer = toolbar.addSpacer();
	spacer.setMaxWidth(10);
	
	tableSelection.setChecked(true);
    },
    
    /*
    *****************************************************************************
	MEMBERS
    *****************************************************************************
    */
    
    members: {
	
	// window to select a table from
	__tableSelection: null,
	__viewSelection: null,
	
	// application reference (root)
	__application: null
    }

});