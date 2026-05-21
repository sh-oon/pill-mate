import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/widgets/app_buttons.dart';
import '../core/widgets/med_pill_svg.dart';
import 'mockup_scaffold.dart';

/// Phase 3 — 약 서랍 전체 화면.
///
/// 헤더 + 검색 + 필터 chip(전체/알람있음/알람없음) + 정렬 + 카드 리스트.
/// 빈 상태 / 결과 없음 / populated 세 가지 시나리오를 토글로 미리보기.
class MockupDrawerScreen extends StatefulWidget {
  const MockupDrawerScreen({super.key});

  @override
  State<MockupDrawerScreen> createState() => _MockupDrawerScreenState();
}

class _MockupDrawerScreenState extends State<MockupDrawerScreen> {
  _State _state = _State.populated;
  _Filter _filter = _Filter.all;
  _Sort _sort = _Sort.name;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return MockupScaffold(
      label: 'Phase 3 · 약 서랍 전체 화면',
      child: Column(
        children: [
          _PreviewToggle(state: _state, onChange: (s) => setState(() => _state = s)),
          Expanded(child: _DrawerBody(
            state: _state,
            filter: _filter,
            sort: _sort,
            query: _query,
            onFilter: (f) => setState(() => _filter = f),
            onSort: (s) => setState(() => _sort = s),
            onQuery: (q) => setState(() => _query = q),
          )),
        ],
      ),
    );
  }
}

class _PreviewToggle extends StatelessWidget {
  const _PreviewToggle({required this.state, required this.onChange});
  final _State state;
  final ValueChanged<_State> onChange;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceMuted,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.tune, size: 14, color: AppColors.textMuted),
          const SizedBox(width: 6),
          Text('mockup 시나리오:', style: AppTypography.bodySmall),
          const SizedBox(width: 10),
          Expanded(
            child: SegmentedButton<_State>(
              segments: const [
                ButtonSegment(value: _State.populated, label: Text('등록됨'), icon: Icon(Icons.list, size: 14)),
                ButtonSegment(value: _State.empty, label: Text('비어 있음'), icon: Icon(Icons.inbox, size: 14)),
                ButtonSegment(value: _State.noMatch, label: Text('검색 0건'), icon: Icon(Icons.search_off, size: 14)),
              ],
              selected: {state},
              onSelectionChanged: (set) => onChange(set.first),
              showSelectedIcon: false,
              style: const ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerBody extends StatelessWidget {
  const _DrawerBody({
    required this.state,
    required this.filter,
    required this.sort,
    required this.query,
    required this.onFilter,
    required this.onSort,
    required this.onQuery,
  });

  final _State state;
  final _Filter filter;
  final _Sort sort;
  final String query;
  final ValueChanged<_Filter> onFilter;
  final ValueChanged<_Sort> onSort;
  final ValueChanged<String> onQuery;

  @override
  Widget build(BuildContext context) {
    // populated가 아니면 mock data 비움.
    final items = state == _State.populated ? _items.where((i) {
      if (filter == _Filter.withAlarm && !i.hasAlarm) return false;
      if (filter == _Filter.noAlarm && i.hasAlarm) return false;
      if (query.isNotEmpty && !i.name.contains(query)) return false;
      return true;
    }).toList() : <_DrawerItemMock>[];

    return CustomScrollView(
      slivers: [
        // 헤더 (탭 화면이라 AppBar 대신 padding으로).
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('약 서랍', style: AppTypography.titleLarge),
                      const SizedBox(height: 2),
                      Text(
                        state == _State.populated
                          ? '등록한 약·영양제 ${_items.length}개'
                          : '아직 등록한 약이 없어요',
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                ),
                _AddButton(onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('등록 플로우 Step 1으로 이동')),
                  );
                }),
              ],
            ),
          ),
        ),
        // 검색 + 필터/정렬 — 등록 0개면 숨김.
        if (state != _State.empty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: _SearchBar(
                query: state == _State.noMatch ? '없는약이름' : query,
                onChanged: onQuery,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _FilterChip(
                    label: '전체',
                    selected: filter == _Filter.all,
                    onTap: () => onFilter(_Filter.all),
                  ),
                  const SizedBox(width: 6),
                  _FilterChip(
                    label: '알람 있음',
                    icon: Icons.alarm_on,
                    selected: filter == _Filter.withAlarm,
                    onTap: () => onFilter(_Filter.withAlarm),
                  ),
                  const SizedBox(width: 6),
                  _FilterChip(
                    label: '알람 없음',
                    icon: Icons.alarm_off,
                    selected: filter == _Filter.noAlarm,
                    onTap: () => onFilter(_Filter.noAlarm),
                  ),
                  const SizedBox(width: 12),
                  Container(width: 1, color: AppColors.borderHairline),
                  const SizedBox(width: 12),
                  _SortChip(sort: sort, onTap: () {
                    // mock: 한 단계씩 회전
                    final next = _Sort.values[(sort.index + 1) % _Sort.values.length];
                    onSort(next);
                  }),
                ],
              ),
            ),
          ),
        ],

        // 본문.
        if (state == _State.empty)
          SliverFillRemaining(hasScrollBody: false, child: _EmptyState())
        else if (items.isEmpty)
          SliverFillRemaining(hasScrollBody: false, child: _NoMatchState(filter: filter, query: query))
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
            sliver: SliverList.separated(
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _DrawerCard(item: items[i]),
            ),
          ),
      ],
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: const Padding(
          padding: EdgeInsets.all(10),
          child: Icon(Icons.add, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.query, required this.onChanged});
  final String query;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderHairline),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: AppColors.textFaint, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: TextEditingController(text: query),
              onChanged: onChanged,
              decoration: const InputDecoration(
                hintText: '내 약에서 검색',
                hintStyle: TextStyle(color: AppColors.textFaint),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.primary : AppColors.borderHairline),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: selected ? Colors.white : AppColors.textMuted),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: selected ? Colors.white : AppColors.textStrong,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  const _SortChip({required this.sort, required this.onTap});
  final _Sort sort;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderHairline),
        ),
        child: Row(
          children: [
            const Icon(Icons.swap_vert, size: 14, color: AppColors.textMuted),
            const SizedBox(width: 4),
            Text(sort.label, style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _DrawerCard extends StatelessWidget {
  const _DrawerCard({required this.item});
  final _DrawerItemMock item;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${item.name} → tracked detail로 이동')),
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderHairline),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14),
              ),
              child: MedPillSvg(name: item.name, size: 40),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(item.name, style: AppTypography.titleMedium, overflow: TextOverflow.ellipsis),
                      ),
                      if (item.isSeed) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.successTint,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('seed', style: AppTypography.bodySmall.copyWith(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(item.meta, style: AppTypography.bodySmall, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            if (item.hasAlarm)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Icon(Icons.alarm_on, color: AppColors.primary, size: 22),
                  if (item.nextTime != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.nextTime!,
                      style: AppTypography.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                    ),
                  ],
                ],
              )
            else
              const Icon(Icons.alarm_off, color: AppColors.textFaint, size: 22),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.primaryTint,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.inbox_outlined, size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text(
              '아직 등록한 약이 없어요',
              style: AppTypography.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '카탈로그에서 자주 챙기는 영양제를 찾아\n빠르게 등록해보세요.',
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            AppButton(
              label: '약/영양제 추가하기',
              variant: AppButtonVariant.primary,
              size: AppButtonSize.lg,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('등록 플로우 Step 1로 이동')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _NoMatchState extends StatelessWidget {
  const _NoMatchState({required this.filter, required this.query});
  final _Filter filter;
  final String query;

  @override
  Widget build(BuildContext context) {
    final reason = query.isNotEmpty
        ? '"$query" 으로 검색한 결과 없음'
        : filter == _Filter.withAlarm
            ? '알람이 설정된 약이 없어요'
            : filter == _Filter.noAlarm
                ? '모든 약에 알람이 설정되어 있어요'
                : '결과 없음';
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, size: 56, color: AppColors.textFaint),
            const SizedBox(height: 16),
            Text(reason, style: AppTypography.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              '검색어를 바꾸거나 필터를 해제해보세요',
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Types + mock data
// ─────────────────────────────────────────────────────────────────────────────

enum _State { populated, empty, noMatch }

enum _Filter { all, withAlarm, noAlarm }

enum _Sort {
  name('이름순'),
  added('등록순'),
  next('다음 복용순');

  const _Sort(this.label);
  final String label;
}

class _DrawerItemMock {
  const _DrawerItemMock({
    required this.name,
    required this.meta,
    required this.hasAlarm,
    this.nextTime,
    this.isSeed = true,
  });

  final String name;
  final String meta;
  final bool hasAlarm;
  final String? nextTime;
  final bool isSeed;
}

const _items = <_DrawerItemMock>[
  _DrawerItemMock(
    name: '비타민D',
    meta: '영양제 · 1000 IU · 매일 1회',
    hasAlarm: true,
    nextTime: '오후 8:00',
  ),
  _DrawerItemMock(
    name: '오메가3',
    meta: '영양제 · 1000 mg · 매일 1회',
    hasAlarm: true,
    nextTime: '아침 9:00',
  ),
  _DrawerItemMock(
    name: '종합비타민',
    meta: '영양제 · 1정 · 매일 1회',
    hasAlarm: true,
    nextTime: '아침 9:00',
  ),
  _DrawerItemMock(
    name: '유산균',
    meta: '영양제 · 100억 · 알람 미설정',
    hasAlarm: false,
  ),
  _DrawerItemMock(
    name: '내가 추가한 약',
    meta: '약 · 직접 입력 · 알람 미설정',
    hasAlarm: false,
    isSeed: false,
  ),
];
