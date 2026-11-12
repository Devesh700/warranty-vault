export 'local_file_store_stub.dart'
    if (dart.library.io) 'local_file_store_native.dart'
    if (dart.library.js_interop) 'local_file_store_web.dart';
