import 'package:flutter/material.dart';
import '../models/comment_model.dart';
import 'package:intl/intl.dart';

class CommentItem extends StatelessWidget {
  final Comment comment;
  final bool isMe;

  const CommentItem({Key? key, required this.comment, required this.isMe}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (comment.isSystemMessage) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            comment.text,
            style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
          ),
        ),
      );
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4),
        padding: EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue[100] : Colors.white,
          borderRadius: BorderRadius.only(
             topLeft: Radius.circular(12),
             topRight: Radius.circular(12),
             bottomLeft: isMe ? Radius.circular(12) : Radius.zero,
             bottomRight: isMe ? Radius.zero : Radius.circular(12),
          ),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))]
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMe) ...[
               Text(comment.userName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blue[800])),
               SizedBox(height: 4),
            ],
            Text(comment.text),
            SizedBox(height: 4),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(comment.timestamp)),
                style: TextStyle(fontSize: 10, color: Colors.black54),
              ),
            )
          ],
        ),
      ),
    );
  }
}
