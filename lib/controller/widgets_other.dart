void initialiseWidget() {}

void widgetInitState(Function function) {}

// Called when Doing Background Work initiated from Widget
Future<void> backgroundCallback(Uri? uri) async {}

Future<void> updateAppWidget(
  int percentage, {
  String bandKey = '',
  String bandLabel = '',
  String oddsText = '',
}) async {}

Future<void> clearAppWidget() async {}
