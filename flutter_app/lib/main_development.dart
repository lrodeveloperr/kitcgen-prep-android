import 'package:kitchen_prep_board/app/app.dart';
import 'package:kitchen_prep_board/bootstrap.dart';

Future<void> main() async {
  await bootstrap(() => const App());
}
