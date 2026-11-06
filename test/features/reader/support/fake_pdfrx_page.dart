import 'package:pdfrx/pdfrx.dart';

class FakePdfrxPage implements PdfPage {
  FakePdfrxPage({
    required this.width,
    required this.height,
    this.rotation = PdfPageRotation.none,
    this.pageNumber = 1,
  });

  @override
  final double width;

  @override
  final double height;

  @override
  final PdfPageRotation rotation;

  @override
  final int pageNumber;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not faked');
}
