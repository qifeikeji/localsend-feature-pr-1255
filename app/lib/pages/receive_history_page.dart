import 'package:flutter/material.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/widget/lists/receive_history_list_body.dart';
import 'package:localsend_app/widget/responsive_list_view.dart';

class ReceiveHistoryPage extends StatelessWidget {
  const ReceiveHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t.receiveHistoryPage.title),
      ),
      body: ResponsiveListView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        children: const [
          ReceiveHistoryListBody(),
        ],
      ),
    );
  }
}
