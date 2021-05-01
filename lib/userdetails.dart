import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
class Userdetails{
  User _loggedInUser;
  final _firestore = FirebaseFirestore.instance;
  var Usermessage ;
  final _auth = FirebaseAuth.instance;

  String _email;
  String _DataOfBirth;
  String _Gender;
  Map<String,dynamic> _results;
  Future<User> getCurrentUser() async {
    try {
      final user = await _auth.currentUser;
      //print(user);
      if (user != null) {
        _loggedInUser = user ;
      }
      else{
        print("No User Is Valid");
        throw "No User";
      }

    }catch(e){
      print(e);
    }
    return _loggedInUser;
  }
  void getData() async {
    _loggedInUser = await getCurrentUser();
    var document = await _firestore.collection('Information').get();
    var messages = document.docs;
    //print(messages);
    for (var message in messages) {
      //print(document.docs.length);
      var dataEmails = message.data()["email"].toString();
      //print(dataEmails);
      //print(_loggedInUser.email);
        if(dataEmails == _loggedInUser.email){
          Usermessage = await message;
          break;
        }
    }
    parseUserData();
  }
  void parseUserData(){
    _email = Usermessage["email"].toString();
    _Gender = Usermessage["Gender"].toString();
    _DataOfBirth = Usermessage["DataOfBirth"].toString();
    _results = Usermessage["result"];
    print(_email);
    print(_Gender);
    print(_DataOfBirth);
    print(_results);
  }
  String getEmail(){
    return _email;
  }
  String getdataOfBirth(){
    return _DataOfBirth;
  }
  String getGender(){
    return _Gender;
  }
  Map<String,dynamic> getresults(){
    return _results;
  }
  void UserSignOut() async{
    await _auth.signOut();
  }
}