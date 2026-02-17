import 'dart:convert';
import 'package:http/http.dart' as http;

// Мини REST-клиент Firestore для Windows dev:
// используем, когда firebase_firestore на desktop ведет себя нестабильно.
class FirestoreRestService {
  static const String projectId = 'deti-zhivotnie-prod';
  static const String apiKey = 'AIzaSyBhL-nacZ_T2FMiLClgx7coFAuU_B6EO4Q';

  static Uri _listDocsUri(String documentPath) {
    final base =
        'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/$documentPath';
    return Uri.parse('$base?key=$apiKey');
  }

  static dynamic _decodeValue(Map<String, dynamic> v) {
    if (v.containsKey('stringValue')) return v['stringValue'] as String;
    if (v.containsKey('booleanValue')) return v['booleanValue'] as bool;
    if (v.containsKey('integerValue')) return int.tryParse(v['integerValue'].toString()) ?? 0;
    if (v.containsKey('doubleValue')) return (v['doubleValue'] as num).toDouble();
    if (v.containsKey('nullValue')) return null;
    if (v.containsKey('mapValue')) {
      final fields = (v['mapValue'] as Map<String, dynamic>)['fields'] as Map<String, dynamic>? ?? {};
      return fields.map((k, vv) => MapEntry(k, _decodeValue(vv as Map<String, dynamic>)));
    }
    if (v.containsKey('arrayValue')) {
      final values = (v['arrayValue'] as Map<String, dynamic>)['values'] as List<dynamic>? ?? const [];
      return values.map((e) => _decodeValue(e as Map<String, dynamic>)).toList();
    }
    return null;
  }

  static Map<String, dynamic> _decodeFields(Map<String, dynamic> doc) {
    final fields = doc['fields'] as Map<String, dynamic>? ?? {};
    return fields.map((k, v) => MapEntry(k, _decodeValue(v as Map<String, dynamic>)));
  }

  static String _idFromName(String name) {
    final parts = name.split('/');
    return parts.isNotEmpty ? parts.last : name;
  }

  static Future<List<Map<String, dynamic>>> listCollectionDocs(String collectionPath) async {
    final res = await http.get(_listDocsUri(collectionPath));
    if (res.statusCode != 200) {
      throw Exception('REST Firestore error ${res.statusCode}: ${res.body}');
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final docs = (json['documents'] as List<dynamic>?) ?? const [];
    return docs.map((d) {
      final doc = d as Map<String, dynamic>;
      final fields = _decodeFields(doc);
      fields['id'] = _idFromName(doc['name'] as String);
      return fields;
    }).toList();
  }
}

