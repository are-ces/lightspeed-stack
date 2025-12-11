# Install OpenShift installer
mkdir -p ~/bin
curl -L -o openshift-install-linux.tar.gz "https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/stable/openshift-install-linux.tar.gz"
tar -xzf openshift-install-linux.tar.gz
rm openshift-install-linux.tar.gz
mv openshift-install ~/bin/
chmod +x ~/bin/openshift-install

# Verify OpenShift installer
if ! command -v openshift-install &> /dev/null
then
echo "❌ openshift-install not found. Installation failed."
exit 1
fi

echo "✅ openshift-install is installed."
openshift-install version
