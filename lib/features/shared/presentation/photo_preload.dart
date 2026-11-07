// Starts downloading photos so the browser has them cached by the time a
// list shows them. Only the web build has a browser cache to fill.
export 'photo_preload_stub.dart'
    if (dart.library.html) 'photo_preload_web.dart';
