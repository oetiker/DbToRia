/* ************************************************************************
   Copyright: 2009 OETIKER+PARTNER AG
   License:   GPLv3 or later
   Authors:   Tobi Oetiker <tobi@oetiker.ch>
              Fritz Zaucker <fritz.zaucker@oetiker.ch?
   Utf8Check: äöü
************************************************************************ */

/* ************************************************************************
************************************************************************ */

qx.Class.define("dbtoria.ui.form.FloatTimeField", {
    extend : qx.ui.form.TextField,
    include : [ dbtoria.ui.form.MControlSetter, dbtoria.ui.form.MControlProperties ],

    /**
     * Create a customized TextField for time entries.
     * Converts times in hh:mm:ss format to decimal.
     */
    construct : function() {
        this.base(arguments);
        this.set({
            toolTip: new qx.ui.tooltip.ToolTip(qx.locale.Manager.tr('Use either decimal or hh:mm::ss format.'))
        });
    },

    members : {
        validator: function(value,control) {
            if (value == null && !control.getRequired()) {
                control.setValid(true);
                return true;
            }
            var regex = /(\d*?):(\d+)/;
            var res;
            if (qx.lang.Type.isString(value) && (res = regex.exec(value)) ) {
                this.debug('res='+res);
                var h = res[1];
                var m = res[2];
                var s=0;
                if ((res = regex.exec(m))) {
                    m = res[1];
                    s = res[2];
                }
                value = h+m/60+s/3600;
            }
            this.debug('value='+value);
            var msg = qx.locale.Manager.tr('This field must be a number.');
            var valid = (value != null) && !isNaN(Number(value));
            if (!valid){
                control.setInvalidMessage(msg);
                control.setValid(valid);
            }
            return valid;
        }
    }

});
