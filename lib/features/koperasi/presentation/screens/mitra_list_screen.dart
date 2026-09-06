import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/apple_ui.dart';
import '../../domain/koperasi.dart';
import '../providers/koperasi_provider.dart';
import '../widgets/location_prompt.dart';
import '../widgets/mitra_card.dart';

/// Halaman "Lihat Semua" Mitra UMKM: pencarian, filter kategori/jarak/rating/
/// status buka, dan paginasi.
class MitraListScreen extends ConsumerStatefulWidget {
  const MitraListScreen({super.key});

  @override
  ConsumerState<MitraListScreen> createState() => _MitraListScreenState();
}

class _MitraListScreenState extends ConsumerState<MitraListScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 400) {
      ref.read(mitraListPagedProvider.notifier).loadMore();
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref
          .read(mitraFilterProvider.notifier)
          .update((f) => f.copyWith(search: value));
    });
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(mitraListPagedProvider);
    final filter = ref.watch(mitraFilterProvider);
    final hasLocation = ref.watch(userCoordinatesProvider) != null;

    return Scaffold(
      backgroundColor: AppColors.surfaceSoft,
      appBar: AppBar(title: const Text('Mitra UMKM')),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(mitraListPagedProvider.notifier).load(forceRefresh: true),
        color: AppColors.primary,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.base),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      textInputAction: TextInputAction.search,
                      decoration: const InputDecoration(
                        hintText: 'Cari nama usaha...',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _MitraFilterBar(filter: filter),
                  ],
                ),
              ),
            ),

            // Pencarian mitra memang berbasis kedekatan; tanpa koordinat yang
            // ditampilkan adalah ajakan memilih lokasi, bukan daftar kosong.
            if (!hasLocation)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: AppSpacing.lg),
                  child: LocationPrompt(),
                ),
              )
            else
              async.when(
                loading: () => const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                error: (_, __) => SliverToBoxAdapter(
                  child: _Message(
                    message: 'Data belum berhasil dimuat.',
                    actionLabel: 'Coba Lagi',
                    onAction: () => ref
                        .read(mitraListPagedProvider.notifier)
                        .load(forceRefresh: true),
                  ),
                ),
                data: (list) {
                  if (list.items.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: _Message(
                        message:
                            'Belum ada Mitra UMKM pada radius ini.\n'
                            'Perluas jarak pencarian atau ubah filter.',
                      ),
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.base,
                      0,
                      AppSpacing.base,
                      AppSpacing.xl,
                    ),
                    sliver: SliverList.separated(
                      itemCount: list.items.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.md),
                      itemBuilder: (context, index) {
                        final mitra = list.items[index];
                        return MitraCard(
                          mitra: mitra,
                          fullWidth: true,
                          onVisit: () => context.push('/umkm/${mitra.id}'),
                        );
                      },
                    ),
                  );
                },
              ),

            if (async.valueOrNull?.isLoadingMore ?? false)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.xl),
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MitraFilterBar extends ConsumerWidget {
  final MitraFilter filter;

  const _MitraFilterBar({required this.filter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void update(MitraFilter next) =>
        ref.read(mitraFilterProvider.notifier).state = next;

    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: AppleChip(
              label: 'Semua',
              selected: filter.category == null,
              onTap: () => update(filter.copyWith(clearCategory: true)),
            ),
          ),
          for (final c in MitraCategory.values)
            if (c != MitraCategory.lainnya)
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: AppleChip(
                  label: c.label,
                  selected: filter.category == c,
                  onTap: () => update(filter.copyWith(category: c)),
                ),
              ),
          for (final km in const [5.0, 10.0, 25.0])
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: AppleChip(
                label: '${km.toInt()} km',
                selected: filter.radiusKm == km,
                onTap: () => update(filter.copyWith(radiusKm: km)),
              ),
            ),
          AppleChip(
            label: 'Rating 4+',
            selected: filter.minRating >= 4,
            onTap: () => update(
              filter.copyWith(minRating: filter.minRating >= 4 ? 0 : 4),
            ),
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _Message({required this.message, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.muted),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
