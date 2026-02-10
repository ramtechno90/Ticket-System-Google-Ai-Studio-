# flutter_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Firebase Storage CORS Configuration

If you encounter issues loading images from Firebase Storage in development or production (especially on web), you need to configure the CORS policy for your bucket.

1.  A `cors.json` file is provided in the repository root.
2.  Install the `gsutil` tool (part of the Google Cloud SDK).
3.  Run the following command, replacing `[YOUR-BUCKET-NAME]` with your actual Firebase Storage bucket name (e.g., `gs://your-project-id.appspot.com`):

    ```bash
    gsutil cors set cors.json gs://[YOUR-BUCKET-NAME]
    ```

    Alternatively, you can set this directly from the Google Cloud Console for the bucket.
