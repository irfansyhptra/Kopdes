import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme.dart';
import '../../../../shared/widgets/apple_ui.dart';
import '../../domain/directions.dart';
import '../providers/koperasi_provider.dart';
import '../widgets/koperasi_card.dart';

/// Halaman "Lihat Lainnya": seluruh Kopdes dengan pencarian, filter, dan
/// paginasi.
class KoperasiListScreen extends ConsumerStatefulWidget {
  const KoperasiListScreen({super.key});

  @override
  ConsumerState<KoperasiListScreen> createState() => _KoperasiListScreenState();
}

class _KoperasiListScreenState extends ConsumerState<KoperasiListScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  /// Pencarian di-debounce supaya tidak mengirim request per ketikan.
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
      ref.read(koperasiListPagedProvider.notifier).loadMore();
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref
          .read(koperasiFilterProvider.notifier)
          .update((f) => f.copyWith(search: value));
    });
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(koperasiListPagedProvider);
    final filter = ref.watch(koperasiFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceSoft,
      appBar: AppBar(title: const Text('Kopdes')),
      body: RefreshIndicator(
        onRefresh: () => ref
            .read(koperasiListPagedProvider.notifier)
            .load(forceRefresh: true),
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
                        hintText: 'Cari Kopdes atau desa...',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _FilterBar(filter: filter),
                  ],
                ),
              ),
            ),

            async.when(
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
              ),
              error: (_, __) => SliverToBoxAdapter(
                child: _Message(
                  message: 'Data belum berhasil dimuat.',
                  actionLabel: 'Coba Lagi',
                  onAction: () => ref
                      .read(koperasiListPagedProvider.notifier)
                      .load(forceRefresh: true),
                ),
              ),
              data: (list) {
                if (list.items.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: _Message(
                      message:
                          'Belum ada Kopdes yang cocok.\n'
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
                      final koperasi = list.items[index];
                      return KoperasiCard(
                        koperasi: koperasi,
                        onOpen: () => context.push('/koperasi/${koperasi.id}'),
                        onDirections: () => openDirections(
                          latitude: koperasi.latitude,
                          longitude: koperasi.longitude,
                          label: koperasi.name,
                        ),
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

class _FilterBar extends ConsumerWidget {
  final KoperasiFilter filter;

  const _FilterBar({required this.filter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void update(KoperasiFilter next) =>
        ref.read(koperasiFilterProvider.notifier).state = next;

    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          for (final km in const [5.0, 10.0, 25.0])
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: AppleChip(
                label: '${km.toInt()} km',
                selected: filter.radiusKm == km,
                onTap: () => update(filter.copyWith(radiusKm: km)),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: AppleChip(
              label: 'Rating 4+',
              selected: filter.minRating >= 4,
              onTap: () => update(
                filter.copyWith(minRating: filter.minRating >= 4 ? 0 : 4),
              ),
            ),
          ),
          AppleChip(
            label: 'Buka Sekarang',
            selected: filter.openOnly,
            onTap: () => update(filter.copyWith(openOnly: !filter.openOnly)),
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
