part of 'global_image.dart';

class _GlobalImageState extends State<GlobalImage> {
  int _retryKey = 0;
  Object? _reported;
  bool _announcedLoad = false;

  // ─── Placeholder gate ──────────────────────────────────────
  //
  // A placeholder that appears and vanishes inside a few frames reads
  // as a GLITCH rather than as progress — the flash is worse than the
  // wait it was covering. So: nothing for the first `placeholderDelay`,
  // and once something IS shown it stays `placeholderMinDuration`.
  //
  // The same pair `LoadingCubit` applies to overlays, applied to the
  // one other place in the app where something appears while waiting.

  Timer? _delayTimer;
  Timer? _minTimer;

  /// Whether the wait has run long enough to admit to it.
  bool _placeholderDue = false;

  /// Whether the placeholder has been up long enough to make way.
  bool _minElapsed = true;

  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _armPlaceholder();
  }

  @override
  void didUpdateWidget(GlobalImage old) {
    super.didUpdateWidget(old);
    // A new picture is a new wait.
    if (old.url != widget.url ||
        old.assetPath != widget.assetPath ||
        old.file?.path != widget.file?.path ||
        !identical(old.bytes, widget.bytes)) {
      _loaded = false;
      _announcedLoad = false;
      _armPlaceholder();
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _minTimer?.cancel();
    super.dispose();
  }

  void _armPlaceholder() {
    _delayTimer?.cancel();
    _minTimer?.cancel();
    final delay =
        widget.style.placeholderDelay ?? ImageDefaults.placeholderDelay;

    if (delay == Duration.zero) {
      _placeholderDue = true;
      _startMinTimer();
      return;
    }
    _placeholderDue = false;
    _minElapsed = true;
    _delayTimer = Timer(delay, () {
      if (!mounted || _loaded) return;
      setState(() => _placeholderDue = true);
      _startMinTimer();
    });
  }

  void _startMinTimer() {
    final hold =
        widget.style.placeholderMinDuration ??
        ImageDefaults.placeholderMinDuration;
    if (hold == Duration.zero) {
      _minElapsed = true;
      return;
    }
    _minElapsed = false;
    _minTimer = Timer(hold, () {
      if (!mounted) return;
      setState(() => _minElapsed = true);
    });
  }

  /// Whether the arrived picture is still being held back so the
  /// placeholder is not a flash.
  bool get _holdingPlaceholder => _loaded && _placeholderDue && !_minElapsed;

  @override
  Widget build(BuildContext context) {
    final rs = widget.style.resolve(context);

    Widget content = Padding(
      padding: rs.padding ?? EdgeInsets.zero,
      child: _withTap(_buildImageContent(context, rs), rs),
    );

    content = Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: rs.backgroundColor,
        // A gradient frame is painted, not decorated — a solid border
        // underneath it would draw a second line.
        border: rs.gradientBorder == null ? rs.border : null,
        borderRadius: rs.borderRadius,
        boxShadow: rs.boxShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: ClipRRect(
        borderRadius: rs.clipRadius,
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            content,
            if (rs.innerShadow != null)
              Positioned.fill(
                child: CustomPaint(
                  painter: ImageInnerShadowPainter(
                    shadow: rs.innerShadow!,
                    borderRadius: rs.borderRadius,
                  ),
                ),
              ),
            if (widget.overlay != null) widget.overlay!,
          ],
        ),
      ),
    );

    if (rs.gradientBorder != null) {
      content = CustomPaint(
        foregroundPainter: GradientBorderPainter(
          gradient: rs.gradientBorder!,
          borderWidth: rs.gradientBorderWidth,
          borderRadius: rs.borderRadius,
        ),
        child: content,
      );
    }

    if (_holdingPlaceholder) {
      content = Stack(
        fit: StackFit.passthrough,
        children: [
          content,
          Positioned.fill(
            child: widget.placeholder ?? _placeholderBody(rs),
          ),
        ],
      );
    }

    if (widget.aspectRatio != null) {
      content = AspectRatio(aspectRatio: widget.aspectRatio!, child: content);
    }

    if (widget.heroTag != null) {
      content = Hero(tag: widget.heroTag!, child: content);
    }

    // A picture with no name is DECORATION and says nothing; one with a
    // name is an image. A TAPPABLE one is named at the ink layer
    // instead — see `_withTap` — so the name and the tap action land on
    // one node.
    //
    // The wrapper used to set `excludeSemantics: true`, which swallowed
    // the InkWell's action and every node in the `overlay` slot: it
    // announced a button a screen reader had no way to press, and a
    // play button on a video thumbnail did not exist at all.
    if (_tap != null || widget.semanticLabel == null) return content;
    return Semantics(
      label: widget.semanticLabel,
      image: true,
      container: true,
      explicitChildNodes: true,
      child: content,
    );
  }

  // ─── Tap ───────────────────────────────────────────────────

  /// What a tap does: the caller's callback, or the viewer.
  VoidCallback? get _tap {
    if (widget.onTap != null) return widget.onTap;
    if (!widget.lightbox) return null;
    return () => GlobalImageViewer.open(
      context,
      sources: [_viewerSource()],
    );
  }

  /// This picture, as the viewer wants it.
  GlobalImageSource _viewerSource() => switch (widget.type) {
    ImageType.network => GlobalImageSource.network(
      widget.url!,
      semanticLabel: widget.semanticLabel,
      heroTag: widget.heroTag,
      headers: widget.httpHeaders,
    ),
    ImageType.asset => GlobalImageSource.asset(
      widget.assetPath!,
      semanticLabel: widget.semanticLabel,
      heroTag: widget.heroTag,
    ),
    ImageType.file => GlobalImageSource.file(
      widget.file!,
      semanticLabel: widget.semanticLabel,
      heroTag: widget.heroTag,
    ),
    ImageType.memory => GlobalImageSource.memory(
      widget.bytes!,
      semanticLabel: widget.semanticLabel,
      heroTag: widget.heroTag,
    ),
    ImageType.provider => GlobalImageSource.provider(
      widget.provider!,
      semanticLabel: widget.semanticLabel,
      heroTag: widget.heroTag,
    ),
  };

  Widget _withTap(Widget imageContent, ResolvedImageStyle rs) {
    final onTap = _tap;
    if (onTap == null) return imageContent;
    final inkRadius = rs.inkRadius(rs.padding);

    if (widget.transparencyAwareRipple) {
      return Stack(
        fit: StackFit.passthrough,
        children: [
          imageContent,
          Positioned.fill(
            child: Semantics(
              label: widget.semanticLabel,
              button: true,
              image: widget.semanticLabel != null,
              child: AlphaMaskedInkWell(
                onTap: widget.onTap!,
                borderRadius: inkRadius,
                maskImage: _buildRawImage(rs),
              ),
            ),
          ),
        ],
      );
    }

    return Stack(
      // PASSTHROUGH, or the tap layer costs the picture its size: a
      // bare `Stack` loosens the constraints it hands its children, so
      // an image told `width: double.infinity, height: 180` fell back
      // to its own aspect ratio and sat square in a wide box. Only the
      // tappable path had it — the plain one was passthrough already.
      fit: StackFit.passthrough,
      children: [
        imageContent,
        Positioned.fill(
          child: Semantics(
            // On the INK layer, so the name, the button flag and the
            // tap action are ONE node rather than a label beside an
            // anonymous button. `InkWell` supplies the action but not
            // the flag.
            label: widget.semanticLabel,
            button: true,
            image: widget.semanticLabel != null,
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: onTap,
                borderRadius: inkRadius,
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Content ───────────────────────────────────────────────

  Widget _buildRawImage(ResolvedImageStyle rs) => switch (widget.type) {
    ImageType.network => _buildNetworkImage(rs),
    ImageType.asset => _buildAssetImage(rs),
    ImageType.file => _buildFileImage(rs),
    ImageType.memory => _buildMemoryImage(rs),
    ImageType.provider => _buildProviderImage(rs),
  };

  Widget _buildImageContent(BuildContext context, ResolvedImageStyle rs) {
    var img = _applyColorAndGradient(_buildRawImage(rs), rs);

    if (rs.grayscale) {
      img = ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.2126, 0.7152, 0.0722, 0, 0, //
          0.2126, 0.7152, 0.0722, 0, 0, //
          0.2126, 0.7152, 0.0722, 0, 0, //
          0, 0, 0, 1, 0, //
        ]),
        child: img,
      );
    }
    // `Image` fades ITSELF when handed an opacity animation — no
    // `saveLayer`. Only the paths that are not an `Image` (SVG, and the
    // cached-network widget's own placeholder machinery) still need the
    // layer, and `_paintsOwnOpacity` says which.
    if (rs.opacity < 1.0 && !_paintsOwnOpacity) {
      img = Opacity(opacity: rs.opacity, child: img);
    }
    if (widget.mirrorInRtl && Directionality.of(context) == TextDirection.rtl) {
      img = Transform(
        alignment: Alignment.center,
        transform: Matrix4.rotationY(math.pi),
        child: img,
      );
    }
    return img;
  }

  /// Whether the source builds a real `Image`, which can fade itself.
  bool get _paintsOwnOpacity {
    final path = switch (widget.type) {
      ImageType.asset => widget.assetPath,
      ImageType.network => widget.url,
      _ => null,
    };
    final isSvg = path != null && _getFormatFromPath(path) == ImageFormat.svg;
    return !isSvg;
  }

  /// The opacity to hand an `Image`, or null when a layer is doing it.
  Animation<double>? _imageOpacity(ResolvedImageStyle rs) =>
      rs.opacity >= 1.0 || !_paintsOwnOpacity
      ? null
      : AlwaysStoppedAnimation<double>(rs.opacity);

  Widget _applyColorAndGradient(Widget child, ResolvedImageStyle rs) {
    var out = child;
    if (rs.gradient != null) {
      out = ShaderMask(
        shaderCallback: (bounds) => rs.gradient!.createShader(bounds),
        blendMode: rs.overlayBlendMode,
        child: out,
      );
    }
    if (rs.color != null) {
      out = ColorFiltered(
        colorFilter: ColorFilter.mode(rs.color!, rs.overlayBlendMode),
        child: out,
      );
    }
    return out;
  }

  // ─── Sources ───────────────────────────────────────────────

  static ImageFormat? _getFormatFromPath(String path) {
    final clean = path.split('?').first.split('#').first;
    return switch (clean.split('.').last.toLowerCase()) {
      'png' => ImageFormat.png,
      'jpg' => ImageFormat.jpg,
      'jpeg' => ImageFormat.jpeg,
      'gif' => ImageFormat.gif,
      'webp' => ImageFormat.webp,
      'svg' => ImageFormat.svg,
      _ => null,
    };
  }

  Widget _buildNetworkImage(ResolvedImageStyle rs) {
    final url = widget.url;
    if (url == null || url.isEmpty) return _buildErrorWidget(rs);

    final format = _getFormatFromPath(url);

    if (format == ImageFormat.svg) {
      return SvgPicture.network(
        url,
        width: widget.width,
        height: widget.height,
        // `fit` used to be dropped on this path, so an SVG ignored the
        // one layout knob every other source honoured.
        fit: rs.fit,
        alignment: rs.alignment,
        headers: widget.httpHeaders,
        colorFilter: rs.color != null
            ? ColorFilter.mode(rs.color!, BlendMode.srcIn)
            : null,
        placeholderBuilder: (_) => widget.placeholder ?? _buildPlaceholder(rs),
        errorBuilder: (context, error, stack) {
          Logger.m.w('[Image] SVG load failed: $url', error: error);
          return _buildErrorWidget(rs, error);
        },
      );
    }

    if (format != null && !widget.type.supportsExtension(format)) {
      Logger.m.w('[Image] unsupported network format: $url');
      return _buildErrorWidget(rs);
    }

    // An EXTENSION is not what makes a URL an image — the response's
    // content type is, and most real ones carry no extension at all:
    // `picsum.photos/id/237/400/400`, an S3 presigned link, a
    // Cloudinary transform, a Gravatar hash. `Validators.isValidImageUrl`
    // demanded `.jpg|.png|…` and every one of those failed it, so the
    // tile drew an error plate for a picture that loads perfectly —
    // which is exactly what a picker hydrated from a server showed.
    //
    // A URL that is not a picture still ends at the error plate; it
    // just gets there by FAILING TO LOAD rather than by failing a
    // regex. The validator stays what it is: a form rule for a human
    // typing a URL, where the stricter answer is the useful one.
    if (!ImageUrls.looksFetchable(url)) {
      Logger.m.w('[Image] not a fetchable URL: $url');
      return _buildErrorWidget(rs);
    }

    if (!widget.cacheNetwork) {
      return Image.network(
        url,
        fit: rs.fit,
        filterQuality: rs.filterQuality,
        cacheWidth: rs.cacheExtent(widget.width),
        cacheHeight: rs.cacheExtent(widget.height),
        opacity: _imageOpacity(rs),
        frameBuilder: _fadeIn(rs),
        errorBuilder: (context, error, stack) {
          Logger.m.w('[Image] network load failed: $url', error: error);
          return _buildErrorWidget(rs, error);
        },
      );
    }

    return CachedNetworkImage(
      key: ValueKey('${url}_$_retryKey'),
      imageUrl: url,
      fit: rs.fit,
      alignment: rs.alignment is Alignment
          ? rs.alignment as Alignment
          : Alignment.center,
      repeat: rs.repeat,
      httpHeaders: widget.httpHeaders,
      cacheKey: widget.cacheKey,
      memCacheWidth: rs.cacheExtent(widget.width),
      memCacheHeight: rs.cacheExtent(widget.height),
      filterQuality: rs.filterQuality,
      fadeInDuration: rs.fadeDuration,
      imageBuilder: (context, provider) {
        _reportLoaded();
        return Image(
          image: provider,
          fit: rs.fit,
          opacity: _imageOpacity(rs),
          alignment: rs.alignment,
          repeat: rs.repeat,
          filterQuality: rs.filterQuality,
        );
      },
      placeholder: widget.showProgress
          ? null
          : (context, _) => widget.placeholder ?? _buildPlaceholder(rs),
      progressIndicatorBuilder: widget.showProgress
          ? (context, _, progress) => Center(
              child: SizedBox(
                width: rs.errorIconSize,
                height: rs.errorIconSize,
                child: progress.totalSize == null
                    ? GlobalProgress.loading(
                        type: ProgressType.circular,
                        style: ProgressStyle(
                          indeterminate: true,
                          thickness: ImageDefaults.progressThickness,
                          color: rs.progressColor,
                        ),
                      )
                    : GlobalProgress.circular(
                        value: progress.downloaded / progress.totalSize!,
                        style: ProgressStyle(
                          thickness: ImageDefaults.progressThickness,
                          color: rs.progressColor,
                        ),
                      ),
              ),
            )
          : null,
      errorWidget: (context, _, error) {
        Logger.m.w('[Image] network load failed: $url', error: error);
        return _buildErrorWidget(rs, error);
      },
    );
  }

  Widget _buildAssetImage(ResolvedImageStyle rs) {
    final path = widget.assetPath;
    if (path == null || path.isEmpty) return _buildErrorWidget(rs);

    final format = _getFormatFromPath(path);
    if (format == null || !widget.type.supportsExtension(format)) {
      Logger.m.w('[Image] unsupported asset format: $path');
      return _buildErrorWidget(rs);
    }

    if (format == ImageFormat.svg) {
      return SvgPicture.asset(
        path,
        width: widget.width,
        height: widget.height,
        fit: rs.fit,
        alignment: rs.alignment,
        colorFilter: rs.color != null
            ? ColorFilter.mode(rs.color!, BlendMode.srcIn)
            : null,
        errorBuilder: (context, error, stack) {
          Logger.m.w('[Image] SVG asset failed: $path', error: error);
          return _buildErrorWidget(rs, error);
        },
      );
    }

    return Image.asset(
      path,
      fit: rs.fit,
      alignment: rs.alignment,
      repeat: rs.repeat,
      filterQuality: rs.filterQuality,
      cacheWidth: rs.cacheExtent(widget.width),
      cacheHeight: rs.cacheExtent(widget.height),
      opacity: _imageOpacity(rs),
      frameBuilder: _fadeIn(rs),
      errorBuilder: (context, error, stack) {
        Logger.m.w('[Image] asset load failed: $path', error: error);
        return _buildErrorWidget(rs, error);
      },
    );
  }

  Widget _buildFileImage(ResolvedImageStyle rs) {
    final file = widget.file;
    if (file == null || !file.existsSync()) return _buildErrorWidget(rs);

    final format = _getFormatFromPath(file.path);
    if (format == null || !widget.type.supportsExtension(format)) {
      Logger.m.w('[Image] unsupported file format: ${file.path}');
      return _buildErrorWidget(rs);
    }

    return Image.file(
      file,
      fit: rs.fit,
      alignment: rs.alignment,
      repeat: rs.repeat,
      filterQuality: rs.filterQuality,
      cacheWidth: rs.cacheExtent(widget.width),
      cacheHeight: rs.cacheExtent(widget.height),
      opacity: _imageOpacity(rs),
      frameBuilder: _fadeIn(rs),
      errorBuilder: (context, error, stack) {
        Logger.m.w('[Image] file load failed: ${file.path}', error: error);
        return _buildErrorWidget(rs, error);
      },
    );
  }

  Widget _buildMemoryImage(ResolvedImageStyle rs) {
    final bytes = widget.bytes;
    if (bytes == null || bytes.isEmpty) return _buildErrorWidget(rs);

    return Image.memory(
      bytes,
      fit: rs.fit,
      alignment: rs.alignment,
      repeat: rs.repeat,
      filterQuality: rs.filterQuality,
      cacheWidth: rs.cacheExtent(widget.width),
      cacheHeight: rs.cacheExtent(widget.height),
      opacity: _imageOpacity(rs),
      frameBuilder: _fadeIn(rs),
      errorBuilder: (context, error, stack) {
        Logger.m.w('[Image] memory decode failed', error: error);
        return _buildErrorWidget(rs, error);
      },
    );
  }

  /// A provider the caller already holds.
  ///
  /// The one path where this module does NOT choose the loader — a
  /// provider has already decided where its bytes come from. Everything
  /// after the fetch is still ours: the fit, the fade, the cache
  /// extent, the error plate.
  Widget _buildProviderImage(ResolvedImageStyle rs) {
    final provider = widget.provider;
    if (provider == null) return _buildErrorWidget(rs);

    return Image(
      image: provider,
      fit: rs.fit,
      alignment: rs.alignment,
      repeat: rs.repeat,
      filterQuality: rs.filterQuality,
      opacity: _imageOpacity(rs),
      frameBuilder: _fadeIn(rs),
      errorBuilder: (context, error, stack) {
        Logger.m.w('[Image] provider decode failed', error: error);
        return _buildErrorWidget(rs, error);
      },
    );
  }

  /// Fades a picture in once it has been decoded.
  ///
  /// Only when it was NOT ready synchronously: one already in the image
  /// cache appears at once, or every scroll back through a list
  /// re-fades pictures that never went away.
  ImageFrameBuilder? _fadeIn(ResolvedImageStyle rs) {
    if (rs.fadeDuration == Duration.zero) return null;
    return (context, child, frame, wasSynchronouslyLoaded) {
      if (frame != null || wasSynchronouslyLoaded) _reportLoaded();
      if (wasSynchronouslyLoaded) return child;
      return Stack(
        fit: StackFit.passthrough,
        children: [
          // A local source is not instant either — a large asset or a
          // camera file decodes over a frame or two, and the widget
          // showed NOTHING for that window: the placeholder was wired
          // to the network path alone.
          if (frame == null)
            Positioned.fill(
              child: widget.placeholder ?? _buildPlaceholder(rs),
            ),
          AnimatedOpacity(
            opacity: frame == null ? 0 : 1,
            duration: rs.fadeDuration,
            curve: Curves.easeOut,
            child: child,
          ),
        ],
      );
    };
  }

  // ─── Placeholder + error ───────────────────────────────────

  /// Tells the caller ONCE per failure, after the frame — a callback
  /// fired during build would rebuild the tree it is describing.
  void _report(Object? error) {
    final cb = widget.onError;
    if (cb == null || error == null || identical(error, _reported)) return;
    _reported = error;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) cb(error);
    });
  }

  void _reportLoaded() {
    if (_announcedLoad) return;
    _announcedLoad = true;
    final cb = widget.onLoaded;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // A picture that beat the delay cancels it outright: the wait is
      // over, so there is nothing left to admit to.
      _delayTimer?.cancel();
      if (!_placeholderDue) _minElapsed = true;
      setState(() => _loaded = true);
      cb?.call();
    });
  }

  Widget _buildPlaceholder(ResolvedImageStyle rs) {
    // A BlurHash is NOT gated. The gate exists to stop a contentless
    // placeholder flashing, and a blur is the picture's own shapes: it
    // crossfades into the real thing rather than being swapped out, so
    // there is no flash to avoid — and delaying the one placeholder
    // worth showing would be the opposite of the point.
    if (widget.blurHash != null) return _placeholderBody(rs);

    // Everything else waits until the delay has earned it.
    if (!_placeholderDue) return const SizedBox.shrink();
    return _placeholderBody(rs);
  }

  Widget _placeholderBody(ResolvedImageStyle rs) {
    // The picture's own shape, blurred, beats a grey rectangle: a
    // gallery fills with what is coming rather than with placeholders.
    final hash = widget.blurHash;
    if (hash != null) {
      final blur = BlurHash(
        hash: hash,
        imageFit: rs.fit,
        // TRANSPARENT. The package paints `Container(color:)` while its
        // own decode runs, and that default is `Colors.blueGrey` — a
        // solid slab that appears before the blur does, which is the
        // grey flash a BlurHash exists to avoid.
        color: Colors.transparent,
      );
      if (!rs.blurHashSheen) return blur;
      return ImageLoadingSheen(
        color: context.shimmerColors.highlight.withValues(
          alpha: ImageDefaults.sheenOpacity,
        ),
        period: ImageDefaults.sheenPeriod,
        bandFraction: ImageDefaults.sheenBandFraction,
        child: blur,
      );
    }

    final pad = rs.padding;
    final w = widget.width != null
        ? (widget.width! - (pad?.horizontal ?? 0)).clamp(0.0, double.infinity)
        : ImageDefaults.placeholderWidth;
    final h = widget.height != null
        ? (widget.height! - (pad?.vertical ?? 0)).clamp(0.0, double.infinity)
        : null;
    return GlobalShimmer.placeholder(
      width: w,
      height: h,
      borderRadius: rs.borderRadius,
    );
  }

  Widget _buildErrorWidget(ResolvedImageStyle rs, [Object? error]) {
    _report(error);
    // A caller's own widget REPLACES the plate — but not the retry,
    // which used to return above this point and leave anyone passing
    // both with no way to try again.
    final plate =
        widget.errorBuilder?.call(context, error) ??
        widget.errorWidget ??
        _errorPlate(rs);

    if (!widget.retryOnError) return plate;
    return _withRetry(plate, rs);
  }

  Widget _errorPlate(ResolvedImageStyle rs) {
    return ColoredBox(
      color: rs.errorPlateColor,
      child: Center(
        child: GlobalIcon(
          icon: Icons.broken_image_outlined,
          style: IconStyle(size: rs.errorIconSize, color: rs.errorIconColor),
        ),
      ),
    );
  }

  Widget _withRetry(Widget plate, ResolvedImageStyle rs) {
    // The pill was a `GestureDetector` around a `DecoratedBox` and a
    // raw `Text`: it looked like a button and was not one, so a screen
    // reader got a tap action with no name and no button flag, and the
    // whole plate was tappable rather than the control.
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(child: plate),
        Positioned(
          bottom: context.spacing.sm,
          // FILLED, not text: a text button's background is always
          // transparent by design, so the scrim was dropped and a white
          // label sat on a pale plate — the control was tappable and
          // invisible.
          child: GlobalFilledButton(
            text: CommonStrings.tapToRetry,
            icon: Icons.refresh,
            shrinkWidth: true,
            onPressed: () => setState(() => _retryKey++),
            style: ButtonStateStyle(
              backgroundColor: rs.retryScrimColor,
              foregroundColor: rs.retryLabelColor,
              borderRadius: BorderRadius.circular(context.radii.sm),
              padding: EdgeInsets.symmetric(
                horizontal: context.spacing.sm,
                vertical: context.spacing.xs / 2,
              ),
              textStyle: context.textTheme.labelSmall?.copyWith(
                color: rs.retryLabelColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
