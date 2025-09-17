# Observability AppFramework Developer Example

This folder contains a demo implementation of the AppFramework 'Development' stack, meant to illustrate how it might be used
in the development of applications which emit telemetry (via otel or other mechanisms supported by the Open Telemetry Collector).

It includes a simple python application instrumented with the Otel SDK, a custom dashboard used to visualize the metrics, logs, and traces from the app,
and a set of compose configuration files needed to launch the stack and configure it with the dashboard.

<img src="https://raw.githubusercontent.com/F5ObservabilityHub/AppFramework-Docs/refs/heads/main/docs/assets/example_developer_hello_world.png" width="900px">

## Pre-Requisite
* Python3 environment
* Docker / Podman with compose support
* Git client

## Run The Example
The example can be run via the following process:

```shell
git clone https://github.com/F5ObservabilityHub/AppFramework.git
cd AppFramework/examples/developer_hello_world
# recommended
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
docker compose up -d
# Wait for the stack to fully start to avoid network errors
python ./hello_world.py
```

## Run With Your Own Development Project
The AppFramework Development Stack is intended for use alongside or within a seperate project where a telemetry producing application
is being developd. Due to the limitations of docker compose, the AppFramework files must reside on the filesystem of the machine
where you intend to run the stack. There are a few options for how to lay things out to best suit your use-case:

1. AppFramework as an external / stand-alone project - clone the AppFramework to your filesystem somewhere and run the stack from there.
    * Pros: Keeps your development project free of additional dependencies. Simplest to maintain
    * Cons: Harder to consistently support custom dashboards, configuration settings, etc - especially for multi-person teams.
2. AppFramework as a sub-module - Add AppFramework as a git submodule to your poject.
    * Pros: Can control which version of appframework is run with which version of your project. Simplified customizations for multi-person teams.
    * Cons: Have to git-submodule this (e.g. extra initialization setps)

<img src="https://raw.githubusercontent.com/F5ObservabilityHub/AppFramework-Docs/refs/heads/main/docs/assets/developer_layouts.png" width="900px">

