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
    include : [ dbtoria.ui.form.MControlSetter ],

    /**
     * Create a customized TextField.
     *
     */
    construct : function() {
        this.base(arguments);
    },

    members : {
        validator: function() {
            return function(value,control){
                        var msg = qx.locale.Manager.tr('This field must be a string.');
                        var valid = (qx.lang.Type.isString(value) || value == null);
                        if (!valid){
                            control.setInvalidMessage(msg);
                            control.setValid(valid);
                        }
                        return valid;
                   };
        }
    }

});
