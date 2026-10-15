import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hukuk_reels/core/services/avatar_sync.dart';
import 'package:hukuk_reels/core/services/progress_service.dart';

const _jpegB64 = '/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAgGBgcGBQgHBwcJCQgKDBQNDAsLDBkSEw8UHRofHh0aHBwgJC4nICIsIxwcKDcpLDAxNDQ0Hyc5PTgyPC4zNDL/wAALCAABAAEBAREA/8QAFAABAAAAAAAAAAAAAAAAAAAACf/EABQQAQAAAAAAAAAAAAAAAAAAAAD/2gAIAQEAAD8AKp//2Q==';

/// İki oyunculu sahte sunucu: sürümler + fotoğraflar.
class _FakeServer {
  final Map<int, (String, String)> photos = {};
  final calls = <String>[];
  int version = 0;
  int me = 1;
  int? failStatus;

  Map<String, dynamic> state() => {
        'connected': true,
        'me': me,
        'players': [
          for (final id in [1, 2])
            {'id': id, 'name': 'P$id', 'active': 1, 'avatar': photos[id]?.$1},
        ],
      };

  Future<Map<String, dynamic>> call(String action,
      [Map<String, dynamic> data = const {}]) async {
    calls.add(action);
    if (failStatus != null) return {'error': 'olmadı', 'status': failStatus};
    switch (action) {
      case 'avatarPut':
        final b64 = (data['data'] as String).split(',').last;
        photos[me] = ('v${++version}', b64);
        return state();
      case 'avatarDelete':
        photos.remove(me);
        return state();
      case 'avatarGet':
        final p = photos[data['id']];
        return p == null
            ? {'error': 'yok', 'status': 404}
            : {'id': data['id'], 'version': p.$1, 'data': p.$2};
    }
    return state();
  }
}

void main() {
  late _FakeServer server;
  final sync = AvatarSync.instance;
  final progress = ProgressService.instance;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await progress.init();
  });

  setUp(() async {
    server = _FakeServer();
    sync.call = server.call;
    sync.clearPeers();
    await progress.setAvatarDataUrl(null);
    await progress.markAvatarSynced(null);
  });

  test('a new photo is uploaded once and marked synced', () async {
    await progress.setAvatarDataUrl('data:image/jpeg;base64,$_jpegB64');
    expect(progress.avatarPending, 'up');
    await sync.sync(server.state());
    expect(server.calls.where((c) => c == 'avatarPut'), hasLength(1));
    expect(progress.avatarPending, isNull);
    expect(progress.avatarVersion, server.photos[1]!.$1);
    server.calls.clear();
    await sync.sync(server.state());
    expect(server.calls, isEmpty, reason: 'nothing changes, nothing is sent');
  });

  test('the partner photo is downloaded only when its version changes',
      () async {
    server.photos[2] = ('a1', _jpegB64);
    await sync.sync(server.state());
    expect(sync.photoOf(2), base64Decode(_jpegB64));
    server.calls.clear();
    await sync.sync(server.state());
    expect(server.calls.where((c) => c == 'avatarGet'), isEmpty);
    server.photos.remove(2);
    await sync.sync(server.state());
    expect(sync.photoOf(2), isNull);
  });

  test('own photo changed on another device is pulled; removal follows',
      () async {
    server.photos[1] = ('x9', _jpegB64);
    await sync.sync(server.state());
    expect(progress.avatar, base64Decode(_jpegB64));
    expect(progress.avatarVersion, 'x9');
    expect(progress.avatarPending, isNull);
    server.photos.remove(1);
    await sync.sync(server.state());
    expect(progress.avatar, isNull);
    expect(progress.avatarVersion, isNull);
  });

  test('removing locally deletes on the server', () async {
    await progress.setAvatarDataUrl('data:image/jpeg;base64,$_jpegB64');
    await sync.sync(server.state());
    await progress.setAvatarDataUrl(null);
    expect(progress.avatarPending, 'del');
    await sync.sync(server.state());
    expect(server.photos.containsKey(1), isFalse);
    expect(progress.avatarPending, isNull);
  });

  test('a rejected photo is not resent; network errors are retried',
      () async {
    await progress.setAvatarDataUrl('data:image/jpeg;base64,$_jpegB64');
    server.failStatus = 503;
    await sync.sync(server.state());
    expect(progress.avatarPending, 'up');
    expect(sync.lastError, isNotNull);
    server.failStatus = 400;
    await sync.sync(server.state());
    expect(progress.avatarPending, 'rejected');
    server.failStatus = null;
    server.calls.clear();
    await sync.sync(server.state());
    expect(server.calls.where((c) => c == 'avatarPut'), isEmpty);
  });

  test('nothing is synced when not connected', () async {
    await progress.setAvatarDataUrl('data:image/jpeg;base64,$_jpegB64');
    await sync.sync({'connected': false});
    expect(server.calls, isEmpty);
  });
}
