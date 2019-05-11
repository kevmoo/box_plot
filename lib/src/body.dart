const _epsilon = 0.0001;

/// Represents a point object with a location and velocity.
class Body {
  double _velocity;
  double _location;

  double get velocity => _velocity;

  double get location => _location;

  Body({double location = 0, double velocity = 0})
      : assert(location.isFinite),
        _location = location,
        assert(velocity.isFinite),
        _velocity = velocity;

  /// [drag] must be greater than or equal to zero. It defines the percent of
  /// the previous velocity that is lost every second.
  ///
  /// Returns `true` if the value was updated.
  bool animate(double seconds,
      {double force = 0, double drag = 0, double maxVelocity, double snapTo}) {
    assert(seconds.isFinite && seconds > 0,
        'milliseconds must be finite and > 0 (was $seconds)');

    force ??= 0;
    assert(force.isFinite, 'force must be finite');

    drag ??= 0;
    assert(drag.isFinite && drag >= 0, 'drag must be finite and >= 0');

    maxVelocity ??= double.infinity;
    assert(maxVelocity > 0, 'maxVelocity must be null or > 0');

    final dragVelocity = _velocity * (1 - drag * seconds);

    if (_sameDirection(_velocity, dragVelocity)) {
      assert(dragVelocity.abs() <= _velocity.abs(),
          'Huh? $dragVelocity $_velocity');
      _velocity = dragVelocity;
    } else {
      _velocity = 0;
    }

    // apply force to velocity
    _velocity += force * seconds;

    // apply terminal velocity
    if (_velocity.abs() > maxVelocity) {
      _velocity = _velocity.sign * maxVelocity;
    }

    // update location
    final locationDelta = _velocity * seconds;
    if (locationDelta.abs() > _epsilon || (force.abs() * seconds) > _epsilon) {
      _location += locationDelta;
      return true;
    } else {
      if (snapTo != null && (_location - snapTo).abs() < _epsilon * 2) {
        _location = snapTo;
      }
      _velocity = 0;
      return false;
    }
  }

  @override
  String toString() => 'Body @($_location) ↕($_velocity)';

  @override
  bool operator ==(Object other) =>
      other is Body &&
      other._location == _location &&
      other._velocity == _velocity;

  // Since this is a mutable class, a constant value is returned for `hashCode`
  // This ensures values don't get lost in a Hashing data structure.
  // Note: this means you shouldn't use this type in most Map/Set impls.
  @override
  int get hashCode => 199;
}

bool _sameDirection(double a, double b) => a.sign == b.sign;
