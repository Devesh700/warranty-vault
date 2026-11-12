import 'package:flutter/widgets.dart';

import '../local_file_store.dart';

class LocalImage extends StatelessWidget {
  const LocalImage({
    super.key,
    required this.pathOrUri,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  final String pathOrUri;
  final BoxFit fit;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return LocalFileStore.buildImage(
      pathOrUri,
      fit: fit,
      width: width,
      height: height,
    );
  }
}
