import 'package:flutter_bloc/flutter_bloc.dart';

/// Bottom-navigation tab: 0 Home, 1 Your Rides, 2 Messages, 3 Profile.
class CarpoolNavCubit extends Cubit<int> {
  CarpoolNavCubit([int initial = 0]) : super(initial);
  void select(int index) => emit(index);
}
