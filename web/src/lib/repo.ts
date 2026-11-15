/**
 * Repository identity, in one place.
 *
 * When the repo is renamed on GitHub, GitHub keeps the old URL redirecting, but
 * hard-coded `mwijay12/bongofoodie` strings scattered across the app would drift.
 * Change `owner` and `name` here and every link follows — the release download,
 * the release page, the "view source" links and the release-lookup in
 * `web/tests/home.spec.ts` (that one reads this file's values through the page).
 */
export const repo = {
  owner: 'mwijay12',
  name: 'bongofoodie',
} as const;

export const repoUrl = `https://github.com/${repo.owner}/${repo.name}`;

export const repoReleasesUrl = `${repoUrl}/releases`;
