import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:Wiggle2/games/compatibility.dart/compatibilityStart.dart';
import 'package:Wiggle2/screens/home/othersProfile.dart';
import 'package:Wiggle2/shared/constants.dart';
import 'package:Wiggle2/models/wiggle.dart';
import 'package:Wiggle2/services/database.dart';
import 'package:Wiggle2/shared/loading.dart';
import '../../games/trivia/trivia.dart';
import '../../models/user.dart';
import 'wiggle_list.dart';

class ConversationScreen extends StatefulWidget {
  final String chatRoomId;
  final Wiggle wiggle;
  final List<Wiggle> wiggles;
  final UserData userData;

  ConversationScreen(
      {this.wiggles, this.chatRoomId, this.wiggle, this.userData});

  @override
  _ConversationScreenState createState() => _ConversationScreenState();
}

final f = new DateFormat('h:mm a');

class _ConversationScreenState extends State<ConversationScreen> {
  String message;
  TextEditingController messageTextEditingController =
      new TextEditingController();

  ScrollController scrollController = new ScrollController();

  Stream<QuerySnapshot> chatMessagesStream;

  Widget chatMessageList() {
    return StreamBuilder(
      stream: chatMessagesStream,
      builder: (context, snapshot) {
        return snapshot.hasData
            ? ListView.builder(
                controller: scrollController,
                itemCount: snapshot.data.documents.length,
                itemBuilder: (context, index) {
                  return MessageTile(
                      type: snapshot.data.documents[index].data["type"],
                      message: snapshot.data.documents[index].data["message"],
                      isSendByMe:
                          snapshot.data.documents[index].data["email"] ==
                              Constants.myEmail,
                      time: f
                          .format(snapshot.data.documents[index].data["time"]
                              .toDate())
                          .toString());
                })
            : Container();
      },
    );
  }

  sendMessage() {
    if (message.isNotEmpty) {
      Map<String, dynamic> messageMap = {
        "message": message,
        "sendBy": Constants.myName,
        "time": Timestamp.now(),
        "email": Constants.myEmail,
        "type": 'message'
      };
      DatabaseService().addConversationMessages(widget.chatRoomId, messageMap);
      DatabaseService()
          .feedReference
          .document(widget.wiggle.email)
          .collection('feed')
          .add({
        'type': 'message',
        'msgInfo': message,
        'ownerID': widget.wiggle.email,
        'ownerName': widget.wiggle.name,
        'timestamp': DateTime.now(),
        'userDp': widget.userData.dp,
        'userID': widget.userData.name,
      });

      setState(() {
        saveReceivercloud(widget.wiggle);
        message = "";
        messageTextEditingController.clear();
      });
    }
  }

  saveReceivercloud(Wiggle wiggle) async {
    QuerySnapshot query =
        await DatabaseService().getReceivertoken(wiggle.email);
    String val = query.documents[0].data['token'].toString();
    DatabaseService().cloudReference.document().setData({
      'type': 'message',
      'ownerID': wiggle.email,
      'ownerName': wiggle.name,
      'timestamp': DateTime.now(),
      'userDp': widget.userData.dp,
      'userID': widget.userData.name,
      'token': val,
    });
  }

  @override
  void initState() {
    DatabaseService().getConversationMessages(widget.chatRoomId).then((val) {
      setState(() {
        chatMessagesStream = val;
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User>(context);
    return StreamBuilder<UserData>(
      stream: DatabaseService(uid: user.uid).userData,
      builder: (context, snapshot) {
        UserData userData = snapshot.data;
        if (userData != null) {
          return GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Scaffold(
              resizeToAvoidBottomPadding: true,
              backgroundColor: Color.fromRGBO(3, 9, 23, 1),
              appBar: AppBar(
                backgroundColor: Colors.blueGrey,
                title: Row(
                  children: <Widget>[
                    CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 23,
                      child: ClipOval(
                        child: SizedBox(
                          width: 180,
                          height: 180,
                          child: Image.network(
                                widget.wiggle.dp,
                                fit: BoxFit.fill,
                              ) ??
                              Image.asset('assets/images/profile1.png',
                                  fit: BoxFit.fill),
                        ),
                      ),
                    ),
                    FlatButton(
                      color: Colors.blueGrey,
                      child: Text(widget.wiggle.name),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => OthersProfile(
                              wiggles: widget.wiggles,
                              wiggle: widget.wiggle,
                              userData: userData,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                actions: <Widget>[
                  IconButton(
                    icon: Icon(Icons.gamepad),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CompatibilityStart(
                              friendAnon: false,
                              userData: widget.userData,
                              wiggle: widget.wiggle,
                              wiggles: widget.wiggles),
                        ),
                      );
                    },
                  ),
                ],
              ),
              body: Stack(
                children: <Widget>[
                  chatMessageList(),
                  // Divider(height: 2),
                  Container(
                    alignment: Alignment.bottomCenter,
                    width: MediaQuery.of(context).size.width,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Row(
                      children: <Widget>[
                        Container(
                          child: Expanded(
                            child: TextFormField(
                              controller: messageTextEditingController,
                              onChanged: (val) {
                                setState(() => message = val);
                                Future.delayed(Duration(milliseconds: 100), () {
                                  scrollController.animateTo(
                                      scrollController.position.maxScrollExtent,
                                      duration: Duration(milliseconds: 500),
                                      curve: Curves.ease);
                                });
                              },
                              style: TextStyle(color: Colors.white),
                              decoration: InputDecoration.collapsed(
                                  hintText: "Send a message...",
                                  hintStyle: TextStyle(color: Colors.white54),
                                  border: InputBorder.none),
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        GestureDetector(
                          onTap: () {
                            sendMessage();
                          },
                          child: Container(
                            height: 40,
                            width: 40,
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(40),
                            ),
                            padding: EdgeInsets.all(12),
                            child: Image.asset('assets/images/send.png'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        } else {
          return Loading();
        }
      },
    );
  }
}

class MessageTile extends StatelessWidget {
  final String message;
  final bool isSendByMe;
  final String time;
  final String type;

  MessageTile({this.message, this.isSendByMe, this.time, this.type});

  //delete msg
  //edit msg

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        padding: EdgeInsets.only(
            top: 8,
            bottom: 8,
            left: isSendByMe ? 0 : 24,
            right: isSendByMe ? 24 : 0),
        alignment: isSendByMe ? Alignment.centerRight : Alignment.centerLeft,
        width: MediaQuery.of(context).size.width,
        child: Container(
          margin: isSendByMe
              ? EdgeInsets.only(left: 30)
              : EdgeInsets.only(right: 30),
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          decoration: BoxDecoration(
            color: (type == 'message')
                ? (isSendByMe ? Colors.blueGrey : Colors.indigoAccent)
                : Colors.red,
            borderRadius: isSendByMe
                ? BorderRadius.only(
                    topLeft: Radius.circular(23),
                    topRight: Radius.circular(23),
                    bottomLeft: Radius.circular(23),
                  )
                : BorderRadius.only(
                    topLeft: Radius.circular(23),
                    topRight: Radius.circular(23),
                    bottomRight: Radius.circular(23),
                  ),
          ),
          child: Container(
            child: Column(
              crossAxisAlignment: isSendByMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  child: Text(
                    time,
                    textAlign: TextAlign.end,
                  ),
                ),
                Text(
                  message,
                  textAlign: TextAlign.start,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: 'OverpassRegular',
                      fontWeight: FontWeight.w300),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}