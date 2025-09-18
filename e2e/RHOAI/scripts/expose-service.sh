source pod.env

oc expose svc/$APP_LABEL --name=vllm-model-public --port=80
