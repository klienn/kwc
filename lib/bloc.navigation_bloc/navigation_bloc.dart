import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kwc_app/screens/home/admin_home.dart';
import 'package:kwc_app/screens/home/home.dart';
import 'package:kwc_app/screens/logout/logout.dart';
import 'package:kwc_app/screens/notification/notification.dart';
import 'package:kwc_app/screens/payment/payment.dart';
import 'package:kwc_app/screens/profile/profile.dart';
import 'package:kwc_app/screens/settings/settings.dart';

enum NavigationEvents {
  profilePageClickedEvent,
  homePageClickedEvent,
  paymentClickedEvent,
  notificationClickedEvent,
  settingsClickedEvent,
  logoutClickedEvent,
  adminDashboardClickedEvent,
}

abstract class NavigationStates {}

class NavigationBloc extends Bloc<NavigationEvents, NavigationStates> {
  NavigationBloc() : super(Home()) {
    // Set initial state to Home() widget directly
    // Registering the event handlers
    on<NavigationEvents>((event, emit) {
      switch (event) {
        case NavigationEvents.adminDashboardClickedEvent:
          emit(AdminHome()); // Emit the Logout widget directly
          break;
        case NavigationEvents.profilePageClickedEvent:
          emit(Profile()); // Emit the Profile widget directly
          break;
        case NavigationEvents.homePageClickedEvent:
          emit(Home()); // Emit the Home widget directly
          break;
        case NavigationEvents.paymentClickedEvent:
          emit(Payment()); // Emit the Payment widget directly
          break;
        case NavigationEvents.notificationClickedEvent:
          emit(Notifications()); // Emit the Notification widget directly
          break;
        case NavigationEvents.settingsClickedEvent:
          emit(Settings()); // Emit the Settings widget directly
          break;
        case NavigationEvents.logoutClickedEvent:
          emit(Logout()); // Emit the Logout widget directly
          break;
      }
    });
  }
}
