import 'package:freezed_annotation/freezed_annotation.dart';

part 'video_info.freezed.dart';
part 'video_info.g.dart';

/// images 字段：视频时是字符串，图集时是字符串数组
/// 用自定义 converter 处理
class ImagesConverter implements JsonConverter<dynamic, dynamic> {
  const ImagesConverter();

  @override
  dynamic fromJson(dynamic json) => json; // 保持原样，String 或 List

  @override
  dynamic toJson(dynamic object) => object;
}

@freezed
class VideoInfo with _$VideoInfo {
  const VideoInfo._();

  const factory VideoInfo({
    @Default('') String author,
    @JsonKey(fromJson: _parseId) @Default('') String uid,
    @Default('') String avatar,
    @JsonKey(fromJson: _parseInt) @Default(0) int like,
    @JsonKey(fromJson: _parseInt) @Default(0) int time,
    @Default('') String title,
    @Default('') String cover,
    @ImagesConverter() required dynamic images,
    @Default('') String url,
    @JsonKey(fromJson: _parseInt) @Default(0) int duration,
    required MusicInfo music,
  }) = _VideoInfo;

  factory VideoInfo.fromJson(Map<String, dynamic> json) =>
      _$VideoInfoFromJson(json);

  // images 是 List 就是图集，是 String 就是视频
  bool get isVideo => images is! List;
  List<String> get imageList =>
      images is List ? List<String>.from(images as List) : [];
}

@freezed
class MusicInfo with _$MusicInfo {
  const factory MusicInfo({
    @Default('') String title,
    @Default('') String author,
    @Default('') String avatar,
    @Default('') String url,
  }) = _MusicInfo;

  factory MusicInfo.fromJson(Map<String, dynamic> json) =>
      _$MusicInfoFromJson(json);
}

// uid 可能是 int 或 String
String _parseId(dynamic value) {
  if (value == null) return '';
  return value.toString();
}

int _parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}
