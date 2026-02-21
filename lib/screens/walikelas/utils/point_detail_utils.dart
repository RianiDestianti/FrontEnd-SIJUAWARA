class DetailPointUtils {
  static String resolveSpLevel(String? raw, int total) {
    final sp = raw?.trim();
    if (sp != null && sp.isNotEmpty) return sp;
    if (total <= -76) return 'SP3';
    if (total <= -51) return 'SP2';
    if (total <= -25) return 'SP1';
    return '-';
  }

  static String resolvePhLevel(String? raw, int total) {
    if (total <= -25) return '-';
    final ph = raw?.trim();
    if (ph != null && ph.isNotEmpty) return ph;
    if (total >= 151) return 'PH3';
    if (total >= 126) return 'PH2';
    if (total >= 100) return 'PH1';
    return '-';
  }

  static String signed(int v) => v > 0 ? '+$v' : '$v';
}