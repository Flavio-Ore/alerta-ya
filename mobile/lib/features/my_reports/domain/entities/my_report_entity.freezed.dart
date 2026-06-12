// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'my_report_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$MyReportEntity {
  String get reportId => throw _privateConstructorUsedError;
  IncidentType get type => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  double get lat => throw _privateConstructorUsedError;
  double get lng => throw _privateConstructorUsedError;
  Map<String, dynamic> get formData => throw _privateConstructorUsedError;
  List<String> get mediaUrls => throw _privateConstructorUsedError;
  MyReportIncident? get incident => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $MyReportEntityCopyWith<MyReportEntity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MyReportEntityCopyWith<$Res> {
  factory $MyReportEntityCopyWith(
          MyReportEntity value, $Res Function(MyReportEntity) then) =
      _$MyReportEntityCopyWithImpl<$Res, MyReportEntity>;
  @useResult
  $Res call(
      {String reportId,
      IncidentType type,
      DateTime createdAt,
      double lat,
      double lng,
      Map<String, dynamic> formData,
      List<String> mediaUrls,
      MyReportIncident? incident});

  $MyReportIncidentCopyWith<$Res>? get incident;
}

/// @nodoc
class _$MyReportEntityCopyWithImpl<$Res, $Val extends MyReportEntity>
    implements $MyReportEntityCopyWith<$Res> {
  _$MyReportEntityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? reportId = null,
    Object? type = null,
    Object? createdAt = null,
    Object? lat = null,
    Object? lng = null,
    Object? formData = null,
    Object? mediaUrls = null,
    Object? incident = freezed,
  }) {
    return _then(_value.copyWith(
      reportId: null == reportId
          ? _value.reportId
          : reportId // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as IncidentType,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      lat: null == lat
          ? _value.lat
          : lat // ignore: cast_nullable_to_non_nullable
              as double,
      lng: null == lng
          ? _value.lng
          : lng // ignore: cast_nullable_to_non_nullable
              as double,
      formData: null == formData
          ? _value.formData
          : formData // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      mediaUrls: null == mediaUrls
          ? _value.mediaUrls
          : mediaUrls // ignore: cast_nullable_to_non_nullable
              as List<String>,
      incident: freezed == incident
          ? _value.incident
          : incident // ignore: cast_nullable_to_non_nullable
              as MyReportIncident?,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $MyReportIncidentCopyWith<$Res>? get incident {
    if (_value.incident == null) {
      return null;
    }

    return $MyReportIncidentCopyWith<$Res>(_value.incident!, (value) {
      return _then(_value.copyWith(incident: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$MyReportEntityImplCopyWith<$Res>
    implements $MyReportEntityCopyWith<$Res> {
  factory _$$MyReportEntityImplCopyWith(_$MyReportEntityImpl value,
          $Res Function(_$MyReportEntityImpl) then) =
      __$$MyReportEntityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String reportId,
      IncidentType type,
      DateTime createdAt,
      double lat,
      double lng,
      Map<String, dynamic> formData,
      List<String> mediaUrls,
      MyReportIncident? incident});

  @override
  $MyReportIncidentCopyWith<$Res>? get incident;
}

/// @nodoc
class __$$MyReportEntityImplCopyWithImpl<$Res>
    extends _$MyReportEntityCopyWithImpl<$Res, _$MyReportEntityImpl>
    implements _$$MyReportEntityImplCopyWith<$Res> {
  __$$MyReportEntityImplCopyWithImpl(
      _$MyReportEntityImpl _value, $Res Function(_$MyReportEntityImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? reportId = null,
    Object? type = null,
    Object? createdAt = null,
    Object? lat = null,
    Object? lng = null,
    Object? formData = null,
    Object? mediaUrls = null,
    Object? incident = freezed,
  }) {
    return _then(_$MyReportEntityImpl(
      reportId: null == reportId
          ? _value.reportId
          : reportId // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as IncidentType,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      lat: null == lat
          ? _value.lat
          : lat // ignore: cast_nullable_to_non_nullable
              as double,
      lng: null == lng
          ? _value.lng
          : lng // ignore: cast_nullable_to_non_nullable
              as double,
      formData: null == formData
          ? _value._formData
          : formData // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      mediaUrls: null == mediaUrls
          ? _value._mediaUrls
          : mediaUrls // ignore: cast_nullable_to_non_nullable
              as List<String>,
      incident: freezed == incident
          ? _value.incident
          : incident // ignore: cast_nullable_to_non_nullable
              as MyReportIncident?,
    ));
  }
}

/// @nodoc

class _$MyReportEntityImpl implements _MyReportEntity {
  const _$MyReportEntityImpl(
      {required this.reportId,
      required this.type,
      required this.createdAt,
      required this.lat,
      required this.lng,
      required final Map<String, dynamic> formData,
      required final List<String> mediaUrls,
      this.incident})
      : _formData = formData,
        _mediaUrls = mediaUrls;

  @override
  final String reportId;
  @override
  final IncidentType type;
  @override
  final DateTime createdAt;
  @override
  final double lat;
  @override
  final double lng;
  final Map<String, dynamic> _formData;
  @override
  Map<String, dynamic> get formData {
    if (_formData is EqualUnmodifiableMapView) return _formData;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_formData);
  }

  final List<String> _mediaUrls;
  @override
  List<String> get mediaUrls {
    if (_mediaUrls is EqualUnmodifiableListView) return _mediaUrls;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_mediaUrls);
  }

  @override
  final MyReportIncident? incident;

  @override
  String toString() {
    return 'MyReportEntity(reportId: $reportId, type: $type, createdAt: $createdAt, lat: $lat, lng: $lng, formData: $formData, mediaUrls: $mediaUrls, incident: $incident)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MyReportEntityImpl &&
            (identical(other.reportId, reportId) ||
                other.reportId == reportId) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.lat, lat) || other.lat == lat) &&
            (identical(other.lng, lng) || other.lng == lng) &&
            const DeepCollectionEquality().equals(other._formData, _formData) &&
            const DeepCollectionEquality()
                .equals(other._mediaUrls, _mediaUrls) &&
            (identical(other.incident, incident) ||
                other.incident == incident));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      reportId,
      type,
      createdAt,
      lat,
      lng,
      const DeepCollectionEquality().hash(_formData),
      const DeepCollectionEquality().hash(_mediaUrls),
      incident);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MyReportEntityImplCopyWith<_$MyReportEntityImpl> get copyWith =>
      __$$MyReportEntityImplCopyWithImpl<_$MyReportEntityImpl>(
          this, _$identity);
}

abstract class _MyReportEntity implements MyReportEntity {
  const factory _MyReportEntity(
      {required final String reportId,
      required final IncidentType type,
      required final DateTime createdAt,
      required final double lat,
      required final double lng,
      required final Map<String, dynamic> formData,
      required final List<String> mediaUrls,
      final MyReportIncident? incident}) = _$MyReportEntityImpl;

  @override
  String get reportId;
  @override
  IncidentType get type;
  @override
  DateTime get createdAt;
  @override
  double get lat;
  @override
  double get lng;
  @override
  Map<String, dynamic> get formData;
  @override
  List<String> get mediaUrls;
  @override
  MyReportIncident? get incident;
  @override
  @JsonKey(ignore: true)
  _$$MyReportEntityImplCopyWith<_$MyReportEntityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$MyReportsPage {
  List<MyReportEntity> get items => throw _privateConstructorUsedError;
  int get page => throw _privateConstructorUsedError;
  int get pageSize => throw _privateConstructorUsedError;
  int get total => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $MyReportsPageCopyWith<MyReportsPage> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MyReportsPageCopyWith<$Res> {
  factory $MyReportsPageCopyWith(
          MyReportsPage value, $Res Function(MyReportsPage) then) =
      _$MyReportsPageCopyWithImpl<$Res, MyReportsPage>;
  @useResult
  $Res call({List<MyReportEntity> items, int page, int pageSize, int total});
}

/// @nodoc
class _$MyReportsPageCopyWithImpl<$Res, $Val extends MyReportsPage>
    implements $MyReportsPageCopyWith<$Res> {
  _$MyReportsPageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? page = null,
    Object? pageSize = null,
    Object? total = null,
  }) {
    return _then(_value.copyWith(
      items: null == items
          ? _value.items
          : items // ignore: cast_nullable_to_non_nullable
              as List<MyReportEntity>,
      page: null == page
          ? _value.page
          : page // ignore: cast_nullable_to_non_nullable
              as int,
      pageSize: null == pageSize
          ? _value.pageSize
          : pageSize // ignore: cast_nullable_to_non_nullable
              as int,
      total: null == total
          ? _value.total
          : total // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MyReportsPageImplCopyWith<$Res>
    implements $MyReportsPageCopyWith<$Res> {
  factory _$$MyReportsPageImplCopyWith(
          _$MyReportsPageImpl value, $Res Function(_$MyReportsPageImpl) then) =
      __$$MyReportsPageImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<MyReportEntity> items, int page, int pageSize, int total});
}

/// @nodoc
class __$$MyReportsPageImplCopyWithImpl<$Res>
    extends _$MyReportsPageCopyWithImpl<$Res, _$MyReportsPageImpl>
    implements _$$MyReportsPageImplCopyWith<$Res> {
  __$$MyReportsPageImplCopyWithImpl(
      _$MyReportsPageImpl _value, $Res Function(_$MyReportsPageImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? page = null,
    Object? pageSize = null,
    Object? total = null,
  }) {
    return _then(_$MyReportsPageImpl(
      items: null == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<MyReportEntity>,
      page: null == page
          ? _value.page
          : page // ignore: cast_nullable_to_non_nullable
              as int,
      pageSize: null == pageSize
          ? _value.pageSize
          : pageSize // ignore: cast_nullable_to_non_nullable
              as int,
      total: null == total
          ? _value.total
          : total // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

class _$MyReportsPageImpl implements _MyReportsPage {
  const _$MyReportsPageImpl(
      {required final List<MyReportEntity> items,
      required this.page,
      required this.pageSize,
      required this.total})
      : _items = items;

  final List<MyReportEntity> _items;
  @override
  List<MyReportEntity> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  final int page;
  @override
  final int pageSize;
  @override
  final int total;

  @override
  String toString() {
    return 'MyReportsPage(items: $items, page: $page, pageSize: $pageSize, total: $total)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MyReportsPageImpl &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            (identical(other.page, page) || other.page == page) &&
            (identical(other.pageSize, pageSize) ||
                other.pageSize == pageSize) &&
            (identical(other.total, total) || other.total == total));
  }

  @override
  int get hashCode => Object.hash(runtimeType,
      const DeepCollectionEquality().hash(_items), page, pageSize, total);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MyReportsPageImplCopyWith<_$MyReportsPageImpl> get copyWith =>
      __$$MyReportsPageImplCopyWithImpl<_$MyReportsPageImpl>(this, _$identity);
}

abstract class _MyReportsPage implements MyReportsPage {
  const factory _MyReportsPage(
      {required final List<MyReportEntity> items,
      required final int page,
      required final int pageSize,
      required final int total}) = _$MyReportsPageImpl;

  @override
  List<MyReportEntity> get items;
  @override
  int get page;
  @override
  int get pageSize;
  @override
  int get total;
  @override
  @JsonKey(ignore: true)
  _$$MyReportsPageImplCopyWith<_$MyReportsPageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$ReportStatusChangedEvent {
  String get incidentId => throw _privateConstructorUsedError;
  IncidentStatus get status => throw _privateConstructorUsedError;
  String get district => throw _privateConstructorUsedError;
  IncidentType get type => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;
  String? get feedback => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $ReportStatusChangedEventCopyWith<ReportStatusChangedEvent> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ReportStatusChangedEventCopyWith<$Res> {
  factory $ReportStatusChangedEventCopyWith(ReportStatusChangedEvent value,
          $Res Function(ReportStatusChangedEvent) then) =
      _$ReportStatusChangedEventCopyWithImpl<$Res, ReportStatusChangedEvent>;
  @useResult
  $Res call(
      {String incidentId,
      IncidentStatus status,
      String district,
      IncidentType type,
      DateTime updatedAt,
      String? feedback});
}

/// @nodoc
class _$ReportStatusChangedEventCopyWithImpl<$Res,
        $Val extends ReportStatusChangedEvent>
    implements $ReportStatusChangedEventCopyWith<$Res> {
  _$ReportStatusChangedEventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? incidentId = null,
    Object? status = null,
    Object? district = null,
    Object? type = null,
    Object? updatedAt = null,
    Object? feedback = freezed,
  }) {
    return _then(_value.copyWith(
      incidentId: null == incidentId
          ? _value.incidentId
          : incidentId // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as IncidentStatus,
      district: null == district
          ? _value.district
          : district // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as IncidentType,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      feedback: freezed == feedback
          ? _value.feedback
          : feedback // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ReportStatusChangedEventImplCopyWith<$Res>
    implements $ReportStatusChangedEventCopyWith<$Res> {
  factory _$$ReportStatusChangedEventImplCopyWith(
          _$ReportStatusChangedEventImpl value,
          $Res Function(_$ReportStatusChangedEventImpl) then) =
      __$$ReportStatusChangedEventImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String incidentId,
      IncidentStatus status,
      String district,
      IncidentType type,
      DateTime updatedAt,
      String? feedback});
}

/// @nodoc
class __$$ReportStatusChangedEventImplCopyWithImpl<$Res>
    extends _$ReportStatusChangedEventCopyWithImpl<$Res,
        _$ReportStatusChangedEventImpl>
    implements _$$ReportStatusChangedEventImplCopyWith<$Res> {
  __$$ReportStatusChangedEventImplCopyWithImpl(
      _$ReportStatusChangedEventImpl _value,
      $Res Function(_$ReportStatusChangedEventImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? incidentId = null,
    Object? status = null,
    Object? district = null,
    Object? type = null,
    Object? updatedAt = null,
    Object? feedback = freezed,
  }) {
    return _then(_$ReportStatusChangedEventImpl(
      incidentId: null == incidentId
          ? _value.incidentId
          : incidentId // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as IncidentStatus,
      district: null == district
          ? _value.district
          : district // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as IncidentType,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      feedback: freezed == feedback
          ? _value.feedback
          : feedback // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$ReportStatusChangedEventImpl implements _ReportStatusChangedEvent {
  const _$ReportStatusChangedEventImpl(
      {required this.incidentId,
      required this.status,
      required this.district,
      required this.type,
      required this.updatedAt,
      this.feedback});

  @override
  final String incidentId;
  @override
  final IncidentStatus status;
  @override
  final String district;
  @override
  final IncidentType type;
  @override
  final DateTime updatedAt;
  @override
  final String? feedback;

  @override
  String toString() {
    return 'ReportStatusChangedEvent(incidentId: $incidentId, status: $status, district: $district, type: $type, updatedAt: $updatedAt, feedback: $feedback)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ReportStatusChangedEventImpl &&
            (identical(other.incidentId, incidentId) ||
                other.incidentId == incidentId) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.district, district) ||
                other.district == district) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.feedback, feedback) ||
                other.feedback == feedback));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, incidentId, status, district, type, updatedAt, feedback);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ReportStatusChangedEventImplCopyWith<_$ReportStatusChangedEventImpl>
      get copyWith => __$$ReportStatusChangedEventImplCopyWithImpl<
          _$ReportStatusChangedEventImpl>(this, _$identity);
}

abstract class _ReportStatusChangedEvent implements ReportStatusChangedEvent {
  const factory _ReportStatusChangedEvent(
      {required final String incidentId,
      required final IncidentStatus status,
      required final String district,
      required final IncidentType type,
      required final DateTime updatedAt,
      final String? feedback}) = _$ReportStatusChangedEventImpl;

  @override
  String get incidentId;
  @override
  IncidentStatus get status;
  @override
  String get district;
  @override
  IncidentType get type;
  @override
  DateTime get updatedAt;
  @override
  String? get feedback;
  @override
  @JsonKey(ignore: true)
  _$$ReportStatusChangedEventImplCopyWith<_$ReportStatusChangedEventImpl>
      get copyWith => throw _privateConstructorUsedError;
}
