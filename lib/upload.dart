import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:path/path.dart';
import 'package:async/async.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:skin_cancer_app/userdetails.dart';
import 'dart:convert';
import 'constants.dart';

class Upload extends StatefulWidget {
  @override
  _UploadState createState() => _UploadState();
}

class _UploadState extends State<Upload> {
  File _image;
  final picker = ImagePicker();
  var result;
  bool showSpinner = false;
  final _firestore = FirebaseFirestore.instance;
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  GlobalKey<ScaffoldState> showError(String error) {
    _scaffoldKey.currentState.showSnackBar(SnackBar(
      content: new Text(error),
      duration: new Duration(seconds: 10),
    ));
  }

  Future _getImageFromCamera() async {
    final pickedFile = await picker.getImage(source: ImageSource.camera);
    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }

  Future _getImageFromMemory() async {
    final pickedFile = await picker.getImage(source: ImageSource.gallery);
    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }

  _upload(File imageFile, context) async {
    bool isLoggedin = await Userdetails().Userislogged();
    if (_image == null) {
      _showMyDialog(context, "noimage");
      setState(() {
        showSpinner = false;
      });
      return;
    }

    if (isLoggedin == false) {
      _showMyDialog(context, "loginError");
      setState(() {
        showSpinner = false;
      });
      return;
    }
    var stream =
        // ignore: deprecated_member_use
        new http.ByteStream(DelegatingStream.typed(imageFile.openRead()));
    var length = await imageFile.length();
    var uri = Uri.parse(
        "https://skincancerapi-alexuni.herokuapp.com/API?Email=$userEmail&TestNumber=$lengthOfResults&Format=jpg");
    var request = new http.MultipartRequest("POST", uri);
    var multipartFile = new http.MultipartFile('file', stream, length,
        filename: basename(imageFile.path));
    request.files.add(multipartFile);
    var response = await request.send();
    print(response.statusCode);
    response.stream.transform(utf8.decoder).listen((value) {
      print(value);
      setState(() {
        result = value.toString().substring(0, 4);
        showSpinner = false;
        _showMyDialog(context, "result");
        return;
      });
    });
  }

  Future<void> _showMyDialog(context, String type) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true, // user must tap button!
      builder: (BuildContext context) {
        ListBody ResponseView;
        if (type == "result") {
          if (double.parse(result) > 50) {
            ResponseView = ListBody(
              children: <Widget>[
                Image.asset(
                  'images/danger.png',
                  height: 100,
                  width: 100,
                ),
                SizedBox(
                  height: 15,
                ),
                Text(
                  'Your Image Has $result% Cancer \n\nPlease Visit The Nearest Hospital',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            );
          } else {
            ResponseView = ListBody(
              children: <Widget>[
                Image.asset(
                  'images/True.jpg',
                  height: 100,
                  width: 100,
                ),
                SizedBox(
                  height: 15,
                ),
                Text(
                  'Your Image Has $result% Cancer \n\nYou Are Okay',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            );
          }
          return AlertDialog(
            title: Center(child: Text('Your Result is Ready')),
            content: SingleChildScrollView(
              child: ResponseView,
            ),
            actions: <Widget>[
              TextButton(
                child: Text('Proceed'),
                onPressed: () {
                  addToFireStore();
                  setState(() {
                    _image = null;
                  });
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        } else if (type == "noimage") {
          return AlertDialog(
            title: Text('No Image Selected !'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text('Please Select An Image'),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text('Proceed'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        } else {
          return AlertDialog(
            title: Text('Please Login First'),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text('You need to login before uploading images'),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text('Login'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        }
      },
    );
  }

  // ignore: non_constant_identifier_names
  Widget Animation(String text) {
    // ignore: deprecated_member_use
    return TypewriterAnimatedTextKit(
      text: [text],
      speed: const Duration(milliseconds: 100),
      textStyle: KTextStyleCancer,
    );
  }

  Map<String, dynamic> resultsOfUser;
  int lengthOfResults;
  String userEmail;
  String documentId;
  void getResultAndLength() async {
    bool result = await Userdetails().Userislogged();
    if (result == true) {
      userEmail = await Userdetails().getEmail();
      lengthOfResults = await Userdetails().getlength() + 1;
      resultsOfUser = await Userdetails().getresults();
      documentId = await Userdetails().getDocumentId();
      print(resultsOfUser);
      print(lengthOfResults);
      print(userEmail);
      print(documentId);
    }
  }

  String format = "jpg";
  void addToFireStore() async {
    print(resultsOfUser);
    Map<String, dynamic> resultCombine = resultsOfUser;
    Map<String, dynamic> newPart = {
      "result$lengthOfResults": {
        "Image": "$lengthOfResults.$format",
        "cellType": "0",
        "date": DateTime.now().toString(),
        "percentage": "$result"
      }
    };
    resultCombine.addAll(newPart);
    print(resultCombine);
    await _firestore
        .collection("Information")
        .doc(documentId)
        .update({"result": resultCombine});
  }

  @override
  void initState() {
    super.initState();
    getResultAndLength();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              heroTag: "Add from Memory",
              backgroundColor: Colors.teal,
              onPressed: _getImageFromMemory,
              child: Icon(Icons.add),
            ),
            SizedBox(height: 10),
            FloatingActionButton(
              heroTag: "Add from Camera",
              backgroundColor: Colors.teal,
              onPressed: _getImageFromCamera,
              child: Icon(Icons.add_a_photo),
            )
          ],
        ),
        body: ModalProgressHUD(
          inAsyncCall: showSpinner,
          child: Container(
            child: ListView(
              children: [
                SizedBox(height: 70),
                Row(children: <Widget>[
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Animation("  Cancer"),
                        ),
                        Expanded(child: Image.asset("images/logo.png")),
                        Expanded(
                          child: Animation("    Free"),
                        )
                      ],
                    ),
                  )
                ]),
                Row(
                  children: <Widget>[
                    Expanded(
                        flex: 2,
                        child: Container(
                          child: Column(
                            children: [
                              SizedBox(height: 50),
                              Container(
                                padding: EdgeInsets.fromLTRB(13, 0, 0, 0),
                                width: 240,
                                child: Center(
                                  child: Text(
                                    "It’s Never Too Late, Or Too Early    To Start Preventing Skin Cancer.",
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              Container(
                                margin: EdgeInsets.symmetric(vertical: 20),
                                width: 250,
                                // ignore: deprecated_member_use
                                child: RaisedButton(
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18.0),
                                      side: BorderSide(
                                          color:
                                              Color.fromRGBO(0, 160, 227, 1))),
                                  onPressed: () {
                                    setState(() {
                                      showSpinner = true;
                                      _upload(_image, context);
                                    });
                                  },
                                  padding: EdgeInsets.all(10.0),
                                  color: Colors.teal,
                                  textColor: Colors.white,
                                  child: Text("Get Results",
                                      style: TextStyle(fontSize: 15)),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  _getImageFromMemory();
                                },
                                child: Container(
                                    decoration: BoxDecoration(
                                        color: Colors.black12,
                                        border:
                                            Border.all(color: Colors.black)),
                                    width: 200,
                                    height: 140,
                                    child: _image == null
                                        ? Center(
                                            child: Icon(
                                              Icons.arrow_circle_up,
                                              size: 55,
                                            ),
                                          )
                                        : Image.file(
                                            _image,
                                            fit: BoxFit.fitWidth,
                                          )),
                              ),
                              SizedBox(height: 10),
                              _image == null
                                  ? Text(
                                      "Upload Your Image",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    )
                                  : Text("")
                            ],
                          ),
                          color: Colors.white,
                        ))
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
