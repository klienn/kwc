import 'package:flutter_bloc/flutter_bloc.dart';

class ProfileEvent {}

class UpdateProfileEvent extends ProfileEvent {
  final String name;
  final String username;
  final String imageUrl;

  UpdateProfileEvent(
      {required this.name, required this.username, required this.imageUrl});
}

class ProfileState {
  final String name;
  final String username;
  final String imageUrl;

  ProfileState(
      {required this.name, required this.username, required this.imageUrl});
}

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc()
      : super(ProfileState(
            name: 'John Doe',
            username: 'johndoe123',
            imageUrl: 'default_image_url'));

  @override
  Stream<ProfileState> mapEventToState(ProfileEvent event) async* {
    if (event is UpdateProfileEvent) {
      yield ProfileState(
        name: event.name,
        username: event.username,
        imageUrl: event.imageUrl,
      );
    }
  }
}
