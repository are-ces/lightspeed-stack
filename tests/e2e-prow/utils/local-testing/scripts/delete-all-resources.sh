source pod.env
oc delete -f manifests/vllm/inference-service.yaml -n e2e-rhoai-dsc
oc delete -f manifests/vllm/vllm-runtime-cpu.yaml -n e2e-rhoai-dsc

oc delete pod $POD_NAME -n e2e-rhoai-dsc
oc delete pod llama-stack-service -n e2e-rhoai-dsc
oc delete pod lightspeed-stack-service -n e2e-rhoai-dsc
oc delete pod test-pod -n e2e-rhoai-dsc


oc delete configmap llama-stack-config -n e2e-rhoai-dsc
oc delete configmap lightspeed-stack-config -n e2e-rhoai-dsc
oc delete configmap test-script-cm -n e2e-rhoai-dsc


oc delete secret api-url-secret -n e2e-rhoai-dsc
oc delete secret hf-token-secret -n e2e-rhoai-dsc
oc delete secret lcs-ip-secret -n e2e-rhoai-dsc
oc delete secret llama-stack-ip-secret -n e2e-rhoai-dsc
oc delete secret vllm-api-key-secret -n e2e-rhoai-dsc
oc delete secret redhat-pull-secret -n e2e-rhoai-dsc

oc get pods -n e2e-rhoai-dsc
