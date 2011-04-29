/* ************************************************************************
   Copyright: 2009 OETIKER+PARTNER AG
   License:   GPLv3 or later
   Authors:   Tobi Oetiker <tobi@oetiker.ch>
              Fritz Zaucker <fritz.zaucker@oetiker.ch?
   Utf8Check: äöü
************************************************************************ */

/* ************************************************************************
************************************************************************ */

qx.Class.define("dbtoria.ui.form.DateField", {
    extend : qx.ui.form.DateField,

    /**
     * @param tooltip {String} optional tooltip text.
     *
     * Create a customized DateField.
     *
     */
    construct : function(tooltip) {
        this.base(arguments);
        if (tooltip) {
            this.setToolTip(new qx.ui.tooltip.ToolTip(tooltip));
        }
        this.set({allowGrowX : false});
    },

    members : {
        setter: function(value) {
            if (value == null) {
                this.setValue(value);
            }
            else {
                this.setValue(new Date(value));
            }
        }
    }

});
