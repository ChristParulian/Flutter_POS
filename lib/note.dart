class Note {
  int? id;
  String title;
  String description;

  Note({this.id, required this.title, required this.description});

  // Convert a Note object to a Map object
  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      'title': title,
      'description': description,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  // Extract a Note object from a Map object
  Note.fromMap(Map<String, dynamic> map)
      : id = map['id'],
        title = map['title'],
        description = map['description'];
}
