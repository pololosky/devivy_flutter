import 'package:shared_preferences/shared_preferences.dart';

import '../models/business_profile.dart';

class ProfileRepository {
  static const _prefix = 'profile_';

  Future<BusinessProfile> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return BusinessProfile.fromPrefsMap({
      'businessName': prefs.getString('${_prefix}businessName') ?? '',
      'address': prefs.getString('${_prefix}address') ?? '',
      'slogan': prefs.getString('${_prefix}slogan') ?? '',
      'signaturePath': prefs.getString('${_prefix}signaturePath') ?? '',
      'logoPath': prefs.getString('${_prefix}logoPath') ?? '',
    });
  }

  Future<void> saveProfile(BusinessProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    final map = profile.toPrefsMap();
    await Future.wait(
      map.entries.map((e) => prefs.setString('$_prefix${e.key}', e.value)),
    );
  }

  Future<void> saveSignaturePath(String? filePath) async {
    final prefs = await SharedPreferences.getInstance();
    if (filePath == null || filePath.isEmpty) {
      await prefs.remove('${_prefix}signaturePath');
    } else {
      await prefs.setString('${_prefix}signaturePath', filePath);
    }
  }

  Future<void> saveLogoPath(String? filePath) async {
    final prefs = await SharedPreferences.getInstance();
    if (filePath == null || filePath.isEmpty) {
      await prefs.remove('${_prefix}logoPath');
    } else {
      await prefs.setString('${_prefix}logoPath', filePath);
    }
  }
}
