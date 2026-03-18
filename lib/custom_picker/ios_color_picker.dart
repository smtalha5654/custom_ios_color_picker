import 'package:flutter/material.dart';
import 'package:ios_color_picker/custom_picker/pickers/slider_picker/slider_helper.dart';
import 'package:ios_color_picker/custom_picker/pickers_selector_row.dart';
import 'package:ios_color_picker/custom_picker/shared.dart';
import 'color_observer.dart';
import 'extensions.dart';

///Returns iOS Style color Picker
class IosColorPicker extends StatefulWidget {
  const IosColorPicker({
    super.key,
    required this.onColorSelected, // keeps your existing slider callback
    this.actionWidget, // optional custom button
    this.onActionTap, // new callback for action tap
  });

  final ValueChanged<Color> onColorSelected; // existing slider callback
  final Widget? actionWidget; // optional button
  final ValueChanged<Color>? onActionTap; // triggers on action button tap

  @override
  State<IosColorPicker> createState() => _IosColorPickerState();
}

class _IosColorPickerState extends State<IosColorPicker> {
  final TextEditingController _hexController = TextEditingController();
  Color? _hexPreviewColor;
  String? _hexErrorText;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  bool _isValidHex(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return false;
    return RegExp(kCompleteValidHexPattern).hasMatch(trimmed);
  }

  void _onHexChanged(String raw) {
    final value = raw.trim();
    if (value.isEmpty) {
      setState(() {
        _hexPreviewColor = null;
        _hexErrorText = null;
      });
      return;
    }

    if (_isValidHex(value)) {
      final parsed = HexColor.fromHex(value);
      setState(() {
        _hexPreviewColor = parsed;
        _hexErrorText = null;
      });

      // Also reflect in the picker so sliders / preview match.
      colorController.updateColor(parsed);
      widget.onColorSelected(colorController.value);
    } else {
      // Only show validation error once user has typed a full-ish code.
      final normalized = value.replaceFirst('#', '');
      final shouldShowError = normalized.length >= 6;
      setState(() {
        _hexPreviewColor = null;
        _hexErrorText =
            shouldShowError ? 'Please enter a valid hex color.' : null;
      });
    }
  }

  void _submitHexColor(BuildContext context) {
    final value = _hexController.text.trim();
    if (!_isValidHex(value)) {
      setState(() {
        _hexErrorText = 'Please enter a valid hex color.';
        _hexPreviewColor = null;
      });
      return;
    }

    final parsed = HexColor.fromHex(value);

    if (widget.onActionTap != null) {
      widget.onActionTap!(parsed);
    }

    Navigator.pop(context, parsed);
  }

  @override
  Widget build(BuildContext context) {
    final keyboardPadding = MediaQuery.of(context).viewInsets.bottom;
    final bool isKeyboardOpen = keyboardPadding > 0;
    final double sheetBaseHeight = 300 + componentsHeight(context) + 74;

    return Column(
      children: [
        Expanded(
          child: InkWell(
            splashColor: Colors.transparent,
            focusColor: Colors.transparent,
            onTap: () => Navigator.pop(context),
            child: SizedBox(
              width: maxWidth(context),
            ),
          ),
        ),
        Container(
          width: maxWidth(context),
          height: isKeyboardOpen ? null : sheetBaseHeight,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          decoration: BoxDecoration(
            color: backgroundColor.withValues(alpha: 0.98),
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(10),
              topLeft: Radius.circular(10),
            ),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(bottom: keyboardPadding),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      0,
                      8,
                      2,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 40,
                        ),
                        Text(
                          'Colors',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                  fontSize: 17,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700),
                        ),
                        ValueListenableBuilder<Color>(
                          valueListenable: colorController,
                          builder: (context, color, child) {
                            return GestureDetector(
                              onTap: () {
                                if (widget.onActionTap != null) {
                                  widget.onActionTap!(color);
                                }
                                Navigator.pop(context, color);
                              },
                              child: widget.actionWidget ??
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Color(0xff3A3A3B),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      color: Color(0xffA4A4AA),
                                      size: 20,
                                    ),
                                  ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  PickersSelectorRow(
                    onColorChanged: widget.onColorSelected,
                  ),

                  ///ALL
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 17.0),
                    child: Text(
                      'OPACITY',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.6)),
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12.0, vertical: 2),
                          child: SizedBox(
                            height: 36.0,
                            child: ValueListenableBuilder<Color>(
                              valueListenable: colorController,
                              builder: (context, color, child) {
                                return ColorPickerSlider(
                                    TrackType.alpha, HSVColor.fromColor(color),
                                    small: false, (v) {
                                  colorController.updateOpacity(v.alpha);
                                  widget.onColorSelected(colorController.value);
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // const SizedBox(
                  //   height: 44,
                  // ),
                  Divider(
                    height: 44,
                    thickness: 0.2,
                    indent: 17,
                    endIndent: 17,
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          Container(
                            height: 78,
                            width: 78,
                            clipBehavior: Clip.antiAliasWithSaveLayer,
                            margin: const EdgeInsets.only(
                              left: 16,
                            ),
                            decoration: const BoxDecoration(
                              borderRadius: BorderRadius.all(
                                Radius.circular(10),
                              ),
                            ),
                            child: Transform.scale(
                              scale: 1.5,
                              child: Transform.rotate(
                                angle: 0.76,
                                child: Row(
                                  children: [
                                    Expanded(
                                        child: Container(color: Colors.white)),
                                    Expanded(
                                        child: Container(color: Colors.black)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          ValueListenableBuilder<Color>(
                            valueListenable: colorController,
                            builder: (context, color, child) {
                              return Container(
                                height: 78,
                                width: 78,
                                margin: const EdgeInsets.only(
                                  left: 16,
                                ),
                                decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.all(
                                      Radius.circular(10),
                                    ),
                                    color: color),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (_hexPreviewColor != null)
                          Container(
                            height: 36,
                            width: 36,
                            margin: const EdgeInsets.only(right: 10, bottom: 2),
                            decoration: BoxDecoration(
                              color: _hexPreviewColor,
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(10)),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25),
                                width: 0.8,
                              ),
                            ),
                          )
                        else
                          Container(
                            height: 36,
                            width: 36,
                            margin: const EdgeInsets.only(right: 10, bottom: 2),
                            decoration: BoxDecoration(
                              color: valueColor,
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(10)),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.12),
                                width: 0.8,
                              ),
                            ),
                            child: Icon(
                              Icons.palette_outlined,
                              size: 18,
                              color: Colors.white.withValues(alpha: 0.45),
                            ),
                          ),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextField(
                                controller: _hexController,
                                onChanged: _onHexChanged,
                                onEditingComplete: () =>
                                    _submitHexColor(context),
                                textInputAction: TextInputAction.done,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontSize: 15,
                                      letterSpacing: 0.2,
                                      fontWeight: FontWeight.w500,
                                    ),
                                decoration: InputDecoration(
                                  isDense: true,
                                  filled: true,
                                  fillColor: valueColor,
                                  hintText: 'Hex (e.g. #FF6A00)',
                                  hintStyle: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: Colors.white
                                            .withValues(alpha: 0.35),
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  border: const OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(10)),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                              if (_hexErrorText != null)
                                Padding(
                                  padding:
                                      const EdgeInsets.only(top: 6.0, left: 2),
                                  child: Text(
                                    _hexErrorText!,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Colors.redAccent
                                              .withValues(alpha: 0.9),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () => _submitHexColor(context),
                          child: Container(
                            height: 38,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xff3A3A3B),
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(10)),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.12),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              'Add',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: const Color(0xffA4A4AA),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
