import 'dart:io';
import 'package:flutter/material.dart';
import '../services/cover_cache.dart';

/// 所有畫面共用磁碟快取；記憶體命中不顯示等待動畫。
class CoverView extends StatefulWidget {
  final String? url;
  final String? local;
  final Widget Function(ImageProvider image)? builder;
  const CoverView({super.key, this.url, this.local, this.builder});
  @override
  State<CoverView> createState() => _CoverViewState();
}
class _CoverViewState extends State<CoverView> {
  File? _file;
  Object? _error;
  int _generation = 0;
  bool _fade = false;
  @override
  void initState() { super.initState(); _load(); }
  @override
  void didUpdateWidget(CoverView old) {
    super.didUpdateWidget(old);
    if (old.url != widget.url || old.local != widget.local) _load();
  }
  void _load() {
    final generation = ++_generation;
    _error = null;
    _fade = false;
    _file = widget.local != null ? File(widget.local!) : CoverCache.memory[widget.url];
    if (_file != null || widget.url == null) return;
    CoverCache.get(widget.url!).then((file) {
      if (!mounted || generation != _generation) return;
      setState(() { _file = file; _fade = true; });
    }).catchError((Object error) {
      if (mounted && generation == _generation) setState(() => _error = error);
    });
  }
  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(child: IconButton(
        tooltip: '封面載入失敗，點擊重試', icon: const Icon(Icons.refresh),
        onPressed: () => setState(_load),
      ));
    }
    final file = _file;
    if (file == null) {
      if (widget.url == null) return const Center(child: Icon(Icons.music_note_outlined));
      return const CoverSkeleton();
    }
    final provider = FileImage(file);
    final child = widget.builder?.call(provider) ?? Image(
      image: provider, fit: BoxFit.cover, gaplessPlayback: true,
      errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image_outlined)),
    );
    if (!_fade) return child;
    return TweenAnimationBuilder<double>(
      key: ValueKey(file.path), tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 220),
      builder: (_, value, child) => Opacity(opacity: value, child: child), child: child,
    );
  }
}
class CoverSkeleton extends StatefulWidget {
  const CoverSkeleton({super.key});
  @override
  State<CoverSkeleton> createState() => _CoverSkeletonState();
}
class _CoverSkeletonState extends State<CoverSkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _animation = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);
  @override
  void dispose() { _animation.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(color: scheme.surfaceContainerHighest,
      child: FadeTransition(opacity: Tween<double>(begin: .25, end: .65).animate(_animation),
        child: ColoredBox(color: scheme.onSurface.withOpacity(.15)),
      ),
    );
  }
}
