/* ************************************************************************
   Copyright: 2009 OETIKER+PARTNER AG
   License:   GPLv3 or later
   Authors:   Tobi Oetiker <tobi@oetiker.ch>
              Fritz Zaucker <fritz.zaucker@oetiker.ch?
   Utf8Check: äöü
************************************************************************ */

/* ************************************************************************
************************************************************************ */

qx.Class.define("dbtoria.ui.form.TextArea", {
    extend : qx.ui.form.TextArea,

    /**
     * @param formDesc {formDescription[]} Form description array.
     *
     * Create a customized TextArea.
     *
     */
    construct : function(tooltip) {
        this.base(arguments);
        if (tooltip) {
            this.setToolTip(tooltip);
        }
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
