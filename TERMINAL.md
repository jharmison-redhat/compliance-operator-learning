# Compliance Operator Exploration - Command Line Client

## Prerequisites

- A connected OpenShift 4.7 cluster installed and reachable
  - (This could be a disconnected cluster but you would have to pre-mirror some content for the purposes of this exploration)
- A logged in `User` with a `ClusterRoleBinding` for `cluster-admin` applied.
  - You can run the following to check your cluster-bound `ClusterRoles`:

    ```sh
    function getRoles() {
        local kind="${1}"
        local name="${2}"
        local namespace="${3:-}"

        oc get clusterrolebinding -o json | jq -r "
          .items[]
          |
          select(
            .subjects[]?
            |
            select(
                .kind == \"${kind}\"
                and
                .name == \"${name}\"
                and
                (if .namespace then .namespace else \"\" end) == \"${namespace}\"
            )
          )
          |
          (.roleRef.kind + \"/\" + .roleRef.name)
        "
    }
    getRoles User $(oc whoami)
    ```

  - Your user also might be a member of a `Group` with this binding, so you can get false negatives with the above command.

## Installation

Included in this repository is a manifest file for subscribing to the operator using the settings listed above. From the command line, run the following:

```sh
oc apply -f 00-subscription.yaml
oc project openshift-compliance
while ! oc get deployment compliance-operator &>/dev/null; do echo -n '.'; sleep 1; done; echo
oc rollout status deployment/compliance-operator
```

The operator is now successfully installed.

## Exploring the preinstalled content

After operator installation finishes, you'll be able to look at the different Custom Resource Definitions (CRDs) it generates. Run the following:

```sh
cac_crds=$(oc get crd | awk '/compliance\.openshift\.io/{print $1}')
echo "$cac_crds"
```

Some of this content gets installed by the operator as it begins to start. You can view the created resources with the following:

```sh
for crd in $cac_crds; do
    echo "** $(echo $crd | cut -d. -f1) **"
    oc get $crd
done | less
```

### Breakdown

The Compliance Operator attempts to consolidate each type of object it might need into a unique Custom Resource Definition (CRD), and some of the resource types are bundles or higher abstractions that encapsulate some of the lower resource objects.

You can envision why this would be helpful, for example, if you consider the case of the login banner as an example. Many different compliance profiles (CIS benchmarks for commercial, PCI DSS for financial, HIPAA for healthcare, and of course the NIST controls for federal agencies) might require a setting on the login banner. The values between those profiles differ, but the way to set the banner will be the same for all of them.

To follow Don't Repeat Yourself (DRY) principles, the Compliance Operator breaks down these things into similar chunks that the underlying tooling has already done. That is, XCCDF profiles already have profiles, rules, and tunables. The major change here is that content and execution must be similarly tracked via CRD, and for that reason we have Scans, Suites, Bindings to tie these configuration objects together with a runtime component, Results for the output of a Scan or Suite, and Remediations to request and track what we'll do about failed Results. The CRD types for each of these are named more explicitly and you can browse the pre-installed content by paging through the output from above.

### ProfileBundles

The primary object that gets distributed with the Compliance Operator are `ProfileBundles`. In the paginated listing of objects, type `/profilebundles` and hit `Enter` to search for that phrase. You may have to return to the top with the `Home` key or press `1G` to goto the first line.

#### ocp4

This `ProfileBundle` concerns the Kubernetes platform and components that live inside the Kubernetes API natively. The value of `VALID` in the `STATUS` column indicates that the `ProfileBundle` was downloaded, unpacked, and parsed by the operator to generate the `Profiles` for the platform for various compliance standards. The other columns list the container image that hosted this bundle and the file that should be referenced in the bundle. That image is referenced by manifest hash, and the hash associated is associated with a specific release of the bundles that was packaged with a specific release of the Compliance Operator.

#### rhocs4

This `ProfileBundle` concerns the operating system that underlies the Kubernetes platform in OpenShift. Note especially that it's derived from the same bundle content image, but the profile is built from a different file in that image. This means one image contains all of the content for the platform and the operating system.

#### Then why are they split up?

If the same container image contains the ocp4 and rhocs4 content files, then you may wonder why they're split. The answer comes down to the best practice of least privilege. Executing scans on certain portions of the operating system, and almost all remediations, will require privileged host access. Any changes in the Kubernetes API itself need only privileged API access, but can be accomplished with no privilege on the host. For this reason, the design has split them up from the beginning. The content is still distributed in a single image, because the OpenShift Container Platform includes the Red Hat CoreOS operating system, the Kubernetes API, and the platform services delivered on top of it by operators. They're all versioned and tracked together to ensure maximum benefit from the integrations, but they're still separate pieces that need different treatment in this context.

### Profiles

The bundles themselves are not terrifically useful for us. The real advantages come from the profiles we extract from those bundles. Let's look at the available profiles. Search again by typing `/profiles` and hitting `Enter`.

#### Out of the box

Out of the box profiles included as of Compliance Operator release 0.1.29 are the Center for Internet Security (CIS) benchmarks commonly used for commercial systems, the Essential Eight (E8) benchmarks for the Australian government, and the FISMA moderate systems requirements from NIST SP 800-53.

#### Extending the out-of-the-box

First off, the [Compliance As Code (CaC) project on GitHub](https://github.com/ComplianceAsCode/content) houses the upstreams for all of the generated content. If you wanted to generate your own content, you could do so. I would recommend starting from the [Developer Guide](https://github.com/ComplianceAsCode/content/tree/master/docs/manual/developer) to understand how to build compliance content for this framework, and encourage you to contribute your work in collaboration with the upstream.

Included in the CaC repository is an OpenShift [BuildConfig](https://github.com/ComplianceAsCode/content/blob/master/ocp-resources/content-cluster-build.yaml) that enables you to use the native features of OCP to build the compliance bundle images that the `ProfileBundles` reference. You can apply the default BuildConfig with a simple one-liner to kick off a fresh build right now by pressing `q` (if you still have `less` open) and running the following:

```sh
oc apply -f https://raw.githubusercontent.com/ComplianceAsCode/content/master/ocp-resources/content-cluster-build.yaml -n openshift-compliance
```

Because this build is directly off of the master branch of the upstream, its stability is not guaranteed and the content is not strictly supported under Red Hat's terms. If you need a supported fix from the upstream backported to your OpenShift deployment, you should be able to open a support ticket to receive a prerelease update through official channels.

For our purposes today, though, we're going to use this master branch to explore some coming changes in a future release of the supported content.

Kick off a fresh build from the `BuildConfig` by running the following:

```sh
oc start-build cac-build
```
