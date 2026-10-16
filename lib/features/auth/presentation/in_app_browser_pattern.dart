/// User-agent markers of embedded browsers Google blocks sign-in from:
/// Facebook/Messenger (FBAN, FBAV, FB_IAB, FBIOS), Instagram, LINE, WeChat,
/// and generic Android WebViews ("; wv)").
final inAppBrowserUserAgent = RegExp(
  r'FBAN|FBAV|FB_IAB|FBIOS|Instagram|\bLine/|MicroMessenger|; wv\)',
);
