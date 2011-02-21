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
        		qx.log.appender.Native;
	        	qx.log.appender.Console;
    	    }
            var loginWindow = dbtoria.dialog.Login.getInstance();
            var root = this.getRoot();
            loginWindow.addListenerOnce('login',function(){
                root.add(new dbtoria.window.Main(),{edge: 0}); 
            },this);

            loginWindow.open();
        }
	}
});
