import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../../firebase.dart' as firebase;
import 'components.dart';

class JobCreatorCard extends StatefulWidget {
  final Map<String, dynamic> jobData;
  final String jobID;

  JobCreatorCard({Map<String, dynamic> jobData: null, String jobID: null}):
    // If only objID is given, generate the object's data.
    this.jobData = (jobData == null && jobID != null) ? firebase.getObject("jobs", jobID) : jobData,
    this.jobID = jobID;

  @override
  _JobCreatorCardState createState() => new _JobCreatorCardState();
}

class _JobCreatorCardState extends State<JobCreatorCard> {
  List<CreatorItem<dynamic>> _items;
  Map<String, dynamic> currentData;
  List<String> contactList;

  DateFormat datefmt = new DateFormat("EEEE, MMMM d");
  DateFormat timefmt = new DateFormat("h:mm a");
  DateFormat fullfmt = new DateFormat("h:mm a, EEEE, MMMM d");

  void initState(){
    super.initState();
    currentData = widget.jobData != null ? new Map<String, dynamic>.from(widget.jobData) : <String, dynamic>{};
    _items = getJobItems();
  }

  List<CreatorItem<dynamic>> getJobItems() {
    return <CreatorItem<dynamic>>[
      new CreatorItem<String>( // Name
        name: "Title",
        value: widget.jobData != null ? widget.jobData['name'] : '',
        hint: "(i.e. Pump test at CVS Amite)",
        valueToString: (String value) => value,
        builder: (CreatorItem<String> item){
          void close() {
            setState(() {
              item.isExpanded = false;
            });
          }

          return new Form(
            child: new Builder(
              builder: (BuildContext context){
                return new CollapsibleBody(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0),
                  onSave: () { Form.of(context).save(); close(); },
                  onCancel: () { Form.of(context).reset(); close(); },
                  child: new Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: new TextFormField(
                      controller: item.textController,
                      decoration: new InputDecoration(
                        hintText: item.hint,
                        labelText: item.name,
                      ),
                      onSaved: (String value) {
                        item.value = value;
                        currentData['name'] = value;
                      }
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      new CreatorItem<DateTime>( // When
        // TODO: Bug! If you pick the time after the date, the date resets back.
        name: "Date & time",
        value: widget.jobData != null ? DateTime.parse(widget.jobData["datetime"]) : new DateTime.now(),
        hint: "When is the job?",
        valueToString: (DateTime dt) => fullfmt.format(dt),
        builder: (CreatorItem<DateTime> item) {
          void close() {
            setState((){
              item.isExpanded = false;
            });
          }

          return new Form(
            child: new Builder(
              builder: (BuildContext context) {
                return new CollapsibleBody(
                  onSave: () { Form.of(context).save(); close(); },
                  onCancel: () { Form.of(context).reset(); close(); },
                  child: new FormField<DateTime>(
                    initialValue: item.value,
                    onSaved: (DateTime value) {
                      item.value = value;
                      currentData["datetime"] = value.toIso8601String();
                    },
                    builder: (FormFieldState<DateTime> field){
                      return new Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          new ListTile(
                            title: new Text(datefmt.format(field.value)),
                            trailing: new Icon(Icons.calendar_today),
                            onTap: () async {
                              final DateTime chosen = await showDatePicker(
                                context: context,
                                initialDate: field.value,
                                firstDate: new DateTime(2008),
                                lastDate: new DateTime(2068)
                              );
                              if (chosen != null && (chosen.year != field.value.year || chosen.month != field.value.month || chosen.day != field.value.day)){
                                print("I'm supposed to change here!");
                                field.onChanged(replaceDate(field.value, chosen));
                              }
                            }
                          ),
                          new ListTile(
                            title: new Text(timefmt.format(field.value)),
                            trailing: new Icon(Icons.access_time),
                            onTap: () async {
                              final TimeOfDay chosen = await showTimePicker(
                                context: context,
                                initialTime: new TimeOfDay.fromDateTime(field.value)
                              );
                              if (chosen != null) {
                                setState((){
                                  field.onChanged(replaceTimeOfDay(field.value, chosen));
                                });
                              }
                            }
                          )
                        ]
                      );
                    }
                  ),
                );
              }
            ),
          );
        }
      ),
      new CreatorItem<String>( // Location
        name: "Location",
        value: widget.jobData != null ? widget.jobData["location"] : null,
        hint: "Where is the job?",
        valueToString: (String locationID){
          if (locationID != null){
            return firebase.getObject("locations", locationID)["name"];
          } else {
            return "Select a location";
          }
        },
        builder: (CreatorItem<String> item) {
          void close() {
            setState((){
              item.isExpanded = false;
            });
          }

          return new Form(
            child: new Builder(
              builder: (BuildContext context) {
                return new CollapsibleBody(
                  onSave: () { Form.of(context).save(); close(); },
                  onCancel: () { Form.of(context).reset(); close(); },
                  child: new FormField<String>(
                    initialValue: item.value,
                    onSaved: (String value) {
                      item.value = value;
                      currentData["location"] = value;
                    },
                    builder: (FormFieldState<String> field){
                      return new Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          new ListTile(
                            title: new Text(item.valueToString(field.value)),
                            trailing: new Icon(Icons.create),
                            onTap: () async {
                              final String chosen = await pickFromCategory(
                                context: context,
                                category: "locations",
                                initialObject: field.value,
                              );
                              if (chosen != null && chosen != field.value){
                                field.onChanged(chosen);
                              }
                            }
                          )
                        ]
                      );
                    }
                  ),
                );
              },
            ),
          );
        }
      ),
      new CreatorItem<String>(
        name: "Customer",
        value: widget.jobData != null ? widget.jobData["customer"] : null,
        hint: "Who is this job for?",
        valueToString: (String customerID) {
          if (customerID != null){
            Map<String, dynamic> customerData = firebase.getObject("customers", customerID);
            return customerData["name"];
          } else {
            return "Select a customer";
          }
        },
        builder: (CreatorItem<String> item) {
          void close() {
            setState((){
              item.isExpanded = false;
            });
          }

          return new Form(
            child: new Builder(
              builder: (BuildContext context) {
                return new CollapsibleBody(
                  onSave: () { Form.of(context).save(); close(); },
                  onCancel: () { Form.of(context).reset(); close(); },
                  child: new FormField<String>(
                    initialValue: item.value,
                    onSaved: (String value){
                      item.value = value;
                      currentData["customer"] = value;
                    },
                    builder: (FormFieldState<String> field){
                      return new Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          new ListTile(
                            title: new Text(item.valueToString(item.value)),
                            trailing: new Icon(Icons.create),
                            onTap: () async {
                              final String chosen = await pickFromCategory(
                                context: context,
                                category: "customers",
                                initialObject: field.value,
                              );
                              if (chosen != null && chosen != field.value){
                                field.onChanged(chosen);
                              }
                            }
                          )
                        ]
                      );
                    }
                  ),
                );
              }
            )
          );
        }
      ),
      new CreatorItem<List<String>>( // Contacts
        name: "Contacts",
        value: widget.jobData != null ? widget.jobData['contacts'] : <String>[],
        hint: "Who is involved with this job?",
        valueToString: (List<String> value) => value.length.toString(),
        builder: (CreatorItem<List<String>> item){
          void close() {
            setState((){
              item.isExpanded = false;
            });
          }
          List<String> removeContact(List<String> conList, String contactID){
            List<String> updated = new List<String>.from(conList);
            updated.remove(contactID);
            return updated;
          }
          
          List<String> addContact(List<String> conList, String contactID){
            List<String> updated = new List<String>.from(conList);
            updated.add(contactID);
            return updated;
          }
          
          return new Form(
            child: new Builder(
              builder: (BuildContext context) {
                return new CollapsibleBody(
                  onSave: () { Form.of(context).save(); close(); },
                  onCancel: () { Form.of(context).reset(); close(); },
                  child: new FormField<List<String>>(
                    initialValue: item.value,
                    onSaved: (List<String> value) {
                      item.value = value;
                      currentData["contacts"] = value;
                    },
                    builder: (FormFieldState<List<String>> field){
                      Column x =  new Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: field.value.map((String contactID){
                          Map<String, dynamic> conData = firebase.getObject("contacts", contactID);
                          return new Chip(
                            label: new Text(conData["name"]),
                            onDeleted: () {
                              field.onChanged(removeContact(field.value, contactID));
                            }
                          );
                        }).toList()
                      );
                      x.children.insert(0, new ListTile(
                        title: new Text("Add a contact"),
                        trailing: new Icon(Icons.add),
                        onTap: () async {
                          final String chosen = await pickFromCategory(
                            context: context,
                            category: "contacts",
                          );
                          if (chosen != null && !field.value.contains(chosen)){
                            field.onChanged(addContact(field.value, chosen));
                          }
                        }
                      ));
                      return x;
                    }
                  ),
                );
              }
            ),
          );
        }
      )
      // TODO: Billing [po, billed?]
      // TODO: Notes
    ];
  }

  Widget build(BuildContext build){
    return(new Container(
      padding: const EdgeInsets.fromLTRB(8.0, 28.0, 8.0, 12.0),
      child: new Card(
        child: new ListView(
          children: <Widget>[
            new ExpansionPanelList(
              expansionCallback: (int index, bool isExpanded) {
                setState((){
                  _items[index].isExpanded = !isExpanded;
                });
              },
              children: _items.map((CreatorItem<dynamic> item){
                return new ExpansionPanel(
                  isExpanded: item.isExpanded,
                  headerBuilder: item.headerBuilder,
                  body: item.builder(item)
                );
              }).toList()
            ),
            new ButtonBar(
              children: <Widget>[
                new FlatButton(
                  child: new Text("Cancel"),
                  onPressed: (){ Navigator.pop(context); }
                ),
                new FlatButton(
                  child: new Text("Save & Finish"),
                  textColor: Theme.of(context).accentColor,
                  onPressed: () async {
                     await firebase.sendObject("jobs", currentData, objID: widget.jobID);
                  }
                )
              ]
            )
          ]
        )
      )
    ));
  }
}