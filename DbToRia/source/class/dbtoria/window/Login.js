/* ************************************************************************

  DbToRia - Database to Rich Internet Application
  
  http://www.dbtoria.org

   Copyright:
    2009 David Angleitner, Switzerland
    
   License:
    GPL: http://www.gnu.org/licenses/gpl-2.0.html

   Authors:
    * David Angleitner

************************************************************************ */

/* ************************************************************************

#asset(dbtoria/*)

************************************************************************ */

/**
 * This class provides the login window for dbtoria.
 * 
 * This form asks for username and password, calls authenticate
 * on the backend and either prints an error message
 * or redirects the user to MainWindow.
 */
qx.Class.define("dbtoria.window.Login", {
    extend: qx.ui.window.Window,
    
    /*
    *****************************************************************************
	CONSTRUCTOR
    *****************************************************************************
    */
    
    construct: function(application) {
	
	// call super class
	this.base(arguments, this.tr("Login"));
    
	// set application reference
	this.application = application;
	
	// disable window resizing and moving
	this.set({
	    showMinimize: false,
	    showMaximize: false,
	    movable: false,
	    resizable: false,
	    showClose: false,
	    contentPadding: 20
	});
    
	// center window in browser
	this.addListener("appear", function() {
	    this.center();
	}, this);
    
	// layout properties
	var layout = new qx.ui.layout.Grid(20, 5);
	layout.setColumnAlign(0, "left", "middle");
	layout.setColumnAlign(1, "left", "middle");
    
	this.setLayout(layout);
    
	// generate username and password labels and fields
	this.add(new qx.ui.basic.Label(this.tr("Username")), { row: 0, column: 0 });
	this.add(new qx.ui.basic.Label(this.tr("Password")), { row: 1, column: 0 });
    
	this.username = new qx.ui.form.TextField().set({ width: 150 });
	this.password = new qx.ui.form.PasswordField();
    
	this.add(this.username, { row: 0, column: 1 });
	this.add(this.password, { row: 1, column: 1 });
    
	// generate login button
	var loginBtn = new qx.ui.form.Button(this.tr("login")).set({ allowGrowX: false, width: 70 });
    
	this.add(loginBtn, { row: 2, column: 1 });
    
	// call authenticate method after clicking on login button
	loginBtn.addListener("execute", this.checkAuthentication, this);
    },
    
    /*
    *****************************************************************************
	MEMBERS
    *****************************************************************************
    */
    
    members: {
	
	// username field
	username: null,
	
	// password field
	password: null,
	
	// application reference
	application: null,
    
	
	/**
	* Check proper authentication
	* call authenticate on backend to check if username and password fields
	* are valid database credentials 
	*
	* @param e {Event} Event on login button click
	*/
	checkAuthentication: function(e) {
    
	    // TODO: read url from config file
	    var rpc = dbtoria.communication.Rpc.getInstance()
    
	    try {
		var result = rpc.callSync("authenticate", this.username.getValue(), this.password.getValue());
    
		// if authentication successful close login window an display main window
		if (result.messageType == "answer" && result.message == "ok") {
		    this.close();
		    new dbtoria.window.Main(this.application);
		    
		// otherwise display error message
		} else if (result.messageType == "error") {
		    
		    var errorDialog = dbtoria.dialog.Error.getInstance();
	    
		    switch(result.message) {
			case "UnknownUser":
			    errorDialog.showError(this.tr("User '%1' not available", result.params[0]));
			    break;
			
			case "UnknownDatabase":
			    errorDialog.showError(this.tr("Database '%1' not available", result.params[0]));
			    break;
			
			case "NoPasswordSupplied":
			    errorDialog.showError(this.tr("No password supplied"));
			    break;
			
			case "WrongPassword":
			    errorDialog.showError(this.tr("Wrong password supplied"));
			    break;
			
			default:
			    errorDialog.showError(result.message);
		    }
		    this.password.setValue("");
		}
	    } catch(e) {
		var errorDialog = dbtoria.dialog.Error.getInstance();
		errorDialog.showError("Connection to remote server failed: " + e);
	    }
	}
    }
});