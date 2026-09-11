import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/injection_container.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/history/presentation/bloc/history_bloc.dart';
import 'features/products/presentation/bloc/product_bloc.dart';
import 'features/scan/presentation/bloc/scan_bloc.dart';

class ScanrixApp extends StatelessWidget {
  const ScanrixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(create: (_) => sl<AuthBloc>()),
        BlocProvider<ProductBloc>(create: (_) => sl<ProductBloc>()),
        BlocProvider<ScanBloc>(create: (_) => sl<ScanBloc>()),
        BlocProvider<HistoryBloc>(create: (_) => sl<HistoryBloc>()),
      ],
      child: MaterialApp(
        title: 'Scanrix',
        theme: AppTheme.dark,
        home: const LoginPage(),
      ),
    );
  }
}
