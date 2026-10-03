import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Providers & State
import '../../features/auth/presentation/providers/auth_provider.dart';

// Screens
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/koperasi/presentation/screens/koperasi_detail_screen.dart';
import '../../features/koperasi/presentation/screens/koperasi_list_screen.dart';
import '../../features/content/presentation/screens/content_page_screen.dart';
import '../../features/content/presentation/screens/membership_register_screen.dart';
import '../../features/discovery/presentation/screens/umkm_product_detail_screen.dart';
import '../../features/koperasi/presentation/screens/mitra_detail_screen.dart';
import '../../features/koperasi/presentation/screens/mitra_list_screen.dart';
import '../../features/admin/presentation/screens/umkm_location_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/onboarding/presentation/providers/onboarding_provider.dart';
import '../../features/onboarding/presentation/screens/permission_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/session_expired_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/marketplace/presentation/screens/marketplace_screen.dart';
import '../../features/employee/presentation/screens/employee_dashboard_page.dart';
import '../../features/employee/presentation/screens/finance_report_screen.dart';
import '../../features/employee/presentation/screens/stock_management_screen.dart';
import '../../features/product/presentation/screens/product_detail_screen.dart';
import '../../features/order/presentation/screens/orders_page.dart';
import '../../features/order/presentation/screens/checkout_screen.dart';
import '../../features/order/presentation/screens/order_success_screen.dart';
import '../../features/order/presentation/screens/order_history_screen.dart';
import '../../features/order/presentation/screens/order_detail_screen.dart';
import '../../features/delivery/presentation/screens/tracking_screen.dart';
import '../../features/umkm/presentation/screens/seller_dashboard_screen.dart';
import '../../features/umkm/presentation/screens/product_screen.dart';
import '../../features/umkm/presentation/screens/product_detail_screen.dart'
    as seller_view;
import '../../features/umkm/presentation/screens/product_form_screen.dart';
import '../../features/umkm/presentation/screens/order_screen.dart';
import '../../features/umkm/presentation/screens/store_profile_screen.dart';
import '../../features/ai_assistant/presentation/screens/ai_assistant_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../../features/courier/presentation/screens/courier_dashboard_screen.dart';
import '../../features/product/presentation/screens/admin/admin_product_list_screen.dart';
import '../../features/product/presentation/screens/admin/admin_product_form_screen.dart';
import '../../features/product/presentation/screens/admin/admin_category_list_screen.dart';
import '../../features/admin/presentation/screens/mitra_management_screen.dart';
import '../../features/admin/presentation/screens/umkm_product_takedown_screen.dart';
import '../../features/admin/presentation/screens/order_management_screen.dart';
import '../../features/admin/presentation/screens/courier_management_screen.dart';
import '../../features/admin/presentation/screens/admin_profile_screen.dart';
import '../../features/chat/presentation/screens/conversation_list_screen.dart';
import '../../features/chat/presentation/screens/chat_detail_screen.dart';
import '../../features/chat/presentation/screens/chat_hub_screen.dart';
import '../../features/chat/data/chat_models.dart';
import '../../features/superadmin/presentation/screens/super_admin_dashboard_screen.dart';
import '../../features/superadmin/presentation/screens/account_management_screen.dart';
import '../../features/superadmin/presentation/screens/user_directory_screen.dart';
import '../../features/debug/presentation/screens/developer_debug_screen.dart';
import '../../features/notification/presentation/screens/notification_screen.dart';

// Shell Widget
import '../../shared/widgets/app_shell.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final homeNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'home');
final productsNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'products');
final cartNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'cart');
final aiNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'ai');
final profileNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'profile');

Widget _chatDetail(GoRouterState state, ChatChannel fallbackChannel) {
  final extra = state.extra;
  final arguments = extra is ChatDetailArguments ? extra : null;
  final legacyTitle = extra is String ? extra : null;
  return ChatDetailScreen(
    conversationId: state.pathParameters['id'] ?? '',
    title: arguments?.title ?? legacyTitle ?? 'Percakapan',
    channel: arguments?.channel ?? fallbackChannel,
  );
}

// Class to adapt Stream to Listenable for GoRouter refreshListenable
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  final splashFinished = ref.watch(splashFinishedProvider);
  final onboardingCompleted = ref.watch(onboardingCompletedProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: GoRouterRefreshStream(
      ref.watch(authProvider.notifier).stream,
    ),
    redirect: (context, state) {
      final status = authState.status;
      final user = authState.user;
      final currentLoc = state.uri.path;
      final isSplash = currentLoc == '/splash';
      final isOnboarding = currentLoc == '/onboarding';

      // 1. Do not redirect away from splash if initialization hasn't finished
      if (isSplash && !splashFinished) {
        return null;
      }

      // 2. Redirect to onboarding if not completed and splash is finished
      if (splashFinished && !onboardingCompleted) {
        if (!isOnboarding) {
          return '/onboarding';
        }
        return null;
      }

      // Izin sistem TIDAK punya gerbang di sini. Dialog sistemnya diminta
      // langsung saat beranda terbuka (`HomeScreen`), dan layar
      // `/permissions` hanya didorong bila ada yang ditolak — jadi yang
      // mengizinkan semuanya tidak pernah melihat satu layar pun.

      // Unauthenticated routes
      final isAuthRoute =
          currentLoc == '/login' ||
          currentLoc == '/register' ||
          currentLoc == '/forgot-password';

      final isSessionExpired = currentLoc == '/session-expired';

      // 2. Initial/Loading states: do not redirect while splash checks session
      if (status == AuthStatus.initial || status == AuthStatus.loading) {
        return null;
      }

      // 2. Redirect to Login if not authenticated
      if (status == AuthStatus.unauthenticated) {
        if (!isAuthRoute) {
          return '/login';
        }
        return null;
      }

      // 3. Redirect to Session Expired Screen
      if (status == AuthStatus.sessionExpired) {
        if (!isSessionExpired && currentLoc != '/login') {
          return '/session-expired';
        }
        return null;
      }

      // 4. Authenticated state redirections (Route guards & Landing page logic)
      if (status == AuthStatus.authenticated && user != null) {
        // If they are on Login/Register/Splash/Onboarding, direct them to their role landing dashboard
        if (isAuthRoute || isSplash || isSessionExpired || isOnboarding) {
          switch (user.role) {
            case 'SUPER_ADMIN':
              return '/super-admin';
            case 'ADMIN_KOPDES':
              return '/admin';
            // Pegawai punya beranda sendiri: dashboard admin memuat menu
            // keputusan koperasi yang memang tidak boleh ia jalankan.
            case 'PEGAWAI_KOPDES':
              return '/pegawai';
            case 'COURIER':
              return '/courier';
            case 'UMKM':
              return '/umkm';
            case 'CUSTOMER':
            default:
              return '/home';
          }
        }

        // Prevent non-customers from accessing customer landing path
        if (currentLoc == '/home' || currentLoc == '/') {
          switch (user.role) {
            case 'SUPER_ADMIN':
              return '/super-admin';
            case 'ADMIN_KOPDES':
              return '/admin';
            // Pegawai punya beranda sendiri: dashboard admin memuat menu
            // keputusan koperasi yang memang tidak boleh ia jalankan.
            case 'PEGAWAI_KOPDES':
              return '/pegawai';
            case 'COURIER':
              return '/courier';
            case 'UMKM':
              return '/umkm';
            case 'CUSTOMER':
            default:
              break;
          }
        }

        // Role guards: prevent roles from accessing pages of other roles
        if (currentLoc.startsWith('/super-admin')) {
          if (user.role != 'SUPER_ADMIN') {
            return '/home';
          }
        } else if (currentLoc.startsWith('/admin')) {
          // Dashboard admin bukan untuk pegawai — ia diarahkan ke berandanya
          // sendiri, bukan dibuang ke etalase pelanggan.
          if (user.role == 'PEGAWAI_KOPDES') {
            return '/pegawai';
          }
          if (user.role != 'ADMIN_KOPDES' && user.role != 'SUPER_ADMIN') {
            return '/home';
          }
        } else if (currentLoc.startsWith('/pegawai')) {
          if (user.role != 'PEGAWAI_KOPDES' &&
              user.role != 'ADMIN_KOPDES' &&
              user.role != 'SUPER_ADMIN') {
            return '/home';
          }
        }

        if (currentLoc.startsWith('/courier')) {
          if (user.role != 'COURIER') {
            return '/home';
          }
        }

        if (currentLoc.startsWith('/umkm')) {
          if (user.role != 'UMKM') {
            return '/home';
          }
        }
      }

      return null;
    },
    routes: [
      // 1. Top-level standalone routes
      GoRoute(
        path: '/splash',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/permissions',
        builder: (context, state) => const PermissionScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/koperasi',
        builder: (context, state) => const KoperasiListScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) => KoperasiDetailScreen(
              koperasiId: state.pathParameters['id'] ?? '',
            ),
          ),
        ],
      ),
      // Etalase Mitra UMKM untuk pembeli — `/mitra`, BUKAN `/umkm`.
      //
      // `/umkm` adalah portal penjual, dan penjaga peran di atas memulangkan
      // siapa pun yang bukan UMKM dari seluruh awalan itu. Selama halaman
      // publik ini tinggal di `/umkm/:id`, pembeli yang menekan "Kunjungi"
      // selalu terlempar balik ke beranda — tokonya seolah tidak pernah ada.
      GoRoute(
        path: '/mitra',
        builder: (context, state) => const MitraListScreen(),
        routes: [
          // Didaftarkan sebelum ':id' agar 'products' tidak tertangkap
          // sebagai id mitra.
          GoRoute(
            path: 'products/:id',
            builder: (context, state) => UmkmProductDetailScreen(
              productId: state.pathParameters['id'] ?? '',
            ),
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) =>
                MitraDetailScreen(mitraId: state.pathParameters['id'] ?? ''),
          ),
        ],
      ),
      GoRoute(
        path: '/info/:slug',
        builder: (context, state) =>
            ContentPageScreen(slug: state.pathParameters['slug'] ?? ''),
      ),
      GoRoute(
        path: '/membership/register',
        builder: (context, state) => const MembershipRegisterScreen(),
      ),
      GoRoute(
        path: '/admin/umkm-locations',
        builder: (context, state) => const UmkmLocationScreen(),
      ),
      GoRoute(
        path: '/notifications',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) =>
            _slideTransition(state, const NotificationScreen()),
      ),
      GoRoute(
        path: '/debug',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const DeveloperDebugScreen(),
      ),
      GoRoute(
        path: '/login',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/session-expired',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const SessionExpiredScreen(),
      ),
      GoRoute(
        path: '/tracking/:id',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return TrackingScreen(deliveryId: id);
        },
      ),
      GoRoute(
        path: '/admin',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AdminDashboardScreen(),
      ),

      // ── Pegawai Kopdes ──
      // Rute datar dengan navigasi bawahnya sendiri, terpisah dari shell
      // pelanggan: pegawai tidak boleh punya tab Marketplace atau Keranjang
      // di sela pekerjaannya.
      GoRoute(
        path: '/pegawai',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const KopdesEmployeeDashboardPage(),
      ),
      GoRoute(
        path: '/pegawai/pesanan',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => OrderManagementScreen(
          initialStatus: state.uri.queryParameters['status'],
        ),
      ),
      GoRoute(
        path: '/pegawai/pengiriman',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const CourierManagementScreen(),
      ),
      GoRoute(
        path: '/pegawai/kurir',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const CourierManagementScreen(),
      ),
      GoRoute(
        path: '/pegawai/lacak',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          // Tanpa deliveryId, layar pelacakan tidak punya yang bisa dilacak;
          // pegawai dikirim ke daftar pengantaran untuk memilih dulu.
          final id = state.uri.queryParameters['deliveryId'];
          return id == null || id.isEmpty
              ? const CourierManagementScreen()
              : TrackingScreen(deliveryId: id);
        },
      ),
      GoRoute(
        path: '/pegawai/stok',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => StockManagementScreen(
          initialFilter: state.uri.queryParameters['filter'] ?? 'all',
        ),
      ),
      GoRoute(
        path: '/pegawai/keuangan',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const FinanceReportScreen(),
      ),
      GoRoute(
        path: '/pegawai/ai',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AIAssistantScreen(),
      ),
      GoRoute(
        path: '/pegawai/profil',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AdminProfileScreen(),
      ),
      GoRoute(
        path: '/pegawai/barang/baru',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AdminProductFormScreen(),
      ),
      GoRoute(
        path: '/pegawai/barang/:id',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) =>
            AdminProductFormScreen(productId: state.pathParameters['id']),
      ),
      GoRoute(
        path: '/admin/products',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AdminProductListScreen(),
      ),
      GoRoute(
        path: '/admin/products/new',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AdminProductFormScreen(),
      ),
      GoRoute(
        path: '/admin/products/edit/:id',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return AdminProductFormScreen(productId: id);
        },
      ),
      GoRoute(
        path: '/admin/categories',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AdminCategoryListScreen(),
      ),
      GoRoute(
        path: '/admin/mitra',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const MitraManagementScreen(),
      ),
      GoRoute(
        path: '/admin/umkm-products',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const UmkmProductTakedownScreen(),
      ),
      GoRoute(
        path: '/admin/orders',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const OrderManagementScreen(),
      ),
      GoRoute(
        path: '/admin/couriers',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const CourierManagementScreen(),
      ),
      GoRoute(
        path: '/admin/chat',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) =>
            const ConversationListScreen(channel: ChatChannel.general),
      ),
      GoRoute(
        path: '/admin/profile',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AdminProfileScreen(),
      ),
      GoRoute(
        path: '/chat',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ChatHubScreen(),
        routes: [
          GoRoute(
            path: 'seller',
            builder: (context, state) =>
                const ConversationListScreen(channel: ChatChannel.marketplace),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) =>
                    _chatDetail(state, ChatChannel.marketplace),
              ),
            ],
          ),
          GoRoute(
            path: 'courier',
            builder: (context, state) =>
                const ConversationListScreen(channel: ChatChannel.delivery),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) =>
                    _chatDetail(state, ChatChannel.delivery),
              ),
            ],
          ),
          GoRoute(
            path: 'detail/:id',
            builder: (context, state) =>
                _chatDetail(state, ChatChannel.general),
          ),
        ],
      ),
      GoRoute(
        path: '/super-admin',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const SuperAdminDashboardScreen(),
      ),
      GoRoute(
        path: '/super-admin/accounts',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AccountManagementScreen(),
      ),
      GoRoute(
        path: '/super-admin/users',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const UserDirectoryScreen(),
      ),
      GoRoute(
        path: '/courier',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const CourierDashboardScreen(),
      ),
      GoRoute(
        path: '/umkm',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const SellerDashboardScreen(),
        routes: [
          GoRoute(
            path: 'products',
            builder: (context, state) => const ProductScreen(),
          ),
          GoRoute(
            path: 'products/new',
            builder: (context, state) => const ProductFormScreen(),
          ),
          GoRoute(
            path: 'products/edit/:id',
            builder: (context, state) {
              final id = state.pathParameters['id'] ?? '';
              return ProductFormScreen(productId: id);
            },
          ),
          GoRoute(
            path: 'products/detail/:id',
            builder: (context, state) {
              final id = state.pathParameters['id'] ?? '';
              return seller_view.ProductDetailScreen(productId: id);
            },
          ),
          GoRoute(
            path: 'orders',
            builder: (context, state) => const OrderScreen(),
          ),
          // Rute 'inventory' dihapus: kendali stok melebur ke halaman produk,
          // jadi tidak ada lagi halaman tersendiri untuk ditunjuk.
          GoRoute(path: 'inventory', redirect: (_, __) => '/umkm/products'),
          GoRoute(
            path: 'profile',
            builder: (context, state) => const StoreProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/checkout',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) =>
            _slideTransition(state, const CheckoutScreen()),
      ),
      GoRoute(
        path: '/order-success/:id',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return _slideTransition(state, OrderSuccessScreen(orderId: id));
        },
      ),
      GoRoute(
        path: '/orders/history',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) =>
            _slideTransition(state, const OrderHistoryScreen()),
      ),
      GoRoute(
        path: '/orders/:id',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return _slideTransition(state, OrderDetailScreen(orderId: id));
        },
      ),

      // 2. Nested shell route with bottom bar / nav rail
      StatefulShellRoute.indexedStack(
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          // Branch 1: Home
          StatefulShellBranch(
            navigatorKey: homeNavigatorKey,
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          // Branch 2: Products Catalog
          StatefulShellBranch(
            navigatorKey: productsNavigatorKey,
            routes: [
              GoRoute(
                path: '/products',
                builder: (context, state) {
                  // Beranda mengirim niatnya lewat query: menekan kolom
                  // pencarian di sana berarti langsung mengetik di sini, dan
                  // menekan Filter berarti lembar filternya terbuka.
                  final q = state.uri.queryParameters;
                  return MarketplaceScreen(
                    autofocusSearch: q['cari'] == '1',
                    openFilter: q['filter'] == '1',
                  );
                },
                routes: [
                  GoRoute(
                    path: 'detail/:id',
                    pageBuilder: (context, state) {
                      final id = state.pathParameters['id'] ?? '';
                      return _slideTransition(
                        state,
                        ProductDetailScreen(productId: id),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          // Branch 3: AI Assistant Chat
          StatefulShellBranch(
            navigatorKey: aiNavigatorKey,
            routes: [
              GoRoute(
                path: '/ai-assistant',
                builder: (context, state) => const AIAssistantScreen(),
              ),
            ],
          ),
          // Branch 4: Pesanan — keranjang, pesanan berjalan, dan riwayat.
          // Rutenya tetap '/cart' supaya tautan lama tidak putus.
          StatefulShellBranch(
            navigatorKey: cartNavigatorKey,
            routes: [
              GoRoute(
                path: '/cart',
                builder: (context, state) => const OrdersPage(),
              ),
            ],
          ),
          // Branch 5: Profile
          StatefulShellBranch(
            navigatorKey: profileNavigatorKey,
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

// ─────────────────────────────────────────────────────────
// Page Transition Helper
// iOS-style slide from right with a subtle fade
// ─────────────────────────────────────────────────────────
CustomTransitionPage<void> _slideTransition(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final offsetAnimation = Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

      final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: animation,
          curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
        ),
      );

      return SlideTransition(
        position: offsetAnimation,
        child: FadeTransition(opacity: fadeAnimation, child: child),
      );
    },
  );
}
