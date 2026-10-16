// Google refuses to sign in inside apps' built-in browsers (Facebook,
// Messenger, Instagram… — error "disallowed_useragent"), and volunteers
// often open the app from a Facebook link. Detecting that lets the app ask
// them to open the page in a real browser instead of failing silently.
export 'in_app_browser_stub.dart'
    if (dart.library.html) 'in_app_browser_web.dart';
