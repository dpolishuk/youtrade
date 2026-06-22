import 'package:flutter/material.dart';

import '../../../domain/entities/venue.dart';

Color venueColor(Venue venue, {required Color accent}) {
  return switch (venue) {
    Venue.binance => const Color(0xFFF0B90B),
    Venue.bybit => const Color(0xFFF7A600),
    Venue.okx => accent,
    Venue.coinbase => const Color(0xFF0052FF),
    Venue.unknown => const Color(0xFF9E9E9E),
  };
}

Color venueTint(Venue venue, {required Color accent}) {
  return venueColor(venue, accent: accent).withValues(alpha: 0.14);
}

String venueInitial(Venue venue) {
  return switch (venue) {
    Venue.binance => 'B',
    Venue.bybit => 'Y',
    Venue.okx => 'O',
    Venue.coinbase => 'C',
    Venue.unknown => '?',
  };
}
