String formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes % 60;
  
  if (hours > 0 && minutes > 0) {
    return '${hours}h ${minutes}min';
  } else if (hours > 0) {
    return '${hours}h';
  } else {
    return '${minutes}min';
  }
}

String normalizeDietaryCriteria(String criteria) {
  if (criteria.isEmpty) return criteria;
  
  // Convert to Title Case (first letter of each word uppercase)
  return criteria.split(' ').map((word) {
    if (word.isEmpty) return word;
    return word[0].toUpperCase() + word.substring(1).toLowerCase();
  }).join(' ');
}