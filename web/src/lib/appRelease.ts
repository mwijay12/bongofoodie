/**
 * Where the real Flutter showcase build is handed out.
 *
 * The APK is published by `.github/workflows/showcase-release.yml` as a
 * GitHub **prerelease**, so `/releases/latest` never resolves and must not be
 * used here. Bump `tag` when a new showcase release is published, and keep it
 * recorded on the release page so the origin of the file stays auditable.
 */
export const appRelease = {
  tag: 'showcase-v3',
  /** Bumped in the same commit as `tag`; shown as "Build …" next to the button. */
  commit: '6db3987',
  fileName: 'app-release.apk',
  /** Human-readable size of the published asset (50,403,653 bytes). */
  size: '48.1 MB',
  sizeBytes: 50_403_653,
  appVersion: '2.0.0',
  minAndroid: 'Android 7.0+',
} as const;

export const appReleaseUrl = `https://github.com/mwijay12/bongofoodie/releases/download/${appRelease.tag}/${appRelease.fileName}`;

export const appReleasePageUrl = `https://github.com/mwijay12/bongofoodie/releases/tag/${appRelease.tag}`;
