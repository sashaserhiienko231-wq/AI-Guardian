import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../app/design_system.dart';
import '../app/providers.dart';
import '../app/strings.dart';
import 'shared_widgets.dart';

class QrScannerPage extends ConsumerStatefulWidget {
  const QrScannerPage({super.key});

  @override
  ConsumerState<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends ConsumerState<QrScannerPage> {
  final _contentController = TextEditingController();
  final _imagePicker = ImagePicker();
  final _scannerController = MobileScannerController(
    facing: CameraFacing.back,
    torchEnabled: false,
  );
  Map<String, dynamic>? _result;
  String? _error;
  bool _processing = false;
  bool _detected = false;
  bool _dragging = false;
  bool _cameraUnavailable = false;

  @override
  void dispose() {
    _scannerController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _analyzeContent(String content) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty || _processing) return;

    setState(() {
      _processing = true;
      _detected = true;
      _error = null;
      _result = null;
      _contentController.text = trimmed;
      _contentController.selection = TextSelection.collapsed(
        offset: _contentController.text.length,
      );
    });
    try {
      final result = await ref.read(apiProvider).post('/api/v1/scanner/qr', {
        'content': trimmed,
      });
      if (mounted) setState(() => _result = result);
      try {
        await _scannerController.stop();
      } catch (_) {
        if (mounted) {
          setState(() {
            _cameraUnavailable = true;
            _error = AppStrings(
              ref.read(localeProvider),
            ).scannerCameraUnavailable;
          });
        }
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _detected = false;
          _error = friendlyApiError(error, ukrainian: ref.read(localeProvider));
        });
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _chooseImage() async {
    try {
      final image = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (image != null) await _analyzeImage(image.path);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = AppStrings(ref.read(localeProvider)).qrImageReadError,
        );
      }
    }
  }

  Future<void> _analyzeImage(String path) async {
    try {
      final capture = await _scannerController.analyzeImage(path);
      final content = capture?.barcodes
          .map((barcode) => barcode.rawValue)
          .whereType<String>()
          .firstWhere((value) => value.isNotEmpty, orElse: () => '');
      if (content == null || content.isEmpty) {
        if (mounted) {
          setState(
            () => _error = AppStrings(ref.read(localeProvider)).qrImageNotFound,
          );
        }
        return;
      }
      await _analyzeContent(content);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = AppStrings(ref.read(localeProvider)).qrImageReadError,
        );
      }
    }
  }

  Future<void> _switchCamera() async {
    try {
      await _scannerController.switchCamera();
    } catch (_) {
      if (mounted) {
        setState(() {
          _cameraUnavailable = true;
          _error = AppStrings(
            ref.read(localeProvider),
          ).scannerCameraUnavailable;
        });
      }
    }
  }

  Future<void> _toggleFlash() async {
    try {
      await _scannerController.toggleTorch();
    } catch (_) {
      if (mounted) {
        setState(() {
          _cameraUnavailable = true;
          _error = AppStrings(
            ref.read(localeProvider),
          ).scannerCameraUnavailable;
        });
      }
    }
  }

  Future<void> _resetScanner() async {
    setState(() {
      _result = null;
      _error = null;
      _detected = false;
      _cameraUnavailable = false;
      _contentController.clear();
    });
    try {
      await _scannerController.start();
    } catch (_) {
      if (mounted) {
        setState(() {
          _cameraUnavailable = true;
          _error = AppStrings(
            ref.read(localeProvider),
          ).scannerCameraUnavailable;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings(ref.watch(localeProvider));

    return PageScaffold(
      title: strings.qrScanner,
      subtitle: strings.qrSubtitle,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 820;
              final preview = _buildPreview(context, strings);
              final controls = _buildControls(context, strings);
              if (stacked) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    preview,
                    const SizedBox(height: GuardianSpace.lg),
                    controls,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 6, child: preview),
                  const SizedBox(width: GuardianSpace.lg),
                  Expanded(flex: 4, child: controls),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPreview(BuildContext context, AppStrings strings) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      DropTarget(
        onDragEntered: (_) => setState(() => _dragging = true),
        onDragExited: (_) => setState(() => _dragging = false),
        onDragDone: (details) {
          setState(() => _dragging = false);
          final file = details.files.firstOrNull;
          if (file != null) _analyzeImage(file.path);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 330,
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF0A101C)
                : const Color(0xFFE9EEF6),
            borderRadius: BorderRadius.circular(GuardianRadius.large),
            border: Border.all(
              color: _dragging
                  ? GuardianColors.cyan
                  : Theme.of(context).dividerColor,
              width: _dragging ? 2 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              MobileScanner(
                controller: _scannerController,
                onDetect: (capture) {
                  if (_detected || _processing || _result != null) return;
                  for (final barcode in capture.barcodes) {
                    final value = barcode.rawValue;
                    if (value != null && value.isNotEmpty) {
                      _analyzeContent(value);
                      break;
                    }
                  }
                },
                errorBuilder: (context, error) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && !_cameraUnavailable) {
                      setState(() => _cameraUnavailable = true);
                    }
                  });
                  return _CameraUnavailable(
                    message: strings.scannerCameraUnavailable,
                    actionLabel: strings.chooseQrImage,
                    onChooseImage: _chooseImage,
                  );
                },
              ),
              if (!_cameraUnavailable)
                IgnorePointer(
                  child: Center(
                    child: Container(
                      width: 220,
                      height: 180,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: GuardianColors.cyan.withValues(alpha: 0.9),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(
                          GuardianRadius.medium,
                        ),
                      ),
                    ),
                  ),
                ),
              if (_dragging)
                Container(
                  color: GuardianColors.background.withValues(alpha: 0.78),
                  alignment: Alignment.center,
                  child: Text(
                    strings.dropQrImage,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: GuardianColors.cyan,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              if (_processing)
                Container(
                  color: GuardianColors.background.withValues(alpha: 0.62),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              if (_result != null)
                Container(
                  color: GuardianColors.background.withValues(alpha: 0.94),
                  padding: const EdgeInsets.all(GuardianSpace.xl),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.qr_code_2_rounded,
                            color: GuardianColors.cyan,
                            size: 38,
                          ),
                          const SizedBox(height: GuardianSpace.md),
                          Text(
                            strings.qrResultPreviewTitle,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: GuardianSpace.sm),
                          SelectableText(
                            _contentController.text,
                            maxLines: 5,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: GuardianSpace.md),
                          Text(
                            strings.qrResultPreviewNotice,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      const SizedBox(height: GuardianSpace.md),
      Wrap(
        spacing: GuardianSpace.sm,
        runSpacing: GuardianSpace.sm,
        children: [
          OutlinedButton.icon(
            onPressed: _cameraUnavailable ? null : _switchCamera,
            icon: const Icon(Icons.cameraswitch_outlined),
            label: Text(strings.switchCamera),
          ),
          OutlinedButton.icon(
            onPressed: _cameraUnavailable ? null : _toggleFlash,
            icon: const Icon(Icons.flashlight_on_outlined),
            label: Text(strings.toggleFlash),
          ),
          OutlinedButton.icon(
            onPressed: _chooseImage,
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: Text(strings.chooseQrImage),
          ),
        ],
      ),
      const SizedBox(height: GuardianSpace.sm),
      Text(
        strings.dropQrImage,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ],
  );

  Widget _buildControls(BuildContext context, AppStrings strings) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              strings.decodedContent,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: GuardianSpace.md),
            TextField(
              controller: _contentController,
              key: const Key('qr-content'),
              minLines: 3,
              maxLines: 6,
              onChanged: (_) {
                if (_detected || _result != null || _error != null) {
                  setState(() {
                    _detected = false;
                    _result = null;
                    _error = null;
                  });
                }
              },
              decoration: InputDecoration(
                hintText: strings.qrContentHint,
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: GuardianSpace.md),
            FilledButton.icon(
              onPressed: _processing
                  ? null
                  : () => _analyzeContent(_contentController.text),
              icon: const Icon(Icons.manage_search_rounded),
              label: Text(strings.analyzeQr),
            ),
          ],
        ),
      ),
      if (_error != null) ...[
        const SizedBox(height: GuardianSpace.md),
        ErrorPanel(
          message: _error!,
          retryLabel: strings.retry,
          onRetry: () => _analyzeContent(_contentController.text),
        ),
      ],
      if (_result != null) ...[
        const SizedBox(height: GuardianSpace.md),
        ScanResultCard(
          result: _result!,
          strings: strings,
          link: _contentController.text.trim(),
        ),
        const SizedBox(height: GuardianSpace.sm),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _resetScanner,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(strings.scanAgain),
          ),
        ),
      ],
    ],
  );
}

class _CameraUnavailable extends StatelessWidget {
  const _CameraUnavailable({
    required this.message,
    required this.actionLabel,
    required this.onChooseImage,
  });

  final String message;
  final String actionLabel;
  final VoidCallback onChooseImage;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(GuardianSpace.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.no_photography_outlined,
            color: GuardianColors.cyan,
            size: 38,
          ),
          const SizedBox(height: GuardianSpace.md),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: GuardianSpace.md),
          OutlinedButton.icon(
            onPressed: onChooseImage,
            icon: const Icon(Icons.image_outlined),
            label: Text(actionLabel),
          ),
        ],
      ),
    ),
  );
}
