import 'package:flutter/material.dart';

class GamePauseOverlay extends StatelessWidget {
  final VoidCallback onResume;
  const GamePauseOverlay({super.key, required this.onResume});
  @override
  Widget build(BuildContext context) => Positioned.fill(
        child: ColoredBox(
            color: const Color(0xCC101827),
            child: Center(
              child: FilledButton.icon(
                onPressed: onResume,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Devam et'),
              ),
            )),
      );
}
