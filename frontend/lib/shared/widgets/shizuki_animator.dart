import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/core/constants/app_colors.dart';
import 'package:webview_flutter/webview_flutter.dart';

class _ShizukiLocalAssetServer {
  static final _ShizukiLocalAssetServer instance = _ShizukiLocalAssetServer._();
  _ShizukiLocalAssetServer._();

  static const String _assetPrefix = '/assets/Shizuki_App_Model/';

  HttpServer? _server;
  Uri? _baseUri;
  int _refCount = 0;
  final Map<String, Uint8List> _cache = <String, Uint8List>{};

  Future<Uri> acquire() async {
    _refCount++;
    if (_server != null && _baseUri != null) return _baseUri!;

    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    debugPrint('[Shizuki Server] Started on port ${server.port}');
    server.autoCompress = true;
    server.listen(_handleRequest);

    _server = server;
    _baseUri = Uri.parse('http://${server.address.address}:${server.port}');
    return _baseUri!;
  }

  Future<void> release() async {
    _refCount = (_refCount - 1).clamp(0, 1 << 30);
    if (_refCount > 0) return;
    final server = _server;
    _server = null;
    _baseUri = null;
    _cache.clear();
    if (server != null) {
      await server.close(force: true);
    }
  }

  Future<void> _handleRequest(HttpRequest req) async {
    debugPrint('[Shizuki Server] Received request for: ${req.uri.path}');
    final res = req.response;

    res.headers
      ..set('Access-Control-Allow-Origin', '*')
      ..set('Access-Control-Allow-Methods', 'GET,HEAD,OPTIONS')
      ..set('Access-Control-Allow-Headers', '*')
      ..set('Cross-Origin-Resource-Policy', 'cross-origin')
      ..set('Cache-Control', 'public, max-age=3600');

    if (req.method == 'OPTIONS') {
      res.statusCode = HttpStatus.noContent;
      await res.close();
      return;
    }

    if (req.method != 'GET' && req.method != 'HEAD') {
      res.statusCode = HttpStatus.methodNotAllowed;
      await res.close();
      return;
    }

    var path = req.uri.path;
    if (path == '/' || path.isEmpty) {
      path = '${_assetPrefix}web/index.html';
    }

    if (!path.startsWith(_assetPrefix)) {
      res.statusCode = HttpStatus.notFound;
      await res.close();
      return;
    }

    final assetKey = path.startsWith('/') ? path.substring(1) : path;
    var statusCode = HttpStatus.ok;
    var servedBytes = 0;

    try {
      final bytes = _cache[assetKey] ??= await (() async {
        final byteData = await rootBundle.load(assetKey);
        return byteData.buffer.asUint8List(
          byteData.offsetInBytes,
          byteData.lengthInBytes,
        );
      })();
      _applyContentType(res, assetKey);
      res.contentLength = bytes.length;
      servedBytes = bytes.length;
      if (req.method != 'HEAD') {
        res.add(bytes);
      }
      await res.close();
    } catch (_) {
      statusCode = HttpStatus.notFound;
      res.statusCode = statusCode;
      await res.close();
    }

    debugPrint(
      '[Shizuki Localhost] ${req.method} ${req.uri.path} -> $statusCode ($servedBytes bytes)',
    );
  }

  static void _applyContentType(HttpResponse res, String assetKey) {
    final lower = assetKey.toLowerCase();
    if (lower.endsWith('.json')) {
      res.headers.contentType =
          ContentType('application', 'json', charset: 'utf-8');
    } else if (lower.endsWith('.moc3')) {
      res.headers.contentType = ContentType('application', 'octet-stream');
    } else if (lower.endsWith('.js')) {
      res.headers.contentType =
          ContentType('application', 'javascript', charset: 'utf-8');
    } else if (lower.endsWith('.png')) {
      res.headers.contentType = ContentType('image', 'png');
    } else if (lower.endsWith('.html') || lower.endsWith('.htm')) {
      res.headers.contentType = ContentType('text', 'html', charset: 'utf-8');
    } else if (lower.endsWith('.css')) {
      res.headers.contentType = ContentType('text', 'css', charset: 'utf-8');
    } else if (lower.endsWith('.wasm')) {
      res.headers.contentType = ContentType('application', 'wasm');
    } else {
      res.headers.contentType = ContentType('application', 'octet-stream');
    }
  }
}

enum ShizukiEmotion { idle, cheer, smile, talk, sad, exciting }

enum ShizukiCameraPreset { fullBody, bust }

enum ShizukiLookMode { idle, forward }

class ShizukiTouchEvent {
  const ShizukiTouchEvent({
    required this.region,
    required this.source,
    required this.position,
    this.hitAreas = const <String>[],
  });

  factory ShizukiTouchEvent.fromJson(Map<String, dynamic> json) {
    return ShizukiTouchEvent(
      region: json['region']?.toString() ?? 'default',
      source: json['source']?.toString() ?? 'zone',
      position: Offset(
        (json['x'] as num?)?.toDouble() ?? 0.5,
        (json['y'] as num?)?.toDouble() ?? 0.5,
      ),
      hitAreas: (json['hitAreas'] as List<dynamic>? ?? const <dynamic>[])
          .map((item) => item.toString())
          .toList(growable: false),
    );
  }

  final String region;
  final String source;
  final Offset position;
  final List<String> hitAreas;
}

/// Live2D Cubism 4 mascot via [WebViewWidget] (see `assets/Shizuki_App_Model/web/`).
class ShizukiAnimator extends StatefulWidget {
  const ShizukiAnimator({
    super.key,
    this.emotion = ShizukiEmotion.idle,
    this.size = 280.0,
    this.height,
    this.baseScale = 1.0,
    this.cameraPreset = ShizukiCameraPreset.fullBody,
    this.lookMode = ShizukiLookMode.idle,
    this.talking = false,
    this.zoom = 1.0,
    this.enableTouch = false,
    this.minZoom = 0.85,
    this.maxZoom = 1.6,
    this.resetViewportToken = 0,
    this.onTouch,
    this.onZoomChanged,
    this.transitionDuration = const Duration(milliseconds: 350),
  });

  final ShizukiEmotion emotion;
  final double size;
  final double? height;
  final double baseScale;
  final ShizukiCameraPreset cameraPreset;
  final ShizukiLookMode lookMode;
  final bool talking;
  final double zoom;
  final bool enableTouch;
  final double minZoom;
  final double maxZoom;
  final int resetViewportToken;
  final ValueChanged<ShizukiTouchEvent>? onTouch;
  final ValueChanged<double>? onZoomChanged;
  final Duration transitionDuration;

  @override
  State<ShizukiAnimator> createState() => _ShizukiAnimatorState();
}

class _ShizukiAnimatorState extends State<ShizukiAnimator> {
  static const _assetHtmlUrl = '/assets/Shizuki_App_Model/web/index.html';

  WebViewController? _controller;
  bool _jsReady = false;
  bool _useFallback = false;
  Timer? _fallbackTimer;
  bool _serverAcquired = false;

  @override
  void initState() {
    super.initState();
    _initWebView();
    _fallbackTimer = Timer(const Duration(seconds: 18), () {
      if (!mounted || _jsReady || _useFallback) return;
      setState(() => _useFallback = true);
    });
  }

  Future<void> _initWebView() async {
    final baseUri = await _ShizukiLocalAssetServer.instance.acquire();
    _serverAcquired = true;
    final indexUri = Uri.parse(
      'http://127.0.0.1:${baseUri.port}$_assetHtmlUrl',
    );

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..addJavaScriptChannel(
        'ShizukiHost',
        onMessageReceived: (JavaScriptMessage message) {
          _handleBridgeMessage(message.message);
        },
      );

    await controller.setOnConsoleMessage((JavaScriptConsoleMessage message) {
      debugPrint(
        '[Shizuki WebView JS] ${message.level.name}: ${message.message}',
      );
    });

    debugPrint('[Shizuki Server] Calling loadRequest');
    await controller.loadRequest(indexUri);

    if (!mounted) return;
    setState(() => _controller = controller);
  }

  void _handleBridgeMessage(String rawMessage) {
    if (rawMessage == 'ready') {
      _markJsReady();
      return;
    }

    if (rawMessage.startsWith('error:')) {
      if (!mounted) return;
      setState(() => _useFallback = true);
      return;
    }

    try {
      final decoded = jsonDecode(rawMessage);
      if (decoded is! Map) return;
      final message = decoded.map<String, dynamic>(
        (key, value) => MapEntry(key.toString(), value),
      );

      switch (message['type']) {
        case 'ready':
          _markJsReady();
          return;
        case 'touch':
          final onTouch = widget.onTouch;
          if (onTouch != null) {
            onTouch(ShizukiTouchEvent.fromJson(message));
          }
          return;
        case 'error':
          if (!mounted) return;
          setState(() => _useFallback = true);
          return;
      }
    } catch (_) {
      // Ignore non-JSON bridge messages.
    }
  }

  void _markJsReady() {
    if (!mounted) return;
    setState(() {
      _jsReady = true;
      _useFallback = false;
    });
    _fallbackTimer?.cancel();
    unawaited(_syncRuntimeState());
  }

  bool get _effectiveTalking =>
      widget.talking || widget.emotion == ShizukiEmotion.talk;

  Future<void> _syncRuntimeState() async {
    await _invokeJs('__shizukiSetCamera', widget.cameraPreset.name);
    await _invokeJs('__shizukiSetBaseScale', widget.baseScale);
    await _invokeJs('__shizukiSetZoom', _clampZoom(widget.zoom));
    await _invokeJs('__shizukiResetViewport');
    await _invokeJs('__shizukiSetTouchEnabled', widget.enableTouch);
    await _invokeJs('__shizukiSetEmotion', widget.emotion.name);
    await _invokeJs('__shizukiSetTalking', _effectiveTalking);

    if (widget.lookMode == ShizukiLookMode.forward) {
      await _invokeJs('__shizukiSetLookMode', widget.lookMode.name);
    } else {
      await _invokeJs('__shizukiResetLookMode');
    }
  }

  Future<void> _invokeJs(String functionName, [Object? arg]) async {
    final c = _controller;
    if (c == null || !_jsReady) return;
    try {
      final args = arg == null ? '' : jsonEncode(arg);
      await c.runJavaScript(
        'window.$functionName && window.$functionName($args)',
      );
    } catch (_) {
      if (mounted) setState(() => _useFallback = true);
    }
  }

  double _clampZoom(double zoom) {
    return zoom.clamp(widget.minZoom, widget.maxZoom).toDouble();
  }

  @override
  void didUpdateWidget(ShizukiAnimator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_jsReady) return;

    if (oldWidget.cameraPreset != widget.cameraPreset) {
      unawaited(_invokeJs('__shizukiSetCamera', widget.cameraPreset.name));
    }

    if (oldWidget.baseScale != widget.baseScale) {
      unawaited(_invokeJs('__shizukiSetBaseScale', widget.baseScale));
    }

    if (oldWidget.zoom != widget.zoom ||
        oldWidget.minZoom != widget.minZoom ||
        oldWidget.maxZoom != widget.maxZoom) {
      unawaited(_invokeJs('__shizukiSetZoom', _clampZoom(widget.zoom)));
    }

    if (oldWidget.resetViewportToken != widget.resetViewportToken) {
      unawaited(_invokeJs('__shizukiResetViewport'));
    }

    if (oldWidget.enableTouch != widget.enableTouch) {
      unawaited(_invokeJs('__shizukiSetTouchEnabled', widget.enableTouch));
    }

    if (oldWidget.emotion != widget.emotion) {
      unawaited(_invokeJs('__shizukiSetEmotion', widget.emotion.name));
    }

    if (oldWidget.talking != widget.talking ||
        oldWidget.emotion != widget.emotion) {
      unawaited(_invokeJs('__shizukiSetTalking', _effectiveTalking));
    }

    if (oldWidget.lookMode != widget.lookMode) {
      if (widget.lookMode == ShizukiLookMode.forward) {
        unawaited(_invokeJs('__shizukiSetLookMode', widget.lookMode.name));
      } else {
        unawaited(_invokeJs('__shizukiResetLookMode'));
      }
    }
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    if (_serverAcquired) {
      unawaited(_ShizukiLocalAssetServer.instance.release());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.height ?? widget.size * 1.45;

    if (_useFallback || _controller == null) {
      return SizedBox(
        width: widget.size,
        height: h,
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return SizedBox(
      width: widget.size,
      height: h,
      child: ClipRect(
        child: WebViewWidget(controller: _controller!),
      ),
    );
  }
}
