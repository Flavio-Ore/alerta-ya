import 'package:alertaya/features/my_reports/data/models/my_report_model.dart';
import 'package:alertaya/features/my_reports/domain/entities/my_report_entity.dart';

class MyReportsPageModel {
  static MyReportsPage fromJson(Map<String, dynamic> json) => MyReportsPage(
        items: ((json['items'] as List?) ?? const [])
            .map((e) => MyReportModel.fromJson(
                  Map<String, dynamic>.from(e as Map),
                ))
            .toList(),
        page: json['page'] as int,
        pageSize: json['pageSize'] as int,
        total: json['total'] as int,
      );
}
