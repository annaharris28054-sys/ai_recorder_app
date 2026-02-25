import 'package:flutter/foundation.dart';

import '../data/models/user.dart';

class AppState extends ChangeNotifier {
  User? _currentUser;

  User? get currentUser => _currentUser;

  void setCurrentUser(User? user) {
    _currentUser = user;
    notifyListeners();
  }
}

