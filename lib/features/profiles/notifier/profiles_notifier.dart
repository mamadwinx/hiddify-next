import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:hiddify/core/prefs/prefs.dart';
import 'package:hiddify/data/data_providers.dart';
import 'package:hiddify/domain/enums.dart';
import 'package:hiddify/domain/profiles/profiles.dart';
import 'package:hiddify/features/common/active_profile/active_profile_notifier.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'profiles_notifier.g.dart';

@riverpod
class ProfilesSortNotifier extends _$ProfilesSortNotifier with AppLogger {
  @override
  ({ProfilesSort by, SortMode mode}) build() {
    return (by: ProfilesSort.lastUpdate, mode: SortMode.descending);
  }

  void changeSort(ProfilesSort sortBy) =>
      state = (by: sortBy, mode: state.mode);

  void toggleMode() => state = (
        by: state.by,
        mode: state.mode == SortMode.ascending
            ? SortMode.descending
            : SortMode.ascending
      );
}

@riverpod
class ProfilesNotifier extends _$ProfilesNotifier with AppLogger {
  @override
  Stream<List<Profile>> build() {
    final sort = ref.watch(profilesSortNotifierProvider);
    return _profilesRepo
        .watchAll(sort: sort.by, mode: sort.mode)
        .map((event) => event.getOrElse((l) => throw l));
  }

  ProfilesRepository get _profilesRepo => ref.read(profilesRepositoryProvider);

  Future<Unit> selectActiveProfile(String id) async {
    loggy.debug('changing active profile to: [$id]');
    return _profilesRepo.setAsActive(id).getOrElse((f) {
      loggy.warning('failed to set [$id] as active profile, $f');
      throw f;
    }).run();
  }

  Future<Unit> addProfile(String url) async {
    final activeProfile = await ref.read(activeProfileProvider.future);
    final markAsActive =
        activeProfile == null || ref.read(markNewProfileActiveProvider);
    loggy.debug("adding profile, url: [$url]");
    return ref
        .read(profilesRepositoryProvider)
        .addByUrl(url, markAsActive: markAsActive)
        .getOrElse((l) {
      loggy.warning("failed to add profile: $l");
      throw l;
    }).run();
  }

  Future<Unit?> updateProfile(Profile profile) async {
    loggy.debug("updating profile");
    return ref
        .read(profilesRepositoryProvider)
        .update(profile)
        .getOrElse((l) => throw l)
        .run();
  }

  Future<void> deleteProfile(Profile profile) async {
    loggy.debug('deleting profile: ${profile.name}');
    await _profilesRepo.delete(profile.id).mapLeft(
      (f) {
        loggy.warning('failed to delete profile, $f');
        throw f;
      },
    ).run();
  }
}
