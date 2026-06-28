class CustomerOffer {
  const CustomerOffer({
    required this.productName,
    required this.shopName,
    required this.imageUrl,
    required this.priceTzs,
    required this.rating,
    required this.distanceKm,
    required this.etaMinutes,
    required this.inventoryLabel,
    required this.isBestSeller,
  });

  final String productName;
  final String shopName;
  final String imageUrl;
  final int priceTzs;
  final double rating;
  final double distanceKm;
  final int etaMinutes;
  final String inventoryLabel;
  final bool isBestSeller;
}

class CustomerOrderDraft {
  const CustomerOrderDraft({
    required this.offer,
    required this.quantity,
    required this.deliveryFeeTzs,
    required this.platformFeeTzs,
  });

  final CustomerOffer offer;
  final int quantity;
  final int deliveryFeeTzs;
  final int platformFeeTzs;

  int get subtotalTzs => offer.priceTzs * quantity;

  int get totalTzs => subtotalTzs + deliveryFeeTzs + platformFeeTzs;
}

class CustomerPlacedOrder {
  const CustomerPlacedOrder({
    required this.id,
    required this.draft,
    required this.pickupLabel,
    required this.dropoffLabel,
    required this.riderName,
    required this.riderRating,
    required this.status,
    required this.orderDate,
  });

  final String id;
  final CustomerOrderDraft draft;
  final String pickupLabel;
  final String dropoffLabel;
  final String riderName;
  final double riderRating;
  final String status;
  final DateTime orderDate;
}

String formatTzs(int amount) {
  final text = amount.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    final reverseIndex = text.length - i;
    buffer.write(text[i]);
    if (reverseIndex > 1 && reverseIndex % 3 == 1) {
      buffer.write(',');
    }
  }
  return 'TZS ${buffer.toString()}';
}

class CustomerDemoData {
  static List<CustomerOffer> exploreNearbyOffers() {
    return const [
      CustomerOffer(
        productName: 'Cement - Simba',
        shopName: 'Kurasini Hardware',
        imageUrl:
            'https://images.unsplash.com/photo-1581091870622-3d5c4f43f882?auto=format&fit=crop&w=800&q=80',
        priceTzs: 18500,
        rating: 4.8,
        distanceKm: 0.8,
        etaMinutes: 25,
        inventoryLabel: '50+ available',
        isBestSeller: true,
      ),
      CustomerOffer(
        productName: 'iPhone Charger',
        shopName: 'Mlimani City Gadgets',
        imageUrl:
            'https://images.unsplash.com/photo-1583863788434-e58a36330b1c?auto=format&fit=crop&w=800&q=80',
        priceTzs: 25000,
        rating: 4.9,
        distanceKm: 1.2,
        etaMinutes: 15,
        inventoryLabel: '20+ available',
        isBestSeller: false,
      ),
      CustomerOffer(
        productName: 'Fresh Avocados (x4)',
        shopName: 'Kibo Grocery',
        imageUrl:
            'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=800&q=80',
        priceTzs: 5000,
        rating: 4.7,
        distanceKm: 0.5,
        etaMinutes: 18,
        inventoryLabel: 'In stock',
        isBestSeller: false,
      ),
    ];
  }

  static List<CustomerOffer> searchResultsForQuery(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return const [];
    }

    if (normalized.contains('charger') || normalized.contains('iphone')) {
      return const [
        CustomerOffer(
          productName: 'Fast Charger (20W)',
          shopName: 'Mlimani City Gadgets',
          imageUrl:
              'https://images.unsplash.com/photo-1609091839311-d5365f9ff1c5?auto=format&fit=crop&w=800&q=80',
          priceTzs: 30000,
          rating: 4.8,
          distanceKm: 1.2,
          etaMinutes: 15,
          inventoryLabel: 'In stock',
          isBestSeller: false,
        ),
        CustomerOffer(
          productName: 'Original Apple 20W',
          shopName: 'iShop Tanzania',
          imageUrl:
              'https://images.unsplash.com/photo-1583863788434-e58a36330b1c?auto=format&fit=crop&w=800&q=80',
          priceTzs: 65000,
          rating: 4.9,
          distanceKm: 2.8,
          etaMinutes: 35,
          inventoryLabel: 'Limited stock',
          isBestSeller: true,
        ),
        CustomerOffer(
          productName: 'Fast Charger (20W)',
          shopName: 'Kariakoo Tech Hub',
          imageUrl:
              'https://images.unsplash.com/photo-1612810436541-336d9d3f04d7?auto=format&fit=crop&w=800&q=80',
          priceTzs: 28000,
          rating: 4.7,
          distanceKm: 0.8,
          etaMinutes: 12,
          inventoryLabel: 'In stock',
          isBestSeller: false,
        ),
      ];
    }

    return const [
      CustomerOffer(
        productName: 'Premium White Cement 50kg',
        shopName: 'Kurasini Hardware',
        imageUrl:
            'https://images.unsplash.com/photo-1581092580497-e0d23cbdf1dc?auto=format&fit=crop&w=800&q=80',
        priceTzs: 19000,
        rating: 4.9,
        distanceKm: 0.8,
        etaMinutes: 28,
        inventoryLabel: '50+ available',
        isBestSeller: true,
      ),
      CustomerOffer(
        productName: 'Premium White Cement 50kg',
        shopName: 'Kigamboni Builders',
        imageUrl:
            'https://images.unsplash.com/photo-1581092160562-40aa08e78837?auto=format&fit=crop&w=800&q=80',
        priceTzs: 18500,
        rating: 4.7,
        distanceKm: 2.0,
        etaMinutes: 36,
        inventoryLabel: '20+ available',
        isBestSeller: false,
      ),
    ];
  }

  static List<CustomerPlacedOrder> getOrderHistory() {
    final now = DateTime.now();
    return [
      CustomerPlacedOrder(
        id: 'ORD-001',
        draft: const CustomerOrderDraft(
          offer: CustomerOffer(
            productName: 'iPhone Charger',
            shopName: 'Mlimani City Gadgets',
            imageUrl:
                'https://images.unsplash.com/photo-1583863788434-e58a36330b1c?auto=format&fit=crop&w=800&q=80',
            priceTzs: 25000,
            rating: 4.9,
            distanceKm: 1.2,
            etaMinutes: 15,
            inventoryLabel: '20+ available',
            isBestSeller: false,
          ),
          quantity: 1,
          deliveryFeeTzs: 3500,
          platformFeeTzs: 500,
        ),
        pickupLabel: 'Mlimani City Mall',
        dropoffLabel: 'Morogoro Road, Block G, DSM',
        riderName: 'John M.',
        riderRating: 4.8,
        status: 'delivered',
        orderDate: now.subtract(const Duration(days: 1)),
      ),
      CustomerPlacedOrder(
        id: 'ORD-002',
        draft: const CustomerOrderDraft(
          offer: CustomerOffer(
            productName: 'Fresh Avocados (x4)',
            shopName: 'Kibo Grocery',
            imageUrl:
                'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=800&q=80',
            priceTzs: 5000,
            rating: 4.7,
            distanceKm: 0.5,
            etaMinutes: 18,
            inventoryLabel: 'In stock',
            isBestSeller: false,
          ),
          quantity: 2,
          deliveryFeeTzs: 3500,
          platformFeeTzs: 500,
        ),
        pickupLabel: 'Kibo Market',
        dropoffLabel: 'Sinza Mori, DSM',
        riderName: 'Sarah K.',
        riderRating: 4.9,
        status: 'in_transit',
        orderDate: now.subtract(const Duration(hours: 3)),
      ),
      CustomerPlacedOrder(
        id: 'ORD-003',
        draft: const CustomerOrderDraft(
          offer: CustomerOffer(
            productName: 'Cement - Simba',
            shopName: 'Kurasini Hardware',
            imageUrl:
                'https://images.unsplash.com/photo-1581091870622-3d5c4f43f882?auto=format&fit=crop&w=800&q=80',
            priceTzs: 18500,
            rating: 4.8,
            distanceKm: 0.8,
            etaMinutes: 25,
            inventoryLabel: '50+ available',
            isBestSeller: true,
          ),
          quantity: 5,
          deliveryFeeTzs: 5000,
          platformFeeTzs: 800,
        ),
        pickupLabel: 'Kurasini Depot',
        dropoffLabel: 'Mikocheni, DSM',
        riderName: 'Ali H.',
        riderRating: 4.7,
        status: 'pending',
        orderDate: now.subtract(const Duration(minutes: 30)),
      ),
    ];
  }
}

