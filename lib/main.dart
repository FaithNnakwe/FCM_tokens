import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'ArticleScreen.dart';

Future<void> _messageHandler(RemoteMessage message) async {
  print('Background message: ${message.notification?.body}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(_messageHandler);
  runApp(MessagingApp());
}

class MessagingApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FCM Notification App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: NotificationHomePage(title: 'Firebase Messaging Demo'),
    );
  }
}

class NotificationHomePage extends StatefulWidget {
  final String title;
  const NotificationHomePage({Key? key, required this.title}) : super(key: key);

  @override
  State<NotificationHomePage> createState() => _NotificationHomePageState();
}

class _NotificationHomePageState extends State<NotificationHomePage> {
  late FirebaseMessaging messaging;
  String? token;
  List<String> notificationHistory = [];

  @override
  void initState() {
    super.initState();
    messaging = FirebaseMessaging.instance;

    // Subscribe to topic
    messaging.subscribeToTopic("messaging");

    messaging.requestPermission();

    // Get and print token
    messaging.getToken().then((value) {
      print("FCM Token: $value");
      setState(() {
        token = value;
      });
    });

    // Handle notification tap when app is opened from background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (message.data['screen'] == 'articles') {
        Navigator.push(context, MaterialPageRoute(builder: (_) => ArticleScreen()));
      }
    });

    // Handle cold start deep linking
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null && message.data['screen'] == 'articles') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ArticleScreen()),
        );
      }
    });

    // Foreground message handler
    FirebaseMessaging.onMessage.listen((RemoteMessage event) {
      String notificationType = event.data['notificationType'] ?? 'regular';
        String title = event.notification?.title ?? "Notification";
      String body = event.notification?.body ?? "";

        bool isImportant = notificationType == 'important';

      // Save to history
      setState(() {
        notificationHistory.add("${notificationType.toUpperCase()}: $body");
      });

      // Show the notification in a dialog
      showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: isImportant ? Colors.red[100] : null,
        title: Text(
          isImportant ? "🚨 IMPORTANT: $title" : title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isImportant ? Colors.red : Colors.black,
          ),
        ),
        content: Text(
          body,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isImportant ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        actions: [
          TextButton(
            child: Text("OK"),
            onPressed: () => Navigator.of(context).pop(),
          )
        ],
      );
    });
    },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              "FCM Token (for test message):",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SelectableText(token ?? "Fetching token..."),
            const SizedBox(height: 20),
            Text(
              "Notification History",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: notificationHistory.length,
                itemBuilder: (_, index) {
                  return Card(
                    elevation: 2,
                    margin: EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      title: Text(notificationHistory[index]),
                      onTap: () {
            // Check if the tapped notification should lead to a specific screen
            if (notificationHistory[index].contains('IMPORTANT')) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => ArticleScreen()));
            } else{
              Navigator.push(context, MaterialPageRoute(builder: (_) => ArticleScreen()));
            }
          },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
