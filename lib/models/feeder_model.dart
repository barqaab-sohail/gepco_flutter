class Feeder {
  int? id;
  String? name;
  String? feederCode;
  String? category;

  Feeder({this.id, this.name, this.feederCode, this.category});

  Feeder.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    feederCode = json['feeder_code'];
    category = json['category'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = id;
    data['name'] = name;
    data['feeder_code'] = feederCode;
    data['category'] = category;
    return data;
  }
}
