import 'package:flutter/material.dart';

import 'router.dart';
import 'theme.dart';

class VidyaLedgerApp extends StatelessWidget {
  const VidyaLedgerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'VidyaLedger',
      debugShowCheckedModeBanner: false,
      theme: buildVidyaLedgerTheme(),
      routerConfig: appRouter,
    );
  }
}
