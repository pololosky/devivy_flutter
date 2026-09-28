import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/business_profile.dart';
import '../../data/repositories/profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>(
  (_) => ProfileRepository(),
);

final profileProvider =
    AsyncNotifierProvider<ProfileNotifier, BusinessProfile>(
        ProfileNotifier.new);

class ProfileNotifier extends AsyncNotifier<BusinessProfile> {
  @override
  Future<BusinessProfile> build() async {
    return ref.read(profileRepositoryProvider).getProfile();
  }

  Future<void> save(BusinessProfile profile) async {
    await ref.read(profileRepositoryProvider).saveProfile(profile);
    state = AsyncData(profile);
  }

  Future<void> saveSignature(String? path) async {
    await ref.read(profileRepositoryProvider).saveSignaturePath(path);
    final current = state.valueOrNull ?? BusinessProfile.empty;
    state = AsyncData(current.copyWith(signaturePath: path));
  }

  Future<void> saveLogo(String? path) async {
    await ref.read(profileRepositoryProvider).saveLogoPath(path);
    final current = state.valueOrNull ?? BusinessProfile.empty;
    state = AsyncData(current.copyWith(logoPath: path));
  }
}
