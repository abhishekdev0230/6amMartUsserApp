class LiveTrack {
  bool? status;
  String? message;
  Location? location;

  LiveTrack({this.status, this.message, this.location});

  LiveTrack.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    location = json['location'] != null
        ? new Location.fromJson(json['location'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['status'] = this.status;
    data['message'] = this.message;
    if (this.location != null) {
      data['location'] = this.location!.toJson();
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

  Location(
      {this.id,
        this.userId,
        this.latitude,
        this.longitude,
        this.recordedAt,
        this.createdAt,
        this.updatedAt});

  Location.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    userId = json['user_id'];
    latitude = json['latitude'];
    longitude = json['longitude'];
    recordedAt = json['recorded_at'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['user_id'] = this.userId;
    data['latitude'] = this.latitude;
    data['longitude'] = this.longitude;
    data['recorded_at'] = this.recordedAt;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    return data;
  }
}
