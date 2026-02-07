import 'package:flutter/material.dart';
import '../../domain/entities/collection.dart';
import '../../domain/entities/api_request.dart';
import '../../domain/repositories/collection_repository.dart';

class CollectionProvider with ChangeNotifier {
  final CollectionRepository repository;

  CollectionProvider({required this.repository});

  List<Collection> _collections = [];
  bool _isLoading = false;

  List<Collection> get collections => _collections;
  bool get isLoading => _isLoading;

  Future<void> loadCollections() async {
    _isLoading = true;
    notifyListeners();
    _collections = await repository.getCollections();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> saveToCollection(String collectionId, ApiRequest request) async {
    await repository.saveRequestToCollection(collectionId, request);
    await loadCollections();
  }

  Future<void> createCollection(String name) async {
    await repository.createCollection(name);
    await loadCollections();
  }
}
