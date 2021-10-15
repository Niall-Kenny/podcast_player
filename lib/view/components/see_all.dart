import 'package:flutter/material.dart';
import 'package:fountain_tech_test/fount_test_app_bar.dart';

class SeeAll extends StatelessWidget {
  /// [emptyState] will display when [itemCount] == 0
  final Widget emptyState;
  final Widget Function(BuildContext, int) itemBuilder;
  final String title;
  final int itemCount;
  const SeeAll({
    required this.title,
    required this.itemBuilder,
    required this.itemCount,
    this.emptyState = const SizedBox.shrink(),
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaleFactor: createTextScaleFactor(context),
      ),
      child: Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                height: 22,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 15.0),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(
                height: 22,
              ),
              itemCount == 0
                  ? emptyState
                  : Expanded(
                      child: ListView.separated(
                        itemCount: itemCount,
                        separatorBuilder: (context, index) => const Divider(),
                        itemBuilder: itemBuilder,
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
