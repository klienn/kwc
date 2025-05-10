import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kwc_app/bloc.navigation_bloc/navigation_bloc.dart';
import 'package:kwc_app/sidebar/menu_item.dart';
import 'package:provider/provider.dart';
import 'package:kwc_app/models/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SideBar extends StatefulWidget {
  @override
  State<SideBar> createState() => _SideBarState();
}

class _SideBarState extends State<SideBar> {
  bool isSidebarOpened = false;
  String? userRole;

  @override
  void initState() {
    super.initState();
    fetchUserRole();
  }

  Future<void> fetchUserRole() async {
    final user = Provider.of<Users?>(context, listen: false);
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        setState(() {
          userRole = doc.data()?['role'] ?? 'user';
        });

        if (userRole == 'admin') {
          BlocProvider.of<NavigationBloc>(context)
              .add(NavigationEvents.adminDashboardClickedEvent);
        }
      }
    }
  }

  void toggleSidebar() {
    setState(() {
      isSidebarOpened = !isSidebarOpened;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final sidebarWidth = screenWidth * 0.85;

    return Stack(
      children: [
        // Sidebar Panel
        Positioned(
          top: 0,
          bottom: 0,
          left: isSidebarOpened ? 0 : -sidebarWidth,
          width: sidebarWidth,
          child: Container(
            height: screenHeight,
            color: const Color(0xffF98866),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  const SizedBox(height: 60),
                  ListTile(
                    title: const Text(
                      "Pol123",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text(
                      "Cipolletti Ceniza Jipos",
                      style: TextStyle(
                          color: Color(0xffF54914),
                          fontSize: 20,
                          fontWeight: FontWeight.w800),
                    ),
                    leading: const CircleAvatar(
                      radius: 50,
                      child: Icon(
                        Icons.perm_identity,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Divider(
                    height: 32,
                    thickness: 0.5,
                    color: Colors.white.withOpacity(0.3),
                    indent: 32,
                    endIndent: 32,
                  ),
                  userRole == 'admin'
                      ? MenuItem(
                          icon: Icons.dashboard,
                          title: "Admin Dashboard",
                          onTap: () {
                            toggleSidebar();
                            BlocProvider.of<NavigationBloc>(context).add(
                                NavigationEvents.adminDashboardClickedEvent);
                          },
                        )
                      : MenuItem(
                          icon: Icons.home,
                          title: "Home",
                          onTap: () {
                            toggleSidebar();
                            BlocProvider.of<NavigationBloc>(context)
                                .add(NavigationEvents.homePageClickedEvent);
                          },
                        ),
                  MenuItem(
                      icon: Icons.payment,
                      title: "Payment",
                      onTap: () {
                        toggleSidebar();
                        BlocProvider.of<NavigationBloc>(context)
                            .add(NavigationEvents.paymentClickedEvent);
                      }),
                  MenuItem(
                      icon: Icons.notifications,
                      title: "Notification",
                      onTap: () {
                        toggleSidebar();
                        BlocProvider.of<NavigationBloc>(context)
                            .add(NavigationEvents.notificationClickedEvent);
                      }),
                  Divider(
                    height: 64,
                    thickness: 0.5,
                    color: Colors.white.withOpacity(0.3),
                    indent: 32,
                    endIndent: 32,
                  ),
                  MenuItem(
                      icon: Icons.settings,
                      title: "Settings",
                      onTap: () {
                        toggleSidebar();
                        BlocProvider.of<NavigationBloc>(context)
                            .add(NavigationEvents.settingsClickedEvent);
                      }),
                  MenuItem(
                      icon: Icons.logout,
                      title: "Logout",
                      onTap: () {
                        toggleSidebar();
                        BlocProvider.of<NavigationBloc>(context)
                            .add(NavigationEvents.logoutClickedEvent);
                      }),
                ],
              ),
            ),
          ),
        ),

        // Gesture to close when clicking outside
        if (isSidebarOpened)
          Positioned(
            left: sidebarWidth,
            right: 0,
            top: 0,
            bottom: 0,
            child: GestureDetector(
              onTap: toggleSidebar,
              child: Container(color: Colors.transparent),
            ),
          ),

        // Sidebar Toggle Button (always visible, outside the panel)
        Positioned(
          top: 40,
          left: isSidebarOpened ? sidebarWidth : 0,
          child: GestureDetector(
            onTap: toggleSidebar,
            child: ClipPath(
              clipper: CustomMenuClipper(),
              child: Container(
                width: 35,
                height: 100,
                color: const Color(0xffF98866),
                alignment: Alignment.centerLeft,
                child: Icon(
                  isSidebarOpened ? Icons.close : Icons.menu,
                  color: const Color(0xffF54914),
                  size: 25,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class CustomMenuClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.moveTo(0, 0);
    path.quadraticBezierTo(0, 8, 10, 16);
    path.quadraticBezierTo(
        size.width - 1, size.height / 2 - 20, size.width, size.height / 2);
    path.quadraticBezierTo(
        size.width + 1, size.height / 2 + 20, 10, size.height - 16);
    path.quadraticBezierTo(0, size.height - 8, 0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return true;
  }
}
