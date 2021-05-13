Remainder outline:

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
