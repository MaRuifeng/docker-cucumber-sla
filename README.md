# Cucumber for SLA UI

This is a POC project of containerized cucumber GUI tests for the SLA project. It's built upon the foundation of the [docker-cucumber](https://github.com/MaRuifeng/docker-cucumber) idea. 

The project mainly contains below parts
* Cucumber test specs (feature Gherkin files, step definitions, page objects, environment configs and profile settings etc.)
* A Chef helper utility that offers a Chef workstation to communicate with a Chef server that manages endpoint server states during test execution (SLA is a web application for server compliance and change management)
* A reporting utility that communicates with the report server for test data processing and publishing

A customized [html_formmater](https://github.com/MaRuifeng/docker-cucumber-sla/blob/master/features/support/html_formatter.rb) is added to generate one cucumber HTML report for each feature, instead of a single combined page.

## Getting Started

The cheezy [page-object](https://github.com/cheezy/page-object) gem is widely adopted in this project. It's recommeneded to read through its documentation. 

## Build & Deploy

The `cucumber_build_deploy_jenkins.sh` script file provides an executable specification on how this cucumber container can be built and run. A Jenkins job can be created on top of this script. 

## Author & Organization
* Ruifeng Ma (mrfflyer@gmail.com) - IBM

## License & Acknowledgments
