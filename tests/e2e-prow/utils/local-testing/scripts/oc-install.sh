
# Install OpenShift client (oc)
curl -L -o openshift-client-linux.tar.gz "https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/stable/openshift-client-linux.tar.gz"
tar -xzf openshift-client-linux.tar.gz
rm openshift-client-linux.tar.gz
mv oc kubectl ~/bin/
chmod +x ~/bin/oc ~/bin/kubectl

# Verify OpenShift client installation
if ! command -v oc &> /dev/null
then
echo "❌ oc CLI not found. Installation failed."
exit 1
fi

echo "✅ oc CLI is installed."
oc version