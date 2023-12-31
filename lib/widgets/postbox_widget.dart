import 'package:flutter/material.dart';
import 'package:memo_re/utils/vars.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

Widget buildGrid() {
  User? user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return Center(
      child: Text(
        '로그인 해주세요',
        style: TextStyle(
          fontFamily: 'CafeAir',
          fontSize: 15,
          color: Colors.black,
        ),
      ),
    );
  }

  String userId = user.uid;

  return SingleChildScrollView(
    child: StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('user')
          .doc(userId)
          .collection('posts')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('오류가 발생했습니다.'));
        }

        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        var posts = snapshot.data!.docs;

        if (posts.isEmpty) {
          return Center(child: Text('게시물이 없습니다.'));
        }

        return GridView.builder(
          padding: EdgeInsets.all(18),
          itemCount: posts.length,
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 200, // 최대 너비를 200으로 설정
            crossAxisSpacing: 18.0,
            mainAxisSpacing: 18.0,
            childAspectRatio: 3 / 4, // 너비와 높이의 비율을 3:4로 설정
          ),
          itemBuilder: (context, index) {
            var post = posts[index];
            var imageUrl = post['imageUrl'];
            var postId = post.id;

            if (imageUrl == null) {
              return Center(child: Text('이미지를 불러올 수 없습니다.'));
            }

            return GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    var postText = post['text']; // 컬렉션에서 텍스트 데이터를 가져옵니다.
                    return AlertDialog(
                      content: SingleChildScrollView( // SingleChildScrollView로 감싸서 스크롤 가능하도록 설정
                        child: Column(
                          mainAxisSize: MainAxisSize.min, // Column의 크기를 내용물에 맞게 조절합니다.
                          children: <Widget>[
                            Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                            ),
                            SizedBox(height: 10), // 이미지와 텍스트 사이에 간격을 추가합니다.
                            ListTile(
                              title: Text(
                                postText ?? '텍스트가 없습니다.',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                      actions: <Widget>[
                        ElevatedButton(
                          onPressed: () {
                            _showDeleteConfirmation(context, postId);
                          },
                          style: ElevatedButton.styleFrom(
                            primary: AppColors.primaryColor(),
                          ),
                          child: Text('삭제'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            // 다이얼로그 닫기
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            primary: AppColors.primaryColor(),
                          ),
                          child: Text('닫기'),
                        ),
                      ],
                    );
                  },
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20.0), // 모서리를 둥글게 만듭니다.
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return SizedBox.shrink();
                  },
                ),
              ),
            );
          },
          shrinkWrap: true,
          physics: ClampingScrollPhysics(),
        );
      },
    ),
  );
}

// post 삭제 확인 알림 함수
Future<void> _showDeleteConfirmation(BuildContext context, String postId) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false, // user must tap button for close
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: Text('게시물 삭제'),
        content: Text('정말로 삭제하시겠습니까?'),
        actions: <Widget>[
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              primary: AppColors.primaryColor(),
            ),
            child: Text('아니오'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(); // 다이얼로그 닫기
              Navigator.of(dialogContext).pop();
              _deletePost(context, postId); // 게시물 삭제 함수 호출
            },
            style: ElevatedButton.styleFrom(
              primary: AppColors.primaryColor(),
            ),
            child: Text('예'),
          ),
        ],
      );
    },
  );
}

// post 삭제 함수
Future<void> _deletePost(BuildContext context, String postId) async {
  try {
    // Retrieve the document to get the imageUrl
    DocumentSnapshot postDocument = await FirebaseFirestore.instance
        .collection('user')
        .doc(FirebaseAuth.instance.currentUser
        ?.uid) // Ensure you have the correct uid here
        .collection('posts')
        .doc(postId)
        .get();

    if (postDocument.exists) {
      var data = postDocument.data() as Map<String, dynamic>;
      String? imageUrl = data['imageUrl'];

      await FirebaseFirestore.instance
          .collection('user')
          .doc(FirebaseAuth.instance.currentUser
          ?.uid) // Again, ensure the correct uid
          .collection('posts')
          .doc(postId)
          .delete();

      if (imageUrl != null && imageUrl.isNotEmpty) {
        Reference storageReference = FirebaseStorage.instance.refFromURL(
        imageUrl);
        await storageReference.delete();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('게시물이 삭제되었습니다.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('해당 게시물을 찾을 수 없습니다.')),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('게시물을 삭제하는 중 오류가 발생했습니다.')),
    );
  }
}