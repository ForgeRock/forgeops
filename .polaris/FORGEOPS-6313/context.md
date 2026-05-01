# Context: FORGEOPS-6313

## Source
- Type: jira
- Key: FORGEOPS-6313
- Issue Type: Story
- Project: ForgeOps

## Summary
Add amster ttl option to forgeops env command plus minor improvements

## Description
**Objective**
As a CICD engineer, I want to be able to dynamically set the ttl on the amster job using the forgeops env command to keep the job in the namespace for a long period of time for further tests.

Also:
* Add a check to the --amster-retain argument to ensure the value is an int.
* Update the help command to remove the term "infinity"

## Acceptance Criteria
* Can set the ttl in your environment using forgeops env. Deployment takes this value into consideration.
* Help command updated to not include `infinity`
* Add a string to --amster-retain will throw an error

## Links
None

## Comments
None
