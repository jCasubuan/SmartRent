// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// class ClientHome extends StatelessWidget {
//   const ClientHome({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Icon(Icons.checkroom, size: 64, color: Color(0xFFC9A84C)),
//             const SizedBox(height: 16),
//             const Text(
//               'Client Home',
//               style: TextStyle(
//                 fontSize: 22,
//                 fontWeight: FontWeight.bold,
//                 color: Color(0xFF2C2C2C),
//               ),
//             ),
//             const SizedBox(height: 8),
//             const Text(
//               'Dashboard coming soon',
//               style: TextStyle(fontSize: 14, color: Color(0xFF999999)),
//             ),
//             const SizedBox(height: 40),
//             TextButton(
//               onPressed: () async {
//                 await FirebaseAuth.instance.signOut();
//                 if (context.mounted) {
//                   Navigator.of(context)
//                       .pushNamedAndRemoveUntil('/', (route) => false);
//                 }
//               },
//               child: const Text(
//                 'Sign Out',
//                 style: TextStyle(color: Color(0xFFC9A84C)),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:smart_rent/core/constants/app_colors.dart';
import 'client_tabs/home_tab.dart';
import 'client_tabs/dummy_tabs.dart';

class ClientHome extends StatefulWidget {
  const ClientHome({super.key});

  @override
  State<ClientHome> createState() => _ClientHomeState();
}

class _ClientHomeState extends State<ClientHome> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    HomeTab(),
    FavoritesTab(),
    CartTab(),
    NotificationsTab(),
    ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(child: _tabs[_currentIndex]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textLight,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.star_border),
            activeIcon: Icon(Icons.star),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            activeIcon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_outlined),
            activeIcon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

