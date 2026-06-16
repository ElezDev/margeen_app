import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Moneda colombiana (COP).
const String kCurrencyCode = 'COP';
const String kCurrencySymbol = r'$';
const String kCurrencyInputPrefix = r'$ ';

final _currencyFormat = NumberFormat.currency(
  locale: 'es_CO',
  symbol: kCurrencySymbol,
  decimalDigits: 0,
);

final _dateTimeFormat = DateFormat('d MMM yyyy, HH:mm', 'es_CO');
final _dateFormat = DateFormat('d MMM yyyy', 'es_CO');
final _monthYearFormat = DateFormat('MMMM yyyy', 'es_CO');

double parseAmount(String? value) {
  if (value == null || value.isEmpty) return 0;

  final trimmed = value.trim();
  final direct = double.tryParse(trimmed);
  if (direct != null) return direct;

  final normalized = trimmed
      .replaceAll(kCurrencyCode, '')
      .replaceAll(kCurrencySymbol, '')
      .replaceAll('.', '')
      .replaceAll(',', '.')
      .trim();
  return double.tryParse(normalized) ?? 0;
}

/// Formato COP para pantalla: `$ 1.030.500`
String formatCurrency(String? value) => formatCurrencyNum(parseAmount(value));

String formatCurrencyNum(num value) {
  final raw = _currencyFormat.format(value);
  if (raw.startsWith(kCurrencySymbol) &&
      raw.length > 1 &&
      raw[1] != ' ') {
    return '$kCurrencySymbol ${raw.substring(1)}';
  }
  return raw;
}

/// Etiqueta explícita con código: `$ 1.030.500 COP`
String formatCurrencyCop(num value) =>
    '${formatCurrencyNum(value)} $kCurrencyCode';

InputDecoration currencyInputDecoration({
  required String labelText,
  String? hintText,
}) {
  return InputDecoration(
    labelText: labelText,
    hintText: hintText,
    prefixText: kCurrencyInputPrefix,
  );
}

String? formatDateTime(String? iso) {
  if (iso == null || iso.isEmpty) return null;
  try {
    return _dateTimeFormat.format(DateTime.parse(iso).toLocal());
  } catch (_) {
    return iso;
  }
}

String? formatDate(String? iso) {
  if (iso == null || iso.isEmpty) return null;
  try {
    return _dateFormat.format(DateTime.parse(iso).toLocal());
  } catch (_) {
    return iso;
  }
}

/// Convierte etiquetas de mes de la API (ej. "June 2026") a español.
String formatPeriodMonth(String raw) {
  if (raw.isEmpty) return raw;
  try {
    final parsed = DateFormat('MMMM yyyy', 'en_US').parse(raw);
    return _capitalize(_monthYearFormat.format(parsed));
  } catch (_) {
    try {
      final parsed = DateTime.parse(raw);
      return _capitalize(_monthYearFormat.format(parsed));
    } catch (_) {
      return raw;
    }
  }
}

String _capitalize(String value) {
  if (value.isEmpty) return value;
  return value[0].toUpperCase() + value.substring(1);
}

String formatQuantity(String? value) {
  final amount = parseAmount(value);
  if (amount == amount.roundToDouble()) {
    return amount.toInt().toString();
  }
  return amount.toString();
}

String statusLabel(String status) {
  switch (status) {
    case 'issued':
      return 'Emitida';
    case 'cancelled':
      return 'Anulada';
    case 'draft':
      return 'Borrador';
    default:
      return status;
  }
}
