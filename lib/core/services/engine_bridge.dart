export 'engine_bridge_stub.dart'
    if (dart.library.js_interop) 'engine_bridge_web.dart';

/// Uygulama WebAssembly (dart2wasm + skwasm) derlemesiyle mi çalışıyor;
/// değilse JavaScript (dart2js + CanvasKit).
const bool runningWasm = bool.fromEnvironment('dart.tool.dart2wasm');

/// Görüntüyü çözerken küçültme genişliği (`cacheWidth`). WebAssembly
/// motorunda verilmez: Safari'nin skwasm'ında küçültülmüş görüntü kaymış ve
/// büyütülmüş çiziliyor (yalnız sol üst köşesi görünüyor).
int? decodeWidth(double pixels) => runningWasm ? null : pixels.round();
