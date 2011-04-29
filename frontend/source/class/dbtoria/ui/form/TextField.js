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
     * @param formDesc {formDescription[]} Form description array.
     *
     * Create a customized button.
     *
     */
    construct : function(tooltip) {
        this.base(arguments);
        var tt = new qx.ui.tooltip.ToolTip(tooltip);
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
