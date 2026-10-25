import 'package:flutter/widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/utils/page_size.dart';

/// Height of one history/favorites row including the gap below it (62.r image + 2 x 12.r padding + 12.h gap).
double get kProductRowExtent => 98.h;

/// Page size for the product lists: two screens of rows (see [pageSizeForViewport]).
int productListPageSize(BuildContext context) =>
    pageSizeForViewport(viewportHeight: MediaQuery.sizeOf(context).height, rowExtent: kProductRowExtent);
