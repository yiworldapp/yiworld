import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/splash/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/otp_verify_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/shell/shell_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/event_detail/screens/event_detail_screen.dart';
import '../../features/members/screens/members_screen.dart';
import '../../features/members/screens/member_detail_screen.dart';
import '../../features/birthdays/screens/birthdays_screen.dart';
import '../../features/privileges/screens/privileges_screen.dart';
import '../../features/chat/screens/chat_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/edit_profile_screen.dart';
import '../../features/profile/screens/change_phone_screen.dart';
import '../../features/profile/screens/change_email_screen.dart';
import '../../features/menu/screens/menu_screen.dart';
import '../../features/menu/screens/mous_screen.dart';

part 'app_router.g.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    redirect: (context, state) async {
      final supabase = Supabase.instance.client;
      final session = supabase.auth.currentSession;
      final isLoggedIn = session != null;
      final isSplash = state.matchedLocation == '/splash';
      final isAuthRoute = state.matchedLocation.startsWith('/login') ||
                          state.matchedLocation.startsWith('/otp');

      if (isSplash) return null; // always allow splash

      if (!isLoggedIn && !isAuthRoute) return '/login';

      if (isLoggedIn) {
        final isOnboarding = state.matchedLocation == '/onboarding';
        // Check onboarding status for all logged-in users except those already on /onboarding
        if (!isOnboarding) {
          final profile = await supabase
              .from('profiles')
              .select('onboarding_done')
              .eq('id', session!.user.id)
              .maybeSingle()
              .catchError((_) => null);
          final done = profile?['onboarding_done'] == true;
          if (!done) return '/onboarding';
        }
        // Logged-in + onboarding done + on auth route → go to events
        if (isAuthRoute) return '/events';
      }
      return null;
    },
    routes: [
      // Splash
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (ctx, state) => const SplashScreen(),
      ),

      // Auth routes
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (ctx, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/otp',
        name: 'otp',
        builder: (ctx, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return OtpVerifyScreen(
            email: extra['email'] as String? ?? '',
            isSignUp: extra['isSignUp'] as bool? ?? false,
          );
        },
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (ctx, state) => const OnboardingScreen(),
      ),

      // Shell (bottom nav)
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (ctx, state, child) => ShellScreen(child: child),
        routes: [
          GoRoute(
            path: '/events',
            name: 'events',
            builder: (ctx, state) => const HomeScreen(),
            routes: [
              GoRoute(
                path: ':id',
                name: 'event-detail',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (ctx, state) => EventDetailScreen(eventId: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: '/members',
            name: 'members',
            builder: (ctx, state) => const MembersScreen(),
            routes: [
              GoRoute(
                path: ':id',
                name: 'member-detail',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (ctx, state) => MemberDetailScreen(memberId: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: '/birthdays',
            name: 'birthdays',
            builder: (ctx, state) => const BirthdaysScreen(),
          ),
          GoRoute(
            path: '/privileges',
            name: 'privileges',
            builder: (ctx, state) => const PrivilegesScreen(),
          ),
          GoRoute(
            path: '/chat',
            name: 'chat',
            builder: (ctx, state) => const ChatScreen(),
          ),
        ],
      ),

      // Menu (outside shell - full screen)
      GoRoute(
        path: '/menu',
        name: 'menu',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (ctx, state) => const MenuScreen(),
        routes: [
          GoRoute(
            path: 'mous',
            name: 'mous',
            builder: (ctx, state) => const MOUsScreen(),
          ),
        ],
      ),

      // Profile (outside shell - full screen)
      GoRoute(
        path: '/profile',
        name: 'profile',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (ctx, state) => const ProfileScreen(),
        routes: [
          GoRoute(
            path: 'edit',
            name: 'edit-profile',
            builder: (ctx, state) => const EditProfileScreen(),
            routes: [
              GoRoute(
                path: 'change-phone',
                name: 'change-phone',
                builder: (ctx, state) => const ChangePhoneScreen(),
              ),
              GoRoute(
                path: 'change-email',
                name: 'change-email',
                builder: (ctx, state) => const ChangeEmailScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
