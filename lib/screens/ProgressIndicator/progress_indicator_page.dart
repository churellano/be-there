import 'package:flutter/material.dart';

class ProgressIndicatorPage extends StatefulWidget {
  const ProgressIndicatorPage({super.key});

  @override
  State<ProgressIndicatorPage> createState() =>
      _ProgressIndicatorPageState();
}

class _ProgressIndicatorPageState extends State<ProgressIndicatorPage>
  with TickerProviderStateMixin {
  late AnimationController controller;
  @override
  void initState() {
    controller = AnimationController(
      /// [AnimationController]s can be created with `vsync: this` because of
      /// [TickerProviderStateMixin].
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(() {
        setState(() {});
      });
    controller.repeat(reverse: false);
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding (
        padding: const EdgeInsets.all(20.0),
        child: const CircularProgressIndicator(
          value: null,
          semanticsLabel: 'Circular progress indicator',
        ),
      ),
    );
  }
}