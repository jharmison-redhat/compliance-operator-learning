Remainder outline:

- `oc apply -f 01-profilebundles.yaml`
- ComplianceSuite == ocs4 and rhcos4 profiles at same level
- `oc get profile | grep -F upstream-`
- More coming all the time
- `oc describe profile.compliance upstream-rhcos4-stig | less`
- ProfileBundles are more than Profiles - the parsed results of the profiles come with
- `oc get rule.compliance | grep -F upstream- | wc -l`
- The XML has a lot
- ComplianceSuite is a collection of Scan definitions that are paired together, but they're very low level
- `cat 02-compliancesuite.yaml`
- `oc apply -f 02-compliancesuite.yaml`
- `oc get compliancesuite -w`
- Results in here are nice if you know k8s - your auditors want checkfiles
- `oc get pvc`

```sh
oc apply -f 03-extract.yaml
while ! oc get pod pv-extract | grep -qF Running; do
    sleep 5
done
rm -rf results
mkdir -p results/{nodes,platform}
for scan in {nodes,platform}; do
    oc cp pv-extract:/$scan/0/ results/$scan/
done
for bzip in $(find results -type f -name \*.bzip2); do
    xml=$(echo $bzip | rev | cut -d. -f2- | rev)
    bzcat $bzip > $xml
done
find results -type f -name \*.xml
```

- Remediations!
- We're only going to apply one as applying all of them will actually break the cluster in some ways that matter to us right now.
- `oc debug node/$(oc get node | awk '/worker/{print $1}' | head -1)`
- `chroot /host`
- `cat /etc/shells` - the valid shells for login on this system, `tmux` is one of them.
- `exit` #chroot
- `exit` #debug shell
- `oc describe rule rhcos4-no-tmux-in-shells | less`
- `/Rationale`
- `oc patch complianceremediations/node-stig-no-tmux-in-shells --patch '{"spec":{"apply":true}}' --type=merge`
- `oc get machineconfig 75-node-stig-no-tmux-in-shells -o yaml | less`
- `oc get nodes -w`
- What's a MachineConfig? #while nodes are rebooting
- What happens when a MachineConfig rollout brings nodes down?
- Why a MachineConfig and not bash or ansible to fix it?
- `oc debug node/$(oc get node | awk '/worker/{print $1}' | head -1) -- cat /host/etc/shells`
- `oc debug node/$(oc get node | awk '/worker/{print $1}' | head -2 | tail -1) -- cat /host/etc/shells`
- `oc debug node/$(oc get node | awk '/worker/{print $1}' | head -3 | tail -1) -- cat /host/etc/shells`
- Configuring regular scanning to happen automatically
- `cat 04-scansetting.yaml` - not going to apply it, but much easier to maintain and inherit profiles
- Why didn't we apply all remediations? A few things break. Lots of your things will probably break.
- Acceptible risk, POA&M, etc. These things happen - and you need to figure out where the line is for you and your environment.
- You should look at the [documentation on tailoring](https://docs.openshift.com/container-platform/4.7/security/compliance_operator/compliance-operator-tailor.html) directly to understand how to do this - but know that it can and should be done.
- Have your own XCCDF tailoring profile you want to reuse - or your auditors custom craft their own? There are [docs on that, too](https://docs.openshift.com/container-platform/4.7/security/compliance_operator/compliance-operator-advanced.html#compliance-raw-tailored_compliance-advanced).
