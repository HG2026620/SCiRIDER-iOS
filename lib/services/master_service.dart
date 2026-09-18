import '../config/api_config.dart';
import 'api_service.dart';

class MasterOption {
  final int id;
  final String code;
  final String name;
  final String description;
  final int parentId;

  const MasterOption({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.parentId,
  });

  factory MasterOption.fromJson(Map<String, dynamic> json) {
    return MasterOption(
      id: _toInt(json['id'] ?? json['Id'] ?? json['iValue']),
      code: _toText(json['code'] ?? json['Code'] ?? json['sCode']),
      name: _toText(json['name'] ?? json['Name'] ?? json['sValue']),
      description: _toText(
        json['description'] ?? json['Description'] ?? json['sDescription'],
      ),
      parentId: _toInt(
        json['parentId'] ?? json['ParentId'] ?? json['iParentId'],
      ),
    );
  }

  static int _toInt(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value.toString()) ?? 0;
  }

  static String _toText(dynamic value) {
    return value?.toString().trim() ?? '';
  }
}

class MasterService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> getPRDropdowns() async {
    final response = await _apiService.get(ApiConfig.prDropdowns);

    if (response['data'] is Map) {
      return Map<String, dynamic>.from(response['data']);
    }

    return Map<String, dynamic>.from(response);
  }

  List<MasterOption> toOptionList(dynamic value) {
    if (value is! List) {
      return <MasterOption>[];
    }

    final result = <MasterOption>[];

    for (final item in value) {
      if (item is! Map) {
        continue;
      }

      final option = MasterOption.fromJson(Map<String, dynamic>.from(item));

      if (option.name.isEmpty) {
        continue;
      }

      if (!result.any((x) => x.id == option.id)) {
        result.add(option);
      }
    }

    return result;
  }
}
