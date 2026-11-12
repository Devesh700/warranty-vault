import 'package:drift/drift.dart';

QueryExecutor openAppConnection() {
  throw UnsupportedError('No database implementation found for this platform.');
}

QueryExecutor openInMemoryConnection() {
  throw UnsupportedError('No in-memory database implementation found.');
}
