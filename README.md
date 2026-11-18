# settlement-automation
QA automation for the refactored settlement API project.

All user credentials and API keys are stored in the AWS secrets for the settlement and metadata APIs. AWS authentication works
the same as for the Xplatform automation: in order to access the secrets you will need
to have a valid enoc session in .aws/credentials, under the key set specified in configuration.json. 

## References

### Cucumber:

https://cucumber.io/

https://github.com/cucumber/cucumber-expressions#readme

### REST Assured:

https://rest-assured.io/

https://github.com/rest-assured/rest-assured/wiki/GettingStarted

### JUnit:
https://junit.org/junit5/docs/current/user-guide/

### Settlement API:

<CONFLUENCE_URL>/display/PMENA/Settlement+API+-+Technical+Design

<GITHUB_URL>/xplatform/settlement-api

<GITHUB_URL>/xplatform/settlement-automation

### Settlement API (old version):

<GITHUB_URL>/fdr/dr-settlement-api

<GITHUB_URL>/fdr/dr-settlement-infrastructure