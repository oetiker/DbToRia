/* ************************************************************************
   Copyright: 2009 OETIKER+PARTNER AG
   License:   GPLv3 or later
   Authors:   Tobi Oetiker <tobi@oetiker.ch>
              Fritz Zaucker <fritz.zaucker@oetiker.ch?
   Utf8Check: äöü
************************************************************************ */

/* ************************************************************************
************************************************************************ */

qx.Class.define("dbtoria.ui.form.TextField", {
    extend : qx.ui.form.TextField,

    /**
     * @param tooltip {String} optional tooltip text.
     *
     * Create a customized TextField.
     *
     */
    construct : function(tooltip) {
        this.base(arguments);
        if (tooltip) {
            this.setToolTip(new qx.ui.tooltip.ToolTip(tooltip));
        }
//        this.set({});
    },

    members : {
        setter: function(value) {
            if (value == null) {
                this.setValue(value);
            }
            else {
                this.setValue(String(value));
            }
        }
    }

});
