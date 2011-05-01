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
     * Converts times in hh:mm format to decimal.
     */
    construct : function() {
        this.base(arguments);
    },

    members : {
        validator: function() {
            return function(value,control){
                if (value == null && !control.getRequired()) {
                    control.setValid(true);
                    return true;
                }
                var regex = /(\d*):(\d+)/;
                var res;
                if (qx.lang.Type.isString(value) && (res = regex.exec(value)) ) {
                  this.debug('res='+res);
                    value = Number(res[1]) + Number(res[2])/60;
                }
                this.debug('value='+value);
                var msg = qx.locale.Manager.tr('This field must be a number.');
                var valid = (value != null) && !isNaN(Number(value));
                if (!valid){
                    control.setInvalidMessage(msg);
                    control.setValid(valid);
                    }
                return valid;
            };
        }
    }

});
