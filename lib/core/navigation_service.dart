import 'app_router.dart';

/// Global GoRouter instance.
///
/// Use this to navigate without a BuildContext — e.g. from voice commands,
/// background services, or any code outside the widget tree.
///
/// Usage:
///   appRouter.go('/home');
///   appRouter.push('/profile');
final appRouter = createAppRouter();
