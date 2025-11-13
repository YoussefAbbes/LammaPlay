class GridSpec {
  static int columnsForWidth(double width, {int min = 2, int max = 6}) {
    if (width < 600) return min; // compact
    if (width < 1024) return (min + max) ~/ 2; // medium
    return max; // expanded
  }
}
