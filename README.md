# Course Pilot

A Flutter learning companion: sign in, browse your courses, open a course and complete lessons, online or offline.

**Run:** `flutter pub get && flutter run`. Demo account: `demo@coursepilot.app` / `password123`.
**Test:** `flutter test`. The API is mocked in `MockApiInterceptor`; switch `CourseMockScenario` in `main.dart` to preview empty, error and offline states.

## Architecture

Feature-first folders (`features/auth`, `features/courses`), each split into `data` and `presentation`, plus a small `core` (network, storage, router, theme).

- **Data:** remote and local data sources sit behind a repository. The repository is the only place that decides between network and cache, and it turns every error into a typed `AppFailure`, so the UI never sees Dio or Hive.
- **State:** Riverpod (`AsyncNotifier`/`Notifier`). Screens render the `AsyncValue` with an exhaustive `switch` (loading, data, empty, error). Lesson completion is optimistic: the UI updates instantly and rolls back if the repository throws.
- **Domain logic** lives on the models: `Course.progress` is derived from completed lessons, never stored.
- **Navigation:** go_router, with a redirect driven by the session state.

I chose this because it keeps each layer testable in isolation (the repository runs against the mock API, and screens run against a stubbed repository) without adding more layers than a small app needs.

## Offline support

Every successful `GET /courses` is written to a Hive box as JSON with a timestamp (`CacheStore` → `CourseLocalDataSource`). If a fetch fails, the repository returns the saved copy as a `CourseFeed` marked as cached, and the dashboard shows an "offline / saved X ago" banner. With nothing saved, the error state is shown. Completing a lesson while offline updates the saved copy and queues the completion; the queue is sent before the next fetch, and items the server rejects (4xx) are dropped. Unreadable cache data is treated as no cache.

## Security

The access token is stored in `flutter_secure_storage` (Keychain on iOS/macOS, Keystore-backed storage on Android), never in Hive or preferences. For production I would add short-lived access tokens with a rotating refresh token (also in secure storage), refresh on 401 in a Dio interceptor, certificate pinning, and encryption of the Hive cache with a key held in secure storage. Sign-out already clears the token and all cached course data.

## Scale (1M users, hundreds of courses)

1. **Pagination and summaries:** the list endpoint returns course summaries with server-computed progress, cursor-paginated; lessons load per course on demand.
2. **Smarter caching:** ETag/`If-None-Match` and stale-while-revalidate (show the cache instantly, refresh in the background), with per-course entries instead of one blob.
3. **Reliable progress sync:** idempotent completion requests with client IDs, retry with backoff, and background sync (WorkManager / BGTaskScheduler) instead of waiting for the next fetch.
4. **Observability:** crash reporting, request tracing and performance monitoring (Crashlytics/Sentry), plus feature flags for gradual rollouts.
5. **Backend load:** CDN for course content and rate limiting; the client already avoids duplicate fetches through provider caching.

## Second platform

The app is written once in Flutter and already runs on iOS, Android and macOS from this codebase. Platform-specific pieces are small: secure storage maps to Keychain or Keystore automatically, page transitions follow each platform (Cupertino slide and swipe-back on iOS, the native transition and predictive back on Android), and the layout is width-constrained so it also works on tablets and desktop. Shipping a new platform means configuring signing, icons and entitlements (for example the Keychain entitlement on macOS) and testing on real devices, not rewriting features.
