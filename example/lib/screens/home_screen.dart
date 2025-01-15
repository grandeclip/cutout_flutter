import 'package:flutter/material.dart';

import '../routes.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CutOut Example'),
      ),
      body: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 50),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.u2net);
                  },
                  child: const Text('U2Net Demo'),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.sam);
                  },
                  child: const Text('SAM Demo'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
