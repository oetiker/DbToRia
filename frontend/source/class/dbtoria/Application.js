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


/**
 * This is the main application class of "DbToRia"
 */
qx.Class.define("dbtoria.Application", {
    extend : qx.application.Standalone,


    members : {
        /**
         * This method contains the initial application code and gets called
         *  during startup of the application
         *
         * @return {void}
         */
        main : function() {
            // call super class
            this.base(arguments);

            // Enable logging in debug variant
            if ((qx.core.Environment.get("qx.debug"))) {
                // support native logging capabilities, e.g. Firebug for Firefox
                qx.log.appender.Native;

                // support additional cross-browser console. Press F7
                // to toggle visibility
                qx.log.appender.Console;
            }

            var root = this.getRoot();

//            loginWindow.addListenerOnce('login', function() {
                root.add(new dbtoria.window.Main(), { edge : 0 });
//            }, this);

//          var loginWindow = dbtoria.dialog.Login.getInstance();
//          loginWindow.open();
        }
    }
});
