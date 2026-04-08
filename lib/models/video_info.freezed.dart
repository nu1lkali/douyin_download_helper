// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'video_info.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

VideoInfo _$VideoInfoFromJson(Map<String, dynamic> json) {
  return _VideoInfo.fromJson(json);
}

/// @nodoc
mixin _$VideoInfo {
  String get author => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _parseId)
  String get uid => throw _privateConstructorUsedError;
  String get avatar => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _parseInt)
  int get like => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _parseInt)
  int get time => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get cover => throw _privateConstructorUsedError;
  @ImagesConverter()
  dynamic get images => throw _privateConstructorUsedError;
  String get url => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _parseInt)
  int get duration => throw _privateConstructorUsedError;
  MusicInfo get music => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $VideoInfoCopyWith<VideoInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VideoInfoCopyWith<$Res> {
  factory $VideoInfoCopyWith(VideoInfo value, $Res Function(VideoInfo) then) =
      _$VideoInfoCopyWithImpl<$Res, VideoInfo>;
  @useResult
  $Res call(
      {String author,
      @JsonKey(fromJson: _parseId) String uid,
      String avatar,
      @JsonKey(fromJson: _parseInt) int like,
      @JsonKey(fromJson: _parseInt) int time,
      String title,
      String cover,
      @ImagesConverter() dynamic images,
      String url,
      @JsonKey(fromJson: _parseInt) int duration,
      MusicInfo music});

  $MusicInfoCopyWith<$Res> get music;
}

/// @nodoc
class _$VideoInfoCopyWithImpl<$Res, $Val extends VideoInfo>
    implements $VideoInfoCopyWith<$Res> {
  _$VideoInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? author = null,
    Object? uid = null,
    Object? avatar = null,
    Object? like = null,
    Object? time = null,
    Object? title = null,
    Object? cover = null,
    Object? images = freezed,
    Object? url = null,
    Object? duration = null,
    Object? music = null,
  }) {
    return _then(_value.copyWith(
      author: null == author
          ? _value.author
          : author // ignore: cast_nullable_to_non_nullable
              as String,
      uid: null == uid
          ? _value.uid
          : uid // ignore: cast_nullable_to_non_nullable
              as String,
      avatar: null == avatar
          ? _value.avatar
          : avatar // ignore: cast_nullable_to_non_nullable
              as String,
      like: null == like
          ? _value.like
          : like // ignore: cast_nullable_to_non_nullable
              as int,
      time: null == time
          ? _value.time
          : time // ignore: cast_nullable_to_non_nullable
              as int,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      cover: null == cover
          ? _value.cover
          : cover // ignore: cast_nullable_to_non_nullable
              as String,
      images: freezed == images
          ? _value.images
          : images // ignore: cast_nullable_to_non_nullable
              as dynamic,
      url: null == url
          ? _value.url
          : url // ignore: cast_nullable_to_non_nullable
              as String,
      duration: null == duration
          ? _value.duration
          : duration // ignore: cast_nullable_to_non_nullable
              as int,
      music: null == music
          ? _value.music
          : music // ignore: cast_nullable_to_non_nullable
              as MusicInfo,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $MusicInfoCopyWith<$Res> get music {
    return $MusicInfoCopyWith<$Res>(_value.music, (value) {
      return _then(_value.copyWith(music: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$VideoInfoImplCopyWith<$Res>
    implements $VideoInfoCopyWith<$Res> {
  factory _$$VideoInfoImplCopyWith(
          _$VideoInfoImpl value, $Res Function(_$VideoInfoImpl) then) =
      __$$VideoInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String author,
      @JsonKey(fromJson: _parseId) String uid,
      String avatar,
      @JsonKey(fromJson: _parseInt) int like,
      @JsonKey(fromJson: _parseInt) int time,
      String title,
      String cover,
      @ImagesConverter() dynamic images,
      String url,
      @JsonKey(fromJson: _parseInt) int duration,
      MusicInfo music});

  @override
  $MusicInfoCopyWith<$Res> get music;
}

/// @nodoc
class __$$VideoInfoImplCopyWithImpl<$Res>
    extends _$VideoInfoCopyWithImpl<$Res, _$VideoInfoImpl>
    implements _$$VideoInfoImplCopyWith<$Res> {
  __$$VideoInfoImplCopyWithImpl(
      _$VideoInfoImpl _value, $Res Function(_$VideoInfoImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? author = null,
    Object? uid = null,
    Object? avatar = null,
    Object? like = null,
    Object? time = null,
    Object? title = null,
    Object? cover = null,
    Object? images = freezed,
    Object? url = null,
    Object? duration = null,
    Object? music = null,
  }) {
    return _then(_$VideoInfoImpl(
      author: null == author
          ? _value.author
          : author // ignore: cast_nullable_to_non_nullable
              as String,
      uid: null == uid
          ? _value.uid
          : uid // ignore: cast_nullable_to_non_nullable
              as String,
      avatar: null == avatar
          ? _value.avatar
          : avatar // ignore: cast_nullable_to_non_nullable
              as String,
      like: null == like
          ? _value.like
          : like // ignore: cast_nullable_to_non_nullable
              as int,
      time: null == time
          ? _value.time
          : time // ignore: cast_nullable_to_non_nullable
              as int,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      cover: null == cover
          ? _value.cover
          : cover // ignore: cast_nullable_to_non_nullable
              as String,
      images: freezed == images
          ? _value.images
          : images // ignore: cast_nullable_to_non_nullable
              as dynamic,
      url: null == url
          ? _value.url
          : url // ignore: cast_nullable_to_non_nullable
              as String,
      duration: null == duration
          ? _value.duration
          : duration // ignore: cast_nullable_to_non_nullable
              as int,
      music: null == music
          ? _value.music
          : music // ignore: cast_nullable_to_non_nullable
              as MusicInfo,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$VideoInfoImpl extends _VideoInfo {
  const _$VideoInfoImpl(
      {this.author = '',
      @JsonKey(fromJson: _parseId) this.uid = '',
      this.avatar = '',
      @JsonKey(fromJson: _parseInt) this.like = 0,
      @JsonKey(fromJson: _parseInt) this.time = 0,
      this.title = '',
      this.cover = '',
      @ImagesConverter() required this.images,
      this.url = '',
      @JsonKey(fromJson: _parseInt) this.duration = 0,
      required this.music})
      : super._();

  factory _$VideoInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$VideoInfoImplFromJson(json);

  @override
  @JsonKey()
  final String author;
  @override
  @JsonKey(fromJson: _parseId)
  final String uid;
  @override
  @JsonKey()
  final String avatar;
  @override
  @JsonKey(fromJson: _parseInt)
  final int like;
  @override
  @JsonKey(fromJson: _parseInt)
  final int time;
  @override
  @JsonKey()
  final String title;
  @override
  @JsonKey()
  final String cover;
  @override
  @ImagesConverter()
  final dynamic images;
  @override
  @JsonKey()
  final String url;
  @override
  @JsonKey(fromJson: _parseInt)
  final int duration;
  @override
  final MusicInfo music;

  @override
  String toString() {
    return 'VideoInfo(author: $author, uid: $uid, avatar: $avatar, like: $like, time: $time, title: $title, cover: $cover, images: $images, url: $url, duration: $duration, music: $music)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VideoInfoImpl &&
            (identical(other.author, author) || other.author == author) &&
            (identical(other.uid, uid) || other.uid == uid) &&
            (identical(other.avatar, avatar) || other.avatar == avatar) &&
            (identical(other.like, like) || other.like == like) &&
            (identical(other.time, time) || other.time == time) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.cover, cover) || other.cover == cover) &&
            const DeepCollectionEquality().equals(other.images, images) &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.duration, duration) ||
                other.duration == duration) &&
            (identical(other.music, music) || other.music == music));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      author,
      uid,
      avatar,
      like,
      time,
      title,
      cover,
      const DeepCollectionEquality().hash(images),
      url,
      duration,
      music);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$VideoInfoImplCopyWith<_$VideoInfoImpl> get copyWith =>
      __$$VideoInfoImplCopyWithImpl<_$VideoInfoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$VideoInfoImplToJson(
      this,
    );
  }
}

abstract class _VideoInfo extends VideoInfo {
  const factory _VideoInfo(
      {final String author,
      @JsonKey(fromJson: _parseId) final String uid,
      final String avatar,
      @JsonKey(fromJson: _parseInt) final int like,
      @JsonKey(fromJson: _parseInt) final int time,
      final String title,
      final String cover,
      @ImagesConverter() required final dynamic images,
      final String url,
      @JsonKey(fromJson: _parseInt) final int duration,
      required final MusicInfo music}) = _$VideoInfoImpl;
  const _VideoInfo._() : super._();

  factory _VideoInfo.fromJson(Map<String, dynamic> json) =
      _$VideoInfoImpl.fromJson;

  @override
  String get author;
  @override
  @JsonKey(fromJson: _parseId)
  String get uid;
  @override
  String get avatar;
  @override
  @JsonKey(fromJson: _parseInt)
  int get like;
  @override
  @JsonKey(fromJson: _parseInt)
  int get time;
  @override
  String get title;
  @override
  String get cover;
  @override
  @ImagesConverter()
  dynamic get images;
  @override
  String get url;
  @override
  @JsonKey(fromJson: _parseInt)
  int get duration;
  @override
  MusicInfo get music;
  @override
  @JsonKey(ignore: true)
  _$$VideoInfoImplCopyWith<_$VideoInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MusicInfo _$MusicInfoFromJson(Map<String, dynamic> json) {
  return _MusicInfo.fromJson(json);
}

/// @nodoc
mixin _$MusicInfo {
  String get title => throw _privateConstructorUsedError;
  String get author => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _parseNullableString)
  String get avatar => throw _privateConstructorUsedError;
  String get url => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $MusicInfoCopyWith<MusicInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MusicInfoCopyWith<$Res> {
  factory $MusicInfoCopyWith(MusicInfo value, $Res Function(MusicInfo) then) =
      _$MusicInfoCopyWithImpl<$Res, MusicInfo>;
  @useResult
  $Res call(
      {String title,
      String author,
      @JsonKey(fromJson: _parseNullableString) String avatar,
      String url});
}

/// @nodoc
class _$MusicInfoCopyWithImpl<$Res, $Val extends MusicInfo>
    implements $MusicInfoCopyWith<$Res> {
  _$MusicInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = null,
    Object? author = null,
    Object? avatar = null,
    Object? url = null,
  }) {
    return _then(_value.copyWith(
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      author: null == author
          ? _value.author
          : author // ignore: cast_nullable_to_non_nullable
              as String,
      avatar: null == avatar
          ? _value.avatar
          : avatar // ignore: cast_nullable_to_non_nullable
              as String,
      url: null == url
          ? _value.url
          : url // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MusicInfoImplCopyWith<$Res>
    implements $MusicInfoCopyWith<$Res> {
  factory _$$MusicInfoImplCopyWith(
          _$MusicInfoImpl value, $Res Function(_$MusicInfoImpl) then) =
      __$$MusicInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String title,
      String author,
      @JsonKey(fromJson: _parseNullableString) String avatar,
      String url});
}

/// @nodoc
class __$$MusicInfoImplCopyWithImpl<$Res>
    extends _$MusicInfoCopyWithImpl<$Res, _$MusicInfoImpl>
    implements _$$MusicInfoImplCopyWith<$Res> {
  __$$MusicInfoImplCopyWithImpl(
      _$MusicInfoImpl _value, $Res Function(_$MusicInfoImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = null,
    Object? author = null,
    Object? avatar = null,
    Object? url = null,
  }) {
    return _then(_$MusicInfoImpl(
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      author: null == author
          ? _value.author
          : author // ignore: cast_nullable_to_non_nullable
              as String,
      avatar: null == avatar
          ? _value.avatar
          : avatar // ignore: cast_nullable_to_non_nullable
              as String,
      url: null == url
          ? _value.url
          : url // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MusicInfoImpl implements _MusicInfo {
  const _$MusicInfoImpl(
      {this.title = '',
      this.author = '',
      @JsonKey(fromJson: _parseNullableString) this.avatar = '',
      this.url = ''});

  factory _$MusicInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$MusicInfoImplFromJson(json);

  @override
  @JsonKey()
  final String title;
  @override
  @JsonKey()
  final String author;
  @override
  @JsonKey(fromJson: _parseNullableString)
  final String avatar;
  @override
  @JsonKey()
  final String url;

  @override
  String toString() {
    return 'MusicInfo(title: $title, author: $author, avatar: $avatar, url: $url)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MusicInfoImpl &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.author, author) || other.author == author) &&
            (identical(other.avatar, avatar) || other.avatar == avatar) &&
            (identical(other.url, url) || other.url == url));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, title, author, avatar, url);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MusicInfoImplCopyWith<_$MusicInfoImpl> get copyWith =>
      __$$MusicInfoImplCopyWithImpl<_$MusicInfoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MusicInfoImplToJson(
      this,
    );
  }
}

abstract class _MusicInfo implements MusicInfo {
  const factory _MusicInfo(
      {final String title,
      final String author,
      @JsonKey(fromJson: _parseNullableString) final String avatar,
      final String url}) = _$MusicInfoImpl;

  factory _MusicInfo.fromJson(Map<String, dynamic> json) =
      _$MusicInfoImpl.fromJson;

  @override
  String get title;
  @override
  String get author;
  @override
  @JsonKey(fromJson: _parseNullableString)
  String get avatar;
  @override
  String get url;
  @override
  @JsonKey(ignore: true)
  _$$MusicInfoImplCopyWith<_$MusicInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
