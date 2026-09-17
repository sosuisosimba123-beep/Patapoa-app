import 'package:flutter/foundation.dart';
import 'pocketbase_services.dart';

class AddressService {
  Future<List<Map<String, dynamic>>> getAddresses() async {
    final userId = pb.authStore.model?.id;
    if (userId == null) return [];

    try {
      final result = await pb.collection('addresses').getList(
        filter: 'user = "$userId"',
        sort: '-is_default,created',
      );
      return result.items.map((r) => {'id': r.id, ...r.data}).toList();
    } catch (e) {
      debugPrint('PocketBase GetAddresses Error: $e');
      return [];
    }
  }

  Future<void> createAddress({
    required String label,
    required String recipientName,
    required String phone,
    required String addressLine1,
    required String city,
    double? latitude,
    double? longitude,
  }) async {
    final userId = pb.authStore.model?.id;
    if (userId == null) return;

    await pb.collection('addresses').create(body: {
      'user': userId,
      'label': label,
      'recipient_name': recipientName,
      'phone': phone,
      'address_line_1': addressLine1,
      'city': city,
      'latitude': latitude,
      'longitude': longitude,
    });
  }

  Future<void> setDefaultAddress(String id) async {
    final userId = pb.authStore.model?.id;
    if (userId == null) return;

    // Reset others
    final current = await pb.collection('addresses').getList(filter: 'user = "$userId" && is_default = true');
    for (var item in current.items) {
      await pb.collection('addresses').update(item.id, body: {'is_default': false});
    }

    // Set new default
    await pb.collection('addresses').update(id, body: {'is_default': true});
  }

  Future<void> deleteAddress(String id) async {
    await pb.collection('addresses').delete(id);
  }
}
