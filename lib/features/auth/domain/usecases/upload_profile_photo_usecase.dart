import 'dart:io';

import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/usecase/usecase.dart';

/// POST /auth/me/photo (`app/api/v1/endpoints/auth.py`) — uploads a local
/// image as multipart form data and returns the *raw* `photo_url` the
/// backend stored (a path relative to its own host, per
/// `ApiConstants.resolveMediaUrl`'s doc comment) — deliberately NOT
/// resolved to an absolute URL here, because the caller (`AuthBloc`) feeds
/// this straight back into `PATCH /auth/me` to persist it. Sending back an
/// already-resolved absolute URL would bake the current LAN host into the
/// stored value, breaking the moment that host changes — exactly what
/// keeping it relative server-side was meant to avoid. Resolve to
/// absolute only at display time (already handled by `UserModel.fromJson`
/// on whatever response — GET/PATCH /auth/me — is used for that).
class UploadProfilePhotoUseCase
    implements UseCase<String, UploadProfilePhotoParams> {
  final ApiClient apiClient;

  UploadProfilePhotoUseCase({required this.apiClient});

  @override
  Future<String> call(UploadProfilePhotoParams params) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        params.file.path,
        filename: 'photo.jpg',
      ),
    });
    final data = await apiClient.post(ApiConstants.mePhoto, data: formData);
    final photoUrl = (data as Map<String, dynamic>)['photo_url'] as String?;
    if (photoUrl == null) {
      throw const ServerException(
        message: 'Photo upload succeeded but no photo URL was returned',
      );
    }
    return photoUrl;
  }
}

class UploadProfilePhotoParams {
  final File file;

  const UploadProfilePhotoParams({required this.file});
}
