import 'package:sefer/features/reader/domain/active_viewport_slot.dart';
import 'package:sefer/features/reader/domain/reader_page_navigation.dart';

class ActivePageNavigation implements ReaderPageNavigation {
  final ActiveViewportSlot<ReaderPageNavigation> _slot = ActiveViewportSlot();

  void attach(Object owner, ReaderPageNavigation target) =>
      _slot.attach(owner, target);

  void detach(Object owner) => _slot.detach(owner);

  @override
  int get currentPage => _slot.active?.currentPage ?? 1;

  @override
  Future<void> goToPage(int pageNumber) async =>
      _slot.active?.goToPage(pageNumber);
}
