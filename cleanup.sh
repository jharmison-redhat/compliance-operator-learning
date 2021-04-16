#!/bin/bash

for crd in $(oc get crd | awk '/compliance\.openshift\.io/{print $1}'); do
    if oc get $crd &>/dev/null; then
        echo "Removing all $crd instances"
        oc delete $crd --all --wait
    fi
done

echo "Removing operator"
oc delete -f 00-subscription.yaml --wait

echo "Cleaning up CRDs"
for crd in $(oc get crd | awk '/compliance\.openshift\.io/{print $1}'); do
    oc delete crd $crd --wait
done
