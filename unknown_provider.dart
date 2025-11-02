import 'package:flutter/material.dart';
import '../models/unknown_face.dart';
import '../services/unknown_service.dart';

class UnknownProvider with ChangeNotifier {
  final UnknownService _service = UnknownService();

  List<UnknownFace> _unknownFaces = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<UnknownFace> get unknownFaces => _unknownFaces;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Charger les visages inconnus
  Future<void> loadUnknownFaces() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _unknownFaces = await _service.fetchUnknownFaces();
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  // Marquer comme traité
  Future<bool> markAsProcessed(int id, String notes) async {
    try {
      await _service.markAsProcessed(id, notes);
      await loadUnknownFaces(); // Recharger la liste
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Rafraîchir
  Future<void> refresh() async {
    await loadUnknownFaces();
  }
}