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
#asset(icon/16/mimetypes/office-calendar.png)
#asset(icon/22/actions/document-new.png)
#asset(icon/22/actions/dialog-cancel.png)
#asset(icon/22/actions/edit-redo.png)
#asset(icon/22/actions/document-print.png)
#asset(icon/22/actions/edit-find.png)
#asset(icon/22/actions/edit-find.png)
#asset(icon/22/actions/edit-find.png)

************************************************************************ */
/**
 * This class provides the view for a specific table.
 *
 * It displays a traditional table at first. On clicking on a row it opens a
 * form for data editing. This window also allows for searching, creation and
 * deletion of entries.
 */
qx.Class.define("dbtoria.window.Table", {
    extend: qx.ui.window.Window,

    /*
    *****************************************************************************
	CONSTRUCTOR
    *****************************************************************************

    @param tableId {String} 	The name of the table in the database
    @param tableName {String} 	The user-friendly name which is displayed
    @param application {dbtoria.Application} Reference to the application
    @param mode {String} 	Either "default" or "reference".
				In default mode a double click edits a dataset, in
				reference mode the selected dataset is returned to
				the callingWindow
    @param selection {JSON} 	In reference mode this contains the table structure and
				the widget of the column from the calling window.Table
    @param callingWindow {window.Table} In reference mode this contains the calling window
    */
    construct: function(tableId, tableName, application, mode, selection, callingWindow) {

	// call super class
	this.base(arguments, this.tr("Table") + ": " + tableName);

	this.__dbTable = new dbtoria.db.Table(tableId);
	this.__tableId = tableId;
	this.__tableName = tableName;
	this.__application = application;
	this.__mode = mode || "default";
	this.__selection = selection;
	this.__callingWindow = callingWindow;
	
	// TODO Why is this - without this statement - still filled in new instance?
	this.__formFields  = {};

	this.__toolTip = new qx.ui.tooltip.ToolTip();
	this.__toolTip.setAutoHide(false);
	this.__toolTip.setHideTimeout(20000);
	this.__toolTip.setRich(true);
	
	// use vertical layout with small separator
	this.setLayout(new qx.ui.layout.VBox());
	this.getLayout().setSeparator("separator-vertical");
	
	this.set({
	    contentPadding: 0,
	    margin: 0,
	    width: 800,
	    height: 500
	});
	
	// on clicking the minimize button a new button on the taskbar is
	// generated which allows to restore the window again
	this.addListener("minimize", function(e) {
	    var taskbarButton = new qx.ui.toolbar.Button(this.__tableName, "icon/16/mimetypes/office-calendar.png");
	    application.getTaskbar().add(taskbarButton);
	    
	    // on clicking on the taskbarbutton the window is opened again and
	    // the taskbar button is removed
	    taskbarButton.addListener("execute", function(e) {
		this.open();
		e.getTarget().getLayoutParent().remove(e.getTarget());
	    }, this);
	    
	    this.__table.setToolTip(null);
	    this.__toolTip.setVisibility("excluded");
	});
	
	this.addListener("close", function(e) {
	    this.__table.setToolTip(null);
	    this.__toolTip.setVisibility("excluded");
	});
	    
	// show table
	application.getDesktop().add(this);
	
	this.center();
	this.open();
	
	// load table overview
	this.showTableOverview();
    },
    
    /*
    *****************************************************************************
	MEMBERS
    *****************************************************************************
    */
    
    members: {
	
	// application reference
	__application: null,
	
	// table widget containing user data
	__table: null,
	
	// representation of table in database
	__dbTable: null,
	
	// save button
	__saveButton: null,
	
	// settings for reference tooltip
	__timeout: null,
	__timer: null,
	__cellEvent: null,
	__toolTip: null,
	
	__formFields: {},

	// window.TableFilter object for filtering the data
	__filterWidget: null,
	
	/**
	* Display a table overview with data
	*/
	showTableOverview: function() {
	    
	    // reset width after turning back from form view
	    this.set ({ width: 800 });
	    
	    // remove all children in case we are returning from form view
	    this.removeAll();
	    
	    // change apperance in reference mode
	    if(this.__mode == "reference") {
		this.set({
		    width: 600,
		    height: 300,
		    showStatusbar: true
		});
	    }
	    
	    // generate toolbar for new, delete, refresh, export and search
	    // functions
	    var toolbar = new qx.ui.toolbar.ToolBar();
	    
	    var newButton 	= new qx.ui.toolbar.Button(this.tr("New Entry"), "icon/22/actions/document-new.png");
	    var deleteButton 	= new qx.ui.toolbar.Button(this.tr("Delete Selection"), "icon/22/actions/dialog-cancel.png");
	    var refreshButton	= new qx.ui.toolbar.Button(this.tr("Refresh"), "icon/22/actions/edit-redo.png");
	    var exportButton 	= new qx.ui.toolbar.Button(this.tr("Export"), "icon/22/actions/document-print.png");
	    var filterButton 	= new qx.ui.toolbar.CheckBox(this.tr("Search"), "icon/22/actions/edit-find.png");
	    
	    // filter button
	    filterButton.addListener("changeChecked", function(e) {
		if(e.getTarget().isChecked()) {
		    if(!this.__filterWidget) {
			this.__filterWidget = new dbtoria.window.TableFilter(this, this.__dbTable);
		    }
		    this.addAt(this.__filterWidget, 1);
		}
		else {
		    this.__filterWidget = null;
		    this.updateFilter(null);
		    this.removeAt(1);
		}
	    }, this);

	    // clicking on new button clears the selection in the table and opens
	    // the form view
	    newButton.addListener("execute", function(e) {
		this.__table.getSelectionModel().clearSelection();
		this.showTableDetails(true);
	    }, this);
	    
	    // deleteButton
	    deleteButton.addListener("execute", function(e) {
		if(this.__table.getSelectionModel().getSelectedCount() > 0) {
		    
		    // get primary keys for selection
		    var primaryKeys = this.__dbTable.getPrimaryKeys(this.__dbTable.getTableStructure());
		    
		    // iterate through all selected rows and delete each
		    this.__table.getSelectionModel().iterateSelection(function(index) {
			
			var selection = {};
			
			// if primary keys are available use them for selection criteria
			if(primaryKeys.length > 0) {
			    for(var i = 0; i < primaryKeys.length; i++) {
				selection[primaryKeys[i].field] = this.__table.getTableModel().getValue(primaryKeys[i].index, index);
			    }
			}
			// otherwise use the data from all columns as selection critera
			else {
			    var tableStructure = this.__dbTable.getTableStructure();
			    
			    for(var i = 0; i < tableStructure.length; i++) {
				selection[tableStructure[i].id] = this.__table.getTableModel().getValue(i, index);
			    }
			}
			
			this.__dbTable.deleteData(selection);
			
		    }, this);
		    
		    this.__table.getSelectionModel().clearSelection();
		    this.__table.getTableModel().reloadData();
		}
	    }, this);
	    
	    
	    // clicking on the refresh button updates the table data
	    refreshButton.addListener("execute", function(e) {
		this.__table.getTableModel().reloadData();
	    }, this);
	    
	    var spacer = toolbar.addSpacer();
	    spacer.setMaxWidth(10);
	    
	    toolbar.add(newButton);
	    
	    // only allow deletion from 
	    if(this.__mode == "default") {
		toolbar.add(deleteButton);
	    }
	    
	    toolbar.add(refreshButton);
	    toolbar.addSpacer();
     
	    //toolbar.add(exportButton);
	    toolbar.add(filterButton);
	
	    var spacer = toolbar.addSpacer();
	    spacer.setMaxWidth(10);
	    
	    this.add(toolbar);
	   
	    // if filter widget already present display it again
	    if(this.__filterWidget) {
		filterButton.setChecked(true);
	    }
	    
	    // only generate table once, reuse if it already exists
	    if(this.__table == null) {
		
		// display loading image while table is generated
		var loading = new qx.ui.basic.Image("dbtoria/loading.gif");

		loading.set({
		    alignX: "center",
		    padding: 50,
		    paddingTop: (this.getHeight() - 150) / 2
		});
		
		this.add(loading);
		
		// use RemoteDataModel for faster loading
		var tableModel = new dbtoria.table.RemoteDataModel(this.__dbTable);
		
		// set column names and IDs to model
		tableModel.setColumns(this.__dbTable.getColumnNames(), this.__dbTable.getColumnIDs());
		
		// use custom column and paneScroller models
		var customModel = {
		    tableColumnModel : function(obj) {
			return new qx.ui.table.columnmodel.Resize(obj);
		    },
		    
		    tablePaneScroller : function(obj) {
			return new dbtoria.table.Scroller(obj);
		    }
		};
	  
		var table = new dbtoria.table.Table(tableModel, customModel);

		// set tooltip and mouseover handler
		table.addListener("cellMouseOver", function(e) {
		    
		    // if timer already active, stop it
		    if(this.__timer) {
			this.__timer.stop();
		    }
		    
		    this.__table.setToolTip(null);
		    this.__toolTip.setVisibility("excluded");
		    this.__toolTip.setLabel(this.tr("Loading..."));
		    
		    if(this.__dbTable.getColumn(e.getColumn()).references) {
			this.__cellEvent = e;
			this.__timer = qx.event.Timer.once(this.updateToolTip, this, 500);
		    }
		}, this);
		
		// use enhanced resize behavior for better column width handling
		table.getTableColumnModel().setBehavior(new dbtoria.behavior.EnhancedResize());
		
		// disable cell focus
		table.setShowCellFocusIndicator(false);
		
		// walk through colum information in table structure and assign
		// suitable cellrenderer
		var tableStructure = this.__dbTable.getTableStructure();
		
		for (var i = 0; i < tableStructure.length; i++) {
		    
		    var formElement = tableStructure[i];
		    
		    // set cellrenderer according to type
		    switch(formElement.type) {
			case "boolean":
			    table.getTableColumnModel().setDataCellRenderer(i, new dbtoria.cellrenderer.BooleanString());
			    break;
		    }
		    
		    // references overwrite types
		    if(formElement.references) {
			table.getTableColumnModel().setDataCellRenderer(i, new dbtoria.cellrenderer.Reference());
		    }
		    
		    this.setStatus(this.tr("Doubleclick on an entry to reference this dataset"));
		    
		    // hide columns after 3 if in reference mode
		    if(this.__mode == "reference" && i > 2) {
			
			table.getTableColumnModel().setColumnVisible(i, false);
			
			qx.event.Timer.once(function() {
			    this.setStatus(this.tr("Info: Additional columns are hidden, click on the icon at the top right in table header to display them"))
			    
			    qx.event.Timer.once(function() {
				this.setStatus("");
			    }, this, 5000);
			    
			}, this, 5000);
		    }
		    else {
			qx.event.Timer.once(function() {
			    this.setStatus("");
			}, this, 5000);
		    }
		}
		// allow selection of multiple, independent rows (especially for deleting)
		table.getSelectionModel().setSelectionMode(qx.ui.table.selection.Model.MULTIPLE_INTERVAL_SELECTION);
		
		/* TODO doesnt work with remote table
		   This should select the referenced row
		if(this.__mode == "reference" && this.__selection) {
		    var row = this.findRowWithKey(this.__selection.references.field, this.__selection.widget.getValue());
		    
		    table.getSelectionModel().addSelectionInterval(row, row);
		    
		    // TODO: not working
		    table.getPaneScroller(0).scrollCellVisible(0, row);
		}*/
		
		if(this.__mode == "reference") {
		    
		    // on double clicking a row return value to callingWindow
		    table.addListener("dblclick", function(e) {
			if(this.__table.getSelectionModel().getSelectedCount() > 0) {
			    this.__table.getSelectionModel().iterateSelection(function(index) {
				
				var columnId = this.__dbTable.getColumnIndexByName(this.__selection.references.field);
				var value = this.__table.getTableModel().getValue(columnId, index);
				
				this.__callingWindow.returnReference(this.__selection, value);
				this.close();
			    }, this);
			}
		    }, this);
		    
		}
		else {
		    
		    // on double clicking a row the detail view is shown
		    table.addListener("dblclick", function(e) {
			if(this.__table.getSelectionModel().getSelectedCount() > 0) {
			    this.showTableDetails();
			}
		    }, this);
		}
		
		this.__table = table;
		
		// replace loading image with table
		this.removeAt(1);
	    }

	    this.add(this.__table, { flex: 1 });  
	},
	
	/**
	* Display a form according to table structure information to edit or add
	* a dataset.
	*
	* This function provides save and cancel functions. It adds a form to the
	* table window which lets the user view and change table data.
	* 
	* @param insert {boolean}	Whether the form is displayed to insert
	* 				a new row
	*/
	showTableDetails: function(insert) {
	    var tableView = this;

	    // disable tooltip on details view
	    this.__table.setToolTip(null);
	    this.__toolTip.setVisibility("excluded");
	    this.__toolTip.setLabel(this.tr("Loading..."));
	    
	    // reset window width and height so the window size gets adjusted to form
	    this.set({
		height: null,
		width: null
	    });
	    
	    // remove all children (table view)
	    this.removeAll();
	    
	    // create toolbar with save and cancel buttons
	    var toolbar = new qx.ui.toolbar.ToolBar();
	
	    var saveButton 	= new qx.ui.toolbar.Button(this.tr("Save Changes"), "icon/22/actions/document-new.png");
	    var cancelButton 	= new qx.ui.toolbar.Button(this.tr("Cancel"), "icon/22/actions/dialog-cancel.png");
	    
	    this.__saveButton = saveButton;
	    
	    // disable save button until a change was made
	    saveButton.setEnabled(false);
	    
	    // when save button is clicked save changes
	    saveButton.addListener("execute", function(e) {
		
		var selection = {};
		var data = {};

		// walk through all form elements
		for(var formFieldIndex in this.__formFields) {
		
		    var formField = this.__formFields[formFieldIndex];

		    // build selection criteria (which datasets to update)
		    // use column as selection if it has a primary key or there are no primary keys available
		    if(formField.primaryKey == 1 || this.__dbTable.getPrimaryKeys(this.__dbTable.getTableStructure()).length == 0) {
			switch(formField.formField.classname) {
			    case "qx.ui.basic.Label":
				selection[formFieldIndex] = formField.formField.getContent();
				break;
			    
			    default:
				selection[formFieldIndex] = formField.oldValue;
				break;
			}
		    }
		    
		    // if form field has changed include it for update
		    if(formField.changed) {
			
			// depending on the classname the function to access the content
			// is different
			switch(formField.formField.classname) {
			    case "qx.ui.form.DateField":
				
				var date = formField.formField.getDate();
				//data[formFieldIndex] = date.getFullYear() + "-" + (date.getMonth() +1) + "-" + date.getDate() + " " + date.getHours() + ":" +
				//			date.getMinutes() + ":" + date.getSeconds();
							
				data[formFieldIndex] = date.getFullYear() + "-" + (date.getMonth() +1) + "-" + date.getDate() + " 00:00:00";
				
				break;
			    
			    case "qx.ui.form.Button":
				data[formFieldIndex] = formField.formField.getValue();
				break;
			    
			    case "qx.ui.form.SelectBox":
				data[formFieldIndex] = formField.formField.getSelected().getValue();
				break;
			    
			    case "qx.ui.form.CheckBox":
				data[formFieldIndex] = (formField.formField.getChecked()) ? 1 : 0;
				break;
			    
			    default:
				data[formFieldIndex] = formField.formField.getValue();
				break;
			}
		    }
		}
		
		// whether we are in insert or update mode choose the right db query
		if(insert) {
		     if(this.__dbTable.insertData(data)) {
			this.__table.getTableModel().reloadData();
			this.showTableOverview();
		    }   
		}
		else {
		    if(this.__dbTable.updateData(selection, data)) {
			this.__table.getTableModel().reloadData();
			this.showTableOverview();
		    }    
		}
	    }, this);
	    
	    // go back to table view on cancel
	    cancelButton.addListener("execute", function(e) {
		this.showTableOverview();
	    }, this);
	    
	    var spacer = toolbar.addSpacer();
	    spacer.setMaxWidth(10);
	    
	    toolbar.add(saveButton);
	    toolbar.addSpacer();
	    toolbar.add(cancelButton);
	
	    var spacer = toolbar.addSpacer();
	    spacer.setMaxWidth(10);
	    
	    this.add(toolbar);
	    
	    // either generate form from existing data or empty depending on selection status of table view
	    if(this.__table.getSelectionModel().getSelectedCount() > 0) {
		this.__table.getSelectionModel().iterateSelection(function(index) {

		    // provide selected data in table view to pre-fill form
		    this.add(this.generateForm(this.__table.getTableModel().getRowData(index)));
		}, this);
	    }
	    else {
		this.add(this.generateForm(null));
	    }
	},
	
	/**
	* Generate the form elements according to table structure. If provided
	* fill the form with existing values.
	*
	* @param values {Array}	Single array containing data to auto-fill in form. Must match
	* 			the column information in tableStructure in type and number
	* 			
	* @return {Composite}	The generated form
	* 
	*/
	generateForm: function(values) {

	    var form = new qx.ui.container.Composite(new qx.ui.layout.Grid(15, 5));
	
	    form.getLayout().setColumnAlign(0, "right", "top");
	    form.set({ padding: 20, allowGrowX: true, allowShrinkX: true });   
	    
	    // count rows to know here to add new elements
	    var rowCount = 0;
	    
	    var tableStructure = this.__dbTable.getTableStructure();
	    
	    // TODO fix woraround for empty set
	    if(!values) {
		values = {};
		
		for (var i = 0; i < tableStructure.length; i++) {
		    values[tableStructure[i].id] = "";
		}
	    }
	    
	    // walk through column information in table structure
	    for (var i = 0; i < tableStructure.length; i++) {

		var formElement = tableStructure[i];
		
		this.__formFields[formElement.id] = { changed: false, primaryKey: formElement.primaryKey, oldValue: values[formElement.id] } ;
		
		
		/* TODO
		   this was used to disable (careless) editing of primary keys
		    
		if(formElement.primaryKey) {
		    var label = new qx.ui.basic.Label(values[i]);
	
		    label.set({
			width: 150,
			allowGrowX: false
		    });
		    
		    form.add(new qx.ui.basic.Label(formElement.name), {row: rowCount, column: 0});
		    form.add(label, {row: rowCount++, column: 1});
			    
		    this.__formFields[formElement.id].formField = label;
		}
		else*/
		
		// if current element is not a reference handle as normal data field
		if(!formElement.references) {
		
		    // decide which widget to use according to column type
		    switch(formElement.type) {
			
			case "datetime":
			case "timestamp":
			    var dateField = new qx.ui.form.DateField();
			    
			    dateField.set({allowGrowX: false, width: 150 });
			    
			    if(values[formElement.id]) {
				var date = values[formElement.id].split(" ")[0];
				//var time = values[formElement.id].split(" ")[1];
				
				var day = date.split(".")[0];
				var month = date.split(".")[1] - 1;
				var year = date.split(".")[2];
				
				//var hour = time.split(":")[0];
				//var minute = time.split(":")[1];
				//var seconds = time.split(":")[2];
				
				
				//dateField.setDate(new Date(year, month, day, hour, minute, seconds));
				dateField.setDate(new Date(year, month, day));
			    }
			    else {
				dateField.setDate(new Date());
			    }
			    
			    form.add(new qx.ui.basic.Label(formElement.name), {row: rowCount, column: 0});
			    form.add(dateField, {row: rowCount++, column: 1});
			    
			    this.__formFields[formElement.id].formField = dateField;
			    break;
			
			case "varchar":

			    // change layout according to column max size
			    if(formElement.size <= 50 || !formElement.size) {
				var textField = new qx.ui.form.TextField(String(values[formElement.id]));
	
				// try to parse int from size information, if it succeeds use as maxLength
				if(parseInt(formElement.size)) {
				    var maxLength = parseInt(formElement.size); 
				    textField.setMaxLength(maxLength);
				}

				textField.set({
				    width: 150,
				    name: formElement.name,
				    allowGrowX: false
				});
			   
				// on key press check if maxLength is reached, display error if so
				textField.addListener("keyinput", function(e) {
				    if(e.getTarget().getValue().length + 1 > e.getTarget().getMaxLength()) {
					this.showValidationError(this.tr("Too many characters, only %1 allowed.", e.getTarget().getMaxLength()));
				    }
				}, this);
			    }
			    
			    else if (formElement.size > 50 && formElement.size < 500) {
				var textField = new qx.ui.form.TextArea(String(values[formElement.id]));
				
				// try to parse int from size information, if it succeeds use as maxLength
				if(parseInt(formElement.size)) {
				    var maxLength = parseInt(formElement.size); 
				}
				
				textField.set({
				    width: 300,
				    height: 100,
				    allowGrowX: false,
				    name: formElement.name
				});
			    }
			    
			    else {
				var textField = new qx.ui.form.TextArea(String(values[formElement.id]));
				
				// try to parse int from size information, if it succeeds use as maxLength
				if(parseInt(formElement.size)) {
				    var maxLength = parseInt(formElement.size); 
				}
				
				textField.set({
				    width: 450,
				    height: 200,
				    name: formElement.name
				});
			    }
			    
			    form.add(new qx.ui.basic.Label(formElement.name), {row: rowCount, column: 0});
			    form.add(textField, {row: rowCount++, column: 1});
			    
			    this.__formFields[formElement.id].formField = textField;
			    break;
			
			case "text":
			    var textArea = new qx.ui.form.TextArea(String(values[formElement.id]));
			    
			    textArea.set({
				width: 450,
				height: 200,
				name: formElement.name
			    });
			    
			    form.add(new qx.ui.basic.Label(formElement.name), {row: rowCount, column: 0});
			    form.add(textArea, {row: rowCount++, column: 1});
			    
			    this.__formFields[formElement.id].formField = textArea;
			    break;
			
			case "boolean":
			    var checkBox = new qx.ui.form.CheckBox();
    
			    checkBox.set({
				name: formElement.name
			    });
			    
			    checkBox.setChecked(values[formElement.id] == 1 || values[formElement.id] == "true");
			    
			    form.add(new qx.ui.basic.Label(formElement.name), {row: rowCount, column: 0});
			    form.add(checkBox, {row: rowCount++, column: 1});
			    
			    this.__formFields[formElement.id].formField = checkBox;
			    break;
			
			case "enum":
			    
			    // if enum contains more than 3 elements display
			    // as select box, otherwise as radio group
			    if(formElement.options.length > 3) {
				var selectBox = new qx.ui.form.SelectBox();
				
				selectBox.set({ allowGrowX: false });
				
				for(var j = 0; j < formElement.options.length; j++) {
				    var listItem = new qx.ui.form.ListItem(formElement.options[j]);
				    listItem.setValue(formElement.options[j]);
				    
				    if(values[formElement.id] == formElement.options[j]) {
					selectBox.setSelected(listItem);
				    }
				    
				    selectBox.add(listItem);
				}
				
				form.add(new qx.ui.basic.Label(formElement.name), {row: rowCount, column: 0});
				form.add(selectBox, {row: rowCount++, column: 1});
				
				this.__formFields[formElement.id].formField = selectBox;
			    }
			    else {
				var radioGroup = new qx.ui.form.RadioGroup();
				
				for(var j = 0; j < formElement.options.length; j++) {
				    var radioButton = new qx.ui.form.RadioButton(formElement.options[j]);
				    radioButton.setValue(formElement.options[j]);
				    
				    if(values[formElement.id] == formElement.options[j]) {
					radioButton.setChecked(true);
				    }
				    
				    radioGroup.add(radioButton);
				}
				
				form.add(new qx.ui.basic.Label(formElement.name), {row: rowCount, column: 0});
				
				var radioButtons = radioGroup.getItems();
				
				for(var j = 0; j < radioButtons.length; j++) {
				    form.add(radioButtons[j], {row: rowCount++, column: 1});
				}
				
				this.__formFields[formElement.id].formField = radioGroup;
			    }
			    break;
			
			case "float":
			case "real":
			    var textField = new qx.ui.form.TextField(values[formElement.id]);
			    
			    // try to parse int from size information, if it succeeds use as maxLength
			    if(parseInt(formElement.size)) {
				var maxLength = parseInt(formElement.size); 
			    }
			    textField.set({
				width: 150,
				maxLength: maxLength,
				name: formElement.name,
				allowGrowX: false
			    });
			    
			    // on key press check if maxLength is reached, display error if so
			    // also check if pressed key is 0-9, otherwise discard key event and display error
			    textField.addListener("keyinput", function(e) {
				if(e.getTarget().getValue().length + 1 > e.getTarget().getMaxLength()) {
				    this.showValidationError(this.tr("Too many characters, only %1 allowed.", e.getTarget().getMaxLength()));
				}
				
				// only allow numeric values and points to be entered
				if(!e.getChar().match(/[0-9\.]/)) {
				    e.stopPropagation();
				    e.preventDefault();
				    this.showValidationError(this.tr("Invalid character, only integers and points allowed."));
				}
			    }, this);
			    
			    form.add(new qx.ui.basic.Label(formElement.name), {row: rowCount, column: 0});
			    form.add(textField, {row: rowCount++, column: 1});
			    
			    this.__formFields[formElement.id].formField = textField;
			    break;
			
			case "integer":
			    var textField = new qx.ui.form.TextField(String(values[formElement.id]));
			    
			    // try to parse int from size information, if it succeeds use as maxLength
			    if(parseInt(formElement.size)) {
				var maxLength = parseInt(formElement.size); 
			    }
			    textField.set({
				width: 150,
				maxLength: maxLength,
				name: formElement.name,
				allowGrowX: false
			    });
			    
			    // on key press check if maxLength is reached, display error if so
			    // also check if pressed key is 0-9, otherwise discard key event and display error
			    textField.addListener("keyinput", function(e) {
				if(e.getTarget().getValue().length + 1 > e.getTarget().getMaxLength()) {
				    this.showValidationError(this.tr("Too many characters, only %1 allowed.", e.getTarget().getMaxLength()));
				}
				
				// only allow numeric values to be entered
				if(!e.getChar().match(/[0-9]/)) {
				    e.stopPropagation();
				    e.preventDefault();
				    this.showValidationError(this.tr("Invalid character, only integers allowed."));
				}
			    }, this);
			    
			    form.add(new qx.ui.basic.Label(formElement.name), {row: rowCount, column: 0});
			    form.add(textField, {row: rowCount++, column: 1});
			    
			    this.__formFields[formElement.id].formField = textField;
			    break;
			
			// if no other type matches better, display as textfield
			default:
			    var textField = new qx.ui.form.TextField(String(values[formElement.id]));
			    
			    // try to parse int from size information, if it succeeds use as maxLength
			    if(parseInt(formElement.size)) {
				var maxLength = parseInt(formElement.size); 
			    }
			    textField.set({
				width: 150,
				maxLength: maxLength,
				name: formElement.name,
				allowGrowX: false
			    });
			    
			    // on key press check if maxLength is reached, display error if so
			    textField.addListener("keyinput", function(e) {
				if(e.getTarget().getValue().length + 1 > e.getTarget().getMaxLength()) {
				    this.showValidationError(this.tr("Too many characters, only %1 allowed.", e.getTarget().getMaxLength()));
				}
			    }, this);
			    
			    form.add(new qx.ui.basic.Label(formElement.name + "[" + formElement.type + "]"), {row: rowCount, column: 0});
			    form.add(textField, {row: rowCount++, column: 1});
			    
			    this.__formFields[formElement.id].formField = textField;
			    break;
		    }
		}
		
		// otherwise handle accordingly (reference tool tip, click opens
		// reference window)
		else {

		    // get views for nicer custom reference output
		    var rpc = dbtoria.communication.Rpc.getInstance()
		    
		    try {
			var result = rpc.callSync("getViews");
			var views = result.tables;
		    
		    } catch(e) {
			var errorDialog = dbtoria.dialog.Error.getInstance();
			errorDialog.showError("Connection to remote server failed: " + e);
		    }
		    
		    // change behavior according to element type
		    switch(formElement.type) {
			case "varchar":
			case "integer":

			    // check if there is a view named _[referencedTable]_reference
			    // if there is use the column named "referenceText" as reference text
			    var referenceView = null;
			    var referenceText = (values[formElement.id] || "null");

			    if(views && values[formElement.id] != "null") {
				for(var v=0; v < views.length; v++) {
				    if(views[v].id == "_" + formElement.references.table + "_reference") {
					referenceView = new dbtoria.db.Table(views[v].id);
					referenceText = referenceView.getDataWithKey(formElement.references.field, values[formElement.id])[0].referenceText;
				    }
				}
			    }
			    
			    var button = new qx.ui.form.Button(referenceText);
			    form.getLayout().setRowAlign(rowCount, "left", "middle");
			    
			    if(!values[formElement.id]) {
				values[formElement.id] = "null";
			    }
			    
			    button.set({
				name: formElement.name,
				allowGrowX: false,
				value: values[formElement.id]
			    });
			    
			    formElement.widget = button;
    			    this.setReferenceToolTip(formElement);

			    // create window.Table in "reference" mode if clicked
			    button.addListener("execute", function(e) {
				var referenceWindow = 	new dbtoria.window.Table(
							    this.formElement.references.table,
							    this.formElement.references.table,
							    this.application,
							    "reference",
							    this.formElement,
							    this.callingWindow
							);
			    }, {
				application: this.__application,
				formElement: formElement,
				callingWindow: this
			    });
			    
			    var label = new qx.ui.basic.Label(formElement.name)
			    
			    form.add(label, {row: rowCount, column: 0});
			    form.add(button, {row: rowCount++, column: 1});
			    
			    this.__formFields[formElement.id].formField = button;
			    break;
			
			// if no other type matches better, display as textfield
			default:
			    var textField = new qx.ui.form.TextField(values[formElement.id]);
			    
			    // try to parse int from size information, if it succeeds use as maxLength
			    if(parseInt(formElement.size)) {
				var maxLength = parseInt(formElement.size); 
			    }
			    textField.set({
				width: 150,
				maxLength: maxLength,
				name: formElement.name,
				allowGrowX: false
			    });
			    
			    // on key press check if maxLength is reached, display error if so
			    textField.addListener("keyinput", function(e) {
				if(e.getTarget().getValue().length + 1 > e.getTarget().getMaxLength()) {
				    this.showValidationError(this.tr("Too many characters, only %1 allowed.", e.getTarget().getMaxLength()));
				}
			    }, this);
			    
			    form.add(new qx.ui.basic.Label(formElement.name + "[" + formElement.type + "] REFERENCE"), {row: rowCount, column: 0});
			    form.add(textField, {row: rowCount++, column: 1});
			    
			    this.__formFields[formElement.id].formField = textField;
			    break;
		    }
		}
	    }  
	    
	    // walk through each form field to apply change listeners
	    for(var formFieldIndex in this.__formFields) {
		
		var formField = this.__formFields[formFieldIndex];
		
		// depending on form field change the way to determine
		// when a field has changed
		switch(formField.formField.classname) {
		    case "qx.ui.form.DateField":
			formField.formField.addListener("changeValue", function(e) {
			    this.window.__saveButton.setEnabled(true);
			    this.formField.changed = true;
			}, { window: this, formField : formField });
			
			break;
		    
		    case "qx.ui.form.Button":
			formField.formField.addListener("execute", function(e) {
			    this.window.__saveButton.setEnabled(true);
			    this.formField.changed = true;
			}, { window: this, formField : formField });
			
			break;
		    
		    case "qx.ui.form.SelectBox":
			formField.formField.addListener("changeSelected", function(e) {
			    this.window.__saveButton.setEnabled(true);
			    this.formField.changed = true;
			}, { window: this, formField : formField });
			
			break;
		    
		    case "qx.ui.form.RadioGroup":
			formField.formField.addListener("changeValue", function(e) {
			    this.window.__saveButton.setEnabled(true);
			    this.formField.changed = true;
			}, { window: this, formField : formField });
			
			break;
		    
		    case "qx.ui.form.CheckBox":
			formField.formField.addListener("changeChecked", function(e) {
			    this.window.__saveButton.setEnabled(true);
			    this.formField.changed = true;
			}, { window: this, formField : formField });
			
			break;
		    
		    default:
			formField.formField.addListener("keypress", function(e) {
			    this.window.__saveButton.setEnabled(true);
			    this.formField.changed = true;
			}, { window: this, formField : formField });
			
			break;
		}
	    }
	    
	    return form;
	},
	
	/**
	* This is the callback function called when a dataset has been
	* selected in referenced window.
	*
	* @param referenceFormElement {JSON}	Object containing data and widget of
	* 					the referenced form element
	*
	* @param newValue {String}		New referenced value
	* 
	*/
	returnReference: function(referencedFormElement, newValue) {
	
	    referencedFormElement.widget.setValue(newValue);
	    
	    // get views for nicer custom reference output
	    var rpc = dbtoria.communication.Rpc.getInstance()
	    
	    try {
		var result = rpc.callSync("getViews");
		var views = result.tables;
	    
	    } catch(e) {
		var errorDialog = dbtoria.dialog.Error.getInstance();
		errorDialog.showError("Connection to remote server failed: " + e);
	    }

	    // fetch reference text from view (if available according to naming convention)
	    referenceText = null;
	    if(views) {
		for(var v=0; v < views.length; v++) {
		    if(views[v].id == "_" + referencedFormElement.references.table + "_reference") {
			referenceView = new dbtoria.db.Table(views[v].id);
			referenceText = referenceView.getDataWithKey(referencedFormElement.references.field, newValue)[0].referenceText;
		    }
		}
	    }
	    
	    if(referenceText != null) {
		referencedFormElement.widget.setLabel(referenceText);
	    }
	    
	    // otherwise simply display bare value
	    else {
		referencedFormElement.widget.setLabel(newValue);
	    }
	    
	    this.setReferenceToolTip(referencedFormElement);
	},
	
	
	// TODO cannot be made with remote table?
	findRowWithKey: function(column, value) {
	    var columnId = this.__dbTable.getColumnIndexByName(column);
	    var data = this.__dbTable.getData();
	    
	    for(var i = 0; i < data.length; i++) {
		if(data[i][columnId] == value) {
		    return i;
		}
	    }
	    
	    return null;
	},
	
	/**
	* Set Tooltip for a formElement which references a table
	*
	* @param formElement {JSON}	Object containing data and widget of
	* 				the referencing form element
	*/
	setReferenceToolTip: function(formElement) {
	    var refValue = formElement.widget.getValue();

	    if(refValue) {
		
		var referencedData = this.__dbTable.getReferencedDataForKey(
					formElement.references.table,
					formElement.references.field,
					refValue);

		// build html table with reference data
		if(referencedData) {
		    var toolTipHtml = "<table style='margin: 5px'>";

		    for (var i = 0; i < referencedData.length; i++) {
			for(var referencedRow in referencedData[i]) {
			    
			    var value;
			    if(!referencedData[i][referencedRow]) {
				value = "";
			    }
			    // truncate text if too long
			    else if(referencedData[i][referencedRow].length > 100) {
				value = referencedData[i][referencedRow].substr(0, 100) + "...";
			    }
			    else {
				value = referencedData[i][referencedRow];
			    }
			    toolTipHtml += "<tr><td style='font-weight: bold; text-align: right; vertical-align: top; padding-right: 10px'>" + referencedRow + "</td><td>" + value + "</td></tr>";
			}
		    }
    	
		    toolTipHtml += "</table>";
		    
		    var toolTip = new qx.ui.tooltip.ToolTip(toolTipHtml)
		    
		    toolTip.setRich(true);
		    toolTip.setHideTimeout(20000);
		    formElement.widget.setToolTip(toolTip);
		}
	    }
	},
	
	/**
	* Update the tooltip on main tablewith reference data
	*/
	updateToolTip: function() {
	    var column = this.__dbTable.getColumn(this.__cellEvent.getColumn());
	    var referencedData = this.__dbTable.getReferencedDataForKey(
					column.references.table,
					column.references.field,
					this.__table.getTableModel().getValue(this.__cellEvent.getColumn(), this.__cellEvent.getRow()));
	    
	    if(referencedData) {
		this.__table.setToolTip(this.__toolTip);
		var toolTipHtml = "<table style='margin: 5px'>";
		
		for (var i = 0; i < referencedData.length; i++) {
		    for(var referencedRow in referencedData[i]) {
			
			var value;
			if(!referencedData[i][referencedRow]) {
			    value = "";
			}
			else if(referencedData[i][referencedRow].length > 100) {
			    value = referencedData[i][referencedRow].substr(0, 100) + "...";
			}
			else {
			    value = referencedData[i][referencedRow];
			}
			toolTipHtml += "<tr><td style='font-weight: bold; text-align: right; vertical-align: top; padding-right: 10px'>" + referencedRow + "</td><td>" + value + "</td></tr>";
		    }
		}
    
		toolTipHtml += "</table>";
		
		this.__toolTip.setLabel(toolTipHtml);
		this.__toolTip.placeToMouse(this.__cellEvent);
		this.__toolTip.show();
	    }
	},
	
	/**
	* Sets a new filter and updates table data
	*
	* @param column {window.TableFilter} Filter object
	*/
	updateFilter: function(filter) {
	    this.__dbTable.setFilter(filter);
	    this.__table.getTableModel().reloadData();
	},
	
	/**
	* Show a validation error under the form for 2 seconds
	*
	* @param error {String}	String with error message
	* 
	*/
	showValidationError: function(error) {
	    var errorArea = new qx.ui.container.Composite(new qx.ui.layout.Canvas());
	    
	    // display error message bold white on red
	    errorArea.set({
		padding: 5,
		textColor: "#FFFFFF",
		backgroundColor: "#AA2222",
		font: "bold"
	    });
	    
	    var errorLabel = new qx.ui.basic.Label(this.tr("Error") + ": " + error)
	    errorArea.add(errorLabel);
	    
	    // TODO not working
	    // Fade validation message in
	    this.add(errorArea);
	    //var fadeIn = new qx.fx.effect.core.Fade(errorLabel.getContainerElement().getDomElement());
	    
	    //fadeIn.set({
	    //	from: 0.0,
	    //	to: 1.0});
	    //	fadeIn.start();
	    
	    // destroy validation information after 2 seconds
	    window.setTimeout(function() {
		errorArea.destroy();	
	    }, 2000);
	}
    }
});
