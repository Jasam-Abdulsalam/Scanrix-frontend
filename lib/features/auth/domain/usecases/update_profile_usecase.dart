import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/usecase/usecase.dart';
import '../../data/models/user_model.dart';
import '../entities/user_entity.dart';

/// PATCH /auth/me (`app/api/v1/endpoints/auth.py`) — saves the
/// profile-completion step (`CreateAccountPage`'s "Continue" button) and
/// marks `profileCompleted` true server-side.
class UpdateProfileUseCase implements UseCase<UserEntity, UpdateProfileParams> {
  final ApiClient apiClient;

  UpdateProfileUseCase({required this.apiClient});

  @override
  Future<UserEntity> call(UpdateProfileParams params) async {
    final data = await apiClient.patch(
      ApiConstants.me,
      data: {
        'name': params.name,
        if (params.photoUrl != null) 'photo_url': params.photoUrl,
      },
    );
    return UserModel.fromJson(data as Map<String, dynamic>);
  }
}

class UpdateProfileParams {
  final String name;

  /// A hosted URL only — e.g. the Google account's existing `photoUrl`
  /// left unchanged. A freshly camera/gallery-picked local file has no
  /// URL yet (this app has no image upload/hosting wired up), so it can't
  /// be sent here until that exists.
  final String? photoUrl;

  const UpdateProfileParams({required this.name, this.photoUrl});
}
