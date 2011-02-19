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
 * This is the main application class of "DbToRia"
 */
qx.Class.define("dbtoria.Application", {
    extend: qx.application.Standalone,
    
    /*
    *****************************************************************************
       MEMBERS
    *****************************************************************************
    */
    
    members: {
	/**
	 * This method contains the initial application code and gets called 
	 * during startup of the application
	 */
	main: function() {
	    
	    // call super class
	    this.base(arguments);

	    // enable logging in debug variant
	    if (qx.core.Variant.isSet("qx.debug", "off")) {
		// support native logging capabilities, e.g. Firebug for Firefox
		qx.log.appender.Native;
		// support additional cross-browser console. Press F7 to toggle visibility
		qx.log.appender.Console;
	    }
	
	    // ask server if user has a running session
	    var rpc = dbtoria.communication.Rpc.getInstance()
      
	    try {
		var result = rpc.callSync("authenticate");
      
		// if user has running session display MainWindow
		if (result.messageType == "answer" && result.message == "ok") {
		    new dbtoria.window.Main(this);
		}
		else {
		    // otherwise let him login
		    var loginWindow = new dbtoria.window.Login(this);
		    loginWindow.open();
		}
	    } catch(e) {
		var errorDialog = dbtoria.dialog.Error.getInstance();
		errorDialog.showError("Connection to remote server failed: " + e);
	    }
	},
	
	// Desktop is the main area where new windows are placed 
	__desktop: null,
	
	// On the taskbar minimized windows are shown 
	__taskbar: null,
	
	/**
	* Get the desktop object
	*
	* @return {Desktop} Desktop object to place new windows on
	*/
	getDesktop: function() {
	    return this.__desktop;
	},
	
	/**
	* Set the desktop object
	*
	* @param desktop {Desktop} Desktop object to place new windows on
	*/
	setDesktop: function(desktop) {
	    this.__desktop = desktop;
	},
	
	/**
	* Get the taskbar
	*
	* @return {Toolbar} Taskbar for minimized windows
	*/
	getTaskbar: function() {
	    return this.__taskbar;
	},
	
	/**
	* Set the taskbar
	*
	* @param taskbar {Toolbar} Taskbar for minimized windows
	*/
	setTaskbar: function(taskbar) {
	    this.__taskbar = taskbar;
	}
    }
});