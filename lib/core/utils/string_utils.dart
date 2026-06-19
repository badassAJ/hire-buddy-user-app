extension StringExtensions on String {
  String toTitleCase() {
    if (isEmpty) return this;
    return split(' ').map((word) {
      if (word.isEmpty) return word;
      // Entire word is uppercase (e.g. "CLEANING", "AC") → first cap + rest lowercase
      if (word == word.toUpperCase()) {
        return word[0].toUpperCase() + word.substring(1).toLowerCase();
      }
      // Mixed/lowercase → just capitalize first letter
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }
}
