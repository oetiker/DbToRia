/* ************************************************************************

   Copyrigtht: OETIKER+PARTNER AG
   License:    GPL
   Authors:    Tobias Oetiker
   Utf8Check:  äöü

   $Id: Login.js 425 2010-12-21 07:35:07Z oetiker $

************************************************************************ */

/* ************************************************************************
#asset(qx/icon/${qx.icontheme}/16/actions/dialog-ok.png)
#asset(qx/icon/${qx.icontheme}/64/status/dialog-password.png)
************************************************************************ */

/**
 * Login Popup that performs authentication.
 */
qx.Class.define("dbtoria.dialog.Login", {
    extend : qx.ui.window.Window,
    type : 'singleton',

    construct : function() {
        this.base(arguments, this.tr("DbToRia Login"));

        this.set({
            modal                : true,
            showMinimize         : false,
            showMaximize         : false,
            showClose            : false,
            resizable            : false,
            contentPaddingLeft   : 30,
            contentPaddingRight  : 30,
            contentPaddingTop    : 20,
            contentPaddingBottom : 20
        });
        this.getChildControl('captionbar').exclude();
        this.getChildControl('pane').set({
            decorator : new qx.ui.decoration.Single(1, 'solid', '#777'),
            backgroundColor: '#f8f8f8'
        });
        var grid = new qx.ui.layout.Grid(10, 10);
        this.setLayout(grid);
        grid.setColumnAlign(1, 'right', 'middle');

        this.add(new qx.ui.basic.Image("icon/64/status/dialog-password.png").set({
            alignY : 'top',
            alignX : 'right'
        }),
        {
            row     : 1,
            column  : 0,
            rowSpan : 2
        });

        this.add(new qx.ui.basic.Label(this.tr("Login")), {
            row    : 1,
            column : 1
        });

        var username = new qx.ui.form.TextField();

        this.add(username, {
            row    : 1,
            column : 2
        });

        this.add(new qx.ui.basic.Label(this.tr("Password")), {
            row    : 2,
            column : 1
        });

        var password = new qx.ui.form.PasswordField();

        this.add(password, {
            row    : 2,
            column : 2
        });

        var login = new qx.ui.form.Button("Login", "icon/16/actions/dialog-ok.png");

        login.set({
            marginTop  : 6,
            allowGrowX : false,
            alignX     : 'right'
        });

        this.add(login, {
            row     : 3,
            column  : 0,
            colSpan : 3
        });

        this.addListener('keyup', function(e) {
            if (e.getKeyIdentifier() == 'Enter') {
                login.press();
                login.execute();
                login.release();
            }
        });

        var rpc = dbtoria.communication.Rpc.getInstance();

        login.addListener("execute", function(e) {
            this.setEnabled(false);

            rpc.callAsync(qx.lang.Function.bind(this.__loginHandler, this), 'login', {
                username : username.getValue(),
                password : password.getValue()
            });
        },
        this);

        this.addListener('appear', function() {        
            password.setValue('');
            if (username.getValue()){
                username.setEnabled(false);
                password.focus();
                password.activate();
            }
            else {
                username.focus();
                username.activate();
            }                        
            this.setEnabled(true);
            this.center();
        });
    },

    events : { 'login' : 'qx.event.type.Event' },

    members : {
        /**
         * Handler for the login events
         *
         * @param ret {Boolean} true if the login is ok and false if it is not ok.
         * @param exc {Exception} any error found during the login process.
         * @return {void} 
         */
        __loginHandler : function(ret, exc) {
            if (exc) {
                dbtoria.dialog.MsgBox.getInstance().exc(exc);
                this.setEnabled(true);
            }
            else {
                var element = this.getContainerElement().getDomElement();
                if (ret) {
                    this.fireDataEvent('login', ret);
                    var effect = new qx.fx.effect.combination.Fold(element);
                    effect.start();
                    effect.addListener('finish', function() {
                        this.close();
                    }, this);
                }
                else {
                    var effect = new qx.fx.effect.combination.Shake(element);
                    effect.start();
                    this.setEnabled(true);
                }
            }
        }
    }
});
