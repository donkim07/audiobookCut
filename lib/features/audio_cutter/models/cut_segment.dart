class CutSegment {
  final String time;
  final String name;

  CutSegment({
    required this.time,
    required this.name,
  });

  Duration get duration {
    final parts = time.split(':');
    if (parts.length != 3) return Duration.zero;
    
    return Duration(
      hours: int.tryParse(parts[0]) ?? 0,
      minutes: int.tryParse(parts[1]) ?? 0,
      seconds: int.tryParse(parts[2]) ?? 0,
    );
  }
} 