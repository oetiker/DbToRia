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

qx.Class.define("dbtoria.window.Desktop", {
    extend: qx.ui.window.Desktop,
    type: "singleton",

    /*
    *****************************************************************************
	CONSTRUCTOR
    *****************************************************************************
    */    
    construct: function() {
        this.base(arguments,new qx.ui.window.Manager());
    }
});
