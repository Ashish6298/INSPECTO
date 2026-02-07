import '../entities/collection.dart';
import '../entities/api_request.dart';

abstract class CollectionRepository {
  Future<List<Collection>> getCollections();
  Future<void> saveRequestToCollection(String collectionId, ApiRequest request);
  Future<void> createCollection(String name);
}
