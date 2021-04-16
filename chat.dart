import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_widgets/flutter_widgets.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:giphy_picker/giphy_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart';
import 'package:laid/Controllers/firebaseController.dart';
import 'package:laid/Controllers/notificationController.dart';
import 'package:laid/Controllers/pickImageController.dart';
import 'package:laid/Controllers/utils.dart';
import 'package:laid/chatbox/setting.dart';
import 'package:laid/chatbox/slider.dart';
import 'package:laid/chatbox/widget/full_photo.dart';
import 'package:laid/chatbox/widget/loading.dart';
import 'package:laid/pages/openpost.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:laid/profile/body.dart';
import 'package:swipe_to/swipe_to.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:badges/badges.dart';
import 'package:linkable/linkable.dart';
import 'package:laid/events/openevent.dart';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_audio_recorder/flutter_audio_recorder.dart';
import 'package:path_provider/path_provider.dart';

class ChatRoom extends StatefulWidget {
  ChatRoom(
    this.myID,
    this.myName,
    this.selectedUserToken,
    this.selectedUserID,
    this.chatID,
    this.color,
    this.selectedUserThumbnail,
  );

  String myID;
  String myName;
  String selectedUserToken;
  String selectedUserID;
  String chatID;
  String color;
  String selectedUserThumbnail;
  String usercolor;
  @override
  _ChatRoomState createState() => _ChatRoomState();
}

class _ChatRoomState extends State<ChatRoom> {
  final TextEditingController _msgTextController = new TextEditingController();
  final ScrollController _chatListController = ScrollController();
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  List<Reference> references;

  bool _isLoading = false;
  int chatListLength = 20;
  double _scrollPosition = 60;
  _scrollListener() {
    // print(_scrollPosition);
    // print(_chatListController.position.pixels);

    setState(() {
      if (_scrollPosition < _chatListController.position.pixels) {
        setState(() {
          _scrollPosition = _scrollPosition + 560;
          chatListLength = chatListLength + 20;
        });

        print(chatListLength);
      }
    });
  }

  bool _isUploading = false;
  bool _isRecorded = false;
  bool _isRecording = false;
  AudioPlayer _audioPlayer = AudioPlayer();
  String _filePath;
  FlutterAudioRecorder _audioRecorder;
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

  @override
  void initState() {
    _chatListController.addListener(_scrollListener);
    myFocusNode = FocusNode();
    final Completer<Map<String, dynamic>> completer =
        Completer<Map<String, dynamic>>();

    _firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> textFromTextField) async {
        completer.complete(textFromTextField);

        print("onLaunch:");
      },
      onBackgroundMessage: myBackgroundMessageHandler,
      onLaunch: (Map<String, dynamic> textFromTextField) async {
        print("onLaunch: $textFromTextField");
        completer.complete(textFromTextField);
      },
      onResume: (Map<String, dynamic> textFromTextField) async {
        print("onResume: $textFromTextField");
        completer.complete(textFromTextField);
      },
    );
    super.initState();
  }

  @override
  void dispose() {
    myFocusNode.dispose();
    super.dispose();
  }

  int countchat(myID, snapshot) {
    int resultInt = snapshot.data.documents.length;

    return resultInt;
  }

  String username;
  String content;
  bool reply = false;
  double replyheight = 0;
  FocusNode myFocusNode;
  bool status;
  @override
  Widget build(BuildContext context) {
    var screenSize = MediaQuery.of(context).size;
    var widthh = screenSize.width;
    var heightt = screenSize.height;
    return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          iconTheme: IconThemeData(
            color: Colors.white, //change your color here
          ),
          elevation: 0,
          backgroundColor: Colors.grey.withOpacity(0.1),
          actions: [
            IconButton(
              onPressed: () async {
                status = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return ChatSetting(
                        chatId: widget.chatID,
                        chatWith: widget.selectedUserID,
                      );
                    },
                  ),
                );
              },
              icon: Icon(
                FontAwesomeIcons.questionCircle,
                color: Colors.white,
              ),
            ),
          ],
          title: GestureDetector(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return Profile(
                      widget.selectedUserID,
                      widget.color,
                      widget.myName,
                    );
                  },
                ),
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: Container(
                    color: HexColor('#${widget.color}'),
                    child: CachedNetworkImage(
                      width: widthh * 0.08,
                      imageUrl: widget.selectedUserThumbnail,
                      placeholder: (context, url) =>
                          CircularProgressIndicator(),
                      errorWidget: (context, url, error) => Icon(Icons.error),
                    ),
                  ),
                ),
                SizedBox(
                  width: 10,
                ),
                Text(
                  widget.myName,
                  style: GoogleFonts.lato(
                    textStyle: TextStyle(
                        color: Colors.white, fontSize: widthh * 0.050),
                  ),
                ),
                SizedBox(
                  width: 5,
                ),
                Icon(
                  FontAwesomeIcons.chevronRight,
                  color: Colors.white,
                  size: widthh * 0.05,
                )
              ],
            ),
          ),
          centerTitle: true,
        ),
        body: Stack(
          children: [
            VisibilityDetector(
              key: Key("1"),
              onVisibilityChanged: ((visibility) {
                print('ChatRoom Visibility code is ' +
                    '${visibility.visibleFraction}');
                if (visibility.visibleFraction == 1.0) {
                  FirebaseController.instanace.getUnreadMSGCount();
                }
              }),
              child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('chatroom')
                      .doc(widget.chatID)
                      .collection(widget.chatID)
                      .orderBy('timestamp', descending: true)
                      .limit(chatListLength)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return LinearProgressIndicator();
                    if (snapshot.hasData) {
                      for (var data in snapshot.data.docs) {
                        if (data['idTo'] == widget.myID &&
                            data['isread'] == false) {
                          if (data.reference != null) {
                            FirebaseFirestore.instance.runTransaction(
                                (Transaction myTransaction) async {
                              myTransaction
                                  .update(data.reference, {'isread': true});
                            });
                          }
                        }
                      }
                    }
                    return Stack(
                      children: <Widget>[
                        Column(
                          children: <Widget>[
                            Expanded(
                              child: ListView.builder(
                                  controller: _chatListController,
                                  key: _listKey,
                                  reverse: true,
                                  shrinkWrap: true,
                                  padding:
                                      const EdgeInsets.fromLTRB(4.0, 10, 4, 10),
                                  itemCount: snapshot.data.docs.length,
                                  itemBuilder: (context, index) {
                                    DocumentSnapshot data =
                                        snapshot.data.docs[index];
                                    return data.data()['idFrom'] ==
                                            widget.selectedUserID
                                        ? _listItemOther(
                                            context,
                                            widget.myName,
                                            widget.selectedUserThumbnail,
                                            data.data()['content'],
                                            data.data()['timestamp'],
                                            data.data()['type'],
                                            data.data()['color'],
                                            data.data()['name'],
                                            data.data()['postuid'],
                                            data.data()['reply'],
                                            data.data()['createdAt'],
                                            data.data()['image'],
                                            data.data()['like'],
                                            data.data()['play'],
                                          )
                                        : _listItemMine(
                                            context,
                                            data.data()['content'],
                                            returnTimeStamp(data['timestamp']),
                                            data.data()['isread'],
                                            data.data()['type'],
                                            data.data()['color'],
                                            data.data()['name'],
                                            data.data()['postuid'],
                                            data.data()['timestamp'],
                                            data.data()['reply'],
                                            data.data()['createdAt'],
                                            data.data()['image'],
                                            data.data()['like'],
                                            data.data()['play'],
                                            data.data()['delete'],
                                          );
                                  }),
                            ),
                            Stack(
                              children: [
                                reply == true
                                    ? Container(
                                        width: widthh,
                                        height: heightt * 0.13,
                                        margin: EdgeInsets.only(
                                            top: heightt * 0.01),
                                        padding: EdgeInsets.only(
                                          left: widthh * 0.03,
                                          top: heightt * 0.01,
                                          right: widthh * 0.03,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border(
                                            top: BorderSide(
                                              width: widthh * 0.001,
                                              //                   <--- top side
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  'Replying to $username',
                                                  style: GoogleFonts.lato(
                                                    textStyle: TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: widthh * 0.03,
                                                    ),
                                                  ),
                                                ),
                                                GestureDetector(
                                                  child: Icon(
                                                    FontAwesomeIcons.times,
                                                    color: Colors.white
                                                        .withOpacity(0.6),
                                                  ),
                                                  onTap: () {
                                                    setState(() {
                                                      reply = false;
                                                      replyheight = 0;
                                                    });
                                                  },
                                                ),
                                              ],
                                            ),
                                            Text(
                                              content,
                                              style: GoogleFonts.lato(
                                                textStyle: TextStyle(
                                                  color: Colors.white
                                                      .withOpacity(0.6),
                                                ),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      )
                                    : Container(),
                                Column(
                                  children: [
                                    Container(
                                        width: widthh,
                                        height: heightt * 0.06,
                                        padding: EdgeInsets.only(
                                          left: heightt * 0.02,
                                        ),
                                        margin: EdgeInsets.only(
                                          top: heightt * replyheight,
                                        ),
                                        decoration: BoxDecoration(
                                          // borderRadius: BorderRadius.circular(100),
                                          color: Colors.white.withOpacity(0.1),
                                        ),
                                        child: _buildTextComposer()),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    );
                  }),
            ),
          ],
        ));
  }

  Widget _listItemOther(
      BuildContext context,
      String name,
      String thumbnail,
      String message,
      int time,
      String type,
      String color,
      String title,
      String postuid,
      String replied,
      String createdAt,
      String image,
      bool like,
      bool play) {
    var screenSize = MediaQuery.of(context).size;
    var widthh = screenSize.width;
    var heightt = screenSize.height;
    if (type == 'text') {
      return Container(
          padding: EdgeInsets.only(top: widthh * 0.02, left: widthh * 0.02),
          width: 1000,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return Profile(
                          widget.selectedUserID,
                          widget.color,
                          widget.myName,
                        );
                      },
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: Container(
                    decoration: BoxDecoration(
                      color: HexColor('#${widget.color}'),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 5,
                          blurRadius: 7,
                          offset: Offset(0, 3), // changes position of shadow
                        ),
                      ],
                    ),
                    child: CachedNetworkImage(
                      width: widthh * 0.09,
                      imageUrl: thumbnail,
                      placeholder: (context, url) =>
                          CircularProgressIndicator(),
                      errorWidget: (context, url, error) => Icon(Icons.error),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 10,
              ),
              Expanded(
                child: GestureDetector(
                  onDoubleTap: () async {
                    print(widget.selectedUserToken);
                    final FirebaseAuth auth = FirebaseAuth.instance;
                    final User user = auth.currentUser;
                    final useruid = user.uid;
                    DocumentReference userstotal = FirebaseFirestore.instance
                        .collection('chatroom')
                        .doc(widget.chatID)
                        .collection(widget.chatID)
                        .doc(time.toString());
                    userstotal.update({
                      'like': true,
                    }).then((value) {});
                    DocumentSnapshot variable = await FirebaseFirestore.instance
                        .collection('user')
                        .doc(useruid)
                        .get();
                    await NotificationController.instance
                        .sendNotificationMessageToPeerUser(
                            '1',
                            'text',
                            'liked your message',
                            variable.data()['name'],
                            widget.chatID,
                            widget.selectedUserToken);
                  },
                  onLongPress: () {
                    showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return Dialog(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    2.0)), //this right here
                            child: Wrap(
                              children: [
                                Align(
                                  alignment: Alignment.center,
                                  child: Text(
                                    '',
                                    style: GoogleFonts.lato(
                                      textStyle: TextStyle(
                                          color: Colors.black,
                                          fontSize: widthh * 0.04),
                                    ),
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.center,
                                  child: Text(
                                    returnTimeStamp(time),
                                    style: TextStyle(
                                      fontSize: widthh * 0.03,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                Center(
                                  child: FlatButton(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                    ),
                                    onPressed: () {
                                      Clipboard.setData(
                                          new ClipboardData(text: "$message"));
                                      Navigator.pop(context);
                                    },
                                    child: Text(
                                      "Copy",
                                      style: GoogleFonts.lato(
                                        textStyle: TextStyle(
                                            color: Colors.black,
                                            fontSize: widthh * 0.04),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        });
                  },
                  child: SwipeTo(
                    onRightSwipe: () {
                      setState(() {
                        username = name;
                        content = message;
                        reply = true;
                        replyheight = 0.08;
                      });
                      FocusScope.of(context).requestFocus(myFocusNode);
                    },
                    child: Container(
                      // padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(100),
                            bottomLeft: Radius.circular(20),
                            bottomRight: Radius.circular(100)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          like == true
                              ? Badge(
                                  badgeColor: Colors.white.withOpacity(0.1),
                                  badgeContent: Icon(
                                    FontAwesomeIcons.solidHeart,
                                    color: Colors.red,
                                    size: widthh * 0.031,
                                  ),
                                  child: Container(
                                    // margin: EdgeInsets.only(right: widthh * 0.1),
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(4),
                                          topRight: Radius.circular(100),
                                          bottomLeft: Radius.circular(20),
                                          bottomRight: Radius.circular(100)),
                                      color: Colors.white.withOpacity(0.1),
                                    ),
                                    child: Linkable(
                                      textColor: Colors.white.withOpacity(0.8),
                                      text: message,
                                      style: GoogleFonts.lato(
                                        textStyle:
                                            TextStyle(fontSize: widthh * 0.035),
                                      ),
                                    ),
                                  ),
                                )
                              : Container(
                                  // margin: EdgeInsets.only(right: widthh * 0.1),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(4),
                                        topRight: Radius.circular(100),
                                        bottomLeft: Radius.circular(20),
                                        bottomRight: Radius.circular(100)),
                                    color: Colors.white.withOpacity(0.1),
                                  ),
                                  child: Linkable(
                                    textColor: Colors.white.withOpacity(0.8),
                                    text: message,
                                    style: GoogleFonts.lato(
                                      textStyle:
                                          TextStyle(fontSize: widthh * 0.035),
                                    ),
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ));
    } else if (type == 'reply') {
      return Container(
          padding: EdgeInsets.only(top: widthh * 0.01, left: widthh * 0.02),
          width: 50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return Profile(
                          widget.selectedUserID,
                          widget.color,
                          widget.myName,
                        );
                      },
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: Container(
                    decoration: BoxDecoration(
                      color: HexColor('#${widget.color}'),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 5,
                          blurRadius: 7,
                          offset: Offset(0, 3), // changes position of shadow
                        ),
                      ],
                    ),
                    child: CachedNetworkImage(
                      width: widthh * 0.09,
                      imageUrl: thumbnail,
                      placeholder: (context, url) =>
                          CircularProgressIndicator(),
                      errorWidget: (context, url, error) => Icon(Icons.error),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: widthh * 0.006,
              ),
              Expanded(
                child: GestureDetector(
                  onDoubleTap: () async {
                    final FirebaseAuth auth = FirebaseAuth.instance;
                    final User user = auth.currentUser;
                    final useruid = user.uid;
                    DocumentReference userstotal = FirebaseFirestore.instance
                        .collection('chatroom')
                        .doc(widget.chatID)
                        .collection(widget.chatID)
                        .doc(time.toString());
                    userstotal.update({
                      'like': true,
                    }).then((value) {});
                    DocumentSnapshot variable = await FirebaseFirestore.instance
                        .collection('user')
                        .doc(useruid)
                        .get();
                    await NotificationController.instance
                        .sendNotificationMessageToPeerUser(
                            '1',
                            'text',
                            'liked your message',
                            variable.data()['name'],
                            widget.chatID,
                            widget.selectedUserToken);
                  },
                  onLongPress: () {
                    showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return Dialog(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    2.0)), //this right here
                            child: Wrap(
                              children: [
                                Align(
                                  alignment: Alignment.center,
                                  child: Text(
                                    '',
                                    style: GoogleFonts.lato(
                                      textStyle: TextStyle(
                                          color: Colors.black,
                                          fontSize: widthh * 0.04),
                                    ),
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.center,
                                  child: Text(
                                    returnTimeStamp(time),
                                    style: TextStyle(
                                      fontSize: widthh * 0.03,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                Center(
                                  child: FlatButton(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                    ),
                                    onPressed: () {
                                      Clipboard.setData(
                                          new ClipboardData(text: "$message"));
                                      Navigator.pop(context);
                                    },
                                    child: Text(
                                      "Copy",
                                      style: GoogleFonts.lato(
                                        textStyle: TextStyle(
                                            color: Colors.black,
                                            fontSize: widthh * 0.04),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        });
                  },
                  child: SwipeTo(
                    onRightSwipe: () {
                      setState(() {
                        username = name;
                        content = message;
                        reply = true;
                        replyheight = 0.08;
                      });
                      FocusScope.of(context).requestFocus(myFocusNode);
                    },
                    child: Container(
                      margin: EdgeInsets.only(right: widthh * 0.1),
                      padding: const EdgeInsets.only(left: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(100),
                            bottomLeft: Radius.circular(20),
                            bottomRight: Radius.circular(100)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Container(
                            // margin: EdgeInsets.only(right: widthh * 0.2),
                            padding: const EdgeInsets.only(bottom: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(4),
                                  topRight: Radius.circular(100),
                                  bottomLeft: Radius.circular(20),
                                  bottomRight: Radius.circular(100)),
                            ),
                            child: Text(
                              ('Replied to you'),
                              overflow: TextOverflow.visible,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                          like == true
                              ? Badge(
                                  badgeColor: Colors.white.withOpacity(0.1),
                                  badgeContent: Icon(
                                    FontAwesomeIcons.solidHeart,
                                    color: Colors.red,
                                    size: widthh * 0.031,
                                  ),
                                  child: Container(
                                    // margin: EdgeInsets.only(right: widthh * 0.07),
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(4),
                                          topRight: Radius.circular(100),
                                          bottomLeft: Radius.circular(20),
                                          bottomRight: Radius.circular(100)),
                                      color:
                                          HexColor('#6200EE').withOpacity(0.3),
                                    ),
                                    child: Text(
                                      ('$replied'),
                                      overflow: TextOverflow.visible,
                                      style: TextStyle(
                                          fontSize: widthh * 0.04,
                                          color: Colors.white),
                                    ),
                                  ),
                                )
                              : Container(
                                  // margin: EdgeInsets.only(right: widthh * 0.07),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(4),
                                        topRight: Radius.circular(100),
                                        bottomLeft: Radius.circular(20),
                                        bottomRight: Radius.circular(100)),
                                    color: HexColor('#6200EE').withOpacity(0.6),
                                  ),
                                  child: Text(
                                    ('$replied'),
                                    overflow: TextOverflow.visible,
                                    style: TextStyle(
                                        fontSize: widthh * 0.04,
                                        color: Colors.white),
                                  ),
                                ),
                          SizedBox(
                            height: 1,
                          ),
                          Container(
                            margin: EdgeInsets.only(right: widthh * 0.2),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(4),
                                  topRight: Radius.circular(100),
                                  bottomLeft: Radius.circular(20),
                                  bottomRight: Radius.circular(100)),
                              color: Colors.white.withOpacity(0.1),
                            ),
                            child: Text(
                              ('$message'),
                              style: TextStyle(
                                fontSize: widthh * 0.04,
                                color: Colors.white.withOpacity(0.8),
                              ),
                              overflow: TextOverflow.visible,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ));
    } else {
      return GestureDetector(
        onTap: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => FullPhoto(url: message)));
        },
        child: Container(
          margin: EdgeInsets.only(
              right: widthh * 0.2, top: heightt * 0.02, left: 15),
          child: message == 'loading'
              ? Loading()
              : Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CachedNetworkImage(
                      imageUrl: message,
                      placeholder: (context, url) => Container(
                        transform: Matrix4.translationValues(0, 0, 0),
                        child: Container(
                            width: 60,
                            height: 80,
                            child:
                                Center(child: new CircularProgressIndicator())),
                      ),
                      errorWidget: (context, url, error) =>
                          new Icon(Icons.error),
                      width: widthh,
                      height: heightt * 0.32,
                      fit: BoxFit.cover,
                    ),
                    type == 'camera'
                        ? Container(
                            // margin: EdgeInsets.only(left: widthh * 0.2),
                            child: Text(
                            'Camera',
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ))
                        : Container(),
                  ],
                ),
        ),
      );
    }
  }

  Widget _listItemMine(
    BuildContext context,
    String message,
    String time,
    bool isRead,
    String type,
    String color,
    String title,
    String postuid,
    int timestampdelete,
    String replied,
    String createdAt,
    String image,
    bool like,
    bool play,
    String delete,
  ) {
    final size = MediaQuery.of(context).size;
    var screenSize = MediaQuery.of(context).size;
    var widthh = screenSize.width;
    var heightt = screenSize.height;
    if (type == 'text') {
      return GestureDetector(
        onLongPress: () {
          showDialog(
              context: context,
              builder: (BuildContext context) {
                return Dialog(
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(2.0)), //this right here
                  child: Wrap(
                    children: [
                      Align(
                        alignment: Alignment.center,
                        child: Text(
                          '',
                          style: GoogleFonts.lato(
                            textStyle: TextStyle(
                                color: Colors.black, fontSize: widthh * 0.04),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.center,
                        child: Text(
                          time,
                          style: GoogleFonts.lato(
                            textStyle: TextStyle(
                                color: Colors.black, fontSize: widthh * 0.04),
                          ),
                        ),
                      ),
                      Center(
                        child: FlatButton(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          onPressed: () {
                            CollectionReference users1 = FirebaseFirestore
                                .instance
                                .collection('chatroom')
                                .doc(widget.chatID)
                                .collection(widget.chatID);
                            users1
                                .doc(delete.toString())
                                .delete()
                                .then((value) => print("User Deleted"))
                                .catchError((error) =>
                                    print("Failed to delete user: $error"));
                            Navigator.pop(context);
                          },
                          child: Text(
                            "Unsend",
                            style: GoogleFonts.lato(
                              textStyle: TextStyle(
                                  color: Colors.black, fontSize: widthh * 0.04),
                            ),
                          ),
                        ),
                      ),
                      Center(
                        child: FlatButton(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          onPressed: () {
                            Clipboard.setData(
                                new ClipboardData(text: "$message"));
                            Navigator.pop(context);
                          },
                          child: Text(
                            "Copy",
                            style: GoogleFonts.lato(
                              textStyle: TextStyle(
                                  color: Colors.black, fontSize: widthh * 0.04),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              });
        },
        child: Container(
            padding: EdgeInsets.only(top: widthh * 0.01),
            width: 1000,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                like == true
                    ? Badge(
                        position: BadgePosition.topStart(),
                        badgeColor: Colors.white.withOpacity(0.1),
                        badgeContent: Icon(
                          FontAwesomeIcons.solidHeart,
                          color: Colors.red,
                          size: widthh * 0.031,
                        ),
                        child: Container(
                          // margin: EdgeInsets.only(left: widthh * 0.2),
                          padding: const EdgeInsets.only(
                              left: 20, right: 10, top: 10, bottom: 10),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(30),
                                  topRight: Radius.circular(4),
                                  bottomLeft: Radius.circular(30),
                                  bottomRight: Radius.circular(30)),
                              color: HexColor('#6200EE').withOpacity(0.8)),
                          child: Linkable(
                            textColor: Colors.white.withOpacity(0.8),
                            text: message,
                            style: GoogleFonts.lato(
                              textStyle: TextStyle(fontSize: widthh * 0.035),
                            ),
                          ),
                        ),
                      )
                    : Flexible(
                        child: Container(
                          // width: widthh * 0.7,
                          margin: EdgeInsets.only(left: widthh * 0.2),
                          padding: const EdgeInsets.only(
                              left: 20, right: 10, top: 10, bottom: 10),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(30),
                                  topRight: Radius.circular(4),
                                  bottomLeft: Radius.circular(30),
                                  bottomRight: Radius.circular(30)),
                              color: HexColor('#6200EE').withOpacity(0.8)),
                          child: Wrap(
                            children: [
                              Linkable(
                                textColor: Colors.white.withOpacity(0.8),
                                text: message,
                                style: GoogleFonts.lato(
                                  textStyle:
                                      TextStyle(fontSize: widthh * 0.035),
                                ),
                              ),
                              SizedBox(
                                width: widthh * 0.01,
                              ),
                              isRead
                                  ? Icon(
                                      FontAwesomeIcons.checkDouble,
                                      size: widthh * 0.035,
                                      color: Colors.blue,
                                    )
                                  : Icon(
                                      FontAwesomeIcons.check,
                                      size: widthh * 0.035,
                                      color: Colors.grey,
                                    ),
                            ],
                          ),
                        ),
                      ),
                SizedBox(
                  height: 5,
                ),
                // Text(
                //   time,
                //   style: TextStyle(
                //     fontSize: 10,
                //     color: widget.dark == false
                //         ? Colors.white.withOpacity(0.8)
                //         : Colors.black,
                //   ),
                // ),
              ],
            )),
      );
    } else if (type == 'reply') {
      return GestureDetector(
          onLongPress: () {
            showDialog(
                context: context,
                builder: (BuildContext context) {
                  return Dialog(
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(2.0)), //this right here
                    child: Wrap(
                      children: [
                        Align(
                          alignment: Alignment.center,
                          child: Text(
                            '',
                            style: GoogleFonts.lato(
                              textStyle: TextStyle(
                                  color: Colors.black, fontSize: widthh * 0.04),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.center,
                          child: Text(
                            time,
                            style: GoogleFonts.lato(
                              textStyle: TextStyle(
                                  color: Colors.black, fontSize: widthh * 0.04),
                            ),
                          ),
                        ),
                        Center(
                          child: FlatButton(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            onPressed: () {
                              CollectionReference users1 = FirebaseFirestore
                                  .instance
                                  .collection('chatroom')
                                  .doc(widget.chatID)
                                  .collection(widget.chatID);
                              users1
                                  .doc(delete.toString())
                                  .delete()
                                  .then((value) => print("User Deleted"))
                                  .catchError((error) =>
                                      print("Failed to delete user: $error"));
                              Navigator.pop(context);
                            },
                            child: Text(
                              "Unsend",
                              style: GoogleFonts.lato(
                                textStyle: TextStyle(
                                    color: Colors.black,
                                    fontSize: widthh * 0.04),
                              ),
                            ),
                          ),
                        ),
                        Center(
                          child: FlatButton(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            onPressed: () {
                              Clipboard.setData(
                                  new ClipboardData(text: "$message"));
                              Navigator.pop(context);
                            },
                            child: Text(
                              "Copy",
                              style: GoogleFonts.lato(
                                textStyle: TextStyle(
                                    color: Colors.black,
                                    fontSize: widthh * 0.04),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                });
          },
          child: Container(
              alignment: Alignment.topRight,
              padding: EdgeInsets.only(top: widthh * 0.01),
              width: 1000,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Container(
                    // margin: EdgeInsets.only(left: widthh * 0.4),
                    padding: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(4),
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30)),
                    ),
                    child: Text(
                      ('you Replied'),
                      overflow: TextOverflow.visible,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  like == true
                      ? Badge(
                          position: BadgePosition.topStart(),
                          badgeColor: Colors.white.withOpacity(0.1),
                          badgeContent: Icon(
                            FontAwesomeIcons.solidHeart,
                            color: Colors.red,
                            size: widthh * 0.031,
                          ),
                          child: Container(
                            // padding: const EdgeInsets.only(
                            //     left: 10, right: 10, top: 10, bottom: 10),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(30),
                                    topRight: Radius.circular(4),
                                    bottomLeft: Radius.circular(30),
                                    bottomRight: Radius.circular(30)),
                                color: Colors.white.withOpacity(0.065)),
                            child: Text(
                              ('$replied'),
                              overflow: TextOverflow.visible,
                              style: TextStyle(
                                fontSize: widthh * 0.04,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.only(
                              left: 10, right: 10, top: 10, bottom: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(30),
                                topRight: Radius.circular(4),
                                bottomLeft: Radius.circular(30),
                                bottomRight: Radius.circular(30)),
                            color: Colors.white.withOpacity(0.065),
                          ),
                          child: Text(
                            ('$replied'),
                            overflow: TextOverflow.visible,
                            style: TextStyle(
                              fontSize: widthh * 0.04,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ),
                  Container(
                    margin: EdgeInsets.only(top: 5),
                    padding: const EdgeInsets.only(
                        left: 20, right: 10, top: 10, bottom: 10),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(30),
                            topRight: Radius.circular(4),
                            bottomLeft: Radius.circular(30),
                            bottomRight: Radius.circular(30)),
                        color: HexColor('#6200EE').withOpacity(0.8)),
                    child: Wrap(
                      children: [
                        Text(
                          ('$message'),
                          overflow: TextOverflow.visible,
                          style: TextStyle(
                              color: Colors.white, fontSize: widthh * 0.04),
                        ),
                        SizedBox(
                          width: widthh * 0.01,
                        ),
                        isRead
                            ? Icon(
                                FontAwesomeIcons.checkDouble,
                                size: 15,
                                color: Colors.blue,
                              )
                            : Icon(
                                FontAwesomeIcons.check,
                                size: 15,
                                color: Colors.grey,
                              ),
                      ],
                    ),
                  ),
                ],
              )));
    } else {
      return GestureDetector(
        onTap: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => FullPhoto(url: message)));
        },
        onLongPress: () {
          showDialog(
              context: context,
              builder: (BuildContext context) {
                return Dialog(
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(2.0)), //this right here
                  child: Wrap(
                    children: [
                      Center(
                        child: FlatButton(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          onPressed: () {
                            CollectionReference users1 = FirebaseFirestore
                                .instance
                                .collection('chatroom')
                                .doc(widget.chatID)
                                .collection(widget.chatID);
                            users1
                                .doc(delete.toString())
                                .delete()
                                .then((value) => print("User Deleted"))
                                .catchError((error) =>
                                    print("Failed to delete user: $error"));
                            Navigator.pop(context);
                          },
                          child: Text(
                            "Unsend",
                            style: GoogleFonts.lato(
                              textStyle: TextStyle(
                                  color: Colors.black, fontSize: widthh * 0.04),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              });
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              margin: EdgeInsets.only(
                  left: widthh * 0.2, top: heightt * 0.02, right: 15),
              child: message == 'loading'
                  ? Loading()
                  : CachedNetworkImage(
                      imageUrl: message,
                      placeholder: (context, url) => Container(
                        transform: Matrix4.translationValues(0, 0, 0),
                        child: Container(
                            width: 60,
                            height: 80,
                            child:
                                Center(child: new CircularProgressIndicator())),
                      ),
                      errorWidget: (context, url, error) =>
                          new Icon(Icons.error),
                      width: widthh,
                      height: heightt * 0.32,
                      fit: BoxFit.cover,
                    ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                type == 'camera'
                    ? Container(
                        margin: EdgeInsets.only(left: widthh * 0.2),
                        child: Text(
                          'Camera',
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ))
                    : Container(),
                isRead
                    ? Container(
                        margin: EdgeInsets.only(right: 15),
                        child: Icon(
                          FontAwesomeIcons.checkDouble,
                          size: 15,
                          color: Colors.blue,
                        ),
                      )
                    : Container(
                        margin: EdgeInsets.only(right: 15),
                        child: Icon(
                          FontAwesomeIcons.check,
                          size: 15,
                          color: Colors.grey,
                        ),
                      ),
              ],
            ),
          ],
        ),
      );
    }
  }

  Widget _buildTextComposer() {
    return new IconTheme(
      data: new IconThemeData(color: Colors.blue),
      child: new Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        child: new Row(
          children: <Widget>[
            new Flexible(
              child: new TextFormField(
                keyboardType: TextInputType.multiline,
                maxLines: null,
                focusNode: myFocusNode,
                controller: _msgTextController,
                validator: MultiValidator([
                  RequiredValidator(errorText: ''),
                ]),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                ),
                decoration: new InputDecoration.collapsed(
                    hintText: "Message...",
                    hintStyle: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withOpacity(0.6),
                    )),
              ),
            ),
            new Container(
              margin: new EdgeInsets.symmetric(horizontal: 2.0),
              child: new IconButton(
                  icon: new Icon(FontAwesomeIcons.solidPaperPlane),
                  onPressed: () {
                    _handleSubmitted(_msgTextController.text,
                        reply == true ? "reply" : 'text');
                  }),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSubmitted(String text, String type) async {
    if (text.trim() == '') {
      return Container();
    }
    int timedelete = DateTime.now().millisecondsSinceEpoch;

    try {
      _msgTextController.clear();
      setState(() {
        reply = false;
        replyheight = 0;
      });

      await FirebaseController.instanace
          .sendMessageToChatRoomreply(widget.chatID, widget.myID,
              widget.selectedUserID, text, type, username, content, timedelete)
          .whenComplete(() {});

      await FirebaseController.instanace.updateChatRequestField(
        widget.selectedUserID,
        text,
        widget.chatID,
        widget.myID,
        widget.selectedUserID,
      );
      await FirebaseController.instanace.updateChatRequestField(
        widget.myID,
        text,
        widget.chatID,
        widget.myID,
        widget.selectedUserID,
      );

      DocumentSnapshot noti = await FirebaseFirestore.instance
          .collection('chatroom')
          .doc(widget.chatID)
          .collection(widget.chatID)
          .doc(timedelete.toString())
          .get();
      DocumentSnapshot variable = await FirebaseFirestore.instance
          .collection('user')
          .doc(widget.myID)
          .get();
      if (noti.data()['isread'] != true) {
        await NotificationController.instance.sendNotificationMessageToPeerUser(
            1,
            'text',
            text,
            variable.data()['name'],
            widget.chatID,
            widget.selectedUserToken);
      }

      // DocumentSnapshot variable = await FirebaseFirestore.instance
      //     .collection('user')
      //     .doc(widget.myID)
      //     .get();
      // await NotificationController.instance.sendNotificationMessageToPeerUser(
      //     1,
      //     'text',
      //     text,
      //     variable.data()['name'],
      //     widget.chatID,
      //     widget.selectedUserToken);
    } catch (e) {}
  }
}
