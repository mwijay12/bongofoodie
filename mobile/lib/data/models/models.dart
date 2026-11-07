import 'dart:convert';

enum UserRole {
  customer,
  waiter,
  kitchen,
  admin;

  static UserRole fromString(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'waiter':
        return UserRole.waiter;
      case 'kitchen':
        return UserRole.kitchen;
      default:
        return UserRole.customer;
    }
  }

  bool get isStaff =>
      this == UserRole.admin || this == UserRole.waiter || this == UserRole.kitchen;

  String get value => name;
}

enum PaymentMethod {
  lipaNamba,
  cashOnDelivery;

  String get dbValue =>
      this == PaymentMethod.lipaNamba ? 'lipanamba' : 'cash';

  String get label =>
      this == PaymentMethod.lipaNamba ? 'Lipa Namba (Mobile Money)' : 'Cash on Delivery';

  static PaymentMethod fromString(String? raw) {
    final v = (raw ?? '').toLowerCase();
    return v.contains('lipa') || v.contains('mpesa') || v.contains('mobile')
        ? PaymentMethod.lipaNamba
        : PaymentMethod.cashOnDelivery;
  }
}

class AppUser {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String avatarUrl;
  final UserRole role;
  final bool isDemo;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone = '',
    this.avatarUrl = '',
    this.role = UserRole.customer,
    this.isDemo = false,
  });

  String get initials {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'BF';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }

  AppUser copyWith({
    String? name,
    String? email,
    String? phone,
    String? avatarUrl,
    UserRole? role,
    bool? isDemo,
  }) {
    return AppUser(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      isDemo: isDemo ?? this.isDemo,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'avatar_url': avatarUrl,
        'role': role.name,
        'is_demo': isDemo,
      };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: (json['id'] ?? '').toString(),
        name: (json['name'] ?? 'Bongo Foodie User').toString(),
        email: (json['email'] ?? '').toString(),
        phone: (json['phone'] ?? '').toString(),
        avatarUrl: (json['avatar_url'] ?? '').toString(),
        role: UserRole.fromString(json['role']?.toString()),
        isDemo: json['is_demo'] == true,
      );
}

class CategoryModel {
  final String id;
  final String name;
  final String description;

  const CategoryModel({
    required this.id,
    required this.name,
    this.description = '',
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
        id: (json['id'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        description: (json['description'] ?? '').toString(),
      );
}

class CustomizationOption {
  final String id;
  final String name;
  final double price;
  final String type;

  const CustomizationOption({
    required this.id,
    required this.name,
    required this.price,
    this.type = 'topping',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
        'type': type,
      };

  factory CustomizationOption.fromJson(Map<String, dynamic> json) =>
      CustomizationOption(
        id: (json['id'] ?? json['name'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        price: (json['price'] as num?)?.toDouble() ?? 0,
        type: (json['type'] ?? 'topping').toString(),
      );
}

class MenuItemModel {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final double price;
  final double rating;
  final int ratingCount;
  final int calories;
  final int protein;
  final int prepTimeMins;
  final String categoryId;
  final String categoryName;
  final List<CustomizationOption> availableCustomizations;

  const MenuItemModel({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.price,
    this.rating = 4.8,
    this.ratingCount = 12,
    this.calories = 520,
    this.protein = 24,
    this.prepTimeMins = 20,
    this.categoryId = '',
    this.categoryName = 'Swahili Bites',
    this.availableCustomizations = const [],
  });

  MenuItemModel copyWith({
    double? rating,
    int? ratingCount,
    double? price,
  }) {
    return MenuItemModel(
      id: id,
      name: name,
      description: description,
      imageUrl: imageUrl,
      price: price ?? this.price,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      calories: calories,
      protein: protein,
      prepTimeMins: prepTimeMins,
      categoryId: categoryId,
      categoryName: categoryName,
      availableCustomizations: availableCustomizations,
    );
  }
}

class CartItemModel {
  final String id;
  final String name;
  final double price;
  final String imageUrl;
  final int quantity;
  final List<CustomizationOption> customizations;
  final bool isAiCreated;
  final int? calories;
  final int? protein;
  final String? description;

  const CartItemModel({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    this.quantity = 1,
    this.customizations = const [],
    this.isAiCreated = false,
    this.calories,
    this.protein,
    this.description,
  });

  double get customizationsTotal =>
      customizations.fold<double>(0, (sum, c) => sum + c.price);

  double get unitPrice => price + customizationsTotal;

  double get lineTotal => unitPrice * quantity;

  String get compositeKey {
    final sortedIds = customizations.map((c) => c.id).toList()..sort();
    return '$id::${sortedIds.join('|')}';
  }

  String get signatureKey => compositeKey;
  bool get isCustomAiDish => isAiCreated;

  CartItemModel copyWith({int? quantity}) => CartItemModel(
        id: id,
        name: name,
        price: price,
        imageUrl: imageUrl,
        quantity: quantity ?? this.quantity,
        customizations: customizations,
        isAiCreated: isAiCreated,
        calories: calories,
        protein: protein,
        description: description,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
        'image_url': imageUrl,
        'quantity': quantity,
        'customizations': customizations.map((c) => c.toJson()).toList(),
        'isAICreated': isAiCreated,
        'calories': calories,
        'protein': protein,
        'description': description,
      };

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    final rawCust = json['customizations'];
    final parsedCust = rawCust is List
        ? rawCust
            .whereType<Map>()
            .map((m) => CustomizationOption.fromJson(Map<String, dynamic>.from(m)))
            .toList()
        : <CustomizationOption>[];

    return CartItemModel(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      price: (json['price'] as num?)?.toDouble() ?? 0,
      imageUrl: (json['image_url'] ?? 'salad').toString(),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      customizations: parsedCust,
      isAiCreated: json['isAICreated'] == true,
      calories: (json['calories'] as num?)?.toInt(),
      protein: (json['protein'] as num?)?.toInt(),
      description: json['description']?.toString(),
    );
  }
}

enum OrderStatus {
  pending,
  preparing,
  ready,
  inTransit,
  delivered,
  cancelled;

  String get dbValue {
    switch (this) {
      case OrderStatus.pending:
        return 'pending';
      case OrderStatus.preparing:
        return 'preparing';
      case OrderStatus.ready:
        return 'ready';
      case OrderStatus.inTransit:
        return 'in_transit';
      case OrderStatus.delivered:
        return 'delivered';
      case OrderStatus.cancelled:
        return 'cancelled';
    }
  }

  String get displayLabel {
    switch (this) {
      case OrderStatus.pending:
        return 'Placed';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.ready:
        return 'Ready';
      case OrderStatus.inTransit:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get labelEn => displayLabel;

  int get stepIndex {
    switch (this) {
      case OrderStatus.pending:
      case OrderStatus.preparing:
        return 0;
      case OrderStatus.ready:
        return 1;
      case OrderStatus.inTransit:
        return 2;
      case OrderStatus.delivered:
        return 3;
      case OrderStatus.cancelled:
        return -1;
    }
  }

  static OrderStatus fromDb(String? value) {
    switch ((value ?? '').toLowerCase()) {
      case 'preparing':
        return OrderStatus.preparing;
      case 'ready':
        return OrderStatus.ready;
      case 'in_transit':
      case 'out_for_delivery':
        return OrderStatus.inTransit;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }
}

class OrderModel {
  final String id;
  final String? profileId;
  final String tableNumber;
  final List<CartItemModel> items;
  final OrderStatus status;
  final double totalPrice;
  final String deliveryLocation;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final String paymentMethod;
  final String notes;
  final DateTime createdAt;

  const OrderModel({
    required this.id,
    this.profileId,
    this.tableNumber = 'Delivery',
    required this.items,
    this.status = OrderStatus.pending,
    required this.totalPrice,
    required this.deliveryLocation,
    this.customerName = 'Guest Customer',
    this.customerEmail = '',
    this.customerPhone = '',
    this.paymentMethod = 'cash',
    this.notes = '',
    required this.createdAt,
  });

  double get totalAmount => totalPrice;
  String get deliveryAddress => deliveryLocation;
  PaymentMethod get paymentMethodType => PaymentMethod.fromString(paymentMethod);

  OrderModel copyWith({OrderStatus? status}) => OrderModel(
        id: id,
        profileId: profileId,
        tableNumber: tableNumber,
        items: items,
        status: status ?? this.status,
        totalPrice: totalPrice,
        deliveryLocation: deliveryLocation,
        customerName: customerName,
        customerEmail: customerEmail,
        customerPhone: customerPhone,
        paymentMethod: paymentMethod,
        notes: notes,
        createdAt: createdAt,
      );

  Map<String, dynamic> toDbJson() => {
        'id': id,
        'profile_id': (profileId != null && !profileId!.startsWith('demo-'))
            ? profileId
            : null,
        'table_number': tableNumber,
        'items': jsonEncode(items.map((e) => e.toJson()).toList()),
        'status': status.dbValue,
        'total_price': totalPrice,
        'delivery_location': deliveryLocation,
        'customer_name': customerName,
        'customer_email': customerEmail,
        'customer_phone': customerPhone,
        'payment_method': paymentMethod,
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
      };

  Map<String, dynamic> toLocalJson() => {
        ...toDbJson(),
        'profile_id': profileId,
      };

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    List<CartItemModel> parsedItems = [];
    if (rawItems is String && rawItems.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawItems);
        if (decoded is List) {
          parsedItems = decoded
              .whereType<Map>()
              .map((e) => CartItemModel.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        }
      } catch (_) {}
    } else if (rawItems is List) {
      parsedItems = rawItems
          .whereType<Map>()
          .map((e) => CartItemModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    return OrderModel(
      id: (json['id'] ?? '').toString(),
      profileId: json['profile_id']?.toString(),
      tableNumber: (json['table_number'] ?? 'Delivery').toString(),
      items: parsedItems,
      status: OrderStatus.fromDb(json['status']?.toString()),
      totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0,
      deliveryLocation:
          (json['delivery_location'] ?? 'Dar es Salaam, Tanzania').toString(),
      customerName: (json['customer_name'] ?? 'Guest Customer').toString(),
      customerEmail: (json['customer_email'] ?? '').toString(),
      customerPhone: (json['customer_phone'] ?? '').toString(),
      paymentMethod: (json['payment_method'] ?? 'cash').toString(),
      notes: (json['notes'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}

class PromotionModel {
  final String id;
  final String title;
  final String subtitle;
  final String discountBadge;
  final String promoCode;
  final String bgHex;
  final String imageKey;
  final bool isActive;

  const PromotionModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.discountBadge,
    this.promoCode = 'KARIBU2000',
    this.bgHex = '#F6821F',
    this.imageKey = 'nyamaChoma',
    this.isActive = true,
  });

  String get bgColorHex => bgHex;
  String get badgeText => discountBadge;
  String get targetCategory {
    final lower = title.toLowerCase();
    if (lower.contains('pilau')) return 'Rice & Pilau';
    if (lower.contains('pizza') || lower.contains('burger')) {
      return 'Gourmet Specials';
    }
    return 'Nyama Choma';
  }

  factory PromotionModel.fromJson(Map<String, dynamic> json) => PromotionModel(
        id: (json['id'] ?? '').toString(),
        title: (json['title'] ?? '').toString(),
        subtitle: (json['subtitle'] ?? '').toString(),
        discountBadge: (json['discount_badge'] ?? '🔥 OFFER').toString(),
        promoCode: (json['promo_code'] ?? 'KARIBU2000').toString(),
        bgHex: (json['bg_hex'] ?? '#F6821F').toString(),
        imageKey: (json['image_key'] ?? 'nyamaChoma').toString(),
        isActive: json['is_active'] != false,
      );
}

class DiscoveryModel {
  final String id;
  final String title;
  final String description;

  const DiscoveryModel({
    required this.id,
    required this.title,
    required this.description,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
      };

  factory DiscoveryModel.fromJson(Map<String, dynamic> json) => DiscoveryModel(
        id: (json['id'] ?? '').toString(),
        title: (json['title'] ?? '').toString(),
        description: (json['description'] ?? '').toString(),
      );
}

typedef SpiceTriviaQuestion = TriviaQuestion;

class TriviaQuestion {
  final int id;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explainer;

  const TriviaQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explainer,
  });

  String get rewardNote => explainer;
}

class BranchSettingsModel {
  final String restaurantName;
  final String branchAddress;
  final String phone;
  final String mpesaTill;
  final String tigoTill;
  final String airtelTill;
  final String haloTill;
  final String nmbAccount;
  final String crdbAccount;
  final double deliveryFee;
  final String promoCode;
  final double promoDiscount;
  final bool promoActive;

  const BranchSettingsModel({
    this.restaurantName = 'Bongo Foodie',
    this.branchAddress = 'Kijitonyama Branch, Dar es Salaam',
    this.phone = '+255 712 345 678',
    this.mpesaTill = '556677',
    this.tigoTill = '223344',
    this.airtelTill = '889900',
    this.haloTill = '112233',
    this.nmbAccount = '9900112233',
    this.crdbAccount = '8877665544',
    this.deliveryFee = 2000,
    this.promoCode = 'KARIBU2000',
    this.promoDiscount = 2000,
    this.promoActive = true,
  });

  String get lipaNamba => mpesaTill;
  String get lipaName => restaurantName;

  factory BranchSettingsModel.fromJson(Map<String, dynamic> json) =>
      BranchSettingsModel(
        restaurantName: (json['restaurant_name'] ?? 'Bongo Foodie').toString(),
        branchAddress: (json['branch_address'] ??
                'Kijitonyama Branch, Dar es Salaam')
            .toString(),
        phone: (json['phone'] ?? '+255 712 345 678').toString(),
        mpesaTill: (json['mpesa_till'] ?? '556677').toString(),
        tigoTill: (json['tigo_till'] ?? '223344').toString(),
        airtelTill: (json['airtel_till'] ?? '889900').toString(),
        haloTill: (json['halo_till'] ?? '112233').toString(),
        nmbAccount: (json['nmb_account'] ?? '9900112233').toString(),
        crdbAccount: (json['crdb_account'] ?? '8877665544').toString(),
        deliveryFee: (json['delivery_fee'] as num?)?.toDouble() ?? 3000,
        promoCode: (json['promo_code'] ?? 'KARIBU2000').toString(),
        promoDiscount: (json['promo_discount'] as num?)?.toDouble() ?? 2000,
        promoActive: json['promo_active'] != false,
      );
}

class TzRegion {
  final int code;
  final String name;
  const TzRegion({required this.code, required this.name});
}

class TzDistrict {
  final int code;
  final String name;
  final int regionCode;
  const TzDistrict({
    required this.code,
    required this.name,
    required this.regionCode,
  });
}

class TzWard {
  final int code;
  final String name;
  final int districtCode;
  const TzWard({
    required this.code,
    required this.name,
    required this.districtCode,
  });
}

class ChefChatMessage {
  final String id;
  final bool isUser;
  final String content;
  final DateTime timestamp;

  const ChefChatMessage({
    required this.id,
    required this.isUser,
    required this.content,
    required this.timestamp,
  });
}

class GeneratedDishSpec {
  final String name;
  final String description;
  final double price;
  final int calories;
  final int protein;
  final String category;
  final List<String> customizations;
  final String imageUrl;

  const GeneratedDishSpec({
    required this.name,
    required this.description,
    required this.price,
    required this.calories,
    required this.protein,
    required this.category,
    required this.customizations,
    required this.imageUrl,
  });
}
