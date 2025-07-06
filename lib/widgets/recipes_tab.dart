import 'package:flutter/material.dart';

class RecipeTabView extends StatefulWidget {
  final Future<void> Function() onRefresh;
  final Widget Function() searchBarBuilder;
  final Widget Function() gridBuilder;

  const RecipeTabView({
    super.key,
    required this.onRefresh,
    required this.searchBarBuilder,
    required this.gridBuilder,
  });

  @override
  State<RecipeTabView> createState() => _RecipeTabViewState();
}

class _RecipeTabViewState extends State<RecipeTabView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // important!
    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: Column(
        children: [
          widget.searchBarBuilder(),
          Expanded(child: widget.gridBuilder()),
        ],
      ),
    );
  }
}