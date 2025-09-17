# Observability Hub - AppFramework

## Overview
This project provides a flexible framework for quickly building and experimenting with observability apps.
It offers a collection of tools and components designed to streamline the creation of data pipelines,
visualization dashboards, and monitoring systems, ideal for proof-of-concept development, rapid iteration, and exploration of observability use-cases.
While not intended for production environments, this setup serves as an adaptable starting point for building custom solutions that help gather,
process, and visualize application and infrastructure observability data.

To facilitate rapid development and experimentation, this repository leverages Docker Compose and its built-in import and override functionality.
Presently, we maintain two base "solution stacks" composed of observability components, each tailored to a distinct use case. Both should be considered
a starting point, and projects which are developed against these are expected to add / extend functionality through additional logic, compontents,
and other customizations.


<img src="https://raw.githubusercontent.com/F5ObservabilityHub/AppFramework-Docs/refs/heads/main/docs/assets/application-component-hierarchy.png" width="900px">

### Why Should You Use This?
Building on top of this repository as the core allows you to focus on the higher-level aspects of your solution without getting bogged down 
in the complexities of underlying infrastructure and configuration. By leveraging this framework, many of the lower level configuration and setup steps can be skipped,
as it provides well-considered defaults, follows best practices, self-monitors out of the box, and ensures a solid foundation for collecting and visualizing data.
This allows you to allocate your time and effort toward solving the unique challenges of your application, rather than reinventing the "data plumbing" aspects
with every new use-case.


## AppFramework Stacks

### Observability Developer Stack
The first stack is designed for local development environments, providing a straightforward setup for developers building systems which emit
observability data in Opentelemetry (or other) format. The stack contains everything necessary to fetch / receive data, store it, and
build visualizations around that data. In the future, additional capabilities for validating the emmited data and similar functionality
may be added.

<img src="https://raw.githubusercontent.com/F5ObservabilityHub/AppFramework-Docs/refs/heads/main/docs/assets/observability-development.png" width="900px">

An example use case for this stack might be a developer working to instrument an application with an OTEL SDK.
They would run the solution stack on their laptop, and configure their develpment instance / SDK to forward OTEL metrics/logs/traces to
the stack OTEL collector endpoint (e.g. localhost:4317). As they develop, they can use the stack to validate the output formats and behavior
against expectations.


### Observability Application Stack
The second stack is geared toward those looking to build applications that consume, process, and visualize telemetry data, offering a foundation
for creating powerful prototype monitoring and analytics solutions. By utilizing Docker Compose's flexibility, the stack can be easily customized and extended
to meet specific needs, making it simple to switch between different configurations or adapt the environment as requirements evolve.

<img src="https://raw.githubusercontent.com/F5ObservabilityHub/AppFramework-Docs/refs/heads/main/docs/assets/observability-application.png" width="900px">

An example use case would be the Application Study Tool, a BigIP Telemetry visualization tool. It leverages the Observability Hub
AppFramework components as the core of the tool, providing a mechanism for fetching, storing, and visualizing data. It cusomizes this
basic functionality through the addition of custom OTEL Collector Configurations to gather data from BigIPs, and custom Grafana dashboards
for visualizing this data. By leveraging the Application Components, they can spend more time focusing on the specific use case,
and less time on composing the lower level components.

## Getting Started

### Requirements

[Git Client](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)

Docker (or compatible) container environment with compose.

Installation Instructions:
  * [General (docker engine)](https://docs.docker.com/engine/install/)
  * [Ubuntu (docker engine)](https://docs.docker.com/engine/install/ubuntu/)
  * [RHEL (docker engine)](https://docs.docker.com/engine/install/rhel/)
  * [Podman](https://podman.io/docs/installation)

### Exploratory Mode
You can explore the base AppFramework stacks by cloning the repo and launching them directly via the associated compose file.
This will start the tooling with self-monitoring and default dashboards enabled. After exploring, it's recommended to sub-module
this repo into your own application for further development (see below).

```shell
git clone https://github.com/F5ObservabilityHub/AppFramework
cd AppFramework
# Start the Observability Development Stack
make observability-dev-up
# - OR -
# Start the Observability Application Stack
make observability-app-up
```

Once either stack is started, you can access the Grafana instance at [http://localhost:3001](http://localhost:3001).

Login / Password = admin / admin

### As A Sub-Module
Unfortunately, docker-compose requires that imported compose files be available on the local filesystem.
For use cases that need to customize the base stacks (most), the recommended approach is to sub-module this repo into your project.
We'll add a project template that includes some additional helper commands for this, but for now the following should work:

```shell
cd <your project root>
git submodule add https://github.com/F5ObservabilityHub/AppFramework
git submodule init
git submodule update
```

A simple compose file can then be written to reference the core as follows:

compose.yaml:
```yaml
include:
  - path : 
      - ./AppFramework/stacks/observability-app/compose.yaml
      # - ./override.yaml # Add your application specific overrides here

# Add your own container definitions here
# services:
#     some-application-container:
#        image: blah
```


## Support

For support, please open a GitHub issue.  Note, the code in this repository is community supported and is not supported by F5 Networks.  For a complete list of supported projects please reference [SUPPORT.md](SUPPORT.md).

## Community Code of Conduct

Please refer to the [F5 Observability Hub Community Code of Conduct](code_of_conduct.md).

## License

[Apache License 2.0](LICENSE)

## Copyright

Copyright 2014-2024 F5 Networks Inc.

### F5 Networks Contributor License Agreement

Before you start contributing to any project sponsored by F5 Networks, Inc. (F5) on GitHub, you will need to sign a Contributor License Agreement (CLA).

If you are signing as an individual, we recommend that you talk to your employer (if applicable) before signing the CLA since some employment agreements may have restrictions on your contributions to other projects.
Otherwise by submitting a CLA you represent that you are legally entitled to grant the licenses recited therein.

If your employer has rights to intellectual property that you create, such as your contributions, you represent that you have received permission to make contributions on behalf of that employer, that your employer has waived such rights for your contributions, or that your employer has executed a separate CLA with F5.

If you are signing on behalf of a company, you represent that you are legally entitled to grant the license recited therein.
You represent further that each employee of the entity that submits contributions is authorized to submit such contributions on behalf of the entity pursuant to the CLA.
