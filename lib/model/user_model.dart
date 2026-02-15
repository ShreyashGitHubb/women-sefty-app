// class UserModel{

//   String? name;
//   String? id;
//   String? phone;
//   String? childEmail;
//   String? parentEmail;
//    String? type;

//   UserModel({this.name,this.childEmail,this.id,this.parentEmail,this.phone,this.type});
//   Map<String,dynamic> toJson()=>{
//     'name':name,
//     'phone':phone,
//     'id':id,
//     'childEmail':childEmail,
//     'parentEmail':parentEmail,
//     'type':type
//   };

// }

class UserModel {
  String name;
  String id;
  String? phone;
  String childEmail;
  String parentEmail;
  String type;
  String? adminEmail;

  UserModel({
    required this.name,
    required this.id,
    this.phone,
    required this.childEmail,
    required this.parentEmail,
    required this.type,
    this.adminEmail,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      name: json['name']?.toString() ?? '',
      id: json['id']?.toString() ?? '',
      phone: json['phone']?.toString(),
      childEmail: json['childEmail']?.toString() ?? '',
      parentEmail: json['parentEmail']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      adminEmail: json['adminEmail']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'id': id,
      'childEmail': childEmail,
      'parentEmail': parentEmail,
      'type': type,
      'adminEmail': adminEmail,
    };
  }
}
