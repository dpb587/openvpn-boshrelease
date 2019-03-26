With [Concourse CI](https://concourse-ci.org/pipelines.html)...

```yaml
resources:
- name: openvpn-bosh-release-rc
  type: metalink-repository
  source:
    uri: git+https://github.com/dpb587/openvpn-bosh-release.git//release/rc#artifacts
resource_types:
- name: metalink-repository
  type: docker-image
  source:
    repository: dpb587/metalink-repository-resource
```
