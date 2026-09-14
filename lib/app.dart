import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'core/di/injection_container.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/history/presentation/bloc/history_bloc.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/products/presentation/bloc/product_bloc.dart';
import 'features/scan/presentation/bloc/scan_bloc.dart';

/// Reference design size every `.w`/`.h`/`.sp`/`.r` scales against — see
/// "Sizing / responsive units" in CLAUDE.md.
const _designSize = Size(375, 812);

class ScanrixApp extends StatelessWidget {
  final bool isAuthenticated;

  const ScanrixApp({super.key, required this.isAuthenticated});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(create: (_) => sl<AuthBloc>()),
        BlocProvider<ProductBloc>(create: (_) => sl<ProductBloc>()),
        BlocProvider<ScanBloc>(create: (_) => sl<ScanBloc>()),
        BlocProvider<HistoryBloc>(create: (_) => sl<HistoryBloc>()),
      ],
      child: ScreenUtilInit(
        designSize: _designSize,
        minTextAdapt: true,
        builder: (context, child) => MaterialApp(
          title: 'Scanrix',
          theme: AppTheme.dark,
          home: isAuthenticated ? const HomePage() : const LoginPage(),
        ),
      ),
    );
  }
}
