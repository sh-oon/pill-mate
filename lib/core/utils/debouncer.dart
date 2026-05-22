import 'dart:async';
import 'dart:ui' show VoidCallback;

/// 사용자 입력처럼 burst로 들어오는 액션을 일정 시간 멈춘 뒤에 1회만 실행.
///
/// 일반적 사용처:
/// - 검색 입력 디바운스 (`onChanged`마다 setState 막기)
/// - 스크롤 위치 저장 (마지막 위치 1회만)
/// - 자동 저장 (입력 멈춘 뒤 저장)
///
/// State에서 사용 시 `dispose()`에서 [cancel] 호출 필수 — 그렇지 않으면 unmounted
/// 위젯에 setState가 호출돼 throw.
///
/// ```dart
/// final _searchDebouncer = Debouncer(delay: Duration(milliseconds: 220));
///
/// @override
/// void dispose() {
///   _searchDebouncer.dispose();
///   super.dispose();
/// }
///
/// void _onChanged(String v) {
///   _searchDebouncer.run(() => setState(() => _query = v.trim()));
/// }
/// ```
class Debouncer {
  Debouncer({required this.delay});

  /// 마지막 [run] 호출 이후 액션 실행까지 기다리는 시간.
  final Duration delay;

  Timer? _timer;

  /// 이전에 예약된 액션이 있으면 취소하고, [delay] 뒤에 [action] 실행 예약.
  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  /// 예약된 액션이 있다면 취소. 발화 전이면 액션은 실행되지 않음.
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  /// 예약된 액션이 있는지 여부.
  bool get isPending => _timer?.isActive ?? false;

  /// [cancel]과 동일 — `dispose` 라이프사이클 매칭을 위한 별칭.
  void dispose() => cancel();
}
