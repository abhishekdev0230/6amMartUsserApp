class LiveTrack {
  bool? status;
  String? message;
  Location? location;
  DeliveryHistory? deliveryHistory; // 🔹 Added

  LiveTrack({this.status, this.message, this.location, this.deliveryHistory});

  LiveTrack.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    location = json['location'] != null
        ? Location.fromJson(json['location'])
        : null;
    deliveryHistory = json['deliveryHistory'] != null
        ? DeliveryHistory.fromJson(json['deliveryHistory'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['message'] = message;
    if (location != null) {
      data['location'] = location!.toJson();
    }
    if (deliveryHistory != null) {
      data['deliveryHistory'] = deliveryHistory!.toJson();
    }
    return data;
  }
}

class Location {
  int? id;
  int? userId;
  double? latitude;
  double? longitude;
  String? recordedAt;
  String? createdAt;
  String? updatedAt;

  Location({
    this.id,
    this.userId,
    this.latitude,
    this.longitude,
    this.recordedAt,
    this.createdAt,
    this.updatedAt,
  });

  Location.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    userId = json['user_id'];
    latitude = json['latitude']?.toDouble();
    longitude = json['longitude']?.toDouble();
    recordedAt = json['recorded_at'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['user_id'] = userId;
    data['latitude'] = latitude;
    data['longitude'] = longitude;
    data['recorded_at'] = recordedAt;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}

class DeliveryHistory {
  int? id;
  int? deliveryManId;
  String? orderId;
  String? time;
  String? longitude;
  String? latitude;
  String? location;
  String? createdAt;
  String? updatedAt;

  DeliveryHistory({
    this.id,
    this.deliveryManId,
    this.orderId,
    this.time,
    this.longitude,
    this.latitude,
    this.location,
    this.createdAt,
    this.updatedAt,
  });

  DeliveryHistory.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    orderId = json['order_id']?.toString(); // can be null
    deliveryManId = json['delivery_man_id'];
    time = json['time'];
    longitude = json['longitude'];
    latitude = json['latitude'];
    location = json['location'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['order_id'] = orderId;
    data['delivery_man_id'] = deliveryManId;
    data['time'] = time;
    data['longitude'] = longitude;
    data['latitude'] = latitude;
    data['location'] = location;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}
