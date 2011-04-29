/* ************************************************************************
   Copyright: 2009 OETIKER+PARTNER AG
   License:   GPLv3 or later
   Authors:   Tobi Oetiker <tobi@oetiker.ch>
              Fritz Zaucker <fritz.zaucker@oetiker.ch?
   Utf8Check: äöü
************************************************************************ */

/* ************************************************************************
************************************************************************ */

qx.Class.define("dbtoria.ui.form.CheckBox", {
    extend : qx.ui.form.CheckBox,

    /**
     * @param formDesc {formDescription[]} Form description array.
     *
     * Create a customized CheckBox.
     *
     */
    construct : function(tooltip) {
        this.base(arguments);
        if (tooltip) {
            this.setToolTip(tooltip);
        }
        this.set({allowGrowX : false});
    },

    members : {
        setter: function(value) {
            if (value == null) {
                this.setValue(false);
            }
            else {
                this.setValue(value);
            }
        }
    }

});
