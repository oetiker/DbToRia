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
    include : [ dbtoria.ui.form.MControlProperties ],

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
    statics : {
        __time2float: function(value) {
            var res;
            var regex = /^(\d*?):(?:(\d+)|(\d+):(\d+))$/;
            qx.log.Logger.debug('input='+value);
            if (qx.lang.Type.isString(value) && (res = regex.exec(value)) ) {
                qx.log.Logger.debug('res='+res);
                var s, m, h = res[1];
                if (res[3] != undefined) {
                    m = Number(res[3]);
                    s = Number(res[4]);
                }
                else {
                  s = 0;
                  m = Number(res[2]);
                }
                qx.log.Logger.debug('h='+h+', m='+m+', s='+s);
                value = (h*3600+m*60+s)/3600;
                qx.log.Logger.debug('output='+value);
            }
            return value;
        }
    },

    members : {
        validator: function(value,control) {
            if (value == null && !control.getRequired()) {
                control.setValid(true);
                return true;
            }
            value = dbtoria.ui.form.FloatTimeField.__time2float(value);
//            this.debug('value='+value);
            var msg = qx.locale.Manager.tr('This field must be a number.');
            var valid = (value != null) && !isNaN(Number(value));
            if (!valid){
                control.setInvalidMessage(msg);
                control.setValid(valid);
            }
            return valid;
        },

        setFormDataCallback: function(name, callback) {
            this.addListener('changeValue', function(e) {
                var value = dbtoria.ui.form.FloatTimeField.__time2float(e.getData());
                callback(name, value);
            }, this);
        },

        defaults: function(value) {
            if (this.getValue() != null) {
                return;
            }
            this.setter(value);
        },

        setter: function(value) {
            if (value == null) {
                this.setValue(value);
            }
            else {
                var h = String(Math.floor(value));
                value *= 3600;
                var s = value % 3600;
                var m = String(Math.floor(s/60));
                s = String(s % 60);
                this.debug('m='+m+', m.length='+m.length);
                this.debug('m='+m+', m.length='+m.length);
                if (m.length<2) {
                    m = '0'+m;
                }
                if (s.length<2) {
                    s = '0'+s;
                }
                this.setValue(h+':'+m+':'+s);
            }
        },

        clear: function() {
            this.setValue(null);
        }

    }

});
