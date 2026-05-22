// lib/providers/filter_state.dart
import 'package:flutter/material.dart';

class FilterState extends ChangeNotifier {
  bool isLostSelected = true;
  String searchQuery = '';
  late TextEditingController searchController;

  FilterState() {
    searchController = TextEditingController();
  }

  void setLostSelected(bool value) {
    if (isLostSelected != value) {
      isLostSelected = value;
      notifyListeners();
    }
  }

  void setSearchQuery(String value) {
    searchQuery = value;
    notifyListeners();
  }

  void clearSearch() {
    searchQuery = '';
    searchController.clear();
    notifyListeners();
  }

  void reset() {
    isLostSelected = true;
    searchQuery = '';
    searchController.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}