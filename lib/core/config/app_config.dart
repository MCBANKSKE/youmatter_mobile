class AppConfig {
  AppConfig._();

  static const String appName = 'YouMatter';

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://youmatter.mcbankske.space/api',
  );

  static const String wsUrl = String.fromEnvironment(
    'WS_URL',
    defaultValue: 'wss://youmatter.mcbankske.space',
  );

  static const String reverbAppId = String.fromEnvironment(
    'REVERB_APP_ID',
    defaultValue: '529444',
  );

  static const String reverbAppKey = String.fromEnvironment(
    'REVERB_APP_KEY',
    defaultValue: 'pkwzsovurafetjfbuvfn',
  );
}
