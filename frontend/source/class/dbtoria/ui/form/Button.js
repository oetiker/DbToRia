/* ************************************************************************
   Copyright: 2009 OETIKER+PARTNER AG
   License:   GPLv3 or later
   Authors:   Tobi Oetiker <tobi@oetiker.ch>
              Fritz Zaucker <fritz.zaucker@oetiker.ch?
   Utf8Check: äöü
************************************************************************ */

/* ************************************************************************
************************************************************************ */

qx.Class.define("dbtoria.ui.form.Button", {
    extend : qx.ui.form.Button,

    /**
     * @param formDesc {formDescription[]} Form description array.
     *
     * Create a customized button.
     *
     */
    construct : function(label, icon, tooltip) {
        this.base(arguments);
        var tt = new qx.ui.tooltip.ToolTip(tooltip);
        this.set({ allowGrowX : false,
                   allowGrowY : false,
                   icon       : icon,
                   label      : label,
                   toolTip    : tt
                 });
    },

    members : {
    }

});
