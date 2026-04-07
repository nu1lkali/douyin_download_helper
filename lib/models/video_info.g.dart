// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$VideoInfoImpl _$$VideoInfoImplFromJson(Map<String, dynamic> json) =>
    _$VideoInfoImpl(
      author: json['author'] as String? ?? '',
      uid: json['uid'] == null ? '' : _parseId(json['uid']),
      avatar: json['avatar'] as String? ?? '',
      like: json['like'] == null ? 0 : _parseInt(json['like']),
      time: json['time'] == null ? 0 : _parseInt(json['time']),
      title: json['title'] as String? ?? '',
      cover: json['cover'] as String? ?? '',
      images: const ImagesConverter().fromJson(json['images']),
      url: json['url'] as String? ?? '',
      duration: json['duration'] == null ? 0 : _parseInt(json['duration']),
      music: MusicInfo.fromJson(json['music'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$VideoInfoImplToJson(_$VideoInfoImpl instance) =>
    <String, dynamic>{
      'author': instance.author,
      'uid': instance.uid,
      'avatar': instance.avatar,
      'like': instance.like,
      'time': instance.time,
      'title': instance.title,
      'cover': instance.cover,
      'images': const ImagesConverter().toJson(instance.images),
      'url': instance.url,
      'duration': instance.duration,
      'music': instance.music,
    };

_$MusicInfoImpl _$$MusicInfoImplFromJson(Map<String, dynamic> json) =>
    _$MusicInfoImpl(
      title: json['title'] as String? ?? '',
      author: json['author'] as String? ?? '',
      avatar: json['avatar'] as String? ?? '',
      url: json['url'] as String? ?? '',
    );

Map<String, dynamic> _$$MusicInfoImplToJson(_$MusicInfoImpl instance) =>
    <String, dynamic>{
      'title': instance.title,
      'author': instance.author,
      'avatar': instance.avatar,
      'url': instance.url,
    };
