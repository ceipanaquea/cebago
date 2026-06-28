import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://lqdxnvcaxbgupagwiygc.supabase.co',
    anonKey: 'sb_publishable_ANSzfNjqeI2ZMpBDvjYXyA_HgZn_yvs',
  );

  runApp(const MyApp());
}
