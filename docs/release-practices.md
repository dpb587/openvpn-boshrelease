---
title: Release Practices
---

# Release Practices

When deploying this release, please consider the following in regards to the stability and compliance of your deployments.


## Dependencies

This release contains several components from upstream projects. New versions are monitored and automatically integrated by CI. Where available, checksums and PGP verification are used to verify upstream artifacts.

You can find additional details about licenses of these components from the [`LICENSES` file](https://github.com/dpb587/openvpn-bosh-release/blob/master/LICENSES) in the [source repository](https://github.com/dpb587/openvpn-bosh-release) along with references to the original artifacts and their source code.


## Versioning

Releases are versioned according to [semantic versioning](http://semver.org/) rules...

 > Given a version number MAJOR.MINOR.PATCH, increment the:
 >
 > 0. MAJOR version when you make incompatible API changes,
 > 0. MINOR version when you add functionality in a backwards-compatible manner, and
 > 0. PATCH version when you make backwards-compatible bug fixes.

When upstream dependencies change, their respective version bumps may not be surfaced by an equivalent version bump in this release. For example, if a dependency is upgraded from 2.3.4 to 2.4.0, the release version may only bump the patch if new features are not exposed through the release.

A forward-fixing versioning policy is followed. In general, fixes will not be backported.


## Channels

When referencing this release, you should typically follow the [`stable` channel](https://github.com/dpb587/openvpn-bosh-release/tree/artifacts/release/stable) which contains the official final release tarballs. Alternatively, you can find tarballs of this release on [bosh.io](https://bosh.io/releases/github.com/dpb587/openvpn-bosh-release?all=1).

If you prefer using development releases with potential bugs, the following channels are also available (from later to earlier in the testing process):

 * [`rc`](https://github.com/dpb587/openvpn-bosh-release/tree/artifacts/release/rc) -- testing in external environments has completed successfully
 * [`beta`](https://github.com/dpb587/openvpn-bosh-release/tree/artifacts/release/beta) -- testing within the scope of the repository's CI has completed successfully
 * [`alpha`](https://github.com/dpb587/openvpn-bosh-release/tree/artifacts/release/alpha) -- development builds without any completed, successful testing
