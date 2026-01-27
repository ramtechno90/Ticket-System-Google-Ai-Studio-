class Client {
  final String id;
  final String name;
  final String domain;

  Client({
    required this.id,
    required this.name,
    required this.domain,
  });

  factory Client.fromMap(Map<String, dynamic> data, String id) {
    return Client(
      id: id,
      name: data['name'] ?? '',
      domain: data['domain'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'domain': domain,
    };
  }
}
