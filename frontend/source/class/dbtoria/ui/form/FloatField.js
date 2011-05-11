/* ************************************************************************
   Copyright: 2009 OETIKER+PARTNER AG
   License:   GPLv3 or later
   Authors:   Tobi Oetiker <tobi@oetiker.ch>
              Fritz Zaucker <fritz.zaucker@oetiker.ch?
   Utf8Check: äöü
************************************************************************ */

/* ************************************************************************
************************************************************************ */

qx.Class.define("dbtoria.ui.form.FloatField", {
    extend : qx.ui.form.TextField,
    include : [ dbtoria.ui.form.MControlSetter, dbtoria.ui.form.MControlProperties ],

    /**
     * Create a customized TextField for floating point numbers.
     */
    construct : function() {
        this.base(arguments);
    },

    members : {
        validator: function(value,control) {
            if (value == null && !control.getRequired()) {
                control.setValid(true);
                return true;
            }
            var msg = qx.locale.Manager.tr('This field must be a number.');
            var valid = (value != null) && (value != '') && !isNaN(Number(value));
            if (!valid){
                control.setInvalidMessage(msg);
                control.setValid(valid);
            }
            return valid;
        }
    }

});
