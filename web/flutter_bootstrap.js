{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  config: { canvasKitBaseUrl: 'canvaskit/', canvasKitVariant: 'full' },
}).catch(function (error) {
  console.error('[Flutter]', error);
  const loading = document.getElementById('loading');
  if (loading) {
    loading.textContent = 'Uygulama yüklenemedi. Bağlantını kontrol edip yeniden aç.';
    loading.style.color = '#ffffff';
  }
});
