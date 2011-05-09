/* ************************************************************************
   Copyright: 2009 OETIKER+PARTNER AG
   License:   GPLv3 or later
   Authors:   Tobi Oetiker <tobi@oetiker.ch>
              Fritz Zaucker <fritz.zaucker@oetiker.ch?
   Utf8Check: äöü
************************************************************************ */

/* ************************************************************************
************************************************************************ */

qx.Class.define("dbtoria.ui.form.AutoForm", {
    extend : qx.ui.form.Form,
    include : [ qx.locale.MTranslation ],

    /**
     * @param formDesc {formDescription[]} Form description array.
     *
     * Create a form based on a form descriptions using {@link dbtoria.ui.form.ControlBuilder}.
     *
     * Control descriptions can contain a check property with the
     * the keys 'msg' and 'rx' the rx is checked on value change
     * and the label is shown as invalid message
     *
     */
    construct : function(formDesc) {
        this.base(arguments);
        var fl            = formDesc.length;
        var controlMap    = this.__controlMap = {};
        var formData      = this.__formData   = {};
        var validationMgr = this.getValidationManager();
        for (var i=0; i<fl; i++) {
            var desc  = formDesc[i];
            var trlab = desc.label.translate ? desc.label : this['tr'](desc.label);

            var control = controlMap[desc.name] =
                dbtoria.ui.form.ControlBuilder.createControl(desc, qx.lang.Function.bind(this.__formDataCallback, this));

            if (desc.hasOwnProperty('required') && desc.required) {
                control.set({
                    required: true,
                    requiredInvalidMessage: this.tr('This field is required')
                });
            }
            this.add(control, trlab, null, desc.name);

            // The validator defined in the control (can't do it in control as its
            // validation manager is only know after its added to the form).
            //
            // Alternatively, the validationMgr could be passed to the
            // ControlBuilder.createControl
            // method.
            if (qx.lang.Type.isFunction(control.validator)) {
                validationMgr.add(control, control.validator);
            }

            if (desc.hasOwnProperty('check')) {
                if (desc.check) {
                    control.setToolTip(new qx.ui.tooltip.ToolTip(this.tr('Condition: %1',desc.check)));
                    // FIX ME: build rx in backend
                    //         This might be tricky in case a more complex condition involving
                    //         various columns is used in the backend.
                    // (function(){ /* give use local context - function factory */
                    //     var rx = new RegExp(desc.check.rx);
                    //     var name = desc.name;
                    //     var msg = qx.locale.Manager.tr(desc.check.msg);
                    //     validationMgr.add(control,function(value,control){
                    //         var valid = rx.test(formData[name] || '');
                    //         if (!valid){
                    //             control.setInvalidMessage(msg);
                    //             control.setValid(valid);
                    //         }
                    //         return valid;
                    //     });
                    // })();
                }
            }
        }
    },

    properties : {
        formDataChanged : {
            init     : false,
            check    : "Boolean",
            apply    : '_applyFormDataChanged', // for debugging
            nullable : false
        }
    },

    members : {
        __formData : null,
        __controlMap: null,

        // only for debugging ...
        _applyFormDataChanged: function(newValue, oldValue) {
            this.debug('formDataChanged='+newValue);
        },

        __formDataCallback: function(key, value) {
            this.__formData[key] = value;
            this.setFormDataChanged(true);
        },

        /**
         * Return the form formData.
         *
         * @return {var} TODOC
         */
        getFormData : function() {
            return this.__formData;
        },

        setReadOnly: function(readOnly) {
            for (var k in this.__controlMap) {
                this.__controlMap[k].setReadOnly(readOnly);
            }
        },

        clear: function() {
            for (var k in this.__controlMap) {
                this.__controlMap[k].clear();
            }
        },

        clearPartial: function() {
            for (var k in this.__controlMap) {
                var control = this.__controlMap[k];
                if (!control.getCopyForward()) {
                    control.clear();
                }
            }
        },

        setDefaults: function(dataMap) {
            this.debug('Called setDefaults()');
            for (var k in dataMap) {
//                this.debug('  setDefaults(): key='+k+', value='+dataMap[k]);
                this.__controlMap[k].defaults(dataMap[k]);
            }
        },

        setFormData: function(dataMap) {
            this.debug('Called setFormData()');
            for (var k in dataMap) {
//                this.debug('  setFormData key='+k+', value='+dataMap[k]);
                this.__controlMap[k].setter(dataMap[k]);
            }
        }
    }
});
