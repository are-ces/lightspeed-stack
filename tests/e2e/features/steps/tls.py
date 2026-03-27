"""Step definitions for TLS configuration e2e tests.

These tests configure Llama Stack's run.yaml with NetworkConfig TLS settings
and verify the full pipeline works through the Lightspeed Stack.

Config switching uses the same pattern as other e2e tests: overwrite the
host-mounted run.yaml and restart Docker containers. Cleanup is handled
by a Background step that restores the backup before each scenario.
"""

import copy
import os
import shutil

from behave import given  # pyright: ignore[reportAttributeAccessIssue]
from behave.runner import Context

from tests.e2e.features.steps.proxy import (
    _LLAMA_STACK_CONFIG,
    _load_llama_config,
    _write_config,
)

_LLAMA_STACK_CONFIG_BACKUP = "run.yaml.tls-backup"


_TLS_PROVIDER_BASE: dict = {
    "provider_id": "tls-openai",
    "provider_type": "remote::openai",
    "config": {
        "api_key": "test-key",
        "base_url": "https://mock-tls-inference:8443/v1",
        "allowed_models": ["mock-tls-model"],
    },
}

_TLS_MODEL_RESOURCE: dict = {
    "model_id": "mock-tls-model",
    "provider_id": "tls-openai",
    "provider_model_id": "mock-tls-model",
}


def _ensure_tls_provider(config: dict) -> dict:
    """Find or create the tls-openai inference provider in the config.

    If the provider does not exist, it is added along with the
    mock-tls-model registered resource.

    Parameters:
        config: The Llama Stack configuration dictionary.

    Returns:
        The tls-openai provider configuration dictionary.
    """
    providers = config.setdefault("providers", {})
    inference = providers.setdefault("inference", [])

    for provider in inference:
        if provider.get("provider_id") == "tls-openai":
            return provider

    # Provider not found — add it
    provider = copy.deepcopy(_TLS_PROVIDER_BASE)
    inference.append(provider)

    # Also register the model resource
    resources = config.setdefault("registered_resources", {})
    models = resources.setdefault("models", [])
    if not any(m.get("model_id") == "mock-tls-model" for m in models):
        models.append(copy.deepcopy(_TLS_MODEL_RESOURCE))

    return provider


def _backup_llama_config() -> None:
    """Create a backup of the current run.yaml if not already backed up."""
    if not os.path.exists(_LLAMA_STACK_CONFIG_BACKUP):
        shutil.copy(_LLAMA_STACK_CONFIG, _LLAMA_STACK_CONFIG_BACKUP)


def _prepare_tls_provider() -> tuple[dict, dict]:
    """Back up run.yaml, load it, ensure the TLS provider exists, and init network config.

    Returns:
        A tuple of (full config dict, provider's network config dict).
    """
    _backup_llama_config()
    config = _load_llama_config()
    provider = _ensure_tls_provider(config)
    provider.setdefault("config", {}).setdefault("network", {})
    return config, provider


# --- Background Steps ---
# Restart steps ("The original Llama Stack config is restored if modified",
# "Llama Stack is restarted", "Lightspeed Stack is restarted") are defined in
# proxy.py and shared across features by behave.


# --- TLS Configuration Steps ---


@given("Llama Stack is configured with TLS verification disabled")
def configure_tls_verify_false(context: Context) -> None:
    """Configure run.yaml with TLS verify: false.

    Parameters:
        context: Behave test context.
    """
    config, provider = _prepare_tls_provider()
    provider["config"]["network"]["tls"] = {"verify": False}
    _write_config(config, _LLAMA_STACK_CONFIG)


@given("Llama Stack is configured with CA certificate verification")
def configure_tls_verify_ca(context: Context) -> None:
    """Configure run.yaml with TLS verify: /certs/ca.crt.

    Parameters:
        context: Behave test context.
    """
    config, provider = _prepare_tls_provider()
    provider["config"]["network"]["tls"] = {
        "verify": "/certs/ca.crt",
        "min_version": "TLSv1.2",
    }
    _write_config(config, _LLAMA_STACK_CONFIG)


@given("Llama Stack is configured with TLS verification enabled")
def configure_tls_verify_true(context: Context) -> None:
    """Configure run.yaml with TLS verify: true.

    This should fail when connecting to a self-signed certificate server.

    Parameters:
        context: Behave test context.
    """
    config, provider = _prepare_tls_provider()
    provider["config"]["network"]["tls"] = {"verify": True}
    _write_config(config, _LLAMA_STACK_CONFIG)


@given("Llama Stack is configured with mutual TLS authentication")
def configure_tls_mtls(context: Context) -> None:
    """Configure run.yaml with mutual TLS (client cert and key).

    Parameters:
        context: Behave test context.
    """
    config, provider = _prepare_tls_provider()

    # Update base_url to use the mTLS server port
    provider["config"]["base_url"] = "https://mock-tls-inference:8444/v1"

    provider["config"]["network"]["tls"] = {
        "verify": "/certs/ca.crt",
        "client_cert": "/certs/client.crt",
        "client_key": "/certs/client.key",
    }
    _write_config(config, _LLAMA_STACK_CONFIG)


@given('Llama Stack is configured with CA certificate path "{path}"')
def configure_tls_verify_ca_path(context: Context, path: str) -> None:
    """Configure run.yaml with TLS verify pointing to a specific CA cert path.

    Parameters:
        context: Behave test context.
        path: Path to the CA certificate file.
    """
    config, provider = _prepare_tls_provider()
    provider["config"]["network"]["tls"] = {"verify": path}
    _write_config(config, _LLAMA_STACK_CONFIG)


@given("Llama Stack is configured for mTLS without client certificate")
def configure_mtls_no_client_cert(context: Context) -> None:
    """Configure run.yaml for mTLS port but without providing client certificate.

    This should fail because the mTLS server requires a client certificate.

    Parameters:
        context: Behave test context.
    """
    config, provider = _prepare_tls_provider()
    provider["config"]["base_url"] = "https://mock-tls-inference:8444/v1"
    provider["config"]["network"]["tls"] = {"verify": "/certs/ca.crt"}
    _write_config(config, _LLAMA_STACK_CONFIG)


@given("Llama Stack is configured for mTLS with wrong client certificate")
def configure_mtls_wrong_client_cert(context: Context) -> None:
    """Configure run.yaml for mTLS with a certificate not issued by the server's CA.

    Uses the CA cert itself as the client cert, which is not a valid client
    identity certificate, causing the mTLS handshake to fail.

    Parameters:
        context: Behave test context.
    """
    config, provider = _prepare_tls_provider()
    provider["config"]["base_url"] = "https://mock-tls-inference:8444/v1"
    provider["config"]["network"]["tls"] = {
        "verify": "/certs/ca.crt",
        "client_cert": "/certs/ca.crt",
        "client_key": "/certs/client.key",
    }
    _write_config(config, _LLAMA_STACK_CONFIG)


@given("Llama Stack is configured for mTLS with untrusted client certificate")
def configure_mtls_untrusted_client_cert(context: Context) -> None:
    """Configure run.yaml for mTLS with a client certificate not trusted by the server's CA.

    Uses a client certificate issued by a separate, untrusted CA, causing the
    mTLS handshake to fail.

    Parameters:
        context: Behave test context.
    """
    config, provider = _prepare_tls_provider()
    provider["config"]["base_url"] = "https://mock-tls-inference:8444/v1"
    provider["config"]["network"]["tls"] = {
        "verify": "/certs/ca.crt",
        "client_cert": "/certs/untrusted-client.crt",
        "client_key": "/certs/untrusted-client.key",
    }
    _write_config(config, _LLAMA_STACK_CONFIG)


@given("Llama Stack is configured for mTLS with expired client certificate")
def configure_mtls_expired_client_cert(context: Context) -> None:
    """Configure run.yaml for mTLS with an expired client certificate.

    Uses a client certificate that was signed by the correct CA but has
    expired validity dates.

    Parameters:
        context: Behave test context.
    """
    config, provider = _prepare_tls_provider()
    provider["config"]["base_url"] = "https://mock-tls-inference:8444/v1"
    provider["config"]["network"]["tls"] = {
        "verify": "/certs/ca.crt",
        "client_cert": "/certs/expired-client.crt",
        "client_key": "/certs/client.key",
    }
    _write_config(config, _LLAMA_STACK_CONFIG)


@given("Llama Stack is configured with CA certificate and hostname mismatch server")
def configure_tls_hostname_mismatch(context: Context) -> None:
    """Configure run.yaml to connect to the hostname-mismatch TLS server.

    The mock server on port 8445 presents a certificate issued for
    "wrong-hostname.example.com", but the client connects to
    "mock-tls-inference", causing a hostname verification failure.

    Parameters:
        context: Behave test context.
    """
    config, provider = _prepare_tls_provider()
    provider["config"]["base_url"] = "https://mock-tls-inference:8445/v1"
    provider["config"]["network"]["tls"] = {"verify": "/certs/ca.crt"}
    _write_config(config, _LLAMA_STACK_CONFIG)


@given("Llama Stack is configured with mutual TLS and hostname mismatch server")
def configure_mtls_hostname_mismatch(context: Context) -> None:
    """Configure run.yaml for mTLS against the hostname-mismatch TLS server.

    The mock server on port 8445 presents a certificate issued for
    "wrong-hostname.example.com". Even though client certs are provided,
    the hostname mismatch should cause the connection to fail.

    Parameters:
        context: Behave test context.
    """
    config, provider = _prepare_tls_provider()
    provider["config"]["base_url"] = "https://mock-tls-inference:8445/v1"
    provider["config"]["network"]["tls"] = {
        "verify": "/certs/ca.crt",
        "client_cert": "/certs/client.crt",
        "client_key": "/certs/client.key",
    }
    _write_config(config, _LLAMA_STACK_CONFIG)


@given(
    'Llama Stack is configured with TLS minimum version "{version}" and hostname mismatch server'
)
def configure_tls_min_version_hostname_mismatch(context: Context, version: str) -> None:
    """Configure run.yaml with TLS min version against the hostname-mismatch server.

    Parameters:
        context: Behave test context.
        version: The TLS version (e.g., "TLSv1.2", "TLSv1.3").
    """
    config, provider = _prepare_tls_provider()
    provider["config"]["base_url"] = "https://mock-tls-inference:8445/v1"
    provider["config"]["network"]["tls"] = {
        "verify": "/certs/ca.crt",
        "min_version": version,
    }
    _write_config(config, _LLAMA_STACK_CONFIG)


@given(
    'Llama Stack is configured with TLS minimum version "{version}" and CA certificate path "{path}"'
)
def configure_tls_min_version_with_ca_path(
    context: Context, version: str, path: str
) -> None:
    """Configure run.yaml with TLS minimum version and a specific CA cert path.

    Parameters:
        context: Behave test context.
        version: The TLS version (e.g., "TLSv1.2", "TLSv1.3").
        path: Path to the CA certificate file.
    """
    config, provider = _prepare_tls_provider()
    provider["config"]["network"]["tls"] = {
        "verify": path,
        "min_version": version,
    }
    _write_config(config, _LLAMA_STACK_CONFIG)
