import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import '../firebase.dart' as firebase;
import 'creatorCards.dart';

class JobCard extends StatefulWidget {
  final String jobID;
  final Map<String, dynamic> jobData;

  JobCard(this.jobID, this.jobData);
  
  
  @override
  JobCardState createState() => new JobCardState();
}

class JobCardState extends State<JobCard> {

  List<Widget> cardLines = <Widget>[];

  void goEdit(BuildContext context){
    showDialog(
      context: context,
      child: new CreatorCard("jobs", data: widget.jobData),
    );
  }

  void populateLines (){
    DateFormat formatter = new DateFormat("h:mm a, EEEE, MMMM d");
    Map<String, dynamic> locationData = firebase.getObject("locations", widget.jobData["location"]);
    String address = '${locationData["address"]}, ${locationData["city"]}, ${locationData["state"]}';
    cardLines.add(
      new Container(
        height: 200.0,
        child: new Stack(
          children: <Widget>[
            new Positioned.fill(
              child: new Image(
                image: new AssetImage('assets/placeholder.jpg')
              )
            ),
            new Positioned(
              left: 8.0,
              bottom: 16.0,
              child: new Text(
                widget.jobData["name"],
                style: new TextStyle(
                  color: Colors.white,
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold
                ))
            )
          ]
        )
      )
    );
    cardLines.add(
      new ListTile(
        leading: new Icon(Icons.access_time),
        title: new Text(formatter.format(DateTime.parse(widget.jobData["datetime"])))
      )
    );
    cardLines.add(
      new ListTile(
        title: new Text(address),
        trailing: new IconButton(
          icon: new Icon(Icons.navigation),
          onPressed: () {
            url_launcher.launch('google.navigation:q=$address');
          }
        ),
        onTap: (){
          // TODO: Popup a Location preview
        }
      )
    );
    cardLines.add(new Divider());
    widget.jobData["contacts"].forEach((String contactID) {
      Map<String, dynamic> contactData = firebase.getObject("contacts", contactID);
      cardLines.add(new ListTile(
        title: new Text(contactData["name"]),
        trailing: new IconButton(
          icon: new Icon(Icons.phone),
          onPressed: (){
            url_launcher.launch('tel:${contactData["phone"]}');
          }
        ),
        onTap: () {} // TODO: Launch a contact details card.
      ));
    });
    cardLines.add(new ButtonTheme.bar(
      child: new ButtonBar(
        children: <Widget>[
          new FlatButton(
            child: new Text('Edit info'),
            onPressed: () {
              goEdit(context);
            }
          ),
          new FlatButton(
            child: new Text('Reports'),
            onPressed: () {}
          ),
        ]
      )
    ));
  }

  @override
  void initState(){
    super.initState();
    populateLines();
  }

  @override
  Widget build(BuildContext context){
    return new Container(
      padding: const EdgeInsets.fromLTRB(8.0, 28.0, 8.0, 12.0),
      child: new Card(
        child: new ListView(
          children: new List<Widget>.from(cardLines)
        )
      )
    );
  }
}