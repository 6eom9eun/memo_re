import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:memo_re/widgets/postbox_widget.dart';
import 'package:memo_re/screens/writePage.dart';
import 'package:provider/provider.dart';
import 'package:memo_re/providers/loginProvider.dart';
import 'package:memo_re/utils/vars.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backColor(),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Consumer<LoginProvider>(
                  builder: (context, provider, child) {
                    if (provider.userInformation != null) {
                      return Column(
                        children: [
                          SizedBox(height: 80),
                          CircleAvatar(
                            backgroundImage: NetworkImage(provider.userInformation!.profileUrl),
                            radius: 35,
                            backgroundColor: Colors.transparent,
                          ),
                          Text(
                            provider.userInformation!.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 23,
                            ),
                          ),
                          Text(
                            'remind your memory',
                            style: TextStyle(
                              color: Color(0xFFAAAAAA),
                              fontSize: 16,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.only(top: 0),
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: buildGrid(),
                            ),
                          )
                        ],
                      );
                    } else {
                      return CircularProgressIndicator();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
              context,
              CupertinoPageRoute(
              builder: (context) => WritePage(),
              ),
          );
        },
        child: Icon(Icons.create, size: 35),
        backgroundColor: Color(0xFFFFCF52),
        elevation: 10,
        highlightElevation: 15,
      ),
    );
  }
}