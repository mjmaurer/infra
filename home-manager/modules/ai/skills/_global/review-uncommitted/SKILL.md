---
name: review-uncommitted 
description: Review the working changes that are uncommitted for issues
allowed-tools: Bash(git diffall)
disable-model-invocation: true
---
Review the working changes that are uncommitted for issues. You should retrieve these working changes by running `git diffall`. Don't summarize the changes. You should focus on errors in logic, unwanted behavior and bugs. If you feel strongly that the changes are missing something that wouldn't necessarily qualify as a bug, feel free to point them out as well.