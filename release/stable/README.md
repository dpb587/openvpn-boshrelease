With [Concourse CI](https://concourse-ci.org/pipelines.html)...

```yaml
resources:
- name: openvpn-bosh-release
  type: metalink-repository
  source:
    uri: git+https://github.com/dpb587/openvpn-bosh-release.git//release/stable#artifacts
resource_types:
- name: metalink-repository
  type: docker-image
  source:
    repository: dpb587/metalink-repository-resource
```
