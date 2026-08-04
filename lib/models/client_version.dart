class ClientVersionInfo {
  const ClientVersionInfo({
    required this.channel,
    required this.latestVersion,
    required this.minSupportedVersion,
    required this.updateAvailable,
    required this.updateRequired,
    required this.title,
    required this.releaseNotes,
    required this.downloadUrl,
  });

  final String channel;
  final String latestVersion;
  final String minSupportedVersion;
  final bool updateAvailable;
  final bool updateRequired;
  final String title;
  final String releaseNotes;
  final String downloadUrl;

  factory ClientVersionInfo.fromJson(Map<String, dynamic> json) {
    return ClientVersionInfo(
      channel: json['channel'] as String? ?? '',
      latestVersion: json['latest_version'] as String? ?? '',
      minSupportedVersion: json['min_supported_version'] as String? ?? '',
      updateAvailable: json['update_available'] as bool? ?? false,
      updateRequired: json['update_required'] as bool? ?? false,
      title: json['title'] as String? ?? '发现新版本',
      releaseNotes: json['release_notes'] as String? ?? '',
      downloadUrl: json['download_url'] as String? ?? '',
    );
  }

  static const empty = ClientVersionInfo(
    channel: '',
    latestVersion: '',
    minSupportedVersion: '',
    updateAvailable: false,
    updateRequired: false,
    title: '',
    releaseNotes: '',
    downloadUrl: '',
  );
}
