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
    properties: {
        overflowMenu: {}
    },
    members : {
        addOverflow: function() {
            this.setOverflowMenu( new qx.ui.menu.Menu() );
            var overflowBtn = new qx.ui.toolbar.MenuButton("More ...").set({
                menu: this.getOverflowMenu()
            });
            this.add(overflowBtn);
            this.set({
                overflowIndicator: overflowBtn,
                overflowHandling: true
            });

            overflowBtn.addListener('appear',function(){
                var pane = this.getLayoutParent();
                this.fireDataEvent('resize', pane.getBounds());
            },this);
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
