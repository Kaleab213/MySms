import 'package:flutter/material.dart';
import 'package:sms_maintained/sms.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter SMS App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: SMSHomePage(title: 'Flutter SMS App'),
    );
  }
}

class SMSHomePage extends StatefulWidget {
  SMSHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _SMSHomePageState createState() => _SMSHomePageState();
}

class _SMSHomePageState extends State<SMSHomePage> {
  int _currentIndex = 0;

  final _tabs = [
    SendMessagePage(),
    ReceivedMessagesPage(),
    SentMessagesPage(),
  ];

  void _onBottomNavigationItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: _tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onBottomNavigationItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.send),
            label: 'Send',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inbox),
            label: 'Received',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sentiment_satisfied),
            label: 'Sent',
          ),
        ],
      ),
    );
  }
}

class SendMessagePage extends StatefulWidget {
  @override
  _SendMessagePageState createState() => _SendMessagePageState();
}

class _SendMessagePageState extends State<SendMessagePage> {
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  void _sendSms() async {
    SmsSender sender = SmsSender();
    String messageText = _messageController.text.trim();
    List<String> phoneNumbers = _phoneNumberController.text.trim().split(',');
    phoneNumbers = phoneNumbers.map((number) => number.trim()).toList();
    for (String phoneNumber in phoneNumbers) {
      if (phoneNumber.isNotEmpty && messageText.isNotEmpty) {
        SmsMessage message = SmsMessage(phoneNumber, messageText);
        sender.sendSms(message).then((value) {
          setState(() {
            _messageController.clear();
            _phoneNumberController.clear();
            MessageStorage().addSentMessage(
                'Sent:\nTo: $phoneNumber\nDate: ${message.date}\n\nMessage:\n$messageText');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Message sent to $phoneNumber')),
            );
          });
        }).catchError((error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to send message to $phoneNumber')),
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 183.0, right: 16.0, left: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          TextField(
            controller: _phoneNumberController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _messageController,
            keyboardType: TextInputType.text,
            decoration: const InputDecoration(
              labelText: 'Message',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _sendSms,
            child: const Text('Send SMS'),
          ),
        ],
      ),
    );
  }
}

class ReceivedMessagesPage extends StatefulWidget {
  @override
  _ReceivedMessagesPageState createState() => _ReceivedMessagesPageState();
}

class _ReceivedMessagesPageState extends State<ReceivedMessagesPage> {
  @override
  void initState() {
    super.initState();
    _startReceivingSms();
  }

  void _startReceivingSms() {
    SmsReceiver receiver = SmsReceiver();
    receiver.onSmsReceived.listen((SmsMessage message) {
      setState(() {
        MessageStorage().addReceivedMessage(
            'Received:\nFrom: ${message.address}\nDate: ${message.date}\n\nMessage:\n${message.body}');
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Received Messages:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            itemCount: MessageStorage().receivedMessages.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.blue.withOpacity(0.1),
                  ),
                  padding: const EdgeInsets.all(8.0),
                  child: Text(MessageStorage().receivedMessages[index]),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class SentMessagesPage extends StatefulWidget {
  @override
  _SentMessagesPageState createState() => _SentMessagesPageState();
}

class _SentMessagesPageState extends State<SentMessagesPage> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Sent Messages:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            itemCount: MessageStorage().sentMessages.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.blue.withOpacity(0.1),
                  ),
                  padding: const EdgeInsets.all(8.0),
                  child: Text(MessageStorage().sentMessages[index]),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class MessageStorage {
  static final MessageStorage _singleton = MessageStorage._internal();

  factory MessageStorage() {
    return _singleton;
  }

  MessageStorage._internal();

  List<String> receivedMessages = [];
  List<String> sentMessages = [];

  void addReceivedMessage(String message) {
    receivedMessages.insert(0, message);
  }

  void addSentMessage(String message) {
    sentMessages.insert(0, message);
  }
}
