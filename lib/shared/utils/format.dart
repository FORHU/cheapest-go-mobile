/// Display formatting for prices, dates, and tee times.
library;

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// `4850` → `₱4,850`.
String formatPeso(int amount) {
  final digits = amount.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
    buf.write(digits[i]);
  }
  return '${amount < 0 ? '-' : ''}₱$buf';
}

/// `Nov 14`.
String formatShortDate(DateTime d) => '${_months[d.month - 1]} ${d.day}';

/// `Thu, Nov 14`.
String formatDayDate(DateTime d) => '${weekdayShort(d)}, ${formatShortDate(d)}';

/// `Thu`.
String weekdayShort(DateTime d) => _weekdays[d.weekday - 1];

/// `Nov 14 – 17`, or `Nov 30 – Dec 2` across months.
String formatDateRange(DateTime start, DateTime end) {
  if (start.month == end.month && start.year == end.year) {
    return '${formatShortDate(start)} – ${end.day}';
  }
  return '${formatShortDate(start)} – ${formatShortDate(end)}';
}

/// `06:40` → `6:40 AM`, `13:10` → `1:10 PM`.
String formatTeeTime(String hhmm) {
  final parts = hhmm.split(':');
  final h = int.parse(parts[0]);
  final suffix = h < 12 ? 'AM' : 'PM';
  final h12 = h % 12 == 0 ? 12 : h % 12;
  return '$h12:${parts[1]} $suffix';
}

/// `1` → `1 night`, `3` → `3 nights`.
String plural(int n, String one, [String? many]) => '$n ${n == 1 ? one : (many ?? '${one}s')}';

/// Date with the time of day dropped.
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
