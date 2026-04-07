String formatBytes(int? bytes) {
  if (bytes == null) {
    return '--';
  }
  if (bytes < 1024) {
    return '$bytes B';
  }
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

String formatShortDate(DateTime? value) {
  if (value == null) {
    return '--';
  }
  final local = value.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '${local.year}-$month-$day';
}

String formatShortDateTime(DateTime? value) {
  if (value == null) {
    return '--';
  }
  final local = value.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${local.year}-$month-$day $hour:$minute';
}

String titleCaseToken(String value) {
  return value
      .split('_')
      .where((token) => token.isNotEmpty)
      .map(
        (token) => '${token[0].toUpperCase()}${token.substring(1)}',
      )
      .join(' ');
}
