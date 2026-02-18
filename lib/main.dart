import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // TODO: Initialize Hive for local storage
  // await Hive.initFlutter();

  runApp(
    const ProviderScope(
      child: FspecMobileApp(),
    ),
  );
}
