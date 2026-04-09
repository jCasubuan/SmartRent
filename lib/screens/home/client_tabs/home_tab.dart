// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:smart_rent/core/constants/app_colors.dart';
// import 'package:smart_rent/core/models/gown_model.dart';
// import 'package:smart_rent/core/models/category_model.dart';
// import 'package:smart_rent/screens/auth/landing_page.dart';

// class HomeTab extends StatefulWidget {
//   const HomeTab({super.key});

//   @override
//   State<HomeTab> createState() => _HomeTabState();
// }

// class _HomeTabState extends State<HomeTab> {
//   String? _userName;
//   String _selectedFilter = 'All';

//   final List<String> _filters = ['All', 'Popular', 'Best Offers', 'Premium Gowns'];

//   final List<CategoryModel> _categories = const [
//     CategoryModel(id: 'wedding', name: 'Wedding Gowns', order: 1),
//     CategoryModel(id: 'ball', name: 'Ball Gowns', order: 2),
//     CategoryModel(id: 'evening', name: 'Evening Gowns', order: 3),
//   ];

//   final List<GownModel> _gowns = const [
//     GownModel(id: '1', name: 'Gown 1', price: 10.99, categoryId: 'wedding'),
//     GownModel(id: '2', name: 'Gown 2', price: 10.99, categoryId: 'wedding'),
//     GownModel(id: '3', name: 'Gown 3', price: 10.99, categoryId: 'wedding'),
//     GownModel(id: '4', name: 'Gown 4', price: 10.99, categoryId: 'ball'),
//     GownModel(id: '5', name: 'Gown 5', price: 10.99, categoryId: 'ball'),
//     GownModel(id: '6', name: 'Gown 6', price: 10.99, categoryId: 'ball'),
//     GownModel(id: '7', name: 'Gown 7', price: 10.99, categoryId: 'evening'),
//     GownModel(id: '8', name: 'Gown 8', price: 10.99, categoryId: 'evening'),
//     GownModel(id: '9', name: 'Gown 9', price: 10.99, categoryId: 'evening'),
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _loadUserName();
//   }

//   Future<void> _loadUserName() async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) return;
//     try {
//       final doc = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(user.uid)
//           .get();
//       if (mounted) {
//         setState(() {
//           _userName = doc.data()?['name']?.toString().split(' ').first;
//         });
//       }
//     } catch (_) {}
//   }

//   Future<void> _onRefresh() async {
//     await _loadUserName();
//     setState(() {});
//   }

//   List<GownModel> _getGownsForCategory(String categoryId) {
//     return _gowns.where((g) => g.categoryId == categoryId).toList();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return RefreshIndicator(
//       onRefresh: _onRefresh,
//       color: AppColors.primary,
//       child: CustomScrollView(
//         slivers: [
//           // Search bar + Login/Greeting
//           SliverToBoxAdapter(
//             child: Padding(
//               padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: Container(
//                       height: 44,
//                       decoration: BoxDecoration(
//                         color: const Color(0xFFF5F5F5),
//                         borderRadius: BorderRadius.circular(22),
//                       ),
//                       child: const TextField(
//                         decoration: InputDecoration(
//                           hintText: 'Search',
//                           hintStyle: TextStyle(color: AppColors.textLight, fontSize: 14),
//                           prefixIcon: Icon(Icons.search, color: AppColors.textLight, size: 20),
//                           border: InputBorder.none,
//                           contentPadding: EdgeInsets.symmetric(vertical: 12),
//                         ),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   FirebaseAuth.instance.currentUser == null
//                       ? ElevatedButton(
//                           onPressed: () => Navigator.push(
//                             context,
//                             MaterialPageRoute(builder: (_) => const LandingPage()),
//                           ),
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: AppColors.primary,
//                             foregroundColor: Colors.white,
//                             elevation: 0,
//                             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(22),
//                             ),
//                           ),
//                           child: const Text('Login',
//                               style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
//                         )
//                       : Text(
//                           'Hi, ${_userName ?? ''}!',
//                           style: const TextStyle(
//                               fontSize: 14,
//                               fontWeight: FontWeight.w600,
//                               color: AppColors.primary),
//                         ),
//                 ],
//               ),
//             ),
//           ),

//           // Filter chips
//           SliverToBoxAdapter(
//             child: SizedBox(
//               height: 40,
//               child: ListView.separated(
//                 scrollDirection: Axis.horizontal,
//                 padding: const EdgeInsets.symmetric(horizontal: 16),
//                 itemCount: _filters.length,
//                 separatorBuilder: (_, __) => const SizedBox(width: 8),
//                 itemBuilder: (context, index) {
//                   final filter = _filters[index];
//                   final isSelected = _selectedFilter == filter;
//                   return GestureDetector(
//                     onTap: () => setState(() => _selectedFilter = filter),
//                     child: Container(
//                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                       decoration: BoxDecoration(
//                         color: isSelected ? AppColors.primary : Colors.transparent,
//                         borderRadius: BorderRadius.circular(20),
//                         border: Border.all(
//                           color: isSelected ? AppColors.primary : const Color(0xFFDDDDDD),
//                         ),
//                       ),
//                       child: Text(
//                         filter,
//                         style: TextStyle(
//                           fontSize: 13,
//                           fontWeight: FontWeight.w500,
//                           color: isSelected ? Colors.white : AppColors.textDark,
//                         ),
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ),

//           const SliverToBoxAdapter(child: SizedBox(height: 16)),

//           // Category sections
//           SliverList(
//             delegate: SliverChildBuilderDelegate(
//               (context, index) {
//                 final category = _categories[index];
//                 final gowns = _getGownsForCategory(category.id);
//                 return Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Padding(
//                       padding: const EdgeInsets.symmetric(horizontal: 16),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           Text(
//                             category.name,
//                             style: const TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.w700,
//                               color: AppColors.primary,
//                             ),
//                           ),
//                           const Icon(Icons.chevron_right, color: AppColors.primary, size: 20),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                     SizedBox(
//                       height: 200,
//                       child: ListView.separated(
//                         scrollDirection: Axis.horizontal,
//                         padding: const EdgeInsets.symmetric(horizontal: 16),
//                         itemCount: gowns.length,
//                         separatorBuilder: (_, __) => const SizedBox(width: 12),
//                         itemBuilder: (context, i) => _GownCard(gown: gowns[i]),
//                       ),
//                     ),
//                     const SizedBox(height: 20),
//                   ],
//                 );
//               },
//               childCount: _categories.length,
//             ),
//           ),

//           const SliverToBoxAdapter(child: SizedBox(height: 16)),
//         ],
//       ),
//     );
//   }
// }

// class _GownCard extends StatefulWidget {
//   final GownModel gown;
//   const _GownCard({required this.gown});

//   @override
//   State<_GownCard> createState() => _GownCardState();
// }

// class _GownCardState extends State<_GownCard> {
//   bool _isFavorite = false;

//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       width: 130,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Stack(
//             children: [
//               Container(
//                 width: 130,
//                 height: 140,
//                 decoration: BoxDecoration(
//                   color: const Color(0xFFEEEEEE),
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 child: widget.gown.imageUrl.isNotEmpty
//                     ? ClipRRect(
//                         borderRadius: BorderRadius.circular(10),
//                         child: Image.network(widget.gown.imageUrl, fit: BoxFit.cover),
//                       )
//                     : null,
//               ),
//               Positioned(
//                 top: 6,
//                 left: 6,
//                 child: GestureDetector(
//                   onTap: () => setState(() => _isFavorite = !_isFavorite),
//                   child: Icon(
//                     _isFavorite ? Icons.star : Icons.star_border,
//                     color: AppColors.primary,
//                     size: 22,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 6),
//           Text(
//             widget.gown.name,
//             style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textDark),
//             maxLines: 1,
//             overflow: TextOverflow.ellipsis,
//           ),
//           const SizedBox(height: 2),
//           Text(
//             '\$${widget.gown.price.toStringAsFixed(2)}',
//             style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textDark),
//           ),
//         ],
//       ),
//     );
//   }
// }