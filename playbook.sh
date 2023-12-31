#!/bin/bash

ansible-playbook run.yaml -i hosts.ini --become --ask-become-pass --limit "$@" 
