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
    * Tobias Oetiker
    * Fritz Zaucker

************************************************************************ */

/* ************************************************************************

#asset(dbtoria/*)
#asset(qx/icon/${qx.icontheme}/16/mimetypes/text-plain.png)

************************************************************************ */

/**
 * This class provides the basic functionality of DBToRia desktop windows:
 *
 * - Minimization of window to taskbar
 * - Adding window to bookmark bar (not yet implemented)
 * - Loading indicator
 */
qx.Class.define("dbtoria.module.desktop.Page", {
    extend : qx.ui.tabview.Page,
    construct : function() {
        this.base(arguments);
	this.setShowCloseButton(true);
        dbtoria.module.desktop.Desktop.getInstance().add(this);
    },

    properties: {
        loading: {
            init : false,
            check: 'Boolean',
            apply: '_applyLoading'
        }
    },

    members : {
        __runningTimer: null,
        _createChildControlImpl : function(id, hash){
            var control;
            switch(id) {
                case "stack":
                    control = new qx.ui.container.Composite().set({
                        layout: new qx.ui.layout.Grow(),
                        allowGrowX: true,
                        allowGrowY: true
                    });
                    this._add(control, {flex: 1});
                    break;
                case "pane":
                    control = new qx.ui.container.Composite();
                    this.getChildControl('stack').add(control);
                    break;
                case "loader":
                    control = new qx.ui.basic.Atom(null,"dbtoria/loader.gif").set({
                        visibility: 'hidden',
                        show: 'icon',
                        backgroundColor: '#fcfcfc',
                        opacity: 0.7,
                        allowGrowX: true,
                        allowGrowY: true,
                        alignX: 'center',
                        alignY: 'middle',
                        center: true
                    });
                    this.getChildControl('pane'); // make sure pane is created first!
                    this.getChildControl('stack').add(control);
                    break;
            }
            return control || this.base(arguments, id, hash);
        },

        _applyLoading: function(newValue,oldValue){
            if (newValue == oldValue){
                return;
            }
            if (newValue){                                
                this.__runningTimer = qx.event.Timer.once(function(){
                    this.__runningTimer = null;
                    this.getChildControl('loader').show();
                },this,200);
//              this.__runningTimer.start();
            }
            else {
                if (this.__runningTimer){
                    this.__runningTimer.stop();
                    this.__runningTimer = null;
                }
                this.getChildControl('loader').hide();
            }
        }
    }

});
