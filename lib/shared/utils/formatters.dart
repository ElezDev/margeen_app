import 'package:intl/intl.dart';

final _currencyFormat = NumberFormat.currency(
  locale: 'es_CO',
  symbol: r'$',
  decimalDigits: 0,
);

final _dateFormat = DateFormat('d MMM yyyy, HH:mm', 'es_CO');

double parseAmount(String? value) => double.tryParse(value ?? '') ?? 0;

String formatCurrency(String? value) =>
    _currencyFormat.format(parseAmount(value));

String formatCurrencyNum(num value) => _currencyFormat.format(value);

String? formatDateTime(String? iso) {
  if (iso == null || iso.isEmpty) return null;
  try {
    return _dateFormat.format(DateTime.parse(iso).toLocal());
  } catch (_) {
    return iso;
  }
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
