#!/usr/bin/env node
/**
 * Publish the GitHub Release that a failed semantic-release run left behind.
 *
 * semantic-release pushes the version tag before it publishes the release. If it fails in between
 * (on 2026-09-28 GitHub rejected the push of its notes ref), the tag exists with no release, and a
 * re-run cannot fix that: semantic-release finds the tag on HEAD and decides there is nothing to
 * release. The workflow runs this script only after the release step fails.
 *
 * If HEAD carries a version tag on the remote that has no GitHub Release, the script publishes that
 * release and prints an `::error::` annotation so the failed run still gets looked at. It marks the
 * release latest only when no newer release is published, since a later run may already have
 * published one. In every other case it does nothing.
 *
 * The notes come from semantic-release's own notes generator, run over the same commits with the same
 * preset, so they read like every other release. If the generator cannot run (for example because
 * the npm install step is what failed), GitHub generates the notes instead and the annotation says so.
 *
 *     node Release/recover.mjs              # in CI, after the release step fails
 *     node Release/recover.mjs --selftest   # verify the decisions; no git, gh or network needed
 *
 * `GH` names the gh executable (default `gh`), so the GitHub calls can be stubbed on a laptop.
 */

import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";

// Matches the workflow's `tagFormat: '${version}'`: a tag is the bare version. Releases from `main`
// are always major.minor.patch, so anything else is not a version tag.
const VERSION_TAG = /^(\d+)\.(\d+)\.(\d+)$/;

// Far more releases than the repository will have; `gh release list` returns 30 by default.
const RELEASE_LIST_LIMIT = 1000;

// The preset the workflow's .releaserc.yml passes to semantic-release.
const NOTES_PRESET = "conventionalcommits";

// ---- Versions ----------------------------------------------------------------------------------

/** The version a tag names, or null when the tag is not a version. */
function parseVersion(tag) {
  const match = VERSION_TAG.exec(tag);
  if (match === null) return null;
  const [major, minor, patch] = match.slice(1).map(Number);
  return { tag, major, minor, patch };
}

function compareVersions(a, b) {
  return a.major - b.major || a.minor - b.minor || a.patch - b.patch;
}

/** The versions among `tags`, skipping tags that are not versions. */
function versionsOf(tags) {
  return tags.map(parseVersion).filter((version) => version !== null);
}

/** The highest of `versions`, or null when there are none. */
function highest(versions) {
  return versions.reduce((best, version) => (best === null || compareVersions(version, best) > 0 ? version : best), null);
}

// ---- Parsing command output --------------------------------------------------------------------

/**
 * The names of the tags that point at `commit`, from `git ls-remote --tags` output.
 *
 * An annotated tag is listed twice: the tag object, then `name^{}` with the commit it points at. The
 * peeled line wins, so annotated and lightweight tags are both matched by commit.
 */
function tagsPointingAt(commit, lsRemoteOutput) {
  const targets = new Map();
  for (const line of lsRemoteOutput.split("\n")) {
    const [sha, ref] = line.trim().split(/\s+/);
    if (!ref?.startsWith("refs/tags/")) continue;
    const peeled = ref.endsWith("^{}");
    const name = ref.slice("refs/tags/".length, peeled ? -"^{}".length : undefined);
    if (peeled || !targets.has(name)) targets.set(name, sha);
  }
  return [...targets].filter(([, sha]) => sha === commit).map(([name]) => name);
}

/** The repository's releases from `gh release list --json tagName,isDraft,isPrerelease`. */
function parseReleases(json) {
  return JSON.parse(json).map(({ tagName, isDraft, isPrerelease }) => ({
    tag: tagName,
    state: isDraft ? "draft" : isPrerelease ? "prerelease" : "published",
  }));
}

// ---- Decision ----------------------------------------------------------------------------------

/**
 * What to do, given the tags on HEAD, the tags reachable from HEAD, and the existing releases.
 *
 * - `noVersionTag`: HEAD carries no version tag, so no release is missing.
 * - `alreadyReleased`: the release exists; the failure lies elsewhere.
 * - `publish`: the version is tagged without a release. `previous` is the version before it (null for
 *   the first release). `standing` is `newest`, or `superseded` by a newer published release.
 */
function decide({ headTags, reachableTags, releases }) {
  const version = highest(versionsOf(headTags));
  if (version === null) return { kind: "noVersionTag" };
  if (releases.some((release) => release.tag === version.tag)) return { kind: "alreadyReleased", version };

  const previous = highest(versionsOf(reachableTags).filter((other) => compareVersions(other, version) < 0));
  const newestPublished = highest(versionsOf(releases.filter((r) => r.state === "published").map((r) => r.tag)));
  const standing =
    newestPublished !== null && compareVersions(newestPublished, version) > 0
      ? { kind: "superseded", by: newestPublished }
      : { kind: "newest" };
  return { kind: "publish", version, previous, standing };
}

// ---- Publishing --------------------------------------------------------------------------------

/**
 * The `gh` arguments that publish the release a `publish` decision describes.
 *
 * `notes` is `semanticRelease` with the generated text, or `githubGenerated` when the generator could
 * not run. The title is the bare tag, as semantic-release names every release.
 */
function releaseArguments({ version, previous, standing }, notes) {
  const latest = standing.kind === "newest" ? ["--latest"] : ["--latest=false"];
  const notesArguments =
    notes.kind === "semanticRelease"
      ? ["--notes", notes.text]
      : ["--generate-notes", ...(previous === null ? [] : ["--notes-start-tag", previous.tag])];
  return ["release", "create", version.tag, "--verify-tag", "--title", version.tag, ...latest, ...notesArguments];
}

/** The single-line workflow annotation reporting what the recovery published. */
function annotation({ version, standing }, notes) {
  const latest =
    standing.kind === "newest" ? "marked latest" : `not marked latest because ${standing.by.tag} is newer`;
  const source =
    notes.kind === "semanticRelease" ? "notes from semantic-release's generator" : "GitHub-generated notes";
  return (
    `::error title=Release published by recovery step::` +
    `semantic-release failed after pushing tag ${version.tag}, before publishing its GitHub Release. ` +
    `The recovery step published the release (${latest}, ${source}). ` +
    `Check the Release step's log for the cause.`
  );
}

// ---- Commands ----------------------------------------------------------------------------------

function run(command, args) {
  return execFileSync(command, args, { encoding: "utf8", stdio: ["ignore", "pipe", "inherit"] }).trim();
}

const git = (...args) => run("git", args);
const gh = (...args) => run(process.env.GH ?? "gh", args);

function lines(text) {
  return text.split("\n").filter((line) => line !== "");
}

function gatherFacts() {
  const head = git("rev-parse", "HEAD");
  return {
    headTags: tagsPointingAt(head, git("ls-remote", "--tags", "origin")),
    reachableTags: lines(git("tag", "--merged", "HEAD")),
    releases: parseReleases(
      gh("release", "list", "--limit", String(RELEASE_LIST_LIMIT), "--json", "tagName,isDraft,isPrerelease"),
    ),
  };
}

/**
 * The commits semantic-release would have passed to its notes generator: every commit after the
 * previous version up to this one, merges included, each with its full message trimmed.
 */
function commitsSince(previous, version) {
  const range = previous === null ? version.tag : `${previous.tag}..${version.tag}`;
  const [unit, record] = ["\x1f", "\x1e"];
  return git("log", `--format=%H${unit}%B${record}`, range)
    .split(record)
    .map((entry) => entry.trim())
    .filter((entry) => entry !== "")
    .map((entry) => {
      const [hash, message] = entry.split(unit);
      return { hash, message: message.trim() };
    });
}

/**
 * The release notes, from semantic-release's own generator when it can run, else GitHub's.
 *
 * The generator is imported here rather than at the top so the selftest runs without node_modules.
 */
async function releaseNotes({ version, previous }) {
  try {
    const { generateNotes } = await import("@semantic-release/release-notes-generator");
    const text = await generateNotes(
      { preset: NOTES_PRESET },
      {
        cwd: process.cwd(),
        commits: commitsSince(previous, version),
        lastRelease: previous === null ? {} : { gitTag: previous.tag },
        nextRelease: { version: version.tag, gitTag: version.tag },
        options: { repositoryUrl: git("remote", "get-url", "origin") },
      },
    );
    return { kind: "semanticRelease", text };
  } catch (error) {
    return { kind: "githubGenerated", reason: error.message };
  }
}

async function recover() {
  const decision = decide(gatherFacts());
  switch (decision.kind) {
    case "noVersionTag":
      console.log("HEAD carries no version tag, so no release is missing.");
      return;
    case "alreadyReleased":
      console.log(`The release for ${decision.version.tag} already exists; nothing to recover.`);
      return;
    case "publish": {
      const notes = await releaseNotes(decision);
      if (notes.kind === "githubGenerated") {
        console.log(`::warning::semantic-release's notes generator could not run (${notes.reason}); using GitHub's.`);
      }
      console.log(gh(...releaseArguments(decision, notes)));
      console.log(annotation(decision, notes));
      return;
    }
  }
}

// ---- Selftest ----------------------------------------------------------------------------------

const HEAD = "a".repeat(40);
const OTHER = "b".repeat(40);

function selftest() {
  // Remote tags: a lightweight tag and the peeled target of an annotated tag both count; tags on
  // other commits and non-tag refs do not.
  const lsRemote = [
    `${HEAD}\trefs/heads/main`,
    `${HEAD}\trefs/tags/0.24.2`,
    `${OTHER}\trefs/tags/0.24.1`,
    `${OTHER}\trefs/tags/annotated`,
    `${HEAD}\trefs/tags/annotated^{}`,
    "",
  ].join("\n");
  assert.deepEqual(tagsPointingAt(HEAD, lsRemote).sort(), ["0.24.2", "annotated"]);
  assert.deepEqual(tagsPointingAt(OTHER, lsRemote), ["0.24.1"]);

  const releases = parseReleases(
    JSON.stringify([
      { tagName: "0.24.3", isDraft: false, isPrerelease: false },
      { tagName: "0.30.0", isDraft: true, isPrerelease: false },
      { tagName: "0.31.0", isDraft: false, isPrerelease: true },
      { tagName: "0.24.1", isDraft: false, isPrerelease: false },
    ]),
  );
  assert.deepEqual(releases, [
    { tag: "0.24.3", state: "published" },
    { tag: "0.30.0", state: "draft" },
    { tag: "0.31.0", state: "prerelease" },
    { tag: "0.24.1", state: "published" },
  ]);

  const published = (...tags) => tags.map((tag) => ({ tag, state: "published" }));
  const history = ["0.9.0", "0.10.0", "0.24.0", "0.24.1", "0.24.2"];

  // Nothing to recover: no tag on HEAD, only a tag that is not a version, or the release exists.
  assert.deepEqual(decide({ headTags: [], reachableTags: history, releases: published("0.24.1") }), {
    kind: "noVersionTag",
  });
  assert.deepEqual(decide({ headTags: ["nightly"], reachableTags: history, releases: [] }), {
    kind: "noVersionTag",
  });
  const released = decide({ headTags: ["0.24.2"], reachableTags: history, releases: published("0.24.2") });
  assert.equal(released.kind, "alreadyReleased");
  assert.equal(released.version.tag, "0.24.2");

  // The 2026-09-28 incident: 0.24.2 tagged without a release while 0.24.3 was already published.
  const incident = decide({
    headTags: ["0.24.2"],
    reachableTags: history,
    releases: published("0.24.3", "0.24.1", "0.24.0"),
  });
  assert.equal(incident.kind, "publish");
  assert.equal(incident.version.tag, "0.24.2");
  assert.equal(incident.previous.tag, "0.24.1");
  assert.equal(incident.standing.kind, "superseded");
  assert.equal(incident.standing.by.tag, "0.24.3");

  // Newest when every published release is older; drafts and prereleases do not supersede.
  const newest = decide({
    headTags: ["0.24.2"],
    reachableTags: history,
    releases: [...published("0.24.1"), { tag: "0.30.0", state: "draft" }, { tag: "0.31.0", state: "prerelease" }],
  });
  assert.equal(newest.kind, "publish");
  assert.deepEqual(newest.standing, { kind: "newest" });

  // Versions compare numerically, not as text: 0.10.0 is newer than 0.9.0.
  const numeric = decide({ headTags: ["0.10.0"], reachableTags: ["0.9.0", "0.10.0"], releases: published("0.9.0") });
  assert.equal(numeric.previous.tag, "0.9.0");
  assert.deepEqual(numeric.standing, { kind: "newest" });
  const older = decide({ headTags: ["0.9.1"], reachableTags: ["0.9.0", "0.9.1"], releases: published("0.10.0") });
  assert.equal(older.standing.kind, "superseded");

  // The first release has no previous version.
  const first = decide({ headTags: ["0.1.0"], reachableTags: ["0.1.0"], releases: [] });
  assert.equal(first.kind, "publish");
  assert.equal(first.previous, null);

  // gh arguments: latest only when newest, and the notes come from where the notes value says.
  const semanticNotes = { kind: "semanticRelease", text: "## [0.24.2](…) (2026-09-28)" };
  assert.deepEqual(releaseArguments(incident, semanticNotes), [
    "release", "create", "0.24.2", "--verify-tag", "--title", "0.24.2", "--latest=false",
    "--notes", semanticNotes.text,
  ]);
  const githubNotes = { kind: "githubGenerated", reason: "module not found" };
  assert.deepEqual(releaseArguments(newest, githubNotes), [
    "release", "create", "0.24.2", "--verify-tag", "--title", "0.24.2", "--latest",
    "--generate-notes", "--notes-start-tag", "0.24.1",
  ]);
  assert.deepEqual(releaseArguments(first, githubNotes).slice(-1), ["--generate-notes"]);

  // The annotation is a single-line error naming the version, why it is not latest, and the notes source.
  const incidentMessage = annotation(incident, semanticNotes);
  assert.match(incidentMessage, /^::error title=[^\n]*::[^\n]*$/);
  assert.match(incidentMessage, /0\.24\.2/);
  assert.match(incidentMessage, /not marked latest because 0\.24\.3 is newer/);
  assert.match(incidentMessage, /semantic-release/);
  assert.match(annotation(newest, semanticNotes), /marked latest/);
  assert.match(annotation(newest, githubNotes), /GitHub-generated/);

  console.log("selftest OK: remote tags, releases, decisions, gh arguments and annotation");
}

if (process.argv.includes("--selftest")) {
  selftest();
} else {
  await recover();
}
