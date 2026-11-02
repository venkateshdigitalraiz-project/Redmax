import 'package:flutter_bloc/flutter_bloc.dart';

/// Bottom tabs: 0 Home, 1 My Bookings, 2 Favorites, 3 Profile.
class PartyNavCubit extends Cubit<int> {
  PartyNavCubit() : super(0);
  void select(int index) => emit(index);
}
