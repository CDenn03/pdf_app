class ActiveViewportSlot<T extends Object> {
  Object? _owner;
  T? _target;

  T? get active => _target;

  void attach(Object owner, T target) {
    _owner = owner;
    _target = target;
  }

  bool detach(Object owner) {
    if (!identical(_owner, owner)) return false;
    _owner = null;
    _target = null;
    return true;
  }
}
