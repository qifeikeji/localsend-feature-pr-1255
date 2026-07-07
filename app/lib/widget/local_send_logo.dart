import 'package:flutter/material.dart';
import 'package:localsend_app/widget/local_send_logo_painter.dart';

class LocalSendLogo extends StatelessWidget {
  final bool withText;

  const LocalSendLogo({required this.withText});

  static const _logoSize = 200.0;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final logo = SizedBox(
      width: _logoSize,
      height: _logoSize,
      child: CustomPaint(
        painter: LocalSendLogoPainter(color: primary),
      ),
    );

    if (withText) {
      return Column(
        children: [
          logo,
          const Text(
            'LocalSend',
            style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }
    return logo;
  }
}
