/* ************************************************************************

  DbToRia - Database to Rich Internet Application

  http://www.dbtoria.org

   Copyright:
    2011 Oetiker+Partner AG, Olten, Switzerland

   License:
    GPL: http://www.gnu.org/licenses/gpl-2.0.html

   Authors:
    * Fritz Zaucker

************************************************************************ */

qx.Class.define("dbtoria.module.desktop.AutoToolbar", {
    extend : qx.ui.toolbar.ToolBar,
//    type : "singleton",

    construct : function() {
        this.base(arguments);
            // handler for showing and hiding toolbar items
            this.addListener("showItem", function(e) {
                this.__showItem(e.getData());
            }, this);

            this.addListener("hideItem", function(e) {
                this.__hideItem(e.getData());
            }, this);
    },

    members : {
        _overflowMenu: null,

        addOverflow: function() {
            var overflow = new qx.ui.toolbar.MenuButton("More ...");
            this.add(overflow);
            this.set({
                spacing: 5,
                overflowIndicator: overflow,
                overflowHandling: true
            });

            var overflowMenu = this._overflowMenu = new qx.ui.menu.Menu();
            overflow.setMenu(overflowMenu);
            return overflow;
        },

        __showItem: function(item) {
            item.show();
            item.getUserData('menuBtn').exclude();
        },

        __hideItem: function(item) {
            item.exclude();
            item.getUserData('menuBtn').show();
        }

    }
});
