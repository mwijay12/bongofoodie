import { repoUrl } from '@/lib/repo';

/**
 * Where the real Flutter showcase build is handed out.
 *
 * The APK is published by `.github/workflows/showcase-release.yml` as a
 * GitHub **prerelease**, so `/releases/latest` never resolves and must not be
 * used here. Bump `tag` when a new showcase release is published; the release
 * page keeps the build auditable.
 *
 * Owner/name come from `lib/repo.ts`, which is the only place a repo rename
 * needs to be reflected.
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

export const appReleaseUrl = `${repoUrl}/releases/download/${appRelease.tag}/${appRelease.fileName}`;

export const appReleasePageUrl = `${repoUrl}/releases/tag/${appRelease.tag}`;

export { repoUrl };
