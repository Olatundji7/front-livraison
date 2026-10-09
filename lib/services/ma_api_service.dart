import 'dart:typed_data';
import 'api_client.dart';
import '../models/order_model.dart';

class MaApiService {
  final ApiClient api;
  MaApiService(this.api);

  Future<List<Map<String, dynamic>>> availableDrivers() async {
    final data =
        await api.request('GET', '/drivers/available', authenticated: true);
    return ((data['drivers'] as List?) ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<List<OrderModel>> adminOrders({String? status}) async {
    final data = await api.request(
      'GET',
      '/admin/orders',
      authenticated: true,
      query: status == null || status.isEmpty ? null : {'status': status},
    );
    final list = (data['data'] as List?) ?? [];
    return list
        .map((e) => OrderModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<Map<String, dynamic>> adminDashboard() async {
    final data =
        await api.request('GET', '/admin/dashboard', authenticated: true);
    return Map<String, dynamic>.from(data['stats'] as Map);
  }

  Future<List<Map<String, dynamic>>> adminDrivers() async {
    final data =
        await api.request('GET', '/admin/drivers', authenticated: true);
    return ((data['drivers'] as List?) ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<Map<String, dynamic>> createDriver({
    required String name,
    required String phone,
    required String password,
    String? email,
    String? vehicle,
    String? plate,
    Uint8List? imageBytes,
    String? imageName,
  }) async {
    final data = await api.multipart(
      'POST',
      '/admin/drivers',
      authenticated: true,
      fields: {
        'name': name,
        'phone': phone,
        'password': password,
        if (email != null && email.isNotEmpty) 'email': email,
        if (vehicle != null && vehicle.isNotEmpty) 'vehicule_type': vehicle,
        if (plate != null && plate.isNotEmpty) 'immatriculation': plate,
      },
      fileBytes: imageBytes,
      fileName: imageName,
      fileField: 'photo',
    );
    return Map<String, dynamic>.from(data['driver'] as Map);
  }

  Future<Map<String, dynamic>> updateDriver({
    required int id,
    String? name,
    String? phone,
    String? email,
    String? status,
    String? vehicle,
    String? plate,
    Uint8List? imageBytes,
    String? imageName,
  }) async {
    final data = await api.multipart(
      'POST',
      '/admin/drivers/$id',
      authenticated: true,
      fields: {
        '_method': 'PUT',
        if (name != null && name.isNotEmpty) 'name': name,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (email != null) 'email': email,
        if (status != null) 'status': status,
        if (vehicle != null && vehicle.isNotEmpty) 'vehicule_type': vehicle,
        if (plate != null) 'immatriculation': plate,
      },
      fileBytes: imageBytes,
      fileName: imageName,
      fileField: 'photo',
    );
    return Map<String, dynamic>.from(data['driver'] as Map);
  }

  Future<void> assignAdminOrder(int orderId, int driverId) async {
    await api.request(
      'POST',
      '/admin/orders/$orderId/assign',
      authenticated: true,
      body: {'driver_id': driverId},
    );
  }

  Future<Map<String, dynamic>> driverLocations(int driverId,
      {int limit = 300}) async {
    return Map<String, dynamic>.from(
      await api.request(
        'GET',
        '/admin/drivers/$driverId/locations',
        authenticated: true,
        query: {'limit': '$limit'},
      ),
    );
  }

  Future<List<Map<String, dynamic>>> adminProducts() async {
    final data =
        await api.request('GET', '/admin/products', authenticated: true);
    return ((data['products'] as List?) ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<Map<String, dynamic>> createProduct({
    required String name,
    required String category,
    required int price,
    required int stock,
    String? description,
    Uint8List? imageBytes,
    String? imageName,
    bool active = true,
  }) async {
    final data = await api.multipart(
      'POST',
      '/admin/products',
      authenticated: true,
      fields: {
        'name': name,
        'category': category,
        'price': '$price',
        'stock': '$stock',
        'description': description ?? '',
        'is_active': active ? '1' : '0',
      },
      fileBytes: imageBytes,
      fileName: imageName,
      fileField: 'image',
    );
    return Map<String, dynamic>.from(data['product'] as Map);
  }

  Future<Map<String, dynamic>> updateProduct({
    required int id,
    required String name,
    required String category,
    required int price,
    required int stock,
    String? description,
    bool active = true,
    Uint8List? imageBytes,
    String? imageName,
  }) async {
    final data = await api.multipart(
      'POST',
      '/admin/products/$id',
      authenticated: true,
      fields: {
        '_method': 'PUT',
        'name': name,
        'category': category,
        'price': '$price',
        'stock': '$stock',
        'description': description ?? '',
        'is_active': active ? '1' : '0',
      },
      fileBytes: imageBytes,
      fileName: imageName,
      fileField: 'image',
    );
    return Map<String, dynamic>.from(data['product'] as Map);
  }

  Future<void> deleteProduct(int id) async {
    await api.request('DELETE', '/admin/products/$id', authenticated: true);
  }

  Future<List<Map<String, dynamic>>> advertisements(
      {bool admin = false}) async {
    final data = await api.request(
      'GET',
      admin ? '/admin/advertisements' : '/advertisements',
      authenticated: admin,
    );
    return ((data['advertisements'] as List?) ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<Map<String, dynamic>> createAdvertisement({
    required String title,
    String? description,
    bool active = true,
    Uint8List? imageBytes,
    String? imageName,
    String? startsAt,
    String? endsAt,
  }) async {
    final data = await api.multipart(
      'POST',
      '/admin/advertisements',
      authenticated: true,
      fields: {
        'title': title,
        'description': description ?? '',
        'is_active': active ? '1' : '0',
        if (startsAt != null && startsAt.isNotEmpty) 'starts_at': startsAt,
        if (endsAt != null && endsAt.isNotEmpty) 'ends_at': endsAt,
      },
      fileBytes: imageBytes,
      fileName: imageName,
      fileField: 'image',
    );
    return Map<String, dynamic>.from(data['advertisement'] as Map);
  }

  Future<Map<String, dynamic>> updateAdvertisement({
    required int id,
    required String title,
    String? description,
    bool active = true,
    Uint8List? imageBytes,
    String? imageName,
    String? startsAt,
    String? endsAt,
  }) async {
    final data = await api.multipart(
      'POST',
      '/admin/advertisements/$id',
      authenticated: true,
      fields: {
        '_method': 'PUT',
        'title': title,
        'description': description ?? '',
        'is_active': active ? '1' : '0',
        if (startsAt != null && startsAt.isNotEmpty) 'starts_at': startsAt,
        if (endsAt != null && endsAt.isNotEmpty) 'ends_at': endsAt,
      },
      fileBytes: imageBytes,
      fileName: imageName,
      fileField: 'image',
    );
    return Map<String, dynamic>.from(data['advertisement'] as Map);
  }

  Future<void> deleteAdvertisement(int id) async {
    await api.request(
      'DELETE',
      '/admin/advertisements/$id',
      authenticated: true,
    );
  }

  Future<Map<String, dynamic>> cart() async {
    return Map<String, dynamic>.from(
      await api.request('GET', '/cart', authenticated: true),
    );
  }

  Future<Map<String, dynamic>> addCartItem(int productId, {int quantity = 1}) async {
    return Map<String, dynamic>.from(await api.request(
      'POST',
      '/cart/items',
      authenticated: true,
      body: {'product_id': productId, 'quantity': quantity},
    ));
  }

  Future<Map<String, dynamic>> updateCartItem(int itemId, int quantity) async {
    return Map<String, dynamic>.from(await api.request(
      'PATCH',
      '/cart/items/$itemId',
      authenticated: true,
      body: {'quantity': quantity},
    ));
  }

  Future<Map<String, dynamic>> removeCartItem(int itemId) async {
    return Map<String, dynamic>.from(await api.request(
      'DELETE',
      '/cart/items/$itemId',
      authenticated: true,
    ));
  }

  Future<Map<String, dynamic>> clearCart() async {
    return Map<String, dynamic>.from(await api.request(
      'DELETE',
      '/cart',
      authenticated: true,
    ));
  }

  Future<OrderModel> checkoutCart({
    required String pickupAddress,
    required double pickupLat,
    required double pickupLng,
    required String destinationAddress,
    required double destinationLat,
    required double destinationLng,
    String? note,
  }) async {
    final data = await api.request(
      'POST',
      '/cart/checkout',
      authenticated: true,
      body: {
        'pickup_address': pickupAddress,
        'pickup_latitude': pickupLat,
        'pickup_longitude': pickupLng,
        'destination_address': destinationAddress,
        'destination_latitude': destinationLat,
        'destination_longitude': destinationLng,
        'note': note,
      },
    );
    return OrderModel.fromJson(Map<String, dynamic>.from(data['order'] as Map));
  }

  Future<OrderModel> createOrder({
    required String type,
    required String pickupAddress,
    required double pickupLat,
    required double pickupLng,
    String? destinationAddress,
    double? destinationLat,
    double? destinationLng,
    String? note,
  }) async {
    final body = <String, dynamic>{
      'type': type,
      'pickup_address': pickupAddress,
      'pickup_latitude': pickupLat,
      'pickup_longitude': pickupLng,
      'note': note,
    };
    if (type == 'livraison') {
      body.addAll({
        'destination_address': destinationAddress,
        'destination_latitude': destinationLat,
        'destination_longitude': destinationLng,
      });
    }
    final data = await api.request(
      'POST',
      '/orders',
      authenticated: true,
      body: body,
    );
    return OrderModel.fromJson(Map<String, dynamic>.from(data['order'] as Map));
  }

  Future<OrderModel?> activeOrder() async {
    final data =
        await api.request('GET', '/orders/active', authenticated: true);
    return data['order'] == null
        ? null
        : OrderModel.fromJson(
            Map<String, dynamic>.from(data['order'] as Map),
          );
  }

  Future<List<OrderModel>> clientOrders() async {
    final data = await api.request('GET', '/orders', authenticated: true);
    final list = (data['data'] as List?) ?? [];
    return list
        .map((e) => OrderModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<OrderModel> getOrder(int id) async {
    final data =
        await api.request('GET', '/orders/$id', authenticated: true);
    return OrderModel.fromJson(Map<String, dynamic>.from(data['order'] as Map));
  }

  Future<Map<String, dynamic>> tracking(int id) async {
    return Map<String, dynamic>.from(
      await api.request(
        'GET',
        '/orders/$id/tracking',
        authenticated: true,
      ),
    );
  }

  Future<OrderModel> cancelOrder(int id) async {
    final data = await api.request(
      'POST',
      '/orders/$id/cancel',
      authenticated: true,
    );
    return OrderModel.fromJson(Map<String, dynamic>.from(data['order'] as Map));
  }

  Future<List<OrderModel>> driverAvailableOrders() async {
    final data = await api.request(
      'GET',
      '/driver/orders/available',
      authenticated: true,
    );
    final list = (data['orders'] as List?) ?? [];
    return list
        .map((e) => OrderModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<OrderModel>> driverOrders() async {
    final data =
        await api.request('GET', '/driver/orders', authenticated: true);
    final list = (data['data'] as List?) ?? [];
    return list
        .map((e) => OrderModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<OrderModel> driverAction(int id, String action) async {
    final data = await api.request(
      'POST',
      '/driver/orders/$id/$action',
      authenticated: true,
    );
    return OrderModel.fromJson(Map<String, dynamic>.from(data['order'] as Map));
  }

  Future<Map<String, dynamic>> driverStatus(String status) async {
    final data = await api.request(
      'PATCH',
      '/driver/status',
      authenticated: true,
      body: {'status': status},
    );
    return Map<String, dynamic>.from(data['driver'] as Map);
  }

  Future<void> sendLocation({
    required double latitude,
    required double longitude,
    double? accuracy,
    double? speed,
    double? heading,
  }) async {
    await api.request(
      'POST',
      '/driver/location',
      authenticated: true,
      body: {
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'speed': speed,
        'heading': heading,
      },
    );
  }

  Future<Map<String, dynamic>> currentDriver() async {
    final data =
        await api.request('GET', '/auth/me', authenticated: true);
    final user = Map<String, dynamic>.from(data['user'] as Map);
    return user['deliverer'] is Map
        ? Map<String, dynamic>.from(user['deliverer'] as Map)
        : {};
  }
}
