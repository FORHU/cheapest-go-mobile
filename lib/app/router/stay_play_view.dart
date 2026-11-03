import 'package:flutter/material.dart';
import 'package:cheapest_go_mobile/features/golf/views/golf_view.dart';
import 'package:cheapest_go_mobile/features/hotels/views/hotel_results_view.dart';
import 'package:cheapest_go_mobile/shared/components/ui_kit.dart';

/// The Stay & Play tab: hotels and golf near the arrival airport, side by side
/// behind one Hotels | Golf switch. Composes the two features, so it lives in
/// the app layer.
class StayPlayView extends StatefulWidget {
  const StayPlayView({this.initialTab = 0, super.key});

  /// 0 hotels, 1 golf.
  final int initialTab;

  @override
  State<StayPlayView> createState() => _StayPlayViewState();
}

class _StayPlayViewState extends State<StayPlayView> {
  late int _tab = widget.initialTab;

  @override
  void didUpdateWidget(StayPlayView old) {
    super.didUpdateWidget(old);
    if (old.initialTab != widget.initialTab) _tab = widget.initialTab;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Stay & Play', style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 26)),
                const SizedBox(height: 12),
                SegmentedTabs(
                  labels: const ['Hotels', 'Golf'],
                  selected: _tab,
                  onChanged: (i) => setState(() => _tab = i),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: IndexedStack(
              index: _tab,
              children: const [
                HotelResultsView(showBack: false),
                GolfView(showBack: false),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
