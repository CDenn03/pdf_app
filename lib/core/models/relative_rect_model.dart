import 'package:freezed_annotation/freezed_annotation.dart';

part 'relative_rect_model.freezed.dart';
part 'relative_rect_model.g.dart';

@freezed
abstract class RelativeRectModel with _$RelativeRectModel {
  const factory RelativeRectModel({
    required double top,
    required double left,
    required double bottom,
    required double right,
  }) = _RelativeRectModel;

  factory RelativeRectModel.fromJson(Map<String, dynamic> json) =>
      _$RelativeRectModelFromJson(json);
}
