/// External image storage configuration.
///
/// This project previously uploaded images to Firebase Storage. If your Firebase
/// Storage quota is exceeded, you can store images in a non-Firebase provider
/// and keep only the resulting URL in Firestore (e.g. `products.imageUrl`).
///
/// Recommended provider for "no backend": Cloudinary unsigned upload preset.
/// Note: Unsigned presets are NOT a secret. Treat them as public and restrict
/// preset settings (max file size, allowed formats, folder, moderation).
class ExternalImageStorageConfig {
  /// Master flag for external image uploads.
  static const bool enabled = true;

  /// Cloudinary "cloud name" from the dashboard.
  static const String cloudinaryCloudName = 'YOUR_CLOUD_NAME';

  /// Cloudinary unsigned upload preset name.
  static const String cloudinaryUnsignedUploadPreset = 'YOUR_UPLOAD_PRESET';

  /// Folder where product images are stored in Cloudinary.
  static const String cloudinaryProductFolder = 'tuning_app/products';

  /// Folder where profile images are stored in Cloudinary.
  static const String cloudinaryProfileFolder = 'tuning_app/profiles';

  /// Folder where review images are stored in Cloudinary.
  static const String cloudinaryReviewFolder = 'tuning_app/reviews';
}


