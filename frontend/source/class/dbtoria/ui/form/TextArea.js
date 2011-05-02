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
    include : [ dbtoria.ui.form.MControlSetter, dbtoria.ui.form.MControlProperties ],

    /**
     * Create a customized TextArea.
     *
     */
    construct : function() {
        this.base(arguments);
        // default tooltip
        this.set({
            toolTip: new qx.ui.tooltip.ToolTip(qx.locale.Manager.tr('Use Ctrl-Enter for line breaks.')),
            liveUpdate: true
        });
    },

    members : {
        validator: function(value,control) {
            if (value == null && !control.getRequired()) {
                control.setValid(true);
                return true;
            }
            var msg = qx.locale.Manager.tr('This field must be a string.');
            var valid = qx.lang.Type.isString(value);
            if (!valid){
                control.setInvalidMessage(msg);
                control.setValid(valid);
            }
            return valid;
        }
    }

});
