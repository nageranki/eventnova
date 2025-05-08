import 'package:dropdown_search/dropdown_search.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker_bdaya/flutter_datetime_picker_bdaya.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Event_request extends StatefulWidget {
  Event_request({required this.userType});
  final String userType;

  @override
  State<Event_request> createState() => _Event_requestState();
}

class _Event_requestState extends State<Event_request> {
  // Firebase instances
  final _auth = FirebaseAuth.instance;
  User? loggedInUser;
  final _firestore = FirebaseFirestore.instance;

  // Form state
  String eventName = '',
      formattedDate = '',
      formattedStartTime = '',
      formattedEndTime = '',
      description = '',
      club = 'NONE';
  String? venue = 'OUTSIDE CAMPUS',
      associatedFacultyMail = 'Select';
  List<String> venuesList       = ['OUTSIDE CAMPUS','ECR','ELT','Courtyard'];
  List<String> clubsList        = ['NONE','OutReach', 'BlockChain'];
  List<String> facultyEmailList = ['Select'];
  List<String> facultyNameList  = ['Select'];

  // Computed list of required faculty emails
  List<String> requiredFacs = [];
  late int clashFlag;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
    _getAllVenues();
    _getAllFaculties();
    _getAllClubs();
  }

  // Fetch the currently logged in user
  void _getCurrentUser() {
    final user = _auth.currentUser;
    if (user != null) {
      setState(() => loggedInUser = user);
    }
  }

  // Load venues into the dropdown
  void _getAllVenues() async {
    await for (var snap in _firestore.collection('Venues').snapshots()) {
      for (var doc in snap.docs) {
        setState(() => venuesList.add(doc.data()['Name'] as String));
      }
    }
  }

  // Load faculty details into dropdown lists
  void _getAllFaculties() async {
    final snap = await _firestore.collection('Faculty User Details').get();
    for (var doc in snap.docs) {
      setState(() {
        facultyEmailList.add(doc.data()['Email']  as String);
        facultyNameList .add(doc.data()['Name']   as String);
      });
    }
  }

  // Load clubs into dropdown
  void _getAllClubs() async {
    final snap = await _firestore.collection('Clubs').get();
    for (var doc in snap.docs) {
      setState(() => clubsList.add(doc.data()['Name'] as String));
    }
  }

  // Helper to display faculty name when you only have their email
  Widget facultyNameFromMailWidget(String mail) {
    for (int i = 0; i < facultyEmailList.length; i++) {
      if (facultyEmailList[i] == mail) {
        return Text(facultyNameList[i]);
      }
    }
    return Text('');
  }

  String facultyNameFromMailString(String mail) {
    for (int i = 0; i < facultyEmailList.length; i++) {
      if (facultyEmailList[i] == mail) {
        return facultyNameList[i];
      }
    }
    return ' ';
  }

  // Compute which faculties are required based on club, venue, and department HOD
  Future<void> _computeRequiredFaculties() async {
    requiredFacs.clear();

    // Club advisor
    final clubSnap = await _firestore
        .collection('Clubs')
        .where('Name', isEqualTo: club)
        .get();
    if (clubSnap.docs.isNotEmpty) {
      requiredFacs.add(clubSnap.docs.first.data()['Faculty Advisor Email'] as String);
    }

    // Venue in-charge
    final venueSnap = await _firestore
        .collection('Venues')
        .where('Name', isEqualTo: venue)
        .get();
    if (venueSnap.docs.isNotEmpty) {
      requiredFacs.add(venueSnap.docs.first.data()['Faculty Email'] as String);
    }

    // Department HOD based on whether user is student or faculty
    final userCollection = widget.userType == 'STUDENT'
        ? 'Student User Details'
        : 'Faculty User Details';
    final userSnap = await _firestore
        .collection(userCollection)
        .where('Email', isEqualTo: loggedInUser!.email)
        .get();
    if (userSnap.docs.isNotEmpty) {
      final dept = userSnap.docs.first.data()['Department'] as String;
      final deptSnap = await _firestore
          .collection('Departments')
          .where('Name', isEqualTo: dept)
          .get();
      if (deptSnap.docs.isNotEmpty) {
        requiredFacs.add(deptSnap.docs.first.data()['HOD Email'] as String);
      }
    }
  }

  // Title widget
  Widget _title() => Padding(
    padding: const EdgeInsets.fromLTRB(6.5, 10, 0, 0),
    child: Text(
      'Event Request',
      style: TextStyle(
        fontSize: 40,
        fontWeight: FontWeight.w700,
        color: Color(0xffe46b10),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 40),
              _title(),
              SizedBox(height: 30),

              // ──────────────────────────────────────────
              // 1) Event Name
              // ──────────────────────────────────────────
              Text('Event Name',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              SizedBox(height: 10),
              TextField(
                onChanged: (val) => eventName = val,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  fillColor: Color(0xfff3f3f4),
                  filled: true,
                ),
              ),

              SizedBox(height: 20),

              // ──────────────────────────────────────────
              // 2) Date Picker
              // ──────────────────────────────────────────
              Text('Date',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  DatePickerBdaya.showDatePicker(
                    context,
                    showTitleActions: true,
                    minTime: DateTime.now(),
                    maxTime: DateTime(2025, 12, 31),
                    onConfirm: (dt) => setState(() {
                      formattedDate = DateFormat('dd-MM-yyyy').format(dt);
                    }),
                    currentTime: DateTime.now(),
                    locale: LocaleType.en,
                  );
                },
                child: Container(
                  padding: EdgeInsets.all(15),
                  color: Color(0x2FCECECE),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    formattedDate.isEmpty ? 'Select date' : formattedDate,
                    style: TextStyle(fontSize: 15),
                  ),
                ),
              ),

              SizedBox(height: 20),

              // ──────────────────────────────────────────
              // 3) Start Time Picker
              // ──────────────────────────────────────────
              Text('Event Start Time',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  DatePickerBdaya.showTimePicker(
                    context,
                    showTitleActions: true,
                    onConfirm: (dt) => setState(() {
                      formattedStartTime = DateFormat.Hm().format(dt);
                    }),
                    currentTime: DateTime.now(),
                  );
                },
                child: Container(
                  padding: EdgeInsets.all(15),
                  color: Color(0x2FCECECE),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    formattedStartTime.isEmpty
                        ? 'Select start time'
                        : formattedStartTime,
                    style: TextStyle(fontSize: 15),
                  ),
                ),
              ),

              SizedBox(height: 20),

              // ──────────────────────────────────────────
              // 4) End Time Picker
              // ──────────────────────────────────────────
              Text('Event End Time',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  DatePickerBdaya.showTimePicker(
                    context,
                    showTitleActions: true,
                    onConfirm: (dt) => setState(() {
                      formattedEndTime = DateFormat.Hm().format(dt);
                    }),
                    currentTime: DateTime.now(),
                  );
                },
                child: Container(
                  padding: EdgeInsets.all(15),
                  color: Color(0x2FCECECE),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    formattedEndTime.isEmpty
                        ? 'Select end time'
                        : formattedEndTime,
                    style: TextStyle(fontSize: 15),
                  ),
                ),
              ),

              SizedBox(height: 20),

              // ──────────────────────────────────────────
              // 5) Venue Dropdown
              // ──────────────────────────────────────────
              Text('Venue',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              SizedBox(height: 8),
              DropdownButton<String>(
                isExpanded: true,
                value: venue,
                items: venuesList
                    .map((v) => DropdownMenuItem(
                  value: v,
                  child: Text(v),
                ))
                    .toList(),
                onChanged: (v) => setState(() => venue = v),
              ),

              SizedBox(height: 20),

              // ──────────────────────────────────────────
              // 6) Club Dropdown
              // ──────────────────────────────────────────
              Text('Associated Club',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              SizedBox(height: 8),
              DropdownButton<String>(
                isExpanded: true,
                value: club,
                items: clubsList
                    .map((c) => DropdownMenuItem(
                  value: c,
                  child: Text(c),
                ))
                    .toList(),
                onChanged: (c) => setState(() => club = c!),
              ),

              SizedBox(height: 20),

              // ──────────────────────────────────────────
              // 7) Event Description
              // ──────────────────────────────────────────
              Text('Event Description',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              SizedBox(height: 10),
              TextFormField(
                maxLines: 5,
                onChanged: (val) => description = val,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(width: 0.5, color: Colors.grey)),
                  contentPadding: EdgeInsets.all(12),
                ),
              ),

              SizedBox(height: 20),

              // ──────────────────────────────────────────
              // 8) Associated Faculty Email
              // ──────────────────────────────────────────
              Text('Associated Faculty Email',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              SizedBox(height: 8),
              DropdownButton<String>(
                isExpanded: true,
                value: associatedFacultyMail,
                items: facultyEmailList
                    .map((m) => DropdownMenuItem(
                  value: m,
                  child: facultyNameFromMailWidget(m),
                ))
                    .toList(),
                onChanged: (m) => setState(() {
                  associatedFacultyMail = m!;
                }),
              ),

              SizedBox(height: 30),

              // ──────────────────────────────────────────
              // 9) VERIFY BUTTON & DIALOG LOGIC
              // ──────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () async {
                        // 1) basic form validation
                        if (eventName.isEmpty ||
                            formattedDate.isEmpty ||
                            formattedStartTime.isEmpty ||
                            formattedEndTime.isEmpty ||
                            description.isEmpty) {
                          return; // you can show a snackbar if you like
                        }

                        // 2) clash detection
                        clashFlag = 0;
                        final existing = await _firestore
                            .collection('Event Request')
                            .get();
                        for (var ev in existing.docs) {
                          final d = ev.data();
                          if (d['Date'] == formattedDate &&
                              d['Venue'] == venue &&
                              d['Status'] != 'WITHDRAWN' &&
                              d['Status'] != 'REJECTED') {
                            final thisStart = DateFormat("HH:mm")
                                .parse(formattedStartTime);
                            final thisEnd = DateFormat("HH:mm")
                                .parse(formattedEndTime);
                            final dbStart = DateFormat("HH:mm")
                                .parse(d['Event Start Time']);
                            final dbEnd = DateFormat("HH:mm")
                                .parse(d['Event End Time']);

                            if (thisStart.isBefore(dbEnd) &&
                                thisEnd.isAfter(dbStart)) {
                              clashFlag = 1;
                              break;
                            }
                          }
                        }

                        if (clashFlag == 1) {
                          // show clash dialog
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: Text('ATTENTION!!!'),
                              content: Text(
                                  'Your Event Clashes with another Event. Please change the time and try again'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text('OK',
                                      style: TextStyle(color: Colors.white)),
                                  style: TextButton.styleFrom(
                                      backgroundColor: Colors.black),
                                ),
                              ],
                            ),
                          );
                        } else {
                          // show “Verified” dialog with a SUBMIT button
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: Text('Date, Time and Venue Verified'),
                              content: Text('Please Submit the Event'),
                              actions: [
                                TextButton(
                                  onPressed: () async {
                                    // A) Figure out required faculties
                                    await _computeRequiredFaculties();

                                    // B) Fetch & increment the counter
                                    final constRef = _firestore
                                        .collection('Constants')
                                        .doc('gaLPmBXkrPt1m6I31CjJ');
                                    final snap = await constRef.get();
                                    if (!snap.exists) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                          content: Text(
                                              'Constants doc missing')));
                                      return;
                                    }
                                    final rawId = snap.get('Event ID');
                                    int id;
                                    if (rawId is String) {
                                      id = int.tryParse(rawId) ?? 0;
                                    } else if (rawId is num) {
                                      id = rawId.toInt();
                                    } else {
                                      id = 0;
                                    }
                                    id++;

                                    // C) Write back the new ID
                                    await constRef
                                        .update({'Event ID': id});

                                    // D) Add the Event Request
                                    await _firestore
                                        .collection('Event Request')
                                        .add({
                                      'ID':                   id,
                                      'Event Name':           eventName,
                                      'Date':                 formattedDate,
                                      'Event Start Time':     formattedStartTime,
                                      'Event End Time':       formattedEndTime,
                                      'Venue':                venue,
                                      'Event Description':    description,
                                      'FacultIies Involved':  [associatedFacultyMail],
                                      'Generated User':       loggedInUser!.email,
                                      'Status':               'ONGOING',
                                      'TimeStamp':            FieldValue.serverTimestamp(),
                                      'User Type':            widget.userType,
                                      'Club':                 club,
                                      'Required Faculties':   requiredFacs,
                                      'Reason For Removal':   '',
                                      'Rejected User':        '',
                                    });

                                    // close “Verified” dialog
                                    Navigator.pop(context);

                                    // show success
                                    showDialog(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: Text(
                                            'Event Request submitted successfully'),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: Text('OK',
                                                style: TextStyle(
                                                    color: Colors.white)),
                                            style: TextButton.styleFrom(
                                                backgroundColor:
                                                Colors.black),
                                          )
                                        ],
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: EdgeInsets.all(10),
                                    color: Colors.black,
                                    child: Text('SUBMIT',
                                        style:
                                        TextStyle(color: Colors.white)),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.grey.shade200,
                                offset: Offset(2, 4),
                                blurRadius: 5,
                                spreadRadius: 2)
                          ],
                          gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [Colors.black87, Colors.black87]),
                        ),
                        child: Center(
                          child: Text(
                            'VERIFY',
                            style: TextStyle(fontSize: 20, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
