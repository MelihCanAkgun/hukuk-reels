void listenBattle(void Function(Map<String, dynamic>) listener) {}
Future<Map<String, dynamic>> battleCall(String action,
        [Map<String, dynamic> data = const {}]) async =>
    action == 'inspect'
        ? {}
        : {
            'error':
                '1v1 Battle, yayınlanan web/ana ekran uygulamasında kullanılabilir.'
          };
