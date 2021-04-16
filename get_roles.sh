#!/bin/bash

function usage() {
    echo "usage: $0 SUBJECTTYPE SUBJECTNAME [BINDINGNAMESPACE] (ex: $0 User kubeadmin)" >&2
}

[ -n "$1" -a -n "$2" ] || usage

kind="${1}"
name="${2}"
namespace="${3:-}"

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
