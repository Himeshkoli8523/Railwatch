enum AppFlavor { dev, staging, prod }

extension AppFlavorX on AppFlavor {
  static AppFlavor fromName(String name) {
    switch (name.toLowerCase()) {
      case 'prod':
      case 'production':
        return AppFlavor.prod;
      case 'staging':
        return AppFlavor.staging;
      default:
        return AppFlavor.dev;
    }
  }

  String get label {
    switch (this) {
      case AppFlavor.dev:
        return 'DEV';
      case AppFlavor.staging:
        return 'STG';
      case AppFlavor.prod:
        return 'PROD';
    }
  }
}
