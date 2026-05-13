// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';

// import '../../core/constants/app_colors.dart';
// import 'home/home_screen.dart';


// class MainShell extends StatelessWidget {
//   const MainShell({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.scaffoldBg,
//       body: SafeArea(
//         bottom: false,
//         child: BlocBuilder<NavigationBloc, NavigationState>(
//           builder: (context, state) {
//             return IndexedStack(
//               index: state.currentIndex,
//               children: const [
//                 HomeScreen(),
//                 NotificationsScreen(),
//                 ProfileScreen(),
//               ],
//             );
//           },
//         ),
//       ),
      
//     );
//   }
// }
