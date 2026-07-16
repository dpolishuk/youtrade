import 'package:flutter/material.dart';

/// A single strike row for an options chain.
@immutable
class OptionChainStrike {
  const OptionChainStrike({
    required this.strike,
    required this.isAtm,
    required this.callInTheMoney,
    required this.callIv,
    required this.callDelta,
    required this.callMark,
    required this.putIv,
    required this.putDelta,
    required this.putMark,
  });

  final double strike;
  final bool isAtm;
  final bool callInTheMoney;
  final double callIv;
  final double callDelta;
  final double callMark;
  final double putIv;
  final double putDelta;
  final double putMark;
}
