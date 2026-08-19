import 'package:flutter/material.dart';

import '../controllers/chaty_preferences_controller.dart';
import '../theme/theme_config.dart';

class PremiumMessageComposer extends StatelessWidget {
  final int styleIndex;
  final ThemeConfig theme;
  final ChatyPreferencesController preferencesController;
  final TextEditingController controller;
  final VoidCallback onAttach;
  final VoidCallback onSend;
  final VoidCallback onVoice;
  final VoidCallback onEmoji;
  final ValueChanged<String> onChanged;

  const PremiumMessageComposer({
    super.key,
    required this.styleIndex,
    required this.theme,
    required this.preferencesController,
    required this.controller,
    required this.onAttach,
    required this.onSend,
    required this.onVoice,
    required this.onEmoji,
    required this.onChanged,
  });

  int get _index => styleIndex.clamp(0, 19);
  Color get _surface => preferencesController.gbColor('BGColor') ?? theme.surfaceColor;
  Color get _entry => preferencesController.gbColor('ModChatEntry') ?? theme.cardColor;
  Color get _text => preferencesController.gbColor('ModChatTextColor') ?? theme.primaryTextColor;
  Color get _attach => preferencesController.gbColor('ModChatBtnColor') ?? theme.accentColor;
  Color get _emoji => preferencesController.gbColor('ModChatEmojiColor') ?? theme.secondaryTextColor;
  Color get _sendBackground => preferencesController.gbColor('ModChaSendBKColor') ?? theme.accentColor;
  Color get _sendForeground => preferencesController.gbColor('ModChaSendColor') ?? theme.onAccentColor;

  @override
  Widget build(BuildContext context) {
    final variants = <Widget>[
      _pill(context), _classic(context), _compact(context), _floatingCard(context), _outlined(context),
      _soft(context), _splitActions(context), _minimal(context), _boxed(context), _centerSend(context),
      _stacked(context), _editorial(context), _edge(context), _dense(context), _wide(context),
      _slim(context), _toolbar(context), _workspace(context), _focus(context), _expressive(context),
    ];
    return variants[_index];
  }

  Widget _shell(Widget child, {EdgeInsets padding = const EdgeInsets.fromLTRB(8, 7, 8, 7), Color? color, Border? border}) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(color: color ?? _surface, border: border),
      child: SafeArea(top: false, child: child),
    );
  }

  Widget _field(BuildContext context, {double radius = 22, bool filled = true, int maxLines = 5, String? hint, EdgeInsets? padding}) {
    return TextField(
      controller: controller,
      minLines: 1,
      maxLines: maxLines,
      onChanged: onChanged,
      textInputAction: TextInputAction.newline,
      style: TextStyle(color: _text, fontSize: 14 * theme.fontScale),
      decoration: InputDecoration(
        hintText: hint ?? 'Message…  /task or #reply',
        hintStyle: TextStyle(color: theme.secondaryTextColor),
        filled: filled,
        fillColor: filled ? _entry : Colors.transparent,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(radius), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(radius), borderSide: filled ? BorderSide.none : BorderSide(color: _entry)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(radius), borderSide: BorderSide(color: _attach, width: 1.2)),
        isDense: true,
        contentPadding: padding ?? const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Widget _actionButton({required IconData icon, required String tooltip, required VoidCallback onPressed, bool filled = false, double size = 44}) {
    final target = size < 44 ? 44.0 : size;
    final actionColor = tooltip == 'Emoji' ? _emoji : _attach;
    final child = Icon(icon, size: 20);
    if (filled) {
      return SizedBox(
        width: target,
        height: target,
        child: IconButton.filled(
          tooltip: tooltip,
          style: IconButton.styleFrom(backgroundColor: actionColor, foregroundColor: _sendForeground),
          onPressed: onPressed,
          icon: child,
        ),
      );
    }
    return SizedBox(
      width: target,
      height: target,
      child: IconButton(tooltip: tooltip, color: actionColor, onPressed: onPressed, icon: child),
    );
  }

  Widget _sendOrVoice({double size = 44, bool square = false}) {
    final target = size < 44 ? 44.0 : size;
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final hasText = value.text.trim().isNotEmpty;
        return SizedBox(
          width: target,
          height: target,
          child: IconButton.filled(
            tooltip: hasText ? 'Send' : 'Voice note',
            style: IconButton.styleFrom(
              backgroundColor: _sendBackground,
              foregroundColor: _sendForeground,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(square ? 12 : target / 2)),
            ),
            onPressed: hasText ? onSend : onVoice,
            icon: Icon(hasText ? Icons.send_rounded : Icons.mic_rounded, size: 19),
          ),
        );
      },
    );
  }

  Widget _pill(BuildContext context) => _shell(Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        _actionButton(icon: Icons.add_circle_outline_rounded, tooltip: 'Attach', onPressed: onAttach),
        Expanded(child: _field(context, radius: 24)),
        const SizedBox(width: 6),
        _sendOrVoice(),
      ]), border: Border(top: BorderSide(color: _entry)));

  Widget _classic(BuildContext context) => _shell(Row(children: [
        _actionButton(icon: Icons.emoji_emotions_outlined, tooltip: 'Emoji', onPressed: onEmoji),
        Expanded(child: _field(context, radius: 10, filled: false)),
        _actionButton(icon: Icons.attach_file_rounded, tooltip: 'Attach', onPressed: onAttach),
        _sendOrVoice(square: true),
      ]));

  Widget _compact(BuildContext context) => _shell(Row(children: [
        Expanded(child: _field(context, radius: 16, maxLines: 3, padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9))),
        const SizedBox(width: 4),
        _actionButton(icon: Icons.add_rounded, tooltip: 'Attach', onPressed: onAttach, size: 38),
        _sendOrVoice(size: 38),
      ]), padding: const EdgeInsets.fromLTRB(6, 4, 6, 4));

  Widget _floatingCard(BuildContext context) => _shell(Container(
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(color: _entry, borderRadius: BorderRadius.circular(22), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 18, offset: const Offset(0, 6))]),
        child: Row(children: [
          _actionButton(icon: Icons.add_rounded, tooltip: 'Attach', onPressed: onAttach, size: 40),
          Expanded(child: _field(context, filled: false, radius: 18)),
          _actionButton(icon: Icons.emoji_emotions_outlined, tooltip: 'Emoji', onPressed: onEmoji, size: 40),
          _sendOrVoice(size: 40),
        ]),
      ), color: Colors.transparent);

  Widget _outlined(BuildContext context) => _shell(Row(children: [
        Expanded(child: Container(
          decoration: BoxDecoration(border: Border.all(color: _attach.withValues(alpha: 0.35)), borderRadius: BorderRadius.circular(18)),
          child: Row(children: [
            _actionButton(icon: Icons.attach_file_rounded, tooltip: 'Attach', onPressed: onAttach, size: 40),
            Expanded(child: _field(context, filled: false, radius: 18)),
            _actionButton(icon: Icons.emoji_emotions_outlined, tooltip: 'Emoji', onPressed: onEmoji, size: 40),
          ]),
        )),
        const SizedBox(width: 7),
        _sendOrVoice(square: true),
      ]));

  Widget _soft(BuildContext context) => _shell(Row(children: [
        _actionButton(icon: Icons.add_rounded, tooltip: 'Attach', onPressed: onAttach),
        Expanded(child: _field(context, radius: 28)),
        const SizedBox(width: 6),
        _sendOrVoice(),
      ]), color: _entry.withValues(alpha: 0.45));

  Widget _splitActions(BuildContext context) => _shell(Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Column(mainAxisSize: MainAxisSize.min, children: [
          _actionButton(icon: Icons.emoji_emotions_outlined, tooltip: 'Emoji', onPressed: onEmoji, size: 36),
          _actionButton(icon: Icons.attach_file_rounded, tooltip: 'Attach', onPressed: onAttach, size: 36),
        ]),
        Expanded(child: _field(context, radius: 16)),
        const SizedBox(width: 6),
        _sendOrVoice(square: true),
      ]));

  Widget _minimal(BuildContext context) => _shell(Row(children: [
        Expanded(child: _field(context, radius: 0, filled: false, hint: 'Type a message')),
        _actionButton(icon: Icons.add_rounded, tooltip: 'Attach', onPressed: onAttach),
        _sendOrVoice(size: 40),
      ]), border: Border(top: BorderSide(color: _entry)));

  Widget _boxed(BuildContext context) => _shell(Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: _entry, borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          _actionButton(icon: Icons.attach_file_rounded, tooltip: 'Attach', onPressed: onAttach, size: 38),
          Expanded(child: _field(context, filled: false, radius: 8)),
          _sendOrVoice(size: 38, square: true),
        ]),
      ));

  Widget _centerSend(BuildContext context) => _shell(Row(children: [
        _actionButton(icon: Icons.add_rounded, tooltip: 'Attach', onPressed: onAttach),
        Expanded(child: _field(context, radius: 18)),
        const SizedBox(width: 6),
        _sendOrVoice(size: 48),
        const SizedBox(width: 2),
        _actionButton(icon: Icons.emoji_emotions_outlined, tooltip: 'Emoji', onPressed: onEmoji),
      ]));

  Widget _stacked(BuildContext context) => _shell(Column(mainAxisSize: MainAxisSize.min, children: [
        _field(context, radius: 16, maxLines: 6),
        const SizedBox(height: 6),
        Row(children: [
          _actionButton(icon: Icons.add_circle_outline_rounded, tooltip: 'Attach', onPressed: onAttach, size: 40),
          _actionButton(icon: Icons.emoji_emotions_outlined, tooltip: 'Emoji', onPressed: onEmoji, size: 40),
          const Spacer(),
          _sendOrVoice(size: 40, square: true),
        ]),
      ]));

  Widget _editorial(BuildContext context) => _shell(Row(children: [
        Expanded(child: _field(context, radius: 6, filled: false, hint: 'Write a message…')),
        Container(width: 1, height: 30, color: _entry),
        _actionButton(icon: Icons.attach_file_rounded, tooltip: 'Attach', onPressed: onAttach),
        _sendOrVoice(size: 42, square: true),
      ]));

  Widget _edge(BuildContext context) => _shell(Row(children: [
        Expanded(child: _field(context, radius: 0, filled: false)),
        _actionButton(icon: Icons.emoji_emotions_outlined, tooltip: 'Emoji', onPressed: onEmoji, size: 40),
        _actionButton(icon: Icons.attach_file_rounded, tooltip: 'Attach', onPressed: onAttach, size: 40),
        _sendOrVoice(size: 40, square: true),
      ]), padding: const EdgeInsets.fromLTRB(12, 5, 4, 5), border: Border(top: BorderSide(color: _entry)));

  Widget _dense(BuildContext context) => _shell(Row(children: [
        _actionButton(icon: Icons.add_rounded, tooltip: 'Attach', onPressed: onAttach, size: 34),
        Expanded(child: _field(context, radius: 12, maxLines: 3, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8))),
        const SizedBox(width: 4),
        _sendOrVoice(size: 36, square: true),
      ]), padding: const EdgeInsets.all(4));

  Widget _wide(BuildContext context) => _shell(Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Row(children: [
          _actionButton(icon: Icons.attach_file_rounded, tooltip: 'Attach', onPressed: onAttach),
          Expanded(child: _field(context, radius: 22)),
          _actionButton(icon: Icons.emoji_emotions_outlined, tooltip: 'Emoji', onPressed: onEmoji),
          _sendOrVoice(),
        ]),
      )));

  Widget _slim(BuildContext context) => _shell(Row(children: [
        Expanded(child: _field(context, radius: 22, maxLines: 2, padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9))),
        const SizedBox(width: 5),
        _actionButton(icon: Icons.attach_file_rounded, tooltip: 'Attach', onPressed: onAttach, size: 36),
        _sendOrVoice(size: 36),
      ]), padding: const EdgeInsets.fromLTRB(8, 4, 8, 4));

  Widget _toolbar(BuildContext context) => _shell(Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          _actionButton(icon: Icons.add_rounded, tooltip: 'Attach', onPressed: onAttach, size: 36),
          _actionButton(icon: Icons.emoji_emotions_outlined, tooltip: 'Emoji', onPressed: onEmoji, size: 36),
          const Spacer(),
          Text('/task supported', style: TextStyle(color: theme.secondaryTextColor, fontSize: 10.5)),
        ]),
        Row(children: [Expanded(child: _field(context, radius: 14)), const SizedBox(width: 6), _sendOrVoice(size: 40, square: true)]),
      ]));

  Widget _workspace(BuildContext context) => _shell(Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Container(
          decoration: BoxDecoration(color: _entry, borderRadius: BorderRadius.circular(12)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            _actionButton(icon: Icons.add_rounded, tooltip: 'Attach', onPressed: onAttach, size: 38),
            _actionButton(icon: Icons.emoji_emotions_outlined, tooltip: 'Emoji', onPressed: onEmoji, size: 38),
          ]),
        ),
        const SizedBox(width: 7),
        Expanded(child: _field(context, radius: 12, maxLines: 6)),
        const SizedBox(width: 7),
        _sendOrVoice(size: 42, square: true),
      ]));

  Widget _focus(BuildContext context) => _shell(Row(children: [
        Expanded(child: _field(context, radius: 24, hint: 'Focus message…')),
        const SizedBox(width: 6),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) {
            final hasText = value.text.trim().isNotEmpty;
            return hasText
                ? _sendOrVoice()
                : PopupMenuButton<String>(
                    tooltip: 'Message actions',
                    icon: Icon(Icons.add_circle_outline_rounded, color: _attach),
                    onSelected: (value) {
                      if (value == 'attach') onAttach();
                      if (value == 'emoji') onEmoji();
                      if (value == 'voice') onVoice();
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'attach', child: Text('Attach')),
                      PopupMenuItem(value: 'emoji', child: Text('Emoji')),
                      PopupMenuItem(value: 'voice', child: Text('Voice note')),
                    ],
                  );
          },
        ),
      ]));

  Widget _expressive(BuildContext context) => _shell(Container(
        padding: const EdgeInsets.fromLTRB(8, 8, 6, 8),
        decoration: BoxDecoration(
          color: _entry,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: _attach.withValues(alpha: 0.18)),
        ),
        child: Row(children: [
          _actionButton(icon: Icons.add_circle_rounded, tooltip: 'Attach', onPressed: onAttach, size: 42),
          Expanded(child: _field(context, filled: false, radius: 22, maxLines: 5)),
          _actionButton(icon: Icons.emoji_emotions_rounded, tooltip: 'Emoji', onPressed: onEmoji, size: 42),
          _sendOrVoice(size: 44),
        ]),
      ), color: Colors.transparent);
}
