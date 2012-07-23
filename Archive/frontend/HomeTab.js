/* ************************************************************************

  DbToRia - Database to Rich Internet Application

  http://www.dbtoria.org

   Copyright:
    2009 David Angleitner, Switzerland
    2011 Oetiker+Partner AG, Olten, Switzerland

   License:
    GPL: http://www.gnu.org/licenses/gpl-2.0.html

   Authors:
    * David Angleitner
    * Fritz Zaucker
    * Tobi Oetiker (oetiker) <tobi@oetiker.ch>

************************************************************************ */

qx.Class.define("dbtoria.module.desktop.HomeTab", {
    extend : qx.ui.tabview.Page,
    type : "singleton",

    construct : function() {
        this.base(arguments);
	this.setLabel(this.tr('Home'));
    }

});
